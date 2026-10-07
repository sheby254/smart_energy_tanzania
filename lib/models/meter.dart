import 'dart:convert';

enum MeterKind { home, business }

enum MeterStatus { connected, disconnected, pending }

class Meter {
  const Meter({
    required this.id,
    required this.name,
    required this.number,
    required this.balanceKwh,
    required this.kind,
    required this.status,
    required this.lastUpdated,
  });

  final String id;
  final String name;
  final String number;
  final double balanceKwh;
  final MeterKind kind;
  final MeterStatus status;
  final String lastUpdated;

  String get formattedBalance => balanceKwh.toStringAsFixed(1);

  String get statusLabel =>
      switch (status) {
        MeterStatus.connected => 'Connected',
        MeterStatus.disconnected => 'Disconnected',
        MeterStatus.pending => 'Awaiting connection',
      };

  String get statusDescription {
    if (status != MeterStatus.connected) return statusLabel;
    return '$statusLabel · updated $lastUpdated';
  }

  String get transferLabel => '$name · $formattedBalance kWh';

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'balanceKwh': balanceKwh,
    'kind': kind.name,
    'status': status.name,
    'lastUpdated': lastUpdated,
  };

  factory Meter.fromJson(Map<String, dynamic> json) => Meter(
    id: json['id'] as String,
    name: json['name'] as String,
    number: json['number'] as String,
    balanceKwh: (json['balanceKwh'] as num).toDouble(),
    kind: MeterKind.values.byName(json['kind'] as String),
    status: MeterStatus.values.byName(json['status'] as String),
    lastUpdated: json['lastUpdated'] as String,
  );

  static List<Meter> decodeList(String value) {
    final data = jsonDecode(value) as List<dynamic>;
    return data
        .map((item) => Meter.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
