class ApiConstants {
  // En producción apunta a la API desplegada en Railway por defecto
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://gesto-pago-production.up.railway.app',
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
