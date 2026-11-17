import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/sample_data.dart';
import '../models/student.dart';
import '../providers/app_state.dart';
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
  String _query = '';
  String? _dept;
  int? _semester;
  String? _skill;
  String? _projectType;

  int get _filterCount =>
      [_dept, _semester, _skill, _projectType].where((e) => e != null).length;

  void _clearFilters() => setState(() {
    _dept = null;
    _semester = null;
    _skill = null;
    _projectType = null;
    _query = '';
  });

  List<Student> _filtered(List<Student> all) {
    final q = _query.trim().toLowerCase();
    return all.where((s) {
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
  }

  void _openFilters() {
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
                    departments,
                    (v) => update(() => _dept = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<int>(
                    'Semester',
                    _semester,
                    semesters,
                    (v) => update(() => _semester = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<String>(
                    'Skill',
                    _skill,
                    allSkills,
                    (v) => update(() => _skill = v),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _drop<String>(
                    'Project type',
                    _projectType,
                    projectTypes,
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

  Widget _drop<T>(
    String label,
    T? value,
    List<T> items,
    ValueChanged<T?> onChanged,
  ) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
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
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: _filterCount > 0,
              label: Text('$_filterCount'),
              child: const Icon(Icons.filter_alt_outlined),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Search by name or skill',
                prefixIcon: Icon(Icons.search_outlined),
                isDense: true,
              ),
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
