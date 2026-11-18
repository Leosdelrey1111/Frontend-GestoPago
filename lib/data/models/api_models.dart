import '../../core/constants/api_constants.dart';

class LoginResponse {
  final int codigo;
  final String mensaje;
  final bool requiere2FA;
  final String? preAuthToken;
  final String? token;
  final String? otpAuthUrl;
  final String? totpSecret;
  final bool primerRegistro2FA;
  final String? telefonoEnmascarado;
  final String? correoEnmascarado;

  LoginResponse({
    required this.codigo,
    required this.mensaje,
    required this.requiere2FA,
    this.preAuthToken,
    this.token,
    this.otpAuthUrl,
    this.totpSecret,
    this.primerRegistro2FA = false,
    this.telefonoEnmascarado,
    this.correoEnmascarado,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return LoginResponse(
      codigo: json['codigo'] ?? 200,
      mensaje: json['mensaje'] ?? '',
      requiere2FA: data['requiere2FA'] ?? false,
      preAuthToken: data['preAuthToken'],
      token: data['token'],
      otpAuthUrl: data['otpAuthUrl'],
      totpSecret: data['totpSecret'],
      primerRegistro2FA: data['primerRegistro2FA'] ?? false,
      telefonoEnmascarado: data['telefonoEnmascarado'],
      correoEnmascarado: data['correoEnmascarado'],
    );
  }
}

class CuentaModel {
  final int id;
  final String numeroCuenta;
  final double saldo;
  final String estatus;

  CuentaModel({
    required this.id,
    required this.numeroCuenta,
    required this.saldo,
    required this.estatus,
  });

  factory CuentaModel.fromJson(Map<String, dynamic> json) {
    return CuentaModel(
      id: json['id'] ?? 0,
      numeroCuenta: json['numeroCuenta'] ?? '',
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0.0,
      estatus: json['estatus'] ?? 'ACTIVA',
    );
  }
}

class CatalogoProductoModel {
  final String id;
  final String nombreProducto;
  final String servicio;
  final String idServicio;
  final String idProducto;
  final double? precio;
  final String? tipoReferencia;
  final String? urlLogo;

  CatalogoProductoModel({
    required this.id,
    required this.nombreProducto,
    required this.servicio,
    required this.idServicio,
    required this.idProducto,
    this.precio,
    this.tipoReferencia,
    this.urlLogo,
  });

  factory CatalogoProductoModel.fromJson(Map<String, dynamic> json) {
    return CatalogoProductoModel(
      id: (json['id'] ?? '').toString(),
      nombreProducto: (json['nombreProducto'] ?? '').toString(),
      servicio: (json['servicio'] ?? '').toString(),
      idServicio: (json['idServicio'] ?? '').toString(),
      idProducto: (json['idProducto'] ?? '').toString(),
      precio: _parseDouble(json['precio']),
      tipoReferencia: json['tipoReferencia']?.toString(),
      urlLogo: _resolverUrlLogo(json['urlLogo']),
    );
  }

  static String? _resolverUrlLogo(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    return '${ApiConstants.baseUrl}${s.startsWith('/') ? s : '/$s'}';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }
}

class TransaccionResponseModel {
  final int? folioTransaccion;
  final String? autorizacion;
  final String mensaje;
  final String estatus;
  final double? monto;
  final double? nuevoSaldo;
  final String? fechaCreacion;

  TransaccionResponseModel({
    this.folioTransaccion,
    this.autorizacion,
    required this.mensaje,
    required this.estatus,
    this.monto,
    this.nuevoSaldo,
    this.fechaCreacion,
  });

  factory TransaccionResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final rawFolio = data['folioTransaccion'] ?? data['folio'];
    return TransaccionResponseModel(
      folioTransaccion: rawFolio is int ? rawFolio : int.tryParse('${rawFolio ?? ''}'),
      autorizacion: (data['numAutorizacion'] ?? data['autorizacion'])?.toString(),
      mensaje: (data['mensaje'] ?? json['mensaje'] ?? '').toString(),
      estatus: (data['estatus'] ?? '').toString(),
      monto: (data['monto'] as num?)?.toDouble() ?? double.tryParse('${data['monto'] ?? ''}'),
      nuevoSaldo: (data['nuevoSaldo'] as num?)?.toDouble() ?? double.tryParse('${data['nuevoSaldo'] ?? ''}'),
      fechaCreacion: (data['fecha'] ?? data['fechaCreacion'])?.toString(),
    );
  }
}

class TransaccionHistorialModel {
  final int id;
  final int folio;
  final String servicio;
  final String referencia;
  final double monto;
  final String fecha;
  final String estado;
  final String? numAutorizacion;

  String get producto => servicio;

  TransaccionHistorialModel({
    required this.id,
    required this.folio,
    required this.servicio,
    required this.referencia,
    required this.monto,
    required this.fecha,
    required this.estado,
    this.numAutorizacion,
  });

  factory TransaccionHistorialModel.fromJson(Map<String, dynamic> json) {
    final rawFolio = json['folioTransaccion'] ?? json['folio'] ?? json['id'] ?? 0;
    final parsedFolio = rawFolio is int ? rawFolio : int.tryParse(rawFolio.toString()) ?? 0;
    return TransaccionHistorialModel(
      id: parsedFolio,
      folio: parsedFolio,
      servicio: (json['servicio'] ?? json['producto'] ?? json['idServicio'] ?? 'Servicio').toString(),
      referencia: (json['referencia'] ?? json['telefonoOreferencia'] ?? json['upc'] ?? '').toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? double.tryParse('${json['monto']}') ?? 0.0,
      fecha: (json['fecha'] ?? json['fechaCreacion'] ?? '').toString(),
      estado: (json['estado'] ?? json['estatus'] ?? 'EXITOSO').toString(),
      numAutorizacion: json['numAutorizacion']?.toString(),
    );
  }
}

class TicketModel {
  final String folio;
  final String fechaHora;
  final String nombreServicio;
  final String referencia;
  final double monto;
  final double comision;
  final String autorizacionProveedor;
  final String estatus;
  final String leyendaFiscal;

  TicketModel({
    required this.folio,
    required this.fechaHora,
    required this.nombreServicio,
    required this.referencia,
    required this.monto,
    this.comision = 0.0,
    required this.autorizacionProveedor,
    required this.estatus,
    this.leyendaFiscal = '',
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    return TicketModel(
      folio: (data['folio'] ?? data['id'] ?? '').toString(),
      fechaHora: (data['fechaOperacion'] ?? data['fecha'] ?? '').toString(),
      nombreServicio: (data['servicio'] ?? data['producto'] ?? 'Servicio de Pago').toString(),
      referencia: (data['referenciaOTelefono'] ?? data['referencia'] ?? '').toString(),
      monto: (data['monto'] as num?)?.toDouble() ?? double.tryParse('${data['monto']}') ?? 0.0,
      comision: (data['comision'] as num?)?.toDouble() ?? 0.0,
      autorizacionProveedor: (data['numeroAutorizacion'] ?? data['idTransaccionProveedor'] ?? 'AUT-APROBADA').toString(),
      estatus: (data['estatus'] ?? 'EXITOSO').toString(),
      leyendaFiscal: (data['leyenda'] ?? 'Transacción bancaria procesada en tiempo real mediante cifrado bancario seguro.').toString(),
    );
  }
}
