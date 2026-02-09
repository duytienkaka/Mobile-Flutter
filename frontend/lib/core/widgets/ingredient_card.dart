import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class IngredientCard extends StatelessWidget {
  final String name;
  final String quantity;
  final String expiry;
  final String status;
  final bool isExpired;
  final bool isWarning;

  const IngredientCard({
    super.key,
    required this.name,
    required this.quantity,
    required this.expiry,
    required this.status,
    this.isExpired = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool showBadge = isExpired || isWarning;
    Color badgeColor = AppColors.textMuted;
    if (isExpired) badgeColor = AppColors.danger;
    if (!isExpired && isWarning) badgeColor = AppColors.warning;

    final statusColor = isExpired
        ? AppColors.danger
        : (isWarning ? AppColors.warning : AppColors.textPrimary);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.black, width: 3.5),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9EA4C7),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            quantity,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 96,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            expiry,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF9EA4C7),
                            ),
                          ),
                          const Spacer(),
                          if (status.isNotEmpty)
                            Text(
                              status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.black,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Center(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showBadge)
          Positioned(
            right: -4,
            top: -6,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
