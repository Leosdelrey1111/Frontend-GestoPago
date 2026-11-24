import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _ejecutarRegistro() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.registrarUsuario(
        nombre: _nombreController.text.trim(),
        apellidoPaterno: _apellidoController.text.trim(),
        correo: _correoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: BankTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: BankTheme.border),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: BankTheme.emeraldSuccess, size: 28),
                SizedBox(width: 10),
                Text('Apertura Exitosa', style: TextStyle(color: BankTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenido/a ${_nombreController.text.trim()}. Tu cuenta digital ha sido creada.',
                  style: const TextStyle(color: BankTheme.textMuted, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BankTheme.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: BankTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRowResumen('Número de Cuenta:', (res['numeroCuenta'] ?? '').toString()),
                      const SizedBox(height: 6),
                      _buildRowResumen('Saldo Inicial:', '\$0.00 MXN', valorColor: BankTheme.textMain),
                      const SizedBox(height: 6),
                      _buildRowResumen('Siguiente paso:', 'Crear PIN al iniciar sesión', valorColor: BankTheme.cyanAccent),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankTheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Ir a Iniciar Sesión', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No fue posible abrir la cuenta. Verifique que el correo no esté ya registrado.';
      });
    }
  }

  Widget _buildRowResumen(String label, String valor, {Color? valorColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: BankTheme.textMuted, fontSize: 12)),
        Text(valor, style: TextStyle(color: valorColor ?? BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 12.5)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BankTheme.background,
      appBar: AppBar(
        backgroundColor: BankTheme.surface,
        elevation: 0,
        title: const Text('Solicitud de Apertura Bancaria', style: TextStyle(color: BankTheme.textMain, fontSize: 15, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: BankTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: BankTheme.modalShadow,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: BankTheme.brandGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Registro de Nuevo Titular', style: TextStyle(color: BankTheme.textMain, fontSize: 19, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Apertura de Cuenta Digital', style: TextStyle(color: BankTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BankTheme.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BankTheme.danger.withOpacity(0.4)),
                      ),
                      child: Text(_errorMessage!, style: const TextStyle(color: BankTheme.danger, fontSize: 12.5)),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          'Nombre(s) *',
                          _nombreController,
                          Icons.person_outline,
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'El nombre es requerido';
                            if (v.trim().length < 3) return 'Mínimo 3 caracteres requeridos';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildInput(
                          'Apellido(s) *',
                          _apellidoController,
                          Icons.badge_outlined,
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'El apellido es requerido';
                            if (v.trim().length < 3) return 'Mínimo 3 caracteres requeridos';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  _buildInput(
                    'Correo Electrónico *',
                    _correoController,
                    Icons.email_outlined,
                    maxLength: 60,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El correo es requerido';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                        return 'Ingrese un correo electrónico válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _buildInput(
                    'Teléfono Móvil (10 dígitos) *',
                    _telefonoController,
                    Icons.phone_android_rounded,
                    maxLength: 10,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'El teléfono es requerido';
                      if (v.trim().length != 10) return 'Debe tener exactamente 10 dígitos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _buildInput(
                    'Contraseña de Acceso *',
                    _passwordController,
                    Icons.lock_outline_rounded,
                    maxLength: 32,
                    obscureText: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'La contraseña es requerida';
                      if (v.length < 6) return 'Mínimo 6 caracteres requeridos';
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  _buildInput(
                    'Confirmar Contraseña *',
                    _confirmPasswordController,
                    Icons.lock_reset_rounded,
                    maxLength: 32,
                    obscureText: _obscureConfirmPass,
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                      onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Confirme su contraseña';
                      if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _ejecutarRegistro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BankTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Crear Cuenta Digital', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: BankTheme.primary, size: 19),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: BankTheme.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
