import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Datos Personales
  final _nombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();

  // Datos Fiscales y Nacimiento
  final _curpController = TextEditingController();
  final _rfcController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  DateTime? _fechaNacimientoSeleccionada;

  // Contacto y Domicilio
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _codigoPostalController = TextEditingController();

  // Credenciales
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
    _segundoNombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _curpController.dispose();
    _rfcController.dispose();
    _fechaNacimientoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _codigoPostalController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFechaNacimiento() async {
    final DateTime maxDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    final DateTime initialDate = _fechaNacimientoSeleccionada ?? maxDate;
    final DateTime minDate = DateTime(1920, 1, 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(maxDate) ? maxDate : initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: BankTheme.primary,
              onPrimary: Colors.white,
              surface: BankTheme.surfaceElevated,
              onSurface: BankTheme.textMain,
            ),
            dialogBackgroundColor: BankTheme.surface,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaNacimientoSeleccionada = picked;
        _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
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
        segundoNombre: _segundoNombreController.text.trim().isNotEmpty
            ? _segundoNombreController.text.trim()
            : null,
        apellidoPaterno: _apellidoPaternoController.text.trim(),
        apellidoMaterno: _apellidoMaternoController.text.trim(),
        curp: _curpController.text.trim().toUpperCase(),
        rfc: _rfcController.text.trim().toUpperCase(),
        fechaNacimiento: _fechaNacimientoController.text.trim(),
        codigoPostal: int.parse(_codigoPostalController.text.trim()),
        correo: _correoController.text.trim().toLowerCase(),
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
                  'Bienvenido/a ${_nombreController.text.trim()}. Tu cuenta digital bancaria ha sido creada satisfactoriamente.',
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
                      _buildRowResumen('Titular:', '${_nombreController.text.trim()} ${_apellidoPaternoController.text.trim()}'),
                      const SizedBox(height: 6),
                      _buildRowResumen('Siguiente paso:', 'Crear PIN de 4 dígitos al iniciar sesión', valorColor: BankTheme.cyanAccent),
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
      String mensaje = 'No fue posible abrir la cuenta bancaria.';
      if (e.toString().contains('CURP')) {
        mensaje = 'Ya existe un cliente registrado con la CURP proporcionada.';
      } else if (e.toString().contains('RFC')) {
        mensaje = 'Ya existe un cliente registrado con el RFC proporcionado.';
      } else if (e.toString().contains('correo') || e.toString().contains('401')) {
        mensaje = 'El correo electrónico ya se encuentra registrado.';
      }
      setState(() {
        _isLoading = false;
        _errorMessage = mensaje;
      });
    }
  }

  Widget _buildRowResumen(String label, String valor, {Color? valorColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: BankTheme.textMuted, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: valorColor ?? BankTheme.textMain, fontWeight: FontWeight.bold, fontSize: 12.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: BankTheme.cyanAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: BankTheme.cyanAccent,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: BankTheme.border, thickness: 1)),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 580),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(24),
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
                        child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Apertura de Cuenta Digital', style: TextStyle(color: BankTheme.textMain, fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Registro bancario oficial de nuevo titular', style: TextStyle(color: BankTheme.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BankTheme.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BankTheme.danger.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: BankTheme.danger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(_errorMessage!, style: const TextStyle(color: BankTheme.danger, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    ),

                  // 1. DATOS PERSONALES
                  _buildSectionHeader('1. DATOS PERSONALES', Icons.person_outline_rounded),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          'Primer Nombre *',
                          _nombreController,
                          Icons.badge_outlined,
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length < 3) return 'Mín. 3 caracteres';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput(
                          'Segundo Nombre',
                          _segundoNombreController,
                          Icons.badge_outlined,
                          maxLength: 40,
                          hintText: 'Opcional',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          'Apellido Paterno *',
                          _apellidoPaternoController,
                          Icons.person_outline,
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length < 3) return 'Mín. 3 caracteres';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput(
                          'Apellido Materno *',
                          _apellidoMaternoController,
                          Icons.person_outline,
                          maxLength: 40,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length < 3) return 'Mín. 3 caracteres';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 2. IDENTIDAD Y DATOS FISCALES
                  _buildSectionHeader('2. IDENTIFICACIÓN Y DATOS FISCALES', Icons.verified_user_outlined),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInput(
                          'CURP (18 caracteres) *',
                          _curpController,
                          Icons.fingerprint_rounded,
                          maxLength: 18,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length != 18) return 'Debe tener 18 caracteres';
                            if (!RegExp(r'^[A-Z]{4}\d{6}[HM][A-Z]{5}[0-9A-Z]\d$').hasMatch(v.trim())) {
                              return 'Formato de CURP no válido';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput(
                          'RFC (12-13 car.) *',
                          _rfcController,
                          Icons.assignment_ind_outlined,
                          maxLength: 13,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            UpperCaseTextFormatter(),
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length < 12 || v.trim().length > 13) return '12 o 13 car.';
                            if (!RegExp(r'^[A-ZÑ&]{3,4}\d{6}[A-Z0-9]{3}$').hasMatch(v.trim())) {
                              return 'RFC no válido';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Fecha de nacimiento
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha de Nacimiento (Mayor de 18 años) *', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _fechaNacimientoController,
                        readOnly: true,
                        onTap: _seleccionarFechaNacimiento,
                        style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
                        decoration: InputDecoration(
                          counterText: '',
                          prefixIcon: const Icon(Icons.calendar_month_outlined, color: BankTheme.primary, size: 19),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.date_range_rounded, color: BankTheme.cyanAccent, size: 20),
                            onPressed: _seleccionarFechaNacimiento,
                          ),
                          hintText: 'AAAA-MM-DD',
                          hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
                          filled: true,
                          fillColor: BankTheme.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Seleccione su fecha de nacimiento';
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 3. CONTACTO Y UBICACIÓN
                  _buildSectionHeader('3. CONTACTO Y DOMICILIO', Icons.location_on_outlined),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildInput(
                          'Teléfono Móvil (10 dígitos) *',
                          _telefonoController,
                          Icons.phone_android_rounded,
                          maxLength: 10,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length != 10) return 'Exactamente 10 dígitos';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: _buildInput(
                          'C.P. (5 dígitos) *',
                          _codigoPostalController,
                          Icons.markunread_mailbox_outlined,
                          maxLength: 5,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Requerido';
                            if (v.trim().length != 5) return '5 dígitos';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

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

                  // 4. SEGURIDAD DE LA CUENTA
                  _buildSectionHeader('4. SEGURIDAD Y ACCESO', Icons.lock_outline_rounded),
                  _buildInput(
                    'Contraseña de Acceso (8-12 car.) *',
                    _passwordController,
                    Icons.lock_outline_rounded,
                    maxLength: 12,
                    obscureText: _obscurePass,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'La contraseña es requerida';
                      if (v.length < 8 || v.length > 12) return 'Debe tener entre 8 y 12 caracteres';
                      if (!RegExp(r'^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=!._\-*]).*$').hasMatch(v)) {
                        return 'Incluya mayúscula, minúscula, número y símbolo (@, #, \$, etc.)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildInput(
                    'Confirmar Contraseña *',
                    _confirmPasswordController,
                    Icons.lock_reset_rounded,
                    maxLength: 12,
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
                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _ejecutarRegistro,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BankTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Solicitar Apertura Bancaria', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: BankTheme.primary, size: 19),
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
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

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
