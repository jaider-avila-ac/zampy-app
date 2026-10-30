import 'package:flutter/material.dart';

import '../../../shared/app_colors.dart';

class SkeletonMenuCard extends StatefulWidget {
  const SkeletonMenuCard({super.key});

  @override
  State<SkeletonMenuCard> createState() => _SkeletonMenuCardState();
}

class _SkeletonMenuCardState extends State<SkeletonMenuCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 82,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.kCardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.kSkeleton,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar(width: 150),
                    const SizedBox(height: 8),
                    _bar(width: 90),
                    const SizedBox(height: 8),
                    _bar(width: 110),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar({required double width}) => Container(
    width: width,
    height: 10,
    decoration: BoxDecoration(
      color: AppColors.kSkeleton,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
