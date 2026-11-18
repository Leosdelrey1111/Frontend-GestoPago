class ApiConstants {
  // En emulador Android usar http://10.0.2.2:8080
  // En Flutter Web / Dispositivo local usar http://localhost:8080 o IP de red
  static const String baseUrl = 'http://localhost:8080';

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
