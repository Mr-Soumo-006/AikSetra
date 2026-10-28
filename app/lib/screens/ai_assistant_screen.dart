import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'calculators_screen.dart';
import 'bank_account_opening_screen.dart';
import 'business_dashboard_screen.dart';
import 'autopay_screen.dart';
import 'statements_screen.dart';

class AIAssistantScreen extends StatefulWidget {
  final String? initialPrompt;

  const AIAssistantScreen({super.key, this.initialPrompt});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AIMessageModel> _messages = [];
  bool _isLoading = false;
  String? _activeConversationId;

  final List<String> _quickPrompts = [
    '💡 Which stocks should I invest in right now?',
    '💳 What is my total bank balance?',
    '📊 Calculate SIP of ₹5,000 at 12% for 10 years',
    '📈 Top breakout stocks today',
    '🔄 How do I switch primary bank account?',
    '🧾 Show my recent transactions',
    '💼 How do I set up a Business Account?',
  ];

  @override
  void initState() {
    super.initState();
    _loadWelcomeMessage();
    if (widget.initialPrompt != null && widget.initialPrompt!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSend(widget.initialPrompt!.trim());
      });
    }
  }

  void _loadWelcomeMessage() {
    _messages.add(
      AIMessageModel(
        id: 'welcome_01',
        role: 'assistant',
        content:
            'Hello! I am your **AikSetra AI Financial Assistant**.\n\n'
            'I am connected to your AikSetra platform and powered by our local neural engine and verified financial knowledge base.\n\n'
            '**Here is what I can do for you:**\n'
            '• **Check Balances & Accounts**: View your linked accounts and switch default banks.\n'
            '• **Financial Calculations**: Calculate SIP, EMI, FD, RD, and GST returns.\n'
            '• **Stock Market Research**: Check live stock quotes, price performance, and financial metrics.\n'
            '• **App Navigation & Guidance**: Learn how to use QR codes, AutoPay, and Business Accounts.\n\n'
            '💡 *Note: I will never ask for your MPIN, passwords, or card details. All stock insights are strictly informational and non-advisory.*',
        suggestedQuestions: [
          'What is my total bank balance?',
          'Calculate SIP of ₹5,000 at 12% for 10 years',
          'Show Reliance stock quote',
          'How do I switch my primary bank account?',
        ],
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _handleSend(String query) async {
    final text = query.trim();
    if (text.isEmpty || _isLoading) return;

    _textController.clear();

    final userMsg = AIMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });

    _scrollToBottom();

    final result = await AIService.sendMessage(text, conversationId: _activeConversationId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && result['data'] != null) {
      final data = result['data'] as Map<String, dynamic>;
      _activeConversationId = data['conversationId']?.toString();

      final assistantMsg = AIMessageModel.fromJson({
        'id': data['messageId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'role': 'assistant',
        'content': data['reply'] ?? 'I have processed your request.',
        'citations': data['citations'] ?? [],
        'suggested_questions': data['suggestedQuestions'] ?? [],
        'action_type': data['actionType'],
        'action_payload': data['actionPayload'],
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _messages.add(assistantMsg);
      });
    } else {
      final errorMsg = AIMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: 'assistant',
        content:
            '⚠️ **Notice**: ${result['message'] ?? 'Could not reach the assistant. Please try again.'}',
        createdAt: DateTime.now(),
      );
      setState(() {
        _messages.add(errorMsg);
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleAction(String actionType, Map<String, dynamic>? payload) {
    switch (actionType) {
      case 'open_calculator':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CalculatorsScreen()),
        );
        break;
      case 'open_bank_accounts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BankAccountOpeningScreen()),
        );
        break;
      case 'open_business_account':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
        );
        break;
      case 'open_autopay':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AutoPayScreen()),
        );
        break;
      case 'open_history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StatementsScreen()),
        );
        break;
      case 'open_stock_market':
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📈 Viewing Live Stock Market & Investment Screener'),
            backgroundColor: Color(0xFF0D1B2A),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $actionType in AikSetra...'),
            backgroundColor: const Color(0xFF0D1B2A),
          ),
        );
    }
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Conversation?'),
        content: const Text('Are you sure you want to clear this conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _messages.clear();
                _activeConversationId = null;
                _loadWelcomeMessage();
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFF671F);
    final secondaryColor = const Color(0xFF046A38);
    final navyBg = const Color(0xFF0D1B2A);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navyBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                ),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AikSetra Assistant',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'Local AI • RAG Grounded',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Container(
        color: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
        child: Column(
          children: [
            // Quick suggestions horizontal strip
            if (_messages.length <= 2)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _quickPrompts.length,
                  itemBuilder: (context, idx) {
                    final prompt = _quickPrompts[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0D1B2A),
                          ),
                        ),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        side: BorderSide(
                          color: primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                        onPressed: () => _handleSend(prompt.replaceFirst(RegExp(r'^[^\s]+\s'), '')),
                      ),
                    );
                  },
                ),
              ),

            // Messages ListView
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg, isDark, primaryColor, secondaryColor);
                },
              ),
            ),

            // Loading indicator
            if (_isLoading)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Analyzing financial ledger & citations...',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C2E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ask about balances, calculations, stocks...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _handleSend,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () => _handleSend(_textController.text),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    AIMessageModel msg,
    bool isDark,
    Color primaryColor,
    Color secondaryColor,
  ) {
    final isUser = msg.role == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, right: 8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B2A),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor, width: 1),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF0D1B2A)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser
                      ? primaryColor.withOpacity(0.4)
                      : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: const Offset(0, 1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Text
                  SelectableText(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isUser
                          ? Colors.white
                          : (isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF0F172A)),
                    ),
                  ),

                  // Action Deep Link Button if suggested
                  if (msg.actionType != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: Text(
                        _actionLabel(msg.actionType!),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _handleAction(msg.actionType!, msg.actionPayload),
                    ),
                  ],

                  // Grounded Citations Accordion
                  if (msg.citations.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: secondaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified, size: 14, color: secondaryColor),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Sources (${msg.citations.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: secondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          for (final cite in msg.citations)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                '• ${cite.title} [${cite.category}] (Relevance: ${(cite.relevanceScore * 100).toInt()}%)',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark ? Colors.white60 : Colors.black87,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // Suggested Follow-up Questions
                  if (!isUser && msg.suggestedQuestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: msg.suggestedQuestions.map((q) {
                        return InkWell(
                          onTap: () => _handleSend(q),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_forward, size: 10, color: primaryColor),
                                const SizedBox(width: 3),
                                Text(
                                  q,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white70 : primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Feedback thumbs on Assistant messages
                  if (!isUser && msg.id != 'welcome_01') ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up_alt_outlined, size: 14),
                          color: isDark ? Colors.white38 : Colors.black38,
                          onPressed: () {
                            AIService.submitFeedback(msg.id, 'helpful');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you for your feedback!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down_alt_outlined, size: 14),
                          color: isDark ? Colors.white38 : Colors.black38,
                          onPressed: () {
                            AIService.submitFeedback(msg.id, 'unhelpful');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Feedback recorded for continuous improvement.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            Container(
              margin: const EdgeInsets.only(top: 2, left: 8),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 14),
            ),
          ],
        ],
      ),
    );
  }

  String _actionLabel(String actionType) {
    switch (actionType) {
      case 'open_calculator':
        return 'Open Financial Calculators';
      case 'open_bank_accounts':
        return 'View Bank Accounts';
      case 'open_business_account':
        return 'Open Business Account';
      case 'open_autopay':
        return 'View AutoPay Mandates';
      case 'open_history':
        return 'View Full Transaction History';
      case 'open_stock_market':
        return 'Open Stock Market Watchlist';
      default:
        return 'Open Feature in AikSetra';
    }
  }
}
