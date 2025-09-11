import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart' as di;
import 'core/widgets/optimized_bloc_builder.dart';
import 'core/services/auth_navigation_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/main_navigation_page.dart';
import 'features/payment/presentation/bloc/payment_bloc.dart';
import 'features/dashboard/presentation/bloc/beranda_bloc.dart';
import 'features/dashboard/presentation/bloc/beranda_event.dart';
import 'core/services/api_service.dart';

// Cache the text theme to prevent repeated font loading
late final TextTheme _cachedTextTheme;
late final ThemeData _cachedThemeData;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Performance optimizations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Optimize memory usage
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Pre-cache fonts for better performance
  await _initializeTheme();

  await di.init();
  runApp(const MyApp());
}

Future<void> _initializeTheme() async {
  const String fontName = 'Plus Jakarta Sans';

  // Create a custom TextTheme using the local font
  _cachedTextTheme =
      const TextTheme(
        displayLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w800,
        ),
        displayMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(fontFamily: fontName, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(fontFamily: fontName, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          fontFamily: fontName,
          fontWeight: FontWeight.w400,
        ),
      ).apply(
        bodyColor: const Color(0xFF121212),
        displayColor: const Color(0xFF121212),
      );

  _cachedThemeData = ThemeData(
    primarySwatch: Colors.blue,
    textTheme: _cachedTextTheme,
    fontFamily: fontName, // Set the default font family
    visualDensity: VisualDensity.adaptivePlatformDensity,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF135EA2),
      brightness: Brightness.light,
    ),
    // Optimize app bar theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: Color(0xFF121212),
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    // Optimize scaffold theme
    scaffoldBackgroundColor: const Color(0xFFFBFBFB),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _memoryCleanupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadCriticalData();
  }

  void _preloadCriticalData() {
    // Defer non-critical data loading to prevent blocking main thread during startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a slight delay to ensure UI is fully rendered before starting data loading
      Future.delayed(const Duration(milliseconds: 100), () {
        try {
          // Only preload critical data that's immediately visible
          // Payment summary will be loaded on-demand when dashboard is accessed
          final berandaBloc = di.sl<BerandaBloc>();
          berandaBloc.add(const FetchBerandaDataEvent());
        } catch (e) {
          // Handle any initialization errors gracefully
          debugPrint('Error preloading critical data: $e');
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _memoryCleanupTimer?.cancel();
    // Clean up API service connections
    ApiService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        // Schedule cleanup instead of immediate clearing
        _scheduleMemoryCleanup();
        break;
      case AppLifecycleState.resumed:
        // Cancel cleanup if user returns quickly
        _cancelMemoryCleanup();
        break;
      case AppLifecycleState.detached:
        // App is being terminated, do selective cleanup
        _performSelectiveCleanup();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // No action needed for these states
        break;
    }
  }

  void _scheduleMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
    // Only clean after extended background time (5 minutes)
    _memoryCleanupTimer = Timer(const Duration(minutes: 5), () {
      _performSelectiveCleanup();
    });
  }

  void _cancelMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
  }

  void _performSelectiveCleanup() {
    // Only clear if memory pressure is high
    final imageCache = PaintingBinding.instance.imageCache;
    const int maxCacheSize = 50 * 1024 * 1024; // 50MB threshold

    if (imageCache.currentSizeBytes > maxCacheSize) {
      // Clear live images but keep cached ones for faster reload
      imageCache.clearLiveImages();
      // Only clear cache if still over threshold
      if (imageCache.currentSizeBytes > maxCacheSize) {
        imageCache.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<AuthBloc>()..add(const CheckAuthStatusEvent()),
          lazy: false, // Load immediately for auth - critical for app flow
        ),
        BlocProvider(
          create: (_) => di.sl<PaymentBloc>(),
          lazy: true, // Use lazy loading to defer initialization until actually needed
        ),
      ],
      child: MaterialApp(
        title: 'Wismon Keuangan',
        debugShowCheckedModeBanner: false, // Remove debug banner
        navigatorKey: AuthNavigationService.navigatorKey, // Add global navigator key
        // Performance optimizations
        builder: (context, child) {
          // Prevent text scaling beyond reasonable limits
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(
                MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
              ),
            ),
            child: child!,
          );
        },

        theme: _cachedThemeData,

        home: const AuthWrapper(),

        // Performance monitoring in debug mode
        showPerformanceOverlay: false, // Set to true only for debugging
        // Optimize route generation
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/login':
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const LoginPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 200),
              );
            case '/main':
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const MainNavigationPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                transitionDuration: const Duration(milliseconds: 200),
              );
            default:
              return null;
          }
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        // Listen to all auth state changes for navigation
        return previous.runtimeType != current.runtimeType;
      },
      listener: (context, state) {
        // Handle navigation on auth state changes
        if (state is AuthUnauthenticated || state is AuthError) {
          // Clear any existing routes and navigate to login
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        } else if (state is AuthAuthenticated) {
          // Navigate to main app
          Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
        }
      },
      child: OptimizedBlocBuilder<AuthBloc, AuthState>(
        debugName: 'AuthWrapper',
        buildWhen: (previous, current) {
          // Only rebuild when auth state actually changes
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            return const MainNavigationPage();
          }
          if (state is AuthUnauthenticated || state is AuthError) {
            return const LoginPage();
          }
          return const LoadingScreen();
        },
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo with Hero animation
              RepaintBoundary(
                child: Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135EA2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x20135EA2),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.school,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // App Title
              const Text(
                'Wismon Keuangan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF135EA2),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Student Payment System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 32),

              // Loading indicator with animation
              RepaintBoundary(
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF135EA2)),
                    strokeWidth: 2.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
