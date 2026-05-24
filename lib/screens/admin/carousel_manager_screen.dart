import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/company_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/app_themes.dart';
import '../../services/app_localizations.dart';
import 'carousel_slot_detail_screen.dart';
import '../../widgets/admin_drawer.dart';

class CarouselManagerScreen extends StatefulWidget {
  const CarouselManagerScreen({super.key});

  @override
  State<CarouselManagerScreen> createState() => _CarouselManagerScreenState();
}

class _CarouselManagerScreenState extends State<CarouselManagerScreen> {
  final _service = SupabaseService();
  Map<int, String> _actions = {};
  bool _loadingActions = true;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final actions = await _service.getCarouselActions(companyId);
    if (mounted) setState(() { _actions = actions; _loadingActions = false; });
  }

  Future<void> _openDetail(int slot) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CarouselSlotDetailScreen(
          slot: slot,
          currentAction: _actions[slot],
        ),
      ),
    );
    // Si se guardó algo, recargamos las acciones
    if (result == true) _loadActions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).get('carousel_title')),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      drawer: const AdminDrawer(),
      body: _loadingActions
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final slot = i + 1;
          final slotLabel = slot.toString().padLeft(2, '0');
          final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
          final imageUrl = _service.getCarouselImageUrl(slot, companyId);
          final action = _actions[slot];

          // Badge de acción
          Widget? actionBadge;
          if (action != null && action.isNotEmpty) {
            final isUrl = action.startsWith('http');
            actionBadge = Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    isUrl ? Icons.link : Icons.home_work_outlined,
                    size: 12,
                    color: AppThemes.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      isUrl ? action : 'Ref. ${action.replaceAll(RegExp(r'\D'), '').padLeft(3, '0')}',
                      style: const TextStyle(fontSize: 11, color: AppThemes.primaryGreen),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                '$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),
            ),
            title: Text(
              'Posición $slotLabel',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'carrusel/carrusel_img_$slotLabel.jpg',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (actionBadge != null) actionBadge,
              ],
            ),
            trailing: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.primaryGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _openDetail(slot),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(AppLocalizations.of(context).get('carousel_change')),
            ),
          );
        },
      ),
    );
  }
}
