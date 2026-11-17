import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _dept;
  late int _semester;
  late String _projectType;
  late String _availability;
  late Set<String> _skills;
  late Set<String> _interests;

  @override
  void initState() {
    super.initState();
    final me = context.read<AppState>().me;
    _name = TextEditingController(text: me?.name ?? '');
    _bio = TextEditingController(text: me?.bio ?? '');
    _dept = me?.department ?? departments.first;
    _semester = me?.semester ?? semesters.first;
    _projectType = me?.projectType ?? projectTypes.first;
    _availability = me?.availability ?? availabilityOptions.first;
    _skills = {...?me?.skills};
    _interests = {...?me?.interests};
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _toast(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_skills.isEmpty) return _toast('Select at least one skill');
    if (_interests.isEmpty) return _toast('Select at least one interest');

    final profile = Student(
      id: meId,
      name: _name.text.trim(),
      department: _dept,
      semester: _semester,
      skills: _skills.toList(),
      interests: _interests.toList(),
      projectType: _projectType,
      availability: _availability,
      bio: _bio.text.trim(),
    );
    await context.read<AppState>().saveProfile(profile);
    if (mounted) _toast('Profile saved');
  }

  @override
  Widget build(BuildContext context) {
    final hasProfile = context.watch<AppState>().me != null;

    return Scaffold(
      appBar: AppBar(title: Text(hasProfile ? 'My Profile' : 'Create Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (!hasProfile)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Create your profile to get matched with teammates.',
                ),
              ),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _dept,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: [
                      for (final d in departments)
                        DropdownMenuItem(value: d, child: Text(d)),
                    ],
                    onChanged: (v) => setState(() => _dept = v!),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _semester,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: [
                      for (final s in semesters)
                        DropdownMenuItem(value: s, child: Text('$s')),
                    ],
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _projectType,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Project type',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final p in projectTypes)
                  DropdownMenuItem(value: p, child: Text(p)),
              ],
              onChanged: (v) => setState(() => _projectType = v!),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _availability,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Availability',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
              items: [
                for (final a in availabilityOptions)
                  DropdownMenuItem(value: a, child: Text(a)),
              ],
              onChanged: (v) => setState(() => _availability = v!),
            ),
            const SizedBox(height: AppSpacing.lg),
            _chipGroup('Skills', allSkills, _skills),
            const SizedBox(height: AppSpacing.md),
            _chipGroup('Interests', allInterests, _interests),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              maxLength: 150,
              decoration: const InputDecoration(
                labelText: 'Short bio',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(hasProfile ? 'Update Profile' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup(String title, List<String> options, Set<String> selected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final o in options)
              FilterChip(
                label: Text(o),
                selected: selected.contains(o),
                onSelected: (on) =>
                    setState(() => on ? selected.add(o) : selected.remove(o)),
              ),
          ],
        ),
      ],
    );
  }
}
