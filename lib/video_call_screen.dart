import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/match_provider.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final ScrollController _chatScrollController = ScrollController();
  bool _showEmojiPanel = false;

  @override
  void dispose() {
    _chatScrollController.dispose();
    super.dispose();
  }

  Widget _buildMainVideoArea(MatchProvider provider) {
    final hasProfilePhoto = provider.profileImageBytes != null;

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white10,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.75), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: ClipOval(
        child: hasProfilePhoto
            ? Image.memory(
                provider.profileImageBytes!,
                fit: BoxFit.cover,
                width: 220,
                height: 220,
                gaplessPlayback: true,
              )
            : const Center(
                child: Icon(Icons.person, size: 84, color: Colors.white54),
              ),
      ),
    );
  }

  void _appendEmoji(TextEditingController controller, String emoji) {
    final text = controller.text;
    controller.text = '$text$emoji';
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchProvider>(
      builder: (context, provider, child) {
        if (provider.chatHistory.isNotEmpty) {
          _scrollToBottom();
        }

        final currentUser = provider.nameController.text.trim().isEmpty ? 'You' : provider.nameController.text.trim();

        return Scaffold(
          appBar: AppBar(
            title: Text('VibeMatch Call: ${widget.channelName}'),
            backgroundColor: const Color(0xFF0A0A0E),
            elevation: 0,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: const Color(0xFF0A0A0E),
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildMainVideoArea(provider),
                          const SizedBox(height: 18),
                          const Text(
                            'Connected to Call Successfully! 🚀',
                            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            '(Bypassed Mac local dependencies for smooth web testing)',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: const Color(0xFF060609),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                              child: Row(
                                children: [
                                  const Text(
                                    'Live Chat',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Room ${widget.channelName}',
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: provider.chatHistory.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No messages yet. Say hello! 👋',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _chatScrollController,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      itemCount: provider.chatHistory.length,
                                      itemBuilder: (context, index) {
                                        final message = provider.chatHistory[index];
                                        final isMine = message.sender == currentUser || message.sender == 'You';
                                        return Align(
                                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.symmetric(vertical: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                                            decoration: BoxDecoration(
                                              color: isMine ? const Color(0xFF8B5CF6) : Colors.white10,
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(18),
                                                topRight: const Radius.circular(18),
                                                bottomLeft: Radius.circular(isMine ? 18 : 4),
                                                bottomRight: Radius.circular(isMine ? 4 : 18),
                                              ),
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  message.sender,
                                                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  message.message,
                                                  style: const TextStyle(fontSize: 16, color: Colors.white),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  message.time,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: isMine ? Colors.white70 : Colors.white60,
                                                  ),
                                                  textAlign: isMine ? TextAlign.right : TextAlign.left,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: provider.partnerTyping
                                ? Container(
                                    key: const ValueKey('typingIndicator'),
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(255, 255, 255, 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Partner is typing...',
                                      style: TextStyle(color: Colors.white70, fontSize: 14),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 8),
                          if (_showEmojiPanel)
                            Container(
                              width: double.infinity,
                              height: 200,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F0F16),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                              ),
                              child: GridView.count(
                                crossAxisCount: 6,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: ['😂', '❤️', '👍', '😍', '🔥', '👏', '🎉', '😢', '😮', '😡', '🙏', '✨']
                                    .map((emoji) {
                                  return GestureDetector(
                                    onTap: () => _appendEmoji(provider.chatTextController, emoji),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Center(
                                        child: Text(
                                          emoji,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F0F16),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.5), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.emoji_emotions, color: Color(0xFF8B5CF6)),
                                  onPressed: () {
                                    setState(() {
                                      _showEmojiPanel = !_showEmojiPanel;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: provider.chatTextController,
                                    decoration: const InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(color: Colors.white38),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                                    ),
                                    style: const TextStyle(color: Colors.white),
                                    textInputAction: TextInputAction.send,
                                    onChanged: (text) {
                                      if (text.isEmpty) {
                                        provider.emitStopTypingIfNeeded();
                                      } else {
                                        provider.emitTypingIfNeeded();
                                      }
                                    },
                                    onSubmitted: (_) => provider.sendChatMessage(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.send, color: Color(0xFF8B5CF6)),
                                  onPressed: provider.sendChatMessage,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF2A2A),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('End Call', style: TextStyle(fontSize: 16, color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Tooltip(
                            message: 'Next Vibe',
                            child: InkWell(
                              onTap: provider.nextVibe,
                              borderRadius: BorderRadius.circular(32),
                              child: Container(
                                width: 74,
                                height: 74,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF007F),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 8)),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                                    SizedBox(height: 2),
                                    Text('Next Vibe', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (provider.hasIncomingCall) _buildIncomingCallDialog(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIncomingCallDialog(MatchProvider provider) {
    final imageBytes = provider.incomingCallPartnerImageBytes;

    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        alignment: Alignment.center,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F16),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Incoming Vibe Match',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
                child: ClipOval(
                  child: imageBytes != null
                      ? Image.memory(imageBytes, fit: BoxFit.cover)
                      : const Icon(Icons.person, size: 52, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                provider.incomingCallPartnerName ?? 'Someone',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.acceptIncomingCall,
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Accept', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.rejectIncomingCall,
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF2A2A)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
