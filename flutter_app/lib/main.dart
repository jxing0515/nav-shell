import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'store/app_store.dart';
import 'store/store_scope.dart';
import 'home/home_page.dart';
import 'settings/settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.load();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
      overlays: SystemUiOverlay.values);
  runApp(NavApp(store: store));
}

class NavApp extends StatelessWidget {
  final AppStore store;
  const NavApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      notifier: store,
      child: MaterialApp(
        title: '导航',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
          scaffoldBackgroundColor: const Color(0xFFF5F5F7),
          fontFamily: 'HarmonyOS',
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A84FF), brightness: Brightness.dark),
          scaffoldBackgroundColor: const Color(0xFF1C1C1E),
          fontFamily: 'HarmonyOS',
        ),
        themeMode: ThemeMode.system,
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return HomePage(
      onOpenSettings: () => Navigator.of(context).push(
            MaterialPageRoute(
                maintainState: false,
                builder: (_) => const SettingsPage()),
          ),
    );
  }
}
