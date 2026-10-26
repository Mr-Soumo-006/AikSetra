import 'package:flutter/material.dart';
import '../services/bharat_one_pay_api.dart';

class AutoPayScreen extends StatefulWidget {
  const AutoPayScreen({super.key});

  @override
  State<AutoPayScreen> createState() => _AutoPayScreenState();
}

class _AutoPayScreenState extends State<AutoPayScreen> {
  bool _isLoading = true;
  List<dynamic> _mandates = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _loadMandates();
  }

  Future<void> _loadMandates() async {
    setState(() => _isLoading = true);
    final res = await BharatOnePayApi.getAutoPayMandates();
    if (res['success'] == true && mounted) {
      setState(() {
        _mandates = res['mandates'] ?? [];
        _summary = res['summary'] ?? {};
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleMandateStatus(String id, String currentStatus) async {
    final nextStatus = currentStatus == 'ACTIVE' ? 'PAUSED' : 'ACTIVE';
    final res = await BharatOnePayApi.updateAutoPayStatus(id, nextStatus);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mandate is now $nextStatus'), backgroundColor: const Color(0xFF046A38)),
      );
      _loadMandates();
    }
  }

  Future<void> _cancelMandate(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel AutoPay Mandate?'),
        content: const Text('This will permanently revoke the e-Mandate with your bank and cancel upcoming scheduled debits.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Mandate')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Cancel Mandate'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final res = await BharatOnePayApi.updateAutoPayStatus(id, 'CANCELLED');
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('e-Mandate revoked successfully with NPCI switch.'), backgroundColor: Color(0xFFDC2626)),
        );
        _loadMandates();
      }
    }
  }

  void _showCreateMandateModal() {
    final billerCtrl = TextEditingController();
    final vpaCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '1500');
    final pinCtrl = TextEditingController();
    String freq = 'MONTHLY';
    String category = 'ELECTRICITY';
    int debitDay = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Setup New Bank AutoPay Mandate', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const Text(
                      'NPCI e-Mandate registered directly with your linked bank. Debit occurs automatically on scheduled date.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: billerCtrl,
                      decoration: InputDecoration(
                        labelText: 'Biller / Merchant Name',
                        hintText: 'e.g. CESC Electricity, Netflix, Star Health',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: vpaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Biller UPI ID / VPA',
                        hintText: 'e.g. cesc@bbps, merchant@upi',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: category,
                            decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: const [
                              DropdownMenuItem(value: 'ELECTRICITY', child: Text('Electricity')),
                              DropdownMenuItem(value: 'BROADBAND', child: Text('Broadband')),
                              DropdownMenuItem(value: 'SUBSCRIPTION', child: Text('Subscription')),
                              DropdownMenuItem(value: 'INSURANCE', child: Text('Insurance')),
                              DropdownMenuItem(value: 'RENT', child: Text('House Rent')),
                            ],
                            onChanged: (v) => setModalState(() => category = v!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: freq,
                            decoration: InputDecoration(labelText: 'Frequency', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: const [
                              DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                              DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                              DropdownMenuItem(value: 'QUARTERLY', child: Text('Quarterly')),
                              DropdownMenuItem(value: 'ANNUALLY', child: Text('Annually')),
                            ],
                            onChanged: (v) => setModalState(() => freq = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Max Debit Limit (₹)',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: debitDay,
                            decoration: InputDecoration(labelText: 'Debit Day', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                            items: [1, 5, 10, 15, 20, 25, 28].map((d) => DropdownMenuItem(value: d, child: Text('Day $d of month'))).toList(),
                            onChanged: (v) => setModalState(() => debitDay = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: pinCtrl,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Authorize with UPI MPIN (e.g. 1234)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF046A38)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (billerCtrl.text.isEmpty || vpaCtrl.text.isEmpty || pinCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete all mandate fields.')));
                            return;
                          }
                          Navigator.pop(ctx);
                          final res = await BharatOnePayApi.createAutoPayMandate(
                            billerOrPayeeName: billerCtrl.text.trim(),
                            vpa: vpaCtrl.text.trim(),
                            category: category,
                            frequency: freq,
                            maxAmount: double.tryParse(amountCtrl.text) ?? 1500,
                            scheduledDay: debitDay,
                            mpin: pinCtrl.text.trim(),
                          );
                          if (res['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Mandate authorized successfully!'), backgroundColor: const Color(0xFF046A38)),
                            );
                            _loadMandates();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(res['message'] ?? 'Mandate authorization failed.'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046A38),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Authorize & Create Mandate (UMRN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('AutoPay & Mandates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        actions: [
          IconButton(onPressed: _loadMandates, icon: const Icon(Icons.refresh_rounded), tooltip: 'Refresh'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateMandateModal,
        backgroundColor: const Color(0xFF046A38),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Mandate', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMandates,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Summary Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('ACTIVE AUTOPAY COMMITMENT', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(6)),
                                child: const Text('NPCI e-MANDATE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('₹${_summary['monthlyCommitment'] ?? 0}/month', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text('${_summary['activeCount'] ?? 0} Active Mandates', style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 14),
                              Text('${_summary['pausedCount'] ?? 0} Paused', style: const TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    const Text('Bank-Authorized Mandates', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),

                    if (_mandates.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: const Text('No AutoPay mandates set up yet. Tap "+ New Mandate" below.'),
                      )
                    else
                      ..._mandates.map((m) {
                        final isActive = m['status'] == 'ACTIVE';
                        final isCancelled = m['status'] == 'CANCELLED';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: isActive ? const Color(0xFF046A38).withValues(alpha: 0.3) : const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: (isActive ? const Color(0xFF046A38) : Colors.grey).withValues(alpha: 0.12),
                                    child: Icon(
                                      m['category'] == 'ELECTRICITY' ? Icons.bolt_rounded : (m['category'] == 'INSURANCE' ? Icons.shield_rounded : Icons.autorenew_rounded),
                                      color: isActive ? const Color(0xFF046A38) : Colors.grey,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(m['billerOrPayeeName'] ?? 'Mandate', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                        const SizedBox(height: 2),
                                        Text('UMRN: ${m['umrn'] ?? "Pending"}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isActive ? const Color(0xFFDCFCE7) : (isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      m['status'] ?? 'ACTIVE',
                                      style: TextStyle(
                                        color: isActive ? const Color(0xFF046A38) : (isCancelled ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Max Debit Limit', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text('₹${m['maxAmount']} • ${m['frequency']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Next Debit Date', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                      Text(m['nextDebitDate'] ?? 'Scheduled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB))),
                                    ],
                                  ),
                                ],
                              ),
                              if (!isCancelled) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _toggleMandateStatus(m['id'], m['status']),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(isActive ? 'Pause Mandate' : 'Resume Mandate', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _cancelMandate(m['id']),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Cancel / Revoke', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
