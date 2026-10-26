import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bharat_one_pay_api.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  bool _isLoading = true;
  bool _soundboxActive = true;
  Map<String, dynamic> _profile = {};
  Map<String, dynamic> _stats = {};
  List<dynamic> _invoices = [];

  final List<Map<String, dynamic>> _todayCollections = [
    {'customer': 'Aditya Sen', 'vpa': 'aditya@oksbi', 'amount': 1450.0, 'time': '12:45 PM', 'method': 'UPI QR'},
    {'customer': 'Priya Das', 'vpa': 'priyadas@paytm', 'amount': 320.0, 'time': '11:15 AM', 'method': 'UPI QR'},
    {'customer': 'Kunal Ghosh', 'vpa': 'kunal@icici', 'amount': 2800.0, 'time': '10:02 AM', 'method': 'Payment Link'},
    {'customer': 'Sneha Paul', 'vpa': 'sneha@axl', 'amount': 650.0, 'time': '09:20 AM', 'method': 'RuPay Credit on UPI'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchBusinessData();
  }

  Future<void> _fetchBusinessData() async {
    setState(() => _isLoading = true);
    final profileRes = await BharatOnePayApi.getBusinessProfile();
    final invoiceRes = await BharatOnePayApi.getBusinessInvoices();

    if (mounted) {
      setState(() {
        if (profileRes['success'] == true) {
          _profile = profileRes['profile'] ?? {};
          _stats = profileRes['stats'] ?? {};
        }
        if (invoiceRes['success'] == true) {
          _invoices = invoiceRes['invoices'] ?? [];
        }
        _isLoading = false;
      });
    }
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
                              value: gstRate,
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

  void _showMerchantQrModal() {
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
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.qr_code_2, size: 140, color: Color(0xFF0D1B2A)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('AikSetra Technologies Pvt Ltd', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                  const Text('UPI ID: aiksetra.merchant@okhdfcbank', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
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
                      Clipboard.setData(const ClipboardData(text: 'aiksetra.merchant@okhdfcbank'));
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
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing merchant QR code...')));
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

  void _simulateSoundbox() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.volume_up, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('🔊 "AikSetra par ₹1,450 prapt hue" (Payment received on AikSetra)')),
          ],
        ),
        backgroundColor: Color(0xFF046A38),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final businessName = _profile['businessName'] ?? 'AikSetra Digital Store';
    final gstin = _profile['gstin'] ?? '19AAACA1234A1Z5';
    final todayTotal = (_stats['todayTotal'] as num?)?.toDouble() ?? 5220.0;
    final todayCount = _stats['todayCount'] ?? 4;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AikSetra Business Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_soundboxActive ? Icons.volume_up : Icons.volume_off),
            tooltip: 'AikSetra Soundbox Simulation',
            onPressed: () {
              setState(() => _soundboxActive = !_soundboxActive);
              if (_soundboxActive) _simulateSoundbox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Merchant Standee QR',
            onPressed: _showMerchantQrModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF046A38)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant Header Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1B2A),
                      borderRadius: BorderRadius.circular(18),
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
                                      Text(businessName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.verified, color: Color(0xFF00E676), size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('GSTIN: $gstin', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(8)),
                              child: const Text('MERCHANT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Instant Bank Settlement: Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            TextButton.icon(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 24)),
                              onPressed: _showMerchantQrModal,
                              icon: const Icon(Icons.qr_code, color: Color(0xFFFF9100), size: 16),
                              label: const Text('View Standee QR', style: TextStyle(color: Color(0xFFFF9100), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Today's Collection Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Today\'s Total Collections', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('₹${todayTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                              child: Text('$todayCount Payments Today', style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Average Ticket', '₹${(todayTotal / todayCount).toStringAsFixed(0)}'),
                            _buildStatColumn('Settlement Cycle', 'Real-time'),
                            _buildStatColumn('MDR / Charge', '0% (UPI Free)'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF046A38),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.receipt_long, size: 18),
                          label: const Text('Create GST Bill', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: _showCreateInvoiceModal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0D1B2A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.file_download_outlined, size: 18),
                          label: const Text('Settlement Report', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading today\'s settlement Excel statement...')),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Real-time Collections Ledger
                  const Text('Today\'s Received Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _todayCollections.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final txn = _todayCollections[idx];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFDCFCE7),
                            child: Icon(Icons.arrow_downward, color: Color(0xFF046A38), size: 20),
                          ),
                          title: Text(txn['customer'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text('${txn['vpa']} • ${txn['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('+₹${(txn['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF046A38))),
                              Text(txn['method'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (_invoices.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Generated GST Invoices', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _invoices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, idx) {
                          final inv = _invoices[idx];
                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEFF6FF),
                              child: Icon(Icons.receipt_long, color: Color(0xFF1D4ED8), size: 20),
                            ),
                            title: Text(inv['customerName'] ?? 'Invoice #${inv['invoiceNumber']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Text('Inv: ${inv['invoiceNumber']} • Status: ${inv['status'] ?? 'SENT'}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            trailing: Text('₹${(inv['totalAmount'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ],
    );
  }
}
