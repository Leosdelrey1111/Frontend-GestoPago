import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';
import '../../data/models/api_models.dart';

class ServiceCardWidget extends StatelessWidget {
  final CatalogoProductoModel producto;
  final VoidCallback onTap;

  const ServiceCardWidget({
    super.key,
    required this.producto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final precio = producto.precio;
    final esMontoFijo = precio != null && precio > 0;

    return Container(
      decoration: BoxDecoration(
        color: BankTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BankTheme.border.withOpacity(0.7), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          hoverColor: BankTheme.primary.withOpacity(0.08),
          splashColor: BankTheme.cyanAccent.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo compacto
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: producto.urlLogo != null && producto.urlLogo!.isNotEmpty
                      ? Image.network(
                          producto.urlLogo!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.bolt_rounded, size: 24, color: BankTheme.primary),
                        )
                      : const Icon(Icons.bolt_rounded, size: 24, color: BankTheme.primary),
                ),

                // Textos de Producto y Categoría
                Column(
                  children: [
                    Text(
                      producto.nombreProducto,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BankTheme.textMain,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      producto.servicio,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: BankTheme.textMuted,
                      ),
                    ),
                  ],
                ),

                // Badge de Precio o Monto Libre más estilizado y compacto
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                  decoration: BoxDecoration(
                    color: esMontoFijo
                        ? BankTheme.primary.withOpacity(0.14)
                        : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: esMontoFijo
                          ? BankTheme.primary.withOpacity(0.35)
                          : Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        esMontoFijo ? Icons.sell_outlined : Icons.edit_note_rounded,
                        size: 11,
                        color: esMontoFijo ? BankTheme.cyanAccent : BankTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        esMontoFijo ? '\$${precio.toStringAsFixed(2)}' : 'Libre',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: esMontoFijo ? BankTheme.cyanAccent : BankTheme.textMain,
                        ),
                      ),
                    ],
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
