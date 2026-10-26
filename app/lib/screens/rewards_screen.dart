import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/bharat_one_pay_api.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  bool _isLoading = true;
  int _coins = 450;
  double _totalCashback = 1280.0;
  String _referralCode = 'AIK777';
  int _successfulReferrals = 6;
  double _referralEarned = 600.0;
  List<dynamic> _coupons = [];
  List<dynamic> _cashbackHistory = [];

  final List<Map<String, dynamic>> _scratchCards = [
    {'id': 'sc_01', 'isScratched': false, 'title': 'Surprise Reward', 'reward': '₹25 Cashback Credited! 🎉', 'expiry': 'Valid for 7 days'},
    {'id': 'sc_02', 'isScratched': true, 'title': 'Swiggy Gourmet', 'reward': 'Flat 20% Off (Code: AIKSWIGGY)', 'expiry': 'Unlocked'},
    {'id': 'sc_03', 'isScratched': false, 'title': 'Bill Pay Bonanza', 'reward': 'Flat ₹50 on Electricity Bill', 'expiry': 'Valid for 3 days'},
    {'id': 'sc_04', 'isScratched': true, 'title': 'Zomato Gold', 'reward': '₹100 Off on Dining', 'expiry': 'Unlocked'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchRewards();
  }

  Future<void> _fetchRewards() async {
    setState(() => _isLoading = true);
    final res = await BharatOnePayApi.getRewardsOverview();
    if (res['success'] == true && mounted) {
      final data = res['data'] ?? {};
      setState(() {
        _coins = data['coins'] ?? 450;
        _totalCashback = (data['totalCashback'] as num?)?.toDouble() ?? 1280.0;
        _referralCode = data['referralCode'] ?? 'AIK777';
        _successfulReferrals = data['successfulReferrals'] ?? 6;
        _referralEarned = (data['referralEarnings'] as num?)?.toDouble() ?? 600.0;
        _coupons = data['coupons'] ?? [];
        _cashbackHistory = data['cashbackHistory'] ?? [];
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _openScratchCard(int index) {
    final card = _scratchCards[index];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: card['isScratched'] ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  card['isScratched'] ? Icons.celebration : Icons.card_giftcard,
                  color: card['isScratched'] ? const Color(0xFF046A38) : const Color(0xFFB45309),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                card['isScratched'] ? 'Congratulations!' : 'AikSetra Scratch Card',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
              ),
              const SizedBox(height: 8),
              Text(
                card['isScratched'] ? card['reward'] : 'Tap below to reveal your assured fintech reward or cashback.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: card['isScratched'] ? FontWeight.bold : FontWeight.normal,
                  color: card['isScratched'] ? const Color(0xFF046A38) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              if (!card['isScratched'])
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF9100),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setModalState(() {
                        card['isScratched'] = true;
                      });
                      setState(() {
                        _totalCashback += 25.0;
                      });
                    },
                    child: const Text('Scratch to Reveal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF046A38),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Claim Reward', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
            ],
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
        title: const Text('Rewards & Cashback', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF046A38)))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Balance Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0D1B2A), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0D1B2A).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Cashback Earned', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9100),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.white, size: 16),
                                  const SizedBox(width: 4),
                                  Text('$_coins Coins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('₹${_totalCashback.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Directly deposited to Primary Bank', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(6)),
                              child: const Text('AUTO-CREDIT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Scratch Cards Section
                  const Text('Scratch & Win', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _scratchCards.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, idx) {
                      final card = _scratchCards[idx];
                      final isScratched = card['isScratched'] == true;
                      return InkWell(
                        onTap: () => _openScratchCard(idx),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isScratched
                                  ? [Colors.white, const Color(0xFFF1F5F9)]
                                  : [const Color(0xFFFF9100), const Color(0xFFFF6D00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isScratched ? const Color(0xFFCBD5E1) : Colors.transparent),
                            boxShadow: [
                              BoxShadow(
                                color: (isScratched ? Colors.black12 : const Color(0xFFFF9100)).withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
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
                                  Icon(
                                    isScratched ? Icons.check_circle : Icons.touch_app,
                                    color: isScratched ? const Color(0xFF046A38) : Colors.white,
                                    size: 22,
                                  ),
                                  Text(
                                    isScratched ? 'CLAIMED' : 'UNSCRATCHED',
                                    style: TextStyle(
                                      color: isScratched ? const Color(0xFF64748B) : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                isScratched ? card['reward'] : 'Tap to Scratch',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isScratched ? const Color(0xFF0D1B2A) : Colors.white,
                                ),
                              ),
                              Text(
                                card['expiry'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isScratched ? const Color(0xFF94A3B8) : Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Refer & Earn Card
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.people_alt, color: Color(0xFF046A38), size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Refer Friends & Earn ₹100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1B2A))),
                                  SizedBox(height: 2),
                                  Text('When your friend makes their 1st UPI payment', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('YOUR REFERRAL CODE', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Text(_referralCode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF0D1B2A))),
                                ],
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF046A38),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: _referralCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Referral code copied to clipboard!')),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_successfulReferrals successful referrals • ₹${_referralEarned.toStringAsFixed(0)} earned so far',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF046A38)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Partner Offers & Coupons
                  const Text('Exclusive Partner Vouchers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 12),
                  ..._buildCouponItems(),
                  if (_cashbackHistory.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Cashback Credit History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    const SizedBox(height: 12),
                    ..._cashbackHistory.map((h) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h['description'] ?? 'Cashback Credited', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(h['date'] ?? 'Recent', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                              Text('+₹${h['amount'] ?? '25'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF046A38))),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  List<Widget> _buildCouponItems() {
    final coupons = _coupons.isNotEmpty
        ? _coupons
        : [
            {'brand': 'Swiggy Food', 'offer': 'Flat ₹125 OFF on orders above ₹299', 'code': 'SWIGGY125', 'expiry': 'Valid till 31 Oct'},
            {'brand': 'BookMyShow', 'offer': 'Buy 1 Get 1 Free on Movie Tickets', 'code': 'AIKBMS2X', 'expiry': 'Valid till 05 Nov'},
            {'brand': 'Myntra Fashion', 'offer': 'Extra 15% OFF on Autumn Collection', 'code': 'MYNTRAIK15', 'expiry': 'Valid till 15 Nov'},
          ];

    return coupons.map((c) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFF1F5F9),
              child: const Icon(Icons.local_offer, color: Color(0xFFFF9100), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['brand'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D1B2A))),
                  const SizedBox(height: 2),
                  Text(c['offer'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(c['expiry'] ?? '', style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF046A38),
                side: const BorderSide(color: Color(0xFF046A38)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: c['code'] ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Promo code ${c['code']} copied!')),
                );
              },
              child: Text(c['code'] ?? 'REDEEM', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          ],
        ),
      );
    }).toList();
  }
}
