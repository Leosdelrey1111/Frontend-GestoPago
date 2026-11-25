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

  Future<Map<String, dynamic>> reenviarOtp(String correo, String preAuthToken) async {
    final response = await _dio.post(
      '/auth/2fa/reenviar-otp',
      data: {'correo': correo},
      options: Options(headers: {'X-Pre-Auth-Token': preAuthToken}),
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<bool> verificarCorreoDisponible(String correo) async {
    try {
      final response = await _dio.get(
        '/auth/verificar-correo',
        queryParameters: {'correo': correo.trim().toLowerCase()},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data['disponible'] == true;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<Map<String, dynamic>> registrarUsuario({
    required String nombre,
    String? segundoNombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String fechaNacimiento,
    required String curp,
    required String rfc,
    required String correo,
    required String telefono,
    required String calle,
    required String numeroExterior,
    String? numeroInterior,
    required String colonia,
    required String municipio,
    required String estado,
    required int codigoPostal,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/registro',
      data: {
        'nombre': nombre,
        'segundoNombre': segundoNombre,
        'apellidoPaterno': apellidoPaterno,
        'apellidoMaterno': apellidoMaterno,
        'fechaNacimiento': fechaNacimiento,
        'curp': curp,
        'rfc': rfc,
        'correo': correo,
        'telefono': telefono,
        'calle': calle,
        'numeroExterior': numeroExterior,
        'numeroInterior': numeroInterior,
        'colonia': colonia,
        'municipio': municipio,
        'estado': estado,
        'codigoPostal': codigoPostal,
        'password': password,
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
      options: Options(headers: {'X-Pre-Auth-Token': preAuthToken}),
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

  Future<Map<String, dynamic>> solicitarOtpParaPin() async {
    final response = await _dio.post('/auth/pin/solicitar-otp');
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

  Future<Map<String, dynamic>> cambiarPinConSeguridad({
    required String password,
    required String otp,
    required String nuevoPin,
  }) async {
    final response = await _dio.post(
      '/auth/pin/cambiar-con-seguridad',
      data: {
        'password': password,
        'otp': otp,
        'nuevoPin': nuevoPin,
      },
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
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
