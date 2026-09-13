import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_shell/home/home_page.dart';
import 'package:nav_shell/store/app_store.dart';
import 'package:nav_shell/store/store_scope.dart';

void main() {
  // Regression: HomePage used to call StoreScope.of(context) (an inherited
  // lookup) from initState, which trips a debug-only assert:
  // "dependOnInheritedWidgetOfExactType<StoreScope>() ... was called before
  // _HomePageState.initState() completed".
  testWidgets('HomePage mounts under StoreScope and listens to store changes',
      (tester) async {
    final store = AppStore();
    await tester.pumpWidget(StoreScope(
      notifier: store,
      child: MaterialApp(home: HomePage(onOpenSettings: () {})),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('请添加一个页面'), findsOneWidget);

    // notifyListeners -> _onStore (no persistence, so no plugin channels).
    store.setLoading(null);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
