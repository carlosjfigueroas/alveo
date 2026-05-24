import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/app_localizations.dart';

class CommissionChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final bool isDark;

  const CommissionChart({
    Key? key,
    required this.data,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (data.isEmpty) {
      return Center(
        child: Text(
          l10n.get('no_chart_data'),
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
      );
    }

    final keys = data.keys.toList();
    double maxY = 0;
    
    // Find maxY to scale chart
    for (var val in data.values) {
      if (val['total']! > maxY) maxY = val['total']!;
    }
    
    // Add 20% padding to top
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100; // default if all 0

    return Padding(
      padding: const EdgeInsets.only(right: 16.0, left: 8.0, top: 16.0, bottom: 8.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => isDark ? Colors.grey[800]! : Colors.white,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = keys[group.x.toInt()];
                final isTotal = rodIndex == 0;
                final value = rod.toY;
                final label = isTotal ? l10n.get('total_collected') : l10n.get('agency_retention');
                return BarTooltipItem(
                  '$month\n$label: \$${NumberFormat('#,###').format(value)}',
                  TextStyle(
                    color: isTotal ? Colors.teal : Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= keys.length) return const SizedBox();
                  
                  // Format '2023-05' to 'May' or '05/23'
                  final dateParts = keys[index].split('-');
                  if (dateParts.length == 2) {
                    final monthName = _getMonthAbbr(dateParts[1], l10n);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        monthName,
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox();
                  return Text(
                    _formatNumber(value),
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4 > 0 ? maxY / 4 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.white10 : Colors.black12,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(keys.length, (i) {
            final monthData = data[keys[i]]!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: monthData['total'] ?? 0.0,
                  color: Colors.teal,
                  width: 12,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
                BarChartRodData(
                  toY: monthData['retention'] ?? 0.0,
                  color: Colors.indigo,
                  width: 12,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${NumberFormat("#,###.0").format(value / 1000000)}M';
    } else if (value >= 1000) {
      return '${NumberFormat("#,###").format(value / 1000)}k';
    }
    return NumberFormat("#,###").format(value);
  }

  String _getMonthAbbr(String monthNum, AppLocalizations l10n) {
    switch (monthNum) {
      case '01': return l10n.get('month_1_abbr');
      case '02': return l10n.get('month_2_abbr');
      case '03': return l10n.get('month_3_abbr');
      case '04': return l10n.get('month_4_abbr');
      case '05': return l10n.get('month_5_abbr');
      case '06': return l10n.get('month_6_abbr');
      case '07': return l10n.get('month_7_abbr');
      case '08': return l10n.get('month_8_abbr');
      case '09': return l10n.get('month_9_abbr');
      case '10': return l10n.get('month_10_abbr');
      case '11': return l10n.get('month_11_abbr');
      case '12': return l10n.get('month_12_abbr');
      default: return monthNum;
    }
  }
}
