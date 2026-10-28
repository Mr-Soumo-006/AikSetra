import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';
import '../services/theme_manager.dart';
import 'business_dashboard_screen.dart';

class BusinessRegistrationScreen extends StatefulWidget {
  const BusinessRegistrationScreen({super.key});

  @override
  State<BusinessRegistrationScreen> createState() => _BusinessRegistrationScreenState();
}

class _BusinessRegistrationScreenState extends State<BusinessRegistrationScreen> {
  int _currentStep = 0;
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Step 1: About You / Owner Details
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _designationCtrl;
  late final TextEditingController _panCtrl;

  // Step 2: Business Details
  final _companyCtrl = TextEditingController(text: 'AikSetra Infotech Solutions');
  final _gstinCtrl = TextEditingController(text: '19AAECN1234F1Z5');
  final _addressCtrl = TextEditingController(text: 'Plot 42, Tech Park, Sector V, Salt Lake, Kolkata, WB 700091');
  final _bankCtrl = TextEditingController(text: 'HDFC Bank');
  final _accountNoCtrl = TextEditingController(text: '50100492814589');
  final _ifscCtrl = TextEditingController(text: 'HDFC0001234');
  final _upiCtrl = TextEditingController(text: 'aiksetra.merchant@okhdfcbank');

  String _selectedCategory = 'Information Technology & Software';
  String _selectedEntity = 'Private Limited Company';
  bool _agreedToTerms = true;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Information Technology & Software',
    'Retail & Kirana Store',
    'Electronics & Gadgets',
    'Professional & Consulting Services',
    'Restaurant, Food & Beverages',
    'Wholesale Trading & Distribution',
    'Healthcare & Pharmaceuticals',
    'Manufacturing & Infrastructure',
    'Other Enterprise',
  ];

  final List<String> _entityTypes = [
    'Private Limited Company',
    'Sole Proprietorship',
    'Partnership Firm',
    'Limited Liability Partnership (LLP)',
    'Individual Merchant / Freelancer',
  ];

  @override
  void initState() {
    super.initState();
    final user = BharatOnePayApi.currentUser;
    final currentAcc = BharatOnePayApi.currentAccount;

    _nameCtrl = TextEditingController(text: user?.fullName ?? 'Soumo Naskar');
    _emailCtrl = TextEditingController(text: user?.email ?? 'soumo@gmail.com');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '+91 9830113038');
    _designationCtrl = TextEditingController(text: 'Founder & Managing Director');
    _panCtrl = TextEditingController(text: 'AAECN1234F');

    if (currentAcc != null) {
      _bankCtrl.text = currentAcc.bankName;
      _ifscCtrl.text = currentAcc.ifsc;
      if (currentAcc.maskedAccountNumber.length > 4) {
        _accountNoCtrl.text = currentAcc.maskedAccountNumber;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _designationCtrl.dispose();
    _panCtrl.dispose();
    _companyCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _bankCtrl.dispose();
    _accountNoCtrl.dispose();
    _ifscCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitBusinessApplication() async {
    if (!_formKeyStep2.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the NPCI & RBI merchant authorization terms.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulated NPCI Onboarding delay
    await Future.delayed(const Duration(milliseconds: 1200));

    await BharatOnePayApi.registerBusinessAccount(
      ownerName: _nameCtrl.text.trim(),
      ownerEmail: _emailCtrl.text.trim(),
      ownerPhone: _phoneCtrl.text.trim(),
      ownerPan: _panCtrl.text.trim().toUpperCase(),
      ownerDesignation: _designationCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      businessType: _selectedCategory,
      gstin: _gstinCtrl.text.trim().toUpperCase(),
      businessAddress: _addressCtrl.text.trim(),
      bankName: _bankCtrl.text.trim(),
      bankAccountNo: _accountNoCtrl.text.trim(),
      ifsc: _ifscCtrl.text.trim().toUpperCase(),
      merchantVpa: _upiCtrl.text.trim().toLowerCase(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    // Show success dialog
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: ThemeManager.isDarkMode ? const Color(0xFF131B2E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF046A38), size: 54),
            ),
            const SizedBox(height: 18),
            Text(
              'Business Account Opened!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: ThemeManager.isDarkMode ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_companyCtrl.text.trim()} is now active for Standee QR collections, double-entry ledger tracking, and automated settlements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: ThemeManager.isDarkMode ? Colors.white70 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
                  );
                },
                child: const Text('Go to Business Accounts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final bgScaffold = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: const Text('Open Business Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF046A38), strokeWidth: 3),
                  const SizedBox(height: 18),
                  Text('Verifying merchant credentials with NPCI...', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Generating merchant UPI QR & initializing ledger', style: TextStyle(color: textSecondary, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Onboarding Header Banner
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D1B2A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF046A38),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'AikSetra for Merchants',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'One-Time Setup for Business Owners',
                                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF671F),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('0% MDR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _BenefitPill(icon: Icons.qr_code_2, label: 'Standee QR'),
                            _BenefitPill(icon: Icons.menu_book_rounded, label: 'Live Ledger'),
                            _BenefitPill(icon: Icons.pie_chart_rounded, label: 'Balance Sheet'),
                            _BenefitPill(icon: Icons.volume_up, label: 'Soundbox'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step indicator pills
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentStep = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _currentStep == 0 ? const Color(0xFF046A38) : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _currentStep == 0 ? const Color(0xFF046A38) : cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, size: 16, color: _currentStep == 0 ? Colors.white : textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '1. About You',
                                  style: TextStyle(
                                    color: _currentStep == 0 ? Colors.white : textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_formKeyStep1.currentState!.validate()) {
                              setState(() => _currentStep = 1);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _currentStep == 1 ? const Color(0xFF046A38) : cardBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _currentStep == 1 ? const Color(0xFF046A38) : cardBorder),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.business_center, size: 16, color: _currentStep == 1 ? Colors.white : textSecondary),
                                const SizedBox(width: 6),
                                Text(
                                  '2. Business Details',
                                  style: TextStyle(
                                    color: _currentStep == 1 ? Colors.white : textSecondary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // STEP 1: ABOUT US / OWNER DETAILS
                  if (_currentStep == 0) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Form(
                        key: _formKeyStep1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Applicant & Owner Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Details of the primary business owner / authorized signatory.',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            const SizedBox(height: 18),

                            _buildFieldLabel('Full Name', textSecondary),
                            TextFormField(
                              controller: _nameCtrl,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('e.g. Soumo Naskar', Icons.badge_outlined, cardBorder, textSecondary),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Email Address', textSecondary),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('e.g. soumo@gmail.com', Icons.email_outlined, cardBorder, textSecondary),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Please enter email';
                                if (!v.contains('@') || !v.contains('.')) return 'Enter valid email address';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Mobile Number (Registered with Aadhaar / Bank)', textSecondary),
                            TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('+91 9830113038', Icons.phone_android_outlined, cardBorder, textSecondary),
                              validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid phone number' : null,
                            ),
                            const SizedBox(height: 14),

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Owner Designation / Role', textSecondary),
                                      TextFormField(
                                        controller: _designationCtrl,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration('Proprietor / MD', Icons.work_outline, cardBorder, textSecondary),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Personal PAN', textSecondary),
                                      TextFormField(
                                        controller: _panCtrl,
                                        textCapitalization: TextCapitalization.characters,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration('AAECN1234F', Icons.credit_card_outlined, cardBorder, textSecondary),
                                        validator: (v) => (v == null || v.trim().length != 10) ? '10-digit PAN required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF046A38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                                label: const Text('Next: Business Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  if (_formKeyStep1.currentState!.validate()) {
                                    setState(() => _currentStep = 1);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]

                  // STEP 2: BUSINESS DETAILS
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Form(
                        key: _formKeyStep2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Business & Company Details',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Legal business profile, GSTIN, and settlement bank account.',
                              style: TextStyle(fontSize: 12, color: textSecondary),
                            ),
                            const SizedBox(height: 18),

                            _buildFieldLabel('Company / Business Legal Name', textSecondary),
                            TextFormField(
                              controller: _companyCtrl,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('e.g. AikSetra Digital Store', Icons.store_outlined, cardBorder, textSecondary),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter company name' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Business Category / Sector', textSecondary),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              dropdownColor: cardBg,
                              style: TextStyle(color: textPrimary, fontSize: 14),
                              decoration: _inputDecoration('', Icons.category_outlined, cardBorder, textSecondary),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCategory = v);
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Business Legal Constitution', textSecondary),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedEntity,
                              dropdownColor: cardBg,
                              style: TextStyle(color: textPrimary, fontSize: 14),
                              decoration: _inputDecoration('', Icons.account_balance_outlined, cardBorder, textSecondary),
                              items: _entityTypes.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedEntity = v);
                              },
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('GSTIN / Business Registration (Optional for < ₹40L)', textSecondary),
                            TextFormField(
                              controller: _gstinCtrl,
                              textCapitalization: TextCapitalization.characters,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('19AAECN1234F1Z5', Icons.receipt_long_outlined, cardBorder, textSecondary),
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Business Operating Address & PIN Code', textSecondary),
                            TextFormField(
                              controller: _addressCtrl,
                              maxLines: 2,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('Shop / Office Address, City, PIN', Icons.location_on_outlined, cardBorder, textSecondary),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Address required' : null,
                            ),
                            const SizedBox(height: 18),

                            const Divider(),
                            const SizedBox(height: 12),
                            Text(
                              'Settlement Bank Account',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Where customer QR collections will be settled automatically every day.',
                              style: TextStyle(fontSize: 11, color: textSecondary),
                            ),
                            const SizedBox(height: 12),

                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Bank Name', textSecondary),
                                      TextFormField(
                                        controller: _bankCtrl,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration('HDFC Bank', Icons.account_balance_outlined, cardBorder, textSecondary),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('IFSC Code', textSecondary),
                                      TextFormField(
                                        controller: _ifscCtrl,
                                        textCapitalization: TextCapitalization.characters,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration('HDFC0001234', null, cardBorder, textSecondary),
                                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Account Number', textSecondary),
                            TextFormField(
                              controller: _accountNoCtrl,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('Enter bank account number', Icons.numbers, cardBorder, textSecondary),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),

                            _buildFieldLabel('Preferred Merchant UPI ID', textSecondary),
                            TextFormField(
                              controller: _upiCtrl,
                              style: TextStyle(color: textPrimary),
                              decoration: _inputDecoration('aiksetra.merchant@okhdfcbank', Icons.qr_code, cardBorder, textSecondary),
                              validator: (v) => (v == null || !v.contains('@')) ? 'Valid UPI ID required' : null,
                            ),
                            const SizedBox(height: 16),

                            // Terms Checkbox
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _agreedToTerms,
                                    activeColor: const Color(0xFF046A38),
                                    onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'I confirm I am an authorized signatory for this business entity and accept NPCI / RBI merchant transaction and settlement guidelines.',
                                    style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: textPrimary,
                                      side: BorderSide(color: cardBorder),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: () => setState(() => _currentStep = 0),
                                    child: const Text('Back to Step 1'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF046A38),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    onPressed: _submitBusinessApplication,
                                    child: const Text(
                                      'Open Business Account',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon, Color borderColor, Color hintColor) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.6), fontSize: 13),
      prefixIcon: icon != null ? Icon(icon, size: 20, color: hintColor) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF046A38), width: 1.5)),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _BenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF9100), size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
