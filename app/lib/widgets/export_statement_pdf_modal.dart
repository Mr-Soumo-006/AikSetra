import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/bharat_one_pay_api.dart';
import '../services/theme_manager.dart';

class ExportStatementPdfModal extends StatefulWidget {
  final bool initialIsBusiness;

  const ExportStatementPdfModal({
    super.key,
    this.initialIsBusiness = false,
  });

  static Future<void> show(BuildContext context, {bool initialIsBusiness = false}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ExportStatementPdfModal(initialIsBusiness: initialIsBusiness),
    );
  }

  @override
  State<ExportStatementPdfModal> createState() => _ExportStatementPdfModalState();
}

class _ExportStatementPdfModalState extends State<ExportStatementPdfModal> {
  late bool _isBusiness;
  String _selectedPreset = 'Current Month';
  DateTimeRange? _customDateRange;

  final List<Map<String, String>> _presets = [
    {'label': 'Today', 'period': "Today's Business Ledger (30 Oct 2026)", 'start': '30 Oct 2026', 'end': '30 Oct 2026'},
    {'label': 'Last 7 Days', 'period': 'Last 7 Days Statement (24 Oct - 30 Oct 2026)', 'start': '24 Oct 2026', 'end': '30 Oct 2026'},
    {'label': 'Current Month', 'period': 'October 2026 Monthly Statement', 'start': '01 Oct 2026', 'end': '30 Oct 2026'},
    {'label': 'Previous Month', 'period': 'September 2026 Monthly Statement', 'start': '01 Sep 2026', 'end': '30 Sep 2026'},
    {'label': 'Quarter 3 (Q3)', 'period': 'FY 2026-27 Q3 Statement (Oct - Dec)', 'start': '01 Oct 2026', 'end': '31 Dec 2026'},
    {'label': 'FY 2026-27', 'period': 'Annual Statement FY 2026-27', 'start': '01 Apr 2026', 'end': '31 Mar 2027'},
  ];

  @override
  void initState() {
    super.initState();
    _isBusiness = widget.initialIsBusiness;
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  void _pickCustomDateRange() async {
    final now = DateTime(2026, 10, 30);
    final initialRange = _customDateRange ?? DateTimeRange(start: DateTime(2026, 10, 1), end: now);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF046A38),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0D1B2A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPreset = 'Custom';
      });
    }
  }

  void _downloadPdf() async {
    String periodTitle;
    String startDate;
    String endDate;

    if (_selectedPreset == 'Custom' && _customDateRange != null) {
      startDate = _formatDate(_customDateRange!.start);
      endDate = _formatDate(_customDateRange!.end);
      periodTitle = 'Custom Timeline ($startDate - $endDate)';
    } else {
      final presetObj = _presets.firstWhere(
        (p) => p['label'] == _selectedPreset,
        orElse: () => _presets[2],
      );
      periodTitle = presetObj['period']!;
      startDate = presetObj['start']!;
      endDate = presetObj['end']!;
    }

    final biz = _isBusiness;
    final holder = biz ? (BharatOnePayApi.businessProfile['companyName'] ?? 'Pentile Business Solutions') : (BharatOnePayApi.currentUser?.fullName ?? 'Soumo Naskar');
    final acc = biz ? 'Pentile Digital Store (Current Account)' : (BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India (Primary)');
    final accNo = biz ? (BharatOnePayApi.businessProfile['bankAccountNo'] ?? '•••• 4589') : (BharatOnePayApi.currentAccount?.maskedAccountNumber ?? '•••• 3038');
    final pan = biz ? (BharatOnePayApi.businessProfile['pan'] ?? 'AAECN1234F') : 'AAECN1234F';
    final gstin = biz ? (BharatOnePayApi.businessProfile['gstin'] ?? '19AAECN1234F1Z5') : '';
    final ifsc = biz ? (BharatOnePayApi.businessProfile['ifsc'] ?? 'HDFC0001234') : (BharatOnePayApi.currentAccount?.ifsc ?? 'SBIN0001234');

    final pdfUrl = BharatOnePayApi.getStatementPdfUrl(
      isBusiness: biz,
      period: periodTitle,
      startDate: startDate,
      endDate: endDate,
      holderName: holder,
      accountName: acc,
      accountNumber: accNo,
      panNumber: pan,
      gstin: gstin,
      ifsc: ifsc,
      openingBalance: biz ? 42500.0 : 35200.0,
      closingBalance: biz ? (BharatOnePayApi.businessProfile['balance'] as num?)?.toDouble() ?? 48250.0 : (BharatOnePayApi.currentAccount?.balance ?? 85400.0),
    );

    Navigator.pop(context);

    try {
      final uri = Uri.parse(pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF046A38),
            content: Text('Generating official PDF statement for $periodTitle...'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Opening PDF statement download...')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0D1B2A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final biz = _isBusiness;
    final holder = biz ? (BharatOnePayApi.businessProfile['companyName'] ?? 'Pentile Business Solutions') : (BharatOnePayApi.currentUser?.fullName ?? 'Soumo Naskar');
    final acc = biz ? 'Pentile Digital Store (Current Account)' : (BharatOnePayApi.currentAccount?.bankName ?? 'State Bank of India (Primary)');
    final accNo = biz ? (BharatOnePayApi.businessProfile['bankAccountNo'] ?? '•••• 4589') : (BharatOnePayApi.currentAccount?.maskedAccountNumber ?? '•••• 3038');
    final pan = biz ? (BharatOnePayApi.businessProfile['pan'] ?? 'AAECN1234F') : 'AAECN1234F';
    final gstin = biz ? (BharatOnePayApi.businessProfile['gstin'] ?? '19AAECN1234F1Z5') : 'N/A (Personal Individual)';
    final ifsc = biz ? (BharatOnePayApi.businessProfile['ifsc'] ?? 'HDFC0001234') : (BharatOnePayApi.currentAccount?.ifsc ?? 'SBIN0001234');

    String currentTimelineStr;
    if (_selectedPreset == 'Custom' && _customDateRange != null) {
      currentTimelineStr = '${_formatDate(_customDateRange!.start)}  to  ${_formatDate(_customDateRange!.end)}';
    } else {
      final p = _presets.firstWhere((p) => p['label'] == _selectedPreset, orElse: () => _presets[2]);
      currentTimelineStr = '${p['start']}  to  ${p['end']}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Final Accounts & Audit PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
                      ),
                      Text(
                        'Choose accounting timeline & confirm credentials for certified PDF statement',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24),

            // 1. Account Selector Toggle
            Text(
              'Select Account Credentials',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isBusiness = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _isBusiness ? const Color(0xFF046A38) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _isBusiness ? const Color(0xFF046A38) : cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront, size: 16, color: _isBusiness ? Colors.white : textPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Business Account',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _isBusiness ? Colors.white : textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pentile (••••4589)',
                            style: TextStyle(
                              fontSize: 10,
                              color: _isBusiness ? Colors.white70 : textSecondary,
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
                    onTap: () => setState(() => _isBusiness = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: !_isBusiness ? const Color(0xFF046A38) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: !_isBusiness ? const Color(0xFF046A38) : cardBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, size: 16, color: !_isBusiness ? Colors.white : textPrimary),
                              const SizedBox(width: 6),
                              Text(
                                'Personal Savings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: !_isBusiness ? Colors.white : textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'SBI (••••3038)',
                            style: TextStyle(
                              fontSize: 10,
                              color: !_isBusiness ? Colors.white70 : textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 2. Accounting Timeline / Date System
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Timeline / Accounting Period',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textPrimary),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  icon: const Icon(Icons.date_range, size: 15, color: Color(0xFF046A38)),
                  label: const Text('Custom Dates', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                  onPressed: _pickCustomDateRange,
                ),
              ],
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._presets.map((p) {
                  final isSel = _selectedPreset == p['label'];
                  return ChoiceChip(
                    label: Text(p['label']!),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedPreset = p['label']!),
                    selectedColor: const Color(0xFF0D1B2A),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  );
                }),
                if (_customDateRange != null)
                  ChoiceChip(
                    label: Text('Custom: ${_formatDate(_customDateRange!.start)} - ${_formatDate(_customDateRange!.end)}'),
                    selected: _selectedPreset == 'Custom',
                    onSelected: (_) => setState(() => _selectedPreset = 'Custom'),
                    selectedColor: const Color(0xFFFF9100),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),

            // 3. Credentials & Parameters Stamped on PDF
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CREDENTIALS STAMPED ON PDF',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5, color: Color(0xFF046A38)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF059669).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUDIT VERIFIED',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  _buildPreviewRow('Legal Entity:', holder, textPrimary, textSecondary),
                  const SizedBox(height: 4),
                  _buildPreviewRow('Account / Bank:', '$acc ($accNo)', textPrimary, textSecondary),
                  const SizedBox(height: 4),
                  _buildPreviewRow('PAN Number:', pan, textPrimary, textSecondary),
                  const SizedBox(height: 4),
                  _buildPreviewRow('GSTIN:', gstin, textPrimary, textSecondary),
                  const SizedBox(height: 4),
                  _buildPreviewRow('IFSC Code:', ifsc, textPrimary, textSecondary),
                  const SizedBox(height: 4),
                  _buildPreviewRow('Audit Timeline:', currentTimelineStr, const Color(0xFF1E3A8A), textSecondary, boldVal: true),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Download PDF Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF046A38),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.download, size: 18),
                label: const Text(
                  'Download Certified Statement PDF',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _downloadPdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, Color valColor, Color labelColor, {bool boldVal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: labelColor)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: boldVal ? FontWeight.bold : FontWeight.w600,
              color: valColor,
            ),
          ),
        ),
      ],
    );
  }
}
