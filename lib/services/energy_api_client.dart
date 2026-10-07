import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/energy_transfer.dart';
import '../models/meter.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.name,
    required this.email,
  });

  final String token;
  final String name;
  final String email;
}

class RecordedTransfer {
  const RecordedTransfer({required this.transfer, required this.meters});

  final EnergyTransfer transfer;
  final List<Meter> meters;
}

class EnergyApiClient {
  EnergyApiClient({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment(
    'SMART_ENERGY_API_URL',
  );
  static final _defaultBaseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kIsWeb
      ? 'http://127.0.0.1:8000/api'
      : defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000/api'
      : 'http://127.0.0.1:8000/api';

  final String baseUrl;
  final http.Client _client;
  String? _token;

  void setToken(String? token) => _token = token;

  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final data = await _send(
      'POST',
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      authenticated: false,
    );
    return _authSession(data);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _send(
      'POST',
      '/login',
      body: {'email': email, 'password': password},
      authenticated: false,
    );
    return _authSession(data);
  }

  Future<AuthSession> verifySession(String token) async {
    final data = await _send('GET', '/user', token: token);
    return AuthSession(
      token: token,
      name: data['name'] as String,
      email: data['email'] as String,
    );
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/logout');
    } finally {
      _token = null;
    }
  }

  Future<({List<Meter> meters, List<EnergyTransfer> transfers})>
  loadDashboard() async {
    final data = await _send('GET', '/dashboard');
    final meters = (data['meters'] as List<dynamic>)
        .map((item) => Meter.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    final transfers = (data['transfers'] as List<dynamic>)
        .map((item) => EnergyTransfer.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return (meters: meters, transfers: transfers);
  }

  Future<Meter> createMeter(Meter meter) async {
    final data = await _send(
      'POST',
      '/meters',
      body: {
        'name': meter.name,
        'number': meter.number,
        'kind': meter.kind.name,
        'balanceKwh': meter.balanceKwh,
      },
    );
    return Meter.fromJson(data);
  }

  Future<RecordedTransfer> createTransfer({
    required String fromMeterId,
    required String toMeterId,
    required double amountKwh,
  }) async {
    final data = await _send(
      'POST',
      '/transfers',
      body: {
        'fromMeterId': int.parse(fromMeterId),
        'toMeterId': int.parse(toMeterId),
        'amountKwh': amountKwh,
      },
    );
    final meters = (data['meters'] as List<dynamic>)
        .map((item) => Meter.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
    return RecordedTransfer(
      transfer: EnergyTransfer.fromJson(
        data['transfer'] as Map<String, dynamic>,
      ),
      meters: meters,
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, Object?>? body,
    String? token,
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    final authToken = token ?? _token;
    if (authenticated && authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }

    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      final payload = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errors = payload['errors'];
        final message = errors is Map
            ? errors.values
                  .whereType<List<dynamic>>()
                  .expand((messages) => messages)
                  .join('\n')
            : payload['message'] as String? ?? 'The server request failed.';
        throw ApiException(message, statusCode: response.statusCode);
      }
      final data = payload['data'];
      return data is Map<String, dynamic> ? data : payload;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Check your connection and try again.',
      );
    } on http.ClientException {
      throw ApiException(
        'Could not connect to the server at $baseUrl. Check the API URL and network connection.',
      );
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    }
  }

  AuthSession _authSession(Map<String, dynamic> data) {
    final user = data['user'] as Map<String, dynamic>;
    final token = data['token'] as String;
    _token = token;
    return AuthSession(
      token: token,
      name: user['name'] as String,
      email: user['email'] as String,
    );
  }

  void close() => _client.close();
}
