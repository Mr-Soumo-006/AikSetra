import 'package:flutter/material.dart';

class TaxPaymentsScreen extends StatefulWidget {
  final String? initialCategory;
  const TaxPaymentsScreen({super.key, this.initialCategory});

  @override
  State<TaxPaymentsScreen> createState() => _TaxPaymentsScreenState();
}

class _TaxPaymentsScreenState extends State<TaxPaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = ['Income Tax', 'GST PMT-06', 'Property Tax', 'Municipal Bills'];

  @override
  void initState() {
    super.initState();
    int initialIdx = 0;
    if (widget.initialCategory != null) {
      final idx = _tabs.indexWhere((t) => t.toLowerCase().contains(widget.initialCategory!.toLowerCase()));
      if (idx != -1) initialIdx = idx;
    }
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIdx);
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
        title: const Text('Taxes & Govt Dues', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9100),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          IncomeTaxChallanView(),
          GstPmt06View(),
          PropertyTaxView(),
          MunicipalBillsView(),
        ],
      ),
    );
  }
}

// 1. INCOME TAX (CHALLAN 280)
class IncomeTaxChallanView extends StatefulWidget {
  const IncomeTaxChallanView({super.key});
  @override
  State<IncomeTaxChallanView> createState() => _IncomeTaxChallanViewState();
}

class _IncomeTaxChallanViewState extends State<IncomeTaxChallanView> {
  final _formKey = GlobalKey<FormState>();
  final _panCtrl = TextEditingController(text: 'ABCDE1234F');
  final _amountCtrl = TextEditingController(text: '15000');
  String _assessmentYear = '2025-2026';
  String _taxType = 'Advance Tax (100)';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOfficialBanner('e-Pay Tax via TIN-NSDL / Income Tax Department Portal. Instant BSR receipt generation.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Permanent Account Number (PAN)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _panCtrl,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 10,
                    decoration: InputDecoration(
                      hintText: 'ABCDE1234F',
                      counterText: '',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().length != 10) return 'Valid 10-character PAN required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Assessment Year (AY)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _assessmentYear,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: '2025-2026', child: Text('AY 2025-2026 (FY 2024-25)')),
                      DropdownMenuItem(value: '2024-2025', child: Text('AY 2024-2025 (FY 2023-24)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _assessmentYear = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Type of Payment (Major Head)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _taxType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Advance Tax (100)', child: Text('Advance Tax (100)')),
                      DropdownMenuItem(value: 'Self-Assessment Tax (300)', child: Text('Self-Assessment Tax (300)')),
                      DropdownMenuItem(value: 'Tax on Regular Assessment (400)', child: Text('Regular Assessment (400)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _taxType = v);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Tax Amount to Pay (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '10000',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter valid amount' : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _showChallanReceipt('ITNS-280', _panCtrl.text.trim().toUpperCase(), _amountCtrl.text.trim(), 'Income Tax Department (CBDT)');
                        }
                      },
                      child: const Text('Proceed to Pay Challan 280', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallanReceipt(String challan, String id, String amount, String authority) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF046A38)),
            const SizedBox(width: 8),
            Text('$challan Generated', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authority: $authority', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text('Identifier: $id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('Amount: ₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF046A38))),
            const SizedBox(height: 8),
            Text('BSR Code: 0210041 • CIN: 0210041${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            const Text('Payment will be debited via AikSetra UPI and official CIN e-Receipt will be issued instantly.', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Challan payment of ₹$amount successful! e-Receipt saved to downloads.')),
              );
            },
            child: const Text('Pay with UPI'),
          ),
        ],
      ),
    );
  }
}

// 2. GST PMT-06 CHALLAN
class GstPmt06View extends StatefulWidget {
  const GstPmt06View({super.key});
  @override
  State<GstPmt06View> createState() => _GstPmt06ViewState();
}

class _GstPmt06ViewState extends State<GstPmt06View> {
  final _gstinCtrl = TextEditingController(text: '19AAACA1234A1Z5');
  final _cgstCtrl = TextEditingController(text: '4500');
  final _sgstCtrl = TextEditingController(text: '4500');
  final _igstCtrl = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    final cgst = double.tryParse(_cgstCtrl.text) ?? 0.0;
    final sgst = double.tryParse(_sgstCtrl.text) ?? 0.0;
    final igst = double.tryParse(_igstCtrl.text) ?? 0.0;
    final total = cgst + sgst + igst;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOfficialBanner('GST PMT-06 Monthly / Quarterly return tax payment via GSTN portal.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('GSTIN (15 Digits)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  controller: _gstinCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: '19AAACA1234A1Z5',
                    prefixIcon: const Icon(Icons.business),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CGST (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _cgstCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SGST (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _sgstCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('IGST (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _igstCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Challan Payable:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF046A38))),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Generated GST PMT-06 Challan for ₹$total. Redirecting to UPI...')),
                      );
                    },
                    child: const Text('Generate PMT-06 & Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

// 3. PROPERTY TAX VIEW
class PropertyTaxView extends StatelessWidget {
  const PropertyTaxView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOfficialBanner('Pay Municipal Corporation Property Tax with instant receipt and rebate.'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Municipal Body', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: 'KMC',
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: const [
                    DropdownMenuItem(value: 'KMC', child: Text('Kolkata Municipal Corporation (KMC)')),
                    DropdownMenuItem(value: 'MCGM', child: Text('Brihanmumbai Municipal Corp (MCGM)')),
                    DropdownMenuItem(value: 'BBMP', child: Text('Bruhat Bengaluru Mahanagara Palike (BBMP)')),
                    DropdownMenuItem(value: 'MCD', child: Text('Municipal Corporation of Delhi (MCD)')),
                  ],
                  onChanged: (_) {},
                ),
                const SizedBox(height: 14),
                const Text('Assessee / Property Holding No.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                const SizedBox(height: 6),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'e.g. 110-2490-8812',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fetching property tax bill from municipal servers...')),
                      );
                    },
                    child: const Text('Fetch Property Bill', style: TextStyle(fontWeight: FontWeight.bold)),
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

// 4. MUNICIPAL BILLS VIEW
class MunicipalBillsView extends StatelessWidget {
  const MunicipalBillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOfficialBanner('Bharat BillPay (BBPS) certified municipal dues: Water, Sewage, Trade License.'),
          const SizedBox(height: 16),
          _buildDuesTile('Water & Sewage Tax', 'Bangalore Water Supply & Sewerage Board (BWSSB)', 'RR Number', Icons.water_drop),
          _buildDuesTile('Municipal Trade License Renewal', 'Kolkata Municipal Corporation (KMC)', 'License Certificate ID', Icons.storefront),
          _buildDuesTile('Development Authority Dues', 'Delhi Development Authority (DDA)', 'Allotment Challan Number', Icons.account_balance),
        ],
      ),
    );
  }

  Widget _buildDuesTile(String title, String issuer, String idLabel, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFEFF6FF),
            child: Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 2),
                Text(issuer, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text('Requires: $idLabel', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF046A38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {},
            child: const Text('Pay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

Widget _buildOfficialBanner(String text) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFBFDBFE)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified, color: Color(0xFF1D4ED8), size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500)),
        ),
      ],
    ),
  );
}
