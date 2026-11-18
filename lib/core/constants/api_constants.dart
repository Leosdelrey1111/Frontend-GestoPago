class ApiConstants {
  // En desarrollo local usa http://localhost:8080; en producción pasar:
  // --dart-define=API_URL=https://tu-backend.up.railway.app
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080',
  );

  // Auth & 2FA
  static const String login = '/auth/login';
  static const String validar2Fa = '/auth/2fa/validar';

  // Cuentas del cliente
  static const String misCuentas = '/cuentas/mis-cuentas';

  // Catalogo
  static const String catalogo = '/gestopago/catalogo';

  // Transacciones
  static const String pagar = '/transacciones/pagar';
  static const String historial = '/transacciones/historial';
  static String ticket(int folio) => '/transacciones/$folio/ticket';
}
