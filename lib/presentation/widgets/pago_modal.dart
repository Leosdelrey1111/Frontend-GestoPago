import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/models/api_models.dart';

class PagoModal extends StatefulWidget {
  final CatalogoProductoModel producto;
  final List<CuentaModel> cuentas;
  final CuentaModel? cuentaInicial;
  final Function(
    String numeroCuenta,
    String idProducto,
    String idServicio,
    String telefonoOreferencia,
    double monto,
    String pin,
  ) onConfirmar;
  final bool isProcessing;

  const PagoModal({
    super.key,
    required this.producto,
    required this.cuentas,
    this.cuentaInicial,
    required this.onConfirmar,
    required this.isProcessing,
  });

  @override
  State<PagoModal> createState() => _PagoModalState();
}

class _PagoModalState extends State<PagoModal> {
  final _refController = TextEditingController();
  final _montoController = TextEditingController();
  final _pinController = TextEditingController();
  final _formKeyPaso1 = GlobalKey<FormState>();

  String? _cuentaSeleccionada;
  bool _enPasoPin = false;

  void _mostrarToast(String titulo, String mensaje, {bool esAdvertencia = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final color = esAdvertencia ? BankTheme.warning : BankTheme.danger;
    final icono = esAdvertencia ? Icons.shield_outlined : Icons.error_outline_rounded;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 24,
        right: 24,
        left: 24,
        child: Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BankTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.65), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icono, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mensaje,
                            style: TextStyle(
                              color: BankTheme.textMuted.withOpacity(0.9),
                              fontSize: 12.5,
                              height: 1.3,
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

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.cuentas.isNotEmpty) {
      _cuentaSeleccionada = widget.cuentaInicial?.numeroCuenta ?? widget.cuentas.first.numeroCuenta;
    }
    if (widget.producto.precio != null && widget.producto.precio! > 0) {
      _montoController.text = widget.producto.precio!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _refController.dispose();
    _montoController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _avanzarAPin() {
    if (!_formKeyPaso1.currentState!.validate()) return;
    if (_cuentaSeleccionada == null || _cuentaSeleccionada!.isEmpty) {
      _mostrarToast('Cuenta requerida', 'Seleccione una cuenta de débito para realizar el cargo.', esAdvertencia: true);
      return;
    }

    // Validación de estatus de la cuenta seleccionada
    final cta = widget.cuentas.firstWhere(
      (c) => c.numeroCuenta == _cuentaSeleccionada,
      orElse: () => widget.cuentas.first,
    );
    if (cta.estatus != 'ACTIVA') {
      _mostrarToast('Cuenta bloqueada', 'La cuenta se encuentra ${cta.estatus}. Desbloquéela antes de pagar.');
      return;
    }

    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
    if (cta.saldo < monto) {
      _mostrarToast(
        'Saldo Insuficiente',
        'Tu saldo disponible (\$${cta.saldo.toStringAsFixed(2)}) no es suficiente para cubrir este pago de \$${monto.toStringAsFixed(2)}.',
        esAdvertencia: true,
      );
      return;
    }

    setState(() => _enPasoPin = true);
  }

  void _ejecutarPagoFinal() {
    if (_pinController.text.length < 4) {
      _mostrarToast('PIN de seguridad incompleto', 'Ingrese su PIN de seguridad de 4 dígitos para autorizar el cargo.', esAdvertencia: true);
      return;
    }

    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;
    widget.onConfirmar(
      _cuentaSeleccionada!,
      widget.producto.idProducto,
      widget.producto.idServicio,
      _refController.text.trim(),
      monto,
      _pinController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
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
                  // Header de la Operación
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      color: BankTheme.surfaceElevated,
                      border: Border(bottom: BorderSide(color: BankTheme.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: widget.producto.urlLogo != null && widget.producto.urlLogo!.isNotEmpty
                                  ? Image.network(
                                      widget.producto.urlLogo!,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.bolt_rounded, size: 26, color: BankTheme.primary),
                                    )
                                  : const Icon(Icons.bolt_rounded, size: 26, color: BankTheme.primary),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.producto.nombreProducto,
                                  style: const TextStyle(
                                    color: BankTheme.textMain,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Text(
                                  widget.producto.servicio,
                                  style: const TextStyle(
                                    color: BankTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: BankTheme.textMuted, size: 22),
                          onPressed: widget.isProcessing ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),

                  // Contenido Dinámico (Paso 1 o Paso 2 PIN)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _enPasoPin ? _buildPaso2Pin() : _buildPaso1(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaso1() {
    return Form(
      key: _formKeyPaso1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: BankTheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PASO 1 DE 2',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: BankTheme.cyanAccent,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Datos de la Operación',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Selector de Cuenta
          if (widget.cuentas.isNotEmpty) ...[
            const Text(
              'Cuenta de Cargo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankTheme.textMuted),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _cuentaSeleccionada,
              dropdownColor: BankTheme.surfaceElevated,
              style: const TextStyle(color: BankTheme.textMain, fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: BankTheme.cyanAccent),
                filled: true,
                fillColor: BankTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.primary, width: 1.5)),
              ),
              items: widget.cuentas.map((c) {
                return DropdownMenuItem<String>(
                  value: c.numeroCuenta,
                  child: Text('Cta: ${c.numeroCuenta}  (Disp: \$${c.saldo.toStringAsFixed(2)})'),
                );
              }).toList(),
              onChanged: (val) => setState(() => _cuentaSeleccionada = val),
            ),
            const SizedBox(height: 16),
          ],

          // Referencia / Teléfono
          const Text(
            'Número de Teléfono (10 dígitos) o Referencia',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankTheme.textMuted),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _refController,
            keyboardType: TextInputType.number,
            maxLength: 10,
            style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej. 5512345678 (10 dígitos)',
              hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
              counterText: '',
              prefixIcon: const Icon(Icons.phone_android_rounded, size: 20, color: BankTheme.primary),
              filled: true,
              fillColor: BankTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.primary, width: 1.5)),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'La referencia o teléfono es obligatoria';
              if (v.trim().length != 10 || !RegExp(r'^\d{10}$').hasMatch(v.trim())) {
                return 'Debe ingresar exactamente 10 dígitos numéricos';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Monto
          const Text(
            'Importe a Pagar (\$ MXN)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankTheme.textMuted),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _montoController,
            readOnly: widget.producto.precio != null && widget.producto.precio! > 0,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: BankTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.attach_money_rounded, size: 20, color: BankTheme.emeraldSuccess),
              filled: true,
              fillColor: BankTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.primary, width: 1.5)),
            ),
            validator: (v) {
              final m = double.tryParse(v ?? '');
              if (m == null || m <= 0) return 'Ingrese un monto válido mayor a 0';
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Botón Continuar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _avanzarAPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: BankTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuar a Autorización', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2Pin() {
    final monto = double.tryParse(_montoController.text.trim()) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: BankTheme.textMuted, size: 20),
              onPressed: widget.isProcessing ? null : () => setState(() => _enPasoPin = false),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: BankTheme.emeraldSuccess.withOpacity(0.18),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PASO 2 DE 2',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: BankTheme.emeraldSuccess,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Autorización de Seguridad',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankTheme.textMain),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Resumen del Cargo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BankTheme.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BankTheme.border),
          ),
          child: Column(
            children: [
              const Text('Monto Total a Debitar', style: TextStyle(fontSize: 11, color: BankTheme.textMuted)),
              const SizedBox(height: 4),
              Text(
                '\$${monto.toStringAsFixed(2)} MXN',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: BankTheme.emeraldSuccess),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: BankTheme.border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Destino / Teléfono:', style: TextStyle(fontSize: 12, color: BankTheme.textMuted)),
                  Text(_refController.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankTheme.textMain)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Text(
          'Ingresa tu PIN de Seguridad (4 dígitos)',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: BankTheme.textMain),
        ),
        const SizedBox(height: 10),

        // Input de PIN
        SizedBox(
          width: 220,
          child: TextField(
            controller: _pinController,
            obscureText: true,
            maxLength: 4,
            autofocus: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              letterSpacing: 16,
              fontWeight: FontWeight.bold,
              color: BankTheme.cyanAccent,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '••••',
              hintStyle: const TextStyle(color: BankTheme.textHint, letterSpacing: 16),
              filled: true,
              fillColor: BankTheme.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: BankTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Botón de Confirmación con estado de carga
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: widget.isProcessing ? null : _ejecutarPagoFinal,
            style: ElevatedButton.styleFrom(
              backgroundColor: BankTheme.emeraldSuccess,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: widget.isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Confirmar y Pagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
