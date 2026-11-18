import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/session_storage.dart';
import '../models/api_models.dart';

class ApiService {
  final Dio _dio = ApiClient().dio;

  Future<LoginResponse> login(String correo, String contrasena) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {
        'correo': correo,
        'password': contrasena,
      },
    );
    return LoginResponse.fromJson(response.data);
  }

  Future<Map<String, dynamic>> reenviarOtp(String correo) async {
    final response = await _dio.post(
      '/auth/2fa/reenviar-otp',
      data: {
        'correo': correo,
        'otp': '000000',
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    required String apellidoPaterno,
    required String correo,
    required String telefono,
    required String password,
    required String pin,
    double depositoInicial = 1000.0,
  }) async {
    final response = await _dio.post(
      '/auth/registro',
      data: {
        'nombre': nombre,
        'apellidoPaterno': apellidoPaterno,
        'correo': correo,
        'telefono': telefono,
        'password': password,
        'pin': pin,
        'depositoInicial': depositoInicial,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<String> validarOtp(String correo, String preAuthToken, String codigoOtp) async {
    final response = await _dio.post(
      ApiConstants.validar2Fa,
      data: {
        'correo': correo,
        'otp': codigoOtp,
      },
    );
    final data = response.data is Map<String, dynamic> ? response.data : {};
    final token = (data['token'] ?? data['data']?['token']) as String;
    await SessionStorage.saveToken(token);
    await SessionStorage.saveUserEmail(correo);
    return token;
  }

  Future<List<CuentaModel>> getMisCuentas() async {
    final response = await _dio.get(ApiConstants.misCuentas);
    final dynamic data = response.data;
    if (data is List) {
      return data.map((item) => CuentaModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<CatalogoProductoModel>> getCatalogo() async {
    final response = await _dio.get(ApiConstants.catalogo);
    final dynamic data = response.data;
    if (data is List) {
      return data.map((item) => CatalogoProductoModel.fromJson(item)).toList();
    } else if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((item) => CatalogoProductoModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<TransaccionResponseModel> pagarServicio({
    required String numeroCuenta,
    required String idProducto,
    required String idServicio,
    required String telefonoOreferencia,
    required double monto,
    required String passwordOPin,
    String? claveIdempotencia,
  }) async {
    final response = await _dio.post(
      ApiConstants.pagar,
      data: {
        'numeroCuenta': numeroCuenta,
        'idProducto': idProducto,
        'idServicio': idServicio,
        'telefonoOreferencia': telefonoOreferencia,
        'monto': monto,
        'passwordOPin': passwordOPin,
        'claveIdempotencia': claveIdempotencia ?? const Uuid().v4(),
      },
    );
    return TransaccionResponseModel.fromJson(response.data);
  }

  Future<List<TransaccionHistorialModel>> getHistorial({
    int pagina = 0,
    int tamano = 20,
    String? numeroCuenta,
  }) async {
    if (numeroCuenta == null || numeroCuenta.isEmpty) {
      final cuentas = await getMisCuentas();
      if (cuentas.isNotEmpty) {
        numeroCuenta = cuentas.first.numeroCuenta;
      }
    }
    if (numeroCuenta == null || numeroCuenta.isEmpty) {
      return [];
    }
    final response = await _dio.post(
      ApiConstants.historial,
      data: {
        'numeroCuenta': numeroCuenta,
        'limite': tamano,
      },
    );
    final dynamic data = response.data;
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((item) => TransaccionHistorialModel.fromJson(item)).toList();
    } else if (data is List) {
      return data.map((item) => TransaccionHistorialModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<TicketModel> getTicket(int folio) async {
    final response = await _dio.get(ApiConstants.ticket(folio));
    return TicketModel.fromJson(response.data);
  }

  Future<void> actualizarPin(String nuevoPin) async {
    await _dio.post(
      '/auth/pin',
      data: {'pin': nuevoPin},
    );
  }

  Future<Map<String, dynamic>> verificarSesion() async {
    final response = await _dio.get('/auth/verificar-sesion');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<void> cambiarEstatusCuenta(String numeroCuenta, String estatus) async {
    await _dio.patch(
      '/cuentas/mis-cuentas/estatus',
      queryParameters: {
        'numeroCuenta': numeroCuenta,
        'estatus': estatus,
      },
    );
  }
}
