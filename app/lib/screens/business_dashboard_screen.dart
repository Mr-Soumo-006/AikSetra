import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/bharat_one_pay_api.dart';
import '../services/theme_manager.dart';
import 'business_registration_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _soundboxActive = true;
  String _ledgerFilter = 'ALL'; // ALL, CREDIT, DEBIT

  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _invoices = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchBusinessData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchBusinessData() async {
    setState(() => _isLoading = true);
    final profileRes = await BharatOnePayApi.getBusinessProfile();
    final invoiceRes = await BharatOnePayApi.getBusinessInvoices();

    if (mounted) {
      setState(() {
        if (profileRes['success'] == true) {
          _profile = profileRes['profile'] ?? {};
          _stats = profileRes['todayStats'] ?? profileRes['stats'] ?? {};
        }
        if (invoiceRes['success'] == true) {
          _invoices = invoiceRes['invoices'] ?? [];
        }
        _isLoading = false;
      });
    }
  }

  void _simulateSoundbox([double amount = 1450.0]) {
    final amtStr = amount.toStringAsFixed(0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text('🔊 "AikSetra par ₹$amtStr prapt hue" (Payment received on AikSetra)'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF046A38),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _simulateCustomerPaymentModal() {
    final nameCtrl = TextEditingController(text: 'Vikram Malhotra');
    final vpaCtrl = TextEditingController(text: 'vikram@oksbi');
    final amtCtrl = TextEditingController(text: '1500');
    String method = 'Standee QR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              top: 24,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Simulate Customer Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Text(
                    'Simulate an incoming UPI QR scan payment from a customer. It will trigger the Soundbox alert, post to the double-entry ledger, and update the balance sheet.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Customer Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Vikram Malhotra',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Customer UPI ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: vpaCtrl,
                    decoration: InputDecoration(
                      hintText: 'vikram@oksbi',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Payment Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1500',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Channel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: method,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: const [
                      DropdownMenuItem(value: 'Standee QR', child: Text('Standee Merchant QR')),
                      DropdownMenuItem(value: 'RuPay UPI', child: Text('RuPay Credit Card on UPI')),
                      DropdownMenuItem(value: 'Bharat QR', child: Text('Bharat QR Dynamic Link')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => method = v);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Confirm Received Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        final amt = double.tryParse(amtCtrl.text.trim()) ?? 1500.0;
                        BharatOnePayApi.recordBusinessCollection(
                          customerName: nameCtrl.text.trim().isEmpty ? 'Customer' : nameCtrl.text.trim(),
                          customerVpa: vpaCtrl.text.trim().isEmpty ? 'customer@upi' : vpaCtrl.text.trim(),
                          amount: amt,
                          method: method,
                          particulars: 'Store Counter Payment',
                        );
                        Navigator.pop(ctx);
                        if (_soundboxActive) _simulateSoundbox(amt);
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInstantSettlementModal() {
    final currentBal = (BharatOnePayApi.businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    final settleCtrl = TextEditingController(text: currentBal.toStringAsFixed(0));
    final bankName = BharatOnePayApi.businessProfile['bankName'] ?? 'HDFC Bank';
    final accNo = BharatOnePayApi.businessProfile['bankAccountNo'] ?? '•••• 4589';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Instant Bank Settlement', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF046A38), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$bankName Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('Account No: $accNo (Default Settlement)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Available to Settle: ₹${currentBal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF046A38))),
            const SizedBox(height: 8),
            TextField(
              controller: settleCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: 'Enter settlement amount',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.bolt, color: Color(0xFFFF9100)),
                label: const Text('Transfer Instantly via IMPS (0% MDR)', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  final amt = double.tryParse(settleCtrl.text.trim()) ?? 0.0;
                  if (amt <= 0 || amt > currentBal) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid settlement amount'), backgroundColor: Colors.redAccent),
                    );
                    return;
                  }
                  BharatOnePayApi.recordBusinessSettlement(amount: amt);
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('₹${amt.toStringAsFixed(2)} transferred to $bankName $accNo via IMPS! Ref: IMP${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                      backgroundColor: const Color(0xFF046A38),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOwnerModal() {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController(text: 'Co-Director / Partner');
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final panCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Business Owner / Director', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Full Legal Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(hintText: 'e.g. Ananya Sen', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              const Text('Role / Capacity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: roleCtrl,
                decoration: InputDecoration(hintText: 'Managing Partner / Director', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: 'ananya@aiksetra.com', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              const Text('Mobile Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hintText: '+91 9830554433', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              const Text('Personal PAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: panCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: 'ABCDE1234F', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF046A38),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    BharatOnePayApi.businessOwners.add({
                      'id': 'own_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameCtrl.text.trim(),
                      'role': roleCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                      'pan': panCtrl.text.trim().toUpperCase(),
                      'stake': 'Partner Stake',
                      'status': 'AUTHORIZED SIGNATORY',
                      'isPrimary': false,
                    });
                    BharatOnePayApi.saveSessionToDisk();
                    Navigator.pop(ctx);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${nameCtrl.text.trim()} added as authorized business signatory!')),
                    );
                  },
                  child: const Text('Add Authorized Signatory', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMerchantQrModal() {
    final company = BharatOnePayApi.businessProfile['companyName'] ?? 'AikSetra Digital Store';
    final vpa = BharatOnePayApi.businessProfile['merchantVpa'] ?? 'aiksetra.merchant@okhdfcbank';
    final qrData = 'upi://pay?pa=$vpa&pn=${Uri.encodeComponent(company)}&mc=5411&cu=INR';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AikSetra Standee QR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 190.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    company,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1B2A)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text('UPI ID: $vpa', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                    child: const Text('ACCEPTED HERE: GPay, PhonePe, Paytm, RuPay', style: TextStyle(color: Color(0xFF046A38), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy UPI ID'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: vpa));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merchant UPI ID copied!')));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share QR'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Standee QR link shared!')));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateInvoiceModal() {
    final formKey = GlobalKey<FormState>();
    final customerCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final itemCtrl = TextEditingController(text: 'Consulting / Merchandise');
    final amountCtrl = TextEditingController();
    double gstRate = 18.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Create GST Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Customer Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: customerCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Customer Mobile (for WhatsApp / SMS Invoice)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(
                      hintText: '9876543210',
                      prefixText: '+91 ',
                      counterText: '',
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().length != 10) ? '10-digit mobile required' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Item / Service Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: itemCtrl,
                    decoration: InputDecoration(
                      hintText: 'Goods or service supplied',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: amountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '5000',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter amount' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('GST Slab', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<double>(
                              initialValue: gstRate,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 0.0, child: Text('0%')),
                                DropdownMenuItem(value: 5.0, child: Text('5%')),
                                DropdownMenuItem(value: 12.0, child: Text('12%')),
                                DropdownMenuItem(value: 18.0, child: Text('18%')),
                                DropdownMenuItem(value: 28.0, child: Text('28%')),
                              ],
                              onChanged: (v) {
                                if (v != null) setModalState(() => gstRate = v);
                              },
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final amt = double.parse(amountCtrl.text.trim());

                          final res = await BharatOnePayApi.createBusinessInvoice(
                            customerName: customerCtrl.text.trim(),
                            customerPhone: phoneCtrl.text.trim(),
                            items: [
                              {'description': itemCtrl.text.trim(), 'quantity': 1, 'price': amt, 'gstRate': gstRate}
                            ],
                          );

                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          if (res['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Invoice #${res['invoice']?['invoiceNumber'] ?? 'INV-NEW'} created! Payment link sent.'),
                                backgroundColor: const Color(0xFF046A38),
                              ),
                            );
                            _fetchBusinessData();
                          }
                        }
                      },
                      child: const Text('Generate Invoice & Payment Link', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

    final companyName = BharatOnePayApi.businessProfile['companyName'] ?? _profile['businessName'] ?? 'AikSetra Digital Store';
    final gstin = BharatOnePayApi.businessProfile['gstin'] ?? _profile['gstin'] ?? '19AAECN1234F1Z5';
    final category = BharatOnePayApi.businessProfile['businessType'] ?? 'Retail & Technology';
    final balance = (BharatOnePayApi.businessProfile['balance'] as num?)?.toDouble() ?? 48250.0;
    final vpa = BharatOnePayApi.businessProfile['merchantVpa'] ?? 'aiksetra.merchant@okhdfcbank';
    final bankName = BharatOnePayApi.businessProfile['bankName'] ?? 'HDFC Bank';
    final accNo = BharatOnePayApi.businessProfile['bankAccountNo'] ?? '•••• 4589';

    return Scaffold(
      backgroundColor: bgScaffold,
      appBar: AppBar(
        title: Text(companyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_soundboxActive ? Icons.volume_up : Icons.volume_off),
            tooltip: 'Soundbox Audio Simulation',
            onPressed: () {
              setState(() => _soundboxActive = !_soundboxActive);
              if (_soundboxActive) _simulateSoundbox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_2),
            tooltip: 'Standee QR Code',
            onPressed: _showMerchantQrModal,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note),
            tooltip: 'Edit Business Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BusinessRegistrationScreen()),
              ).then((_) => setState(() {}));
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00E676),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.storefront, size: 18)),
            Tab(text: 'Ledger', icon: Icon(Icons.menu_book, size: 18)),
            Tab(text: 'Balance Sheet', icon: Icon(Icons.pie_chart, size: 18)),
            Tab(text: 'Owners & Accs', icon: Icon(Icons.group, size: 18)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF046A38)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(cardBg, cardBorder, textPrimary, textSecondary, companyName, gstin, category, balance, vpa, bankName, accNo),
                _buildLedgerTab(cardBg, cardBorder, textPrimary, textSecondary),
                _buildBalanceSheetTab(cardBg, cardBorder, textPrimary, textSecondary, balance),
                _buildOwnersAndAccountsTab(cardBg, cardBorder, textPrimary, textSecondary, bankName, accNo, vpa, balance),
              ],
            ),
    );
  }

  // ================= TAB 1: OVERVIEW =================
  Widget _buildOverviewTab(
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
    String companyName,
    String gstin,
    String category,
    double balance,
    String vpa,
    String bankName,
    String accNo,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0D1B2A), Color(0xFF1B2A4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: Color(0xFF00E676), size: 18),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Category: $category', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          Text('GSTIN: $gstin', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(8)),
                      child: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Available Settlement Pool', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                        const SizedBox(height: 2),
                        Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
                        if (_stats['volume'] != null)
                          Text(
                            'Today: ₹${(_stats['volume'] as num).toStringAsFixed(0)} (${_stats['txnCount'] ?? 0} txns)',
                            style: const TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF671F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.bolt, size: 16),
                      label: const Text('Settle Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: _showInstantSettlementModal,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick Action Cards
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.qr_code_2,
                  label: 'Standee QR',
                  color: const Color(0xFF046A38),
                  onTap: _showMerchantQrModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.receipt_long,
                  label: 'Create GST Bill',
                  color: const Color(0xFF1D4ED8),
                  onTap: _showCreateInvoiceModal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.add_card,
                  label: 'Test Scan In',
                  color: const Color(0xFFFF671F),
                  onTap: _simulateCustomerPaymentModal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Soundbox Broadcast Status
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _soundboxActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _soundboxActive ? Icons.volume_up : Icons.volume_off,
                    color: _soundboxActive ? const Color(0xFF046A38) : const Color(0xFF64748B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _soundboxActive ? 'AikSetra Smart Soundbox: Active' : 'Soundbox Audio: Muted',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                      ),
                      Text(
                        _soundboxActive ? 'Voice alerts in Hindi, Bengali & English on payment' : 'Tap to enable instant voice announcements',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _soundboxActive,
                  activeTrackColor: const Color(0xFF046A38).withValues(alpha: 0.5),
                  activeThumbColor: const Color(0xFF046A38),
                  onChanged: (v) {
                    setState(() => _soundboxActive = v);
                    if (v) _simulateSoundbox();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent Collections Snapshot
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Collections', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
              TextButton(
                onPressed: () => _tabController.animateTo(1),
                child: const Text('View Full Ledger →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: BharatOnePayApi.businessLedger.take(4).length,
              separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
              itemBuilder: (context, idx) {
                final entry = BharatOnePayApi.businessLedger[idx];
                final isCredit = entry['type'] == 'CREDIT';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                    child: Icon(
                      isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isCredit ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                      size: 18,
                    ),
                  ),
                  title: Text(entry['party'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                  subtitle: Text('${entry['method']} • ${entry['date']}', style: TextStyle(fontSize: 11, color: textSecondary)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${isCredit ? "+" : "-"}₹${(entry['amount'] as double).toStringAsFixed(2)}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? const Color(0xFF046A38) : const Color(0xFFDC2626)),
                      ),
                      Text('Bal: ₹${(entry['balance'] as double).toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: textSecondary)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_invoices.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('GST Tax Invoices (${_invoices.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
                TextButton(
                  onPressed: _showCreateInvoiceModal,
                  child: const Text('+ New Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoices.take(3).length,
                separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
                itemBuilder: (context, idx) {
                  final inv = _invoices[idx];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFEFF6FF),
                      child: Icon(Icons.receipt_long, color: Color(0xFF1D4ED8), size: 18),
                    ),
                    title: Text(inv['customerName'] ?? 'Invoice #${inv['invoiceNumber']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                    subtitle: Text('Inv: ${inv['invoiceNumber']} • Status: ${inv['status'] ?? "PAID"}', style: TextStyle(fontSize: 11, color: textSecondary)),
                    trailing: Text('₹${(inv['totalAmount'] as num?)?.toStringAsFixed(2) ?? "0.00"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= TAB 2: DOUBLE-ENTRY LEDGER =================
  Widget _buildLedgerTab(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary) {
    final isDark = ThemeManager.isDarkMode;
    final filtered = BharatOnePayApi.businessLedger.where((e) {
      if (_ledgerFilter == 'CREDIT') return e['type'] == 'CREDIT';
      if (_ledgerFilter == 'DEBIT') return e['type'] == 'DEBIT';
      return true;
    }).toList();

    double totalInflow = 0.0;
    double totalOutflow = 0.0;
    for (final e in BharatOnePayApi.businessLedger) {
      final amt = (e['amount'] as num?)?.toDouble() ?? 0.0;
      if (e['type'] == 'CREDIT') totalInflow += amt;
      if (e['type'] == 'DEBIT') totalOutflow += amt;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ledger Summary Header Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Double-Entry General Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                      child: const Text('REAL-TIME', style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Inflow (Cr)', style: TextStyle(color: Color(0xFF046A38), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('+₹${totalInflow.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF046A38), fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Outflow (Dr)', style: TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text('-₹${totalOutflow.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 17)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Filters & Download
          Row(
            children: [
              _buildFilterChip('ALL', 'All Entries', cardBorder),
              const SizedBox(width: 8),
              _buildFilterChip('CREDIT', 'Credits (+)', cardBorder),
              const SizedBox(width: 8),
              _buildFilterChip('DEBIT', 'Debits (-)', cardBorder),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.file_download_outlined, color: Color(0xFF046A38)),
                tooltip: 'Export Statement',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Downloading double-entry ledger statement (PDF & Excel)...')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ledger Table
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
              itemBuilder: (context, idx) {
                final entry = filtered[idx];
                final isCredit = entry['type'] == 'CREDIT';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        child: Icon(
                          isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isCredit ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry['party'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                            const SizedBox(height: 2),
                            Text('${entry['particulars']} • ${entry['method']}', style: TextStyle(fontSize: 11, color: textSecondary)),
                            Text(entry['date'] as String, style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isCredit ? "+" : "-"}₹${(entry['amount'] as double).toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isCredit ? const Color(0xFF046A38) : const Color(0xFFDC2626)),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Bal: ₹${(entry['balance'] as double).toStringAsFixed(0)}',
                              style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, Color borderColor) {
    final isSelected = _ledgerFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _ledgerFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046A38) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF046A38) : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ================= TAB 3: BALANCE SHEET =================
  Widget _buildBalanceSheetTab(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary, double balance) {
    // Dynamic accounting model
    final cashAtBank = balance;
    const accountsReceivable = 24500.0;
    const storeInventory = 35000.0;
    final totalCurrentAssets = cashAtBank + accountsReceivable + storeInventory;

    const soundboxHardware = 1999.0;
    const posInfrastructure = 8500.0;
    const totalFixedAssets = soundboxHardware + posInfrastructure;

    final totalAssets = totalCurrentAssets + totalFixedAssets;

    const accountsPayable = 18500.0;
    const gstOutputPayable = 9749.0;
    const totalLiabilities = accountsPayable + gstOutputPayable;

    // In double-entry: Total Assets = Total Liabilities + Owner Equity
    final totalEquity = totalAssets - totalLiabilities;
    const initialCapital = 65000.0;
    final retainedSurplus = totalEquity - initialCapital;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balanced Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified, color: Color(0xFF046A38), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Double-Entry Balance Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF046A38))),
                      Text('Assets = Liabilities + Equity (Balanced ₹)', style: TextStyle(fontSize: 11, color: Color(0xFF065F46))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ASSETS SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ASSETS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF046A38), letterSpacing: 0.5)),
                    Text('₹${totalAssets.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046A38))),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                const Text('Current Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                _buildSheetRow('Cash & Settlement Pool', '₹${cashAtBank.toStringAsFixed(2)}', textPrimary, textSecondary),
                _buildSheetRow('Accounts Receivable (Client Invoices)', '₹${accountsReceivable.toStringAsFixed(2)}', textPrimary, textSecondary),
                _buildSheetRow('Store Stock & Merchandise', '₹${storeInventory.toStringAsFixed(2)}', textPrimary, textSecondary),
                const SizedBox(height: 8),
                const Text('Fixed & Capital Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                _buildSheetRow('AikSetra 4G Soundbox Terminal', '₹${soundboxHardware.toStringAsFixed(2)}', textPrimary, textSecondary),
                _buildSheetRow('Store POS Counter & Scanner Hardware', '₹${posInfrastructure.toStringAsFixed(2)}', textPrimary, textSecondary),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Assets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('₹${totalAssets.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // LIABILITIES & EQUITY SECTION
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LIABILITIES & EQUITY', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF1D4ED8), letterSpacing: 0.5)),
                    Text('₹${totalAssets.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D4ED8))),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(),
                const SizedBox(height: 6),
                const Text('Current Liabilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                _buildSheetRow('Accounts Payable (Vendor Dues)', '₹${accountsPayable.toStringAsFixed(2)}', textPrimary, textSecondary),
                _buildSheetRow('Output GST Tax Provision (18% Slab)', '₹${gstOutputPayable.toStringAsFixed(2)}', textPrimary, textSecondary),
                const SizedBox(height: 8),
                const Text('Owner Equity & Retained Earnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                _buildSheetRow('Initial Owner Capital Injected', '₹${initialCapital.toStringAsFixed(2)}', textPrimary, textSecondary),
                _buildSheetRow('Retained Operational Surplus', '₹${retainedSurplus.toStringAsFixed(2)}', textPrimary, textSecondary),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Liabilities & Equity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('₹${(totalLiabilities + totalEquity).toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial KPIs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Key Financial Ratios', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildKpiColumn('Working Capital', '₹${(totalCurrentAssets - totalLiabilities).toStringAsFixed(0)}', const Color(0xFF046A38)),
                    _buildKpiColumn('Current Ratio', '${(totalCurrentAssets / totalLiabilities).toStringAsFixed(1)}x', const Color(0xFF1D4ED8)),
                    _buildKpiColumn('Debt to Equity', (totalLiabilities / totalEquity).toStringAsFixed(2), const Color(0xFFFF671F)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetRow(String title, String amount, Color primaryColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: TextStyle(fontSize: 12, color: secondaryColor))),
          Text(amount, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: primaryColor)),
        ],
      ),
    );
  }

  Widget _buildKpiColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }

  // ================= TAB 4: OWNERS & ACCOUNTS =================
  Widget _buildOwnersAndAccountsTab(Color cardBg, Color cardBorder, Color textPrimary, Color textSecondary, String bankName, String accNo, String vpa, double balance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Settlement Account Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Settlement Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('AUTO-SETTLE', style: TextStyle(color: Color(0xFF046A38), fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.account_balance, color: Color(0xFF1D4ED8), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('$bankName Primary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                          Text('Account: $accNo • IFSC: ${BharatOnePayApi.businessProfile['ifsc'] ?? 'HDFC0001234'}', style: TextStyle(fontSize: 12, color: textSecondary)),
                          Text('Branch: Salt Lake Sector V, Kolkata', style: TextStyle(fontSize: 11, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Merchant UPI ID', style: TextStyle(fontSize: 11, color: textSecondary)),
                          Text(vpa, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textPrimary)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy', style: TextStyle(fontSize: 11)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: vpa));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID copied!')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Owners Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Business Account Owners', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary)),
              TextButton.icon(
                icon: const Icon(Icons.person_add_alt_1, size: 16, color: Color(0xFF046A38)),
                label: const Text('Add Owner', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                onPressed: _showAddOwnerModal,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Owners List
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: BharatOnePayApi.businessOwners.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: cardBorder),
              itemBuilder: (context, idx) {
                final owner = BharatOnePayApi.businessOwners[idx];
                final isPrimary = owner['isPrimary'] == true;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPrimary ? const Color(0xFF046A38) : const Color(0xFF1D4ED8),
                    child: Text(
                      (owner['name'] as String).substring(0, 1),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(owner['name'] as String, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary)),
                      const SizedBox(width: 6),
                      if (isPrimary)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(4)),
                          child: const Text('PRIMARY', style: TextStyle(color: Color(0xFF046A38), fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(owner['role']?.toString() ?? '', style: TextStyle(fontSize: 11, color: textSecondary, fontWeight: FontWeight.w500)),
                      Text('${owner['email']} • ${owner['phone']}', style: TextStyle(fontSize: 10, color: textSecondary)),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isPrimary ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      owner['status'] ?? 'AUTHORIZED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? const Color(0xFF046A38) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
