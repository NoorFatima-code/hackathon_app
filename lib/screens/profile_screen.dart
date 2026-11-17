import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/skill_chip.dart';
import 'profile_preview_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _completionFields = 9;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late String _dept;
  late int _semester;
  late String _projectType;
  late String _availability;
  late Set<String> _skills;
  late Set<String> _interests;
  String? _photoData;
  late bool _isEditing;
  bool _isPickingPhoto = false;

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
    _photoData = me?.photoData;
    _isEditing = me == null;
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

  void _loadProfile(Student? student) {
    _name.text = student?.name ?? '';
    _bio.text = student?.bio ?? '';
    _dept = student?.department ?? departments.first;
    _semester = student?.semester ?? semesters.first;
    _projectType = student?.projectType ?? projectTypes.first;
    _availability = student?.availability ?? availabilityOptions.first;
    _skills = {...?student?.skills};
    _interests = {...?student?.interests};
    _photoData = student?.photoData;
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto) return;
    setState(() => _isPickingPhoto = true);
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;

      final fileLength = await file.length();
      if (fileLength != null && fileLength > 20 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 20 MB.');
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw const FormatException('The selected image could not be read.');
      }

      final compressed = await compute<Uint8List, Uint8List>(
        _compressProfilePhoto,
        bytes,
      );
      if (!mounted) return;
      final photoData = base64Encode(compressed);
      if (_isEditing) {
        setState(() => _photoData = photoData);
      } else {
        final state = context.read<AppState>();
        final student = state.me;
        if (student != null) {
          await state.saveProfile(student.copyWith(photoData: photoData));
          if (mounted) _toast('Profile photo updated');
        }
      }
    } on MissingPluginException {
      if (mounted) {
        _toast(
          'Photo picker unavailable. Fully restart the app and try again.',
        );
      }
    } on UnimplementedError {
      if (mounted) {
        _toast(
          'Photo picker unavailable. Fully restart the app and try again.',
        );
      }
    } on Exception catch (error) {
      if (mounted) _toast('Could not select photo: $error');
    } on Error catch (error) {
      if (mounted) _toast('Could not process photo: $error');
    } finally {
      if (mounted) setState(() => _isPickingPhoto = false);
    }
  }

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
      photoData: _photoData,
    );
    await context.read<AppState>().saveProfile(profile);
    if (!mounted) return;
    setState(() => _isEditing = false);
    _toast('Profile saved');
  }

  int _currentCompletion() {
    return [
      _photoData?.isNotEmpty == true,
      _name.text.trim().isNotEmpty,
      _dept.isNotEmpty,
      _semester > 0,
      _skills.isNotEmpty,
      _interests.isNotEmpty,
      _projectType.isNotEmpty,
      _availability.isNotEmpty,
      _bio.text.trim().isNotEmpty,
    ].where((complete) => complete).length;
  }

  int _savedCompletion(Student student) {
    return [
      student.photoData?.isNotEmpty == true,
      student.name.trim().isNotEmpty,
      student.department.isNotEmpty,
      student.semester > 0,
      student.skills.isNotEmpty,
      student.interests.isNotEmpty,
      student.projectType.isNotEmpty,
      student.availability.isNotEmpty,
      student.bio.trim().isNotEmpty,
    ].where((complete) => complete).length;
  }

  void _openPreview(Student student) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePreviewScreen(student: student),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AppState>().me;
    final hasProfile = me != null;

    if (hasProfile && !_isEditing) {
      return _profileOverview(me);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(hasProfile ? 'Edit profile' : 'Create Profile'),
        actions: [
          if (hasProfile)
            TextButton(
              key: const ValueKey('profile-cancel-edit'),
              onPressed: () => setState(() {
                _loadProfile(me);
                _isEditing = false;
              }),
              child: const Text('Cancel'),
            ),
        ],
      ),
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
            _photoEditor(),
            const SizedBox(height: AppSpacing.md),
            _completenessCard(_currentCompletion()),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
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
                    onChanged: (v) {
                      if (v != null) setState(() => _dept = v);
                    },
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
                    onChanged: (v) {
                      if (v != null) setState(() => _semester = v);
                    },
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
              onChanged: (v) {
                if (v != null) setState(() => _projectType = v);
              },
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
              onChanged: (v) {
                if (v != null) setState(() => _availability = v);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _multiSelectDropdown(
              'Skills',
              allSkills,
              _skills,
              Icons.build_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _multiSelectDropdown(
              'Interests',
              allInterests,
              _interests,
              Icons.favorite_border,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bio,
              maxLines: 3,
              maxLength: 150,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Short bio',
                prefixIcon: Icon(Icons.edit_note_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(hasProfile ? 'Save changes' : 'Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileOverview(Student student) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Row(
                    children: [
                      ProfileAvatar(
                        name: student.name,
                        photoData: student.photoData,
                        radius: 38,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              '${student.department} • Semester ${student.semester}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('profile-overview-photo-picker'),
                      onPressed: _isPickingPhoto ? null : _pickPhoto,
                      icon: _isPickingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_outlined),
                      label: Text(
                        _isPickingPhoto
                            ? 'Opening photo picker...'
                            : student.photoData == null
                            ? 'Add profile photo'
                            : 'Change photo',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _completenessCard(_savedCompletion(student)),
          const SizedBox(height: AppSpacing.md),
          _infoCard(
            title: 'Project preferences',
            icon: Icons.category_outlined,
            values: [student.projectType, student.availability],
          ),
          const SizedBox(height: AppSpacing.md),
          _chipCard('Skills', student.skills, Icons.build_outlined),
          const SizedBox(height: AppSpacing.md),
          _chipCard('Interests', student.interests, Icons.favorite_border),
          if (student.bio.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(student.bio),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('profile-preview-button'),
                  onPressed: () => _openPreview(student),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('profile-edit-button'),
                  onPressed: () => setState(() {
                    _loadProfile(student);
                    _isEditing = true;
                  }),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoEditor() {
    return Column(
      children: [
        Stack(
          children: [
            ProfileAvatar(name: _name.text, photoData: _photoData, radius: 48),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextButton(
          key: const ValueKey('profile-photo-picker'),
          onPressed: _isPickingPhoto ? null : _pickPhoto,
          child: _isPickingPhoto
              ? const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text('Opening photo picker...'),
                  ],
                )
              : Text(_photoData == null ? 'Add profile photo' : 'Change photo'),
        ),
        if (_photoData != null)
          TextButton(
            onPressed: () => setState(() => _photoData = null),
            child: const Text('Remove photo'),
          ),
      ],
    );
  }

  Widget _completenessCard(int completed) {
    final percent = completed / _completionFields;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profile completeness',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '$completed of $_completionFields profile details complete',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<String> values,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(values.join(' • ')),
          ],
        ),
      ),
    );
  }

  Widget _chipCard(String title, List<String> items, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              Text('No $title added yet.')
            else
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [for (final item in items) SkillChip(item)],
              ),
          ],
        ),
      ),
    );
  }

  Widget _multiSelectDropdown(
    String title,
    List<String> options,
    Set<String> selected,
    IconData icon,
  ) {
    final key = title.toLowerCase();
    return PopupMenuButton<String>(
      key: ValueKey('$key-dropdown'),
      tooltip: 'Select $title',
      onSelected: (option) => setState(() {
        if (!selected.add(option)) selected.remove(option);
      }),
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem<String>(
            key: ValueKey('$key-option-$option'),
            value: option,
            child: Row(
              children: [
                Icon(
                  selected.contains(option)
                      ? Icons.check_box
                      : Icons.check_box_outline_blank,
                  size: 20,
                  color: selected.contains(option)
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.muted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(option)),
              ],
            ),
          ),
      ],
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          selected.isEmpty ? 'Choose one or more' : selected.join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected.isEmpty ? AppColors.muted : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

Uint8List _compressProfilePhoto(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw const FormatException('The selected file is not a supported image.');
  }

  final oriented = img.bakeOrientation(decoded);
  final longestSide = math.max(oriented.width, oriented.height);
  final resized = longestSide <= 512
      ? oriented
      : oriented.width >= oriented.height
      ? img.copyResize(oriented, width: 512)
      : img.copyResize(oriented, height: 512);
  return Uint8List.fromList(img.encodeJpg(resized, quality: 78));
}
