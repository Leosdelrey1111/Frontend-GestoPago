import 'dart:ui';
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
        icono = Icons.check_circle_rounded;
        break;
      case ToastTipo.error:
        color = BankTheme.danger;
        icono = Icons.error_rounded;
        break;
      case ToastTipo.advertencia:
        color = BankTheme.warning;
        icono = Icons.warning_amber_rounded;
        break;
      case ToastTipo.info:
      default:
        color = BankTheme.cyanAccent;
        icono = Icons.info_rounded;
        break;
    }

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final isMobile = ResponsiveLayout.isMobile(ctx);

        return Positioned(
          bottom: bottomInset + (isMobile ? 24.0 : 32.0),
          left: isMobile ? 20.0 : null,
          right: isMobile ? 20.0 : 32.0,
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: isMobile ? Alignment.bottomCenter : Alignment.bottomRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutBack,
                  builder: (context, val, child) {
                    return Opacity(
                      opacity: val.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, (1 - val) * 20),
                        child: child,
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131B2E).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.45), width: 1.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: color.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Icon(icono, color: color, size: 18),
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
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    mensaje,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 11.5,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                if (entry.mounted) entry.remove();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.close_rounded, color: Colors.white.withOpacity(0.5), size: 16),
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
          ),
        );
      },
    );

    overlay.insert(entry);
    Future.delayed(duracion, () {
      if (entry.mounted) entry.remove();
    });
  }
}
