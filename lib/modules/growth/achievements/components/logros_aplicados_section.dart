import 'package:flutter/material.dart';

import '../../../../services/logro_service.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/modules/menu/editor/tabs/publish/LogrosAplicadosSection.jsx
// Solo lectura: logros que YA se aplicaron a este menú. La ve el dueño o un colaborador editor,
// sin exponer el progreso general de la cuenta ni los logros de otros menús.

class LogrosAplicadosSection extends StatefulWidget {
  const LogrosAplicadosSection({super.key, required this.menuCodigo});
  final String menuCodigo;

  @override
  State<LogrosAplicadosSection> createState() => _LogrosAplicadosSectionState();
}

class _LogrosAplicadosSectionState extends State<LogrosAplicadosSection> {
  List<Map<String, dynamic>> _logros = const [];

  @override
  void initState() {
    super.initState();
    LogroService.aplicadosDelMenu(widget.menuCodigo).then((data) {
      if (mounted) setState(() => _logros = data);
    }).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_logros.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.kCardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_outlined, size: 16, color: AppColors.kBlueLight),
              SizedBox(width: 6),
              Text('Logros aplicados a este menú',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.kTextPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          for (final l in _logros)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l['nombre']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.kTextSecondary)),
                  ),
                  Text(
                    '+${l['diasRecompensa'] ?? 0} día${l['diasRecompensa'] == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kBlue),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
