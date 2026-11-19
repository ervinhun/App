import 'package:app/core/api/generated/export.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/sync/connectivity.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/features/food/data/expiry_defaults_controller.dart';
import 'package:app/features/food/data/product_catalog_api.dart';
import 'package:app/features/food/domain/expiry_defaults.dart';
import 'package:app/features/food/domain/food_item.dart';
import 'package:app/features/food/domain/product_type.dart';
import 'package:app/features/fridges/data/fridges_api.dart';
import 'package:app/features/fridges/data/fridges_cache.dart';
import 'package:app/features/fridges/domain/fridge.dart';
import 'package:app/features/fridges/presentation/activity_log_screen.dart';
import 'package:app/features/fridges/presentation/alert_settings_screen.dart';
import 'package:app/features/fridges/presentation/expiry_defaults_screen.dart';
import 'package:app/features/fridges/presentation/management_screen.dart';
import 'package:app/features/fridges/presentation/widgets/management_widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../auth/fakes.dart';
import '../food/product_types_test.dart' show eggs, milk;
import 'fakes.dart';

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);

  final UserDto? _user;

  @override
  Future<UserDto?> build() async => _user;
}

void main() {
  late FakeFridgesApi api;
  late FakeFridgesCache cache;
  late FakeExpiryDefaultsStorage expiryDefaults;

  Future<void> pumpManagement(
    WidgetTester tester, {
    String at = Routes.management,
    bool online = true,
    UserDto? user = anna,
  }) async {
    tester.view.physicalSize = const Size(430, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(
          path: Routes.home,
          builder: (_, _) => const Scaffold(body: Text('My food')),
        ),
        GoRoute(
          path: Routes.management,
          builder: (_, _) => const ManagementScreen(),
          routes: [
            GoRoute(
              path: 'expiry-defaults',
              builder: (_, _) => const ExpiryDefaultsScreen(),
            ),
            GoRoute(
              path: 'alerts',
              builder: (_, _) => const AlertSettingsScreen(),
            ),
            GoRoute(
              path: 'activity',
              builder: (_, _) => const ActivityLogScreen(),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          authControllerProvider.overrideWith(() => _FakeAuth(user)),
          guestStorageProvider.overrideWithValue(
            FakeGuestStorage(user == null),
          ),
          fridgesApiProvider.overrideWithValue(api),
          fridgesCacheProvider.overrideWithValue(cache),
          networkAvailableProvider.overrideWith((ref) => Stream.value(online)),
          expiryDefaultsStorageProvider.overrideWithValue(expiryDefaults),
          productTypesProvider.overrideWith(
            (ref) => Stream.value(const <ProductType>[milk, eggs]),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    api = FakeFridgesApi();
    cache = FakeFridgesCache();
    expiryDefaults = FakeExpiryDefaultsStorage();
  });

  final android = TargetPlatformVariant.only(TargetPlatform.android);

  group('Management', () {
    testWidgets('the owner sees the invite code, the crew and every setting', (
      tester,
    ) async {
      await pumpManagement(tester);

      expect(find.text('Our fridge, our crew.'), findsOneWidget);
      expect(find.text('Home fridge'), findsWidgets);
      expect(find.text("2 people · You're the owner"), findsNothing);
      expect(find.textContaining("You're the owner"), findsOneWidget);
      expect(find.text('ABCD2345'), findsOneWidget);
      expect(find.text('2 of 15'), findsOneWidget);
      // The owner first, with what each may do.
      expect(find.text('Anna Berg · You'), findsOneWidget);
      expect(find.text('Add, remove & manage'), findsOneWidget);
      expect(find.text('Add only · No expiry'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Anna Berg · You')).dy,
        lessThan(tester.getTopLeft(find.text('Ben Okafor')).dy),
      );
      expect(find.text('Expiry defaults'), findsOneWidget);
      expect(find.text('Expiry alerts'), findsOneWidget);
      expect(find.text('Activity log'), findsOneWidget);
      expect(find.textContaining('7 & 2 days before'), findsOneWidget);
    }, variant: android);

    testWidgets('a member sees no invite code or activity log', (tester) async {
      api
        ..fridges = [fridge(owner: false)]
        ..crews = {
          'home': [
            const FridgeMember(
              userId: 'maya',
              displayName: 'Maya Patel',
              isOwner: true,
              canPut: true,
              canUse: true,
            ),
            annaMember(owner: false),
          ],
        };
      await pumpManagement(tester);

      expect(find.textContaining('Shared with you'), findsOneWidget);
      expect(find.text('Good food. Better shared.'), findsNothing);
      expect(find.text('Activity log'), findsNothing);
      expect(find.text('Expiry alerts'), findsOneWidget);

      // Their own row is how they leave.
      await tester.tap(find.text('Anna Berg · You'));
      await tester.pumpAndSettle();
      expect(find.text('Leave Home fridge?'), findsOneWidget);
      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();
      expect(api.calls, contains('remove ${anna.id}'));
    }, variant: android);

    testWidgets('the owner changes what a member may do', (tester) async {
      await pumpManagement(tester);

      await tester.tap(find.text('Ben Okafor'));
      await tester.pumpAndSettle();
      expect(find.text('What can they do?'), findsOneWidget);

      // "Use & remove food" on.
      await tester.tap(find.byType(Switch).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();

      expect(api.calls, contains('rights ben put=true use=true'));
      expect(find.text('Add & remove · No expiry'), findsOneWidget);
    }, variant: android);

    testWidgets('resetting the invite code asks first', (tester) async {
      await pumpManagement(tester);

      await tester.tap(find.text('Reset code'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(api.calls, contains('reset code home'));
      expect(find.text('NEWC0DE9'), findsOneWidget);
    }, variant: android);

    testWidgets(
      'offline in a shared fridge, says changes wait and blocks them',
      (tester) async {
        cache.lists[anna.id] = [fridge()];
        cache.memberLists['home'] = [annaMember(), ben];
        api.offline = true;
        await pumpManagement(tester, online: false);

        expect(
          find.textContaining('Others use this fridge too'),
          findsOneWidget,
        );

        await tester.tap(find.text('Ben Okafor'));
        await tester.pumpAndSettle();
        expect(find.text('What can they do?'), findsNothing);
        expect(find.textContaining('changes wait'), findsWidgets);
      },
      variant: android,
    );

    testWidgets('offline in a fridge only the user uses, it can be renamed', (
      tester,
    ) async {
      cache.lists[anna.id] = [fridge(members: 1)];
      cache.memberLists['home'] = [annaMember()];
      api.offline = true;
      await pumpManagement(tester, online: false);

      expect(
        find.textContaining('Nobody else uses this fridge'),
        findsOneWidget,
      );

      await tester.tap(find.textContaining('Just you'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cabin');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Cabin'), findsWidgets);
      expect(cache.pendingChanges['home']?.name, 'Cabin');
      expect(
        find.text("Saved on this phone. It syncs when you're back online."),
        findsOneWidget,
      );
    }, variant: android);

    testWidgets('a guest is asked to sign in to share', (tester) async {
      await pumpManagement(tester, user: null);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Sign in or create an account'), findsOneWidget);
      expect(find.text('Activity log'), findsNothing);
      expect(api.calls, isEmpty);
    }, variant: android);

    testWidgets('with no fridge, offers to create one', (tester) async {
      api.fridges = [];
      await pumpManagement(tester);

      await tester.tap(find.text('Create a fridge'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Flat');
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(api.calls, contains('create Flat'));
      expect(find.text('Flat'), findsWidgets);
    }, variant: android);

    testWidgets('on iOS, the fridge switcher is an action sheet', (
      tester,
    ) async {
      api.fridges = [fridge(), fridge(id: 'work', name: 'Work')];
      await pumpManagement(tester);

      await tester.tap(find.byType(FridgeSwitcherPill));
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();
      expect(find.text('Work'), findsWidgets);
      expect(cache.current, 'work');
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('opens each setting, and Back returns', (tester) async {
      await pumpManagement(tester);

      await tester.tap(find.text('Activity log'));
      await tester.pumpAndSettle();
      expect(find.text('A little housekeeping.'), findsOneWidget);
      expect(find.text('Home fridge · Anna Berg, owner'), findsOneWidget);

      await tester.tap(find.text('Back to management'));
      await tester.pumpAndSettle();
      expect(find.text('Our fridge, our crew.'), findsOneWidget);
    }, variant: android);
  });

  group('Expiry alerts', () {
    testWidgets('the owner moves the heads-up and saves', (tester) async {
      await pumpManagement(tester, at: Routes.alertSettings);

      expect(
        find.text('On · 7 days before & 2 days before · 16:00'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('More days').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save alerts'));
      await tester.pumpAndSettle();

      expect(api.alerts['home']?.warningDaysBefore, 8);
      expect(find.text('Alerts saved'), findsOneWidget);
    }, variant: android);

    testWidgets('ticking a member picks people by hand', (tester) async {
      await pumpManagement(tester, at: Routes.alertSettings);

      expect(find.text('2 selected'), findsOneWidget);
      await tester.tap(find.text('Ben Okafor'));
      await tester.pumpAndSettle();
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.text('Save alerts'));
      await tester.pumpAndSettle();
      expect(api.alerts['home']?.scope, RecipientsScope.custom);
      expect(api.alerts['home']?.recipientUserIds, {anna.id});
    }, variant: android);

    testWidgets('a member can look but not change them', (tester) async {
      api.fridges = [fridge(owner: false)];
      await pumpManagement(tester, at: Routes.alertSettings);

      expect(find.text('Only the owner can change these.'), findsOneWidget);
      expect(find.text('Save alerts'), findsNothing);
    }, variant: android);
  });

  group('Expiry defaults', () {
    testWidgets('a category rule is saved on the phone', (tester) async {
      await pumpManagement(tester, at: Routes.expiryDefaults);

      expect(find.text('Fridge rules'), findsOneWidget);
      // Dairy & Eggs: unopened, then once opened.
      await tester.enterText(find.byType(TextField).at(1), '3');
      // Builds the now enabled Save button, and the guard against leaving.
      await tester.pump();
      await tester.tap(find.text('Save defaults'));
      await tester.pumpAndSettle();

      expect(
        expiryDefaults.defaults.rule(StorageLocation.fridge, 'Dairy & Eggs'),
        const ExpiryRule(opened: 3),
      );
      expect(find.text('Expiry defaults saved'), findsOneWidget);
    }, variant: android);

    testWidgets('a category opens onto its types, which can be searched', (
      tester,
    ) async {
      await pumpManagement(tester, at: Routes.expiryDefaults);

      await tester.tap(find.text('Dairy & Eggs'));
      await tester.pumpAndSettle();
      expect(find.text('Dairy & Eggs subcategories'), findsOneWidget);
      expect(find.text('Milk'), findsOneWidget);
      expect(find.text('Eggs (in shell)'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Search subcategories'),
        'egg',
      );
      await tester.pumpAndSettle();
      expect(find.text('Milk'), findsNothing);
    }, variant: android);

    testWidgets('leaving with unsaved changes asks first', (tester) async {
      await pumpManagement(tester);
      await tester.tap(find.text('Expiry defaults'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), '3');
      // Builds the now enabled Save button, and the guard against leaving.
      await tester.pump();
      await tester.tap(find.text('Back to management'));
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Our fridge, our crew.'), findsOneWidget);
      expect(expiryDefaults.defaults.rules, isEmpty);
    }, variant: android);
  });

  group('Activity log', () {
    testWidgets("shows who added what, and what's gone", (tester) async {
      final now = DateTime.now();
      api.activityLog['home'] = [
        ActivityEntry(
          itemId: '1',
          name: 'Greek yogurt',
          category: 'Dairy & Eggs',
          amount: '1 tub',
          addedByUserId: 'ben',
          addedAt: DateTime(now.year, now.month, now.day, 9, 12),
          status: ItemStatus.active,
        ),
        ActivityEntry(
          itemId: '2',
          name: 'chicken breast',
          category: 'Poultry',
          amount: '400 g',
          addedByUserId: anna.id,
          addedAt: DateTime(now.year, now.month, now.day, 8, 45),
          status: ItemStatus.consumed,
        ),
      ];
      await pumpManagement(tester, at: Routes.activityLog);

      expect(find.text('Added Greek yogurt'), findsOneWidget);
      expect(find.text('Dairy & Eggs · 1 tub · Today · 09:12'), findsOneWidget);
      expect(find.text('Anna Berg · You'), findsOneWidget);
      expect(find.text('Used up since'), findsOneWidget);

      await tester.tap(find.text('Gone'));
      await tester.pumpAndSettle();
      expect(find.text('Added Greek yogurt'), findsNothing);
      expect(find.text('Added chicken breast'), findsOneWidget);
    }, variant: android);

    testWidgets('is the owner only', (tester) async {
      api.fridges = [fridge(owner: false)];
      await pumpManagement(tester, at: Routes.activityLog);

      expect(find.textContaining('Only the owner'), findsOneWidget);
      expect(api.calls, isNot(contains('activity home')));
    }, variant: android);
  });
}
