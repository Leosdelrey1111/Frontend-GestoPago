import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_toast.dart';
import '../providers/auth_provider.dart';

enum _MetodoVerificacion { app, correo }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const int _segundosEntreEnvios = 60;

  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _mostrarPasoOtp = false;
  bool _obscurePassword = true;
  bool _codigoCorreoEnviado = false;
  int _segundosRestantes = 0;
  Timer? _temporizador;
  _MetodoVerificacion? _metodoElegido;

  @override
  void dispose() {
    _temporizador?.cancel();
    _correoController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _reiniciarPasoVerificacion() {
    _temporizador?.cancel();
    _otpController.clear();
    _codigoCorreoEnviado = false;
    _segundosRestantes = 0;
    _metodoElegido = null;
  }

  void _elegirMetodo(_MetodoVerificacion metodo) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    auth.limpiarError();
    setState(() {
      _metodoElegido = metodo;
      _otpController.clear();
    });

    if (metodo == _MetodoVerificacion.correo && !_codigoCorreoEnviado && _segundosRestantes <= 0) {
      await _enviarCodigoPorCorreo();
    }
  }

  void _volverASelectorMetodo() {
    Provider.of<AuthProvider>(context, listen: false).limpiarError();
    setState(() {
      _metodoElegido = null;
      _otpController.clear();
    });
  }

  void _iniciarCuentaRegresiva() {
    _temporizador?.cancel();
    setState(() => _segundosRestantes = _segundosEntreEnvios);
    _temporizador = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _segundosRestantes--;
        if (_segundosRestantes <= 0) t.cancel();
      });
    });
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
        _reiniciarPasoVerificacion();
        _mostrarPasoOtp = true;
      });
    } else if (auth.isAuthenticated && mounted) {
      _irAlInicio(auth);
    }
  }

  void _irAlInicio(AuthProvider auth) {
    Navigator.pushReplacementNamed(
      context,
      auth.tienePinConfigurado ? '/home' : '/configurar-pin',
    );
  }

  Future<void> _enviarCodigoPorCorreo() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.reenviarCodigoCorreo();
    if (!mounted) return;
    if (exito) {
      setState(() => _codigoCorreoEnviado = true);
      _iniciarCuentaRegresiva();
      _mostrarMensaje('Código enviado a ${auth.correoEnmascarado ?? 'su correo registrado'}.', BankTheme.emeraldSuccess);
    }
  }

  void _enviarOtp() async {
    if (_otpController.text.length != 6) {
      _mostrarMensaje('Ingresa los 6 dígitos del código de seguridad.', BankTheme.danger);
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final exito = await auth.verificarOtp(_otpController.text.trim());
    if (exito && mounted) {
      _irAlInicio(auth);
    }
  }

  void _mostrarMensaje(String texto, Color color) {
    ToastTipo tipo = ToastTipo.info;
    String titulo = 'Notificación';
    if (color == BankTheme.danger) {
      tipo = ToastTipo.error;
      titulo = 'Error de Autenticación';
    } else if (color == BankTheme.emeraldSuccess) {
      tipo = ToastTipo.exito;
      titulo = 'Operación Exitosa';
    } else if (color == BankTheme.warning) {
      tipo = ToastTipo.advertencia;
      titulo = 'Atención';
    }
    BankToast.mostrar(
      context,
      titulo: titulo,
      mensaje: texto,
      tipo: tipo,
    );
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
          colors: [Color(0xFF0F2027), Color(0xFF1B2E3D), Color(0xFF0A192F)],
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
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            'Pasarela transaccional corporativa y ecosistema de pagos en tiempo real.',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 36),
          _buildFeaturePill(Icons.verified_user_rounded, 'Verificación en dos pasos (TOTP / correo)'),
          const SizedBox(height: 14),
          _buildFeaturePill(Icons.phonelink_lock_rounded, 'Una sola sesión activa por usuario'),
          const SizedBox(height: 14),
          _buildFeaturePill(Icons.shield_rounded, 'Operaciones protegidas con PIN e idempotencia'),
        ],
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: BankTheme.cyanAccent, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoracionCampo({String? hint, IconData? icono, Widget? sufijo, Color? colorFoco}) {
    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: BankTheme.border),
    );
    return InputDecoration(
      prefixIcon: icono != null ? Icon(icono, color: BankTheme.primary, size: 20) : null,
      suffixIcon: sufijo,
      hintText: hint,
      hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
      filled: true,
      fillColor: BankTheme.background,
      border: borde,
      enabledBorder: borde,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colorFoco ?? BankTheme.primary, width: 1.5),
      ),
    );
  }

  Widget _buildFormSide(AuthProvider auth) {
    String titulo = 'Acceso bancario';
    String subtitulo = 'Ingresa tus credenciales para continuar';
    if (_mostrarPasoOtp) {
      titulo = 'Verificación de identidad';
      subtitulo = _metodoElegido == null
          ? 'Elige cómo quieres verificar tu cuenta'
          : (_metodoElegido == _MetodoVerificacion.app
              ? 'Ingresa el código generado en tu aplicación'
              : 'Ingresa el código enviado a tu correo');
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(color: BankTheme.textMain, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(subtitulo, style: const TextStyle(color: BankTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 24),
            if (auth.errorMessage != null) _buildBannerError(auth.errorMessage!),
            if (!_mostrarPasoOtp)
              ..._buildPasoCredenciales(auth)
            else if (_metodoElegido == null)
              ..._buildSelectorOpciones2FA(auth)
            else
              ..._buildPasoCodigo2FA(auth),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerError(String mensaje) {
    return Container(
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
            child: Text(mensaje, style: const TextStyle(color: BankTheme.danger, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPasoCredenciales(AuthProvider auth) {
    return [
      const Text('Correo electrónico', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _correoController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
        decoration: _decoracionCampo(hint: 'nombre@correo.com', icono: Icons.email_outlined),
        validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
      ),
      const SizedBox(height: 16),
      const Text('Contraseña', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 6),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
        decoration: _decoracionCampo(
          icono: Icons.lock_outline_rounded,
          sufijo: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: BankTheme.textHint,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
      ),
      const SizedBox(height: 26),
      _botonPrincipal(
        texto: 'Iniciar sesión',
        color: BankTheme.primary,
        cargando: auth.isLoading,
        onPressed: _enviarLogin,
      ),
      const SizedBox(height: 20),
      Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('¿Aún no tienes cuenta?', style: TextStyle(color: BankTheme.textMuted, fontSize: 13)),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/registro'),
              child: const Text(
                'Crear cuenta',
                style: TextStyle(color: BankTheme.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Paso 2A: Selector estilo Google con las opciones disponibles antes de ejecutar ningún método.
  List<Widget> _buildSelectorOpciones2FA(AuthProvider auth) {
    final destinoCorreo = auth.correoEnmascarado ?? 'tu correo registrado';
    return [
      _opcionVerificacionCard(
        icono: Icons.security_rounded,
        color: BankTheme.cyanAccent,
        titulo: 'Google Authenticator',
        subtitulo: auth.primerRegistro2FA
            ? 'Vincula tu app autenticadora escaneando el código QR.'
            : 'Obtén un código de verificación de 6 dígitos desde tu celular.',
        onTap: auth.isLoading ? null : () => _elegirMetodo(_MetodoVerificacion.app),
      ),
      const SizedBox(height: 14),
      _opcionVerificacionCard(
        icono: Icons.email_outlined,
        color: BankTheme.emeraldSuccess,
        titulo: 'Enviar código por correo electrónico',
        subtitulo: 'Recibe un código temporal de un solo uso en $destinoCorreo.',
        onTap: auth.isLoading ? null : () => _elegirMetodo(_MetodoVerificacion.correo),
      ),
      const SizedBox(height: 22),
      Center(
        child: TextButton(
          onPressed: () {
            auth.limpiarError();
            setState(() {
              _reiniciarPasoVerificacion();
              _mostrarPasoOtp = false;
            });
          },
          child: const Text('Volver al inicio de sesión', style: TextStyle(color: BankTheme.textMuted, fontSize: 12.5)),
        ),
      ),
    ];
  }

  Widget _opcionVerificacionCard({
    required IconData icono,
    required Color color,
    required String titulo,
    required String subtitulo,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: BankTheme.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BankTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(icono, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: const TextStyle(color: BankTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(subtitulo, style: const TextStyle(color: BankTheme.textMuted, fontSize: 12, height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: BankTheme.textMuted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  /// Paso 2B: Vista enfocada únicamente en el método elegido.
  List<Widget> _buildPasoCodigo2FA(AuthProvider auth) {
    final esApp = _metodoElegido == _MetodoVerificacion.app;
    return [
      esApp ? _buildMetodoApp(auth) : _buildMetodoCorreo(auth),
      const SizedBox(height: 22),
      const Text('Código de seguridad (6 dígitos)', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      TextFormField(
        controller: _otpController,
        maxLength: 6,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        style: const TextStyle(color: BankTheme.cyanAccent, fontSize: 26, letterSpacing: 14, fontWeight: FontWeight.w900),
        decoration: _decoracionCampo(hint: '••••••', colorFoco: BankTheme.cyanAccent).copyWith(
          counterText: '',
          hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 26, letterSpacing: 14),
        ),
        onFieldSubmitted: (_) => _enviarOtp(),
      ),
      const SizedBox(height: 22),
      _botonPrincipal(
        texto: 'Verificar y continuar',
        color: BankTheme.emeraldSuccess,
        cargando: auth.isLoading,
        onPressed: _enviarOtp,
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton.icon(
          onPressed: auth.isLoading ? null : _volverASelectorMetodo,
          icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: BankTheme.cyanAccent),
          label: const Text('Probar otro método de verificación', style: TextStyle(color: BankTheme.cyanAccent, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    ];
  }

  Widget _botonPrincipal({
    required String texto,
    required Color color,
    required bool cargando,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: cargando ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: cargando
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(texto, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold)),
      ),
    );
  }

  BoxDecoration get _decoracionTarjeta => BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankTheme.border),
      );

  Widget _encabezadoTarjeta({
    required IconData icono,
    required Color color,
    required String titulo,
    required String descripcion,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icono, color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: BankTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(descripcion, style: const TextStyle(color: BankTheme.textMuted, fontSize: 11.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetodoApp(AuthProvider auth) {
    if (!auth.primerRegistro2FA) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _decoracionTarjeta,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _encabezadoTarjeta(
              icono: Icons.phonelink_lock_rounded,
              color: BankTheme.cyanAccent,
              titulo: 'Google Authenticator',
              descripcion: 'Abre tu aplicación en el celular e ingresa el código de 6 dígitos para GestoPago Bank.',
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Cambiaste de teléfono? Solicita a un administrador el restablecimiento de tu token.',
              style: TextStyle(color: BankTheme.textHint, fontSize: 11),
            ),
          ],
        ),
      );
    }
    return _buildVinculacionQr(auth);
  }

  Widget _buildVinculacionQr(AuthProvider auth) {
    final otpAuthUrl = auth.otpAuthUrl ?? '';
    final totpSecret = auth.totpSecret ?? '';
    final qrImageUrl = otpAuthUrl.isNotEmpty
        ? 'https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${Uri.encodeComponent(otpAuthUrl)}'
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracionTarjeta,
      child: Column(
        children: [
          _encabezadoTarjeta(
            icono: Icons.qr_code_scanner_rounded,
            color: BankTheme.cyanAccent,
            titulo: 'Vincula tu app autenticadora',
            descripcion: '1. Abre Google Authenticator. 2. Escanea este QR. 3. Ingresa el código de 6 dígitos.',
          ),
          const SizedBox(height: 16),
          if (qrImageUrl != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Image.network(
                qrImageUrl,
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(width: 140, height: 140, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 140,
                  height: 140,
                  child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 40)),
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
                  Flexible(
                    child: Text(
                      'Clave manual: $totpSecret',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: BankTheme.cyanAccent, fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: totpSecret));
                      _mostrarMensaje('Clave copiada al portapapeles.', BankTheme.primary);
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
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

  Widget _buildMetodoCorreo(AuthProvider auth) {
    final destino = auth.correoEnmascarado ?? 'tu correo registrado';
    final puedeReenviar = !auth.isLoading && _segundosRestantes <= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _decoracionTarjeta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _encabezadoTarjeta(
            icono: Icons.mark_email_read_rounded,
            color: BankTheme.emeraldSuccess,
            titulo: 'Código por correo electrónico',
            descripcion: _codigoCorreoEnviado
                ? 'Enviamos un código de 6 dígitos a $destino (vigencia de 3 minutos).'
                : 'Solicitando código de verificación para $destino...',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: puedeReenviar ? _enviarCodigoPorCorreo : null,
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: Text(
                _segundosRestantes > 0 ? 'Reenviar en ${_segundosRestantes}s' : 'Reenviar código',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
