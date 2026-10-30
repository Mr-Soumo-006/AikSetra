import '../services/theme_manager.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';

class CalculatorsScreen extends StatefulWidget {
  final String? initialTool;
  const CalculatorsScreen({super.key, this.initialTool});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _tools = [
    {'title': 'Calculator', 'sub': 'Financial Tape', 'icon': Icons.calculate_rounded, 'color': Color(0xFFFF9100)},
    {'title': 'EMI Loan', 'sub': 'Home & Auto', 'icon': Icons.home_work_rounded, 'color': Color(0xFF2563EB)},
    {'title': 'SIP Return', 'sub': 'Mutual Funds', 'icon': Icons.trending_up_rounded, 'color': Color(0xFF046A38)},
    {'title': 'GST Tax', 'sub': '4 Slabs & HSN', 'icon': Icons.receipt_long_rounded, 'color': Color(0xFF7C3AED)},
    {'title': 'Income Tax', 'sub': 'FY 24-25 Regime', 'icon': Icons.account_balance_rounded, 'color': Color(0xFFFF671F)},
    {'title': 'TDS Tax', 'sub': '194C / J / H / I', 'icon': Icons.gavel_rounded, 'color': Color(0xFF0D9488)},
    {'title': 'Currency FX', 'sub': 'Live RBI Rates', 'icon': Icons.currency_exchange_rounded, 'color': Color(0xFF0284C7)},
    {'title': 'FD Maturity', 'sub': 'Quarterly Compound', 'icon': Icons.savings_rounded, 'color': Color(0xFF4338CA)},
    {'title': 'RD Maturity', 'sub': 'Monthly Recurring', 'icon': Icons.sync_alt_rounded, 'color': Color(0xFF059669)},
    {'title': 'Compound', 'sub': 'Exponential Gains', 'icon': Icons.pie_chart_rounded, 'color': Color(0xFFD97706)},
    {'title': 'Inflation', 'sub': 'Purchasing Power', 'icon': Icons.candlestick_chart_rounded, 'color': Color(0xFFDC2626)},
    {'title': 'Goal Plan', 'sub': 'Target Wealth', 'icon': Icons.track_changes_rounded, 'color': Color(0xFFDB2777)},
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTool != null) {
      final match = _tools.indexWhere((t) => (t['title'] as String).toLowerCase().contains(widget.initialTool!.toLowerCase()));
      if (match != -1) initialIndex = match;
    }
    _tabController = TabController(length: _tools.length, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final scaffoldBg = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final currentTool = _tools[_tabController.index];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Calculator Hub',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: -0.3),
            ),
            Text(
              '12 Precision Engines • ${currentTool['title']} (${currentTool['sub']})',
              style: TextStyle(fontSize: 10.5, color: (currentTool['color'] as Color).withValues(alpha: 0.9), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: const Color(0xFF091422),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: currentTool['color'] as Color,
              indicatorWeight: 3.5,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF94A3B8),
              tabs: _tools.map((t) {
                final isSel = _tools.indexOf(t) == _tabController.index;
                final toolColor = t['color'] as Color;
                return Tab(
                  child: Row(
                    children: [
                      Icon(t['icon'] as IconData, size: 16, color: isSel ? toolColor : const Color(0xFF94A3B8)),
                      const SizedBox(width: 6),
                      Text(
                        t['title'] as String,
                        style: TextStyle(
                          fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          NormalCalculatorView(
            onSwitchTool: (index) {
              _tabController.animateTo(index);
            },
          ),
          const EmiCalculatorView(),
          const SipCalculatorView(),
          const GstCalculatorView(),
          const IncomeTaxCalculatorView(),
          const TdsCalculatorView(),
          const FxCalculatorView(),
          const FdCalculatorView(),
          const RdCalculatorView(),
          const CompoundInterestCalculatorView(),
          const InflationCalculatorView(),
          const SavingsGoalCalculatorView(),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE PREMIUM UI COMPONENTS FOR FINANCIAL CALCULATORS
// ============================================================================

Widget _buildResultCard({
  required String title,
  required String primaryValue,
  required List<Map<String, String>> subValues,
  Color accentColor = const Color(0xFF0D1B2A),
  double? ratioPrimary, // Optional 0.0 to 1.0 for visual stacked comparison
  String? ratioLabelPrimary,
  String? ratioLabelSecondary,
}) {
  final isDark = ThemeManager.isDarkMode;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark
            ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
            : [accentColor, const Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(
        color: isDark ? const Color(0xFF334155) : accentColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: accentColor.withValues(alpha: 0.25),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verified Badge Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF34D399)),
                const SizedBox(width: 5),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'RBI / CBDT Rulebook',
                style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Large Primary Readout
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            primaryValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Visual Stacked Progress Bar (if applicable, e.g. Principal vs Interest)
        if (ratioPrimary != null && ratioPrimary > 0 && ratioPrimary < 1) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                Expanded(
                  flex: (ratioPrimary * 100).round().clamp(1, 99),
                  child: Container(
                    height: 8,
                    color: const Color(0xFF10B981), // Emerald
                  ),
                ),
                Expanded(
                  flex: ((1 - ratioPrimary) * 100).round().clamp(1, 99),
                  child: Container(
                    height: 8,
                    color: const Color(0xFFFF9100), // Amber
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${ratioLabelPrimary ?? "Principal"}: ${(ratioPrimary * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              Text(
                '${ratioLabelSecondary ?? "Interest / Gains"}: ${((1 - ratioPrimary) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 10),

        // Subvalue Chips Grid
        ...subValues.map((sv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor == const Color(0xFF0D1B2A) ? const Color(0xFFFF9100) : accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(sv['label']!, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5)),
                    ],
                  ),
                  Text(
                    sv['val']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            )),
      ],
    ),
  );
}

Widget _buildSliderField({
  required String title,
  required double value,
  required double min,
  required double max,
  required double step,
  required String display,
  required ValueChanged<double> onChanged,
  List<double>? presetValues,
  List<String>? presetLabels,
}) {
  final isDark = ThemeManager.isDarkMode;
  final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
  final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
  final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
  final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  return Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cardBg,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: cardBorder, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Stepper Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: textSecondary)),
            Row(
              children: [
                // Decrement Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final nextVal = (value - step).clamp(min, max);
                    onChanged(nextVal);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.remove, size: 14, color: textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  display,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textPrimary),
                ),
                const SizedBox(width: 8),
                // Increment Button
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    final nextVal = (value + step).clamp(min, max);
                    onChanged(nextVal);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add, size: 14, color: textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Slider Bar
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: const Color(0xFFFF671F),
            inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            thumbColor: const Color(0xFFFF9100),
            overlayColor: const Color(0xFFFF671F).withValues(alpha: 0.15),
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),

        // Min & Max Range Labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Min: ${min >= 100000 ? "₹${(min/100000).toStringAsFixed(0)}L" : min.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: textSecondary)),
              Text('Max: ${max >= 10000000 ? "₹${(max/10000000).toStringAsFixed(0)}Cr" : (max >= 100000 ? "₹${(max/100000).toStringAsFixed(0)}L" : max.toStringAsFixed(0))}', style: TextStyle(fontSize: 10, color: textSecondary)),
            ],
          ),
        ),

        // Quick Preset Chips (if provided)
        if (presetValues != null && presetValues.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(presetValues.length, (idx) {
                final pVal = presetValues[idx];
                final pLbl = presetLabels != null && idx < presetLabels.length ? presetLabels[idx] : pVal.toString();
                final isSelected = (value - pVal).abs() < (step / 2.0);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onChanged(pVal);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF671F) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF671F) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                        ),
                      ),
                      child: Text(
                        pLbl,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    ),
  );
}

// ============================================================================
// 0. NORMAL / STANDARD FINANCIAL CALCULATOR (LUXURY FINTECH DESIGN)
// ============================================================================
class NormalCalculatorView extends StatefulWidget {
  final ValueChanged<int> onSwitchTool;
  const NormalCalculatorView({super.key, required this.onSwitchTool});

  @override
  State<NormalCalculatorView> createState() => _NormalCalculatorViewState();
}

class _NormalCalculatorViewState extends State<NormalCalculatorView> {
  String _expression = '';
  String _display = '0';
  String? _gstBreakdown;
  bool _shouldResetOnNextDigit = false;
  final List<String> _history = [];
  bool _showHistory = false;
  double _memory = 0.0;

  void _onDigit(String d) {
    HapticFeedback.selectionClick();
    setState(() {
      _gstBreakdown = null;
      if (_display == '0' || _shouldResetOnNextDigit) {
        _display = d;
        _shouldResetOnNextDigit = false;
      } else {
        _display += d;
      }
    });
  }

  void _onDecimal() {
    HapticFeedback.selectionClick();
    setState(() {
      _gstBreakdown = null;
      if (_shouldResetOnNextDigit) {
        _display = '0.';
        _shouldResetOnNextDigit = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onOperator(String op) {
    HapticFeedback.lightImpact();
    setState(() {
      _gstBreakdown = null;
      if (_expression.endsWith('=') || _shouldResetOnNextDigit) {
        _expression = '$_display $op ';
        _shouldResetOnNextDigit = false;
      } else if (_expression.isNotEmpty && '+−×÷'.contains(_expression.trim().split(' ').last) && _display == '0') {
        final parts = _expression.trim().split(' ');
        parts[parts.length - 1] = op;
        _expression = '${parts.join(' ')} ';
      } else {
        _expression += '$_display $op ';
      }
      _display = '0';
    });
  }

  void _onParenthesis() {
    HapticFeedback.selectionClick();
    setState(() {
      _gstBreakdown = null;
      int openCount = '('.allMatches(_expression).length - ')'.allMatches(_expression).length;
      if (openCount > 0 && _display != '0') {
        _expression += '$_display) ';
        _display = '0';
      } else {
        _expression += '( ';
      }
    });
  }

  void _onNegate() {
    HapticFeedback.selectionClick();
    setState(() {
      _gstBreakdown = null;
      if (_display == '0') return;
      if (_display.startsWith('-')) {
        _display = _display.substring(1);
      } else {
        _display = '-$_display';
      }
    });
  }

  void _onPercent() {
    HapticFeedback.lightImpact();
    final val = double.tryParse(_display) ?? 0.0;
    setState(() {
      _gstBreakdown = null;
      final pct = val / 100.0;
      _display = _formatNumber(pct);
    });
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() {
      _expression = '';
      _display = '0';
      _gstBreakdown = null;
      _shouldResetOnNextDigit = false;
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    setState(() {
      _gstBreakdown = null;
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onEquals() {
    HapticFeedback.heavyImpact();
    if (_expression.isEmpty) return;
    final fullExpr = '$_expression$_display';
    try {
      final res = MathEvaluator.evaluate(fullExpr);
      final formatted = _formatNumber(res);
      setState(() {
        _history.insert(0, '$fullExpr = $formatted');
        if (_history.length > 20) _history.removeLast();
        _expression = '$fullExpr =';
        _display = formatted;
        _shouldResetOnNextDigit = true;
      });
    } catch (_) {
      setState(() {
        _display = 'Error';
        _shouldResetOnNextDigit = true;
      });
    }
  }

  void _applyGstRate(double percent) {
    HapticFeedback.lightImpact();
    final base = double.tryParse(_display) ?? 0.0;
    if (base <= 0) return;
    final gstAmt = base * (percent / 100.0);
    final total = base + gstAmt;
    final cgst = gstAmt / 2.0;
    final sgst = gstAmt / 2.0;

    setState(() {
      _expression = '₹${_formatNumber(base)} + ${percent.toStringAsFixed(0)}% GST =';
      _display = _formatNumber(total);
      _shouldResetOnNextDigit = true;
      _gstBreakdown = 'Base: ₹${_formatNumber(base)} | CGST: ₹${_formatNumber(cgst)} | SGST: ₹${_formatNumber(sgst)} | Total: ₹${_formatNumber(total)}';
      _history.insert(0, '₹${_formatNumber(base)} + ${percent.toStringAsFixed(0)}% GST = ₹${_formatNumber(total)}');
    });
  }

  void _applyDiscount(double percent) {
    HapticFeedback.lightImpact();
    final base = double.tryParse(_display) ?? 0.0;
    if (base <= 0) return;
    final discAmt = base * (percent / 100.0);
    final total = base - discAmt;

    setState(() {
      _expression = '₹${_formatNumber(base)} - ${percent.toStringAsFixed(0)}% OFF =';
      _display = _formatNumber(total);
      _shouldResetOnNextDigit = true;
      _gstBreakdown = 'Orig: ₹${_formatNumber(base)} | Discount: -₹${_formatNumber(discAmt)} | Final: ₹${_formatNumber(total)}';
      _history.insert(0, '₹${_formatNumber(base)} - ${percent.toStringAsFixed(0)}% Disc = ₹${_formatNumber(total)}');
    });
  }

  void _memClear() {
    HapticFeedback.mediumImpact();
    setState(() => _memory = 0.0);
  }

  void _memRecall() {
    HapticFeedback.selectionClick();
    setState(() {
      _display = _formatNumber(_memory);
      _shouldResetOnNextDigit = true;
    });
  }

  void _memAdd() {
    HapticFeedback.lightImpact();
    final v = double.tryParse(_display) ?? 0.0;
    setState(() => _memory += v);
  }

  void _memSub() {
    HapticFeedback.lightImpact();
    final v = double.tryParse(_display) ?? 0.0;
    setState(() => _memory -= v);
  }

  String _formatNumber(double n) {
    if (n.isNaN || n.isInfinite) return 'Error';
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    String s = n.toStringAsFixed(4);
    while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final displayBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    final keypadBg = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      children: [
        // 1. DISPLAY AREA
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: displayBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Top control bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => setState(() => _showHistory = !_showHistory),
                          icon: Icon(_showHistory ? Icons.keyboard_hide : Icons.history, size: 15, color: const Color(0xFFFF9100)),
                          label: Text(_showHistory ? 'Hide Tape' : 'Tape (${_history.length})', style: const TextStyle(fontSize: 11, color: Color(0xFFFF9100), fontWeight: FontWeight.bold)),
                        ),
                        if (_memory != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(4)),
                            child: const Text('M', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                      tooltip: 'Copy Result',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _display));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied $_display to clipboard'),
                            duration: const Duration(seconds: 1),
                            backgroundColor: const Color(0xFF046A38),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // History Drawer
                if (_showHistory && _history.isNotEmpty)
                  Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.builder(
                      itemCount: _history.length,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      itemBuilder: (ctx, i) => InkWell(
                        onTap: () {
                          final parts = _history[i].split('=');
                          if (parts.length > 1) {
                            setState(() {
                              _display = parts.last.trim().replaceAll('₹', '');
                              _shouldResetOnNextDigit = true;
                            });
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            _history[i],
                            style: TextStyle(fontSize: 11, color: textSecondary, fontFamily: 'monospace'),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Expression Line
                Text(
                  _expression.isEmpty ? ' ' : _expression,
                  style: TextStyle(
                    fontSize: 15,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Main Display Number
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _display,
                    style: TextStyle(
                      fontSize: 46,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -1,
                    ),
                  ),
                ),

                // Live Tax / Discount Breakdown Toast
                if (_gstBreakdown != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Text(
                      _gstBreakdown!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF046A38)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2. QUICK FINANCIAL ACTIONS STRIP (+GST & Discount)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Quick Tax: ', style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                _buildQuickActionPill('+5% GST', () => _applyGstRate(5)),
                _buildQuickActionPill('+12% GST', () => _applyGstRate(12)),
                _buildQuickActionPill('+18% GST', () => _applyGstRate(18)),
                _buildQuickActionPill('+28% GST', () => _applyGstRate(28)),
                _buildQuickActionPill('-10% OFF', () => _applyDiscount(10), color: const Color(0xFFDC2626)),
                _buildQuickActionPill('-20% OFF', () => _applyDiscount(20), color: const Color(0xFFDC2626)),
              ],
            ),
          ),
        ),

        // 3. KEYPAD GRID
        Expanded(
          flex: 6,
          child: Container(
            color: keypadBg,
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Column(
              children: [
                // Memory Row
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('MC', const Color(0xFF64748B), isAccent: true, onTap: _memClear),
                      _buildCalcBtn('MR', const Color(0xFF64748B), isAccent: true, onTap: _memRecall),
                      _buildCalcBtn('M+', const Color(0xFF64748B), isAccent: true, onTap: _memAdd),
                      _buildCalcBtn('M-', const Color(0xFF64748B), isAccent: true, onTap: _memSub),
                    ],
                  ),
                ),
                // Function Row 1
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('AC', const Color(0xFFEF4444), isAccent: true, onTap: _onClear),
                      _buildCalcBtn('⌫', const Color(0xFF334155), isAccent: true, onTap: _onBackspace),
                      _buildCalcBtn('( )', const Color(0xFF334155), isAccent: true, onTap: _onParenthesis),
                      _buildCalcBtn('÷', const Color(0xFFFF9100), isOperator: true, onTap: () => _onOperator('÷')),
                    ],
                  ),
                ),
                // Row 7, 8, 9, ×
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('7', textPrimary, onTap: () => _onDigit('7')),
                      _buildCalcBtn('8', textPrimary, onTap: () => _onDigit('8')),
                      _buildCalcBtn('9', textPrimary, onTap: () => _onDigit('9')),
                      _buildCalcBtn('×', const Color(0xFFFF9100), isOperator: true, onTap: () => _onOperator('×')),
                    ],
                  ),
                ),
                // Row 4, 5, 6, −
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('4', textPrimary, onTap: () => _onDigit('4')),
                      _buildCalcBtn('5', textPrimary, onTap: () => _onDigit('5')),
                      _buildCalcBtn('6', textPrimary, onTap: () => _onDigit('6')),
                      _buildCalcBtn('−', const Color(0xFFFF9100), isOperator: true, onTap: () => _onOperator('−')),
                    ],
                  ),
                ),
                // Row 1, 2, 3, +
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('1', textPrimary, onTap: () => _onDigit('1')),
                      _buildCalcBtn('2', textPrimary, onTap: () => _onDigit('2')),
                      _buildCalcBtn('3', textPrimary, onTap: () => _onDigit('3')),
                      _buildCalcBtn('+', const Color(0xFFFF9100), isOperator: true, onTap: () => _onOperator('+')),
                    ],
                  ),
                ),
                // Row ±, 0, ., =
                Expanded(
                  child: Row(
                    children: [
                      _buildCalcBtn('±', textPrimary, onTap: _onNegate),
                      _buildCalcBtn('0', textPrimary, onTap: () => _onDigit('0')),
                      _buildCalcBtn('.', textPrimary, onTap: _onDecimal),
                      _buildCalcBtn('=', const Color(0xFF10B981), isEquals: true, onTap: _onEquals),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionPill(String label, VoidCallback onTap, {Color color = const Color(0xFF059669)}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10.5)),
        ),
      ),
    );
  }

  Widget _buildCalcBtn(
    String label,
    Color color, {
    bool isAccent = false,
    bool isOperator = false,
    bool isEquals = false,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager.isDarkMode;
    Color btnBg;
    Color btnText;

    if (isEquals) {
      btnBg = const Color(0xFF046A38);
      btnText = Colors.white;
    } else if (isOperator) {
      btnBg = isDark ? const Color(0xFF33200B) : const Color(0xFFFFF7ED);
      btnText = const Color(0xFFFF9100);
    } else if (isAccent) {
      btnBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
      btnText = color;
    } else {
      btnBg = isDark ? const Color(0xFF131B2E) : Colors.white;
      btnText = isDark ? Colors.white : const Color(0xFF0F172A);
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3.5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: btnBg,
            foregroundColor: btnText,
            elevation: isEquals ? 3 : 0.8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isEquals
                    ? const Color(0xFF046A38)
                    : (isOperator
                        ? const Color(0xFFFF9100).withValues(alpha: 0.4)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
                width: 1,
              ),
            ),
            padding: EdgeInsets.zero,
          ),
          onPressed: onTap,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: label.length > 2 ? 13 : 20,
                fontWeight: isEquals || isOperator ? FontWeight.w900 : FontWeight.bold,
                color: btnText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 1. EMI CALCULATOR
// ============================================================================
class EmiCalculatorView extends StatefulWidget {
  const EmiCalculatorView({super.key});
  @override
  State<EmiCalculatorView> createState() => _EmiCalculatorViewState();
}

class _EmiCalculatorViewState extends State<EmiCalculatorView> {
  double _amount = 1000000;
  double _rate = 8.5;
  double _tenureYears = 15;

  @override
  Widget build(BuildContext context) {
    final n = (_tenureYears * 12).round();
    final r = (_rate / 12) / 100;
    final emi = (_amount * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
    final totalPayable = emi * n;
    final totalInterest = totalPayable - _amount;
    final principalRatio = _amount / totalPayable;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Monthly Loan EMI',
            primaryValue: '₹${emi.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: principalRatio,
            ratioLabelPrimary: 'Principal',
            ratioLabelSecondary: 'Total Interest',
            subValues: [
              {'label': 'Principal Borrowed', 'val': '₹${_amount.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}'},
              {'label': 'Total Interest Payout', 'val': '₹${totalInterest.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}'},
              {'label': 'Total Amount Payable', 'val': '₹${totalPayable.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}'},
            ],
            accentColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Loan Amount (Principal)',
            value: _amount,
            min: 50000,
            max: 10000000,
            step: 50000,
            display: '₹${_amount.round()}',
            presetValues: [500000, 1000000, 2500000, 5000000, 10000000],
            presetLabels: ['₹5L', '₹10L', '₹25L', '₹50L', '₹1Cr'],
            onChanged: (v) => setState(() => _amount = v),
          ),
          _buildSliderField(
            title: 'Annual Interest Rate (%)',
            value: _rate,
            min: 6.0,
            max: 20.0,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}% p.a.',
            presetValues: [7.5, 8.5, 9.5, 11.0, 14.0],
            presetLabels: ['7.5%', '8.5%', '9.5%', '11%', '14%'],
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Loan Duration)',
            value: _tenureYears,
            min: 1,
            max: 30,
            step: 1,
            display: '${_tenureYears.round()} Years (${n} Months)',
            presetValues: [5, 10, 15, 20, 25],
            presetLabels: ['5Y', '10Y', '15Y', '20Y', '25Y'],
            onChanged: (v) => setState(() => _tenureYears = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 2. SIP WEALTH CALCULATOR
// ============================================================================
class SipCalculatorView extends StatefulWidget {
  const SipCalculatorView({super.key});
  @override
  State<SipCalculatorView> createState() => _SipCalculatorViewState();
}

class _SipCalculatorViewState extends State<SipCalculatorView> {
  double _monthly = 5000;
  double _cagr = 12.0;
  double _years = 10;

  @override
  Widget build(BuildContext context) {
    final months = (_years * 12).round();
    final i = (_cagr / 12) / 100;
    final totalInvested = _monthly * months;
    final futureValue = _monthly * ((pow(1 + i, months) - 1) / i) * (1 + i);
    final totalGain = futureValue - totalInvested;
    final ratioInvested = totalInvested / futureValue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Expected Wealth at Maturity',
            primaryValue: '₹${futureValue.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: ratioInvested,
            ratioLabelPrimary: 'Invested',
            ratioLabelSecondary: 'Wealth Gain',
            subValues: [
              {'label': 'Total Invested Capital', 'val': '₹${totalInvested.round()}'},
              {'label': 'Estimated Capital Gain', 'val': '₹${totalGain.round()}'},
              {'label': 'Wealth Multiplier', 'val': '${(futureValue / totalInvested).toStringAsFixed(2)}x growth'},
            ],
            accentColor: const Color(0xFF046A38),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Monthly SIP Installment',
            value: _monthly,
            min: 500,
            max: 200000,
            step: 500,
            display: '₹${_monthly.round()}/mo',
            presetValues: [1000, 2500, 5000, 10000, 25000],
            presetLabels: ['₹1k', '₹2.5k', '₹5k', '₹10k', '₹25k'],
            onChanged: (v) => setState(() => _monthly = v),
          ),
          _buildSliderField(
            title: 'Expected Annual Return (CAGR %)',
            value: _cagr,
            min: 5.0,
            max: 25.0,
            step: 0.5,
            display: '${_cagr.toStringAsFixed(1)}% p.a.',
            presetValues: [8.0, 12.0, 15.0, 18.0],
            presetLabels: ['8% (Debt)', '12% (Nifty)', '15% (Flexi)', '18% (Small)'],
            onChanged: (v) => setState(() => _cagr = v),
          ),
          _buildSliderField(
            title: 'Investment Horizon (Tenure)',
            value: _years,
            min: 1,
            max: 35,
            step: 1,
            display: '${_years.round()} Years',
            presetValues: [3, 5, 10, 15, 20],
            presetLabels: ['3Y', '5Y', '10Y', '15Y', '20Y'],
            onChanged: (v) => setState(() => _years = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 3. GST TAX CALCULATOR
// ============================================================================
class GstCalculatorView extends StatefulWidget {
  const GstCalculatorView({super.key});
  @override
  State<GstCalculatorView> createState() => _GstCalculatorViewState();
}

class _GstCalculatorViewState extends State<GstCalculatorView> {
  final _amountCtrl = TextEditingController(text: '10000');
  double _gstRate = 18.0;
  bool _isInclusive = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final amt = double.tryParse(_amountCtrl.text) ?? 0.0;
    double netAmount;
    double gstAmount;
    double totalAmount;

    if (_isInclusive) {
      totalAmount = amt;
      netAmount = totalAmount / (1 + (_gstRate / 100.0));
      gstAmount = totalAmount - netAmount;
    } else {
      netAmount = amt;
      gstAmount = netAmount * (_gstRate / 100.0);
      totalAmount = netAmount + gstAmount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: _isInclusive ? 'Base Net Amount (Ex-GST)' : 'Final Gross Invoice Total',
            primaryValue: '₹${(_isInclusive ? netAmount : totalAmount).toStringAsFixed(2)}',
            ratioPrimary: totalAmount > 0 ? (netAmount / totalAmount) : 0.8,
            ratioLabelPrimary: 'Base Net',
            ratioLabelSecondary: 'Total GST',
            subValues: [
              {'label': 'Net Base Amount', 'val': '₹${netAmount.toStringAsFixed(2)}'},
              {'label': 'Total GST (${_gstRate.round()}%)', 'val': '₹${gstAmount.toStringAsFixed(2)}'},
              {'label': 'CGST Split (${(_gstRate / 2).toStringAsFixed(1)}%)', 'val': '₹${(gstAmount / 2).toStringAsFixed(2)}'},
              {'label': 'SGST / UTGST Split (${(_gstRate / 2).toStringAsFixed(1)}%)', 'val': '₹${(gstAmount / 2).toStringAsFixed(2)}'},
            ],
            accentColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(height: 16),

          // Mode Selector
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('GST Exclusive (Add GST)')),
                  selected: !_isInclusive,
                  onSelected: (val) => setState(() => _isInclusive = !val),
                  selectedColor: const Color(0xFF7C3AED),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: !_isInclusive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : Colors.black87),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('GST Inclusive (Extract)')),
                  selected: _isInclusive,
                  onSelected: (val) => setState(() => _isInclusive = val),
                  selectedColor: const Color(0xFF7C3AED),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: _isInclusive ? Colors.white : (isDark ? const Color(0xFF94A3B8) : Colors.black87),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: _isInclusive ? 'Total Price (inclusive of GST)' : 'Base Amount (exclusive of GST)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 16),

          Text('Official GST Slabs (CBIC / GST Council)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [5.0, 12.0, 18.0, 28.0].map((rate) {
              final sel = _gstRate == rate;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: sel ? const Color(0xFF7C3AED) : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      foregroundColor: sel ? Colors.white : textPrimary,
                      side: BorderSide(color: sel ? const Color(0xFF7C3AED) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => setState(() => _gstRate = rate),
                    child: Text('${rate.round()}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 4. INCOME TAX CALCULATOR (NEW REGIME FY 2024-25)
// ============================================================================
class IncomeTaxCalculatorView extends StatefulWidget {
  const IncomeTaxCalculatorView({super.key});
  @override
  State<IncomeTaxCalculatorView> createState() => _IncomeTaxCalculatorViewState();
}

class _IncomeTaxCalculatorViewState extends State<IncomeTaxCalculatorView> {
  final _salaryCtrl = TextEditingController(text: '1200000');

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final gross = double.tryParse(_salaryCtrl.text) ?? 0.0;
    const stdDeduction = 75000.0;
    final taxable = max(0.0, gross - stdDeduction);

    double baseTax = 0;
    if (taxable <= 300000) {
      baseTax = 0;
    } else if (taxable <= 700000) {
      baseTax = (taxable - 300000) * 0.05;
    } else if (taxable <= 1000000) {
      baseTax = 20000 + (taxable - 700000) * 0.10;
    } else if (taxable <= 1200000) {
      baseTax = 20000 + 30000 + (taxable - 1000000) * 0.15;
    } else if (taxable <= 1500000) {
      baseTax = 20000 + 30000 + 30000 + (taxable - 1200000) * 0.20;
    } else {
      baseTax = 20000 + 30000 + 30000 + 60000 + (taxable - 1500000) * 0.30;
    }

    // Section 87A rebate up to ₹7L taxable income under new regime
    if (taxable <= 700000) {
      baseTax = 0;
    }

    final cess = baseTax * 0.04;
    final totalTax = baseTax + cess;
    final inHand = gross - totalTax;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Annual Income Tax (FY 2024-25 New Regime)',
            primaryValue: '₹${totalTax.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: gross > 0 ? (inHand / gross) : 0.9,
            ratioLabelPrimary: 'Take-Home Pay',
            ratioLabelSecondary: 'Income Tax',
            subValues: [
              {'label': 'Gross Salary / Annual Income', 'val': '₹${gross.round()}'},
              {'label': 'Standard Deduction (Budget 2024)', 'val': '-₹${stdDeduction.round()}'},
              {'label': 'Net Taxable Income', 'val': '₹${taxable.round()}'},
              {'label': 'Effective Tax Rate', 'val': '${gross > 0 ? ((totalTax / gross) * 100).toStringAsFixed(1) : "0"}%'},
              {'label': 'Net Annual Take-Home (Post-Tax)', 'val': '₹${inHand.round()}'},
            ],
            accentColor: const Color(0xFFFF671F),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _salaryCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Gross Annual CTC / Total Income',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.25) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Union Budget 2024 Schedule: Standard deduction increased to ₹75,000. Full tax rebate under Section 87A for income up to ₹7.75 Lakhs.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF60A5FA), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 5. TDS CALCULATOR (OFFICIAL INCOME TAX ACT SCHEDULES)
// ============================================================================
class TdsCalculatorView extends StatefulWidget {
  const TdsCalculatorView({super.key});
  @override
  State<TdsCalculatorView> createState() => _TdsCalculatorViewState();
}

class _TdsCalculatorViewState extends State<TdsCalculatorView> {
  final _amountCtrl = TextEditingController(text: '50000');
  String _selectedSection = '194C';
  bool _hasPan = true;

  final List<Map<String, dynamic>> _tdsSections = [
    {
      'section': '194C',
      'label': 'Sec 194C: Contractors / Transporters (1%)',
      'rate': 1.0,
      'threshold': 30000.0,
      'desc': 'Single payout > ₹30,000 or aggregate > ₹1,00,000/yr',
    },
    {
      'section': '194J',
      'label': 'Sec 194J: Tech, Software & Professional (2%)',
      'rate': 2.0,
      'threshold': 30000.0,
      'desc': 'Tech services, IT software, BPO contracts (2%)',
    },
    {
      'section': '194H',
      'label': 'Sec 194H: Commission & Brokerage (2%)',
      'rate': 2.0,
      'threshold': 15000.0,
      'desc': 'Reduced from 5% to 2% in Finance Act 2024',
    },
    {
      'section': '194I',
      'label': 'Sec 194I: Rent on Property / Equipment (10%)',
      'rate': 10.0,
      'threshold': 240000.0,
      'desc': 'Annual rental payout exceeding ₹2,40,000',
    },
    {
      'section': '194Q',
      'label': 'Sec 194Q: Purchase of Goods (0.1%)',
      'rate': 0.1,
      'threshold': 5000000.0,
      'desc': 'Turnover > ₹10 Cr purchasing goods > ₹50 Lakhs',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final currentRule = _tdsSections.firstWhere(
      (s) => s['section'] == _selectedSection,
      orElse: () => _tdsSections.first,
    );

    final baseRate = (currentRule['rate'] as num).toDouble();
    final threshold = (currentRule['threshold'] as num).toDouble();
    final isThresholdCrossed = amount >= threshold;
    final effectiveRate = !_hasPan ? 20.0 : baseRate;
    final tdsAmount = isThresholdCrossed ? (amount * effectiveRate / 100.0) : 0.0;
    final netPayable = amount - tdsAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'TDS Deduction Breakdown',
            primaryValue: '₹${tdsAmount.toStringAsFixed(2)}',
            ratioPrimary: amount > 0 ? (netPayable / amount) : 0.98,
            ratioLabelPrimary: 'Net Payable',
            ratioLabelSecondary: 'TDS Deducted',
            subValues: [
              {'label': 'Gross Bill / Payout Amount', 'val': '₹${amount.toStringAsFixed(2)}'},
              {'label': 'TDS Section & Nature', 'val': '${currentRule['section']}'},
              {'label': 'Applicable Rate', 'val': !_hasPan ? '20% (Section 206AA No-PAN)' : '$effectiveRate%'},
              {'label': 'Exemption Threshold', 'val': '₹${threshold.toStringAsFixed(0)}'},
              {'label': 'Net Amount Payable to Payee', 'val': '₹${netPayable.toStringAsFixed(2)}'},
            ],
            accentColor: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Gross Invoice / Bill Amount (₹)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          Text('Select Nature of Payment (TDS Section)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2E) : Colors.white,
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF131B2E) : Colors.white,
                value: _selectedSection,
                items: _tdsSections.map((s) => DropdownMenuItem(
                  value: s['section'] as String,
                  child: Text(s['label'] as String, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textPrimary)),
                )).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSection = v);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _hasPan,
            activeColor: const Color(0xFF046A38),
            title: Text('Payee PAN Card Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary)),
            subtitle: Text(
              _hasPan ? 'Standard Section $_selectedSection rate applied' : '⚠️ Section 206AA: Mandatory 20% higher TDS without PAN',
              style: TextStyle(fontSize: 11, color: _hasPan ? const Color(0xFF64748B) : Colors.red),
            ),
            onChanged: (v) => setState(() => _hasPan = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 6. FX CURRENCY CONVERTER
// ============================================================================
class FxCalculatorView extends StatefulWidget {
  const FxCalculatorView({super.key});
  @override
  State<FxCalculatorView> createState() => _FxCalculatorViewState();
}

class _FxCalculatorViewState extends State<FxCalculatorView> {
  final _inrCtrl = TextEditingController(text: '10000');
  String _targetCurrency = 'USD';
  Map<String, double> _rates = {
    'USD': 84.15,
    'EUR': 91.20,
    'GBP': 109.40,
    'AED': 22.91,
    'SGD': 63.80,
    'JPY': 0.55,
    'CAD': 61.10,
    'AUD': 55.70,
  };

  @override
  Widget build(BuildContext context) {
    final inr = double.tryParse(_inrCtrl.text) ?? 0.0;
    final rate = _rates[_targetCurrency] ?? 1.0;
    final converted = inr / rate;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Foreign Currency Received',
            primaryValue: '$_targetCurrency ${converted.toStringAsFixed(2)}',
            subValues: [
              {'label': '1 $_targetCurrency', 'val': '₹$rate INR'},
              {'label': 'Exchange Rail', 'val': 'Direct Interbank RBI Ref'},
              {'label': 'Forex Spread Markup', 'val': '0% Direct Settlement'},
            ],
            accentColor: const Color(0xFF0284C7),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _inrCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Indian Rupee Amount (INR)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 14),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rates.keys.map((curr) {
              final sel = _targetCurrency == curr;
              return ChoiceChip(
                label: Text('$curr (₹${_rates[curr]})'),
                selected: sel,
                selectedColor: const Color(0xFF0284C7),
                backgroundColor: ThemeManager.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                labelStyle: TextStyle(color: sel ? Colors.white : (ThemeManager.isDarkMode ? const Color(0xFF94A3B8) : Colors.black87), fontWeight: FontWeight.bold),
                onSelected: (val) {
                  if (val) setState(() => _targetCurrency = curr);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 7. FD CALCULATOR
// ============================================================================
class FdCalculatorView extends StatefulWidget {
  const FdCalculatorView({super.key});
  @override
  State<FdCalculatorView> createState() => _FdCalculatorViewState();
}

class _FdCalculatorViewState extends State<FdCalculatorView> {
  double _deposit = 100000;
  double _rate = 7.1;
  double _years = 5;

  @override
  Widget build(BuildContext context) {
    // Quarterly compounding formula
    final maturity = _deposit * pow(1 + (_rate / 400.0), 4 * _years);
    final interest = maturity - _deposit;
    final ratio = _deposit / maturity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Maturity Amount (Quarterly Compounded)',
            primaryValue: '₹${maturity.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: ratio,
            ratioLabelPrimary: 'Principal',
            ratioLabelSecondary: 'Interest Earned',
            subValues: [
              {'label': 'Principal Deposit', 'val': '₹${_deposit.round()}'},
              {'label': 'Guaranteed Total Interest', 'val': '₹${interest.round()}'},
              {'label': 'DICGC Insurance Covered', 'val': 'Up to ₹5,00,000 per bank'},
            ],
            accentColor: const Color(0xFF4338CA),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Fixed Deposit Amount',
            value: _deposit,
            min: 5000,
            max: 5000000,
            step: 5000,
            display: '₹${_deposit.round()}',
            presetValues: [25000, 50000, 100000, 500000, 1000000],
            presetLabels: ['₹25k', '₹50k', '₹1L', '₹5L', '₹10L'],
            onChanged: (v) => setState(() => _deposit = v),
          ),
          _buildSliderField(
            title: 'Interest Rate (% p.a.)',
            value: _rate,
            min: 4.0,
            max: 10.0,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}%',
            presetValues: [6.5, 7.1, 7.5, 8.2],
            presetLabels: ['6.5%', '7.1% (SBI)', '7.5% (HDFC)', '8.2% (Sr. Cit)'],
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Years)',
            value: _years,
            min: 1,
            max: 10,
            step: 1,
            display: '${_years.round()} Years',
            presetValues: [1, 2, 3, 5, 10],
            presetLabels: ['1Y', '2Y', '3Y', '5Y', '10Y'],
            onChanged: (v) => setState(() => _years = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 8. RD CALCULATOR
// ============================================================================
class RdCalculatorView extends StatefulWidget {
  const RdCalculatorView({super.key});
  @override
  State<RdCalculatorView> createState() => _RdCalculatorViewState();
}

class _RdCalculatorViewState extends State<RdCalculatorView> {
  double _monthly = 5000;
  double _rate = 6.8;
  double _months = 24;

  @override
  Widget build(BuildContext context) {
    final n = _months;
    final r = _rate / 100.0;
    // Standard RBI RD maturity formula: P * n + P * n(n+1)/2 * (r/12)
    final totalDeposit = _monthly * n;
    final interest = _monthly * (n * (n + 1) / 2.0) * (r / 12.0);
    final maturity = totalDeposit + interest;
    final ratio = totalDeposit / maturity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Recurring Deposit Maturity',
            primaryValue: '₹${maturity.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: ratio,
            ratioLabelPrimary: 'Total Saved',
            ratioLabelSecondary: 'Interest Earned',
            subValues: [
              {'label': 'Total Monthly Deposits', 'val': '₹${totalDeposit.round()}'},
              {'label': 'Total Interest Earned', 'val': '₹${interest.round()}'},
              {'label': 'Duration', 'val': '${(n / 12).toStringAsFixed(1)} Years (${n.round()} Months)'},
            ],
            accentColor: const Color(0xFF059669),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Monthly Recurring Deposit',
            value: _monthly,
            min: 500,
            max: 100000,
            step: 500,
            display: '₹${_monthly.round()}/mo',
            presetValues: [1000, 2500, 5000, 10000, 20000],
            presetLabels: ['₹1k', '₹2.5k', '₹5k', '₹10k', '₹20k'],
            onChanged: (v) => setState(() => _monthly = v),
          ),
          _buildSliderField(
            title: 'Annual Interest Rate (%)',
            value: _rate,
            min: 4.0,
            max: 9.0,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}%',
            presetValues: [6.5, 6.8, 7.2, 7.8],
            presetLabels: ['6.5%', '6.8% (SBI)', '7.2% (HDFC)', '7.8% (Senior)'],
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Months)',
            value: _months,
            min: 6,
            max: 120,
            step: 6,
            display: '${_months.round()} Months (${(_months / 12).toStringAsFixed(1)}Y)',
            presetValues: [12, 24, 36, 60],
            presetLabels: ['1 Year', '2 Years', '3 Years', '5 Years'],
            onChanged: (v) => setState(() => _months = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 9. COMPOUND INTEREST CALCULATOR
// ============================================================================
class CompoundInterestCalculatorView extends StatefulWidget {
  const CompoundInterestCalculatorView({super.key});
  @override
  State<CompoundInterestCalculatorView> createState() => _CompoundInterestCalculatorViewState();
}

class _CompoundInterestCalculatorViewState extends State<CompoundInterestCalculatorView> {
  double _principal = 100000;
  double _rate = 10.0;
  double _years = 10;

  @override
  Widget build(BuildContext context) {
    final finalAmount = _principal * pow(1 + (_rate / 100.0), _years);
    final totalInterest = finalAmount - _principal;
    final ratio = _principal / finalAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Compound Future Value',
            primaryValue: '₹${finalAmount.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            ratioPrimary: ratio,
            ratioLabelPrimary: 'Principal',
            ratioLabelSecondary: 'Compound Interest',
            subValues: [
              {'label': 'Principal Investment', 'val': '₹${_principal.round()}'},
              {'label': 'Total Compound Growth', 'val': '₹${totalInterest.round()}'},
              {'label': 'Growth Multiplier', 'val': '${(finalAmount / _principal).toStringAsFixed(2)}x'},
            ],
            accentColor: const Color(0xFFD97706),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Initial Principal Amount',
            value: _principal,
            min: 1000,
            max: 2000000,
            step: 5000,
            display: '₹${_principal.round()}',
            onChanged: (v) => setState(() => _principal = v),
          ),
          _buildSliderField(
            title: 'Annual Rate of Return (%)',
            value: _rate,
            min: 1.0,
            max: 30.0,
            step: 0.5,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Compounding Horizon (Years)',
            value: _years,
            min: 1,
            max: 40,
            step: 1,
            display: '${_years.round()} Years',
            onChanged: (v) => setState(() => _years = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 10. INFLATION CALCULATOR
// ============================================================================
class InflationCalculatorView extends StatefulWidget {
  const InflationCalculatorView({super.key});
  @override
  State<InflationCalculatorView> createState() => _InflationCalculatorViewState();
}

class _InflationCalculatorViewState extends State<InflationCalculatorView> {
  double _currentAmount = 100000;
  double _inflationRate = 6.0;
  double _years = 10;

  @override
  Widget build(BuildContext context) {
    final futureCost = _currentAmount * pow(1 + (_inflationRate / 100.0), _years);
    final purchasingPower = _currentAmount / pow(1 + (_inflationRate / 100.0), _years);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Future Equivalent Cost',
            primaryValue: '₹${futureCost.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            subValues: [
              {'label': 'Today\'s Value', 'val': '₹${_currentAmount.round()}'},
              {'label': 'Future Cost to Buy Same Goods', 'val': '₹${futureCost.round()}'},
              {'label': 'Purchasing Power of Today\'s Money', 'val': '₹${purchasingPower.round()}'},
            ],
            accentColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Current Cost of Goods',
            value: _currentAmount,
            min: 5000,
            max: 2000000,
            step: 5000,
            display: '₹${_currentAmount.round()}',
            onChanged: (v) => setState(() => _currentAmount = v),
          ),
          _buildSliderField(
            title: 'Expected Annual Inflation (%)',
            value: _inflationRate,
            min: 2.0,
            max: 12.0,
            step: 0.2,
            display: '${_inflationRate.toStringAsFixed(1)}% p.a.',
            onChanged: (v) => setState(() => _inflationRate = v),
          ),
          _buildSliderField(
            title: 'Years in Future',
            value: _years,
            min: 1,
            max: 30,
            step: 1,
            display: '${_years.round()} Years',
            onChanged: (v) => setState(() => _years = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 11. GOAL PLANNER CALCULATOR
// ============================================================================
class SavingsGoalCalculatorView extends StatefulWidget {
  const SavingsGoalCalculatorView({super.key});
  @override
  State<SavingsGoalCalculatorView> createState() => _SavingsGoalCalculatorViewState();
}

class _SavingsGoalCalculatorViewState extends State<SavingsGoalCalculatorView> {
  double _targetGoal = 1000000;
  double _years = 5;
  double _cagr = 12.0;

  @override
  Widget build(BuildContext context) {
    final months = (_years * 12).round();
    final i = (_cagr / 12) / 100;
    // Required monthly SIP: Target / [ ((1+i)^n - 1) / i * (1+i) ]
    final factor = ((pow(1 + i, months) - 1) / i) * (1 + i);
    final requiredMonthly = _targetGoal / factor;
    final totalInvested = requiredMonthly * months;
    final totalGain = _targetGoal - totalInvested;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Required Monthly SIP to Hit Goal',
            primaryValue: '₹${requiredMonthly.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}/mo',
            ratioPrimary: totalInvested > 0 ? (totalInvested / _targetGoal) : 0.6,
            ratioLabelPrimary: 'Your Investment',
            ratioLabelSecondary: 'Market Gains',
            subValues: [
              {'label': 'Target Wealth Goal', 'val': '₹${_targetGoal.round()}'},
              {'label': 'Your Total Contribution', 'val': '₹${totalInvested.round()}'},
              {'label': 'Compounded Wealth Created', 'val': '₹${totalGain.round()}'},
            ],
            accentColor: const Color(0xFFDB2777),
          ),
          const SizedBox(height: 16),

          _buildSliderField(
            title: 'Target Financial Goal Amount',
            value: _targetGoal,
            min: 50000,
            max: 50000000,
            step: 50000,
            display: '₹${_targetGoal.round()}',
            presetValues: [500000, 1000000, 2500000, 5000000, 10000000],
            presetLabels: ['₹5L', '₹10L', '₹25L', '₹50L', '₹1Cr'],
            onChanged: (v) => setState(() => _targetGoal = v),
          ),
          _buildSliderField(
            title: 'Time to Reach Goal (Years)',
            value: _years,
            min: 1,
            max: 30,
            step: 1,
            display: '${_years.round()} Years (${months} Months)',
            presetValues: [2, 3, 5, 10, 15],
            presetLabels: ['2Y', '3Y', '5Y', '10Y', '15Y'],
            onChanged: (v) => setState(() => _years = v),
          ),
          _buildSliderField(
            title: 'Expected CAGR Return (%)',
            value: _cagr,
            min: 5.0,
            max: 20.0,
            step: 0.5,
            display: '${_cagr.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _cagr = v),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MATH EVALUATION ENGINE (RECURSIVE DESCENT PARSER)
// ============================================================================
class MathEvaluator {
  static double evaluate(String expression) {
    String clean = expression
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll('₹', '');

    clean = _preprocessPercentages(clean);
    final tokens = _tokenize(clean);
    final parser = _Parser(tokens);
    return parser.parse();
  }

  static String _preprocessPercentages(String expr) {
    final regex = RegExp(r'(\d+(\.\d+)?)%');
    return expr.replaceAllMapped(regex, (m) => '(${m.group(1)}/100)');
  }

  static List<String> _tokenize(String expr) {
    final List<String> tokens = [];
    int i = 0;
    while (i < expr.length) {
      final c = expr[i];
      if ('+-*/()'.contains(c)) {
        if (c == '-' && (tokens.isEmpty || '+-*/('.contains(tokens.last))) {
          int start = i;
          i++;
          while (i < expr.length && (expr[i].contains(RegExp(r'[0-9.]')))) {
            i++;
          }
          tokens.add(expr.substring(start, i));
          continue;
        }
        tokens.add(c);
        i++;
      } else if (c.contains(RegExp(r'[0-9.]'))) {
        int start = i;
        while (i < expr.length && expr[i].contains(RegExp(r'[0-9.]'))) {
          i++;
        }
        tokens.add(expr.substring(start, i));
      } else {
        i++;
      }
    }
    return tokens;
  }
}

class _Parser {
  final List<String> tokens;
  int pos = 0;

  _Parser(this.tokens);

  double parse() {
    return parseAddSub();
  }

  double parsePrimary() {
    if (pos >= tokens.length) return 0.0;
    final t = tokens[pos];
    if (t == '(') {
      pos++;
      final res = parseAddSub();
      if (pos < tokens.length && tokens[pos] == ')') pos++;
      return res;
    }
    pos++;
    return double.tryParse(t) ?? 0.0;
  }

  double parseMulDiv() {
    double left = parsePrimary();
    while (pos < tokens.length) {
      final op = tokens[pos];
      if (op == '*') {
        pos++;
        left *= parsePrimary();
      } else if (op == '/') {
        pos++;
        final denom = parsePrimary();
        left = denom != 0 ? left / denom : 0.0;
      } else {
        break;
      }
    }
    return left;
  }

  double parseAddSub() {
    double left = parseMulDiv();
    while (pos < tokens.length) {
      final op = tokens[pos];
      if (op == '+') {
        pos++;
        left += parseMulDiv();
      } else if (op == '-') {
        pos++;
        left -= parseMulDiv();
      } else {
        break;
      }
    }
    return left;
  }
}
