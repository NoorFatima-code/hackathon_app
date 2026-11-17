import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

Future<List<String>?> showAssignRolesDialog({
  required BuildContext context,
  required String memberName,
  required String projectType,
  required List<String> options,
  List<String> initialRoles = const [],
  String actionLabel = 'Assign roles',
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (_) => _AssignRolesDialog(
      memberName: memberName,
      projectType: projectType,
      options: options,
      initialRoles: initialRoles,
      actionLabel: actionLabel,
    ),
  );
}

class _AssignRolesDialog extends StatefulWidget {
  final String memberName;
  final String projectType;
  final List<String> options;
  final List<String> initialRoles;
  final String actionLabel;

  const _AssignRolesDialog({
    required this.memberName,
    required this.projectType,
    required this.options,
    required this.initialRoles,
    required this.actionLabel,
  });

  @override
  State<_AssignRolesDialog> createState() => _AssignRolesDialogState();
}

class _AssignRolesDialogState extends State<_AssignRolesDialog> {
  late final Set<String> _selected = widget.initialRoles.toSet();

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Assign project roles'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose one or more roles for ${widget.memberName} '
          'on this ${widget.projectType}.',
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final role in widget.options)
                  FilterChip(
                    key: ValueKey('assign-role-$role'),
                    label: Text(role),
                    selected: _selected.contains(role),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selected.add(role);
                        } else {
                          _selected.remove(role);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const ValueKey('confirm-member-roles'),
        onPressed: _selected.isEmpty
            ? null
            : () => Navigator.pop(context, _selected.toList()),
        child: Text(widget.actionLabel),
      ),
    ],
  );
}
