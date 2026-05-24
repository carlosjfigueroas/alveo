import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/company_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/app_themes.dart';
import '../../services/app_localizations.dart';
import '../../utils/image_utils.dart';

class CarouselSlotDetailScreen extends StatefulWidget {
  final int slot;
  final String? currentAction;

  const CarouselSlotDetailScreen({
    super.key,
    required this.slot,
    this.currentAction,
  });

  @override
  State<CarouselSlotDetailScreen> createState() => _CarouselSlotDetailScreenState();
}

class _CarouselSlotDetailScreenState extends State<CarouselSlotDetailScreen> {
  final _service = SupabaseService();
  final _picker = ImagePicker();
  late final TextEditingController _actionController;

  Uint8List? _selectedImageBytes;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _actionController = TextEditingController(text: widget.currentAction ?? '');
  }

  @override
  void dispose() {
    _actionController.dispose();
    super.dispose();
  }

  // Detecta si el valor es una URL o una referencia numérica
  String _actionTypeLabel(String value) {
    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return '🌐 Link externo';
    }
    final ref = int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
    if (ref != null) return '🏢 Inmueble Ref. ${ref.toString().padLeft(3, '0')}';
    return '⚠️ Formato no reconocido';
  }

  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    Uint8List bytes = await file.readAsBytes();
    if (bytes.length > 100 * 1024) {
      bytes = await ImageUtils.compressImage(bytes);
    }
    setState(() => _selectedImageBytes = bytes);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final l10n = AppLocalizations.of(context);
    try {
      // 1. Subir imagen si se seleccionó una nueva
      if (_selectedImageBytes != null) {
        await _service.uploadCarouselImage(
          widget.slot,
          _selectedImageBytes!,
          'image/jpeg',
          companyId,
        );
      }
      // 2. Guardar la acción (o eliminarla si está vacía)
      await _service.setCarouselAction(
        companyId,
        widget.slot,
        _actionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.get('carousel_action_saved')),
            backgroundColor: AppThemes.primaryGreen,
          ),
        );
        Navigator.of(context).pop(true); // Indica al padre que hubo cambios
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.get('error_generic')}$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slotLabel = widget.slot.toString().padLeft(2, '0');
    final actionValue = _actionController.text;
    final typeLabel = _actionTypeLabel(actionValue);
    final companyId = Provider.of<CompanyProvider>(context, listen: false).companyId;
    final currentImageUrl = _service.getCarouselImageUrl(widget.slot, companyId);

    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.get('carousel_slot_title')} $slotLabel'),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Vista Previ de Imagen ──────────────────────────────────────
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              clipBehavior: Clip.antiAlias,
              child: _selectedImageBytes != null
                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  : Image.network(
                      '$currentImageUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Sin imagen actual',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // ─── Selección de imagen ────────────────────────────────────────
            Text(
              l10n.get('carousel_select_image'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(
                _selectedImageBytes == null
                    ? l10n.get('carousel_select_image')
                    : l10n.get('carousel_image_selected'),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppThemes.primaryGreen,
                side: const BorderSide(color: AppThemes.primaryGreen),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (_selectedImageBytes != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: AppThemes.primaryGreen, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    l10n.get('carousel_image_selected'),
                    style: const TextStyle(color: AppThemes.primaryGreen, fontSize: 13),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // ─── Campo de acción ────────────────────────────────────────────
            Text(
              l10n.get('carousel_action_label'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _actionController,
              enabled: !_isSaving,
              decoration: InputDecoration(
                hintText: l10n.get('carousel_action_hint'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.link),
                suffixIcon: _actionController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _actionController.clear()),
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            // Indicador de tipo detectado
            if (typeLabel.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: typeLabel.contains('⚠️') ? Colors.orange : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 48),

            // ─── Botón Guardar ──────────────────────────────────────────────
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      l10n.get('carousel_action_save'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
