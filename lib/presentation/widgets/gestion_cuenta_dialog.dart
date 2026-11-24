import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_toast.dart';
import '../../data/models/api_models.dart';
import '../providers/pago_provider.dart';

class GestionCuentaDialog extends StatefulWidget {
  final CuentaModel cuenta;

  const GestionCuentaDialog({super.key, required this.cuenta});

  @override
  State<GestionCuentaDialog> createState() => _GestionCuentaDialogState();
}

class _GestionCuentaDialogState extends State<GestionCuentaDialog> {
  bool _isLoading = false;

  void _cambiarEstatus(String nuevoEstatus, String mensajeExito) async {
    setState(() => _isLoading = true);
    final pago = Provider.of<PagoProvider>(context, listen: false);
    final exito = await pago.actualizarEstatusCuenta(widget.cuenta.numeroCuenta, nuevoEstatus);

    if (mounted) {
      setState(() => _isLoading = false);
      if (exito) {
        Navigator.pop(context);
        BankToast.mostrar(
          context,
          titulo: nuevoEstatus == 'BLOQUEADA' ? 'Tarjeta Bloqueada' : 'Tarjeta Activada',
          mensaje: mensajeExito,
          tipo: nuevoEstatus == 'BLOQUEADA' ? ToastTipo.advertencia : ToastTipo.exito,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estatus = widget.cuenta.estatus;
    final esActiva = estatus == 'ACTIVA';
    final esBloqueada = estatus == 'BLOQUEADA';

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
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: BankTheme.primary.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.credit_card_rounded, color: BankTheme.cyanAccent, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seguridad de Cuenta', style: TextStyle(color: BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 15)),
                                Text('Administración de Tarjeta Débito', style: TextStyle(color: BankTheme.textMuted, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: BankTheme.textMuted, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Resumen de la cuenta
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BankTheme.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BankTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Número de Cuenta', style: TextStyle(color: BankTheme.textMuted, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(widget.cuenta.numeroCuenta, style: const TextStyle(color: BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: esActiva
                                  ? BankTheme.emeraldSuccess.withOpacity(0.18)
                                  : BankTheme.danger.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: esActiva
                                    ? BankTheme.emeraldSuccess.withOpacity(0.5)
                                    : BankTheme.danger.withOpacity(0.5),
                              ),
                            ),
                            child: Text(
                              estatus,
                              style: TextStyle(
                                color: esActiva ? BankTheme.emeraldSuccess : BankTheme.danger,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Acciones de Tarjeta y Seguridad',
                      style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Opción: Bloqueo / Apagado Temporal (Tipo Nu)
                    _buildActionTile(
                      icon: esActiva ? Icons.lock_outline_rounded : Icons.lock_open_rounded,
                      titulo: esActiva ? 'Apagar / Bloquear Tarjeta' : 'Desbloquear y Activar Tarjeta',
                      subtitulo: esActiva
                          ? 'Impide transacciones y cargos no reconocidos temporalmente.'
                          : 'Habilita tu tarjeta para compras y pagos de servicios.',
                      color: esActiva ? BankTheme.warning : BankTheme.emeraldSuccess,
                      onTap: _isLoading
                          ? null
                          : () => _cambiarEstatus(
                                esActiva ? 'BLOQUEADA' : 'ACTIVA',
                                esActiva ? 'Tarjeta bloqueada temporalmente' : 'Tarjeta reactivada exitosamente',
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

  Widget _buildActionTile({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BankTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(color: BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(subtitulo, style: const TextStyle(color: BankTheme.textHint, fontSize: 11)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: BankTheme.textHint, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

