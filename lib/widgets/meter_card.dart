import 'package:flutter/material.dart';

import '../models/meter.dart';
import '../theme/app_theme.dart';

class MeterCard extends StatelessWidget {
  const MeterCard({
    required this.meter,
    this.showLastUpdated = true,
    super.key,
  });

  final Meter meter;
  final bool showLastUpdated;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (meter.status) {
      MeterStatus.connected => AppColors.green,
      MeterStatus.disconnected => AppColors.muted,
      MeterStatus.pending => AppColors.amber,
    };
    final icon = switch (meter.kind) {
      MeterKind.home => Icons.home_rounded,
      MeterKind.business => Icons.storefront_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FB),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.blue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meter.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  meter.number,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: statusColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        showLastUpdated
                            ? meter.statusDescription
                            : meter.statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                meter.formattedBalance,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'kWh',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
