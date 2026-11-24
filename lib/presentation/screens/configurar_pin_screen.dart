import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_toast.dart';
import '../providers/auth_provider.dart';

class ConfigurarPinScreen extends StatefulWidget {
  const ConfigurarPinScreen({super.key});

  @override
  State<ConfigurarPinScreen> createState() => _ConfigurarPinScreenState();
}

class _ConfigurarPinScreenState extends State<ConfigurarPinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;
  String? _errorLocal;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _guardarPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length != 4 || !RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _errorLocal = 'El PIN debe ser de 4 dígitos numéricos');
      return;
    }
    if (pin != confirm) {
      setState(() => _errorLocal = 'Los PINs ingresados no coinciden');
      return;
    }

    setState(() => _errorLocal = null);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.configurarPin(pin);

    if (exito && mounted) {
      BankToast.mostrar(
        context,
        titulo: 'Seguridad Configurada',
        mensaje: '¡PIN transaccional configurado exitosamente!',
        tipo: ToastTipo.exito,
      );
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: BankTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BankTheme.emeraldSuccess.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined, color: BankTheme.emeraldSuccess, size: 40),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Crea tu PIN de Seguridad',
                  style: TextStyle(
                    color: BankTheme.textMain,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Este PIN de 4 dígitos autorizará tus compras y pagos protegidos en el portal.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BankTheme.textMuted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 28),
                if (_errorLocal != null || auth.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BankTheme.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BankTheme.danger.withOpacity(0.4)),
                    ),
                    child: Text(
                      _errorLocal ?? auth.errorMessage ?? '',
                      style: const TextStyle(color: BankTheme.danger, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextField(
                  controller: _pinController,
                  obscureText: _obscurePin,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BankTheme.cyanAccent,
                    fontSize: 26,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Ingresa 4 dígitos',
                    labelStyle: const TextStyle(color: BankTheme.textMuted, fontSize: 13, letterSpacing: 0),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                      onPressed: () => setState(() => _obscurePin = !_obscurePin),
                    ),
                    filled: true,
                    fillColor: BankTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: BankTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPinController,
                  obscureText: _obscureConfirmPin,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BankTheme.cyanAccent,
                    fontSize: 26,
                    letterSpacing: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    labelText: 'Confirma tu PIN',
                    labelStyle: const TextStyle(color: BankTheme.textMuted, fontSize: 13, letterSpacing: 0),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                      onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
                    ),
                    filled: true,
                    fillColor: BankTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: BankTheme.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _guardarPin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BankTheme.emeraldSuccess,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Activar PIN y Continuar',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
