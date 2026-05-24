import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/app_provider.dart';
import '../../services/supabase_service.dart';
import '../../services/app_themes.dart';
import '../../models/site_content.dart';
import '../../services/app_localizations.dart';
import '../../widgets/admin_drawer.dart';
import '../../providers/company_provider.dart';

class AdminContentEditor extends StatefulWidget {
  const AdminContentEditor({super.key});

  @override
  State<AdminContentEditor> createState() => _AdminContentEditorState();
}

class _AdminContentEditorState extends State<AdminContentEditor> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = SupabaseService();
  bool _isSaving = false;

  // About Us controllers
  final List<TextEditingController> _aboutControllersEs = [];
  final List<TextEditingController> _aboutControllersEn = [];
  List<AboutContent> _aboutData = [];

  // FAQ data
  List<FaqEntry> _faqData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final companyId = context.read<CompanyProvider>().companyId;
    final provider = context.read<AppProvider>();
    await provider.fetchSiteContent(companyId);
    
    setState(() {
      _aboutData = provider.aboutContent;
      _faqData = List.from(provider.faqs);
      
      _aboutControllersEs.clear();
      _aboutControllersEn.clear();
      for (var item in _aboutData) {
        _aboutControllersEs.add(TextEditingController(text: item.valueEs));
        _aboutControllersEn.add(TextEditingController(text: item.valueEn));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var c in _aboutControllersEs) {
      c.dispose();
    }
    for (var c in _aboutControllersEn) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAbout() async {
    setState(() => _isSaving = true);
    try {
      final companyId = context.read<CompanyProvider>().companyId;
      for (int i = 0; i < _aboutData.length; i++) {
        await _service.updateAboutContent(
          _aboutData[i].key,
          _aboutControllersEs[i].text,
          _aboutControllersEn[i].text,
          companyId,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('success_about_updated'))),
        );
        context.read<AppProvider>().fetchSiteContent(companyId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addFaq() {
    setState(() {
      _faqData.add(FaqEntry(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        questionEs: '',
        answerEs: '',
        questionEn: '',
        answerEn: '',
        sortOrder: _faqData.length + 1,
      ));
    });
  }

  Future<void> _saveFaqs() async {
    setState(() => _isSaving = true);
    try {
      final companyId = context.read<CompanyProvider>().companyId;
      for (var faq in _faqData) {
        await _service.saveFaq(faq, companyId);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('success_faqs_updated'))),
        );
        context.read<AppProvider>().fetchSiteContent(companyId);
        _loadData(); // Reload to get real IDs
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar FAQs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteFaq(String id, int index) async {
    if (id.startsWith('temp_')) {
      setState(() {
        _faqData.removeAt(index);
      });
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).get('delete_confirm_title')),
        content: Text(AppLocalizations.of(context).get('delete_confirm_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context).get('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text(AppLocalizations.of(context).get('delete'), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteFaq(id);
        setState(() { _faqData.removeAt(index); });
        if (mounted) {
          final companyId = context.read<CompanyProvider>().companyId;
          context.read<AppProvider>().fetchSiteContent(companyId);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('content_management')),
        backgroundColor: const Color(0xFF003366),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: AppThemes.primaryGreen,
          tabs: [
            Tab(text: l10n.get('about_us_tab'), icon: const Icon(Icons.info_outline)),
            Tab(text: l10n.get('faq_tab'), icon: const Icon(Icons.help_outline)),
          ],
        ),
      ),
      drawer: const AdminDrawer(),
      body: _isSaving 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildFaqTab(),
              ],
            ),
    );
  }

  Widget _buildAboutTab() {
    final l10n = AppLocalizations.of(context);
    if (_aboutControllersEs.isEmpty) {
      return Center(child: Text(l10n.get('loading_content')));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.get('intro_paragraphs'), style: Theme.of(context).textTheme.titleLarge),
              ElevatedButton.icon(
                onPressed: _saveAbout,
                icon: const Icon(Icons.save),
                label: Text(l10n.get('save_changes')),
                style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...List.generate(_aboutControllersEs.length, (index) {
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.get('paragraph_label', [index + 1]), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aboutControllersEs[index],
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: l10n.get('text_es'),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _aboutControllersEn[index],
                      maxLines: null,
                      decoration: InputDecoration(
                        labelText: l10n.get('text_en'),
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFaqTab() {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.get('faq_tab'), style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _addFaq,
                    icon: const Icon(Icons.add),
                    label: Text(l10n.get('add_faq')),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveFaqs,
                    icon: const Icon(Icons.save),
                    label: Text(l10n.get('save_all')),
                    style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _faqData.length,
            itemBuilder: (context, index) {
              final faq = _faqData[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  key: ValueKey(faq.id),
                  title: Text(faq.questionEs.isEmpty ? l10n.get('new_question') : faq.questionEs),
                  subtitle: Text('${l10n.get('sort_order')}: ${faq.sortOrder}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteFaq(faq.id, index),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => _faqData[index] = FaqEntry(
                              id: faq.id, questionEs: v, answerEs: faq.answerEs,
                              questionEn: faq.questionEn, answerEn: faq.answerEn, sortOrder: faq.sortOrder
                            ),
                            controller: TextEditingController(text: faq.questionEs)..selection = TextSelection.collapsed(offset: faq.questionEs.length),
                            decoration: InputDecoration(labelText: '${l10n.get('question')} (ES)', border: const OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) => _faqData[index] = FaqEntry(
                              id: faq.id, questionEs: faq.questionEs, answerEs: v,
                              questionEn: faq.questionEn, answerEn: faq.answerEn, sortOrder: faq.sortOrder
                            ),
                            controller: TextEditingController(text: faq.answerEs)..selection = TextSelection.collapsed(offset: faq.answerEs.length),
                            maxLines: null,
                            decoration: InputDecoration(labelText: '${l10n.get('answer')} (ES)', border: const OutlineInputBorder()),
                          ),
                          const Divider(height: 32),
                          TextField(
                            onChanged: (v) => _faqData[index] = FaqEntry(
                              id: faq.id, questionEs: faq.questionEs, answerEs: faq.answerEs,
                              questionEn: v, answerEn: faq.answerEn, sortOrder: faq.sortOrder
                            ),
                            controller: TextEditingController(text: faq.questionEn)..selection = TextSelection.collapsed(offset: faq.questionEn.length),
                            decoration: InputDecoration(labelText: '${l10n.get('question')} (EN)', border: const OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            onChanged: (v) => _faqData[index] = FaqEntry(
                              id: faq.id, questionEs: faq.questionEs, answerEs: faq.answerEs,
                              questionEn: faq.questionEn, answerEn: v, sortOrder: faq.sortOrder
                            ),
                            controller: TextEditingController(text: faq.answerEn)..selection = TextSelection.collapsed(offset: faq.answerEn.length),
                            maxLines: null,
                            decoration: InputDecoration(labelText: '${l10n.get('answer')} (EN)', border: const OutlineInputBorder()),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text('${l10n.get('sort_order')}: '),
                              SizedBox(
                                width: 60,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => _faqData[index] = FaqEntry(
                                    id: faq.id, questionEs: faq.questionEs, answerEs: faq.answerEs,
                                    questionEn: faq.questionEn, answerEn: faq.answerEn, sortOrder: int.tryParse(v) ?? faq.sortOrder
                                  ),
                                  controller: TextEditingController(text: faq.sortOrder.toString()),
                                  decoration: const InputDecoration(isDense: true),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
