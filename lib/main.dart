import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/network/auth_interceptor.dart';
import 'core/theme/bank_theme.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/pago_provider.dart';
import 'presentation/screens/configurar_pin_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/registro_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PagoProvider()),
      ],
      child: MaterialApp(
        title: 'GestoPago Portal',
        debugShowCheckedModeBanner: false,
        navigatorKey: SessionExpiredEvent.navigatorKey,
        theme: BankTheme.themeData,
        home: const SplashOrRedirect(),
        routes: {
          '/login': (_) => const LoginScreen(),
          '/registro': (_) => const RegistroScreen(),
          '/home': (_) => const HomeScreen(),
          '/configurar-pin': (_) => const ConfigurarPinScreen(),
        },
      ),
    );
  }
}

class SplashOrRedirect extends StatelessWidget {
  const SplashOrRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    // Si está autenticado pero aún no tiene su PIN personal configurado (Onboarding completo)
    if (!auth.tienePinConfigurado) {
      return const ConfigurarPinScreen();
    }
    return const HomeScreen();
  }
}
