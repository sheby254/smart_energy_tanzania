import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class UsageTrendCard extends StatelessWidget {
  const UsageTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Usage trends',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NO READINGS',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 74,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    color: AppColors.muted,
                    size: 25,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Usage history will appear when readings are available',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          const Text(
            'Live readings are not connected yet.',
            style: TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
