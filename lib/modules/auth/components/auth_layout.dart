import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/app_colors.dart';

class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.child, this.maxWidth = 420});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SvgPicture.asset(
                      'assets/logos/imagotipo-indigo-zammpy.svg',
                      height: 36,
                      colorFilter: const ColorFilter.mode(
                        AppColors.kBlue,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
