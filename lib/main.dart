import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/services/supabase_service.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/studio_provider.dart';
import 'core/providers/client_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/register_page.dart';
import 'features/auth/pages/register_studio_page.dart';
import 'features/auth/pages/loading_page.dart';
import 'features/client/pages/client_home_page.dart';
import 'features/studio/pages/studio_home_page.dart';
import 'features/splash/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Supabase
  await SupabaseService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => StudioProvider()),
        ChangeNotifierProvider(create: (_) => ClientProvider()),
      ],
      child: MaterialApp.router(
        title: 'StudioFlow',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: _router,
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/register-studio',
      builder: (context, state) => const RegisterStudioPage(),
    ),
    GoRoute(
      path: '/loading',
      builder: (context, state) => const LoadingPage(),
    ),
    GoRoute(
      path: '/client',
      builder: (context, state) => const ClientHomePage(),
    ),
    GoRoute(
      path: '/studio',
      builder: (context, state) => const StudioHomePage(),
    ),
  ],
);
