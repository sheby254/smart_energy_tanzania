import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy_tanzania/models/energy_transfer.dart';
import 'package:smart_energy_tanzania/services/transfer_ticket_service.dart';

void main() {
  test('builds a PDF ticket with a PDF document header', () async {
    final transfer = EnergyTransfer(
      id: 'SE-test-001',
      fromMeterId: 'home-1',
      fromMeterName: 'Home',
      fromMeterNumber: '0100 234 567',
      toMeterId: 'office-1',
      toMeterName: 'Office',
      toMeterNumber: '0100 987 654',
      amountKwh: 15,
      createdAt: DateTime(2026, 10, 6, 9, 30),
    );

    final bytes = await const TransferTicketService().buildTicket(transfer);

    expect(utf8.decode(bytes.take(8).toList()), startsWith('%PDF-'));
    expect(bytes.length, greaterThan(500));
  });
}
