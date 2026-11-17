import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state.dart';
import '../widgets/skill_chip.dart';

class MyTeamScreen extends StatelessWidget {
  const MyTeamScreen({super.key});

  void _openCreate(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateTeamSheet(),
    );
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
    final memberSkills = {for (final m in members) ...?m?.skills};
    final openRoles = team.rolesNeeded
        .where((r) => !memberSkills.contains(r))
        .toList();
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
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.white,
                    foregroundColor: t.colorScheme.primary,
                    child: const Icon(Icons.groups_outlined),
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
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          team.projectType,
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(Icons.work_outline, color: t.colorScheme.primary),
              const SizedBox(width: AppSpacing.sm),
              Text('Open roles', style: t.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (openRoles.isEmpty)
            const Text('All roles are filled 🎉')
          else
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final r in openRoles) SkillChip(r, highlight: true),
              ],
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
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: t.colorScheme.primaryContainer,
                  foregroundColor: t.colorScheme.onPrimaryContainer,
                  child: Text((m?.name[0] ?? 'Y').toUpperCase()),
                ),
                title: Text(
                  m == null
                      ? 'You'
                      : (m.id == meId ? '${m.name} (You)' : m.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  m == null ? '' : m.skills.join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
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

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select at least one role')),
        );
      return;
    }
    await context.read<AppState>().createTeam(
      _title.text,
      _type,
      _roles.toList(),
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'Roles / skills needed',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final s in allSkills)
                    FilterChip(
                      label: Text(s),
                      selected: _roles.contains(s),
                      onSelected: (on) =>
                          setState(() => on ? _roles.add(s) : _roles.remove(s)),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
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
