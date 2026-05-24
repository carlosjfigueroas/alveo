import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/property_history.dart';
import '../services/commission_service.dart';

class PropertyHistoryWidget extends StatefulWidget {
  final String propertyId;

  const PropertyHistoryWidget({Key? key, required this.propertyId}) : super(key: key);

  @override
  State<PropertyHistoryWidget> createState() => _PropertyHistoryWidgetState();
}

class _PropertyHistoryWidgetState extends State<PropertyHistoryWidget> {
  final _commissionService = CommissionService();
  bool _isLoading = true;
  List<PropertyHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history = await _commissionService.getPropertyHistory(widget.propertyId);
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_history.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No hay historial de operaciones registrado para este inmueble.'),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final dateFormat = DateFormat('dd/MM/yyyy');

    int timesSold = _history.where((h) => h.operationType == 'Venta').length;
    int timesRented = _history.where((h) => h.operationType == 'Alquiler').length;
    double totalRevenue = _history.fold(0.0, (sum, h) => sum + h.finalPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryStat(title: 'Ventas', value: timesSold.toString()),
              _SummaryStat(title: 'Alquileres', value: timesRented.toString()),
              _SummaryStat(title: 'Ingreso Total', value: currencyFormat.format(totalRevenue)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Registro de Operaciones',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final entry = _history[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.operationType == 'Venta' 
                      ? Colors.green.withValues(alpha: 0.2) 
                      : Colors.blue.withValues(alpha: 0.2),
                  child: Icon(
                    entry.operationType == 'Venta' ? Icons.sell : Icons.key,
                    color: entry.operationType == 'Venta' 
                        ? (Theme.of(context).brightness == Brightness.dark ? Colors.green.shade300 : Colors.green)
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.blue.shade300 : Colors.blue),
                  ),
                ),
                title: Text('${entry.operationType} - ${currencyFormat.format(entry.finalPrice)}'),
                subtitle: Text('Fecha: ${dateFormat.format(entry.startDate)}'),
                trailing: entry.notes != null && entry.notes!.isNotEmpty
                    ? Tooltip(message: entry.notes, child: const Icon(Icons.info_outline))
                    : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryStat({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title, 
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.grey.shade600, 
            fontSize: 12
          )
        ),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          )
        ),
      ],
    );
  }
}
