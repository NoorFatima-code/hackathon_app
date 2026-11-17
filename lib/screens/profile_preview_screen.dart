import 'package:flutter/material.dart';
import '../models/student.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skill_chip.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({super.key, required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile preview')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: student.name,
                    photoData: student.photoData,
                    radius: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    student.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${student.department} • Semester ${student.semester}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      _metadata(
                        context,
                        Icons.category_outlined,
                        student.projectType,
                      ),
                      _metadata(
                        context,
                        Icons.schedule_outlined,
                        student.availability,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (student.bio.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _section(
              context,
              title: 'About',
              child: Text(
                student.bio,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (student.skills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _section(context, title: 'Skills', child: _chips(student.skills)),
          ],
          if (student.interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _section(
              context,
              title: 'Interests',
              child: _chips(student.interests),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metadata(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _section(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }

  Widget _chips(List<String> labels) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [for (final label in labels) SkillChip(label)],
    );
  }
}
