import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/team_chat_message.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class TeamChatScreen extends StatefulWidget {
  const TeamChatScreen({super.key});

  @override
  State<TeamChatScreen> createState() => _TeamChatScreenState();
}

class _TeamChatScreenState extends State<TeamChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await context.read<AppState>().sendTeamMessage(text);
      if (mounted) _messageController.clear();
    } on PlatformException catch (_) {
      _showError('Could not save your message. Please try again.');
    } on StateError catch (error) {
      _showError(error.message);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final team = state.team;
    final currentUserId = state.me?.id ?? meId;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(team == null ? 'Team chat' : team.title)),
      body: team == null
          ? const Center(child: Text('Create a team to start chatting.'))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  color: colors.primaryContainer.withValues(alpha: 0.55),
                  child: Text(
                    '${team.memberIds.length} ${team.memberIds.length == 1 ? 'member' : 'members'} · Team conversation',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
                Expanded(
                  child: team.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.forum_outlined,
                                  size: 44,
                                  color: colors.primary.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Start the conversation',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Messages you send will be saved with your team.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: team.messages.length,
                          itemBuilder: (context, index) {
                            final message =
                                team.messages[team.messages.length - 1 - index];
                            return _MessageBubble(
                              message: message,
                              isMine: message.senderId == currentUserId,
                            );
                          },
                        ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.md,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('team-chat-composer'),
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              hintText: 'Message your team',
                              isDense: true,
                              prefixIcon: Icon(Icons.chat_bubble_outline),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _messageController,
                          builder: (context, value, _) => IconButton.filled(
                            key: const ValueKey('send-team-message'),
                            tooltip: 'Send message',
                            onPressed: value.text.trim().isEmpty ? null : _send,
                            icon: const Icon(Icons.send_rounded),
                          ),
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

class _MessageBubble extends StatelessWidget {
  final TeamChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isMine ? AppColors.primary : AppColors.surface;
    final foreground = isMine ? Colors.white : AppColors.ink;
    final sentAt = TimeOfDay.fromDateTime(
      message.sentAt.toLocal(),
    ).format(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(AppRadii.md),
                topRight: const Radius.circular(AppRadii.md),
                bottomLeft: Radius.circular(
                  isMine ? AppRadii.md : AppSpacing.xs,
                ),
                bottomRight: Radius.circular(
                  isMine ? AppSpacing.xs : AppRadii.md,
                ),
              ),
              border: isMine ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine) ...[
                  Text(
                    message.senderName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Text(message.text, style: TextStyle(color: foreground)),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    sentAt,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
