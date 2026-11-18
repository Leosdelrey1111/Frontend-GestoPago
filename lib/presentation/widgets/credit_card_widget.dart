import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/models/api_models.dart';
import 'gestion_cuenta_dialog.dart';

class CreditCardWidget extends StatefulWidget {
  final CuentaModel? cuenta;
  final String userEmail;

  const CreditCardWidget({
    super.key,
    required this.cuenta,
    required this.userEmail,
  });

  @override
  State<CreditCardWidget> createState() => _CreditCardWidgetState();
}

class _CreditCardWidgetState extends State<CreditCardWidget> {
  bool _mostrarSaldo = true;

  @override
  Widget build(BuildContext context) {
    final saldo = widget.cuenta?.saldo ?? 0.0;
    final numCuenta = widget.cuenta?.numeroCuenta ?? '0000 0000 00';
    final estatus = widget.cuenta?.estatus ?? 'ACTIVA';

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A8A), // Deep Blue Indigo
            Color(0xFF0F172A), // Midnight Dark
            Color(0xFF020617), // Deep Navy
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Arte decorativo radial de fondo
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BankTheme.cyanAccent.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -50,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BankTheme.primary.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Contenido principal de la Tarjeta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fila superior: Branding + Badge de Estatus Activo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.15)),
                        ),
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEOBANK DIGITAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'GestoPago Verified Debit',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (widget.cuenta != null) {
                        showDialog(
                          context: context,
                          builder: (_) => GestionCuentaDialog(cuenta: widget.cuenta!),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: estatus == 'ACTIVA'
                            ? BankTheme.emeraldSuccess.withOpacity(0.18)
                            : BankTheme.danger.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: estatus == 'ACTIVA'
                              ? BankTheme.emeraldSuccess.withOpacity(0.5)
                              : BankTheme.danger.withOpacity(0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: estatus == 'ACTIVA' ? BankTheme.emeraldSuccess : BankTheme.danger,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            estatus,
                            style: TextStyle(
                              color: estatus == 'ACTIVA' ? BankTheme.emeraldSuccess : BankTheme.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.settings_outlined, color: Colors.white70, size: 12),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Chip Bancario Dorado & Contactless
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFDF7A), Color(0xFFD4AF37), Color(0xFFA67C00)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 32,
                        height: 20,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black.withOpacity(0.25), width: 1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Icon(Icons.wifi_rounded, color: Colors.white.withOpacity(0.7), size: 22),
                ],
              ),

              // Sección de Saldo con Privacidad (Eye Toggle)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'SALDO DISPONIBLE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _mostrarSaldo = !_mostrarSaldo),
                        child: Padding(
                          padding: const EdgeInsets.all(2.0),
                          child: Icon(
                            _mostrarSaldo ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _mostrarSaldo ? '\$${saldo.toStringAsFixed(2)} MXN' : '•••••••• MXN',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              // Footer de Tarjeta: Titular y Número de Cuenta Enmascarado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          widget.userEmail,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'CUENTA DÉBITO',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        numCuenta.length >= 4 ? '•••• ${numCuenta.substring(numCuenta.length - 4)}' : numCuenta,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
