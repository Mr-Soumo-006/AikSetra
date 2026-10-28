import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/bharat_one_pay_api.dart';
import '../services/theme_manager.dart';

class BankAccountSwitcherModal {
  static Future<BankAccountModel?> show(
    BuildContext context, {
    String title = 'Select Bank Account',
    String subtitle = 'Choose an account for UPI transactions & settlements',
    bool isBusinessContext = false,
    String? selectedAccountId,
    ValueChanged<BankAccountModel>? onAccountSelected,
  }) async {
    final acc = await showModalBottomSheet<BankAccountModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BankAccountSwitcherSheet(
        title: title,
        subtitle: subtitle,
        isBusinessContext: isBusinessContext,
        selectedAccountId: selectedAccountId,
      ),
    );
    if (acc != null && onAccountSelected != null) {
      onAccountSelected(acc);
    }
    return acc;
  }

  static Future<BankAccountModel?> showAddAccountDialog(
    BuildContext context, {
    bool isBusinessContext = false,
  }) async {
    return _showAddAccountDialogHelper(context, isBusinessContext: isBusinessContext);
  }
}

class _BankAccountSwitcherSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isBusinessContext;
  final String? selectedAccountId;

  const _BankAccountSwitcherSheet({
    required this.title,
    required this.subtitle,
    required this.isBusinessContext,
    this.selectedAccountId,
  });

  @override
  State<_BankAccountSwitcherSheet> createState() => _BankAccountSwitcherSheetState();
}

class _BankAccountSwitcherSheetState extends State<_BankAccountSwitcherSheet> {
  String _filter = 'ALL'; // ALL, SAVINGS, CURRENT
  late String _currentSelectedId;

  @override
  void initState() {
    super.initState();
    if (widget.selectedAccountId != null) {
      _currentSelectedId = widget.selectedAccountId!;
    } else if (widget.isBusinessContext) {
      _currentSelectedId = BharatOnePayApi.currentBusinessAccount?.id ??
          BharatOnePayApi.currentAccount?.id ??
          (BharatOnePayApi.linkedAccounts.isNotEmpty ? BharatOnePayApi.linkedAccounts.first.id : '');
    } else {
      _currentSelectedId = BharatOnePayApi.currentAccount?.id ??
          (BharatOnePayApi.linkedAccounts.isNotEmpty ? BharatOnePayApi.linkedAccounts.first.id : '');
    }
  }

  Future<void> _showAddBankAccountDialog() async {
    final acc = await _showAddAccountDialogHelper(context, isBusinessContext: widget.isBusinessContext);
    if (acc != null && mounted) {
      setState(() {
        _currentSelectedId = acc.id;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${acc.bankName} (${acc.accountType}) linked successfully!'),
          backgroundColor: const Color(0xFF046A38),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager.isDarkMode;
    final cardBg = isDark ? const Color(0xFF131B2E) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final accounts = BharatOnePayApi.linkedAccounts;
    final filtered = accounts.where((a) {
      if (_filter == 'SAVINGS') return a.accountType == 'SAVINGS';
      if (_filter == 'CURRENT') return a.accountType == 'CURRENT';
      return true;
    }).toList();

    final savingsCount = accounts.where((a) => a.accountType == 'SAVINGS').length;
    final currentCount = accounts.where((a) => a.accountType == 'CURRENT').length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            widget.isBusinessContext ? Icons.storefront_rounded : Icons.account_balance_rounded,
                            color: widget.isBusinessContext ? const Color(0xFF046A38) : const Color(0xFFFF671F),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.title,
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
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
          ),
          const Divider(height: 1),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip('ALL', 'All (${accounts.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('SAVINGS', 'Savings ($savingsCount)'),
                const SizedBox(width: 8),
                _buildFilterChip('CURRENT', 'Current ($currentCount)'),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF046A38)),
                  label: const Text('Add Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                  onPressed: _showAddBankAccountDialog,
                ),
              ],
            ),
          ),

          // Account List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final acc = filtered[idx];
                final isSelected = acc.id == _currentSelectedId;
                final isCurrent = acc.accountType == 'CURRENT';

                return InkWell(
                  onTap: () async {
                    setState(() => _currentSelectedId = acc.id);
                    if (widget.isBusinessContext) {
                      await BharatOnePayApi.switchBusinessAccount(acc.id);
                    } else {
                      await BharatOnePayApi.switchPrimaryAccount(acc.id);
                    }
                    if (context.mounted) Navigator.pop(context, acc);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4))
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF046A38) : cardBorder,
                        width: isSelected ? 1.8 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Bank Icon with distinctive ring
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _getBankColor(acc.bankName).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getBankColor(acc.bankName).withValues(alpha: 0.3)),
                          ),
                          child: Icon(Icons.account_balance, color: _getBankColor(acc.bankName), size: 24),
                        ),
                        const SizedBox(width: 12),

                        // Account Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      acc.bankName,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isCurrent ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      acc.accountType,
                                      style: TextStyle(
                                        color: isCurrent ? const Color(0xFF1D4ED8) : const Color(0xFF046A38),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  if (acc.isPrimary) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF671F),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text('DEFAULT', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${acc.maskedAccountNumber} • IFSC: ${acc.ifsc}',
                                style: TextStyle(fontSize: 11, color: textSecondary),
                              ),
                              Text(
                                '${acc.branch} • Balance: ₹${acc.balance.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 10.5, color: textSecondary.withValues(alpha: 0.85), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),

                        // Radio check icon
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFF046A38) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF046A38) : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Link Another Bank Account (Current or Savings)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _showAddBankAccountDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filter == key;
    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF046A38) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF046A38) : const Color(0xFFCBD5E1)),
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

  Color _getBankColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('sbi') || n.contains('state bank')) return const Color(0xFF1E40AF);
    if (n.contains('hdfc')) return const Color(0xFF004C8F);
    if (n.contains('icici')) return const Color(0xFFB91C1C);
    if (n.contains('axis')) return const Color(0xFF831843);
    if (n.contains('kotak')) return const Color(0xFFDC2626);
    if (n.contains('punjab') || n.contains('pnb')) return const Color(0xFFD97706);
    return const Color(0xFF046A38);
  }
}

Future<BankAccountModel?> _showAddAccountDialogHelper(BuildContext context, {bool isBusinessContext = false}) async {
  final formKey = GlobalKey<FormState>();
  final bankCtrl = TextEditingController(text: 'Kotak Mahindra Bank');
  final accCtrl = TextEditingController();
  final ifscCtrl = TextEditingController(text: 'KKBK0000123');
  final branchCtrl = TextEditingController(text: 'Sector V Branch');
  String accountType = isBusinessContext ? 'CURRENT' : 'SAVINGS';

  return showModalBottomSheet<BankAccountModel>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (addCtx) => StatefulBuilder(
      builder: (context, setModalState) {
        final isDark = ThemeManager.isDarkMode;
                final cardBorder = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);
        final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
        final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

        return Padding(
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
                      Text('Link New Bank Account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textPrimary)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(addCtx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Link a verified Savings or Current account for high-limit UPI & settlements.',
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Account Type selector
                  Text('Account Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => accountType = 'SAVINGS'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: accountType == 'SAVINGS'
                                  ? const Color(0xFF046A38).withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accountType == 'SAVINGS' ? const Color(0xFF046A38) : cardBorder,
                                width: accountType == 'SAVINGS' ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.savings_outlined, size: 16, color: accountType == 'SAVINGS' ? const Color(0xFF046A38) : textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SAVINGS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: accountType == 'SAVINGS' ? const Color(0xFF046A38) : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('Personal / Salary', style: TextStyle(fontSize: 10, color: textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => accountType = 'CURRENT'),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: accountType == 'CURRENT'
                                  ? const Color(0xFF1D4ED8).withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: accountType == 'CURRENT' ? const Color(0xFF1D4ED8) : cardBorder,
                                width: accountType == 'CURRENT' ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.business_center_outlined, size: 16, color: accountType == 'CURRENT' ? const Color(0xFF1D4ED8) : textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'CURRENT',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: accountType == 'CURRENT' ? const Color(0xFF1D4ED8) : textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                Text('Business & Trade', style: TextStyle(fontSize: 10, color: textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: bankCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. State Bank of India',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  Text('Account Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: accCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter account number',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().length < 8) ? 'Enter valid account number' : null,
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('IFSC Code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: ifscCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'SBIN0001234',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Branch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: branchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Branch Name',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final res = await BharatOnePayApi.linkNewBankAccount(
                            bankName: bankCtrl.text.trim(),
                            accountType: accountType,
                            accountNumber: accCtrl.text.trim(),
                            ifsc: ifscCtrl.text.trim(),
                            branch: branchCtrl.text.trim(),
                            isBusiness: isBusinessContext || accountType == 'CURRENT',
                          );
                          if (addCtx.mounted) Navigator.pop(addCtx, res['account'] as BankAccountModel?);
                        }
                      },
                      child: const Text('Verify & Link Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
