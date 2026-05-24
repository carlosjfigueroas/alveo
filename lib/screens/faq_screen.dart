import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../services/app_themes.dart';
import '../providers/company_provider.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final companyProvider = context.watch<CompanyProvider>();
    final companyName = companyProvider.companyLocalizedName(isSpanish ? 'es' : 'en');

    final regex = RegExp(r'\[?\s*NOMBRE\s+AGENCIA\s*\]?', caseSensitive: false);
    final faqs = appProvider.faqs.isNotEmpty 
        ? appProvider.faqs.map((f) => {
            'q': f.localizedQuestion(isSpanish, companyName),
            'a': f.localizedAnswer(isSpanish, companyName),
          }).toList()
        : [
            {'q': l10n.get('faq1_q').replaceAll(regex, companyName), 'a': l10n.get('faq1_a').replaceAll(regex, companyName)},
            {'q': l10n.get('faq2_q').replaceAll(regex, companyName), 'a': l10n.get('faq2_a').replaceAll(regex, companyName)},
            {'q': l10n.get('faq3_q').replaceAll(regex, companyName), 'a': l10n.get('faq3_a').replaceAll(regex, companyName)},
            {'q': l10n.get('faq4_q').replaceAll(regex, companyName), 'a': l10n.get('faq4_a').replaceAll(regex, companyName)},
            {'q': l10n.get('faq5_q').replaceAll(regex, companyName), 'a': l10n.get('faq5_a').replaceAll(regex, companyName)},
          ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('faq_title'))),
      body: RefreshIndicator(
        onRefresh: () {
          final companyId = context.read<CompanyProvider>().companyId;
          return appProvider.fetchSiteContent(companyId);
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                title: Text(
                  faq['q'] ?? '', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppThemes.primaryGreen)
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Text(
                      faq['a'] ?? '', 
                      style: const TextStyle(fontSize: 16, height: 1.5)
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
