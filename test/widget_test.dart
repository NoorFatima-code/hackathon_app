import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_app/main.dart';
import 'package:hackathon_app/providers/app_state.dart';
import 'package:hackathon_app/screens/home_shell.dart';
import 'package:hackathon_app/screens/my_team_screen.dart';
import 'package:hackathon_app/models/team.dart';
import 'package:hackathon_app/models/team_chat_message.dart';
import 'package:hackathon_app/models/team_request.dart';
import 'package:hackathon_app/models/student.dart';
import 'package:hackathon_app/services/match_service.dart';
import 'package:hackathon_app/screens/request_screen.dart';
import 'package:hackathon_app/screens/team_chat_screen.dart';
import 'package:hackathon_app/services/storage_service.dart';
import 'package:hackathon_app/theme/app_theme.dart';
import 'package:hackathon_app/widgets/student_card.dart';
import 'package:hackathon_app/data/sample_data.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hackathon_app/screens/discover_screen.dart';

void main() {
  test('migrates legacy team needs to the skills field', () {
    final team = Team.fromJson({
      'title': 'Legacy team',
      'projectType': 'Semester Project',
      'rolesNeeded': ['Flutter', 'Dart'],
      'memberIds': ['me'],
    });

    expect(team.rolesNeeded, isEmpty);
    expect(team.skillsNeeded, ['Flutter', 'Dart']);
    expect(team.messages, isEmpty);
  });

  test('matches team skills without treating roles as skills', () {
    final me = sampleStudents[0];
    final candidate = sampleStudents[1];
    final roleOnlyTeam = Team(
      title: 'Web project',
      projectType: 'FYP',
      rolesNeeded: ['Backend Developer'],
      memberIds: ['me'],
    );
    final skillsTeam = Team(
      title: 'Web project',
      projectType: 'FYP',
      rolesNeeded: ['Backend Developer'],
      skillsNeeded: ['React'],
      memberIds: ['me'],
    );

    final roleOnlyResult = MatchService.score(me, candidate, roleOnlyTeam);
    final skillsResult = MatchService.score(me, candidate, skillsTeam);

    expect(
      roleOnlyResult.reasons.any(
        (reason) => reason.contains('your team needs'),
      ),
      isFalse,
    );
    expect(skillsResult.reasons, contains('Has React, which your team needs'));
  });

  testWidgets('opens profile setup without an auth gate', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..init(),
        child: const TeamUpApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to TeamUp'), findsNothing);
    expect(find.text('Create your account'), findsNothing);
    expect(find.text('Create Profile'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('shows left navigation rail on wide layouts', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final appState = AppState()..me = sampleStudents.first;
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
      ),
    );

    expect(find.byKey(const ValueKey('side-navigation')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pumpAndSettle();
    expect(_gridColumns(tester), 3);
    expect(_gridExtent(tester), StudentCard.gridExtent);
    expect(find.byType(StudentCard), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('side-nav-item-1')));
    await tester.pumpAndSettle();
    expect(_gridColumns(tester), 3);
    expect(_gridExtent(tester), StudentCard.gridExtent);
    expect(find.byKey(const ValueKey('side-nav-active')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student cards fit on compact layouts', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
      ),
    );

    await tester.tap(find.text('Discover'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(StudentCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('student card opens request form and sends message', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: MaterialApp(theme: AppTheme.light(), home: const HomeShell()),
      ),
    );

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Discover'),
      ),
    );
    await tester.pumpAndSettle();
    final selectedStudent = tester
        .widget<StudentCard>(find.byType(StudentCard).first)
        .student;
    await tester.tap(find.byType(StudentCard).first);
    await tester.pumpAndSettle();

    expect(find.text('Short message'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('request-message')),
      'Hi, I would like to join your project.',
    );
    await tester.ensureVisible(find.text('Send request'));
    await tester.tap(find.text('Send request'));
    await tester.pumpAndSettle();

    expect(appState.sent, hasLength(1));
    expect(
      appState.sent.single.message,
      'Hi, I would like to join your project.',
    );
    expect(
      find.text('Request sent to ${selectedStudent.name}.'),
      findsOneWidget,
    );
  });

  testWidgets('Discover sorts students by semester', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const DiscoverScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('discover-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semester').last);
    await tester.pumpAndSettle();

    final firstCard = tester.widget<StudentCard>(
      find.byType(StudentCard).first,
    );
    expect(firstCard.student.name, 'Bilal Ahmed');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Discover saves, applies, and reloads a named filter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});

    Widget discoverApp() => ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(theme: AppTheme.light(), home: const DiscoverScreen()),
    );

    await tester.pumpWidget(discoverApp());
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('discover-search')),
      'Ayesha',
    );
    await tester.tap(find.byKey(const ValueKey('save-discover-filter')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('saved-filter-name')),
      'Ayesha filter',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('saved-filter-Ayesha filter')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('discover-search')),
      'no matching student',
    );
    await tester.pumpAndSettle();
    expect(find.byType(StudentCard), findsNothing);

    await tester.tap(find.byKey(const ValueKey('saved-filter-Ayesha filter')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCard), findsOneWidget);
    expect(
      tester.widget<StudentCard>(find.byType(StudentCard)).student.name,
      'Ayesha Khan',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(discoverApp());
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('saved-filter-Ayesha filter')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('saved-filter-Ayesha filter')));
    await tester.pumpAndSettle();
    expect(find.byType(StudentCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('team creation keeps roles and skills separate', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => appState,
        child: MaterialApp(theme: AppTheme.light(), home: const MyTeamScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create team'));
    await tester.pumpAndSettle();

    expect(find.text('Roles needed'), findsOneWidget);
    expect(find.text('Skills needed'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('team-title')),
      'Campus Planner',
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('role-option-Frontend Developer')),
    );
    await tester.tap(
      find.byKey(const ValueKey('role-option-Frontend Developer')),
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('skill-option-Flutter')),
    );
    await tester.tap(find.byKey(const ValueKey('skill-option-Flutter')));
    await tester.ensureVisible(
      find.byKey(const ValueKey('submit-create-team')),
    );
    await tester.tap(find.byKey(const ValueKey('submit-create-team')));
    await tester.pumpAndSettle();

    expect(appState.team!.rolesNeeded, ['Frontend Developer']);
    expect(appState.team!.skillsNeeded, ['Flutter']);
    expect(find.text('Roles / skills needed'), findsNothing);
    expect(find.text('Skills needed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'accepting a request assigns roles shown on an editable member card',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final appState = AppState()
        ..me = const Student(
          id: meId,
          name: 'Team Owner',
          department: 'CS',
          semester: 6,
          skills: ['Flutter'],
          interests: ['Mobile Apps'],
          projectType: 'FYP',
          availability: 'Flexible',
        )
        ..team = const Team(
          title: 'Campus Planner',
          projectType: 'FYP',
          rolesNeeded: ['Backend Developer', 'QA / Test Engineer'],
          memberIds: [meId],
        )
        ..requests = [
          TeamRequest(
            id: 'request-1',
            student: sampleStudents[1],
            message: 'I would like to join.',
            direction: RequestDirection.received,
            status: RequestStatus.pending,
            createdAt: DateTime(2026, 11, 17),
          ),
        ];

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const RequestsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Received (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(find.text('Assign project roles'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('assign-role-Backend Developer')),
      );
      await tester.tap(
        find.byKey(const ValueKey('assign-role-Backend Developer')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('assign-role-Backend Developer')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(
        find.byKey(const ValueKey('assign-role-QA / Test Engineer')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('confirm-member-roles')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('confirm-member-roles')));
      await tester.pumpAndSettle();

      final memberId = sampleStudents[1].id;
      expect(appState.requests.single.status, RequestStatus.accepted);
      expect(appState.team!.memberIds, contains(memberId));
      expect(appState.team!.memberRoles[memberId], [
        'Backend Developer',
        'QA / Test Engineer',
      ]);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MyTeamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      final memberCard = find.byKey(ValueKey('team-member-$memberId'));
      await tester.ensureVisible(memberCard);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: memberCard,
          matching: find.text('Backend Developer'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: memberCard,
          matching: find.text('QA / Test Engineer'),
        ),
        findsOneWidget,
      );

      await tester.tap(memberCard);
      await tester.pumpAndSettle();
      expect(find.text('Assign project roles'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('assign-role-QA / Test Engineer')),
      );
      await tester.tap(find.byKey(const ValueKey('confirm-member-roles')));
      await tester.pumpAndSettle();

      expect(appState.team!.memberRoles[memberId], ['Backend Developer']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('team chat sends and persists messages', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final appState = AppState()
      ..me = const Student(
        id: meId,
        name: 'Team Owner',
        department: 'CS',
        semester: 6,
        skills: ['Flutter'],
        interests: ['Mobile Apps'],
        projectType: 'Semester Project',
        availability: 'Flexible',
      )
      ..team = const Team(
        title: 'Campus Planner',
        projectType: 'Semester Project',
        rolesNeeded: ['Mobile App Developer'],
        memberIds: [meId],
      );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(theme: AppTheme.light(), home: const MyTeamScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('team-chat-entry')));
    await tester.pumpAndSettle();

    expect(find.byType(TeamChatScreen), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('team-chat-composer')),
      'Build is ready for review.',
    );
    await tester.pump();
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('send-team-message')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const ValueKey('send-team-message')));
    await tester.pumpAndSettle();

    expect(find.text('Build is ready for review.'), findsOneWidget);
    expect(appState.team!.messages.single.senderName, 'Team Owner');
    final savedTeam = await StorageService().loadTeam();
    expect(savedTeam!.messages.single.text, 'Build is ready for review.');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'removing a partner confirms, clears roles, and keeps chat history',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final partner = sampleStudents[1];
      final appState = AppState()
        ..me = const Student(
          id: meId,
          name: 'Team Owner',
          department: 'CS',
          semester: 6,
          skills: ['Flutter'],
          interests: ['Mobile Apps'],
          projectType: 'FYP',
          availability: 'Flexible',
        )
        ..team = Team(
          title: 'Campus Planner',
          projectType: 'FYP',
          rolesNeeded: ['Backend Developer'],
          memberIds: [meId, partner.id],
          memberRoles: {
            partner.id: ['Backend Developer'],
          },
          messages: [
            TeamChatMessage(
              id: 'chat-1',
              senderId: partner.id,
              senderName: partner.name,
              text: 'I can take the backend work.',
              sentAt: DateTime(2026, 11, 17),
            ),
          ],
        );

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MyTeamScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      final removeButton = find.byKey(
        ValueKey('remove-team-member-${partner.id}'),
      );
      await tester.ensureVisible(removeButton);
      await tester.pumpAndSettle();
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
      expect(find.text('Remove team member?'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(appState.team!.memberIds, contains(partner.id));

      await tester.ensureVisible(removeButton);
      await tester.pumpAndSettle();
      await tester.tap(removeButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove partner'));
      await tester.pumpAndSettle();

      expect(appState.team!.memberIds, isNot(contains(partner.id)));
      expect(appState.team!.memberRoles.containsKey(partner.id), isFalse);
      expect(appState.team!.messages.single.senderId, partner.id);
      final savedTeam = await StorageService().loadTeam();
      expect(savedTeam!.memberIds, isNot(contains(partner.id)));
      expect(savedTeam.memberRoles.containsKey(partner.id), isFalse);
      expect(savedTeam.messages.single.text, 'I can take the backend work.');
      expect(tester.takeException(), isNull);
    },
  );
}

int _gridColumns(WidgetTester tester) {
  final gridDelegate = _gridDelegate(tester);
  return (gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
      .crossAxisCount;
}

double? _gridExtent(WidgetTester tester) =>
    (_gridDelegate(tester) as SliverGridDelegateWithFixedCrossAxisCount)
        .mainAxisExtent;

SliverGridDelegate _gridDelegate(WidgetTester tester) =>
    find.byType(GridView).evaluate().isNotEmpty
    ? tester.widget<GridView>(find.byType(GridView).first).gridDelegate
    : tester.widget<SliverGrid>(find.byType(SliverGrid).first).gridDelegate;
