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

  Future<Map<String, dynamic>> registrarUsuario({
    // Paso 1
    required String nombre,
    String? segundoNombre,
    required String apellidoPaterno,
    required String apellidoMaterno,
    required String fechaNacimiento,
    // Paso 2
    required String curp,
    required String rfc,
    required String correo,
    required String telefono,
    // Paso 3
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

  Future<PagoResponseModel> pagarServicio({
    required int catalogoProductoId,
    required String numeroCuentaOrigen,
    required String referencia,
    required double monto,
    required String pin,
    String? idDispositivo,
  }) async {
    final response = await _dio.post(
      ApiConstants.pagos,
      data: {
        'catalogoProductoId': catalogoProductoId,
        'numeroCuentaOrigen': numeroCuentaOrigen,
        'referencia': referencia,
        'monto': monto,
        'pin': pin,
        'idDispositivo': idDispositivo ?? const Uuid().v4(),
      },
    );
    return PagoResponseModel.fromJson(response.data);
  }

  Future<List<MovimientoModel>> getMovimientos(String numeroCuenta) async {
    final response = await _dio.get(ApiConstants.movimientos(numeroCuenta));
    final dynamic data = response.data;
    if (data is List) {
      return data.map((item) => MovimientoModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<TicketModel>> getTickets(String numeroCuenta) async {
    final response = await _dio.get(ApiConstants.tickets(numeroCuenta));
    final dynamic data = response.data;
    if (data is List) {
      return data.map((item) => TicketModel.fromJson(item)).toList();
    }
    return [];
  }
}
