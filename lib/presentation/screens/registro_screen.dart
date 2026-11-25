import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/widgets/bank_select_field.dart';
import '../../core/widgets/bank_date_picker_dialog.dart';
import '../../data/services/api_service.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  int _currentStep = 0; // 0: Personal, 1: Fiscal y Contacto, 2: Domicilio y Seguridad

  final _formKeyStep0 = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  // Paso 0: Datos Personales
  final _nombreController = TextEditingController();
  final _segundoNombreController = TextEditingController();
  final _apellidoPaternoController = TextEditingController();
  final _apellidoMaternoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  DateTime? _fechaNacimientoSeleccionada;
  String? _sexoSeleccionado;
  String? _estadoCivilSeleccionado;

  final _focusNombre = FocusNode();
  final _focusSegundoNombre = FocusNode();
  final _focusApellidoPaterno = FocusNode();
  final _focusApellidoMaterno = FocusNode();

  // Paso 1: Fiscal & Contacto
  final _curpController = TextEditingController();
  final _rfcController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _ocupacionController = TextEditingController();
  final _ingresoMensualController = TextEditingController();

  final _focusCurp = FocusNode();
  final _focusRfc = FocusNode();
  final _focusTelefono = FocusNode();
  final _focusCorreo = FocusNode();
  final _focusOcupacion = FocusNode();
  final _focusIngreso = FocusNode();

  bool _verificandoCorreo = false;
  String? _errorCorreoEnTiempoReal;
  String? _ultimoCorreoVerificado;

  // Paso 2: Domicilio y Claves
  final _codigoPostalController = TextEditingController();
  final _calleController = TextEditingController();
  final _numeroExteriorController = TextEditingController();
  final _numeroInteriorController = TextEditingController();
  final _coloniaController = TextEditingController();
  final _municipioController = TextEditingController();
  String? _estadoSeleccionado; // Sin valor por defecto

  final _focusCp = FocusNode();
  final _focusMunicipio = FocusNode();
  final _focusColonia = FocusNode();
  final _focusCalle = FocusNode();
  final _focusNumExt = FocusNode();
  final _focusNumInt = FocusNode();
  final _focusPass = FocusNode();
  final _focusConfirmPass = FocusNode();

  // Opciones de Sexo Oficial
  final List<BankSelectOption<String>> _opcionesSexo = const [
    BankSelectOption(value: 'MASCULINO', label: 'Masculino', icon: Icons.male_rounded),
    BankSelectOption(value: 'FEMENINO', label: 'Femenino', icon: Icons.female_rounded),
    BankSelectOption(value: 'PREFIERO_NO_DECIR', label: 'Prefiero no especificar', icon: Icons.transgender_rounded),
  ];

  // Opciones de Estado Civil
  final List<BankSelectOption<String>> _opcionesEstadoCivil = const [
    BankSelectOption(value: 'SOLTERO', label: 'Soltero(a)', icon: Icons.person_rounded),
    BankSelectOption(value: 'CASADO', label: 'Casado(a)', icon: Icons.favorite_rounded),
    BankSelectOption(value: 'UNION_LIBRE', label: 'Unión Libre', icon: Icons.group_rounded),
    BankSelectOption(value: 'DIVORCIADO', label: 'Divorciado(a)', icon: Icons.heart_broken_rounded),
    BankSelectOption(value: 'VIUDO', label: 'Viudo(a)', icon: Icons.shield_outlined),
  ];

  // Opciones de Ocupación Oficial
  final List<String> _catalogoOcupaciones = const [
    'Empleado Sector Privado',
    'Empleado Sector Público',
    'Profesionista Independiente',
    'Empresario / Negocio Propio',
    'Comerciante',
    'Estudiante',
    'Jubilado / Pensionado',
    'Hogar',
  ];

  // Colonias sugeridas del C.P.
  List<String> _coloniasSugeridas = [];
  bool _buscandoCp = false;

  // Catálogo oficial de municipios por Estado
  Map<String, List<String>> _catalogoMunicipios = {};
  List<String> _municipiosDisponibles = [];

  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirmPass = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  final List<Map<String, String>> _estadosMexico = [
    {'key': 'AGUASCALIENTES', 'nombre': 'Aguascalientes'},
    {'key': 'BAJA_CALIFORNIA', 'nombre': 'Baja California'},
    {'key': 'BAJA_CALIFORNIA_SUR', 'nombre': 'Baja California Sur'},
    {'key': 'CAMPECHE', 'nombre': 'Campeche'},
    {'key': 'CHIAPAS', 'nombre': 'Chiapas'},
    {'key': 'CHIHUAHUA', 'nombre': 'Chihuahua'},
    {'key': 'CIUDAD_DE_MEXICO', 'nombre': 'Ciudad de México'},
    {'key': 'COAHUILA', 'nombre': 'Coahuila'},
    {'key': 'COLIMA', 'nombre': 'Colima'},
    {'key': 'DURANGO', 'nombre': 'Durango'},
    {'key': 'ESTADO_DE_MEXICO', 'nombre': 'Estado de México'},
    {'key': 'GUANAJUATO', 'nombre': 'Guanajuato'},
    {'key': 'GUERRERO', 'nombre': 'Guerrero'},
    {'key': 'HIDALGO', 'nombre': 'Hidalgo'},
    {'key': 'JALISCO', 'nombre': 'Jalisco'},
    {'key': 'MICHOACAN', 'nombre': 'Michoacán'},
    {'key': 'MORELOS', 'nombre': 'Morelos'},
    {'key': 'NAYARIT', 'nombre': 'Nayarit'},
    {'key': 'NUEVO_LEON', 'nombre': 'Nuevo León'},
    {'key': 'OAXACA', 'nombre': 'Oaxaca'},
    {'key': 'PUEBLA', 'nombre': 'Puebla'},
    {'key': 'QUERETARO', 'nombre': 'Querétaro'},
    {'key': 'QUINTANA_ROO', 'nombre': 'Quintana Roo'},
    {'key': 'SAN_LUIS_POTOSI', 'nombre': 'San Luis Potosí'},
    {'key': 'SINALOA', 'nombre': 'Sinaloa'},
    {'key': 'SONORA', 'nombre': 'Sonora'},
    {'key': 'TABASCO', 'nombre': 'Tabasco'},
    {'key': 'TAMAULIPAS', 'nombre': 'Tamaulipas'},
    {'key': 'TLAXCALA', 'nombre': 'Tlaxcala'},
    {'key': 'VERACRUZ', 'nombre': 'Veracruz'},
    {'key': 'YUCATAN', 'nombre': 'Yucatán'},
    {'key': 'ZACATECAS', 'nombre': 'Zacatecas'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarCatalogoMunicipios();
  }

  Future<void> _cargarCatalogoMunicipios() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/estados_municipios.json');
      final Map<String, dynamic> rawMap = json.decode(jsonString);
      Map<String, List<String>> normalizado = {};

      rawMap.forEach((estadoNom, munList) {
        String key = _mapearEstado(estadoNom);
        List<String> list = (munList as List).map((m) => m.toString()).toList();
        normalizado[key] = list;
      });

      if (mounted) {
        setState(() {
          _catalogoMunicipios = normalizado;
          _actualizarMunicipiosDeEstado(_estadoSeleccionado);
        });
      }
    } catch (_) {}
  }

  void _actualizarMunicipiosDeEstado(String? estadoKey) {
    if (estadoKey == null) {
      setState(() {
        _municipiosDisponibles = [];
        _municipioController.clear();
      });
      return;
    }
    final list = _catalogoMunicipios[estadoKey] ?? [];
    setState(() {
      _municipiosDisponibles = list;
      if (list.isNotEmpty && !list.contains(_municipioController.text)) {
        _municipioController.text = list.first;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _segundoNombreController.dispose();
    _apellidoPaternoController.dispose();
    _apellidoMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _curpController.dispose();
    _rfcController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _ocupacionController.dispose();
    _ingresoMensualController.dispose();
    _calleController.dispose();
    _numeroExteriorController.dispose();
    _numeroInteriorController.dispose();
    _coloniaController.dispose();
    _municipioController.dispose();
    _codigoPostalController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    _focusNombre.dispose();
    _focusSegundoNombre.dispose();
    _focusApellidoPaterno.dispose();
    _focusApellidoMaterno.dispose();
    _focusCurp.dispose();
    _focusRfc.dispose();
    _focusTelefono.dispose();
    _focusCorreo.dispose();
    _focusOcupacion.dispose();
    _focusIngreso.dispose();
    _focusCp.dispose();
    _focusMunicipio.dispose();
    _focusColonia.dispose();
    _focusCalle.dispose();
    _focusNumExt.dispose();
    _focusNumInt.dispose();
    _focusPass.dispose();
    _focusConfirmPass.dispose();
    super.dispose();
  }

  Future<void> _consultarCodigoPostal(String cp) async {
    if (cp.length != 5) return;
    setState(() => _buscandoCp = true);

    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 4), receiveTimeout: const Duration(seconds: 4)));
      final response = await dio.get('https://zippopotam.us/mx/$cp');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final places = data['places'] as List? ?? [];

        if (places.isNotEmpty) {
          final firstPlace = places.first as Map<String, dynamic>;
          final stateRaw = (firstPlace['state'] ?? '').toString();

          // Mapear estado
          String estadoKey = _mapearEstado(stateRaw);
          List<String> colonias = [];
          for (var p in places) {
            String colName = (p['place name'] ?? '').toString();
            // Si viene una entrada tipo "Ciudad Dolores Hidalgo", es el municipio
            if (colName.toLowerCase().startsWith('ciudad ') && _municipioController.text.trim().isEmpty) {
              _municipioController.text = colName.substring(7).trim();
            }
            if (colName.isNotEmpty && !colonias.contains(colName)) {
              colonias.add(colName);
            }
          }

          setState(() {
            _estadoSeleccionado = estadoKey;
            _actualizarMunicipiosDeEstado(estadoKey);
            _coloniasSugeridas = colonias;
            if (colonias.isNotEmpty) {
              _coloniaController.text = colonias.first;
            }
          });
        }
      }
    } catch (_) {
      // Si la consulta externa falla o no existe el CP, el usuario llena libremente sus campos
    } finally {
      if (mounted) setState(() => _buscandoCp = false);
    }
  }

  String _mapearEstado(String stateStr) {
    String clean = stateStr.toUpperCase()
        .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
        .replaceAll('DISTRITO FEDERAL', 'CIUDAD_DE_MEXICO')
        .replaceAll('CDMX', 'CIUDAD_DE_MEXICO')
        .replaceAll('MEXICO', 'ESTADO_DE_MEXICO')
        .replaceAll(' ', '_');

    for (var est in _estadosMexico) {
      if (clean.contains(est['key']!) || est['key']!.contains(clean)) {
        return est['key']!;
      }
    }
    return 'CIUDAD_DE_MEXICO';
  }

  Future<void> _seleccionarFechaNacimiento(BuildContext btnCtx) async {
    final DateTime maxDate = DateTime.now().subtract(const Duration(days: 365 * 18));
    final DateTime initialDate = _fechaNacimientoSeleccionada ?? maxDate;
    final DateTime minDate = DateTime(1920, 1, 1);

    final DateTime? picked = await BankDatePickerDialog.show(
      anchorContext: btnCtx,
      initialDate: initialDate.isAfter(maxDate) ? maxDate : initialDate,
      firstDate: minDate,
      lastDate: maxDate,
      title: 'Fecha de Nacimiento (Mayor de 18)',
    );

    if (picked != null) {
      setState(() {
        _fechaNacimientoSeleccionada = picked;
        _fechaNacimientoController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _verificarCorreoEnBackend(String correo) async {
    final emailNorm = correo.trim().toLowerCase();
    final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9-]+\.)+([a-zA-Z]{2,6})$');
    if (emailNorm.isEmpty || !emailRegex.hasMatch(emailNorm)) {
      return;
    }
    if (_ultimoCorreoVerificado == emailNorm) return;

    setState(() => _verificandoCorreo = true);
    try {
      final disponible = await _apiService.verificarCorreoDisponible(emailNorm);
      _ultimoCorreoVerificado = emailNorm;
      if (!disponible && mounted) {
        setState(() {
          _errorCorreoEnTiempoReal = 'Este correo electrónico ya se encuentra registrado';
        });
      } else if (mounted) {
        setState(() {
          _errorCorreoEnTiempoReal = null;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _verificandoCorreo = false);
    }
  }

  void _avanzarPaso() async {
    setState(() => _errorMessage = null);
    if (_currentStep == 0) {
      final formValid = _formKeyStep0.currentState!.validate();
      if (!formValid) return;
      if (_sexoSeleccionado == null) {
        setState(() => _errorMessage = 'Por favor selecciona tu sexo');
        return;
      }
      if (_estadoCivilSeleccionado == null) {
        setState(() => _errorMessage = 'Por favor selecciona tu estado civil');
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      final formValid = _formKeyStep1.currentState!.validate();
      if (!formValid) return;

      final correo = _correoController.text.trim().toLowerCase();
      setState(() => _verificandoCorreo = true);
      try {
        final disponible = await _apiService.verificarCorreoDisponible(correo);
        _ultimoCorreoVerificado = correo;
        if (!disponible) {
          setState(() {
            _errorCorreoEnTiempoReal = 'El correo electrónico ya se encuentra registrado';
            _verificandoCorreo = false;
          });
          return;
        }
      } catch (_) {
      } finally {
        if (mounted) setState(() => _verificandoCorreo = false);
      }

      if (_errorCorreoEnTiempoReal != null) return;
      setState(() => _currentStep = 2);
    }
  }

  void _retrocederPaso() {
    if (_currentStep > 0) {
      setState(() {
        _errorMessage = null;
        _currentStep--;
      });
    }
  }

  void _ejecutarRegistroFinal() async {
    if (!_formKeyStep2.currentState!.validate()) return;

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
        fechaNacimiento: _fechaNacimientoController.text.trim(),
        curp: _curpController.text.trim().toUpperCase(),
        rfc: _rfcController.text.trim().toUpperCase(),
        correo: _correoController.text.trim().toLowerCase(),
        telefono: _telefonoController.text.trim(),
        sexo: _sexoSeleccionado,
        estadoCivil: _estadoCivilSeleccionado,
        ocupacion: _ocupacionController.text.trim().isNotEmpty ? _ocupacionController.text.trim() : null,
        ingresoMensual: double.tryParse(_ingresoMensualController.text.trim()),
        calle: _calleController.text.trim(),
        numeroExterior: _numeroExteriorController.text.trim(),
        numeroInterior: _numeroInteriorController.text.trim().isNotEmpty
            ? _numeroInteriorController.text.trim()
            : null,
        colonia: _coloniaController.text.trim(),
        municipio: _municipioController.text.trim(),
        estado: _estadoSeleccionado ?? 'CIUDAD_DE_MEXICO',
        codigoPostal: int.parse(_codigoPostalController.text.trim()),
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
                  'Bienvenido/a ${_nombreController.text.trim()}. Tu cuenta digital y expediente bancario han sido registrados satisfactoriamente.',
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
                      _buildRowResumen('Tarjeta:', 'Débito Digital Activa', valorColor: BankTheme.emeraldSuccess),
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

  Widget _buildStepIndicator() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepCircle(0, '1', 'Personal'),
            _buildStepLine(0),
            _buildStepCircle(1, '2', 'Identidad'),
            _buildStepLine(1),
            _buildStepCircle(2, '3', 'Domicilio'),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStepCircle(int stepIndex, String number, String label) {
    final bool isDone = _currentStep > stepIndex;
    final bool isActive = _currentStep == stepIndex;

    Color circleColor = BankTheme.surfaceElevated;
    Color textColor = BankTheme.textHint;
    Border? border = Border.all(color: BankTheme.border);

    if (isActive) {
      circleColor = BankTheme.primary;
      textColor = Colors.white;
      border = Border.all(color: BankTheme.cyanAccent, width: 1.5);
    } else if (isDone) {
      circleColor = BankTheme.emeraldSuccess;
      textColor = Colors.white;
      border = null;
    }

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
            border: border,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(number, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? BankTheme.cyanAccent : (isDone ? BankTheme.textMain : BankTheme.textHint),
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int leftStep) {
    final bool isPassed = _currentStep > leftStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 6, right: 6),
        height: 2,
        color: isPassed ? BankTheme.emeraldSuccess : BankTheme.border,
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
          onPressed: () {
            if (_currentStep > 0) {
              _retrocederPaso();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: BankTheme.modalShadow,
            ),
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
                          Text('Proceso de Onboarding Oficial KYC', style: TextStyle(color: BankTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                _buildStepIndicator(),

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

                // Contenido del paso actual ajustado exactamente a la altura de su contenido
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey<int>(_currentStep),
                    child: _currentStep == 0
                        ? _buildStep0Personal()
                        : _currentStep == 1
                            ? _buildStep1FiscalYContacto()
                            : _buildStep2DomicilioYSeguridad(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PASO 0: DATOS PERSONALES
  Widget _buildStep0Personal() {
    return Form(
      key: _formKeyStep0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('PASO 1 DE 3: DATOS PERSONALES', Icons.person_outline_rounded),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  'Primer Nombre *',
                  _nombreController,
                  Icons.badge_outlined,
                  focusNode: _focusNombre,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusSegundoNombre),
                  maxLength: 40,
                  hintText: 'Ej. Juan',
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
                  focusNode: _focusSegundoNombre,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusApellidoPaterno),
                  maxLength: 40,
                  hintText: 'Ej. Carlos (Opc.)',
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
                  focusNode: _focusApellidoPaterno,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusApellidoMaterno),
                  maxLength: 40,
                  hintText: 'Ej. Pérez',
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
                  focusNode: _focusApellidoMaterno,
                  textInputAction: TextInputAction.done,
                  maxLength: 40,
                  hintText: 'Ej. López',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    if (v.trim().length < 3) return 'Mín. 3 caracteres';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Fecha de nacimiento personalizada integrada en el Form
          FormField<String>(
            validator: (_) {
              if (_fechaNacimientoController.text.trim().isEmpty) {
                return 'Requerido';
              }
              return null;
            },
            builder: (fieldState) {
              final hasError = fieldState.hasError;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Fecha de Nacimiento (Mayor de 18 años) *', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (dateBtnCtx) => InkWell(
                      onTap: () async {
                        await _seleccionarFechaNacimiento(dateBtnCtx);
                        fieldState.didChange(_fechaNacimientoController.text);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: BankTheme.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasError ? BankTheme.danger : BankTheme.border,
                            width: hasError ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_month_outlined, color: hasError ? BankTheme.danger : BankTheme.primary, size: 19),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _fechaNacimientoController.text.isNotEmpty
                                    ? _fechaNacimientoController.text
                                    : 'Ej. 1998-05-14',
                                style: TextStyle(
                                  color: _fechaNacimientoController.text.isNotEmpty
                                      ? BankTheme.textMain
                                      : BankTheme.textHint,
                                  fontSize: 13.5,
                                  fontWeight: _fechaNacimientoController.text.isNotEmpty
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(Icons.event_available_rounded, color: hasError ? BankTheme.danger : BankTheme.cyanAccent, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, left: 4),
                      child: Text(
                        fieldState.errorText ?? 'Requerido',
                        style: const TextStyle(color: BankTheme.danger, fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Sexo y Estado Civil mediante catálogos oficiales
          Row(
            children: [
              Expanded(
                child: BankSelectField<String>(
                  label: 'Sexo *',
                  value: _sexoSeleccionado,
                  prefixIcon: Icons.wc_rounded,
                  options: _opcionesSexo,
                  onChanged: (val) {
                    setState(() => _sexoSeleccionado = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BankSelectField<String>(
                  label: 'Estado Civil *',
                  value: _estadoCivilSeleccionado,
                  prefixIcon: Icons.favorite_border_rounded,
                  options: _opcionesEstadoCivil,
                  onChanged: (val) {
                    setState(() => _estadoCivilSeleccionado = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _avanzarPaso,
              style: ElevatedButton.styleFrom(
                backgroundColor: BankTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Continuar a Identidad Oficial', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // PASO 1: FISCAL & CONTACTO
  Widget _buildStep1FiscalYContacto() {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('PASO 2 DE 3: IDENTIDAD FISCAL Y CONTACTO', Icons.verified_user_outlined),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  'CURP (18 caracteres) *',
                  _curpController,
                  Icons.fingerprint_rounded,
                  focusNode: _focusCurp,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusRfc),
                  maxLength: 18,
                  hintText: 'Ej. HEDB000514HGT...',
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
                  focusNode: _focusRfc,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusTelefono),
                  maxLength: 13,
                  hintText: 'Ej. HEDB0005141A0',
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

          _buildInput(
            'Teléfono Móvil (10 dígitos) *',
            _telefonoController,
            Icons.phone_android_rounded,
            focusNode: _focusTelefono,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusCorreo),
            maxLength: 10,
            hintText: 'Ej. 5512345678',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (v.trim().length != 10) return 'Exactamente 10 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 14),

          _buildInput(
            'Correo Electrónico *',
            _correoController,
            Icons.email_outlined,
            focusNode: _focusCorreo,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusOcupacion),
            maxLength: 60,
            hintText: 'Ej. usuario@dominio.com',
            keyboardType: TextInputType.emailAddress,
            onChanged: (val) {
              if (_errorCorreoEnTiempoReal != null) {
                setState(() => _errorCorreoEnTiempoReal = null);
              }
              if (val.contains('@') && val.contains('.')) {
                _verificarCorreoEnBackend(val.trim());
              }
            },
            suffixIcon: _verificandoCorreo
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: BankTheme.cyanAccent),
                    ),
                  )
                : null,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'El correo es requerido';
              final clean = v.trim().toLowerCase();
              final emailRegex = RegExp(r'^[a-zA-Z0-9_.+-]+@([a-zA-Z0-9-]+\.)+([a-zA-Z]{2,6})$');
              if (!emailRegex.hasMatch(clean)) {
                return 'Formato inválido (ej. usuario@gmail.com)';
              }
              final parts = clean.split('@');
              if (parts.length == 2) {
                final domainParts = parts[1].split('.');
                final tld = domainParts.last;
                if (tld.length < 2 || tld.length > 6) {
                  return 'Extensión de dominio inválida (.com, .mx, etc.)';
                }
              }
              if (_errorCorreoEnTiempoReal != null) {
                return _errorCorreoEnTiempoReal;
              }
              return null;
            },
          ),
          const SizedBox(height: 14),

          // Ocupación e Ingreso Mensual
          Row(
            children: [
              Expanded(
                flex: 3,
                child: BankSelectField<String>(
                  label: 'Ocupación *',
                  value: _catalogoOcupaciones.contains(_ocupacionController.text)
                      ? _ocupacionController.text
                      : null,
                  prefixIcon: Icons.work_outline_rounded,
                  options: _catalogoOcupaciones.map((o) {
                    return BankSelectOption<String>(
                      value: o,
                      label: o,
                      icon: Icons.business_center_rounded,
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _ocupacionController.text = val);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildInput(
                  'Ingreso (\$ MXN) *',
                  _ingresoMensualController,
                  Icons.attach_money_rounded,
                  focusNode: _focusIngreso,
                  textInputAction: TextInputAction.done,
                  maxLength: 9,
                  hintText: '15000',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    final num = double.tryParse(v.trim());
                    if (num == null || num <= 0) return '> \$0';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Row(
            children: [
              OutlinedButton(
                onPressed: _retrocederPaso,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BankTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: const Text('Atrás', style: TextStyle(color: BankTheme.textMuted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _avanzarPaso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BankTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continuar a Domicilio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PASO 2: DOMICILIO Y SEGURIDAD (CON AUTO-COMPLETADO INTELIGENTE DE C.P.)
  Widget _buildStep2DomicilioYSeguridad() {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('PASO 3 DE 3: DOMICILIO Y ACCESO', Icons.home_work_outlined),

          // Código Postal con Auto-Detección
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('C.P. (5 dígitos) *', style: TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _codigoPostalController,
                      focusNode: _focusCp,
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusMunicipio),
                      maxLength: 5,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(5)],
                      style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
                      decoration: InputDecoration(
                        counterText: '',
                        prefixIcon: const Icon(Icons.markunread_mailbox_outlined, color: BankTheme.primary, size: 19),
                        suffixIcon: _buscandoCp
                            ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: BankTheme.cyanAccent)))
                            : null,
                        hintText: 'Ej. 03100',
                        hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
                        filled: true,
                        fillColor: BankTheme.background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) {
                        if (val.trim().length == 5) {
                          _consultarCodigoPostal(val.trim());
                        }
                      },
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Requerido';
                        if (v.trim().length != 5) return '5 dígitos';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: BankSelectField<String>(
                  label: 'Estado *',
                  value: _estadoSeleccionado,
                  prefixIcon: Icons.map_outlined,
                  options: _estadosMexico.map((e) {
                    return BankSelectOption<String>(
                      value: e['key']!,
                      label: e['nombre']!,
                      icon: Icons.location_city_rounded,
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _estadoSeleccionado = val;
                      _actualizarMunicipiosDeEstado(val);
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Municipio y Colonia
          Row(
            children: [
              Expanded(
                child: _municipiosDisponibles.isNotEmpty
                    ? BankSelectField<String>(
                        label: 'Alcaldía / Municipio *',
                        value: _municipiosDisponibles.contains(_municipioController.text)
                            ? _municipioController.text
                            : _municipiosDisponibles.first,
                        prefixIcon: Icons.location_city_rounded,
                        options: _municipiosDisponibles.map((m) {
                          return BankSelectOption<String>(
                            value: m,
                            label: m,
                            icon: Icons.apartment_rounded,
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _municipioController.text = val);
                        },
                      )
                    : _buildInput(
                        'Alcaldía / Municipio *',
                        _municipioController,
                        Icons.location_city_rounded,
                        focusNode: _focusMunicipio,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusCalle),
                        maxLength: 50,
                        hintText: 'Ej. Benito Juárez',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _coloniasSugeridas.isNotEmpty
                    ? BankSelectField<String>(
                        label: 'Colonia *',
                        value: _coloniasSugeridas.contains(_coloniaController.text)
                            ? _coloniaController.text
                            : _coloniasSugeridas.first,
                        prefixIcon: Icons.location_on_outlined,
                        options: _coloniasSugeridas.map((col) {
                          return BankSelectOption<String>(
                            value: col,
                            label: col,
                            icon: Icons.home_rounded,
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _coloniaController.text = val);
                        },
                      )
                    : _buildInput(
                        'Colonia *',
                        _coloniaController,
                        Icons.location_on_outlined,
                        focusNode: _focusColonia,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusCalle),
                        maxLength: 50,
                        hintText: 'Ej. Del Valle',
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Calle y Números
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildInput(
                  'Calle *',
                  _calleController,
                  Icons.signpost_outlined,
                  focusNode: _focusCalle,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusNumExt),
                  maxLength: 80,
                  hintText: 'Ej. Av. Insurgentes Sur',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInput(
                  'Num. Ext. *',
                  _numeroExteriorController,
                  null, // Sin icono interior para dar 100% de espacio al número
                  focusNode: _focusNumExt,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusNumInt),
                  maxLength: 10,
                  hintText: '123',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requerido';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _buildInput(
                  'Num. Int.',
                  _numeroInteriorController,
                  null, // Sin icono interior para dar 100% de espacio al número
                  focusNode: _focusNumInt,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusPass),
                  maxLength: 10,
                  hintText: '4B (Opc.)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Contraseña con validación en vivo
          _buildInput(
            'Contraseña de Acceso (8-12 car.) *',
            _passwordController,
            Icons.lock_outline_rounded,
            focusNode: _focusPass,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: () => FocusScope.of(context).requestFocus(_focusConfirmPass),
            maxLength: 12,
            hintText: 'Ej. Pass#2026',
            obscureText: _obscurePass,
            onChanged: (val) => setState(() {}),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: BankTheme.textHint, size: 20),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'La contraseña es requerida';
              if (v.length < 8 || v.length > 12) return 'Debe tener entre 8 y 12 caracteres';
              if (!RegExp(r'^(?=.*[0-9])(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=!._\-*]).*$').hasMatch(v)) {
                return 'No cumple con todos los requisitos de seguridad';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // Chips de validación en vivo de contraseña
          _buildPasswordRequirementsIndicator(_passwordController.text),
          const SizedBox(height: 14),

          _buildInput(
            'Confirmar Contraseña *',
            _confirmPasswordController,
            Icons.lock_reset_rounded,
            focusNode: _focusConfirmPass,
            textInputAction: TextInputAction.done,
            maxLength: 12,
            hintText: 'Repite tu contraseña',
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

          Row(
            children: [
              OutlinedButton(
                onPressed: _retrocederPaso,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: BankTheme.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
                child: const Text('Atrás', style: TextStyle(color: BankTheme.textMuted)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _ejecutarRegistroFinal,
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: BankTheme.cyanAccent, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: BankTheme.cyanAccent,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordRequirementsIndicator(String pass) {
    final hasMinLength = pass.length >= 8 && pass.length <= 12;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
    final hasLower = RegExp(r'[a-z]').hasMatch(pass);
    final hasDigit = RegExp(r'[0-9]').hasMatch(pass);
    final hasSymbol = RegExp(r'[@#$%^&+=!._\-*]').hasMatch(pass);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: BankTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: BankTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos de seguridad (8-12 car.):',
            style: TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildReqChip('8-12 caracteres', hasMinLength),
              _buildReqChip('Mayúscula (A-Z)', hasUpper),
              _buildReqChip('Minúscula (a-z)', hasLower),
              _buildReqChip('Número (0-9)', hasDigit),
              _buildReqChip('Símbolo (@,#,\$, etc.)', hasSymbol),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReqChip(String label, bool cumplido) {
    final color = cumplido ? BankTheme.emeraldSuccess : BankTheme.textHint;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          cumplido ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 13,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: cumplido ? BankTheme.textMain : BankTheme.textHint,
            fontSize: 10.5,
            fontWeight: cumplido ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller,
    IconData? icon, {
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    int? maxLength,
    String? hintText,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    TextInputAction? textInputAction,
    VoidCallback? onFieldSubmitted,
  }) {
    List<TextInputFormatter> formatters = [];
    if (maxLength != null) {
      formatters.add(LengthLimitingTextInputFormatter(maxLength));
    }
    if (inputFormatters != null) {
      formatters.addAll(inputFormatters);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: BankTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textInputAction: textInputAction ?? TextInputAction.next,
          onFieldSubmitted: onFieldSubmitted != null ? (_) => onFieldSubmitted() : null,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          inputFormatters: formatters,
          onChanged: onChanged,
          style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: icon != null
                ? Container(
                    width: 38,
                    alignment: Alignment.center,
                    child: Icon(icon, color: BankTheme.primary, size: 18),
                  )
                : null,
            prefixIconConstraints: icon != null ? const BoxConstraints(minWidth: 38, minHeight: 44) : null,
            suffixIcon: suffixIcon,
            hintText: hintText,
            hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
            errorMaxLines: 2,
            filled: true,
            fillColor: BankTheme.background,
            contentPadding: EdgeInsets.symmetric(
              horizontal: icon != null ? 10 : 12,
              vertical: 13,
            ),
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
