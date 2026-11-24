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
                  provider.cargarHistorial();
                  provider.cargarCuentas();
                  final msg = provider.errorMessage ?? 'No fue posible completar el pago.';
                  final esDuplicado = msg.toLowerCase().contains('igual') || msg.toLowerCase().contains('duplicad');
                  _mostrarToast(
                    esDuplicado ? 'Pago duplicado prevenido' : 'Pago rechazado por el proveedor',
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
      builder: (ctx) {
        final topPadding = MediaQuery.of(ctx).padding.top;
        return Positioned(
          top: topPadding + 10,
          right: ResponsiveLayout.isMobile(ctx) ? 16 : 24,
          left: ResponsiveLayout.isMobile(ctx) ? 16 : null,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: BankTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.65), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icono, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: BankTheme.textMain,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            mensaje,
                            style: const TextStyle(
                              color: BankTheme.textMuted,
                              fontSize: 11.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        if (entry.mounted) entry.remove();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded, color: BankTheme.textMuted, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 32,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: const BoxDecoration(
        color: BankTheme.surface,
        border: Border(bottom: BorderSide(color: BankTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 7 : 9),
            decoration: BoxDecoration(
              gradient: BankTheme.brandGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: BankTheme.glowShadow(BankTheme.primary),
            ),
            child: Icon(
              Icons.account_balance_rounded,
              color: Colors.white,
              size: isMobile ? 18 : 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GESTOPAGO BANK',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BankTheme.textMain,
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  isMobile ? 'Portal Móvil Seguro' : 'Portal Transaccional Corporativo • Cifrado AES-256',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: BankTheme.textMuted.withOpacity(0.8),
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded, size: 20, color: BankTheme.danger),
            style: IconButton.styleFrom(
              backgroundColor: BankTheme.danger.withOpacity(0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: BankTheme.danger.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.all(8),
            ),
            onPressed: () async {
              await auth.cerrarSesion();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankTheme.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0284C7).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: BankTheme.textMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.3),
        tabs: const [
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.grid_view_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Catálogo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Tab(
            iconMargin: EdgeInsets.zero,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_rounded, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Movimientos',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
            border: Border.all(color: BankTheme.border.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _busquedaController,
            style: const TextStyle(color: BankTheme.textMain, fontSize: 13.5),
            decoration: InputDecoration(
              hintText: 'Buscar por servicio, proveedor o producto...',
              hintStyle: const TextStyle(color: BankTheme.textHint, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: BankTheme.cyanAccent, size: 20),
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
                  : RefreshIndicator(
                      color: BankTheme.primary,
                      backgroundColor: BankTheme.surfaceElevated,
                      onRefresh: () async {
                        await Future.wait([
                          pago.cargarCuentas(),
                          pago.cargarCatalogo(),
                          pago.cargarHistorial(),
                        ]);
                      },
                      child: LayoutBuilder(
                        builder: (ctx, constraints) {
                          final width = constraints.maxWidth;
                          // Disposición compacta y estilizada:
                          // Móvil (<480px): 3 columnas ajustadas y proporcionadas
                          // Tablets (<800px): 4 columnas
                          // Desktop (<1200px): 5 columnas
                          // Pantallas grandes: 6 columnas
                          final int cols = width < 480 ? 3 : width < 800 ? 4 : width < 1100 ? 5 : 6;
                          final double ratio = width < 480 ? 0.82 : 0.92;
                          return GridView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              childAspectRatio: ratio,
                              crossAxisSpacing: width < 480 ? 8 : 12,
                              mainAxisSpacing: width < 480 ? 8 : 12,
                            ),
                            itemCount: catalogo.length,
                            itemBuilder: (_, index) {
                              final prod = catalogo[index];
                              return ServiceCardWidget(
                                producto: prod,
                                onTap: () => _abrirModalPago(prod),
                              );
                            },
                          );
                        },
                      ),
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

    return RefreshIndicator(
      color: BankTheme.primary,
      backgroundColor: BankTheme.surfaceElevated,
      onRefresh: () async {
        await Future.wait([
          pago.cargarCuentas(),
          pago.cargarHistorial(),
        ]);
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: pago.historial.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, idx) {
          final tx = pago.historial[idx];
          final esRechazada = tx.estado.toUpperCase().contains('RECHAZAD') || 
                              tx.estado.toUpperCase().contains('FALLID');
          final colorStatus = esRechazada ? BankTheme.danger : BankTheme.emeraldSuccess;
          final iconoStatus = esRechazada ? Icons.cancel_outlined : Icons.check_circle_outline;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: BankTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: esRechazada 
                    ? BankTheme.danger.withValues(alpha: 0.3) 
                    : BankTheme.border.withValues(alpha: 0.6),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: colorStatus.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconoStatus, color: colorStatus, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tx.producto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: BankTheme.textMain, 
                                fontSize: 13.5, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorStatus.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              esRechazada ? 'RECHAZADA' : 'EXITOSA',
                              style: TextStyle(
                                color: colorStatus,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Folio: #${tx.folio} • ${esRechazada ? "No se aplicó cargo" : "Aut: ${tx.numAutorizacion ?? "AUT-PROV"}"}',
                        style: TextStyle(
                          color: esRechazada ? BankTheme.textMuted : BankTheme.textMuted, 
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      esRechazada ? '\$${tx.monto.toStringAsFixed(2)} MXN' : '-\$${tx.monto.toStringAsFixed(2)} MXN',
                      style: TextStyle(
                        color: esRechazada ? BankTheme.textMuted : BankTheme.danger, 
                        fontSize: 13.5, 
                        fontWeight: FontWeight.bold,
                        decoration: esRechazada ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _verTicket(tx.folio),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: esRechazada 
                              ? BankTheme.danger.withValues(alpha: 0.15) 
                              : BankTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: esRechazada 
                                ? BankTheme.danger.withValues(alpha: 0.3) 
                                : BankTheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_rounded, 
                              color: esRechazada ? BankTheme.danger : BankTheme.cyanAccent, 
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ticket', 
                              style: TextStyle(
                                color: esRechazada ? BankTheme.danger : BankTheme.cyanAccent, 
                                fontSize: 11, 
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }
}
