import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_toast.dart';
import '../../data/services/api_service.dart';

class CambiarPinDialog extends StatefulWidget {
  const CambiarPinDialog({super.key});

  @override
  State<CambiarPinDialog> createState() => _CambiarPinDialogState();
}

class _CambiarPinDialogState extends State<CambiarPinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _nuevoPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _solicitandoOtp = false;
  bool _otpEnviado = false;
  bool _obscurePass = true;
  bool _obscurePin = true;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _otpController.dispose();
    _nuevoPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _solicitarCodigo2FA() async {
    setState(() {
      _solicitandoOtp = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.solicitarOtpParaPin();
      setState(() {
        _solicitandoOtp = false;
        _otpEnviado = true;
        _infoMessage = res['mensaje'] ?? 'Código de seguridad enviado a su correo.';
      });
      if (mounted) {
        BankToast.mostrar(
          context,
          titulo: 'Código Enviado',
          mensaje: 'Revisa tu correo para ingresar el código 2FA.',
          tipo: ToastTipo.info,
        );
      }
    } catch (e) {
      setState(() {
        _solicitandoOtp = false;
        _errorMessage = 'No se pudo enviar el código de seguridad. Intente nuevamente.';
      });
    }
  }

  void _guardarNuevoPin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.cambiarPinConSeguridad(
        password: _passwordController.text.trim(),
        otp: _otpController.text.trim(),
        nuevoPin: _nuevoPinController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        BankToast.mostrar(
          context,
          titulo: 'NIP Actualizado',
          mensaje: 'Tu NIP de tarjeta ha sido modificado y cifrado exitosamente.',
          tipo: ToastTipo.exito,
        );
      }
    } catch (e) {
      String msg = 'No fue posible actualizar el NIP.';
      if (e.toString().contains('Contraseña') || e.toString().contains('401')) {
        msg = 'Contraseña o código 2FA incorrecto.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = msg;
      });
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
          constraints: const BoxConstraints(maxWidth: 420),
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
                                  color: BankTheme.cyanAccent.withOpacity(0.15),
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
                      const SizedBox(height: 6),
                      const Text(
                        'Por protocolo de seguridad bancaria, confirma tu contraseña y el código de verificación 2FA para crear tu nuevo NIP de 4 dígitos.',
                        style: TextStyle(color: BankTheme.textMuted, fontSize: 11.5, height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BankTheme.danger.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: BankTheme.danger.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: BankTheme.danger, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!, style: const TextStyle(color: BankTheme.danger, fontSize: 11.5))),
                            ],
                          ),
                        ),

                      if (_infoMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BankTheme.emeraldSuccess.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: BankTheme.emeraldSuccess.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.mark_email_read_rounded, color: BankTheme.emeraldSuccess, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_infoMessage!, style: const TextStyle(color: BankTheme.emeraldSuccess, fontSize: 11.5))),
                            ],
                          ),
                        ),

                      // 1. Contraseña de acceso
                      const Text('Contraseña de Acceso Actual *', style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePass,
                        style: const TextStyle(color: BankTheme.textMain, fontSize: 13),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: BankTheme.primary, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 18),
                            onPressed: () => setState(() => _obscurePass = !_obscurePass),
                          ),
                          hintText: 'Ingresa tu contraseña',
                          hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 12),
                          filled: true,
                          fillColor: BankTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requerida' : null,
                      ),
                      const SizedBox(height: 12),

                      // 2. Código 2FA con botón de solicitar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Código 2FA (Correo) *', style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                          InkWell(
                            onTap: _solicitandoOtp ? null : _solicitarCodigo2FA,
                            child: Text(
                              _otpEnviado ? 'Reenviar código' : 'Solicitar código 2FA',
                              style: const TextStyle(color: BankTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                        style: const TextStyle(color: BankTheme.textMain, fontSize: 13, letterSpacing: 2),
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.security_rounded, color: BankTheme.primary, size: 18),
                          suffixIcon: _solicitandoOtp
                              ? const Padding(padding: EdgeInsets.all(10), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: BankTheme.cyanAccent)))
                              : null,
                          hintText: 'Código de 6 dígitos',
                          hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 12, letterSpacing: 0),
                          filled: true,
                          fillColor: BankTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (v.trim().length != 6) return '6 dígitos';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // 3. Nuevo NIP y Confirmación
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Nuevo NIP (4 dig.) *', style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                TextFormField(
                                  controller: _nuevoPinController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscureText: _obscurePin,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                                  style: const TextStyle(color: BankTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  decoration: const InputDecoration(
                                    counterText: '',
                                    prefixIcon: Icon(Icons.password_rounded, color: BankTheme.primary, size: 18),
                                    hintText: '••••',
                                    hintStyle: TextStyle(color: BankTheme.textHint, fontSize: 12, letterSpacing: 0),
                                    filled: true,
                                    fillColor: BankTheme.background,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                          const SizedBox(width: 10),
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
                                  style: const TextStyle(color: BankTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: BankTheme.primary, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 18),
                                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                                    ),
                                    hintText: '••••',
                                    hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 12, letterSpacing: 0),
                                    filled: true,
                                    fillColor: BankTheme.background,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _guardarNuevoPin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BankTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Actualizar NIP de Tarjeta', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
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
