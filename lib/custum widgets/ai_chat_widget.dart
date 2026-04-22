import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat/ai_chat_provider.dart';
import '../models/chat_message.dart';
import 'package:hims_app/screens/mr_details/mr_details.dart';
import 'dart:math';

import '../screens/opd_reciepts/opd_records.dart';

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const Color primaryTeal = Color(0xFF00B5AD);

  // Draggable FAB position
  double _fabX = -1; // -1 means not initialized
  double _fabY = -1;
  static const double _fabSize = 56.0;
  static const double _fabMargin = 16.0;

  // We now use msg.entities check instead of text parsing

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Clamp FAB position so it never goes off-screen
  void _clampFabPosition(Size screenSize) {
    _fabX = _fabX.clamp(_fabMargin, screenSize.width - _fabSize - _fabMargin);
    _fabY = _fabY.clamp(_fabMargin, screenSize.height - _fabSize - _fabMargin);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Initialize FAB position to right-center on first build
    if (_fabX < 0 || _fabY < 0) {
      _fabX = screenSize.width - _fabSize - _fabMargin;
      _fabY = (screenSize.height / 2) - (_fabSize / 2);
    }

    return Consumer<AiChatProvider>(
      builder: (context, provider, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (provider.isOpen) {
            _scrollToBottom();
          }
        });

        return Stack(
          alignment: Alignment.bottomRight,
          children: [
            // ── Backdrop ──────────────────────────────────────────────────
            if (provider.isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    provider.closeChat();
                  },
                  child: Container(color: Colors.black.withOpacity(0.4)),
                ),
              ),

            // ── Chat Window ───────────────────────────────────────────────
            if (provider.isOpen)
              Positioned.fill(
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    elevation: 12,
                    borderRadius: BorderRadius.circular(24),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      width: min(screenSize.width * 0.9, 450),
                      height: min(screenSize.height * 0.6, 500),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: primaryTeal.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildHeader(provider),
                          Expanded(child: _buildMessageList(provider)),
                          _buildInputArea(provider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // ── Draggable FAB ─────────────────────────────────────────────
            if (!provider.isOpen)
              Positioned(
                left: _fabX,
                top: _fabY,
                child: Draggable(
                  // feedback shown while dragging
                  feedback: _buildFab(provider, dragging: true),
                  // hide original while dragging
                  childWhenDragging: const SizedBox.shrink(),
                  onDragEnd: (details) {
                    setState(() {
                      _fabX = details.offset.dx;
                      _fabY = details.offset.dy;
                      _clampFabPosition(screenSize);
                    });
                  },
                  child: _buildFab(provider, dragging: false),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFab(AiChatProvider provider, {required bool dragging}) {
    return AnimatedScale(
      scale: dragging ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: dragging ? null : () => provider.openChat(),
          child: Container(
            width: _fabSize,
            height: _fabSize,
            decoration: BoxDecoration(
              color: primaryTeal,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryTeal.withOpacity(dragging ? 0.5 : 0.35),
                  blurRadius: dragging ? 20 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy,
                color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(AiChatProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryTeal, primaryTeal.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 16,
                child: Icon(Icons.smart_toy, color: primaryTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'HIMS AI Agent',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Powered by Llama 3.3',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.delete_sweep,
                    color: Colors.white, size: 20),
                tooltip: 'Clear chat',
                onPressed: () => provider.clearChat(),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: () => provider.closeChat(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Message List ─────────────────────────────────────────────────────────

  Widget _buildMessageList(AiChatProvider provider) {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
        provider.messages.length + (provider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.messages.length) {
            return _buildLoadingIndicator();
          }
          final msg = provider.messages[index];
          return _buildMessageBubble(msg);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: primaryTeal.withOpacity(0.1),
            radius: 14,
            child: Icon(Icons.smart_toy, color: primaryTeal, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)
                  .copyWith(bottomLeft: const Radius.circular(4)),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: primaryTeal),
                ),
                const SizedBox(width: 8),
                Text('Generating answer...',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    bool showButton = msg.isAi && msg.entities != null && msg.entities!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
        msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.isAi) ...[
            CircleAvatar(
              backgroundColor: primaryTeal.withOpacity(0.1),
              radius: 14,
              child: Icon(Icons.smart_toy, color: primaryTeal, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: msg.isUser ? primaryTeal : Colors.white,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: msg.isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: msg.isAi
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  if (!msg.isUser)
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2)),
                  if (msg.isUser)
                    BoxShadow(
                        color: primaryTeal.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                ],
                border: msg.isUser
                    ? null
                    : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white
                          : const Color(0xFF1F2937),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (showButton) ...[
                    const SizedBox(height: 12),
                    const Divider(
                        height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        final e = msg.entities ?? {};
                        final mr = e['mr_number']?.toString();
                        final name = e['patient_name']?.toString();
                        final search = mr ?? name ?? '';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => OpdRecordsScreen(initialSearch: search)),
                        );
                        Provider.of<AiChatProvider>(context, listen: false).closeChat();
                      },
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Records'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryTeal,
                        backgroundColor: primaryTeal.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey.shade500,
              radius: 14,
              child:
              const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  // ── Input Area ───────────────────────────────────────────────────────────

  Widget _buildInputArea(AiChatProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.transparent),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (text) => setState(() {}),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && !provider.isLoading) {
                        provider.sendMessage(value);
                        _queryController.clear();
                        setState(() {});
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _queryController.text.isNotEmpty &&
                        !provider.isLoading
                        ? primaryTeal
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _queryController.text.isNotEmpty &&
                        !provider.isLoading
                        ? [
                      BoxShadow(
                          color: primaryTeal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4))
                    ]
                        : null,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, size: 18),
                    color: Colors.white,
                    onPressed:
                    _queryController.text.isNotEmpty &&
                        !provider.isLoading
                        ? () {
                      provider
                          .sendMessage(_queryController.text);
                      _queryController.clear();
                      setState(() {});
                    }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome,
                  size: 12, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'AI can make mistakes. Please verify important data.',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}