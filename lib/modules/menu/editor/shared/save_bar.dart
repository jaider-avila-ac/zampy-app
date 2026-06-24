import 'package:flutter/material.dart';
import '../../../../shared/app_colors.dart';

// Equivalente a src/components/ui/SaveBar.jsx en React
// Barra inferior que aparece cuando hay cambios sin guardar.

class SaveBar extends StatelessWidget {
  const SaveBar({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onSave,
  });

  final bool dirty;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: dirty ? Offset.zero : const Offset(0, 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: dirty ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Cambios sin guardar',
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: saving ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white,
                          ),
                        )
                      : const Text('Guardar cambios'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
