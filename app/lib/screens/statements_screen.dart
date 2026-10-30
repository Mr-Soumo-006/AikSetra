import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bharat_one_pay_api.dart';

class StatementsScreen extends StatefulWidget {
  const StatementsScreen({super.key});

  @override
  State<StatementsScreen> createState() => _StatementsScreenState();
}

class _StatementsScreenState extends State<StatementsScreen> {
  String _selectedAccount = 'All Accounts';
  String _selectedPeriod = 'Last 30 Days';
  String _searchQuery = '';

  final List<String> _accounts = ['All Accounts', 'HDFC Bank (••4092)', 'State Bank of India (••8821)', 'AikSetra Wallet'];
  final List<String> _periods = ['This Month', 'Last 30 Days', 'Last 3 Months', 'FY 2024-25'];

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TXN10091',
      'title': 'Salary Credit - AikSetra Tech',
      'date': '25 Oct 2026, 09:30 AM',
      'amount': 85000.0,
      'type': 'credit',
      'account': 'HDFC Bank (••4092)',
      'category': 'Salary',
      'ref': 'NEFT/HDFC/202610250930',
    },
    {
      'id': 'TXN10084',
      'title': 'Auto-SIP - Nifty 50 Index Fund',
      'date': '24 Oct 2026, 06:00 AM',
      'amount': 5000.0,
      'type': 'debit',
      'account': 'HDFC Bank (••4092)',
      'category': 'Investment',
      'ref': 'NACH/UMRN/202610240600',
    },
    {
      'id': 'TXN10079',
      'title': 'CESC Electricity Bill',
      'date': '22 Oct 2026, 04:15 PM',
      'amount': 2450.0,
      'type': 'debit',
      'account': 'State Bank of India (••8821)',
      'category': 'BBPS Utility',
      'ref': 'BBPS/CESC/88192014',
    },
    {
      'id': 'TXN10065',
      'title': 'Cross-Border FX Pay - US College',
      'date': '19 Oct 2026, 02:40 PM',
      'amount': 42075.0,
      'type': 'debit',
      'account': 'HDFC Bank (••4092)',
      'category': 'Forex Remittance',
      'ref': 'SWIFT/FX/202610190240',
    },
    {
      'id': 'TXN10052',
      'title': 'Cashback Reward Credited',
      'date': '18 Oct 2026, 08:00 PM',
      'amount': 150.0,
      'type': 'credit',
      'account': 'AikSetra Wallet',
      'category': 'Rewards',
      'ref': 'AIK/REWARD/77192',
    },
    {
      'id': 'TXN10041',
      'title': 'Swiggy Food Delivery',
      'date': '16 Oct 2026, 09:12 PM',
      'amount': 480.0,
      'type': 'debit',
      'account': 'HDFC Bank (••4092)',
      'category': 'Food',
      'ref': 'UPI/SWIGGY/991204',
    },
  ];

  void _downloadStatementPdf() async {
    final pdfUrl = BharatOnePayApi.getStatementPdfUrl();
    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Generating official PDF audit statement for $_selectedPeriod ($_selectedAccount)...'),
          backgroundColor: const Color(0xFF046A38),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening PDF statement download...'),
          backgroundColor: Color(0xFF0D1B2A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _transactions.where((t) {
      if (_selectedAccount != 'All Accounts' && t['account'] != _selectedAccount) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (t['title'] as String).toLowerCase();
        final cat = (t['category'] as String).toLowerCase();
        final ref = (t['ref'] as String).toLowerCase();
        if (!title.contains(q) && !cat.contains(q) && !ref.contains(q)) return false;
      }
      return true;
    }).toList();

    double totalIn = 0;
    double totalOut = 0;
    for (final t in filtered) {
      if (t['type'] == 'credit') {
        totalIn += (t['amount'] as double);
      } else {
        totalOut += (t['amount'] as double);
      }
    }
    final netFlow = totalIn - totalOut;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Combined Statements & Passbook', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFFF671F)),
            tooltip: 'Download Official PDF Audit Statement',
            onPressed: _downloadStatementPdf,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export CSV',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transactions exported as Excel / CSV file.')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: const Color(0xFF0D1B2A),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.12),
                    hintText: 'Search by payee, category or ref number...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedAccount,
                            dropdownColor: const Color(0xFF0D1B2A),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                            items: _accounts.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedAccount = v);
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPeriod,
                            dropdownColor: const Color(0xFF0D1B2A),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            icon: const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                            items: _periods.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedPeriod = v);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Cashflow Summary Metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('Money In (Credits)', '+₹${totalIn.toStringAsFixed(0)}', const Color(0xFF046A38)),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                _buildMetricColumn('Money Out (Debits)', '-₹${totalOut.toStringAsFixed(0)}', const Color(0xFFDC2626)),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                _buildMetricColumn('Net Cashflow', '${netFlow >= 0 ? '+' : ''}₹${netFlow.toStringAsFixed(0)}', netFlow >= 0 ? const Color(0xFF046A38) : const Color(0xFFDC2626)),
              ],
            ),
          ),
          const Divider(height: 1),

          // Transactions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_outlined, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No transactions match the selected filters', style: TextStyle(color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final txn = filtered[idx];
                      final isCredit = txn['type'] == 'credit';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: isCredit ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isCredit ? const Color(0xFF046A38) : const Color(0xFFDC2626),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(txn['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D1B2A))),
                                      const SizedBox(height: 2),
                                      Text('${txn['account']} • ${txn['date']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isCredit ? '+' : '-'}₹${(txn['amount'] as double).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isCredit ? const Color(0xFF046A38) : const Color(0xFF0D1B2A),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(6)),
                                  child: Text(txn['category'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                ),
                                Text('Ref: ${txn['ref']}', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
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

  Widget _buildMetricColumn(String label, String value, Color valColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: valColor)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
      ],
    );
  }
}
