import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/bank_theme.dart';

class BankDatePickerDialog {
  static Future<DateTime?> show({
    required BuildContext anchorContext,
    required DateTime initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    String title = 'Fecha de Nacimiento',
  }) async {
    final minD = firstDate ?? DateTime(1920, 1, 1);
    final maxD = lastDate ?? DateTime.now();
    DateTime initD = initialDate;
    if (initD.isBefore(minD)) initD = minD;
    if (initD.isAfter(maxD)) initD = maxD;

    return showDialog<DateTime>(
      context: anchorContext,
      builder: (ctx) => _BankCalendarModal(
        initialDate: initD,
        firstDate: minD,
        lastDate: maxD,
        title: title,
      ),
    );
  }
}

class _BankCalendarModal extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const _BankCalendarModal({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.title,
  });

  @override
  State<_BankCalendarModal> createState() => _BankCalendarModalState();
}

class _BankCalendarModalState extends State<_BankCalendarModal> {
  late DateTime _displayedMonth;
  late DateTime _selectedDate;
  bool _mostrarSelectorAnios = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  void _changeMonth(int delta) {
    setState(() {
      final newMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
      if (!newMonth.isBefore(DateTime(widget.firstDate.year, widget.firstDate.month)) &&
          !newMonth.isAfter(DateTime(widget.lastDate.year, widget.lastDate.month))) {
        _displayedMonth = newMonth;
      }
    });
  }

  void _seleccionarAnio(int anio) {
    setState(() {
      _displayedMonth = DateTime(anio, _displayedMonth.month);
      _mostrarSelectorAnios = false;
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final startGrid = firstOfMonth.subtract(Duration(days: firstOfMonth.weekday - 1));
    final monthLabel = DateFormat('MMMM yyyy', 'es_MX').format(_displayedMonth).toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF131B2E),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: BankTheme.border, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 32,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: BankTheme.primary.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, size: 18, color: BankTheme.cyanAccent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: BankTheme.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _mostrarSelectorAnios = !_mostrarSelectorAnios),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: BankTheme.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: BankTheme.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_displayedMonth.year}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankTheme.cyanAccent),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _mostrarSelectorAnios ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 15,
                              color: BankTheme.cyanAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                if (_mostrarSelectorAnios)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2.0,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: (widget.lastDate.year - widget.firstDate.year + 1),
                      itemBuilder: (ctx, idx) {
                        final anio = widget.lastDate.year - idx;
                        final isCur = anio == _displayedMonth.year;

                        return InkWell(
                          onTap: () => _seleccionarAnio(anio),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isCur ? BankTheme.primary : BankTheme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isCur ? BankTheme.cyanAccent : BankTheme.border),
                            ),
                            child: Text(
                              '$anio',
                              style: TextStyle(
                                color: isCur ? Colors.white : BankTheme.textMain,
                                fontSize: 12,
                                fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else ...[
                  // Barra de navegación de mes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: BankTheme.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BankTheme.border),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 20, color: BankTheme.textMain),
                          onPressed: () => _changeMonth(-1),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        ),
                        Expanded(
                          child: Text(
                            monthLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: BankTheme.textMain,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 20, color: BankTheme.textMain),
                          onPressed: () => _changeMonth(1),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Días de la semana
                  Row(
                    children: const [
                      for (final d in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                        Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankTheme.textMuted),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Cuadrícula de 6 semanas
                  for (var w = 0; w < 6; w++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        children: [
                          for (var d = 0; d < 7; d++)
                            Expanded(
                              child: _buildDayCell(
                                DateTime(
                                  startGrid.year,
                                  startGrid.month,
                                  startGrid.day + w * 7 + d,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: BankTheme.textMuted, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final inMonth = day.month == _displayedMonth.month;
    final isSelected = _isSameDay(day, _selectedDate);
    final isDisabled = day.isBefore(widget.firstDate) || day.isAfter(widget.lastDate);

    return Center(
      child: InkWell(
        onTap: isDisabled
            ? null
            : () {
                Navigator.of(context).pop(day);
              },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? BankTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: BankTheme.cyanAccent) : null,
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isDisabled
                  ? BankTheme.textHint.withOpacity(0.25)
                  : isSelected
                      ? Colors.white
                      : inMonth
                          ? BankTheme.textMain
                          : BankTheme.textHint.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}
