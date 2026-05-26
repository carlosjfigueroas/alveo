import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../services/app_localizations.dart';
/// Animated FAB for Ava — Alveo's AI Virtual Assistant.
/// Displays a pulsing glow effect using the company's primary color.
class AiChatFab extends StatefulWidget {
  final VoidCallback onPressed;

  const AiChatFab({super.key, required this.onPressed});

  @override
  State<AiChatFab> createState() => _AiChatFabState();
}

class _AiChatFabState extends State<AiChatFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final companyProv = context.watch<CompanyProvider>();
    final country = companyProv.country?.toLowerCase();
    final isMock = companyProv.company.aiModel == 'mock-test';
    
    String? avatarAsset;
    if (companyProv.isDemo || country == null) {
      avatarAsset = 'assets/images/avatars/avatar_venezuela.png';
    } else {
      if (country.contains('venezuela')) avatarAsset = 'assets/images/avatars/avatar_venezuela.png';
      else if (country.contains('bolivia')) avatarAsset = 'assets/images/avatars/avatar_bolivia.png';
      else if (country.contains('colombia')) avatarAsset = 'assets/images/avatars/avatar_colombia.png';
      else if (country.contains('usa') || country.contains('estados unidos')) avatarAsset = 'assets/images/avatars/avatar_usa.png';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedScale(
        scale: _isHovered ? 1.40 : 1.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(
                          alpha: _isHovered
                              ? (isDark ? 0.75 : 0.55)
                              : (isDark ? 0.5 : 0.35)),
                      blurRadius: _glowAnimation.value + (_isHovered ? 18 : 8),
                      spreadRadius: _glowAnimation.value / 3,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: FloatingActionButton(
            onPressed: widget.onPressed,
            backgroundColor: avatarAsset != null
                ? primaryColor.withValues(alpha: 0.15)
                : primaryColor,
            elevation: _isHovered ? 8 : 4,
            tooltip: AppLocalizations.of(context)
                .get(isMock ? 'ava_fab_tooltip_mock' : 'ava_fab_tooltip_ai'),
            clipBehavior: Clip.antiAlias,
            child: avatarAsset != null
                ? AnimatedScale(
                    scale: _isHovered ? 1.28 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Image.asset(
                        avatarAsset,
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
          ),
        ),
      ),
    );
  }
}
