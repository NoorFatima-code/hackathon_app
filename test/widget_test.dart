import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hackathon_app/main.dart';
import 'package:hackathon_app/providers/app_state.dart';
import 'package:hackathon_app/screens/home_shell.dart';
import 'package:hackathon_app/theme/app_theme.dart';
import 'package:hackathon_app/widgets/student_card.dart';
import 'package:hackathon_app/data/sample_data.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    expect(find.text('Request sent to Ayesha Khan.'), findsOneWidget);
  });
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
