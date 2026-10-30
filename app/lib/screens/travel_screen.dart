import '../services/bharat_one_pay_api.dart';
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

  final List<String> _tabs = ['Flights', 'Trains', 'Buses', 'Movies', 'Hotels'];

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
            Tab(icon: Icon(Icons.movie_creation_outlined), text: 'Movies'),
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
          _buildMoviesTab(),
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
                              _showTravelBookingCheckoutModal(it, title);
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

  // ================= TAB 4: MOVIES & CINEMA TICKETS =================
  String _selectedCinema = 'PVR INOX South City Mall';
  String _selectedMovieDate = 'Today, 30 Oct';

  final List<Map<String, dynamic>> _nowShowingMovies = [
    {
      'id': 'mov_01',
      'title': 'Kalki 2898 AD: Part 2',
      'genre': 'Sci-Fi • Mythological • Action',
      'duration': '3h 12m',
      'rating': '9.2/10 (124K votes)',
      'certificate': 'U/A 16+',
      'formats': ['IMAX 2D', 'Dolby Atmos', '3D'],
      'timings': ['10:15 AM', '01:45 PM', '05:30 PM', '08:45 PM'],
    },
    {
      'id': 'mov_02',
      'title': 'Jawan: Retribution (Jawan 2)',
      'genre': 'Action • High-Octane Thriller',
      'duration': '2h 45m',
      'rating': '8.9/10 (98K votes)',
      'certificate': 'U/A',
      'formats': ['4DX', 'Atmos', '2D'],
      'timings': ['11:00 AM', '02:30 PM', '06:15 PM', '09:30 PM'],
    },
    {
      'id': 'mov_03',
      'title': 'Stree 3: Night Haunt',
      'genre': 'Horror Comedy • Mystery',
      'duration': '2h 20m',
      'rating': '8.8/10 (82K votes)',
      'certificate': 'U/A',
      'formats': ['2D Dolby 7.1'],
      'timings': ['12:30 PM', '04:00 PM', '07:30 PM', '10:45 PM'],
    },
    {
      'id': 'mov_04',
      'title': 'Avatar: Fire and Ash',
      'genre': 'Epic Sci-Fi • Visual Spectacle',
      'duration': '3h 15m',
      'rating': '9.4/10 (210K votes)',
      'certificate': 'U/A',
      'formats': ['IMAX 3D', 'ScreenX', 'HFR 3D'],
      'timings': ['09:45 AM', '01:30 PM', '05:45 PM', '09:15 PM'],
    },
  ];

  Widget _buildMoviesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPartnerBanner('Book Cinema & Multiplex Tickets with Instant M-Ticket, 0 convenience fee & BookMyShow perks.'),
          const SizedBox(height: 16),

          // Cinema Selector
          Container(
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Multiplex / Cinema', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    const Icon(Icons.location_on, size: 16, color: Color(0xFFFF9100)),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'PVR INOX South City Mall',
                      'Cinepolis Acropolis Mall',
                      'INOX Forum Mall Elgin Road',
                      'Miraj Cinemas Mani Square',
                    ].map((cin) {
                      final isSel = _selectedCinema == cin;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cin),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedCinema = cin),
                          selectedColor: const Color(0xFF0D1B2A),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Select Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Today, 30 Oct',
                      'Tomorrow, 31 Oct',
                      'Sat, 01 Nov',
                      'Sun, 02 Nov',
                    ].map((dt) {
                      final isSel = _selectedMovieDate == dt;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(dt),
                          selected: isSel,
                          onSelected: (_) => setState(() => _selectedMovieDate = dt),
                          selectedColor: const Color(0xFFFF9100),
                          backgroundColor: const Color(0xFFF1F5F9),
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : const Color(0xFF334155),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Now Showing Movies Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Now Showing in Theatres',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0D1B2A)),
              ),
              Text(
                'Kolkata (42 Screens)',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          ..._nowShowingMovies.map((mov) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9100).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.movie_creation, color: Color(0xFFFF9100), size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mov['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0D1B2A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${mov['genre']} • ${mov['duration']}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Color(0xFFFFB300), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  mov['rating'],
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    mov['certificate'],
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: (mov['formats'] as List<String>).map((fmt) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF046A38).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          fmt,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF046A38)),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 16),
                  const Text('Showtimes Available:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (mov['timings'] as List<String>).map((t) {
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF046A38),
                          side: const BorderSide(color: Color(0xFF046A38)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showSeatSelectionModal(mov, t),
                        child: Text(t, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showSeatSelectionModal(Map<String, dynamic> movie, String showtime) {
    String selectedCategory = 'Prime';
    int seatCount = 2;
    final Map<String, int> prices = {
      'Recliner': 450,
      'Prime': 280,
      'Classic': 180,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setMState) {
          final unitPrice = prices[selectedCategory] ?? 280;
          final total = unitPrice * seatCount;

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(movie['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                          Text('$_selectedCinema • $showtime • $_selectedMovieDate', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Screen Indicator
                Center(
                  child: Container(
                    width: 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text('SCREEN THIS WAY', style: TextStyle(fontSize: 9, letterSpacing: 1.5, color: Color(0xFF94A3B8))),
                ),
                const SizedBox(height: 16),

                const Text('Select Category & Price', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                const SizedBox(height: 8),
                Row(
                  children: prices.keys.map((cat) {
                    final isSel = selectedCategory == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setMState(() => selectedCategory = cat),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFF0D1B2A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF0D1B2A) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text(cat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF334155))),
                              const SizedBox(height: 2),
                              Text('₹${prices[cat]}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? const Color(0xFFFF9100) : const Color(0xFF046A38))),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Seats:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                    Row(
                      children: [1, 2, 3, 4, 5].map((cnt) {
                        final isSel = seatCount == cnt;
                        return GestureDetector(
                          onTap: () => setMState(() => seatCount = cnt),
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF046A38) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$cnt',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: isSel ? Colors.white : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Total and Proceed Button
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Payable Amount', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          Text('₹$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF046A38),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showMovieCheckoutModal(movie, showtime, selectedCategory, seatCount, total);
                        },
                        child: const Text('Proceed to Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMovieCheckoutModal(Map<String, dynamic> movie, String showtime, String category, int count, int total) {
    final acc = BharatOnePayApi.linkedAccounts.isNotEmpty ? BharatOnePayApi.linkedAccounts.first : null;
    final seatsStr = List.generate(count, (i) => 'E${10 + i}').join(', ');
    final bookingId = 'BMS-AK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Confirm Movie Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            Text(movie['title'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text('Cinema: $_selectedCinema', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('Show: $showtime, $_selectedMovieDate', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('Seats: $seatsStr ($category Class)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF0D1B2A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc != null ? '${acc.bankName} (${acc.maskedAccountNumber})' : 'AikSetra Primary Account',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Available Balance: ₹${acc != null ? acc.balance.toStringAsFixed(2) : "45,000.00"}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF046A38), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                  // Debit balance
                  if (acc != null && acc.balance >= total) {
                    final idx = BharatOnePayApi.linkedAccounts.indexWhere((a) => a.id == acc.id);
                    if (idx != -1) {
                      BharatOnePayApi.linkedAccounts[idx] = acc.copyWith(balance: acc.balance - total);
                    }
                  }

                  BharatOnePayApi.recordTransaction(
                    title: 'Movie Tickets • ${movie['title']}',
                    type: 'DEBIT',
                    category: 'TRAVEL',
                    amount: total.toDouble(),
                    reference: bookingId,
                    status: 'SUCCESS',
                  );
                  BharatOnePayApi.saveSessionToDisk();

                  Navigator.pop(ctx);
                  _showMovieTicketPassDialog(movie, showtime, category, seatsStr, bookingId, total);
                },
                child: Text('Pay ₹$total & Confirm Tickets', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMovieTicketPassDialog(
    Map<String, dynamic> movie,
    String showtime,
    String category,
    String seatsStr,
    String bookingId,
    int total,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF059669), size: 20),
                    SizedBox(width: 6),
                    Text('Booking Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                  child: const Text('M-TICKET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(movie['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text('$_selectedCinema • Audi 3', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('$_selectedMovieDate at $showtime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D1B2A))),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Seats', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(seatsStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF046A38))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Booking ID', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(bookingId, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            // QR Code Mock
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code_2, size: 90, color: Color(0xFF0D1B2A)),
                    SizedBox(height: 4),
                    Text('Scan at Cinema Entry Turnstile', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Save Ticket Pass'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Movie ticket saved to Apple Wallet / Google Wallet & Photos!')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showTravelBookingCheckoutModal(Map<String, String> item, String title) {
    final rawPrice = item['price'] ?? '₹999';
    final numericPrice = double.tryParse(rawPrice.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 999.0;
    final acc = BharatOnePayApi.linkedAccounts.isNotEmpty ? BharatOnePayApi.linkedAccounts.first : null;
    final pnr = '${(DateTime.now().millisecondsSinceEpoch % 9000000000) + 1000000000}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Confirm $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 6),
            Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text('Schedule: ${item['time']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('Category/Class: ${item['type']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF046A38))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: Color(0xFF0D1B2A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          acc != null ? '${acc.bankName} (${acc.maskedAccountNumber})' : 'AikSetra Primary Account',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        Text(
                          'Available Balance: ₹${acc != null ? acc.balance.toStringAsFixed(2) : "45,000.00"}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF046A38), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
                  if (acc != null && acc.balance >= numericPrice) {
                    final idx = BharatOnePayApi.linkedAccounts.indexWhere((a) => a.id == acc.id);
                    if (idx != -1) {
                      BharatOnePayApi.linkedAccounts[idx] = acc.copyWith(balance: acc.balance - numericPrice);
                    }
                  }

                  BharatOnePayApi.recordTransaction(
                    title: '$title Booking • ${item['name']}',
                    type: 'DEBIT',
                    category: 'TRAVEL',
                    amount: numericPrice,
                    reference: 'PNR-$pnr',
                    status: 'SUCCESS',
                  );
                  BharatOnePayApi.saveSessionToDisk();

                  Navigator.pop(ctx);
                  _showTravelConfirmedTicketDialog(item, title, pnr, rawPrice);
                },
                child: Text('Pay $rawPrice & Confirm Ticket', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTravelConfirmedTicketDialog(Map<String, String> item, String title, String pnr, String price) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF059669), size: 22),
                SizedBox(width: 8),
                Text('Ticket Confirmed!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF059669))),
              ],
            ),
            const SizedBox(height: 12),
            Text(item['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
            Text('${item['time']} • ${item['type']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PNR / Booking No.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Text(pnr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0D1B2A))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Status', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    const Text('CNF (Confirmed)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.qr_code, size: 80, color: Color(0xFF0D1B2A)),
                    SizedBox(height: 4),
                    Text('Official E-Ticket Boarding Pass QR', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF046A38), foregroundColor: Colors.white),
            icon: const Icon(Icons.download, size: 14),
            label: const Text('Download Ticket PDF'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Boarding pass & tax invoice PDF downloaded!')),
              );
            },
          ),
        ],
      ),
    );
  }

}
