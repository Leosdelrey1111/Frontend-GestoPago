import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../storage/session_storage.dart';

class SessionExpiredEvent {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void onSessionInvalidated(String message) {
    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
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
    if (status == 401 || status == 403) {
      await SessionStorage.clearSession();
      SessionExpiredEvent.onSessionInvalidated('Sesin finalizada. Inicia sesin nuevamente.');
    }
    return handler.next(err);
  }
}
