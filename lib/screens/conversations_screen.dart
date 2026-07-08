import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api.dart';
import '../theme.dart';
import 'chat_screen.dart';

class _Conversation {
  final int id;
  final Business business;
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;

  _Conversation({
    required this.id,
    required this.business,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
  });

  factory _Conversation.fromJson(Map<String, dynamic> json) {
    return _Conversation(
      id: json['id'],
      business: Business.fromJson(json['business']),
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
    );
  }
}

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  List<_Conversation> conversations = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await api.get('/chat/conversations');
      if (mounted) {
        setState(() {
          conversations = (result['conversations'] as List).map((c) => _Conversation.fromJson(c)).toList();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await api.get('/chat/conversations');
      if (mounted) {
        setState(() {
          conversations = (result['conversations'] as List).map((c) => _Conversation.fromJson(c)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : conversations.isEmpty
              ? const Center(child: Text('No conversations yet'))
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = conversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Text('🏪', style: TextStyle(fontSize: 20)),
                        ),
                        title: Text(c.business.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          c.lastMessage ?? 'Start a conversation',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (c.lastMessageTime != null)
                              Text(
                                c.lastMessageTime!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                              ),
                            if (c.unreadCount > 0) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  c.unreadCount.toString(),
                                  style: const TextStyle(fontSize: 11, color: Colors.white),
                                ),
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(conversationId: c.id),
                          ));
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
