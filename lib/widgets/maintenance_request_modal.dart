import 'package:flutter/material.dart';
import '../models/maintenance_request.dart';
import '../models/unit_model.dart';
import '../models/user_profile.dart';
import '../repositories/interfaces/maintenance_repository.dart';
import '../repositories/firestore/firestore_maintenance_repository.dart';
import '../theme/luxury_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/maintenance_validator.dart';
import 'interactive_tap_bounce.dart';

class MaintenanceRequestModal extends StatefulWidget {
  final Unit unit;
  final String trade;
  final String compoundTitle;
  final UserProfile? assignedCustomer;
  final MaintenanceRepository? maintRepo;
  final ValueChanged<MaintenanceRequest>? onTicketCreated;

  const MaintenanceRequestModal({
    super.key,
    required this.unit,
    required this.trade,
    this.compoundTitle = 'Sky Hills',
    this.assignedCustomer,
    this.maintRepo,
    this.onTicketCreated,
  });

  static Future<MaintenanceRequest?> show({
    required BuildContext context,
    required Unit unit,
    required String trade,
    String compoundTitle = 'Sky Hills',
    UserProfile? assignedCustomer,
    MaintenanceRepository? maintRepo,
    ValueChanged<MaintenanceRequest>? onTicketCreated,
  }) {
    return showModalBottomSheet<MaintenanceRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MaintenanceRequestModal(
        unit: unit,
        trade: trade,
        compoundTitle: compoundTitle,
        assignedCustomer: assignedCustomer,
        maintRepo: maintRepo,
        onTicketCreated: onTicketCreated,
      ),
    );
  }

  @override
  State<MaintenanceRequestModal> createState() => MaintenanceRequestModalState();
}

class MaintenanceRequestModalState extends State<MaintenanceRequestModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descController;
  late final MaintenanceRepository _maintRepo;

  String _priority = 'Medium';
  bool _isSubmitting = false;
  String? _submitErrorMessage;

  final _titleShakeKey = GlobalKey<_ShakeWidgetState>();
  final _descShakeKey = GlobalKey<_ShakeWidgetState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: '${widget.trade} Maintenance Request');
    descController = TextEditingController();
    _maintRepo = widget.maintRepo ?? FirestoreMaintenanceRepository();
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_isSubmitting) return;

    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final titleErr = MaintenanceValidator.validateTitle(titleController.text, isAr: isAr);
    final descErr = MaintenanceValidator.validateDescription(descController.text, isAr: isAr);

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || titleErr != null || descErr != null) {
      if (titleErr != null) {
        _titleShakeKey.currentState?.shake();
      }
      if (descErr != null) {
        _descShakeKey.currentState?.shake();
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitErrorMessage = null;
    });

    try {
      final tradeLower = widget.trade.toLowerCase();
      final category = tradeLower.contains('plumb') || tradeLower.contains('water') || tradeLower.contains('drain')
          ? MaintenanceCategory.plumbing
          : tradeLower.contains('electric')
              ? MaintenanceCategory.electrical
              : MaintenanceCategory.hvac;

      final urgency = _priority == 'Low'
          ? MaintenanceUrgency.low
          : _priority == 'High'
              ? MaintenanceUrgency.high
              : _priority == 'Emergency'
                  ? MaintenanceUrgency.emergency
                  : MaintenanceUrgency.medium;

      final ticketId = 'T-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final newTicket = MaintenanceRequest(
        id: ticketId,
        ticketNumber: ticketId,
        compoundId: widget.unit.compoundId,
        unitId: widget.unit.id,
        residentUserId: widget.assignedCustomer?.uid ?? 'RESIDENT-ADMIN',
        title: titleController.text.trim(),
        description: descController.text.trim(),
        category: category,
        urgency: urgency,
        status: MaintenanceStatus.submitted,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _maintRepo.createTicket(newTicket);

      widget.onTicketCreated?.call(newTicket);

      if (!mounted) return;
      Navigator.of(context).pop(newTicket);
    } catch (e) {
      debugPrint('[MaintenanceRequestModal] Error creating ticket: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submitErrorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardAltBg = isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.build_rounded, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.requestService(widget.trade),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.filingOperationalTicket(widget.unit.unitNumber, widget.compoundTitle),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ShakeWidget(
                key: _titleShakeKey,
                child: TextFormField(
                  controller: titleController,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.ticketTitleLabel,
                    filled: true,
                    fillColor: cardAltBg,
                    border: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  validator: (value) => MaintenanceValidator.validateTitle(value, isAr: isAr),
                ),
              ),
              const SizedBox(height: 12),
              _ShakeWidget(
                key: _descShakeKey,
                child: TextFormField(
                  controller: descController,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 13,
                  ),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.describeServiceRequirements,
                    filled: true,
                    fillColor: cardAltBg,
                    border: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: BorderSide.none,
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: const BorderSide(color: AppColors.error, width: 1.2),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: AppBorderRadius.medium,
                      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                  validator: (value) => MaintenanceValidator.validateDescription(value, isAr: isAr),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.ticketUrgencyPriority,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: ['Low', 'Medium', 'High', 'Emergency'].map((p) {
                  final isSelected = _priority == p;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _priority = p);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : cardAltBg,
                          borderRadius: AppBorderRadius.pill,
                          boxShadow: isSelected
                              ? (isDark ? AppShadows.darkSoft : AppShadows.soft)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          p.toUpperCase(),
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isSelected ? Colors.white : textMuted,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_submitErrorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(isDark ? 40 : 20),
                    borderRadius: AppBorderRadius.medium,
                    border: Border.all(color: AppColors.error.withAlpha(90)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _submitErrorMessage!,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: isDark ? const Color(0xFFFF8A80) : AppColors.error,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              InteractiveTapBounce(
                onTap: _isSubmitting ? null : submit,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? AppColors.accent.withAlpha(150) : AppColors.accent,
                    borderRadius: AppBorderRadius.pill,
                    boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isAr ? 'جاري الإرسال...' : 'Submitting...',
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          l10n.fileServiceRequest,
                          style: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShakeWidget extends StatefulWidget {
  final Widget child;

  const _ShakeWidget({super.key, required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offsetAnimation,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offsetAnimation.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
