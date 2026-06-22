import 'package:flutter/material.dart';
import '../../../shared/app_colors.dart';
import '../../../hooks/use_geo_location.dart';

// Equivalente a src/modules/explore/components/LocationBanner.jsx en React

class LocationBanner extends StatefulWidget {
  const LocationBanner({
    super.key,
    required this.onGranted,
    required this.onDismiss,
  });

  final void Function(double lat, double lon) onGranted;
  final VoidCallback onDismiss;

  @override
  State<LocationBanner> createState() => _LocationBannerState();
}

class _LocationBannerState extends State<LocationBanner> {
  bool _asking = false;

  Future<void> _handleAsk() async {
    setState(() => _asking = true);
    try {
      final pos = await requestDeviceLocation();
      widget.onGranted(pos.lat, pos.lon);
    } catch (_) {
      await setGeoStatus('denied');
      widget.onDismiss();
    }
    if (mounted) setState(() => _asking = false);
  }

  @override
  Widget build(BuildContext context) {
    // Equivalente al div con border border-slate-200 rounded-2xl p-4 en React
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.kCardBorder),
      ),
      child: Row(
        children: [
          // Ícono Navigation (Navigation size={17} en React)
          const Icon(Icons.navigation_outlined, size: 17, color: AppColors.kBlueLight),
          const SizedBox(width: 12),

          // Texto
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Ver restaurantes cerca?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Comparte tu ubicación para ver menús de tu ciudad.',
                  style: TextStyle(fontSize: 12, color: AppColors.kTextSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Botón Permitir
          TextButton(
            onPressed: _asking ? null : _handleAsk,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.kBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _asking ? '...' : 'Permitir',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 4),

          // Botón X
          GestureDetector(
            onTap: widget.onDismiss,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 15, color: AppColors.kTextMuted),
            ),
          ),
        ],
      ),
    );
  }
}
