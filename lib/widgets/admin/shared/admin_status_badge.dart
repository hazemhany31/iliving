import 'package:flutter/material.dart';
import '../../../models/installment.dart';
import '../../../models/user_profile.dart';
import '../../../theme/app_theme.dart';

enum BadgeType { success, warning, error, info, neutral }

class AdminStatusBadge extends StatelessWidget {
  final String label;
  final BadgeType type;
  final IconData? icon;
  final bool isDense;

  const AdminStatusBadge({
    super.key,
    required this.label,
    this.type = BadgeType.neutral,
    this.icon,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case BadgeType.success:
        bg = AppColors.success.withAlpha(isDark ? 40 : 25);
        fg = AppColors.success;
        border = AppColors.success.withAlpha(isDark ? 80 : 60);
        break;
      case BadgeType.warning:
        bg = AppColors.warning.withAlpha(isDark ? 40 : 25);
        fg = isDark ? AppColors.warning : const Color(0xFFD97706);
        border = AppColors.warning.withAlpha(isDark ? 80 : 60);
        break;
      case BadgeType.error:
        bg = AppColors.error.withAlpha(isDark ? 40 : 25);
        fg = AppColors.error;
        border = AppColors.error.withAlpha(isDark ? 80 : 60);
        break;
      case BadgeType.info:
        bg = AppColors.info.withAlpha(isDark ? 40 : 25);
        fg = AppColors.info;
        border = AppColors.info.withAlpha(isDark ? 80 : 60);
        break;
      case BadgeType.neutral:
        bg = isDark
            ? AppColors.darkCard.withAlpha(180)
            : AppColors.lightCard.withAlpha(200);
        fg = isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary;
        border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
        break;
    }

    final double verticalPadding = isDense ? 2.0 : 4.0;
    final double horizontalPadding = isDense ? 8.0 : 10.0;
    final double fontSize = isDense ? 11.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool isDense;

  const RoleBadge({
    super.key,
    required this.role,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    BadgeType type;
    IconData icon;
    String label;

    switch (role) {
      case UserRole.superAdmin:
        type = BadgeType.error;
        icon = Icons.admin_panel_settings;
        label = 'Super Admin';
        break;
      case UserRole.salesManager:
        type = BadgeType.info;
        icon = Icons.supervisor_account;
        label = 'Sales Manager';
        break;
      case UserRole.broker:
        type = BadgeType.warning;
        icon = Icons.real_estate_agent;
        label = 'Broker / Agent';
        break;
      case UserRole.finance:
        type = BadgeType.success;
        icon = Icons.account_balance;
        label = 'Finance';
        break;
      case UserRole.facilityManager:
        type = BadgeType.info;
        icon = Icons.business;
        label = 'Facility Manager';
        break;
      case UserRole.security:
        type = BadgeType.neutral;
        icon = Icons.security;
        label = 'Security';
        break;
      case UserRole.customer:
        type = BadgeType.neutral;
        icon = Icons.person;
        label = 'Customer';
        break;
    }

    return AdminStatusBadge(
      label: label,
      type: type,
      icon: icon,
      isDense: isDense,
    );
  }
}

class UnitStatusChip extends StatelessWidget {
  final String status;
  final bool isVacant;
  final bool isDense;

  const UnitStatusChip({
    super.key,
    required this.status,
    this.isVacant = true,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    BadgeType type;
    IconData icon;
    String label = status;

    final lower = status.toLowerCase();

    if (lower.contains('avail') || (isVacant && !lower.contains('sold') && !lower.contains('reserv'))) {
      type = BadgeType.success;
      icon = Icons.check_circle_outline;
      if (label.isEmpty) label = 'Available';
    } else if (lower.contains('reserv') || lower.contains('pending') || lower.contains('hold')) {
      type = BadgeType.warning;
      icon = Icons.bookmark_outline;
      if (label.isEmpty) label = 'Reserved';
    } else if (lower.contains('sold') || lower.contains('occup')) {
      type = BadgeType.info;
      icon = Icons.home;
      if (label.isEmpty) label = 'Occupied / Sold';
    } else if (lower.contains('maint') || lower.contains('block')) {
      type = BadgeType.error;
      icon = Icons.build;
      if (label.isEmpty) label = 'Maintenance';
    } else {
      type = BadgeType.neutral;
      icon = Icons.info_outline;
      if (label.isEmpty) label = status.isEmpty ? 'Unknown' : status;
    }

    return AdminStatusBadge(
      label: label,
      type: type,
      icon: icon,
      isDense: isDense,
    );
  }
}

class PaymentStatusChip extends StatelessWidget {
  final InstallmentStatus status;
  final bool isDense;

  const PaymentStatusChip({
    super.key,
    required this.status,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    BadgeType type;
    IconData icon;
    String label;

    switch (status) {
      case InstallmentStatus.pendingApproval:
        type = BadgeType.warning;
        icon = Icons.hourglass_top_rounded;
        label = 'WAITING APPROVAL';
        break;
      case InstallmentStatus.paid:
        type = BadgeType.success;
        icon = Icons.verified;
        label = 'Paid';
        break;
      case InstallmentStatus.partiallyPaid:
        type = BadgeType.warning;
        icon = Icons.donut_large;
        label = 'Partially Paid';
        break;
      case InstallmentStatus.gracePeriod:
        type = BadgeType.warning;
        icon = Icons.hourglass_top;
        label = 'Grace Period';
        break;
      case InstallmentStatus.overdue:
        type = BadgeType.error;
        icon = Icons.error_outline;
        label = 'Overdue';
        break;
      case InstallmentStatus.waived:
        type = BadgeType.info;
        icon = Icons.subtitles_off;
        label = 'Waived';
        break;
      case InstallmentStatus.unpaid:
        type = BadgeType.neutral;
        icon = Icons.circle_outlined;
        label = 'Unpaid';
        break;
    }

    return AdminStatusBadge(
      label: label,
      type: type,
      icon: icon,
      isDense: isDense,
    );
  }
}

class MaintenanceStatusChip extends StatelessWidget {
  final String status;
  final bool isDense;

  const MaintenanceStatusChip({
    super.key,
    required this.status,
    this.isDense = false,
  });

  @override
  Widget build(BuildContext context) {
    BadgeType type;
    IconData icon;
    final lower = status.toLowerCase();

    if (lower.contains('resolve') || lower.contains('complete') || lower.contains('done')) {
      type = BadgeType.success;
      icon = Icons.task_alt;
    } else if (lower.contains('progress') || lower.contains('assign')) {
      type = BadgeType.warning;
      icon = Icons.engineering;
    } else if (lower.contains('escalat') || lower.contains('urgent') || lower.contains('cancel')) {
      type = BadgeType.error;
      icon = Icons.warning_amber;
    } else {
      type = BadgeType.neutral;
      icon = Icons.pending_actions;
    }

    return AdminStatusBadge(
      label: status.isEmpty ? 'Pending' : status,
      type: type,
      icon: icon,
      isDense: isDense,
    );
  }
}
