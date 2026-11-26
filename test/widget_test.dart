import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_gestopago/data/models/api_models.dart';

void main() {
  group('CatalogoProductoModel Tests', () {
    test('Identifica servicio de referencia correctamente', () {
      final productoCfe = CatalogoProductoModel(
        id: '1',
        nombreProducto: 'Pago CFE',
        servicio: 'CFE',
        idServicio: '10',
        idProducto: '100',
      );
      expect(productoCfe.esServicioReferencia, isTrue);

      final productoTelcel = CatalogoProductoModel(
        id: '2',
        nombreProducto: 'Paquete Amigo 100',
        servicio: 'TELCEL',
        idServicio: '82',
        idProducto: '200',
      );
      expect(productoTelcel.esServicioReferencia, isFalse);
    });

    test('Mapeo de json CatalogoProductoModel', () {
      final json = {
        'id': 123,
        'nombreProducto': 'Telmex Recibo',
        'servicio': 'TELMEX',
        'idServicio': '11',
        'idProducto': '300',
        'precio': '150.00',
      };
      final model = CatalogoProductoModel.fromJson(json);
      expect(model.nombreProducto, 'Telmex Recibo');
      expect(model.precio, 150.0);
      expect(model.esServicioReferencia, isTrue);
    });
  });

  group('TicketModel Tests', () {
    test('Crea TicketModel y copyWith funciona correctamente', () {
      final ticket = TicketModel(
        folio: '1001',
        upc: '123456789012',
        autorizacionProveedor: 'AUT-789',
        fechaHora: '2026-11-26 14:00',
        nombreServicio: 'CFE',
        referencia: '012345678901',
        monto: 250.0,
        estatus: 'PAGADO / APROBADO',
      );

      expect(ticket.folio, '1001');
      expect(ticket.monto, 250.0);
      expect(ticket.upc.length, 12);

      final enriquecido = ticket.copyWith(
        producto: 'CFE Suministrador de Servicios Básicos',
        tipoProducto: 'Energía Eléctrica',
      );

      expect(enriquecido.producto, 'CFE Suministrador de Servicios Básicos');
      expect(enriquecido.tipoProducto, 'Energía Eléctrica');
      expect(enriquecido.folio, '1001');
    });

    test('TicketModel parsea JSON con campos GestoPago', () {
      final json = {
        'data': {
          'folio': 555,
          'upc': '987654321098',
          'numeroAutorizacion': 'AUT-999',
          'fechaOperacion': '2026-11-26 14:30:00',
          'servicio': 'TELCEL',
          'referenciaOTelefono': '5512345678',
          'monto': 100.0,
          'estatus': 'EXITOSO',
          'leyenda': 'Transacción procesada',
        }
      };

      final ticket = TicketModel.fromJson(json);
      expect(ticket.folio, '555');
      expect(ticket.upc, '987654321098');
      expect(ticket.autorizacionProveedor, 'AUT-999');
      expect(ticket.referencia, '5512345678');
      expect(ticket.monto, 100.0);
    });
  });
}
