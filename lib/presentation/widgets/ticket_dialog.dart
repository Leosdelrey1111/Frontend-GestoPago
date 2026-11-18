import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/models/api_models.dart';

class TicketDialog extends StatelessWidget {
  final TicketModel ticket;

  const TicketDialog({super.key, required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabecera Verde Exitosa
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F5132), Color(0xFF198754)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'PAGO COMPLETADO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Comprobante Digital Fiscal GestoPago',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),

                  // Cuerpo del Ticket
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                '\$${ticket.monto.toStringAsFixed(2)} MXN',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: BankTheme.textMain,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ticket.nombreServicio,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: BankTheme.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: BankTheme.border),
                        const SizedBox(height: 16),

                        // Desglose del Recibo
                        _buildRow('Folio Operación', '#${ticket.folio}'),
                        _buildRow('Número Autorización', ticket.autorizacionProveedor ?? 'AUT-SIMULADA'),
                        _buildRow('Referencia / Teléfono', ticket.referencia),
                        _buildRow('Comisión Proveedor', '\$${ticket.comision.toStringAsFixed(2)} MXN'),
                        _buildRow('Fecha y Hora', ticket.fechaHora),
                        _buildRow('Estatus', ticket.estatus, valorColor: BankTheme.emeraldSuccess),

                        const SizedBox(height: 16),
                        Divider(height: 1, color: BankTheme.border),
                        const SizedBox(height: 14),

                        // Leyenda de Idempotencia y Cifrado
                        Text(
                          ticket.leyendaFiscal.isNotEmpty
                              ? ticket.leyendaFiscal
                              : 'Transacción procesada y validada en tiempo real mediante cifrado AES-256 e idempotencia contable.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10.5, color: BankTheme.textHint, height: 1.4),
                        ),
                        const SizedBox(height: 20),

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
                            child: const Text('Cerrar Comprobante', style: TextStyle(color: BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13)),
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
    );
  }

  Widget _buildRow(String label, String value, {Color? valorColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: BankTheme.textMuted)),
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
