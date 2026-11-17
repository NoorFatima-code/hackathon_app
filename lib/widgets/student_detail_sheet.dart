import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'skill_chip.dart';

Future<void> showStudentDetailSheet(
  BuildContext context, {
  required Student student,
  int? score,
  List<String> reasons = const [],
  Set<String> highlightSkills = const {},
}) async {
  final requestSent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => StudentDetailSheet(
      student: student,
      score: score,
      reasons: reasons,
      highlightSkills: highlightSkills,
    ),
  );

  if (requestSent == true && context.mounted) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('Request sent to ${student.name}.')),
      );
  }
}

class StudentDetailSheet extends StatefulWidget {
  final Student student;
  final int? score;
  final List<String> reasons;
  final Set<String> highlightSkills;

  const StudentDetailSheet({
    super.key,
    required this.student,
    this.score,
    this.reasons = const [],
    this.highlightSkills = const {},
  });

  @override
  State<StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends State<StudentDetailSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _message;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final firstName = widget.student.name.trim().split(RegExp(r'\s+')).first;
    _message = TextEditingController(
      text: 'Hi $firstName, I would like to team up with you.',
    );
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    if (_sending || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    bool sent;
    try {
      sent = await context.read<AppState>().sendRequest(
        widget.student,
        _message.text,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }

    if (!mounted) return;
    if (sent) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'A request to ${widget.student.name} is already pending.',
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final student = widget.student;
    final requestPending = context.watch<AppState>().hasPendingTo(student.id);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.primary,
                    child: Text(
                      student.name[0].toUpperCase(),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.name, style: theme.textTheme.titleLarge),
                        Text(
                          '${student.department} • Semester ${student.semester}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.sm,
                children: [
                  _metadata(Icons.category_outlined, student.projectType),
                  _metadata(Icons.schedule_outlined, student.availability),
                  if (widget.score != null)
                    _metadata(
                      Icons.auto_awesome_outlined,
                      '${widget.score}% match',
                    ),
                ],
              ),
              if (student.bio.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('About', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(student.bio, style: theme.textTheme.bodyMedium),
              ],
              if (student.skills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Skills', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final skill in student.skills)
                      SkillChip(
                        skill,
                        highlight: widget.highlightSkills.contains(skill),
                      ),
                  ],
                ),
              ],
              if (student.interests.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Interests', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final interest in student.interests)
                      SkillChip(interest),
                  ],
                ),
              ],
              if (widget.reasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Why this match', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                for (final reason in widget.reasons)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: colors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (requestPending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Your request is already pending.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Text('Short message', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('request-message'),
                  controller: _message,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    hintText: 'Introduce yourself and your project idea.',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Write a short message'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _sendRequest,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: const Text('Send request'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metadata(IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.secondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
