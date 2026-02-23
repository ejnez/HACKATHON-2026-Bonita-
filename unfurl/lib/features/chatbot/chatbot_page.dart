import 'package:flutter/material.dart';
import 'package:unfurl/features/tasks/task_provider.dart';
import 'package:unfurl/shared/theme.dart';
import 'package:unfurl/shared/widgets/app_drawer.dart';

class _ChatMessage {
  final String text;
  final bool fromUser;
  final bool isNotice;

  const _ChatMessage({
    required this.text,
    required this.fromUser,
    this.isNotice = false,
  });
}

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  static const String _demoUserId = 'demo-user';

  final TaskProvider _provider = TaskProvider();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _loading = false;
  String _sessionId = _newSessionId();
  List<Map<String, dynamic>> _generatedTasks = const [];
  final List<_ChatMessage> _messages = const [
    _ChatMessage(
      text: 'Welcome to Unfurl. Paste your brain dump and I will organize it for you.',
      fromUser: false,
      isNotice: true,
    ),
  ].toList();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static String _newSessionId() {
    return 'demo-session-${DateTime.now().millisecondsSinceEpoch}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    _controller.clear();
    setState(() {
      _loading = true;
      _messages.add(_ChatMessage(text: text, fromUser: true));
    });
    _scrollToBottom();

    try {
      final res = await _provider.sendBrainDump(
        sessionId: _sessionId,
        userId: _demoUserId,
        message: text,
      );
      final ready = res['list_ready'] == true;
      final tasks = (res['tasks'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      setState(() {
        _generatedTasks = ready ? tasks : const [];
        _messages.add(
          _ChatMessage(
            text: ready
                ? 'The list will be created soon.'
                : (res['reply']?.toString() ?? 'I got your message.'),
            fromUser: false,
          ),
        );
      });

      if (ready && tasks.isNotEmpty) {
        _scrollToBottom();
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
        } else {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      setState(() {
        _generatedTasks = const [];
        _messages.add(
          _ChatMessage(
            text: 'Could not send right now: $e',
            fromUser: false,
            isNotice: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      _scrollToBottom();
    }
  }

  void _clearConversation() {
    setState(() {
      _sessionId = _newSessionId();
      _generatedTasks = const [];
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            text: 'Conversation cleared. Share a new brain dump when you are ready.',
            fromUser: false,
            isNotice: true,
          ),
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unload My Brain')),
      drawer: const AppDrawer(currentRoute: '/chatbot'),
      body: Container(
        decoration: const BoxDecoration(gradient: blossomBackground),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.82),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD7E7DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color.fromRGBO(40, 72, 57, 0.08),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.spa_rounded, color: sageGreen, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Brain Dump',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                Text(
                                  'Dump thoughts. Get a sorted plan.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _clearConversation,
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD9E9E0)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(40, 72, 57, 0.10),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                                itemCount: _messages.length + (_loading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (_loading && index == _messages.length) {
                                    return const _TypingBubble();
                                  }
                                  final message = _messages[index];
                                  return _ChatBubble(message: message);
                                },
                              ),
                            ),
                            if (_generatedTasks.isNotEmpty)
                              _TaskSummary(tasks: _generatedTasks),
                            _Composer(
                              controller: _controller,
                              loading: _loading,
                              onSend: _send,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF8),
        border: Border(
          top: BorderSide(color: sageGreen.withValues(alpha: 0.18)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE9E2)),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !loading,
                onSubmitted: (_) => onSend(),
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Write what is on your mind...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: loading ? null : onSend,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(78, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.1,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.send_rounded, size: 18),
                      SizedBox(width: 4),
                      Text('Send'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isNotice) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8F5),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0xFFDDEAE3)),
            ),
            child: Text(
              message.text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final alignment =
        message.fromUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor =
        message.fromUser ? sageGreen.withValues(alpha: 0.92) : Colors.white;
    final textColor = message.fromUser ? Colors.white : cocoaText;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: message.fromUser
                ? sageGreen.withValues(alpha: 0.28)
                : sageGreen.withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          message.text,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: textColor),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: sageGreen.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(color: sageGreen.withValues(alpha: 0.45)),
            const SizedBox(width: 4),
            _Dot(color: sageGreen.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            _Dot(color: sageGreen),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;

  const _Dot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _TaskSummary extends StatelessWidget {
  final List<Map<String, dynamic>> tasks;

  const _TaskSummary({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDBE9E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your List',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          ...tasks.map((task) {
            final rank = task['priority_rank']?.toString() ?? '-';
            final name = task['task_name']?.toString() ?? 'Untitled task';
            final mins = task['estimated_time']?.toString() ?? '?';
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sageGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      rank,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('$name  -  $mins min')),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

