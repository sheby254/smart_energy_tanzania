import 'package:flutter_test/flutter_test.dart';
import 'package:smart_energy_tanzania/models/meter.dart';

void main() {
  group('Meter', () {
    test('formats balance and transfer label from meter data', () {
      const meter = Meter(
        id: 'home-1',
        name: 'Home',
        number: '0100 234 567',
        balanceKwh: 120.5,
        kind: MeterKind.home,
        status: MeterStatus.pending,
        lastUpdated: 'awaiting meter connection',
      );

      expect(meter.formattedBalance, '120.5');
      expect(meter.transferLabel, 'Home · 120.5 kWh');
      expect(Meter.fromJson(meter.toJson()).toJson(), meter.toJson());
    });

    test('describes connected and disconnected status', () {
      const connected = Meter(
        id: 'home-1',
        name: 'Home',
        number: '0100 234 567',
        balanceKwh: 120.5,
        kind: MeterKind.home,
        status: MeterStatus.connected,
        lastUpdated: '10 min ago',
      );
      const disconnected = Meter(
        id: 'shop-1',
        name: 'Shop',
        number: '0100 111 222',
        balanceKwh: 12,
        kind: MeterKind.business,
        status: MeterStatus.disconnected,
        lastUpdated: '1 hour ago',
      );

      expect(connected.statusLabel, 'Connected');
      expect(connected.statusDescription, 'Connected · updated 10 min ago');
      expect(disconnected.statusLabel, 'Disconnected');
      expect(disconnected.statusDescription, 'Disconnected');
    });
  });
}
