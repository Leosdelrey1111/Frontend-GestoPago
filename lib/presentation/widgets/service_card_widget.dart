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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BankTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          hoverColor: BankTheme.primary.withOpacity(0.08),
          splashColor: BankTheme.cyanAccent.withOpacity(0.12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Contenedor del Logo con fondo blanco para preservar la identidad gráfica original
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: producto.urlLogo != null && producto.urlLogo!.isNotEmpty
                      ? Image.network(
                          producto.urlLogo!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.bolt_rounded, size: 30, color: BankTheme.primary),
                        )
                      : const Icon(Icons.bolt_rounded, size: 30, color: BankTheme.primary),
                ),
                const SizedBox(height: 12),

                // Nombre del Producto
                Text(
                  producto.nombreProducto,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: BankTheme.textMain,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),

                // Categoría / Proveedor
                Text(
                  producto.servicio,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: BankTheme.textMuted,
                  ),
                ),
                const Spacer(),

                // Tag de Precio o Monto Libre
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: esMontoFijo
                        ? BankTheme.primary.withOpacity(0.18)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: esMontoFijo
                          ? BankTheme.primary.withOpacity(0.4)
                          : Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        esMontoFijo ? Icons.sell_outlined : Icons.edit_note_rounded,
                        size: 13,
                        color: esMontoFijo ? BankTheme.cyanAccent : BankTheme.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        esMontoFijo ? '\$${precio!.toStringAsFixed(2)}' : 'Monto Abierto',
                        style: TextStyle(
                          fontSize: 11.5,
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
