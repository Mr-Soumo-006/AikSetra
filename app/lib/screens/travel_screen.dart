import 'package:flutter/material.dart';

class TravelScreen extends StatefulWidget {
  final String? initialCategory;
  const TravelScreen({super.key, this.initialCategory});

  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _pnrController = TextEditingController();
  Map<String, dynamic>? _pnrResult;

  final List<String> _tabs = ['Flights', 'Trains', 'Buses', 'Hotels'];

  @override
  void initState() {
    super.initState();
    int initialIdx = 0;
    if (widget.initialCategory != null) {
      final idx = _tabs.indexWhere((t) => t.toLowerCase() == widget.initialCategory!.toLowerCase());
      if (idx != -1) initialIdx = idx;
    }
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: initialIdx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pnrController.dispose();
    super.dispose();
  }

  void _checkPnr() {
    final pnr = _pnrController.text.trim();
    if (pnr.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit PNR number')),
      );
      return;
    }

    setState(() {
      _pnrResult = {
        'pnr': pnr,
        'trainName': 'Rajdhani Express (12301)',
        'from': 'Howrah Jn (HWH)',
        'to': 'New Delhi (NDLS)',
        'date': '28 Oct 2026',
        'class': '3rd AC (3A)',
        'status': 'CNF (Confirmed)',
        'berth': 'B3 - 42 (Side Lower)',
        'chart': 'Chart Prepared',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Travel & Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF9100),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.flight_takeoff), text: 'Flights'),
            Tab(icon: Icon(Icons.train), text: 'Trains'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Buses'),
            Tab(icon: Icon(Icons.hotel), text: 'Hotels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFlightsTab(),
          _buildTrainsTab(),
          _buildBusesTab(),
          _buildHotelsTab(),
        ],
      ),
    );
  }

  Widget _buildFlightsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerBanner('Domestic & International Flights with zero convenience fee on RuPay / UPI.'),
          const SizedBox(height: 16),
          _buildSearchBox(
            fromCity: 'DEL - New Delhi',
            toCity: 'BOM - Mumbai',
            date: 'Tomorrow, 27 Oct',
            labelExtra: '1 Traveller, Economy',
            onSearch: () => _showSearchResults('Flights DEL ✈️ BOM', [
              {'name': 'IndiGo 6E-205', 'time': '06:00 - 08:15 (2h 15m)', 'price': '₹4,899', 'type': 'Non-stop'},
              {'name': 'Air India AI-805', 'time': '09:30 - 11:45 (2h 15m)', 'price': '₹5,350', 'type': 'Non-stop'},
              {'name': 'Vistara UK-995', 'time': '14:20 - 16:35 (2h 15m)', 'price': '₹5,790', 'type': 'Non-stop'},
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Popular Flight Routes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
          const SizedBox(height: 12),
          _buildRouteChip('Delhi to Bengaluru', 'From ₹4,299'),
          _buildRouteChip('Mumbai to Goa', 'From ₹2,499'),
          _buildRouteChip('Kolkata to Port Blair', 'From ₹5,199'),
        ],
      ),
    );
  }

  Widget _buildTrainsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerBanner('Authorized IRCTC Train Booking Partner. Real-time availability & PNR tracking.'),
          const SizedBox(height: 16),
          _buildSearchBox(
            fromCity: 'HWH - Howrah Jn',
            toCity: 'PURI - Puri',
            date: 'Wed, 28 Oct',
            labelExtra: 'General Quota, Sleeper / 3A',
            onSearch: () => _showSearchResults('Trains Howrah 🚆 Puri', [
              {'name': 'Dhauli Express (12821)', 'time': '09:15 - 18:00 (8h 45m)', 'price': '₹245', 'type': '2S / CC'},
              {'name': 'Puri Vande Bharat (22895)', 'time': '06:10 - 12:35 (6h 25m)', 'price': '₹1,265', 'type': 'Chair Car'},
              {'name': 'Howrah Puri Superfast (12837)', 'time': '22:40 - 07:10 (8h 30m)', 'price': '₹390', 'type': 'SL / 3A'},
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Live PNR Status Check', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _pnrController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: 'Enter 10-Digit PNR Number',
                    hintText: 'e.g. 6423891042',
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF046A38),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _checkPnr,
                      child: const Text('Check Status'),
                    ),
                  ),
                ),
                if (_pnrResult != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_pnrResult!['trainName']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFF046A38), borderRadius: BorderRadius.circular(6)),
                              child: Text(_pnrResult!['status']!, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${_pnrResult!['from']} ➔ ${_pnrResult!['to']}', style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        const SizedBox(height: 4),
                        Text('Berth / Seat: ${_pnrResult!['berth']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0D1B2A))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerBanner('Intercity bus tickets with live GPS tracking across redBus & KSRTC/MSRTC networks.'),
          const SizedBox(height: 16),
          _buildSearchBox(
            fromCity: 'Bengaluru',
            toCity: 'Hyderabad',
            date: 'Tomorrow, 27 Oct',
            labelExtra: 'AC Sleeper / Multi-Axle',
            onSearch: () => _showSearchResults('Buses Bengaluru 🚌 Hyderabad', [
              {'name': 'IntrCity SmartBus (Volvo AC)', 'time': '21:30 - 06:15 (8h 45m)', 'price': '₹950', 'type': 'AC Sleeper'},
              {'name': 'Orange Tours & Travels', 'time': '22:00 - 06:30 (8h 30m)', 'price': '₹1,100', 'type': 'BharatBenz AC'},
              {'name': 'SRS Travels', 'time': '23:15 - 07:45 (8h 30m)', 'price': '₹850', 'type': 'Multi-Axle'},
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerBanner('Verified domestic and international hotels. Guaranteed check-in & free cancellation.'),
          const SizedBox(height: 16),
          _buildSearchBox(
            fromCity: 'Goa (North & South)',
            toCity: '2 Guests, 1 Room',
            date: '28 Oct - 31 Oct (3 Nights)',
            labelExtra: 'Free Breakfast, Pay at Hotel',
            onSearch: () => _showSearchResults('Hotels in Goa', [
              {'name': 'Taj Holiday Village Resort & Spa', 'time': 'Candolim, North Goa', 'price': '₹18,500/nt', 'type': '5-Star Luxury'},
              {'name': 'Novotel Goa Dona Sylvia Resort', 'time': 'Cavelossim Beach', 'price': '₹8,200/nt', 'type': '4-Star Resort'},
              {'name': 'The Baga Marina Beach Resort', 'time': 'Baga Beach', 'price': '₹3,450/nt', 'type': '3-Star Premium'},
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerBanner(String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: Color(0xFF1D4ED8), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox({
    required String fromCity,
    required String toCity,
    required String date,
    required String labelExtra,
    required VoidCallback onSearch,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.radio_button_checked, color: Color(0xFF046A38), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FROM', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text(fromCity, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFF9100), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TO / DESTINATION', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text(toCity, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF0D1B2A), size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DEPARTURE DATE & DETAILS', style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text('$date  •  $labelExtra', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0D1B2A))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046A38),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.search),
              label: const Text('Search Availability & Fares', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              onPressed: onSearch,
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(String title, List<Map<String, String>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            ...items.map((it) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(it['time']!, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 2),
                            Text(it['type']!, style: const TextStyle(fontSize: 11, color: Color(0xFF046A38), fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(it['price']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                          const SizedBox(height: 6),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Selected ${it['name']}. Proceeding to AikSetra UPI Checkout...')),
                              );
                            },
                            child: const Text('Book', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteChip(String title, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0D1B2A))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF046A38))),
        ],
      ),
    );
  }
}
