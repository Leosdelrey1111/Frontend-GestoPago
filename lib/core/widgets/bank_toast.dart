import 'package:flutter/material.dart';
import '../theme/bank_theme.dart';
import '../utils/responsive_layout.dart';

enum ToastTipo { exito, error, advertencia, info }

class BankToast {
  static void mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    ToastTipo tipo = ToastTipo.info,
    Duration duracion = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    Color color;
    IconData icono;

    switch (tipo) {
      case ToastTipo.exito:
        color = BankTheme.emeraldSuccess;
        icono = Icons.check_circle_outline_rounded;
        break;
      case ToastTipo.error:
        color = BankTheme.danger;
        icono = Icons.error_outline_rounded;
        break;
      case ToastTipo.advertencia:
        color = BankTheme.warning;
        icono = Icons.warning_amber_rounded;
        break;
      case ToastTipo.info:
      default:
        color = BankTheme.cyanAccent;
        icono = Icons.info_outline_rounded;
        break;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 20,
        right: ResponsiveLayout.isMobile(ctx) ? 16 : 24,
        left: ResponsiveLayout.isMobile(ctx) ? 16 : null,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, (1 - val) * -16),
                    child: child,
                  ),
                );
              },
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
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
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
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duracion, () {
      if (entry.mounted) entry.remove();
    });
  }
}
