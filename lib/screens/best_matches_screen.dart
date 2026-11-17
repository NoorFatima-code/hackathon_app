import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/student_card.dart';
import '../widgets/student_detail_sheet.dart';

class BestMatchesScreen extends StatelessWidget {
  const BestMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final me = state.me;

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Best Matches')),
        body: const EmptyState(
          icon: Icons.person_add_alt_1_outlined,
          title: 'Create your profile first',
          subtitle: 'We need your skills and interests to find matches.',
        ),
      );
    }

    final results = MatchService.bestMatches(me, state.students, state.team);
    final usingTeam =
        state.team != null &&
        (state.team!.rolesNeeded.isNotEmpty ||
            state.team!.skillsNeeded.isNotEmpty);

    return Scaffold(
      appBar: AppBar(title: const Text('Best Matches')),
      body: results.isEmpty
          ? const EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches yet',
              subtitle: 'Add more skills or interests to your profile.',
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          usingTeam
                              ? 'Sorted by match with your profile and team roles.'
                              : 'Sorted by match with your profile.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final result = results[i];
                          return StudentCard(
                            student: result.student,
                            onTap: () => showStudentDetailSheet(
                              context,
                              student: result.student,
                              score: result.score,
                              reasons: result.reasons,
                              highlightSkills: result.matchedSkills,
                            ),
                            score: result.score,
                            reasons: result.reasons,
                            highlightSkills: result.matchedSkills,
                          );
                        }, childCount: results.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: AppSpacing.md,
                          mainAxisSpacing: AppSpacing.md,
                          mainAxisExtent: StudentCard.gridExtent,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
