import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_toast.dart';
import '../providers/auth_provider.dart';

class CambiarPinDialog extends StatefulWidget {
  final VoidCallback? onPinConfigurado;

  const CambiarPinDialog({super.key, this.onPinConfigurado});

  @override
  State<CambiarPinDialog> createState() => _CambiarPinDialogState();
}

class _CambiarPinDialogState extends State<CambiarPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nuevoPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePin = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nuevoPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _guardarNuevoPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final exito = await auth.configurarPin(_nuevoPinController.text.trim());

      if (mounted) {
        if (exito) {
          Navigator.pop(context);
          BankToast.mostrar(
            context,
            titulo: 'NIP Configurado',
            mensaje: 'Tu NIP de seguridad de 4 dígitos ha sido guardado exitosamente.',
            tipo: ToastTipo.exito,
          );
          if (widget.onPinConfigurado != null) {
            widget.onPinConfigurado!();
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = auth.errorMessage ?? 'No fue posible registrar el NIP. Intente de nuevo.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error al comunicarse con el servidor.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
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
                                  color: BankTheme.cyanAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.pin_rounded, color: BankTheme.cyanAccent, size: 20),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Configurar NIP de Tarjeta',
                                style: TextStyle(
                                  color: BankTheme.textMain,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: BankTheme.textHint, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ingresa tu nuevo NIP de seguridad de 4 dígitos para autorizar pagos y compras de servicios.',
                        style: TextStyle(color: BankTheme.textMuted, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 18),

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BankTheme.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: BankTheme.danger.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: BankTheme.danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!, style: const TextStyle(color: BankTheme.danger, fontSize: 11.5)),
                              ),
                            ],
                          ),
                        ),

                      // Entradas de NIP y Confirmación
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nuevo NIP *', style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _nuevoPinController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: _obscurePin,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                                  style: const TextStyle(color: BankTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    prefixIcon: const Icon(Icons.password_rounded, color: BankTheme.primary, size: 18),
                                    hintText: '••••',
                                    hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 14, letterSpacing: 2),
                                    filled: true,
                                    fillColor: BankTheme.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.border)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5)),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().length != 4) return '4 dígitos';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Confirmar NIP *', style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _confirmPinController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: _obscurePin,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                                  style: const TextStyle(color: BankTheme.textMain, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: BankTheme.primary, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 18),
                                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                    ),
                                    hintText: '••••',
                                    hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 14, letterSpacing: 2),
                                    filled: true,
                                    fillColor: BankTheme.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.border)),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.border)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5)),
                                    isDense: true,
                                  ),
                                  validator: (v) {
                                    if (v != _nuevoPinController.text) return 'No coincide';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarNuevoPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BankTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Guardar NIP de Tarjeta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
