import 'package:flutter/material.dart';

import '../utils/app_translations.dart';

class LanguageLocationSelectorModal extends StatefulWidget {
  final String initialLanguage;
  final ValueChanged<String>? onLanguageSelected;
  final bool isStandalonePage;

  const LanguageLocationSelectorModal({
    super.key,
    this.initialLanguage = 'en-IN',
    this.onLanguageSelected,
    this.isStandalonePage = false,
  });

  static Future<String?> show(
    BuildContext context, {
    String current = 'en-IN',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: LanguageLocationSelectorModal(initialLanguage: current),
        ),
      ),
    );
  }

  @override
  State<LanguageLocationSelectorModal> createState() =>
      _LanguageLocationSelectorModalState();
}

class _LanguageLocationSelectorModalState
    extends State<LanguageLocationSelectorModal> {
  late String _selectedLanguageCode;
  String _selectedState = 'West Bengal';
  bool _isAutoDetecting = false;
  String? _detectedMessage;

  final List<String> _indianStates = [
    'West Bengal',
    'Maharashtra',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Telangana',
    'Andhra Pradesh',
    'Gujarat',
    'Uttar Pradesh',
    'Bihar',
    'Punjab',
    'Kerala',
    'Odisha',
    'Rajasthan',
    'Madhya Pradesh',
    'Haryana',
    'Assam',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLanguageCode = widget.initialLanguage;
  }

  void _detectLocationAutomatically() async {
    setState(() {
      _isAutoDetecting = true;
      _detectedMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 600));

    // Simulated location detection based on network cell/telecom circle (e.g. Kolkata / WB)
    const detectedState = 'West Bengal';
    final recommendedLang = AppTranslations.suggestLanguageForState(
      detectedState,
    );

    if (mounted) {
      setState(() {
        _isAutoDetecting = false;
        _selectedState = detectedState;
        _selectedLanguageCode = recommendedLang;
        _detectedMessage =
            '📍 Location detected: $detectedState (Telecom Circle). Recommended language selected!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final recommendedCode = AppTranslations.suggestLanguageForState(
      _selectedState,
    );
    final recommendedLang = AppTranslations.supportedLanguages.firstWhere(
      (l) => l.code == recommendedCode,
      orElse: () => AppTranslations.supportedLanguages.first,
    );

    return Column(
      children: [
        if (!widget.isStandalonePage) ...[
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Header Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Language • भाषा चुनें',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select language according to your location or preference',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                ],
              ),
              if (!widget.isStandalonePage)
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),
        const Divider(color: Color(0xFF1E293B), height: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. LOCATION-BASED SUGGESTION CARD
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF046A38).withValues(alpha: 0.25),
                        const Color(0xFF0F172A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF046A38).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF34D399),
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Location-Wise Language Preference',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: _isAutoDetecting
                                ? null
                                : _detectLocationAutomatically,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF34D399)
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (_isAutoDetecting)
                                    const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF34D399),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.my_location,
                                      size: 12,
                                      color: Color(0xFF34D399),
                                    ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Detect GPS',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // State dropdown & recommendation
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedState,
                                  dropdownColor: const Color(0xFF1E293B),
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  items: _indianStates.map((st) {
                                    return DropdownMenuItem(
                                      value: st,
                                      child: Text('📍 $st'),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _selectedState = val;
                                        _selectedLanguageCode =
                                            AppTranslations.suggestLanguageForState(
                                              val,
                                            );
                                        _detectedMessage = null;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedLanguageCode = recommendedCode;
                              });
                            },
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: Text(
                              recommendedLang.nativeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF046A38),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_detectedMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _detectedMessage!,
                          style: const TextStyle(
                            color: Color(0xFF34D399),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. MANUAL SELECTION SECTION HEADER
                const Row(
                  children: [
                    Icon(
                      Icons.translate_rounded,
                      color: Color(0xFFFF671F),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'All Indian Languages (Select Manually)',
                      style: TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Language Cards Grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: AppTranslations.supportedLanguages.length,
                  itemBuilder: (ctx, idx) {
                    final lang = AppTranslations.supportedLanguages[idx];
                    final isSelected = lang.code == _selectedLanguageCode;
                    final isRecommended = lang.code == recommendedCode;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedLanguageCode = lang.code;
                        });
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF046A38).withValues(alpha: 0.3)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF34D399)
                                : (isRecommended
                                      ? const Color(0xFFFF671F)
                                            .withValues(alpha: 0.6)
                                      : const Color(0xFF334155)),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        lang.nativeName,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: isSelected
                                              ? FontWeight.w900
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      if (isRecommended) ...[
                                        const SizedBox(width: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF671F),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'REC',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${lang.englishName} • ${lang.sampleGreeting}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF94A3B8),
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF34D399),
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Confirm Button Bar
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            border: Border(top: BorderSide(color: Color(0xFF1E293B))),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                await AppTranslations.setLanguage(_selectedLanguageCode);
                if (widget.onLanguageSelected != null) {
                  widget.onLanguageSelected!(_selectedLanguageCode);
                }
                if (context.mounted && !widget.isStandalonePage) {
                  Navigator.pop(context, _selectedLanguageCode);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF046A38),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Continue with ${AppTranslations.supportedLanguages.firstWhere((l) => l.code == _selectedLanguageCode, orElse: () => AppTranslations.supportedLanguages.first).nativeName}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
