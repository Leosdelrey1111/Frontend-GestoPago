import 'dart:async' as timer_pkg;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/bank_theme.dart';
import '../../core/utils/responsive_layout.dart';
import '../../data/models/api_models.dart';
import '../providers/auth_provider.dart';
import '../providers/pago_provider.dart';
import '../widgets/credit_card_widget.dart';
import '../widgets/pago_modal.dart';
import '../widgets/service_card_widget.dart';
import '../widgets/ticket_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _busquedaController = TextEditingController();
  String _filtroTexto = '';
  String _categoriaSeleccionada = 'TODOS';
  timer_pkg.Timer? _sesionHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pagoProvider = Provider.of<PagoProvider>(context, listen: false);
      pagoProvider.cargarCuentas();
      pagoProvider.cargarCatalogo();
      pagoProvider.cargarHistorial();
    });

    // Verificación periódica de sesión única cada 30 segundos para no saturar red ni BD
    _sesionHeartbeatTimer = timer_pkg.Timer.periodic(const Duration(seconds: 30), (_) async {
      if (!mounted) return;
      try {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        await auth.verificarSesionEnServidor();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _sesionHeartbeatTimer?.cancel();
    _tabController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }

  void _abrirModalPago(CatalogoProductoModel producto) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Consumer<PagoProvider>(
          builder: (dialogCtx, provider, child) {
            return PagoModal(
              producto: producto,
              cuentas: provider.cuentas,
              cuentaInicial: provider.cuentaSeleccionada,
              isProcessing: provider.isProcessingPago,
              onConfirmar: (numCuenta, idProd, idServ, ref, monto, pin) async {
                final resultado = await provider.ejecutarPago(
                  numeroCuenta: numCuenta,
                  idProducto: idProd,
                  idServicio: idServ,
                  telefonoOreferencia: ref,
                  monto: monto,
                  passwordOPin: pin,
                );

                if (!dialogCtx.mounted) return;
                Navigator.pop(dialogCtx);

                if (resultado != null && resultado.folioTransaccion != null) {
                  provider.cargarCuentas();
                  provider.cargarHistorial();
                  final ticket = await provider.obtenerTicket(resultado.folioTransaccion!);
                  if (ticket != null && mounted) {
                    showDialog(
                      context: context,
                      builder: (_) => TicketDialog(ticket: ticket),
                    );
                  }
                } else if (mounted) {
                  final msg = provider.errorMessage ?? 'No fue posible completar el pago.';
                  final esDuplicado = msg.toLowerCase().contains('igual') || msg.toLowerCase().contains('duplicad');
                  _mostrarToast(
                    esDuplicado ? 'Pago duplicado prevenido' : 'No se pudo completar el pago',
                    msg,
                    esAdvertencia: esDuplicado,
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  void _mostrarToast(String titulo, String mensaje, {bool esAdvertencia = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    final color = esAdvertencia ? BankTheme.warning : BankTheme.danger;
    final icono = esAdvertencia ? Icons.shield_outlined : Icons.error_outline_rounded;

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 24,
        right: 24,
        left: ResponsiveLayout.isMobile(ctx) ? 24 : null,
        child: Material(
          color: Colors.transparent,
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
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titulo,
                          style: const TextStyle(color: BankTheme.textMain, fontSize: 13.5, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mensaje,
                          style: const TextStyle(color: BankTheme.textMuted, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      if (entry.mounted) entry.remove();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded, color: BankTheme.textMuted, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 6), () {
      if (entry.mounted) entry.remove();
    });
  }

  void _verTicket(int folio) async {
    final provider = Provider.of<PagoProvider>(context, listen: false);
    final ticket = await provider.obtenerTicket(folio);
    if (ticket != null && mounted) {
      showDialog(
        context: context,
        builder: (_) => TicketDialog(ticket: ticket),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final pago = Provider.of<PagoProvider>(context);
    final isMobile = ResponsiveLayout.isMobile(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    final catalogoFiltrado = pago.catalogo.where((p) {
      final coincideTexto = _filtroTexto.isEmpty ||
          p.nombreProducto.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          p.servicio.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          p.idProducto.contains(_filtroTexto);

      if (!coincideTexto) return false;
      if (_categoriaSeleccionada == 'TODOS') return true;
      final serv = p.servicio.toUpperCase();
      if (_categoriaSeleccionada == 'TELEFONÍA') {
        return serv.contains('TELCEL') || serv.contains('MOVISTAR') || serv.contains('AT&T') || serv.contains('UNEFON') || serv.contains('BAIT') || serv.contains('ABIB');
      } else if (_categoriaSeleccionada == 'SERVICIOS') {
        return serv.contains('CFE') || serv.contains('AGUA') || serv.contains('GAS') || serv.contains('NATURGY');
      } else if (_categoriaSeleccionada == 'ENTRETENIMIENTO') {
        return serv.contains('NETFLIX') || serv.contains('SPOTIFY') || serv.contains('AMAZON') || serv.contains('DISNEY') || serv.contains('XBOX');
      } else if (_categoriaSeleccionada == 'INTERNET/TV') {
        return serv.contains('TELMEX') || serv.contains('TOTALPLAY') || serv.contains('IZZI') || serv.contains('SKY') || serv.contains('DISH');
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: BankTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopAppBar(auth, pago, isMobile),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1320 : 768),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 16 : 28,
                      vertical: isMobile ? 12 : 24,
                    ),
                    child: isDesktop
                        ? _buildDesktopLayout(auth, pago, catalogoFiltrado)
                        : _buildMobileLayout(auth, pago, catalogoFiltrado),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(AuthProvider auth, PagoProvider pago, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 14),
      decoration: BoxDecoration(
        color: BankTheme.surface,
        border: const Border(bottom: BorderSide(color: BankTheme.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: BankTheme.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: BankTheme.glowShadow(BankTheme.primary),
                ),
                child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GESTOPAGO BANK',
                    style: TextStyle(
                      color: BankTheme.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Portal Transaccional Corporativo • Cifrado AES-256',
                    style: TextStyle(
                      color: BankTheme.textMuted.withOpacity(0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Sincronizar saldo e historial',
                icon: const Icon(Icons.sync_rounded, color: BankTheme.textMuted, size: 22),
                onPressed: () {
                  pago.cargarCuentas();
                  pago.cargarCatalogo();
                  pago.cargarHistorial();
                },
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await auth.cerrarSesion();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 16, color: BankTheme.danger),
                label: isMobile
                    ? const SizedBox.shrink()
                    : const Text(
                        'Cerrar Sesión',
                        style: TextStyle(color: BankTheme.danger, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: BankTheme.danger.withOpacity(0.35)),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(AuthProvider auth, PagoProvider pago, List<CatalogoProductoModel> catalogo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CreditCardWidget(
                  cuenta: pago.cuentaSeleccionada,
                  userEmail: auth.userEmail ?? 'cliente@gestopago.com',
                ),
                const SizedBox(height: 18),
                _buildKpiSummary(pago),
                const SizedBox(height: 18),
                _buildSecurityBadge(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: Column(
            children: [
              _buildTabBarHeader(),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCatalogoTab(pago, catalogo, isMobile: false),
                    _buildHistorialTab(pago),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(AuthProvider auth, PagoProvider pago, List<CatalogoProductoModel> catalogo) {
    return Column(
      children: [
        CreditCardWidget(
          cuenta: pago.cuentaSeleccionada,
          userEmail: auth.userEmail ?? 'cliente@gestopago.com',
        ),
        const SizedBox(height: 14),
        _buildTabBarHeader(),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCatalogoTab(pago, catalogo, isMobile: true),
              _buildHistorialTab(pago),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarHeader() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: BankTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BankTheme.border),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: BankTheme.primary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: BankTheme.glowShadow(BankTheme.primary),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: BankTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 18),
                SizedBox(width: 8),
                Text('Catálogo de Pagos'),
              ],
            ),
          ),
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 18),
                SizedBox(width: 8),
                Text('Movimientos y Tickets'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiSummary(PagoProvider pago) {
    final saldo = pago.cuentaSeleccionada?.saldo ?? 0.0;
    final totalMovs = pago.historial.length;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: BankTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: BankTheme.border),
        boxShadow: BankTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Tesorería',
            style: TextStyle(color: BankTheme.textMain, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildKpiItem('Balance Total', '\$${saldo.toStringAsFixed(2)}', Icons.account_balance_wallet_outlined, BankTheme.cyanAccent),
              const SizedBox(width: 14),
              _buildKpiItem('Transacciones', '$totalMovs completadas', Icons.receipt_outlined, BankTheme.emeraldSuccess),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BankTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BankTheme.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(color: BankTheme.textMain, fontSize: 15, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: BankTheme.textMuted, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BankTheme.surfaceElevated.withOpacity(0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BankTheme.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock_rounded, color: BankTheme.emeraldSuccess, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesión Única Activa',
                  style: TextStyle(color: BankTheme.textMain, fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Respaldada en PostgreSQL con control de concurrencia e invalidación en vivo.',
                  style: TextStyle(color: BankTheme.textMuted, fontSize: 11, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogoTab(PagoProvider pago, List<CatalogoProductoModel> catalogo, {required bool isMobile}) {
    final categorias = ['TODOS', 'TELEFONÍA', 'SERVICIOS', 'INTERNET/TV', 'ENTRETENIMIENTO'];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: BankTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BankTheme.border),
          ),
          child: TextField(
            controller: _busquedaController,
            style: const TextStyle(color: BankTheme.textMain, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar servicio o proveedor (CFE, Telcel, Dish, ABIB, Izzi...)',
              hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: BankTheme.primary, size: 20),
              suffixIcon: _filtroTexto.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: BankTheme.textMuted, size: 18),
                      onPressed: () {
                        _busquedaController.clear();
                        setState(() => _filtroTexto = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onChanged: (val) => setState(() => _filtroTexto = val.trim()),
          ),
        ),

        // Filtro de Categorías
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, idx) {
              final cat = categorias[idx];
              final isSel = _categoriaSeleccionada == cat;
              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() => _categoriaSeleccionada = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel ? BankTheme.primary : BankTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel ? BankTheme.primaryLight : BankTheme.border,
                    ),
                    boxShadow: isSel ? BankTheme.glowShadow(BankTheme.primary) : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSel ? Colors.white : BankTheme.textMuted,
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Grid de Servicios
        Expanded(
          child: pago.isLoading && pago.catalogo.isEmpty
              ? const Center(child: CircularProgressIndicator(color: BankTheme.primary))
              : catalogo.isEmpty
                  ? const Center(
                      child: Text(
                        'No se encontraron servicios que coincidan con la búsqueda.',
                        style: TextStyle(color: BankTheme.textMuted, fontSize: 13),
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isMobile ? 2 : 4,
                        childAspectRatio: 0.88,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: catalogo.length,
                      itemBuilder: (_, index) {
                        final prod = catalogo[index];
                        return ServiceCardWidget(
                          producto: prod,
                          onTap: () => _abrirModalPago(prod),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildHistorialTab(PagoProvider pago) {
    if (pago.isLoading && pago.historial.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: BankTheme.primary));
    }
    if (pago.historial.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: BankTheme.textHint),
            SizedBox(height: 12),
            Text(
              'No hay transacciones registradas',
              style: TextStyle(color: BankTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: pago.historial.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, idx) {
        final tx = pago.historial[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BankTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BankTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: BankTheme.emeraldSuccess.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_outline, color: BankTheme.emeraldSuccess, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.producto,
                      style: const TextStyle(color: BankTheme.textMain, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Folio: #${tx.folio} • Aut: ${tx.numAutorizacion ?? "AUT-SIMULADA"}',
                      style: const TextStyle(color: BankTheme.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-\$${tx.monto.toStringAsFixed(2)} MXN',
                    style: const TextStyle(color: BankTheme.danger, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _verTicket(tx.folio),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: BankTheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.receipt_rounded, color: BankTheme.cyanAccent, size: 14),
                          SizedBox(width: 4),
                          Text('Ticket', style: TextStyle(color: BankTheme.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
