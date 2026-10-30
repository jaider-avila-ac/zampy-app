import 'package:flutter/material.dart' hide MenuTheme;

import '../models/public_menu_model.dart';
import '../utils/horario.dart';

class ScheduleAsidePanel {
  ScheduleAsidePanel._();

  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> horario,
    MenuTheme theme,
  ) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar horario',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _SchedulePanel(horario: horario, theme: theme);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset =
            Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        return SlideTransition(position: offset, child: child);
      },
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({required this.horario, required this.theme});

  final Map<String, dynamic> horario;
  final MenuTheme theme;

  @override
  Widget build(BuildContext context) {
    final dias = diasConHorario(horario);
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: theme.surface,
        child: SafeArea(
          left: false,
          child: SizedBox(
            width: 320,
            height: double.infinity,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: theme.border)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        size: 17,
                        color: theme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Horario de atención',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: theme.text,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 18,
                          color: theme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: dias.isEmpty
                      ? Center(
                          child: Text(
                            'Horario no disponible.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: dias.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final dia = dias[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    dia.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: theme.text,
                                    ),
                                  ),
                                ),
                                Text(
                                  dia.veinticuatro
                                      ? '24 horas'
                                      : dia.rangos
                                            .map(
                                              (r) =>
                                                  '${formatHora(r.desde)} – ${formatHora(r.hasta)}',
                                            )
                                            .join('\n'),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: theme.textMuted,
                                  ),
                                ),
                              ],
                            );
                          },
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
