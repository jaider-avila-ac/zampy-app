import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../services/invite_store.dart';
import '../../../shared/app_colors.dart';

class InvitePage extends StatefulWidget {
  const InvitePage({super.key, required this.code});

  final String code;

  @override
  State<InvitePage> createState() => _InvitePageState();
}

class _InvitePageState extends State<InvitePage> {
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    await InviteStore.save(widget.code);
    if (!mounted) return;
    context.go('/register');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.kBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Preparando tu invitación…',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
