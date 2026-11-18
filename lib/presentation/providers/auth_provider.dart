import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../core/storage/session_storage.dart';
import '../../data/services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _preAuthToken;
  String? _tempEmail;
  String? _userEmail;
  String? _deviceId;
  String? _ultimoMensajeServidor;
  String? _otpAuthUrl;
  String? _totpSecret;
  String? _telefonoEnmascarado;
  String? _correoEnmascarado;
  bool _primerRegistro2FA = false;
  bool _isAuthenticated = false;
  bool _tienePinConfigurado = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get preAuthToken => _preAuthToken;
  String? get tempEmail => _tempEmail;
  String? get userEmail => _userEmail;
  String? get deviceId => _deviceId;
  String? get ultimoMensajeServidor => _ultimoMensajeServidor;
  String? get otpAuthUrl => _otpAuthUrl;
  String? get totpSecret => _totpSecret;
  String? get telefonoEnmascarado => _telefonoEnmascarado;
  String? get correoEnmascarado => _correoEnmascarado;
  bool get primerRegistro2FA => _primerRegistro2FA;
  bool get isAuthenticated => _isAuthenticated;
  bool get tienePinConfigurado => _tienePinConfigurado;

  AuthProvider() {
    _initSession();
  }

  Future<void> _initSession() async {
    _deviceId = await SessionStorage.getDeviceId();
    final token = await SessionStorage.getToken();
    _userEmail = await SessionStorage.getUserEmail();

    if (token != null && token.isNotEmpty) {
      try {
        final info = await _apiService.verificarSesion();
        _isAuthenticated = true;
        _tienePinConfigurado = info['tienePin'] == true;
      } catch (e) {
        await SessionStorage.clearSession();
        _isAuthenticated = false;
        _userEmail = null;
      }
    } else {
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<void> verificarSesionEnServidor() async {
    final token = await SessionStorage.getToken();
    if (token == null || token.isEmpty) return;

    try {
      final info = await _apiService.verificarSesion();
      _tienePinConfigurado = info['tienePin'] == true;
    } catch (e) {
      await SessionStorage.clearSession();
      _isAuthenticated = false;
      _userEmail = null;
      notifyListeners();
    }
  }

  Future<bool> iniciarSesion(String correo, String contrasena) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.login(correo, contrasena);
      _tempEmail = correo;
      _ultimoMensajeServidor = res.mensaje;
      _otpAuthUrl = res.otpAuthUrl;
      _totpSecret = res.totpSecret;
      _primerRegistro2FA = res.primerRegistro2FA;
      _telefonoEnmascarado = res.telefonoEnmascarado ?? '•••• 5678';
      _correoEnmascarado = res.correoEnmascarado ?? correo;

      if (res.requiere2FA) {
        _preAuthToken = res.preAuthToken;
        _isLoading = false;
        notifyListeners();
        return true;
      } else if (res.token != null) {
        await SessionStorage.saveToken(res.token!);
        await SessionStorage.saveUserEmail(correo);
        _userEmail = correo;
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return false;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _parseError(e, 'Credenciales inválidas. Verifique su correo y contraseña.');
      notifyListeners();
      return false;
    }
  }

  Future<bool> reenviarCodigoCorreo() async {
    if (_tempEmail == null || _preAuthToken == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.reenviarOtp(_tempEmail!, _preAuthToken!);
      if (res['correoEnmascarado'] != null) {
        _correoEnmascarado = res['correoEnmascarado'];
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = _mensajeDelServidor(e) ?? 'No fue posible enviar el código. Intenta nuevamente.';
      notifyListeners();
      return false;
    }
  }

  void limpiarError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// Mensaje corto y legible que el backend envía en errores de negocio (400/401), si existe.
  String? _mensajeDelServidor(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      final status = e.response?.statusCode;
      if (data is Map && data['mensaje'] is String && (status == 400 || status == 401)) {
        return data['mensaje'] as String;
      }
    }
    return null;
  }

  Future<bool> verificarOtp(String codigoOtp) async {
    if (_preAuthToken == null || _tempEmail == null) {
      _errorMessage = 'Sesión no válida. Inicie sesión nuevamente.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.validarOtp(_tempEmail!, _preAuthToken!, codigoOtp);
      _userEmail = _tempEmail;
      _isAuthenticated = true;
      _preAuthToken = null;

      try {
        final info = await _apiService.verificarSesion();
        _tienePinConfigurado = info['tienePin'] == true;
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Código de seguridad incorrecto o expirado.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cerrarSesion() async {
    await SessionStorage.clearSession();
    _isAuthenticated = false;
    _userEmail = null;
    _tempEmail = null;
    _preAuthToken = null;
    _tienePinConfigurado = false;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> configurarPin(String nuevoPin) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.actualizarPin(nuevoPin);
      _tienePinConfigurado = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'No se pudo registrar el PIN de seguridad.';
      notifyListeners();
      return false;
    }
  }

  String _parseError(dynamic e, String defaultMsg) {
    if (e is Exception) {
      final str = e.toString();
      if (str.contains('Credenciales inválidas')) {
        return 'Credenciales incorrectas. Verifique correo y contraseña.';
      }
      if (str.contains('inactivo')) {
        return 'La cuenta se encuentra inactiva. Contacte a su banco.';
      }
    }
    return defaultMsg;
  }
}
