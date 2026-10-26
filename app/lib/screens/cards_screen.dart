import 'package:flutter/material.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  int _selectedCardIndex = 0;

  final List<Map<String, dynamic>> _cards = [
    {
      'id': 'crd_01',
      'bank': 'HDFC Bank',
      'type': 'RuPay Credit Card on UPI',
      'number': '5241 •••• •••• 4092',
      'holder': 'SOUMO NASKAR',
      'expiry': '08/29',
      'network': 'RuPay',
      'isUpiLinked': true,
      'isDefault': true,
      'color1': 0xFF0D1B2A,
      'color2': 0xFF1B263B,
      'accent': 0xFFFF9100,
      'limit': 150000.0,
      'available': 124350.0,
      'onlineTxn': true,
      'tapAndPay': true,
      'intlTxn': false,
      'atmWithdrawal': false,
    },
    {
      'id': 'crd_02',
      'bank': 'State Bank of India',
      'type': 'Global Debit Card',
      'number': '4591 •••• •••• 8821',
      'holder': 'SOUMO NASKAR',
      'expiry': '11/27',
      'network': 'Visa',
      'isUpiLinked': false,
      'isDefault': false,
      'color1': 0xFF003366,
      'color2': 0xFF006699,
      'accent': 0xFF00C853,
      'limit': 100000.0,
      'available': 64200.0,
      'onlineTxn': true,
      'tapAndPay': true,
      'intlTxn': true,
      'atmWithdrawal': true,
    },
    {
      'id': 'crd_03',
      'bank': 'ICICI Bank',
      'type': 'Sapphiro Credit Card',
      'number': '5105 •••• •••• 3149',
      'holder': 'SOUMO NASKAR',
      'expiry': '04/30',
      'network': 'Mastercard',
      'isUpiLinked': false,
      'isDefault': false,
      'color1': 0xFF8B0000,
      'color2': 0xFFB22222,
      'accent': 0xFFFFD700,
      'limit': 300000.0,
      'available': 289100.0,
      'onlineTxn': true,
      'tapAndPay': false,
      'intlTxn': true,
      'atmWithdrawal': false,
    },
  ];

  final List<Map<String, dynamic>> _cardTransactions = [
    {'title': 'Amazon India', 'date': '24 Oct 2026, 4:15 PM', 'amount': '₹2,499.00', 'type': 'debit', 'status': 'Settled'},
    {'title': 'Swiggy Food Order', 'date': '23 Oct 2026, 8:30 PM', 'amount': '₹480.00', 'type': 'debit', 'status': 'Settled'},
    {'title': 'Fuel HP Petrol Pump', 'date': '22 Oct 2026, 11:10 AM', 'amount': '₹1,500.00', 'type': 'debit', 'status': 'Settled'},
    {'title': 'Card Payment Credit', 'date': '18 Oct 2026, 2:00 PM', 'amount': '₹15,000.00', 'type': 'credit', 'status': 'Credited'},
  ];

  void _showAddCardModal() {
    final formKey = GlobalKey<FormState>();
    final numberCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final expiryCtrl = TextEditingController();
    String cardType = 'RuPay UPI Credit';

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
                      const Text('Link Card or RuPay on UPI', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF81C784)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Color(0xFF046A38), size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'RBI Tokenized & NPCI Safe. We never store raw card numbers or CVV codes.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF046A38), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Card Category', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: cardType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'RuPay UPI Credit', child: Text('RuPay Credit Card (Link to UPI)')),
                      DropdownMenuItem(value: 'Visa/Mastercard Debit', child: Text('Debit Card (ATM / POS / Online)')),
                      DropdownMenuItem(value: 'Standard Credit Card', child: Text('Credit Card (Visa / Mastercard)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => cardType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text('Card Number (16 Digits)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: numberCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 16,
                    decoration: InputDecoration(
                      hintText: '4000 1234 5678 9010',
                      prefixIcon: const Icon(Icons.credit_card),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().length < 15) ? 'Enter a valid 16-digit card number' : null,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expiry (MM/YY)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: expiryCtrl,
                              maxLength: 5,
                              decoration: InputDecoration(
                                hintText: '12/28',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                counterText: '',
                              ),
                              validator: (v) => (v == null || !v.contains('/')) ? 'MM/YY' : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cardholder Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: nameCtrl,
                              textCapitalization: TextCapitalization.characters,
                              decoration: InputDecoration(
                                hintText: 'NAME ON CARD',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final numStr = numberCtrl.text.trim();
                          final masked = '${numStr.substring(0, 4)} •••• •••• ${numStr.substring(numStr.length - 4)}';
                          final isRuPay = cardType.contains('RuPay');

                          setState(() {
                            _cards.insert(0, {
                              'id': 'crd_${DateTime.now().millisecondsSinceEpoch}',
                              'bank': isRuPay ? 'HDFC Bank' : 'Federal Bank',
                              'type': cardType,
                              'number': masked,
                              'holder': nameCtrl.text.trim().toUpperCase(),
                              'expiry': expiryCtrl.text.trim(),
                              'network': isRuPay ? 'RuPay' : 'Visa',
                              'isUpiLinked': isRuPay,
                              'isDefault': false,
                              'color1': isRuPay ? 0xFF14213D : 0xFF2A2A72,
                              'color2': isRuPay ? 0xFF000000 : 0xFF009FFD,
                              'accent': 0xFFFF9100,
                              'limit': 100000.0,
                              'available': 100000.0,
                              'onlineTxn': true,
                              'tapAndPay': true,
                              'intlTxn': false,
                              'atmWithdrawal': !isRuPay,
                            });
                            _selectedCardIndex = 0;
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRuPay ? 'RuPay Credit Card tokenized and linked to UPI!' : 'Card successfully tokenized and saved!'),
                              backgroundColor: const Color(0xFF046A38),
                            ),
                          );
                        }
                      },
                      child: const Text('Tokenize & Link Card', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  void _removeSelectedCard() {
    if (_cards.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one payment card is required.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Card?'),
        content: Text('Remove ${_cards[_selectedCardIndex]['bank']} ${_cards[_selectedCardIndex]['number']} from AikSetra? This will delete the card token.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cards.removeAt(_selectedCardIndex);
                _selectedCardIndex = 0;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Card removed successfully.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('Remove Card'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentCard = _cards[_selectedCardIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Cards & UPI Credit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card),
            tooltip: 'Add Card',
            onPressed: _showAddCardModal,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards Carousel / Stack
            SizedBox(
              height: 215,
              child: PageView.builder(
                itemCount: _cards.length,
                controller: PageController(viewportFraction: 0.92),
                onPageChanged: (idx) => setState(() => _selectedCardIndex = idx),
                itemBuilder: (context, idx) {
                  final card = _cards[idx];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(card['color1'] as int), Color(card['color2'] as int)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Color(card['color1'] as int).withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card['bank'] as String,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    card['type'] as String,
                                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
                                  ),
                                ],
                              ),
                              if (card['isUpiLinked'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9100),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('UPI LINKED', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                )
                              else
                                Text(
                                  card['network'] as String,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.nfc, size: 20, color: Color(0xFF0D1B2A)),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                card['number'] as String,
                                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('CARD HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, letterSpacing: 1)),
                                  Text(card['holder'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, letterSpacing: 1)),
                                  Text(card['expiry'] as String, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _cards.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _selectedCardIndex == index ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _selectedCardIndex == index ? const Color(0xFF046A38) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Card Balance & Limit Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Credit Limit', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('₹${(currentCard['available'] as double).toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Approved Limit', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text('₹${(currentCard['limit'] as double).toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (currentCard['available'] as double) / (currentCard['limit'] as double),
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF046A38)),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Security & Payment Controls
            const Text('Card Security & Controls', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Online E-commerce Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable card payments for websites and apps', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: currentCard['onlineTxn'] as bool,
                    activeColor: const Color(0xFF046A38),
                    onChanged: (val) {
                      setState(() => currentCard['onlineTxn'] = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tap & Pay (Contactless NFC)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Tap card on POS machines up to ₹5,000 without PIN', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: currentCard['tapAndPay'] as bool,
                    activeColor: const Color(0xFF046A38),
                    onChanged: (val) {
                      setState(() => currentCard['tapAndPay'] = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('International Transactions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Allow usage outside India and foreign merchant sites', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: currentCard['intlTxn'] as bool,
                    activeColor: const Color(0xFF046A38),
                    onChanged: (val) {
                      setState(() => currentCard['intlTxn'] = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ATM Cash Withdrawal', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable debit/credit card ATM cash withdrawals', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    value: currentCard['atmWithdrawal'] as bool,
                    activeColor: const Color(0xFF046A38),
                    onChanged: (val) {
                      setState(() => currentCard['atmWithdrawal'] = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Card Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0D1B2A),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.pin, size: 18),
                    label: const Text('Change PIN'),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Redirecting to secure Bank ATM/e-PIN portal...')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove Card'),
                    onPressed: _removeSelectedCard,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Card Transactions
            const Text('Recent Card Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
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
                itemCount: _cardTransactions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final txn = _cardTransactions[idx];
                  final isDebit = txn['type'] == 'debit';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDebit ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                      child: Icon(
                        isDebit ? Icons.arrow_outward : Icons.arrow_downward,
                        color: isDebit ? const Color(0xFFDC2626) : const Color(0xFF046A38),
                        size: 20,
                      ),
                    ),
                    title: Text(txn['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text(txn['date'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isDebit ? '-' : '+'}${txn['amount']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDebit ? const Color(0xFF0D1B2A) : const Color(0xFF046A38),
                          ),
                        ),
                        Text(
                          txn['status'] as String,
                          style: TextStyle(fontSize: 11, color: isDebit ? const Color(0xFF64748B) : const Color(0xFF046A38)),
                        ),
                      ],
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
}
