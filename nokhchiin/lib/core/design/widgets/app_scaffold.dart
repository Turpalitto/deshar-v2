import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import '../tokens/app_spacing.dart';
import 'ornament_accent.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.floatingActionButton,
    this.showOrnament = true,
    this.darkOrnament = false,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;
  final bool showOrnament;
  final bool darkOrnament;

  @override
  Widget build(BuildContext context) {
    final tokens = context.iosTokens;

    return Scaffold(
      backgroundColor: tokens.background,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          if (showOrnament)
            Positioned.fill(
              child: NokhchiinOrnament(
                opacity: darkOrnament ? 0.055 : 0.05,
                light: darkOrnament,
              ),
            ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null || actions != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Row(
                      children: [
                        if (Navigator.canPop(context))
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_rounded, color: tokens.textTertiary, size: 20),
                            onPressed: () => Navigator.maybePop(context),
                          ),
                        if (title != null)
                          Expanded(
                            child: Text(
                              title!,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                                letterSpacing: -0.2,
                              ),
                            ),
                          )
                        else
                          const Spacer(),
                        ...?actions,
                      ],
                    ),
                  ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
