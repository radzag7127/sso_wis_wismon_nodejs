import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/auth/auth_state.dart';
import 'bloc/payment/payment_bloc.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/wismon_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Global RouteObserver for managing route lifecycle events
  static final RouteObserver<PageRoute> routeObserver =
      RouteObserver<PageRoute>();

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(apiService: apiService)..add(const CheckAuthStatus()),
        ),
        BlocProvider<PaymentBloc>(
          create: (context) => PaymentBloc(apiService: apiService),
        ),
      ],
      child: MaterialApp(
        title: 'Wismon Keuangan',
        debugShowCheckedModeBanner: false,
        // Add the route observer to enable RouteAware functionality
        navigatorObservers: [MyApp.routeObserver],
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Simplified approach - use direct widget switching
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthInitial || state is AuthLoading) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              );
            }

            if (state is AuthAuthenticated) {
              return const HomePage();
            }

            if (state is AuthError) {
              // Return to login with error message
              return LoginPageWithError(errorMessage: state.message);
            }

            return const LoginPage();
          },
        ),
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/wismon': (context) => const WismonPage(),
        },
      ),
    );
  }
}

// Wrapper to show login page with error message
class LoginPageWithError extends StatefulWidget {
  final String errorMessage;

  const LoginPageWithError({super.key, required this.errorMessage});

  @override
  State<LoginPageWithError> createState() => _LoginPageWithErrorState();
}

class _LoginPageWithErrorState extends State<LoginPageWithError> {
  @override
  void initState() {
    super.initState();
    // Show error message after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}
