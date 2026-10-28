import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BeneficiariesScreen extends StatefulWidget {
  final Function(String upiId, String name)? onSelectPayee;

  const BeneficiariesScreen({super.key, this.onSelectPayee});

  @override
  State<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends State<BeneficiariesScreen> {
  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _beneficiaries = [
    {
      'id': 'ben_01',
      'name': 'Rahul Verma',
      'upiId': 'rahulverma@okhdfcbank',
      'type': 'UPI ID',
      'bank': 'HDFC Bank',
      'accountNo': null,
      'isVerified': true,
      'avatarColor': 0xFF1E3A8A,
      'initials': 'RV',
      'lastPaid': 'Yesterday',
    },
    {
      'id': 'ben_02',
      'name': 'Pooja Sharma',
      'upiId': 'poojasharma@icici',
      'type': 'UPI ID',
      'bank': 'ICICI Bank',
      'accountNo': null,
      'isVerified': true,
      'avatarColor': 0xFF046A38,
      'initials': 'PS',
      'lastPaid': '21 Oct 2026',
    },
    {
      'id': 'ben_03',
      'name': 'Amit Patel & Sons',
      'upiId': null,
      'type': 'Bank Account',
      'bank': 'State Bank of India',
      'accountNo': '•••• •••• 9812',
      'ifsc': 'SBIN0001420',
      'isVerified': true,
      'avatarColor': 0xFFB45309,
      'initials': 'AP',
      'lastPaid': '14 Oct 2026',
    },
    {
      'id': 'ben_04',
      'name': 'Dr. Sunita Sen',
      'upiId': 'drsunita@axisbank',
      'type': 'UPI ID',
      'bank': 'Axis Bank',
      'accountNo': null,
      'isVerified': true,
      'avatarColor': 0xFF6D28D9,
      'initials': 'SS',
      'lastPaid': '05 Oct 2026',
    },
    {
      'id': 'ben_05',
      'name': 'Kolkata Electric Corp',
      'upiId': 'cesc.billing@icici',
      'type': 'Merchant',
      'bank': 'CESC Ltd',
      'accountNo': null,
      'isVerified': true,
      'avatarColor': 0xFF0D1B2A,
      'initials': 'CE',
      'lastPaid': '01 Oct 2026',
    },
  ];

  void _showAddBeneficiaryModal() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final upiOrAccCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    String payeeType = 'UPI ID';

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
                      const Text('Add New Beneficiary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('UPI ID (VPA)')),
                          selected: payeeType == 'UPI ID',
                          selectedColor: const Color(0xFF046A38),
                          labelStyle: TextStyle(color: payeeType == 'UPI ID' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) setModalState(() => payeeType = 'UPI ID');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Bank A/C + IFSC')),
                          selected: payeeType == 'Bank Account',
                          selectedColor: const Color(0xFF046A38),
                          labelStyle: TextStyle(color: payeeType == 'Bank Account' ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                          onSelected: (val) {
                            if (val) setModalState(() => payeeType = 'Bank Account');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(payeeType == 'UPI ID' ? 'Beneficiary UPI ID' : 'Account Number', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: upiOrAccCtrl,
                    decoration: InputDecoration(
                      hintText: payeeType == 'UPI ID' ? 'mobile@upi or name@bank' : 'Enter 9-18 digit account number',
                      prefixIcon: Icon(payeeType == 'UPI ID' ? Icons.alternate_email : Icons.account_balance),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  if (payeeType == 'Bank Account') ...[
                    const SizedBox(height: 14),
                    const Text('Bank IFSC Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ifscCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. HDFC0000123',
                        prefixIcon: const Icon(Icons.apartment),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => (v == null || v.trim().length != 11) ? '11-character IFSC code required' : null,
                    ),
                  ],
                  const SizedBox(height: 14),
                  const Text('Beneficiary Legal Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Name as registered with bank',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFF1D4ED8), size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'NPCI Penny-Drop / VPA Lookup will verify this payee before any transaction.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A)),
                          ),
                        ),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final name = nameCtrl.text.trim();
                          final idVal = upiOrAccCtrl.text.trim();
                          final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

                          setState(() {
                            _beneficiaries.insert(0, {
                              'id': 'ben_${DateTime.now().millisecondsSinceEpoch}',
                              'name': name,
                              'upiId': payeeType == 'UPI ID' ? idVal : null,
                              'type': payeeType,
                              'bank': payeeType == 'UPI ID' ? 'NPCI Verified Bank' : (ifscCtrl.text.trim().toUpperCase()),
                              'accountNo': payeeType == 'Bank Account' ? '•••• ${idVal.substring(idVal.length - 4)}' : null,
                              'ifsc': payeeType == 'Bank Account' ? ifscCtrl.text.trim().toUpperCase() : null,
                              'isVerified': true,
                              'avatarColor': 0xFF0D1B2A,
                              'initials': initials.isEmpty ? 'BP' : initials,
                              'lastPaid': 'Just added',
                            });
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Beneficiary $name added and verified!'),
                              backgroundColor: const Color(0xFF046A38),
                            ),
                          );
                        }
                      },
                      child: const Text('Verify & Save Beneficiary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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

  void _confirmPay(Map<String, dynamic> payee) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFF046A38), size: 26),
            const SizedBox(width: 8),
            const Text('Scam Shield Verified', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paying: ${payee['name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 6),
            Text(payee['upiId'] ?? 'A/C: ${payee['accountNo']} (${payee['ifsc']})', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF046A38), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Account verified under NPCI directory. No suspicious activity reported.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF046A38), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              if (widget.onSelectPayee != null) {
                widget.onSelectPayee!(payee['upiId'] ?? 'beneficiary@bank', payee['name'] as String);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Selected ${payee['name']} (${payee['upiId'] ?? payee['accountNo']}). Returning to payment.'),
                    backgroundColor: const Color(0xFF046A38),
                  ),
                );
                Navigator.pop(context, payee);
              }
            },
            child: const Text('Proceed to Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickNativeDeviceContact() async {
    try {
      const channel = MethodChannel('in.bharatonepay/contacts');
      final res = await channel.invokeMethod<Map>('pickContact');
      if (res != null) {
        final name = (res['name'] ?? '').toString().trim();
        final phone = (res['phone'] ?? '').toString().trim();
        if (phone.isNotEmpty) {
          final upi = phone.length == 10 ? '$phone@aiksetra' : '$phone@upi';
          if (widget.onSelectPayee != null) {
            widget.onSelectPayee!(upi, name.isNotEmpty ? name : 'Contact ($phone)');
            Navigator.pop(context);
          } else {
            setState(() {
              _beneficiaries.insert(0, {
                'id': 'ben_contact_${DateTime.now().millisecondsSinceEpoch}',
                'name': name.isNotEmpty ? name : 'Contact ($phone)',
                'upiId': upi,
                'type': 'UPI ID',
                'bank': 'Phone Contact',
                'accountNo': null,
                'isVerified': true,
                'avatarColor': 0xFF046A38,
                'initials': name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'C',
                'lastPaid': 'Just now',
              });
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Contact $name ($upi) added!'), backgroundColor: const Color(0xFF046A38)),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact picker not available on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _beneficiaries.where((b) {
      final nameMatches = (b['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final upiMatches = b['upiId'] != null && (b['upiId'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final accMatches = b['accountNo'] != null && (b['accountNo'] as String).contains(_searchQuery);

      final matchesQuery = nameMatches || upiMatches || accMatches;
      if (!matchesQuery) return false;

      if (_selectedFilterIndex == 1) return b['type'] == 'UPI ID';
      if (_selectedFilterIndex == 2) return b['type'] == 'Bank Account';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Contacts & Beneficiaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Beneficiary',
            onPressed: _showAddBeneficiaryModal,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
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
                    hintText: 'Search by name, UPI ID or account number...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: _pickNativeDeviceContact,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF671F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          '📱 Choose from Real Device Contacts',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _buildFilterChip('All Saved (${_beneficiaries.length})', 0),
                const SizedBox(width: 8),
                _buildFilterChip('UPI IDs', 1),
                const SizedBox(width: 8),
                _buildFilterChip('Bank Accounts', 2),
              ],
            ),
          ),
          const Divider(height: 1),

          // Beneficiary List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_search_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No beneficiaries found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final payee = filtered[idx];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: Color(payee['avatarColor'] as int),
                              child: Text(
                                payee['initials'] as String,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(payee['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0D1B2A))),
                                      if (payee['isVerified'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Color(0xFF046A38), size: 16),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    payee['upiId'] ?? '${payee['bank']} • ${payee['accountNo']}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Last paid: ${payee['lastPaid']}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF046A38),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _confirmPay(payee),
                              child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  Widget _buildFilterChip(String label, int index) {
    final sel = _selectedFilterIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      selectedColor: const Color(0xFF0D1B2A),
      labelStyle: TextStyle(
        color: sel ? Colors.white : const Color(0xFF475569),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      onSelected: (val) {
        if (val) setState(() => _selectedFilterIndex = index);
      },
    );
  }
}
