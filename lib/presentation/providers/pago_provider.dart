import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/api_models.dart';
import '../../data/services/api_service.dart';

class PagoProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<CatalogoProductoModel> _catalogo = [];
  List<TransaccionHistorialModel> _historial = [];
  List<CuentaModel> _cuentas = [];
  CuentaModel? _cuentaSeleccionada;

  bool _isLoading = false;
  bool _isProcessingPago = false; // Flag para prevención estricta de doble clic
  String? _errorMessage;
  TicketModel? _currentTicket;

  List<CatalogoProductoModel> get catalogo => _catalogo;
  List<TransaccionHistorialModel> get historial => _historial;
  List<CuentaModel> get cuentas => _cuentas;
  CuentaModel? get cuentaSeleccionada => _cuentaSeleccionada;
  bool get isLoading => _isLoading;
  bool get isProcessingPago => _isProcessingPago;
  String? get errorMessage => _errorMessage;
  TicketModel? get currentTicket => _currentTicket;

  void seleccionarCuenta(CuentaModel? cuenta) {
    _cuentaSeleccionada = cuenta;
    notifyListeners();
  }

  Future<void> cargarCuentas() async {
    try {
      _cuentas = await _apiService.getMisCuentas();
      if (_cuentas.isNotEmpty) {
        if (_cuentaSeleccionada == null) {
          _cuentaSeleccionada = _cuentas.first;
        } else {
          final actualizada = _cuentas.firstWhere(
            (c) => c.numeroCuenta == _cuentaSeleccionada!.numeroCuenta,
            orElse: () => _cuentas.first,
          );
          _cuentaSeleccionada = actualizada;
        }
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> actualizarEstatusCuenta(String numeroCuenta, String nuevoEstatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.cambiarEstatusCuenta(numeroCuenta, nuevoEstatus);
      await cargarCuentas();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'No se pudo actualizar el estatus de la cuenta.';
      notifyListeners();
      return false;
    }
  }

  Future<void> cargarCatalogo() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _catalogo = await _apiService.getCatalogo();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar catálogo de servicios.';
      notifyListeners();
    }
  }

  Future<TransaccionResponseModel?> ejecutarPago({
    required String numeroCuenta,
    required String idProducto,
    required String idServicio,
    required String telefonoOreferencia,
    required double monto,
    required String passwordOPin,
  }) async {
    // Prevención de doble clic en UI
    if (_isProcessingPago) return null;

    _isProcessingPago = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.pagarServicio(
        numeroCuenta: numeroCuenta,
        idProducto: idProducto,
        idServicio: idServicio,
        telefonoOreferencia: telefonoOreferencia,
        monto: monto,
        passwordOPin: passwordOPin,
      );

      // ACTUALIZACION DE SALDO EN TIEMPO REAL:
      // 1. Si la respuesta trae el nuevoSaldo, lo aplicamos de inmediato en la cuenta en memoria
      if (_cuentaSeleccionada != null && res.nuevoSaldo != null && res.nuevoSaldo! >= 0) {
        _cuentaSeleccionada = CuentaModel(
          id: _cuentaSeleccionada!.id,
          numeroCuenta: _cuentaSeleccionada!.numeroCuenta,
          saldo: res.nuevoSaldo!,
          estatus: _cuentaSeleccionada!.estatus,
        );
        // Actualizamos también en la lista general de cuentas
        final idx = _cuentas.indexWhere((c) => c.numeroCuenta == numeroCuenta);
        if (idx != -1) {
          _cuentas[idx] = _cuentaSeleccionada!;
        }
      }

      // 2. Refrescamos historial y cuentas en segundo plano con el servidor
      cargarHistorial();
      cargarCuentas();

      _isProcessingPago = false;
      notifyListeners();
      return res;
    } catch (e) {
      _isProcessingPago = false;
      int? statusCode;
      String rawMsg = '';
      if (e is DioException) {
        statusCode = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['mensaje'] != null) {
          rawMsg = data['mensaje'].toString();
        }
      }
      if (statusCode == 409) {
        cargarHistorial();
        cargarCuentas();
      }
      _errorMessage = _traducirErrorPago(statusCode, rawMsg);
      notifyListeners();
      return null;
    }
  }

  String _traducirErrorPago(int? statusCode, String rawMsg) {
    final lower = rawMsg.toLowerCase();
    if (statusCode == 409 || lower.contains('identica') || lower.contains('duplicad')) {
      return 'Ya se registró un pago igual hace unos segundos. Por tu seguridad bloqueamos el segundo cargo; revisa tus movimientos o espera un minuto para repetirlo.';
    }
    if (lower.contains('saldo insuficiente')) {
      return 'Saldo insuficiente en tu cuenta para cubrir el monto de este pago.';
    }
    if (lower.contains('inactiva') || lower.contains('bloqueada') || lower.contains('cancelada')) {
      return 'Tu cuenta no se encuentra activa. Actívala para poder realizar pagos.';
    }
    if (lower.contains('pin') || lower.contains('contraseña') || statusCode == 401) {
      return 'El PIN transaccional es incorrecto. Verifica e intenta de nuevo.';
    }
    if (statusCode == 503 || lower.contains('proveedor no recibio')) {
      return 'El proveedor del servicio no respondió a tiempo. No se aplicó ningún cargo a tu saldo.';
    }
    if (rawMsg.isNotEmpty) {
      return rawMsg;
    }
    return 'No fue posible completar el pago. Verifica tu conexión e intenta nuevamente.';
  }

  Future<void> cargarHistorial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _historial = await _apiService.getHistorial();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Error al cargar historial de pagos.';
      notifyListeners();
    }
  }

  Future<TicketModel?> obtenerTicket(int folio) async {
    _isLoading = true;
    _errorMessage = null;
    _currentTicket = null;
    notifyListeners();

    try {
      final ticket = await _apiService.getTicket(folio);
      _currentTicket = ticket;
      _isLoading = false;
      notifyListeners();
      return ticket;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'No se pudo obtener el ticket del folio $folio.';
      notifyListeners();
      return null;
    }
  }
}
