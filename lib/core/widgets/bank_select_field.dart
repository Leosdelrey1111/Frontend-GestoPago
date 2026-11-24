import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/bank_theme.dart';

class BankSelectOption<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;

  const BankSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.color,
  });
}

class BankSelectField<T> extends StatelessWidget {
  final String? label;
  final String? placeholder;
  final T? value;
  final List<BankSelectOption<T>> options;
  final ValueChanged<T>? onChanged;
  final IconData? prefixIcon;
  final bool requiredField;
  final String? Function(T?)? validator;

  const BankSelectField({
    super.key,
    this.label,
    this.placeholder,
    this.value,
    required this.options,
    this.onChanged,
    this.prefixIcon,
    this.requiredField = false,
    this.validator,
  });

  BankSelectOption<T>? get _selectedOption {
    for (final opt in options) {
      if (opt.value == value) return opt;
    }
    return null;
  }

  Future<void> _openPopover(BuildContext buttonContext) async {
    final RenderBox? box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null) return;
    final Offset topLeft = box.localToGlobal(Offset.zero);
    final Size buttonSize = box.size;
    final Rect anchorRect = topLeft & buttonSize;

    await showGeneralDialog<void>(
      context: buttonContext,
      barrierDismissible: true,
      barrierLabel: 'Cerrar selector',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 170),
      pageBuilder: (ctx, anim1, anim2) {
        return _BankSelectPopover<T>(
          anchorRect: anchorRect,
          title: label ?? placeholder ?? 'Seleccionar opción',
          currentValue: value,
          options: options,
          defaultIcon: prefixIcon,
          onSelected: (val) {
            onChanged?.call(val);
          },
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedOpt = _selectedOption;
    final hasSelection = selectedOpt != null;

    return FormField<T>(
      initialValue: value,
      validator: validator != null ? (_) => validator!(value) : null,
      builder: (fieldState) {
        final hasError = fieldState.hasError;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null && label!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  label!,
                  style: const TextStyle(
                    color: BankTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Builder(
              builder: (btnCtx) => Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openPopover(btnCtx),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    decoration: BoxDecoration(
                      color: BankTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError
                            ? BankTheme.danger
                            : hasSelection
                                ? BankTheme.primary.withOpacity(0.55)
                                : BankTheme.border,
                        width: hasError ? 1.3 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (prefixIcon != null || selectedOpt?.icon != null) ...[
                          Icon(
                            selectedOpt?.icon ?? prefixIcon,
                            color: hasSelection ? BankTheme.cyanAccent : BankTheme.primary,
                            size: 19,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            hasSelection ? selectedOpt.label : (placeholder ?? 'Seleccionar...'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasSelection ? BankTheme.textMain : BankTheme.textHint,
                              fontSize: 13.5,
                              fontWeight: hasSelection ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: BankTheme.border.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: BankTheme.textMuted,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (hasError && fieldState.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 4),
                child: Text(
                  fieldState.errorText!,
                  style: const TextStyle(
                    color: BankTheme.danger,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BankSelectPopover<T> extends StatefulWidget {
  final Rect anchorRect;
  final String title;
  final T? currentValue;
  final List<BankSelectOption<T>> options;
  final IconData? defaultIcon;
  final ValueChanged<T> onSelected;

  const _BankSelectPopover({
    required this.anchorRect,
    required this.title,
    required this.currentValue,
    required this.options,
    required this.defaultIcon,
    required this.onSelected,
  });

  @override
  State<_BankSelectPopover<T>> createState() => _BankSelectPopoverState<T>();
}

class _BankSelectPopoverState<T> extends State<_BankSelectPopover<T>> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<BankSelectOption<T>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.options;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onFilter(String text) {
    final query = text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filtered = widget.options;
      } else {
        _filtered = widget.options.where((opt) {
          return opt.label.toLowerCase().contains(query) ||
              (opt.subtitle != null && opt.subtitle!.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    final popoverWidth = math.min(math.max(widget.anchorRect.width, 280.0), screen.width - 24).toDouble();
    final double left = widget.anchorRect.left
        .clamp(12.0, math.max(12.0, screen.width - popoverWidth - 12.0))
        .toDouble();

    final spaceBelow = screen.height - widget.anchorRect.bottom - 16;
    final showAbove = spaceBelow < 250 && widget.anchorRect.top > spaceBelow;
    final maxHeight = math.min(360.0, showAbove ? widget.anchorRect.top - 24 : spaceBelow);

    final showSearch = widget.options.length > 7;

    return Stack(
      children: [
        Positioned(
          left: left,
          top: showAbove ? null : widget.anchorRect.bottom + 6,
          bottom: showAbove ? (screen.height - widget.anchorRect.top + 6) : null,
          width: popoverWidth,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(maxHeight: math.max(160.0, maxHeight)),
              decoration: BoxDecoration(
                color: BankTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: BankTheme.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera elegante
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                    child: Row(
                      children: [
                        Icon(widget.defaultIcon ?? Icons.tune_rounded, size: 16, color: BankTheme.cyanAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: BankTheme.textMain,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: BankTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_filtered.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: BankTheme.cyanAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Barra de búsqueda si hay muchas opciones
                  if (showSearch)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: BankTheme.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: BankTheme.border),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: _onFilter,
                          style: const TextStyle(color: BankTheme.textMain, fontSize: 12.5),
                          decoration: const InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: TextStyle(color: BankTheme.textHint, fontSize: 12),
                            prefixIcon: Icon(Icons.search_rounded, size: 16, color: BankTheme.textHint),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 9),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),

                  const Divider(height: 1, color: BankTheme.border),

                  // Lista desplazable
                  Flexible(
                    child: _filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'No se encontraron resultados',
                                style: TextStyle(color: BankTheme.textHint, fontSize: 12),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(6),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) {
                              final opt = _filtered[i];
                              final isSelected = opt.value == widget.currentValue;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    widget.onSelected(opt.value);
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected ? BankTheme.primary.withOpacity(0.18) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected ? BankTheme.cyanAccent.withOpacity(0.5) : Colors.transparent,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        if (opt.icon != null) ...[
                                          Icon(
                                            opt.icon,
                                            size: 16,
                                            color: isSelected ? BankTheme.cyanAccent : BankTheme.textMuted,
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                opt.label,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: isSelected ? Colors.white : BankTheme.textMain,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (opt.subtitle != null && opt.subtitle!.isNotEmpty)
                                                Text(
                                                  opt.subtitle!,
                                                  style: const TextStyle(fontSize: 11, color: BankTheme.textMuted),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(Icons.check_rounded, color: BankTheme.cyanAccent, size: 17),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
