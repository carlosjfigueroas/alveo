import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/app_localizations.dart';
import '../services/app_themes.dart';

class VisitorBadge extends StatelessWidget {
  final int count;
  final bool isLoading;

  const VisitorBadge({
    super.key,
    required this.count,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 80,
          height: 14,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white54 : AppThemes.primaryGreen.withValues(alpha: 0.5)),
          ),
        ),
      );
    }

    final formattedCount = NumberFormat.compact().format(count);
    
    return Tooltip(
      message: l10n.get('this_week'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppThemes.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : AppThemes.primaryGreen.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 14,
              color: isDark ? Colors.white70 : AppThemes.primaryGreen,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.get('weekly_visitors').replaceAll('{0}', formattedCount),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppThemes.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
