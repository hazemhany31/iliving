import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/luxury_theme.dart';
import '../widgets/interactive_tap_bounce.dart';
import '../widgets/luxury_shimmer.dart';

class ElectricityPaymentScreen extends StatefulWidget {
  const ElectricityPaymentScreen({super.key});

  @override
  State<ElectricityPaymentScreen> createState() => _ElectricityPaymentScreenState();
}

class _ElectricityPaymentScreenState extends State<ElectricityPaymentScreen>
    with TickerProviderStateMixin {
  final TextEditingController _meterController = TextEditingController();
  int _selectedCompanyIndex = -1;
  bool _isLoading = false;
  bool _hasBillResult = false;
  Map<String, dynamic>? _currentBill;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<Map<String, String>> _companies = const [
    {'name': 'شمال القاهرة', 'en': 'NORTH CAIRO', 'code': 'NCED'},
    {'name': 'جنوب القاهرة', 'en': 'SOUTH CAIRO', 'code': 'SCED'},
    {'name': 'الإسكندرية', 'en': 'ALEXANDRIA', 'code': 'AEDC'},
    {'name': 'القناة', 'en': 'CANAL', 'code': 'CEDC'},
    {'name': 'شمال الدلتا', 'en': 'N. DELTA', 'code': 'NDED'},
    {'name': 'جنوب الدلتا', 'en': 'S. DELTA', 'code': 'SDED'},
    {'name': 'البحيرة', 'en': 'BEHEIRA', 'code': 'BEDC'},
    {'name': 'شمال الصعيد', 'en': 'N. UPPER', 'code': 'NUED'},
    {'name': 'جنوب الصعيد', 'en': 'S. UPPER', 'code': 'SUED'},
  ];

  static final Map<String, Map<String, dynamic>> _mockBillsDb = {
    '01234567890': {
      'meterNumber': '01234567890',
      'accountHolder': 'أحمد محمد حسن',
      'address': 'شارع التحرير، الدقي، الجيزة',
      'company': 'SCED',
      'companyNameAr': 'جنوب القاهرة',
      'previousReading': 45230,
      'currentReading': 45890,
      'consumptionKwh': 660,
      'amountDue': 485.50,
      'dueDate': '2026-07-15',
      'billMonth': 'يونيو 2026',
      'status': 'unpaid',
      'meterType': 'عداد تقليدي',
      'tariffCategory': 'سكني',
      'history': [
        {'month': 'مايو 2026', 'amount': 420.00, 'status': 'paid', 'consumption': 580},
        {'month': 'أبريل 2026', 'amount': 390.75, 'status': 'paid', 'consumption': 540},
        {'month': 'مارس 2026', 'amount': 350.00, 'status': 'paid', 'consumption': 490},
        {'month': 'فبراير 2026', 'amount': 310.25, 'status': 'paid', 'consumption': 430},
        {'month': 'يناير 2026', 'amount': 445.00, 'status': 'paid', 'consumption': 620},
        {'month': 'ديسمبر 2025', 'amount': 520.50, 'status': 'paid', 'consumption': 720},
      ],
    },
    '09876543210': {
      'meterNumber': '09876543210',
      'accountHolder': 'محمد عبد الرحمن',
      'address': 'المعادي، القاهرة',
      'company': 'SCED',
      'companyNameAr': 'جنوب القاهرة',
      'previousReading': 12400,
      'currentReading': 13150,
      'consumptionKwh': 750,
      'amountDue': 620.00,
      'dueDate': '2026-07-20',
      'billMonth': 'يونيو 2026',
      'status': 'unpaid',
      'meterType': 'عداد مسبوق الدفع',
      'tariffCategory': 'سكني',
      'history': [
        {'month': 'مايو 2026', 'amount': 580.00, 'status': 'paid', 'consumption': 700},
        {'month': 'أبريل 2026', 'amount': 510.00, 'status': 'paid', 'consumption': 620},
        {'month': 'مارس 2026', 'amount': 470.00, 'status': 'paid', 'consumption': 570},
      ],
    },
    '11223344556': {
      'meterNumber': '11223344556',
      'accountHolder': 'فاطمة علي إبراهيم',
      'address': 'مدينة نصر، القاهرة',
      'company': 'NCED',
      'companyNameAr': 'شمال القاهرة',
      'previousReading': 88900,
      'currentReading': 89750,
      'consumptionKwh': 850,
      'amountDue': 1250.75,
      'dueDate': '2026-07-10',
      'billMonth': 'يونيو 2026',
      'status': 'overdue',
      'meterType': 'عداد تقليدي',
      'tariffCategory': 'تجاري',
      'history': [
        {'month': 'مايو 2026', 'amount': 1100.00, 'status': 'paid', 'consumption': 780},
        {'month': 'أبريل 2026', 'amount': 980.50, 'status': 'paid', 'consumption': 700},
        {'month': 'مارس 2026', 'amount': 1050.00, 'status': 'paid', 'consumption': 740},
        {'month': 'فبراير 2026', 'amount': 920.00, 'status': 'paid', 'consumption': 650},
      ],
    },
    '55667788990': {
      'meterNumber': '55667788990',
      'accountHolder': 'عمر خالد السيد',
      'address': 'أكتوبر الجديدة، الجيزة',
      'company': 'SCED',
      'companyNameAr': 'جنوب القاهرة',
      'previousReading': 5600,
      'currentReading': 5980,
      'consumptionKwh': 380,
      'amountDue': 0.0,
      'dueDate': '2026-06-15',
      'billMonth': 'يونيو 2026',
      'status': 'paid',
      'meterType': 'عداد ذكي',
      'tariffCategory': 'سكني',
      'history': [
        {'month': 'يونيو 2026', 'amount': 265.00, 'status': 'paid', 'consumption': 380},
        {'month': 'مايو 2026', 'amount': 230.00, 'status': 'paid', 'consumption': 340},
        {'month': 'أبريل 2026', 'amount': 200.00, 'status': 'paid', 'consumption': 290},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _meterController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _lookupBill() {
    final meter = _meterController.text.trim();
    if (meter.length < 10) {
      _showErrorDialog('رقم عداد غير صحيح', 'من فضلك أدخل رقم العداد الصحيح (10-11 رقم).\nPlease enter a valid meter number (10-11 digits).');
      return;
    }
    if (_selectedCompanyIndex < 0) {
      _showErrorDialog('اختر شركة التوزيع', 'من فضلك اختر شركة توزيع الكهرباء بتاعتك.\nPlease select your electricity distribution company.');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasBillResult = false;
      _currentBill = null;
    });

    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      final bill = _mockBillsDb[meter];
      setState(() {
        _isLoading = false;
        if (bill != null) {
          _currentBill = Map<String, dynamic>.from(bill);
          _hasBillResult = true;
        } else {
          _currentBill = _generateRandomBill(meter);
          _hasBillResult = true;
        }
      });
    });
  }

  Map<String, dynamic> _generateRandomBill(String meter) {
    final company = _companies[_selectedCompanyIndex];
    final consumption = 300 + (meter.hashCode.abs() % 800);
    final amount = consumption * 0.68 + 50;
    return {
      'meterNumber': meter,
      'accountHolder': 'عميل رقم ${meter.substring(0, 5)}',
      'address': 'عنوان مسجل بقاعدة بيانات ${company['name']}',
      'company': company['code'],
      'companyNameAr': company['name'],
      'previousReading': 10000 + (meter.hashCode.abs() % 90000),
      'currentReading': 10000 + (meter.hashCode.abs() % 90000) + consumption,
      'consumptionKwh': consumption,
      'amountDue': double.parse(amount.toStringAsFixed(2)),
      'dueDate': '2026-07-25',
      'billMonth': 'يونيو 2026',
      'status': 'unpaid',
      'meterType': 'عداد تقليدي',
      'tariffCategory': 'سكني',
      'history': [
        {'month': 'مايو 2026', 'amount': amount * 0.9, 'status': 'paid', 'consumption': (consumption * 0.85).round()},
        {'month': 'أبريل 2026', 'amount': amount * 0.8, 'status': 'paid', 'consumption': (consumption * 0.75).round()},
      ],
    };
  }

  void _showErrorDialog(String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: AppBorderRadius.large,
        ),
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.error,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          subtitle,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final iconColor = isDark ? AppColors.textLight : AppColors.textDark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: iconColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.electric_bolt_rounded, color: AppColors.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              'دفع فاتورة الكهرباء',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderBanner(isDark),
            const SizedBox(height: 20),
            _buildSectionLabel('⚡ اختر شركة توزيع الكهرباء', 'SELECT DISTRIBUTION COMPANY', isDark),
            const SizedBox(height: 10),
            _buildCompanyGrid(isDark),
            const SizedBox(height: 20),
            _buildSectionLabel('🔢 رقم العداد', 'ENTER METER NUMBER', isDark),
            const SizedBox(height: 10),
            _buildMeterInput(isDark),
            const SizedBox(height: 20),
            _buildInquiryButton(isDark),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              _buildLoadingShimmer(isDark),
            ],
            if (_hasBillResult && _currentBill != null) ...[
              const SizedBox(height: 24),
              _buildBillResultCard(isDark),
              const SizedBox(height: 24),
              _buildSectionLabel('📋 سجل الفواتير السابقة', 'PAYMENT HISTORY', isDark),
              const SizedBox(height: 10),
              _buildPaymentHistory(isDark),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withAlpha(isDark ? 35 : 18),
                  ),
                  child: const Icon(Icons.electric_bolt_rounded, color: AppColors.accent, size: 24),
                ),
              );
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خدمة دفع فواتير الكهرباء',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ادفع فاتورة الكهرباء بتاعتك عن طريق رقم العداد\nEgypt Electricity Bill Payment',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    color: textMuted,
                    fontSize: 9.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String ar, String en, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ar,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          en,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            color: textMuted,
            fontSize: 8.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyGrid(bool isDark) {
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _companies.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemBuilder: (context, index) {
        final company = _companies[index];
        final isSelected = _selectedCompanyIndex == index;

        return InteractiveTapBounce(
          onTap: () {
            setState(() {
              _selectedCompanyIndex = index;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark ? AppColors.accent : AppColors.primary)
                  : cardBg,
              borderRadius: AppBorderRadius.medium,
              boxShadow: isSelected
                  ? (isDark ? AppShadows.darkElevated : AppShadows.elevated)
                  : (isDark ? AppShadows.darkSoft : AppShadows.soft),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.electric_bolt_rounded,
                  color: isSelected ? Colors.white : AppColors.accent,
                  size: 18,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    company['name']!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    company['en']!,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: isSelected ? Colors.white70 : textMuted,
                      fontSize: 6.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeterInput(bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(isDark ? 35 : 18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.electric_meter_rounded, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _meterController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
              ],
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
              decoration: InputDecoration(
                hintText: 'أدخل رقم العداد هنا...',
                hintStyle: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _lookupBill,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.accent : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.pill,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isLoading ? Icons.hourglass_top_rounded : Icons.search_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _isLoading ? 'جاري الاستعلام...' : 'استعلام عن الفاتورة',
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: AppBorderRadius.large,
          ),
          child: const LuxuryShimmer(width: double.infinity, height: 200),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 60),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 60),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: AppBorderRadius.medium,
              ),
              child: const LuxuryShimmer(width: double.infinity, height: 60),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildBillResultCard(bool isDark) {
    final bill = _currentBill!;
    final status = bill['status'] as String;
    final isOverdue = status == 'overdue';
    final isPaid = status == 'paid';
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    Color statusColor = isPaid ? AppColors.success : (isOverdue ? AppColors.error : AppColors.warning);
    String statusText = isPaid ? 'مسدد ✅' : (isOverdue ? 'متأخر ⚠️' : 'غير مسدد');
    String statusEn = isPaid ? 'PAID' : (isOverdue ? 'OVERDUE' : 'UNPAID');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppBorderRadius.large,
        boxShadow: isDark ? AppShadows.darkElevated : AppShadows.elevated,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(isDark ? 30 : 15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: statusColor, size: 22),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بيانات الفاتورة',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textColor,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'BILL DETAILS — ${bill['billMonth']}',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            color: textMuted,
                            fontSize: 7.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: AppBorderRadius.pill,
                  ),
                  child: Column(
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: statusColor,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        statusEn,
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: statusColor.withAlpha(180),
                          fontSize: 6.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBillRow('اسم صاحب العداد', bill['accountHolder'], Icons.person_outline_rounded, isDark),
                _buildBillRow('رقم العداد', bill['meterNumber'], Icons.electric_meter_outlined, isDark),
                _buildBillRow('العنوان', bill['address'], Icons.location_on_outlined, isDark),
                _buildBillRow('شركة التوزيع', bill['companyNameAr'], Icons.business_outlined, isDark),
                _buildBillRow('نوع العداد', bill['meterType'], Icons.settings_outlined, isDark),
                _buildBillRow('الشريحة', bill['tariffCategory'], Icons.category_outlined, isDark),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, height: 20),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.15,
                  children: [
                    _buildMetricCard('القراءة السابقة', '${bill['previousReading']}', 'PREV', Icons.speed_rounded, textMuted, isDark),
                    _buildMetricCard('القراءة الحالية', '${bill['currentReading']}', 'CURR', Icons.speed_rounded, AppColors.accent, isDark),
                    _buildMetricCard('الاستهلاك', '${bill['consumptionKwh']} ك.و.س', 'KWH', Icons.bolt_rounded, AppColors.warning, isDark),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
                    borderRadius: AppBorderRadius.medium,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'المبلغ المستحق',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: textMuted,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'استحقاق: ${bill['dueDate']}',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              color: isOverdue ? AppColors.error : textMuted,
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        isPaid ? 'مسدد' : '${(bill['amountDue'] as double).toStringAsFixed(2)} ج.م',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          color: isPaid ? AppColors.success : AppColors.accent,
                          fontSize: isPaid ? 16 : 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(String label, String value, IconData icon, bool isDark) {
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textColor,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String labelAr, String value, String labelEn, IconData icon, Color color, bool isDark) {
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardAlt : AppColors.lightCardAlt,
        borderRadius: AppBorderRadius.medium,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              labelAr,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                color: textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(bool isDark) {
    final history = (_currentBill!['history'] as List?) ?? [];
    final textColor = isDark ? AppColors.textLight : AppColors.textDark;
    final textMuted = isDark ? AppColors.textLightMuted : AppColors.textDarkMuted;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;

    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppBorderRadius.medium,
          boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
        ),
        child: Center(
          child: Text(
            'لا يوجد سجل فواتير سابقة',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              color: textMuted,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: history.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final item = history[index] as Map<String, dynamic>;
        final isPaid = item['status'] == 'paid';

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppBorderRadius.medium,
            boxShadow: isDark ? AppShadows.darkSoft : AppShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: isPaid ? AppColors.success : AppColors.error,
                    size: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPaid ? AppColors.success : AppColors.error).withAlpha(25),
                      borderRadius: AppBorderRadius.pill,
                    ),
                    child: Text(
                      isPaid ? 'مسدد' : 'معلق',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        color: isPaid ? AppColors.success : AppColors.error,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['month'] ?? '',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${(item['amount'] as num).toStringAsFixed(0)} ج.م',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: AppColors.accent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '${item['consumption']} ك.و.س',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: textMuted,
                      fontSize: 7.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
