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

  final List<String> _tools = [
    'EMI Loan',
    'SIP Return',
    'GST Tax',
    'Income Tax',
    'Currency FX',
    'FD Maturity',
    'RD Maturity',
    'Compound',
    'Inflation',
    'Goal Plan',
  ];

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialTool != null) {
      final match = _tools.indexWhere((t) => t.toLowerCase().contains(widget.initialTool!.toLowerCase()));
      if (match != -1) initialIndex = match;
    }
    _tabController = TabController(length: _tools.length, vsync: this, initialIndex: initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Financial Calculator Centre', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFFFF9100),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tools.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          EmiCalculatorView(),
          SipCalculatorView(),
          GstCalculatorView(),
          IncomeTaxCalculatorView(),
          FxCalculatorView(),
          FdCalculatorView(),
          RdCalculatorView(),
          CompoundInterestCalculatorView(),
          InflationCalculatorView(),
          SavingsGoalCalculatorView(),
        ],
      ),
    );
  }
}

// 1. EMI CALCULATOR
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Monthly Loan EMI',
            primaryValue: '₹${emi.round().toString().replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}',
            subValues: [
              {'label': 'Principal Amount', 'val': '₹${_amount.round()}'},
              {'label': 'Total Interest', 'val': '₹${totalInterest.round()}'},
              {'label': 'Total Payable', 'val': '₹${totalPayable.round()}'},
            ],
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Loan Amount',
            value: _amount,
            min: 50000,
            max: 10000000,
            step: 50000,
            display: '₹${_amount.round()}',
            onChanged: (v) => setState(() => _amount = v),
          ),
          _buildSliderField(
            title: 'Interest Rate (% p.a.)',
            value: _rate,
            min: 5.0,
            max: 20.0,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Years)',
            value: _tenureYears,
            min: 1,
            max: 30,
            step: 1,
            display: '${_tenureYears.round()} Years (${(_tenureYears * 12).round()} Months)',
            onChanged: (v) => setState(() => _tenureYears = v),
          ),
        ],
      ),
    );
  }
}

// 2. SIP CALCULATOR
class SipCalculatorView extends StatefulWidget {
  const SipCalculatorView({super.key});
  @override
  State<SipCalculatorView> createState() => _SipCalculatorViewState();
}

class _SipCalculatorViewState extends State<SipCalculatorView> {
  double _monthly = 5000;
  double _rate = 12.0;
  double _years = 10;

  @override
  Widget build(BuildContext context) {
    final n = (_years * 12).round();
    final i = (_rate / 12) / 100;
    final totalInvested = _monthly * n;
    final maturity = _monthly * ((pow(1 + i, n) - 1) / i) * (1 + i);
    final returns = maturity - totalInvested;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Expected Wealth at Maturity',
            primaryValue: '₹${maturity.round()}',
            subValues: [
              {'label': 'Total Invested', 'val': '₹${totalInvested.round()}'},
              {'label': 'Est. Wealth Gained', 'val': '₹${returns.round()}'},
            ],
            accentColor: const Color(0xFF046A38),
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Monthly Investment',
            value: _monthly,
            min: 500,
            max: 100000,
            step: 500,
            display: '₹${_monthly.round()}',
            onChanged: (v) => setState(() => _monthly = v),
          ),
          _buildSliderField(
            title: 'Expected Annual Return (%)',
            value: _rate,
            min: 5.0,
            max: 25.0,
            step: 0.5,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Time Period (Years)',
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

// 3. GST CALCULATOR
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
    final base = double.tryParse(_amountCtrl.text) ?? 0.0;
    double netAmount = 0;
    double gstAmount = 0;
    double totalAmount = 0;

    if (_isInclusive) {
      totalAmount = base;
      netAmount = base / (1 + (_gstRate / 100));
      gstAmount = totalAmount - netAmount;
    } else {
      netAmount = base;
      gstAmount = base * (_gstRate / 100);
      totalAmount = base + gstAmount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: _isInclusive ? 'Net Pre-Tax Value' : 'Total Invoice Amount',
            primaryValue: '₹${totalAmount.toStringAsFixed(2)}',
            subValues: [
              {'label': 'Net Amount', 'val': '₹${netAmount.toStringAsFixed(2)}'},
              {'label': 'Total GST (${_gstRate.round()}%)', 'val': '₹${gstAmount.toStringAsFixed(2)}'},
              {'label': 'CGST (${(_gstRate / 2).toStringAsFixed(1)}%)', 'val': '₹${(gstAmount / 2).toStringAsFixed(2)}'},
              {'label': 'SGST (${(_gstRate / 2).toStringAsFixed(1)}%)', 'val': '₹${(gstAmount / 2).toStringAsFixed(2)}'},
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('GST Exclusive (Add GST)')),
                  selected: !_isInclusive,
                  onSelected: (val) => setState(() => _isInclusive = !val),
                  selectedColor: const Color(0xFF046A38),
                  labelStyle: TextStyle(color: !_isInclusive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('GST Inclusive (Extract)')),
                  selected: _isInclusive,
                  onSelected: (val) => setState(() => _isInclusive = val),
                  selectedColor: const Color(0xFF046A38),
                  labelStyle: TextStyle(color: _isInclusive ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('GST Slab Rate', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [5.0, 12.0, 18.0, 28.0].map((rate) {
              final sel = _gstRate == rate;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: sel ? const Color(0xFF0D1B2A) : Colors.white,
                      foregroundColor: sel ? Colors.white : const Color(0xFF0D1B2A),
                      side: BorderSide(color: sel ? const Color(0xFF0D1B2A) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => setState(() => _gstRate = rate),
                    child: Text('${rate.round()}%'),
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

// 4. INCOME TAX ESTIMATOR (New Tax Regime FY 2024-25)
class IncomeTaxCalculatorView extends StatefulWidget {
  const IncomeTaxCalculatorView({super.key});
  @override
  State<IncomeTaxCalculatorView> createState() => _IncomeTaxCalculatorViewState();
}

class _IncomeTaxCalculatorViewState extends State<IncomeTaxCalculatorView> {
  final _salaryCtrl = TextEditingController(text: '1200000');

  @override
  Widget build(BuildContext context) {
    final gross = double.tryParse(_salaryCtrl.text) ?? 0.0;
    const stdDeduction = 75000.0;
    final taxableIncome = max(0.0, gross - stdDeduction);

    double tax = 0;
    if (taxableIncome > 1500000) {
      tax += (taxableIncome - 1500000) * 0.30;
      tax += 300000 * 0.20;
      tax += 300000 * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (taxableIncome > 1200000) {
      tax += (taxableIncome - 1200000) * 0.20;
      tax += 300000 * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (taxableIncome > 900000) {
      tax += (taxableIncome - 900000) * 0.15;
      tax += 300000 * 0.10;
      tax += 300000 * 0.05;
    } else if (taxableIncome > 600000) {
      tax += (taxableIncome - 600000) * 0.10;
      tax += 300000 * 0.05;
    } else if (taxableIncome > 300000) {
      tax += (taxableIncome - 300000) * 0.05;
    }

    // Section 87A rebate: Nil tax up to 7,00,000 taxable income
    if (taxableIncome <= 700000) {
      tax = 0.0;
    }

    final cess = tax * 0.04;
    final totalTax = tax + cess;
    final inHandAnnual = gross - totalTax;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'Estimated Total Tax (New Regime)',
            primaryValue: '₹${totalTax.round()}',
            subValues: [
              {'label': 'Taxable Income', 'val': '₹${taxableIncome.round()}'},
              {'label': 'Standard Deduction', 'val': '₹75,000'},
              {'label': 'Income Tax', 'val': '₹${tax.round()}'},
              {'label': 'Health & Edu Cess (4%)', 'val': '₹${cess.round()}'},
              {'label': 'Est. Annual In-Hand', 'val': '₹${inHandAnnual.round()}'},
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _salaryCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Gross Annual Salary / Income',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'FY 2024-25 (AY 2025-26) New Tax Regime includes standard deduction of ₹75,000 for salaried employees and full tax rebate up to ₹7,75,000 gross salary.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }
}

// 5. FX CONVERTER
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
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    final res = await BharatOnePayApi.getLiveFxRates();
    if (res['success'] == true && res['rates'] != null && mounted) {
      final map = res['rates'] as Map<String, dynamic>;
      setState(() {
        _rates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
      });
    }
  }

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
            title: 'Converted Value ($_targetCurrency)',
            primaryValue: '$_targetCurrency ${converted.toStringAsFixed(2)}',
            subValues: [
              {'label': '1 $_targetCurrency', 'val': '₹$rate INR'},
              {'label': 'Exchange Partner', 'val': 'RBI Ref / AikSetra FX'},
              {'label': 'FX Markup', 'val': '0% (Direct)'},
            ],
            accentColor: const Color(0xFFFF9100),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _inrCtrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Amount in Indian Rupees (INR)',
              prefixText: '₹ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select Target Foreign Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _rates.keys.map((curr) {
              final sel = _targetCurrency == curr;
              return ChoiceChip(
                label: Text('$curr (₹${_rates[curr]})'),
                selected: sel,
                selectedColor: const Color(0xFF0D1B2A),
                labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
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

// 6. FD CALCULATOR
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
    // Quarterly compounding: A = P(1 + r/4)^(4*t)
    final r = (_rate / 100) / 4;
    final n = 4 * _years;
    final maturity = _deposit * pow(1 + r, n);
    final interest = maturity - _deposit;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'FD Maturity Amount (Quarterly Compounding)',
            primaryValue: '₹${maturity.round()}',
            subValues: [
              {'label': 'Principal Deposited', 'val': '₹${_deposit.round()}'},
              {'label': 'Total Interest Earned', 'val': '₹${interest.round()}'},
            ],
            accentColor: const Color(0xFF046A38),
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Total Deposit Amount',
            value: _deposit,
            min: 5000,
            max: 2000000,
            step: 5000,
            display: '₹${_deposit.round()}',
            onChanged: (v) => setState(() => _deposit = v),
          ),
          _buildSliderField(
            title: 'Interest Rate (% p.a.)',
            value: _rate,
            min: 4.0,
            max: 9.5,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Years)',
            value: _years,
            min: 1,
            max: 10,
            step: 1,
            display: '${_years.round()} Years',
            onChanged: (v) => setState(() => _years = v),
          ),
        ],
      ),
    );
  }
}

// 7. RD CALCULATOR
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
    // Standard bank formula for RD: M = P * n + P * n(n+1)/2 * r/12
    final n = _months;
    final r = _rate / 100;
    final totalDeposit = _monthly * n;
    final interest = _monthly * (n * (n + 1) / (2 * 12)) * r;
    final maturity = totalDeposit + interest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultCard(
            title: 'RD Maturity Value',
            primaryValue: '₹${maturity.round()}',
            subValues: [
              {'label': 'Total Deposited', 'val': '₹${totalDeposit.round()}'},
              {'label': 'Total Interest', 'val': '₹${interest.round()}'},
            ],
            accentColor: const Color(0xFF046A38),
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Monthly Installment',
            value: _monthly,
            min: 500,
            max: 50000,
            step: 500,
            display: '₹${_monthly.round()}',
            onChanged: (v) => setState(() => _monthly = v),
          ),
          _buildSliderField(
            title: 'Interest Rate (% p.a.)',
            value: _rate,
            min: 4.0,
            max: 9.0,
            step: 0.1,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Tenure (Months)',
            value: _months,
            min: 6,
            max: 120,
            step: 6,
            display: '${_months.round()} Months (${(_months / 12).toStringAsFixed(1)} Yrs)',
            onChanged: (v) => setState(() => _months = v),
          ),
        ],
      ),
    );
  }
}

// 8. COMPOUND INTEREST CALCULATOR
class CompoundInterestCalculatorView extends StatefulWidget {
  const CompoundInterestCalculatorView({super.key});
  @override
  State<CompoundInterestCalculatorView> createState() => _CompoundInterestCalculatorViewState();
}

class _CompoundInterestCalculatorViewState extends State<CompoundInterestCalculatorView> {
  double _principal = 100000;
  double _rate = 10.0;
  double _years = 5;

  @override
  Widget build(BuildContext context) {
    final amount = _principal * pow(1 + (_rate / 100), _years);
    final interest = amount - _principal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultCard(
            title: 'Total Accumulated Amount',
            primaryValue: '₹${amount.round()}',
            subValues: [
              {'label': 'Principal', 'val': '₹${_principal.round()}'},
              {'label': 'Compound Interest', 'val': '₹${interest.round()}'},
            ],
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Initial Principal',
            value: _principal,
            min: 1000,
            max: 1000000,
            step: 5000,
            display: '₹${_principal.round()}',
            onChanged: (v) => setState(() => _principal = v),
          ),
          _buildSliderField(
            title: 'Annual Interest Rate (%)',
            value: _rate,
            min: 1,
            max: 30,
            step: 0.5,
            display: '${_rate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _rate = v),
          ),
          _buildSliderField(
            title: 'Time (Years)',
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

// 9. INFLATION CALCULATOR
class InflationCalculatorView extends StatefulWidget {
  const InflationCalculatorView({super.key});
  @override
  State<InflationCalculatorView> createState() => _InflationCalculatorViewState();
}

class _InflationCalculatorViewState extends State<InflationCalculatorView> {
  double _currentCost = 100000;
  double _inflationRate = 6.0;
  double _years = 10;

  @override
  Widget build(BuildContext context) {
    final futureCost = _currentCost * pow(1 + (_inflationRate / 100), _years);
    final increase = futureCost - _currentCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultCard(
            title: 'Future Purchasing Cost',
            primaryValue: '₹${futureCost.round()}',
            subValues: [
              {'label': 'Today\'s Cost', 'val': '₹${_currentCost.round()}'},
              {'label': 'Price Surge (Inflation)', 'val': '₹${increase.round()} (+${((futureCost / _currentCost - 1) * 100).round()}%)'},
            ],
            accentColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Current Price/Cost',
            value: _currentCost,
            min: 1000,
            max: 2000000,
            step: 5000,
            display: '₹${_currentCost.round()}',
            onChanged: (v) => setState(() => _currentCost = v),
          ),
          _buildSliderField(
            title: 'Inflation Rate (% p.a.)',
            value: _inflationRate,
            min: 2,
            max: 15,
            step: 0.5,
            display: '${_inflationRate.toStringAsFixed(1)}%',
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

// 10. SAVINGS GOAL CALCULATOR
class SavingsGoalCalculatorView extends StatefulWidget {
  const SavingsGoalCalculatorView({super.key});
  @override
  State<SavingsGoalCalculatorView> createState() => _SavingsGoalCalculatorViewState();
}

class _SavingsGoalCalculatorViewState extends State<SavingsGoalCalculatorView> {
  double _targetAmount = 2500000;
  double _years = 5;
  double _returnRate = 12.0;

  @override
  Widget build(BuildContext context) {
    final n = (_years * 12).round();
    final r = (_returnRate / 12) / 100;
    // Monthly SIP required = Target / ( ((1+r)^n - 1)/r * (1+r) )
    final requiredMonthly = _targetAmount / (((pow(1 + r, n) - 1) / r) * (1 + r));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildResultCard(
            title: 'Required Monthly Savings',
            primaryValue: '₹${requiredMonthly.round()} / month',
            subValues: [
              {'label': 'Target Goal Amount', 'val': '₹${_targetAmount.round()}'},
              {'label': 'Total Capital Invested', 'val': '₹${(requiredMonthly * n).round()}'},
              {'label': 'Compounded Wealth Gain', 'val': '₹${(_targetAmount - (requiredMonthly * n)).round()}'},
            ],
            accentColor: const Color(0xFF046A38),
          ),
          const SizedBox(height: 20),
          _buildSliderField(
            title: 'Target Savings Goal',
            value: _targetAmount,
            min: 50000,
            max: 10000000,
            step: 50000,
            display: '₹${_targetAmount.round()}',
            onChanged: (v) => setState(() => _targetAmount = v),
          ),
          _buildSliderField(
            title: 'Time to Goal (Years)',
            value: _years,
            min: 1,
            max: 25,
            step: 1,
            display: '${_years.round()} Years',
            onChanged: (v) => setState(() => _years = v),
          ),
          _buildSliderField(
            title: 'Expected Portfolio Return (%)',
            value: _returnRate,
            min: 5,
            max: 20,
            step: 0.5,
            display: '${_returnRate.toStringAsFixed(1)}%',
            onChanged: (v) => setState(() => _returnRate = v),
          ),
        ],
      ),
    );
  }
}

// SHARED WIDGET HELPERS
Widget _buildResultCard({
  required String title,
  required String primaryValue,
  required List<Map<String, String>> subValues,
  Color accentColor = const Color(0xFF0D1B2A),
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [accentColor, const Color(0xFF1E293B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: accentColor.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(primaryValue, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Divider(color: Colors.white24, height: 1),
        const SizedBox(height: 12),
        ...subValues.map((sv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(sv['label']!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(sv['val']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
            Text(display, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          activeColor: const Color(0xFF046A38),
          inactiveColor: const Color(0xFFE2E8F0),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
