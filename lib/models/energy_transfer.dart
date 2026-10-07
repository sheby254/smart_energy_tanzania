import 'dart:convert';

class EnergyTransfer {
  const EnergyTransfer({
    required this.id,
    required this.fromMeterId,
    required this.fromMeterName,
    required this.fromMeterNumber,
    required this.toMeterId,
    required this.toMeterName,
    required this.toMeterNumber,
    required this.amountKwh,
    required this.createdAt,
  });

  final String id;
  final String fromMeterId;
  final String fromMeterName;
  final String fromMeterNumber;
  final String toMeterId;
  final String toMeterName;
  final String toMeterNumber;
  final double amountKwh;
  final DateTime createdAt;

  String get formattedAmount => amountKwh.toStringAsFixed(1);

  Map<String, Object> toJson() => {
    'id': id,
    'fromMeterId': fromMeterId,
    'fromMeterName': fromMeterName,
    'fromMeterNumber': fromMeterNumber,
    'toMeterId': toMeterId,
    'toMeterName': toMeterName,
    'toMeterNumber': toMeterNumber,
    'amountKwh': amountKwh,
    'createdAt': createdAt.toIso8601String(),
  };

  factory EnergyTransfer.fromJson(Map<String, dynamic> json) => EnergyTransfer(
    id: json['id'] as String,
    fromMeterId: json['fromMeterId'] as String,
    fromMeterName: json['fromMeterName'] as String,
    fromMeterNumber: json['fromMeterNumber'] as String,
    toMeterId: json['toMeterId'] as String,
    toMeterName: json['toMeterName'] as String,
    toMeterNumber: json['toMeterNumber'] as String,
    amountKwh: (json['amountKwh'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  static List<EnergyTransfer> decodeList(String value) {
    final data = jsonDecode(value) as List<dynamic>;
    return data
        .map((item) => EnergyTransfer.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}
