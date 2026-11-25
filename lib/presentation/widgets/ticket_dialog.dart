import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/models/api_models.dart';

class TicketDialog extends StatelessWidget {
  final TicketModel ticket;

  const TicketDialog({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final esRechazada = ticket.estatus.toUpperCase().contains('RECHAZAD') || 
                        ticket.estatus.toUpperCase().contains('FALLID');
    final esPendiente = ticket.estatus.toUpperCase().contains('PENDIENTE') || 
                        ticket.estatus.toUpperCase().contains('CONCILIA');

    final colorGradiente1 = esRechazada 
        ? const Color(0xFF842029) 
        : esPendiente ? const Color(0xFF664D03) : const Color(0xFF0F5132);
    final colorGradiente2 = esRechazada 
        ? const Color(0xFFDC3545) 
        : esPendiente ? const Color(0xFFFFC107) : const Color(0xFF198754);
    final iconoCabecera = esRechazada 
        ? Icons.cancel_outlined 
        : esPendiente ? Icons.hourglass_empty_rounded : Icons.check_circle_outline_rounded;
    final tituloCabecera = esRechazada 
        ? 'COMPROBANTE: SERVICIO RECHAZADO' 
        : esPendiente ? 'PAGO EN PROCESO DE VALIDACIÓN' : 'COMPROBANTE OFICIAL DE PAGO';

    // Leyenda de respuesta de GestoPago
    String leyendaGestoPago = ticket.leyendaFiscal.trim();
    if (leyendaGestoPago.isEmpty) {
      if (esRechazada) {
        leyendaGestoPago = 'Servicio no disponible o rechazado por la red de GestoPago. No se aplicó ningún cargo a su cuenta.';
      } else if (esPendiente) {
        leyendaGestoPago = 'Transacción en validación con el proveedor. Su saldo permanece retenido hasta conciliación.';
      } else {
        leyendaGestoPago = 'Transacción autorizada y liquidada exitosamente a través de la pasarela GestoPago. Conserve este comprobante.';
      }
    }

    final nombreProd = ticket.producto.isNotEmpty 
        ? ticket.producto 
        : (ticket.nombreServicio.isNotEmpty ? ticket.nombreServicio : 'Servicio Digital');
    final categoriaProd = ticket.tipoProducto.isNotEmpty 
        ? ticket.tipoProducto 
        : (ticket.nombreServicio.isNotEmpty ? ticket.nombreServicio : 'Telecomunicaciones / Servicios');

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.65),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera Dinámica con Gradiente y Logo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [colorGradiente1, colorGradiente2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Imagen / Logo del Producto si existe
                              if (ticket.urlLogo != null && ticket.urlLogo!.isNotEmpty) ...[
                                Container(
                                  width: 48,
                                  height: 48,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Image.network(
                                    ticket.urlLogo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Icon(iconoCabecera, color: colorGradiente1, size: 28),
                                  ),
                                ),
                                const SizedBox(width: 14),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(iconoCabecera, color: Colors.white, size: 32),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tituloCabecera,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'GestoPago Gateway 2.0',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Cuerpo del Ticket
                    Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Monto y Nombre del Producto
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '\$${ticket.monto.toStringAsFixed(2)} MXN',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: esRechazada ? BankTheme.danger : BankTheme.textMain,
                                    letterSpacing: -0.5,
                                    decoration: esRechazada ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nombreProd,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: BankTheme.cyanAccent,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Badge de Tipo de Producto
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: BankTheme.surfaceElevated,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: BankTheme.borderSubtle),
                                  ),
                                  child: Text(
                                    'Tipo: $categoriaProd',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: BankTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Divider(height: 1, color: BankTheme.border),
                          const SizedBox(height: 14),

                          // Desglose de Datos de Transacción
                          _buildRow('Folio Operación', '#${ticket.folio}'),
                          _buildRow(
                            'UPC (Llave de Transacción)', 
                            ticket.upc.isNotEmpty ? ticket.upc : 'N/A',
                            valorColor: BankTheme.cyanAccent,
                          ),
                          _buildRow(
                            'No. Autorización GestoPago', 
                            ticket.autorizacionProveedor.isNotEmpty ? ticket.autorizacionProveedor : 'N/A',
                            valorColor: esRechazada ? BankTheme.danger : BankTheme.emeraldSuccess,
                          ),
                          if (ticket.idTransaccionProveedor.isNotEmpty && ticket.idTransaccionProveedor != 'N/A')
                            _buildRow('ID Tx Proveedor', ticket.idTransaccionProveedor),
                          _buildRow(
                            ticket.referencia.length > 10 ? 'No. Referencia Servicio' : 'Teléfono / Referencia',
                            ticket.referencia,
                            valorColor: BankTheme.textMain,
                          ),
                          _buildRow('Comisión Proveedor', '\$${ticket.comision.toStringAsFixed(2)} MXN'),
                          _buildRow(
                            'Fecha Envío Tx (dateSendTx)', 
                            ticket.dateSendTx.isNotEmpty ? ticket.dateSendTx : ticket.fechaHora,
                          ),
                          _buildRow(
                            'Estatus', 
                            ticket.estatus,
                            valorColor: esRechazada 
                                ? BankTheme.danger 
                                : (esPendiente ? BankTheme.warning : BankTheme.emeraldSuccess),
                          ),

                          const SizedBox(height: 14),
                          Divider(height: 1, color: BankTheme.border),
                          const SizedBox(height: 12),

                          // Leyenda de GestoPago (Respuesta oficial / Servicio no disponible)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: esRechazada 
                                  ? BankTheme.danger.withOpacity(0.08)
                                  : BankTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: esRechazada 
                                    ? BankTheme.danger.withOpacity(0.3)
                                    : BankTheme.borderSubtle,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  esRechazada ? Icons.info_outline_rounded : Icons.verified_user_outlined,
                                  color: esRechazada ? BankTheme.danger : BankTheme.cyanAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    leyendaGestoPago,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: esRechazada ? BankTheme.danger : BankTheme.textHint,
                                      height: 1.35,
                                      fontWeight: esRechazada ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Botón de Cierre
                          SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: BankTheme.surfaceElevated,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: BankTheme.border),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cerrar Comprobante', 
                                style: TextStyle(
                                  color: BankTheme.textMain, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valorColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: BankTheme.textMuted)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valorColor ?? BankTheme.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
