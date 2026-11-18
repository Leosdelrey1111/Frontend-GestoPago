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
      nombreProducto: json['nombreProducto'] ?? '',
      servicio: json['servicio'] ?? '',
      idServicio: (json['idServicio'] ?? '').toString(),
      idProducto: (json['idProducto'] ?? '').toString(),
      precio: (json['precio'] as num?)?.toDouble(),
      tipoReferencia: json['tipoReferencia'],
      urlLogo: json['urlLogo'],
    );
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
    return TransaccionResponseModel(
      folioTransaccion: json['folioTransaccion'],
      autorizacion: json['autorizacion'],
      mensaje: json['mensaje'] ?? '',
      estatus: json['estatus'] ?? '',
      monto: (json['monto'] as num?)?.toDouble(),
      nuevoSaldo: (json['nuevoSaldo'] as num?)?.toDouble(),
      fechaCreacion: json['fechaCreacion'],
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

  String get producto => servicio;
  String? get numAutorizacion => 'AUT-';

  TransaccionHistorialModel({
    required this.id,
    required this.folio,
    required this.servicio,
    required this.referencia,
    required this.monto,
    required this.fecha,
    required this.estado,
  });

  factory TransaccionHistorialModel.fromJson(Map<String, dynamic> json) {
    return TransaccionHistorialModel(
      id: json['id'] ?? 0,
      folio: json['folio'] ?? json['id'] ?? 0,
      servicio: json['servicio'] ?? json['producto'] ?? json['idServicio'] ?? 'Servicio',
      referencia: json['referencia'] ?? json['telefonoOreferencia'] ?? '',
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fecha: json['fecha'] ?? json['fechaCreacion'] ?? '',
      estado: json['estado'] ?? json['estatus'] ?? 'EXITOSO',
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
    return TicketModel(
      folio: (json['folio'] ?? json['id'] ?? '').toString(),
      fechaHora: (json['fechaOperacion'] ?? json['fecha'] ?? '').toString(),
      nombreServicio: (json['servicio'] ?? json['producto'] ?? 'Servicio de Pago').toString(),
      referencia: (json['referenciaOTelefono'] ?? json['referencia'] ?? '').toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      comision: (json['comision'] as num?)?.toDouble() ?? 0.0,
      autorizacionProveedor: (json['numeroAutorizacion'] ?? json['idTransaccionProveedor'] ?? 'AUT-APROBADA').toString(),
      estatus: (json['estatus'] ?? 'EXITOSO').toString(),
      leyendaFiscal: (json['leyenda'] ?? 'Transacción bancaria procesada en tiempo real mediante cifrado bancario seguro.').toString(),
    );
  }
}
