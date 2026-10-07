import 'package:flutter/material.dart';

import '../models/meter.dart';
import '../theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.meters,
    required this.todayUsageKwh,
    super.key,
  });

  final List<Meter> meters;
  final double? todayUsageKwh;

  @override
  Widget build(BuildContext context) {
    final totalBalance = meters.fold<double>(
      0,
      (total, meter) => total + meter.balanceKwh,
    );
    return Container(
      padding: const EdgeInsets.all(21),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1877D2), AppColors.navy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.19),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'TOTAL AVAILABLE UNITS',
                  style: TextStyle(
                    color: Color(0xFFD3E5F8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 7, color: Color(0xFF58D69A)),
                    const SizedBox(width: 5),
                    Text(
                      '${meters.length} meters tracked',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                totalBalance.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 39,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 4),
                child: Text(
                  'kWh',
                  style: TextStyle(color: Color(0xFFD3E5F8), fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 13),
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFD166),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  todayUsageKwh == null ? 'Usage readings' : 'Today’s usage',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFD3E5F8),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                todayUsageKwh == null
                    ? 'No data yet'
                    : '${todayUsageKwh!.toStringAsFixed(1)} kWh',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
