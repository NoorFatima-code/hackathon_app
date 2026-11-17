import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../models/team.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/assign_roles_dialog.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import 'team_chat_screen.dart';

class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  void _openCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateTeamSheet(),
    );
  }

  Future<void> _editMemberRoles(
    BuildContext context,
    Team team,
    Student member,
  ) async {
    final currentRoles = team.memberRoles[member.id] ?? const <String>[];
    final options = {
      ...(team.rolesNeeded.isEmpty ? teamRoleOptions : team.rolesNeeded),
      ...currentRoles,
    }.toList();
    final roles = await showAssignRolesDialog(
      context: context,
      memberName: member.name,
      projectType: team.projectType,
      options: options,
      initialRoles: currentRoles,
      actionLabel: 'Save roles',
    );
    if (roles == null || !context.mounted) return;

    await context.read<AppState>().assignMemberRoles(member.id, roles);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('${member.name} roles updated')));
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    Team team,
    Student member,
  ) async {
    final confirmed = await confirmDialog(
      context,
      title: 'Remove team member?',
      message:
          'Remove ${member.name} from "${team.title}"? Their assigned roles '
          'will become available again. Chat history will be kept.',
      confirmLabel: 'Remove partner',
    );
    if (!confirmed || !context.mounted) return;

    try {
      await context.read<AppState>().removeTeamMember(member.id);
    } on PlatformException catch (_) {
      if (context.mounted) {
        _showMessage(context, 'Could not save the team changes.');
      }
      return;
    } on StateError catch (error) {
      if (context.mounted) _showMessage(context, error.message.toString());
      return;
    }

    if (context.mounted) _showMessage(context, '${member.name} removed');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final team = state.team;

    if (team == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Team')),
        body: EmptyState(
          icon: Icons.groups_outlined,
          title: 'No team yet',
          subtitle: 'Create a team and list the roles you need.',
          action: FilledButton.icon(
            onPressed: () => _openCreate(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create team'),
          ),
        ),
      );
    }

    final members = <Student?>[
      for (final id in team.memberIds) state.studentById(id),
    ];
    final openRoles = team.rolesNeeded;
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Team'),
        actions: [
          IconButton(
            tooltip: 'Leave team',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final ok = await confirmDialog(
                context,
                title: 'Leave team?',
                message: 'This will remove "${team.title}" and its members.',
                confirmLabel: 'Leave',
              );
              if (ok && context.mounted) {
                await context.read<AppState>().leaveTeam();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    t.colorScheme.primaryContainer,
                    t.colorScheme.secondaryContainer,
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: t.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          team.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            _SummaryBadge(
                              icon: Icons.category_outlined,
                              label: team.projectType,
                            ),
                            _SummaryBadge(
                              icon: Icons.people_outline,
                              label:
                                  '${members.length} ${members.length == 1 ? 'member' : 'members'}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: ListTile(
              key: const ValueKey('team-chat-entry'),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.forum_outlined,
                  color: AppColors.accent,
                ),
              ),
              title: const Text('Team chat'),
              subtitle: Text(
                team.messages.isEmpty
                    ? 'Start a conversation with your team'
                    : '${team.messages.length} ${team.messages.length == 1 ? 'message' : 'messages'}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const TeamChatScreen()),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _TeamNeedsCard(
            title: 'Roles needed',
            icon: Icons.work_outline_rounded,
            values: openRoles,
            color: AppColors.primary,
            emptyMessage: 'No specific roles added yet.',
          ),
          const SizedBox(height: AppSpacing.md),
          _TeamNeedsCard(
            title: 'Skills needed',
            icon: Icons.bolt_rounded,
            values: team.skillsNeeded,
            color: AppColors.accent,
            emptyMessage: 'No specific skills added yet.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.people_outline, color: t.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Members (${members.length})',
                style: t.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final m in members)
            _TeamMemberCard(
              key: ValueKey('team-member-${m?.id ?? meId}'),
              member: m,
              roles: m == null ? const [] : team.memberRoles[m.id] ?? const [],
              onTap: m == null || m.id == meId
                  ? null
                  : () => _editMemberRoles(context, team, m),
              onRemove: m == null || m.id == meId
                  ? null
                  : () => _removeMember(context, team, m),
            ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _TeamNeedsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> values;
  final Color color;
  final String emptyMessage;

  const _TeamNeedsCard({
    required this.title,
    required this.icon,
    required this.values,
    required this.color,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                Text(
                  '${values.length}',
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (values.isEmpty)
              Text(emptyMessage, style: theme.textTheme.bodySmall)
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final value in values)
                    Chip(
                      avatar: Icon(icon, size: 16, color: color),
                      label: Text(value),
                      backgroundColor: color.withValues(alpha: 0.07),
                      side: BorderSide(color: color.withValues(alpha: 0.16)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamMemberCard extends StatelessWidget {
  final Student? member;
  final List<String> roles;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _TeamMemberCard({
    super.key,
    required this.member,
    required this.roles,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = member == null || member!.id == meId;
    final name = member == null
        ? 'You'
        : '${member!.name}${isOwner ? ' (You)' : ''}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  name[0].toUpperCase(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      member == null
                          ? 'Team owner'
                          : '${member!.department} · Semester ${member!.semester}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (roles.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Project roles',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final role in roles)
                            _memberTag(
                              theme,
                              role,
                              AppColors.primary,
                              Icons.work_outline_rounded,
                            ),
                        ],
                      ),
                    ],
                    if (onTap != null && roles.isEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Tap to assign project roles',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                    if (member != null && member!.skills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Skills',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final skill in member!.skills.take(3))
                            _memberTag(
                              theme,
                              skill,
                              AppColors.accent,
                              Icons.bolt_rounded,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (onRemove != null)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    IconButton(
                      key: ValueKey('remove-team-member-${member!.id}'),
                      tooltip: 'Remove team member',
                      onPressed: onRemove,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.person_remove_alt_1_outlined,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  isOwner ? Icons.verified_user_outlined : Icons.person_outline,
                  color: isOwner ? AppColors.accent : AppColors.muted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _memberTag(
    ThemeData theme,
    String label,
    Color color,
    IconData icon,
  ) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ],
    ),
  );
}

class _ChoiceSection extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String keyPrefix;
  final List<String> values;
  final Set<String> selected;
  final Color color;
  final ValueChanged<String> onToggle;

  const _ChoiceSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
                Text(
                  '${selected.length} selected',
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(description, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final value in values)
                  FilterChip(
                    key: ValueKey('$keyPrefix-$value'),
                    label: Text(value),
                    selected: selected.contains(value),
                    selectedColor: color.withValues(alpha: 0.14),
                    checkmarkColor: color,
                    onSelected: (_) => onToggle(value),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateTeamSheet extends StatefulWidget {
  const _CreateTeamSheet();

  @override
  State<_CreateTeamSheet> createState() => _CreateTeamSheetState();
}

class _CreateTeamSheetState extends State<_CreateTeamSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  String _type = projectTypes.first;
  final Set<String> _roles = {};
  final Set<String> _skills = {};

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roles.isEmpty && _skills.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select at least one role or skill')),
        );
      return;
    }
    await context.read<AppState>().createTeam(
      _title.text,
      _type,
      roles: _roles.toList(),
      skills: _skills.toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final sortedSkills = [...allSkills]..sort();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create team',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                key: const ValueKey('team-title'),
                controller: _title,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Project title',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Enter a project title'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Project type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final p in projectTypes)
                    DropdownMenuItem(value: p, child: Text(p)),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceSection(
                title: 'Roles needed',
                description: 'Choose the teammate roles for this project.',
                icon: Icons.work_outline_rounded,
                keyPrefix: 'role-option',
                values: teamRoleOptions,
                selected: _roles,
                color: AppColors.primary,
                onToggle: (value) => setState(
                  () => _roles.contains(value)
                      ? _roles.remove(value)
                      : _roles.add(value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ChoiceSection(
                title: 'Skills needed',
                description: 'Add technical or creative skills.',
                icon: Icons.bolt_rounded,
                keyPrefix: 'skill-option',
                values: sortedSkills,
                selected: _skills,
                color: AppColors.accent,
                onToggle: (value) => setState(
                  () => _skills.contains(value)
                      ? _skills.remove(value)
                      : _skills.add(value),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('submit-create-team'),
                  onPressed: _create,
                  child: const Text('Create team'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
