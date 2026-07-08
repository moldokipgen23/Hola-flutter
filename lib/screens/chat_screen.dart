import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';

class _Message {
  final int id;
  final String message;
  final bool isMine;
  final String createdAt;

  _Message({
    required this.id,
    required this.message,
    required this.isMine,
    required this.createdAt,
  });

  factory _Message.fromJson(Map<String, dynamic> json) {
    return _Message(
      id: json['id'],
      message: json['message'],
      isMine: json['is_mine'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Business? business;
  final int? conversationId;

  const ChatScreen({super.key, this.business, this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<_Message> messages = [];
  int? conversationId;
  bool loading = true;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.conversationId != null) {
        final result = await api.get('/chat/conversations/${widget.conversationId}');
        if (mounted) {
          setState(() {
            conversationId = widget.conversationId;
            loading = false;
            final raw = result['messages'] as List? ?? [];
            messages = raw.map((m) => _Message.fromJson(m)).toList();
          });
          _scrollToBottom();
        }
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || sending) return;

    if (conversationId == null && widget.business == null) return;

    setState(() {
      sending = true;
      messages.add(_Message(
        id: DateTime.now().millisecondsSinceEpoch,
        message: text,
        isMine: true,
        createdAt: DateTime.now().toIso8601String(),
      ));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      dynamic result;
      if (conversationId != null) {
        result = await api.post('/chat/conversations/$conversationId/reply', body: {'message': text});
      } else {
        result = await api.post('/chat/businesses/${widget.business!.id}', body: {'message': text});
        conversationId = result['conversation']['id'];
      }
      if (mounted) {
        setState(() {
          messages.removeLast();
          final msg = result['message'] ?? result;
          messages.add(_Message.fromJson(msg));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final businessName = widget.business?.name ?? 'Chat';

    return Scaffold(
      appBar: AppBar(title: Text(businessName)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final msg = messages[index];
                            return Align(
                              alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                                decoration: BoxDecoration(
                                  color: msg.isMine ? AppTheme.primary : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: msg.isMine ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: msg.isMine ? Radius.zero : const Radius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  msg.message,
                                  style: TextStyle(
                                    color: msg.isMine ? Colors.white : AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2)),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                                )
                              : const Icon(Icons.send, color: AppTheme.primary),
                          onPressed: sending ? null : _sendMessage,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
