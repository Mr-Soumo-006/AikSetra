import 'package:flutter/material.dart';

class BankAccountOpeningScreen extends StatefulWidget {
  const BankAccountOpeningScreen({super.key});

  @override
  State<BankAccountOpeningScreen> createState() => _BankAccountOpeningScreenState();
}

class _BankAccountOpeningScreenState extends State<BankAccountOpeningScreen> {
  final List<Map<String, dynamic>> _partnerBanks = [
    {
      'bank': 'Kotak Mahindra Bank',
      'product': 'Kotak 811 Zero Balance A/C',
      'interest': 'Up to 7.00% p.a.',
      'minBalance': '₹0 (Zero Balance)',
      'card': 'Free Virtual RuPay Platinum',
      'features': ['Instant UPI activation', 'Zero balance forever', 'Digital passbook'],
      'rating': '4.8 ★',
      'color': 0xFFED1C24,
    },
    {
      'bank': 'HDFC Bank',
      'product': 'DigiSave Youth Account',
      'interest': 'Up to 3.50% p.a.',
      'minBalance': '₹2,500 Metro / ₹1,000 Semi-urban',
      'card': 'Millennia Platinum Debit Card',
      'features': ['1% cashback on debit card', 'Complimentary airport lounge', 'Preferred banking'],
      'rating': '4.9 ★',
      'color': 0xFF004C8F,
    },
    {
      'bank': 'Federal Bank',
      'product': 'FedBook Selfie Savings A/C',
      'interest': 'Up to 6.25% p.a.',
      'minBalance': '₹0 (Digital Account)',
      'card': 'Contactless Visa Classic',
      'features': ['100% paperless video KYC', 'Free IMPS / NEFT / RTGS', 'Pre-approved loan offers'],
      'rating': '4.7 ★',
      'color': 0xFF003875,
    },
    {
      'bank': 'Axis Bank',
      'product': 'ASAP Digital Savings A/C',
      'interest': 'Up to 4.00% p.a.',
      'minBalance': 'Zero balance on FD link',
      'card': 'E-Debit Virtual Card',
      'features': ['GrabDeals 10% flat cashback', 'Automated recurring deposits', 'Titan gift voucher'],
      'rating': '4.6 ★',
      'color': 0xFF97144D,
    },
  ];

  void _startKycFlow(Map<String, dynamic> bank) {
    int currentStep = 0;
    final aadhaarCtrl = TextEditingController(text: '8492 1045 9921');
    final panCtrl = TextEditingController(text: 'ABCDE1234F');

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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Open ${bank['product']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                        Text('${bank['bank']} • 4-Step Digital KYC', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 16),

                // Step Tracker
                Row(
                  children: List.generate(4, (i) {
                    final isDone = i < currentStep;
                    final isCurrent = i == currentStep;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDone || isCurrent ? const Color(0xFF046A38) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),

                if (currentStep == 0) ...[
                  const Text('Step 1: Aadhaar Paperless e-KYC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('An OTP will be sent to your UIDAI registered mobile number for instant verification.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: aadhaarCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '12-Digit Aadhaar Number',
                      prefixIcon: const Icon(Icons.fingerprint),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else if (currentStep == 1) ...[
                  const Text('Step 2: PAN & Employment Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Verified automatically under NSDL/ITD database.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: panCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Permanent Account Number (PAN)',
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: 'Salaried Professional',
                    decoration: InputDecoration(
                      labelText: 'Occupation Type',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Salaried Professional', child: Text('Salaried Professional')),
                      DropdownMenuItem(value: 'Self Employed / Business', child: Text('Self Employed / Business')),
                      DropdownMenuItem(value: 'Student', child: Text('Student')),
                    ],
                    onChanged: (_) {},
                  ),
                ] else if (currentStep == 2) ...[
                  const Text('Step 3: Schedule Video KYC (V-KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  const Text('Keep your physical PAN card and blank paper ready for live camera verification.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.videocam, color: Color(0xFF046A38), size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Instant V-KYC Officer Available', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF046A38))),
                              Text('Average wait time: Under 2 minutes', style: TextStyle(fontSize: 11, color: Color(0xFF166534))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF046A38), size: 64),
                        SizedBox(height: 12),
                        Text('Application Approved!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0D1B2A))),
                        SizedBox(height: 6),
                        Text('Your account is being provisioned. Welcome kit and virtual card details are ready.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],

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
                      if (currentStep < 3) {
                        setModalState(() => currentStep++);
                      } else {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Welcome to ${bank['bank']}! New account successfully linked to AikSetra.'),
                            backgroundColor: const Color(0xFF046A38),
                          ),
                        );
                      }
                    },
                    child: Text(
                      currentStep < 3 ? 'Proceed to Step ${currentStep + 2}' : 'Go to My Accounts',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Open Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Value Proposition Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D1B2A), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance, color: Color(0xFFFF9100), size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('100% Digital Account Opening', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Zero branch visits. Paperless Aadhaar e-KYC & instant virtual debit card.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Featured Partner Bank Accounts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            const SizedBox(height: 12),

            ..._partnerBanks.map((bank) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(bank['product'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1B2A))),
                              Text(bank['bank'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                            child: Text(bank['rating'] as String, style: const TextStyle(color: Color(0xFF046A38), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Interest Rate', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(bank['interest'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF046A38))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Min Balance', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                  const SizedBox(height: 2),
                                  Text(bank['minBalance'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0D1B2A))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...(bank['features'] as List<String>).map((feat) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.check, color: Color(0xFF046A38), size: 16),
                                const SizedBox(width: 6),
                                Text(feat, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                              ],
                            ),
                          )),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF046A38),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _startKycFlow(bank),
                          child: const Text('Apply Now (Paperless e-KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
