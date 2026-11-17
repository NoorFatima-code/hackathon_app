import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/discover_filter_preset.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/student_card.dart';
import '../widgets/student_detail_sheet.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _storage = StorageService();
  final _searchController = TextEditingController();
  String _query = '';
  String? _dept;
  int? _semester;
  String? _skill;
  String? _projectType;
  DiscoverSortOrder _sortOrder = DiscoverSortOrder.name;
  List<DiscoverFilterPreset> _savedPresets = [];
  String? _presetError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedPresets());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _filterCount =>
      [_dept, _semester, _skill, _projectType].where((e) => e != null).length;

  void _clearFilters() {
    setState(() {
      _dept = null;
      _semester = null;
      _skill = null;
      _projectType = null;
      _query = '';
    });
    _searchController.clear();
  }

  List<Student> _filtered(List<Student> all) {
    final q = _query.trim().toLowerCase();
    final filtered = all.where((s) {
      if (q.isNotEmpty &&
          !s.name.toLowerCase().contains(q) &&
          !s.skills.any((k) => k.toLowerCase().contains(q))) {
        return false;
      }
      if (_dept != null && s.department != _dept) return false;
      if (_semester != null && s.semester != _semester) return false;
      if (_skill != null && !s.skills.contains(_skill)) return false;
      if (_projectType != null && s.projectType != _projectType) return false;
      return true;
    }).toList();

    switch (_sortOrder) {
      case DiscoverSortOrder.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case DiscoverSortOrder.department:
        filtered.sort((a, b) {
          final department = a.department.compareTo(b.department);
          return department != 0
              ? department
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      case DiscoverSortOrder.semester:
        filtered.sort((a, b) {
          final semester = a.semester.compareTo(b.semester);
          return semester != 0
              ? semester
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
    }

    return filtered;
  }

  void _openFilters() {
    final sortedDepartments = [...departments]..sort();
    final sortedSemesters = [...semesters]..sort();
    final sortedSkills = [...allSkills]..sort();
    final sortedProjectTypes = [...projectTypes]..sort();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          void update(VoidCallback f) {
            setState(f);
            setSheet(() {});
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_alt_outlined,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Filters',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<String>(
                    'Department',
                    _dept,
                    sortedDepartments,
                    Icons.school_outlined,
                    (v) => update(() => _dept = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<int>(
                    'Semester',
                    _semester,
                    sortedSemesters,
                    Icons.event_outlined,
                    (v) => update(() => _semester = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<String>(
                    'Skill',
                    _skill,
                    sortedSkills,
                    Icons.code_rounded,
                    (v) => update(() => _skill = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<String>(
                    'Project type',
                    _projectType,
                    sortedProjectTypes,
                    Icons.category_outlined,
                    (v) => update(() => _projectType = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _clearFilters();
                            setSheet(() {});
                          },
                          child: const Text('Clear'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadSavedPresets() async {
    try {
      final presets = await _storage.loadDiscoverFilterPresets();
      if (!mounted) return;
      setState(() {
        _savedPresets = presets
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
      });
    } on FormatException catch (_) {
      if (mounted) {
        setState(() => _presetError = 'Saved filters could not be read.');
      }
    } on PlatformException catch (_) {
      if (mounted) {
        setState(() => _presetError = 'Could not load saved filters.');
      }
    }
  }

  Future<String?> _askForPresetName() async {
    final formKey = GlobalKey<FormState>();
    String? name;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save filter set'),
        content: Form(
          key: formKey,
          child: TextFormField(
            key: const ValueKey('saved-filter-name'),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            maxLength: 32,
            decoration: const InputDecoration(labelText: 'Preset name'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a name' : null,
            onSaved: (value) => name = value?.trim(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.pop(dialogContext, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCurrentFilters() async {
    final name = await _askForPresetName();
    if (name == null || !mounted) return;

    final preset = DiscoverFilterPreset(
      name: name,
      query: _query,
      department: _dept,
      semester: _semester,
      skill: _skill,
      projectType: _projectType,
      sortOrder: _sortOrder,
    );
    final presets = [..._savedPresets];
    final existingIndex = presets.indexWhere(
      (saved) => saved.name.toLowerCase() == name.toLowerCase(),
    );
    if (existingIndex < 0) {
      presets.add(preset);
    } else {
      presets[existingIndex] = preset;
    }
    presets.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    await _persistPresets(presets, 'Filter set saved.');
  }

  Future<void> _deleteSavedPreset(DiscoverFilterPreset preset) async {
    final presets = _savedPresets
        .where((saved) => saved.name.toLowerCase() != preset.name.toLowerCase())
        .toList();
    await _persistPresets(presets, 'Saved filter removed.');
  }

  Future<void> _persistPresets(
    List<DiscoverFilterPreset> presets,
    String successMessage,
  ) async {
    try {
      await _storage.saveDiscoverFilterPresets(presets);
    } on PlatformException catch (_) {
      _showPresetMessage('Could not save filters. Please try again.');
      return;
    } on StateError catch (_) {
      _showPresetMessage('Could not save filters. Please try again.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _savedPresets = presets;
      _presetError = null;
    });
    _showPresetMessage(successMessage);
  }

  void _applyPreset(DiscoverFilterPreset preset) {
    setState(() {
      _query = preset.query;
      _dept = preset.department;
      _semester = preset.semester;
      _skill = preset.skill;
      _projectType = preset.projectType;
      _sortOrder = preset.sortOrder;
      _searchController.text = preset.query;
    });
  }

  bool _isPresetActive(DiscoverFilterPreset preset) =>
      _query == preset.query &&
      _dept == preset.department &&
      _semester == preset.semester &&
      _skill == preset.skill &&
      _projectType == preset.projectType &&
      _sortOrder == preset.sortOrder;

  void _showPresetMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _drop<T>(
    String label,
    T? value,
    List<T> items,
    IconData icon,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        const DropdownMenuItem(value: null, child: Text('All')),
        for (final i in items) DropdownMenuItem(value: i, child: Text('$i')),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final students = _filtered(context.watch<AppState>().students);

    return Scaffold(
      appBar: AppBar(title: const Text('Discover')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: TextField(
                    key: const ValueKey('discover-search'),
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      hintText: 'Search by name or skill',
                      prefixIcon: Icon(Icons.search_outlined),
                      isDense: true,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          key: const ValueKey('discover-filter-button'),
                          onPressed: _openFilters,
                          icon: Badge(
                            isLabelVisible: _filterCount > 0,
                            label: Text('$_filterCount'),
                            child: const Icon(Icons.filter_alt_outlined),
                          ),
                          label: const Text('Filters'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<DiscoverSortOrder>(
                          key: const ValueKey('discover-sort'),
                          initialValue: _sortOrder,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Sort by',
                            isDense: true,
                          ),
                          items: [
                            for (final order in DiscoverSortOrder.values)
                              DropdownMenuItem(
                                value: order,
                                child: Text(order.label),
                              ),
                          ],
                          onChanged: (order) {
                            if (order != null) {
                              setState(() => _sortOrder = order);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Saved filters',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        key: const ValueKey('save-discover-filter'),
                        onPressed: _saveCurrentFilters,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: const Text('Save current'),
                      ),
                    ],
                  ),
                ),
                if (_presetError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _presetError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                if (_savedPresets.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _savedPresets.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final preset = _savedPresets[index];
                        return InputChip(
                          key: ValueKey('saved-filter-${preset.name}'),
                          avatar: const Icon(Icons.bookmark_outline, size: 18),
                          label: Text(preset.name),
                          selected: _isPresetActive(preset),
                          onPressed: () => _applyPreset(preset),
                          onDeleted: () => _deleteSavedPreset(preset),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: students.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No students found',
                    subtitle: 'Try a different search or clear filters.',
                    action: OutlinedButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 560
                          ? 2
                          : 1;
                      return GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          mainAxisExtent: StudentCard.gridExtent,
                        ),
                        itemCount: students.length,
                        itemBuilder: (_, i) => StudentCard(
                          student: students[i],
                          onTap: () => showStudentDetailSheet(
                            context,
                            student: students[i],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
