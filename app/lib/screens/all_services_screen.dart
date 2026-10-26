import 'package:flutter/material.dart';
import '../models/service_catalogue.dart';

class AllServicesScreen extends StatefulWidget {
  final Function(String routeKey) onSelectService;

  const AllServicesScreen({super.key, required this.onSelectService});

  @override
  State<AllServicesScreen> createState() => _AllServicesScreenState();
}

class _AllServicesScreenState extends State<AllServicesScreen> {
  String _searchQuery = '';
  ServiceCategory? _selectedCategory;

  final Map<ServiceCategory, String> _categoryLabels = {
    ServiceCategory.payments: '💳 Payments',
    ServiceCategory.bills: '⚡ Bills & BBPS',
    ServiceCategory.investments: '📈 Invest & Save',
    ServiceCategory.insurance: '🛡️ Insurance',
    ServiceCategory.taxes: '🏛️ Taxes & Govt',
    ServiceCategory.tools: '🧮 Calculators',
    ServiceCategory.other: '✨ Super-App Services',
  };

  @override
  Widget build(BuildContext context) {
    var filtered = ServiceCatalogue.allServices;
    if (_selectedCategory != null) {
      filtered = filtered.where((s) => s.category == _selectedCategory).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      filtered = filtered.where((s) => s.title.toLowerCase().contains(q) || s.subtitle.toLowerCase().contains(q)).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('All Services & Solutions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: const Color(0xFF0F172A),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search 30+ services (e.g. SIP, Electricity, Tax, EMI)...',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF671F), size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All (30+)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        selected: _selectedCategory == null,
                        selectedColor: const Color(0xFFFF671F),
                        backgroundColor: const Color(0xFF1E293B),
                        labelStyle: TextStyle(color: _selectedCategory == null ? Colors.white : const Color(0xFFCBD5E1)),
                        onSelected: (_) => setState(() => _selectedCategory = null),
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      ...ServiceCategory.values.map((cat) {
                        final isSel = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: FilterChip(
                            label: Text(_categoryLabels[cat] ?? cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            selected: isSel,
                            selectedColor: const Color(0xFFFF671F),
                            backgroundColor: const Color(0xFF1E293B),
                            labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFFCBD5E1)),
                            onSelected: (_) => setState(() => _selectedCategory = isSel ? null : cat),
                            showCheckmark: false,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Services Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 54, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        Text('No services found matching "$_searchQuery"', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    itemCount: filtered.length,
                    itemBuilder: (context, idx) {
                      final item = filtered[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectService(item.routeKey);
                          },
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(item.icon, color: item.color, size: 24),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
                              ),
                              if (item.badge != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: item.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Text(item.badge!, style: TextStyle(color: item.color, fontSize: 9, fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(item.subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
