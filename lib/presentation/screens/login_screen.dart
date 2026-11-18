import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController(text: 'bhleonel705@gmail.com');
  final _passwordController = TextEditingController(text: 'Password123!');
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _mostrarPasoOtp = false;
  bool _obscurePassword = true;
  // 0 = Google Authenticator (TOTP), 1 = SMS / Correo (OTP)
  int _metodo2FASeleccionado = 0;
  bool _mostrarQrForzado = false;

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _enviarLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final requiere2FA = await auth.iniciarSesion(
      _correoController.text.trim(),
      _passwordController.text.trim(),
    );

    if (requiere2FA) {
      setState(() {
        _mostrarPasoOtp = true;
        _otpController.clear();
        _mostrarQrForzado = false;
        // Si ya tiene TOTP activado, por defecto va a la pestaa de Google Authenticator
        _metodo2FASeleccionado = 0;
      });
    } else if (auth.isAuthenticated) {
      if (mounted) {
        if (!auth.tienePinConfigurado) {
          Navigator.pushReplacementNamed(context, '/configurar-pin');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    }
  }

  void _enviarOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa los 6 dgitos del cdigo de seguridad.'),
          backgroundColor: BankTheme.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.verificarOtp(_otpController.text.trim());
    if (exito && mounted) {
      if (!auth.tienePinConfigurado) {
        Navigator.pushReplacementNamed(context, '/configurar-pin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _solicitarReenvioCorreo() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.reenviarCodigoCorreo();
    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cdigo enviado a su telfono '),
          backgroundColor: BankTheme.emeraldSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 960;

    return Scaffold(
      backgroundColor: BankTheme.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isDesktop ? 1040 : 480),
            child: Container(
              decoration: BoxDecoration(
                color: BankTheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: BankTheme.border, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(child: _buildBrandingSide()),
                          Expanded(child: _buildFormSide(auth)),
                        ],
                      )
                    : _buildFormSide(auth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandingSide() {
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF1B2E3D),
            Color(0xFF0A192F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 24),
          const Text(
            'GESTOPAGO BANK',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pasarela transaccional corporativa y ecosistema de pagos en tiempo real.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13.5,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          _buildFeaturePill(Icons.verified_user_rounded, 'Autenticacin TOTP (RFC 6238 / Google Authenticator)'),
          const SizedBox(height: 14),
          _buildFeaturePill(Icons.phonelink_lock_rounded, 'Single Active Session respaldada en Base de Datos'),
          const SizedBox(height: 14),
          _buildFeaturePill(Icons.shield_rounded, 'Cifrado Bancario AES-256 e Idempotencia UUID v4'),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: BankTheme.cyanAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormSide(AuthProvider auth) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mostrarPasoOtp ? 'Verificacin de Identidad' : 'Acceso Bancario',
              style: const TextStyle(
                color: BankTheme.textMain,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _mostrarPasoOtp
                  ? 'Selecciona tu mtodo de autenticacin preferido'
                  : 'Ingresa tus credenciales institucionales registradas',
              style: const TextStyle(color: BankTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            if (auth.errorMessage != null)
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
                      child: Text(
                        auth.errorMessage!,
                        style: const TextStyle(color: BankTheme.danger, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

            if (!_mostrarPasoOtp) ...[
              // Input Correo
              const Text('Correo Electrnico', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _correoController,
                style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: BankTheme.primary, size: 20),
                  hintText: 'ejemplo@banco.com',
                  hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
                  filled: true,
                  fillColor: BankTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.primary, width: 1.5)),
                ),
                validator: (v) => (v == null || !v.contains('@')) ? 'Ingrese un correo vlido' : null,
              ),
              const SizedBox(height: 16),

              // Input Password
              const Text('Contrasea de Acceso', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: BankTheme.primary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: BankTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.primary, width: 1.5)),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Ingrese su contrasea' : null,
              ),
              const SizedBox(height: 26),

              // Botn Login
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _enviarLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BankTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Iniciar Sesin', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('No tienes cuenta bancaria?', style: TextStyle(color: BankTheme.textMuted, fontSize: 13)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/registro'),
                      child: const Text(
                        'Crear Cuenta',
                        style: TextStyle(color: BankTheme.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // SELECTOR PROFESIONAL DE METODO 2FA
              _buildSelectorMetodo2FA(),
              const SizedBox(height: 18),

              // VISTA DINAMICA SEGUN EL METODO SELECCIONADO
              if (_metodo2FASeleccionado == 0)
                _buildMetodoGoogleAuth(auth)
              else
                _buildMetodoSmsOtp(auth),

              const SizedBox(height: 22),

              // INPUT 6 DIGITOS
              const Text('Cdigo de Seguridad (6 dgitos)', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _otpController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                autofocus: true,
                style: const TextStyle(color: BankTheme.cyanAccent, fontSize: 26, letterSpacing: 14, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '',
                  hintStyle: const TextStyle(color: BankTheme.textHint, letterSpacing: 14),
                  filled: true,
                  fillColor: BankTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: BankTheme.cyanAccent, width: 1.5)),
                ),
              ),
              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _enviarOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BankTheme.emeraldSuccess,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: auth.isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Autorizar Acceso Seguro', style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _mostrarPasoOtp = false),
                  child: const Text('Volver al inicio de sesin', style: TextStyle(color: BankTheme.textMuted, fontSize: 12.5)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorMetodo2FA() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BankTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _metodo2FASeleccionado = 0),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _metodo2FASeleccionado == 0 ? BankTheme.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _metodo2FASeleccionado == 0 ? Border.all(color: BankTheme.primary.withOpacity(0.5)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 16,
                      color: _metodo2FASeleccionado == 0 ? BankTheme.cyanAccent : BankTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'App Autenticadora',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _metodo2FASeleccionado == 0 ? Colors.white : BankTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _metodo2FASeleccionado = 1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _metodo2FASeleccionado == 1 ? BankTheme.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: _metodo2FASeleccionado == 1 ? Border.all(color: BankTheme.primary.withOpacity(0.5)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 16,
                      color: _metodo2FASeleccionado == 1 ? BankTheme.cyanAccent : BankTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Correo Electrónico',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _metodo2FASeleccionado == 1 ? Colors.white : BankTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetodoGoogleAuth(AuthProvider auth) {
    final debeMostrarQr = auth.primerRegistro2FA || _mostrarQrForzado;

    if (!debeMostrarQr) {
      // PANTALLA LIMPIA DE BANCO: SOLO PIDE EL CODIGO DINAMICO
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: BankTheme.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BankTheme.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: BankTheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.phonelink_lock_rounded, color: BankTheme.cyanAccent, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Google Authenticator',
                        style: TextStyle(color: BankTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Abre tu aplicacin autenticadora e ingresa el cdigo dinmico de 6 dgitos.',
                        style: TextStyle(color: BankTheme.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _mostrarQrForzado = true),
                icon: const Icon(Icons.qr_code_2_rounded, size: 14, color: BankTheme.textMuted),
                label: const Text(
                  'Cambiaste de telfono? Ver cdigo QR',
                  style: TextStyle(color: BankTheme.textMuted, fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // SI ES PRIMERA VEZ (ENROLAMIENTO), MUESTRA EL ASISTENTE CON EL QR
    final otpAuthUrl = auth.otpAuthUrl ?? '';
    final totpSecret = auth.totpSecret ?? '';
    final qrImageUrl = otpAuthUrl.isNotEmpty
        ? 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data='
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BankTheme.border, width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: BankTheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded, color: BankTheme.cyanAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vincula Google Authenticator',
                      style: TextStyle(color: BankTheme.textMain, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Escanea el cdigo QR desde tu app autenticadora',
                      style: TextStyle(color: BankTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (qrImageUrl != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                qrImageUrl,
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        width: 140,
                        height: 140,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 140,
                  height: 140,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 14),

          if (totpSecret.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: BankTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BankTheme.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key_rounded, size: 14, color: BankTheme.cyanAccent),
                  const SizedBox(width: 8),
                  Text(
                    'Clave: ',
                    style: const TextStyle(
                      color: BankTheme.cyanAccent,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: totpSecret));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clave secreta copiada al portapapeles'),
                          backgroundColor: BankTheme.primary,
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.copy_rounded, size: 14, color: BankTheme.textMuted),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetodoSmsOtp(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BankTheme.emeraldSuccess.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mark_email_read_rounded, color: BankTheme.emeraldSuccess, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cdigo por SMS o Correo',
                      style: TextStyle(color: BankTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enviamos un cdigo temporal a su nmero .',
                      style: const TextStyle(color: BankTheme.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vlido por 3 minutos',
                style: TextStyle(color: BankTheme.textMuted, fontSize: 11),
              ),
              TextButton.icon(
                onPressed: auth.isLoading ? null : _solicitarReenvioCorreo,
                icon: const Icon(Icons.refresh_rounded, size: 14, color: BankTheme.cyanAccent),
                label: const Text(
                  'Reenviar cdigo',
                  style: TextStyle(color: BankTheme.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
