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
  final String? idCatTipoServicio;
  final String? tipoFront;
  final String? urlLogo;

  CatalogoProductoModel({
    required this.id,
    required this.nombreProducto,
    required this.servicio,
    required this.idServicio,
    required this.idProducto,
    this.precio,
    this.tipoReferencia,
    this.idCatTipoServicio,
    this.tipoFront,
    this.urlLogo,
  });

  /// Determina si es pago de servicios (CFE, Telmex, etc.) o recarga telefónica móvil
  bool get esServicioReferencia {
    final cat = (idCatTipoServicio ?? '').trim();
    if (cat == '10' || cat == '11') return true;
    final serv = servicio.toUpperCase();
    if (serv.contains('CFE') ||
        serv.contains('TELMEX') ||
        serv.contains('TOTALPLAY') ||
        serv.contains('IZZI') ||
        serv.contains('AGUA') ||
        serv.contains('GAS') ||
        serv.contains('SKY') ||
        serv.contains('VEOLIA') ||
        serv.contains('NATURGY') ||
        serv.contains('SACMEX')) {
      return true;
    }
    return false;
  }

  factory CatalogoProductoModel.fromJson(Map<String, dynamic> json) {
    return CatalogoProductoModel(
      id: (json['id'] ?? '').toString(),
      nombreProducto: (json['nombreProducto'] ?? '').toString(),
      servicio: (json['servicio'] ?? '').toString(),
      idServicio: (json['idServicio'] ?? '').toString(),
      idProducto: (json['idProducto'] ?? '').toString(),
      precio: _parseDouble(json['precio']),
      tipoReferencia: json['tipoReferencia']?.toString(),
      idCatTipoServicio: json['idCatTipoServicio']?.toString(),
      tipoFront: json['tipoFront']?.toString(),
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
  final String upc;
  final String autorizacionProveedor;
  final String idTransaccionProveedor;
  final String dateSendTx;
  final String fechaHora;
  final String nombreServicio;
  final String producto;
  final String tipoProducto;
  final String referencia;
  final double monto;
  final double comision;
  final String estatus;
  final String leyendaFiscal;
  final String? urlLogo;

  TicketModel({
    required this.folio,
    this.upc = '',
    required this.autorizacionProveedor,
    this.idTransaccionProveedor = '',
    this.dateSendTx = '',
    required this.fechaHora,
    required this.nombreServicio,
    this.producto = '',
    this.tipoProducto = '',
    required this.referencia,
    required this.monto,
    this.comision = 0.0,
    required this.estatus,
    this.leyendaFiscal = '',
    this.urlLogo,
  });

  TicketModel copyWith({
    String? folio,
    String? upc,
    String? autorizacionProveedor,
    String? idTransaccionProveedor,
    String? dateSendTx,
    String? fechaHora,
    String? nombreServicio,
    String? producto,
    String? tipoProducto,
    String? referencia,
    double? monto,
    double? comision,
    String? estatus,
    String? leyendaFiscal,
    String? urlLogo,
  }) {
    return TicketModel(
      folio: folio ?? this.folio,
      upc: upc ?? this.upc,
      autorizacionProveedor: autorizacionProveedor ?? this.autorizacionProveedor,
      idTransaccionProveedor: idTransaccionProveedor ?? this.idTransaccionProveedor,
      dateSendTx: dateSendTx ?? this.dateSendTx,
      fechaHora: fechaHora ?? this.fechaHora,
      nombreServicio: nombreServicio ?? this.nombreServicio,
      producto: producto ?? this.producto,
      tipoProducto: tipoProducto ?? this.tipoProducto,
      referencia: referencia ?? this.referencia,
      monto: monto ?? this.monto,
      comision: comision ?? this.comision,
      estatus: estatus ?? this.estatus,
      leyendaFiscal: leyendaFiscal ?? this.leyendaFiscal,
      urlLogo: urlLogo ?? this.urlLogo,
    );
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final fechaRaw = (data['fechaOperacion'] ?? data['dateSendTx'] ?? data['fecha'] ?? '').toString();
    final serv = (data['servicio'] ?? '').toString();
    final prod = (data['producto'] ?? data['nombreProducto'] ?? serv).toString();

    return TicketModel(
      folio: (data['folio'] ?? data['id'] ?? '').toString(),
      upc: (data['upc'] ?? data['claveIdempotencia'] ?? '').toString(),
      autorizacionProveedor: (data['numeroAutorizacion'] ?? data['numAutorizacion'] ?? data['autorizacion'] ?? 'N/A').toString(),
      idTransaccionProveedor: (data['idTransaccionProveedor'] ?? data['idTxGestoPago'] ?? data['idTx'] ?? 'N/A').toString(),
      dateSendTx: fechaRaw,
      fechaHora: fechaRaw,
      nombreServicio: serv.isNotEmpty ? serv : 'Servicio GestoPago',
      producto: prod,
      tipoProducto: (data['tipoProducto'] ?? data['categoria'] ?? serv).toString(),
      referencia: (data['referenciaOTelefono'] ?? data['referencia'] ?? data['telefono'] ?? '').toString(),
      monto: (data['monto'] as num?)?.toDouble() ?? double.tryParse('${data['monto']}') ?? 0.0,
      comision: (data['comision'] as num?)?.toDouble() ?? 0.0,
      estatus: (data['estatus'] ?? data['estado'] ?? 'EXITOSO').toString(),
      leyendaFiscal: (data['leyenda'] ?? data['leyendaFiscal'] ?? '').toString(),
      urlLogo: CatalogoProductoModel._resolverUrlLogo(data['urlLogo']),
    );
  }
}
