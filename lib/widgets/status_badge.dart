import 'package:flutter/material.dart';
import '../models/team_request.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  const StatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      RequestStatus.pending => (AppColors.warning, 'Pending'),
      RequestStatus.accepted => (AppColors.success, 'Accepted'),
      RequestStatus.rejected => (AppColors.danger, 'Rejected'),
      RequestStatus.cancelled => (AppColors.muted, 'Cancelled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
