import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/team_request.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/assign_roles_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          bottom: TabBar(
            tabs: [
              const Tab(icon: Icon(Icons.send_outlined), text: 'Sent'),
              Tab(
                icon: const Icon(Icons.inbox_outlined),
                text: state.pendingReceivedCount > 0
                    ? 'Received (${state.pendingReceivedCount})'
                    : 'Received',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RequestList(items: state.sent, isSent: true),
            _RequestList(items: state.received, isSent: false),
          ],
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  final List<TeamRequest> items;
  final bool isSent;
  const _RequestList({required this.items, required this.isSent});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        icon: isSent ? Icons.send_outlined : Icons.inbox_outlined,
        title: isSent ? 'No sent requests yet' : 'No requests yet',
        subtitle: isSent
            ? 'Go to Discover and send a request.'
            : 'Requests from other students will show here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: items.length,
      itemBuilder: (_, i) => _RequestCard(request: items[i], isSent: isSent),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final TeamRequest request;
  final bool isSent;
  const _RequestCard({required this.request, required this.isSent});

  void _toast(BuildContext context, String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _cancel(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Cancel request?',
      message: 'Cancel your request to ${request.student.name}?',
      confirmLabel: 'Cancel request',
    );
    if (!ok || !context.mounted) return;
    await context.read<AppState>().cancelRequest(request.id);
    if (context.mounted) _toast(context, 'Request cancelled');
  }

  Future<void> _accept(BuildContext context) async {
    final state = context.read<AppState>();
    final team = state.team;
    if (team == null) {
      _toast(context, 'Create your team first in the My Team tab');
      return;
    }

    final roles = await showAssignRolesDialog(
      context: context,
      memberName: request.student.name,
      projectType: team.projectType,
      options: team.rolesNeeded.isEmpty ? teamRoleOptions : team.rolesNeeded,
    );
    if (roles == null || !context.mounted) return;

    await state.respondToRequest(
      request.id,
      accept: true,
      assignedRoles: roles,
    );
    if (context.mounted) {
      _toast(context, '${request.student.name} added to your team');
    }
  }

  Future<void> _reject(BuildContext context) async {
    await context.read<AppState>().respondToRequest(request.id, accept: false);
    if (context.mounted) _toast(context, 'Request rejected');
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes.clamp(1, 59)}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final r = request;
    final pending = r.status == RequestStatus.pending;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: t.colorScheme.primaryContainer,
                  foregroundColor: t.colorScheme.onPrimaryContainer,
                  child: Text(r.student.name[0].toUpperCase()),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.titleMedium,
                      ),
                      Text(
                        '${r.student.department} • Sem ${r.student.semester} • ${_ago(r.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(r.status),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.format_quote_rounded,
                  size: 18,
                  color: t.colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    r.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: t.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (pending) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: isSent
                    ? OutlinedButton.icon(
                        onPressed: () => _cancel(context),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel'),
                      )
                    : Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _reject(context),
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Reject'),
                          ),
                          FilledButton.icon(
                            onPressed: () => _accept(context),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Accept'),
                          ),
                        ],
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
