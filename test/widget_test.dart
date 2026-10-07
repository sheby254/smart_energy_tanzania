import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_energy_tanzania/main.dart';
import 'package:smart_energy_tanzania/services/energy_api_client.dart';
import 'package:smart_energy_tanzania/services/session_storage.dart';

class _MemorySessionStorage implements SessionStorage {
  String? token;

  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;
}

class _EnergyApiFixture {
  final meters = <Map<String, Object>>[
    {
      'id': '1',
      'name': 'Home',
      'number': '0100 234 567',
      'balanceKwh': 120.5,
      'kind': 'home',
      'status': 'pending',
      'lastUpdated': 'awaiting meter connection',
    },
    {
      'id': '2',
      'name': 'Office',
      'number': '0100 987 654',
      'balanceKwh': 80.2,
      'kind': 'business',
      'status': 'pending',
      'lastUpdated': 'awaiting meter connection',
    },
  ];
  final transfers = <Map<String, Object>>[];
  var nextMeterId = 3;

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    if (path == '/api/login' && request.method == 'POST') {
      return _jsonResponse({
        'data': {
          'token': 'fixture-token',
          'user': {'id': 1, 'name': 'Asha Mushi', 'email': 'asha@example.com'},
        },
      });
    }
    if (path == '/api/register' && request.method == 'POST') {
      return _jsonResponse({
        'data': {
          'token': 'fixture-token',
          'user': {'id': 1, 'name': 'Asha Mushi', 'email': 'asha@example.com'},
        },
      }, statusCode: 201);
    }
    if (path == '/api/dashboard' && request.method == 'GET') {
      return _jsonResponse({
        'data': {'meters': meters, 'transfers': transfers},
      });
    }
    if (path == '/api/meters' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final meter = <String, Object>{
        'id': '${nextMeterId++}',
        'name': body['name'] as String,
        'number': body['number'] as String,
        'balanceKwh': body['balanceKwh'] as num,
        'kind': body['kind'] as String,
        'status': 'pending',
        'lastUpdated': 'awaiting meter connection',
      };
      meters.add(meter);
      return _jsonResponse({'data': meter}, statusCode: 201);
    }
    if (path == '/api/transfers' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final from = meters.singleWhere(
        (meter) => meter['id'] == '${body['fromMeterId']}',
      );
      final to = meters.singleWhere(
        (meter) => meter['id'] == '${body['toMeterId']}',
      );
      final amount = (body['amountKwh'] as num).toDouble();
      from['balanceKwh'] = (from['balanceKwh'] as num).toDouble() - amount;
      to['balanceKwh'] = (to['balanceKwh'] as num).toDouble() + amount;
      final transfer = <String, Object>{
        'id': 'SE-FIXTURE',
        'fromMeterId': from['id']!,
        'fromMeterName': from['name']!,
        'fromMeterNumber': from['number']!,
        'toMeterId': to['id']!,
        'toMeterName': to['name']!,
        'toMeterNumber': to['number']!,
        'amountKwh': amount,
        'createdAt': DateTime(2026, 10, 6).toIso8601String(),
      };
      transfers.insert(0, transfer);
      return _jsonResponse({
        'data': {
          'transfer': transfer,
          'meters': [from, to],
        },
      }, statusCode: 201);
    }
    return _jsonResponse({
      'message': 'Unexpected request: $path',
    }, statusCode: 404);
  }

  http.Response _jsonResponse(
    Map<String, Object?> payload, {
    int statusCode = 200,
  }) => http.Response(
    jsonEncode(payload),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  Future<({EnergyApiClient api, _MemorySessionStorage storage})> pumpApp(
    WidgetTester tester,
    _EnergyApiFixture fixture,
  ) async {
    final api = EnergyApiClient(
      baseUrl: 'http://test/api',
      client: MockClient(fixture.handle),
    );
    final storage = _MemorySessionStorage();
    addTearDown(api.close);
    await tester.pumpWidget(SmartEnergyApp(api: api, sessionStorage: storage));
    await tester.pumpAndSettle();
    return (api: api, storage: storage);
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'asha@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
  }

  testWidgets('sign in loads meters and account data from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, _EnergyApiFixture());
    expect(find.text('Welcome back'), findsOneWidget);
    await signIn(tester);

    expect(find.text('Welcome, Asha'), findsOneWidget);
    expect(find.text('200.7'), findsOneWidget);
    expect(find.text('No data yet'), findsOneWidget);
    await tester.tap(find.text('Meters').last);
    await tester.pumpAndSettle();
    expect(find.text('Home').first, findsOneWidget);
    expect(find.text('Awaiting connection'), findsNWidgets(2));
  });

  testWidgets('new user can register through the Laravel API', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fixture = _EnergyApiFixture()..meters.clear();
    await pumpApp(tester, fixture);
    await tester.tap(find.text('New to Smart Energy? Create account'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('auth-name')), 'Asha Mushi');
    await tester.enterText(
      find.byKey(const Key('auth-email')),
      'asha@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('auth-password')),
      'password123',
    );
    await tester.enterText(
      find.byKey(const Key('auth-confirm-password')),
      'password123',
    );
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome, Asha'), findsOneWidget);
    expect(find.text('0.0'), findsOneWidget);
  });

  testWidgets('account can add a meter using the API', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, _EnergyApiFixture());
    await signIn(tester);
    await tester.tap(find.text('Meters').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add a meter'));
    await tester.tap(find.text('Add a meter'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Studio');
    await tester.enterText(fields.at(1), '0100 444 555');
    await tester.enterText(fields.at(2), '35');
    await tester.tap(find.text('Add meter'));
    await tester.pumpAndSettle();

    expect(find.text('Studio'), findsOneWidget);
    expect(find.text('35.0'), findsOneWidget);
  });

  testWidgets('transfer updates balances through the API', (tester) async {
    tester.view.physicalSize = const Size(430, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(tester, _EnergyApiFixture());
    await signIn(tester);
    await tester.tap(find.text('Transfer').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '15');
    await tester.ensureVisible(find.text('Review transfer'));
    await tester.tap(find.text('Review transfer'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm database record'), findsOneWidget);
    expect(
      find.textContaining('No utility meter or TANESCO account'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm transfer'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Transfer record saved to the database. No utility account was changed.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Meters').last);
    await tester.pumpAndSettle();
    expect(find.text('105.5'), findsOneWidget);
    expect(find.text('95.2'), findsOneWidget);
  });
}
