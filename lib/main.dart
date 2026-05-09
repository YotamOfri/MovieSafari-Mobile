import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/home/screens/home_page.dart';
import 'package:flutter_app/features/search/screens/search_page.dart';
import 'package:flutter_app/features/profile/screens/profile_page.dart';
import 'package:flutter_app/features/bookmarks/screens/bookmarks_page.dart';
import 'package:flutter_app/features/shell/screens/app_shell.dart';
import 'package:flutter_app/features/details/screens/details_page.dart';
import 'package:flutter_app/features/details/screens/player_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1014),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: HunterTrackerApp()));
}

// This is your "Router Configuration" - Just like react-router-dom
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. A Top-Level Route (No Navbar here)
    GoRoute(
      path: '/details/:type/:id',
      pageBuilder: (context, state) {
        final type = state.pathParameters['type']!;
        final id = int.parse(state.pathParameters['id']!);
        return CustomTransitionPage(
          key: state.pageKey,
          child: DetailsPage(type: type, id: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 0.1), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/player/:type/:id',
      pageBuilder: (context, state) {
        final type = state.pathParameters['type']!;
        final id = int.parse(state.pathParameters['id']!);
        final season =
            int.tryParse(state.uri.queryParameters['season'] ?? '1') ?? 1;
        final episode =
            int.tryParse(state.uri.queryParameters['episode'] ?? '1') ?? 1;
        return CustomTransitionPage(
          key: state.pageKey,
          child: PlayerPage(
              type: type, id: id, season: season, episode: episode),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),

    // 2. A ShellRoute (This provides the "Layout" or "Wrapper")
    ShellRoute(
      builder: (context, state, child) {
        return AppShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomePage()),
        ),
        GoRoute(
          path: '/search',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SearchPage()),
        ),
        GoRoute(
          path: '/bookmarks',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: BookmarksPage()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfilePage()),
        ),
      ],
    ),
  ],
);

class HunterTrackerApp extends StatelessWidget {
  const HunterTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Streaming App',
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return Container(color: const Color(0xFF0F1014), child: child!);
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        canvasColor: const Color(0xFF0F1014),
        scaffoldBackgroundColor: const Color(0xFF0F1014),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF0F1014), // Unified with background
          surfaceVariant: Color(0xFF0F1014),
        ),
        useMaterial3: true,
      ),
    );
  }
}
