import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../providers/company_provider.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final company = context.watch<CompanyProvider>();
    final l10n = AppLocalizations.of(context);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final companyName = company.companyLocalizedName(isSpanish ? 'es' : 'en');
    
    // Use dynamic content or fallback to static l10n
    final regex = RegExp(r'\[?\s*NOMBRE\s+AGENCIA\s*\]?', caseSensitive: false);
    final paragraphs = appProvider.aboutContent.isNotEmpty 
        ? appProvider.aboutContent.map((c) => c.localizedValue(isSpanish, companyName)).toList()
        : [
            l10n.get('about_p1').replaceAll(regex, companyName),
            l10n.get('about_p2').replaceAll(regex, companyName),
            l10n.get('about_p3').replaceAll(regex, companyName),
            l10n.get('about_p4').replaceAll(regex, companyName),
            l10n.get('about_p5').replaceAll(regex, companyName),
          ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('about_title'))),
      body: RefreshIndicator(
        onRefresh: () {
          final companyId = context.read<CompanyProvider>().companyId;
          return appProvider.fetchSiteContent(companyId);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: company.logoUrl != null
                    ? Image.network(company.logoUrl!, height: 120, errorBuilder: (_,__,___) => const Icon(Icons.broken_image, size: 120))
                    : Image.asset('assets/images/logo_full.png', height: 120),
              ),
              const SizedBox(height: 32),
              Text(
                company.companyLocalizedName(isSpanish ? 'es' : 'en'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              ...paragraphs.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(p, style: const TextStyle(fontSize: 16, height: 1.5)),
              )),
              const Divider(height: 60),
              Text(
                l10n.get('contact_us').toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (company.contactEmail != null)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(company.contactEmail!),
                  onTap: () => launchUrl(Uri.parse('mailto:${company.contactEmail}'), mode: LaunchMode.externalApplication),
                ),
              if (company.contactPhone != null)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(isSpanish ? 'Teléfono' : 'Phone'),
                  subtitle: Text(company.contactPhone!),
                  onTap: () => launchUrl(Uri.parse('tel:${company.contactPhone}'), mode: LaunchMode.externalApplication),
                ),
              if (company.contactWhatsapp != null)
                ListTile(
                  leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                  title: const Text('WhatsApp'),
                  subtitle: Text(company.contactWhatsapp!),
                  onTap: () => launchUrl(Uri.parse('https://wa.me/${company.contactWhatsapp}'), mode: LaunchMode.externalApplication),
                ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
