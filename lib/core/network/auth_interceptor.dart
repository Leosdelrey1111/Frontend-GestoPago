import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../storage/session_storage.dart';
import '../widgets/bank_toast.dart';

class SessionExpiredEvent {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void onSessionInvalidated(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      BankToast.mostrar(
        context,
        titulo: 'Sesión Expirada',
        mensaje: message,
        tipo: ToastTipo.advertencia,
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final deviceId = await SessionStorage.getDeviceId();
    options.headers['X-Device-Id'] = deviceId;

    final token = await SessionStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer ' + token;
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;
    // Solo expira la sesión si la petición viajó con sesión y no es un fallo de PIN/autorización en el pago ni login/2fa.
    final llevabaSesion = err.requestOptions.headers.containsKey('Authorization');
    final esOperacionConPin = path.contains('/pagar');

    if ((status == 401 || status == 403) && llevabaSesion && !esOperacionConPin) {
      await SessionStorage.clearSession();
      SessionExpiredEvent.onSessionInvalidated('Sesión finalizada. Inicia sesión nuevamente.');
    }
    return handler.next(err);
  }
}
