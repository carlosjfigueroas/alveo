import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../providers/company_provider.dart';
import '../services/app_themes.dart';
import '../screens/login_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/about_screen.dart';
import '../screens/faq_screen.dart';
import '../screens/admin/super_admin_dashboard.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyProv = context.watch<CompanyProvider>();
    final company = companyProv.currentCompany;
    final appProvider = context.watch<AppProvider>();
    final l10n = AppLocalizations(appProvider.locale);
    final isSpanish = appProvider.locale.languageCode == 'es';
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Drawer(
      child: Column(
        children: [
          SizedBox(
            height: 90, // Even more compact
            child: DrawerHeader(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 48), // Increased breathing room
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(color: company.primaryColor),
              child: Center(
                child: company.logoUrl != null
                    ? Image.network(company.logoUrl!, height: 35, fit: BoxFit.contain)
                    : Image.asset('assets/images/logo_full.png', height: 35, fit: BoxFit.contain),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const Divider(),
                // Navigation
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.home, color: AppThemes.primaryGreen, size: 20),
                  title: Text(l10n.get('home'), style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    companyProv.resetToHome();
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.info_outline, color: AppThemes.primaryGreen, size: 20),
                  title: Text(l10n.get('about'), style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
                  },
                ),
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.help_outline, color: AppThemes.primaryGreen, size: 20),
                  title: Text(l10n.get('faq'), style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()));
                  },
                ),
                const Divider(),
                // Toggles
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.language, color: AppThemes.primaryGreen, size: 20),
                  title: Text(l10n.get('language'), style: const TextStyle(fontSize: 14)),
                  onTap: () => appProvider.setLocale(isSpanish ? const Locale('en') : const Locale('es')),
                ),
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: Icon(
                    appProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                    color: AppThemes.primaryGreen,
                    size: 20,
                  ),
                  title: Text(appProvider.themeMode == ThemeMode.light 
                    ? l10n.get('dark_mode') 
                    : l10n.get('light_mode'), style: const TextStyle(fontSize: 14)),
                  onTap: () => appProvider.toggleTheme(),
                ),
                const Divider(),
            // Auth Action
            if (appProvider.userProfile == null)
              ListTile(
                visualDensity: const VisualDensity(vertical: -4),
                minVerticalPadding: 0,
                leading: const Icon(Icons.login, color: AppThemes.primaryGreen, size: 20),
                title: Text(l10n.get('login').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: const SizedBox(width: 400, child: LoginScreen()),
                    ),
                  );
                },
              )
            else ...[
              // Admin Panel link (Only for roles permitted)
              if (appProvider.isAdmin)
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.admin_panel_settings, color: AppThemes.primaryGreen, size: 20),
                  title: Text(l10n.get('admin_panel'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
                  },
                ),
              // Super Admin Panel link (STRICT: role must be exactly 'super_admin')
              if (appProvider.userProfile?.role == 'super_admin')
                ListTile(
                  visualDensity: const VisualDensity(vertical: -4),
                  minVerticalPadding: 0,
                  leading: const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                  title: Text(l10n.get('super_panel'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminDashboard()));
                  },
                ),
              ListTile(
                visualDensity: const VisualDensity(vertical: -4),
                minVerticalPadding: 0,
                leading: const Icon(Icons.logout, color: AppThemes.terracottaRed, size: 20),
                title: Text(
                  l10n.get('logout').toUpperCase(),
                  style: const TextStyle(color: AppThemes.terracottaRed, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await appProvider.signOut();
                },
              ),
            ],
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(onPressed: () => _launchURL(companyProv.instagramUrl ?? 'https://instagram.com'), icon: const FaIcon(FontAwesomeIcons.instagram, color: Colors.grey, size: 20)),
                      IconButton(onPressed: () => _launchURL(companyProv.facebookUrl ?? 'https://facebook.com'), icon: const FaIcon(FontAwesomeIcons.facebook, color: Colors.grey, size: 20)),
                      IconButton(onPressed: () => _launchURL(companyProv.telegramUrl ?? 'https://telegram.org'), icon: const FaIcon(FontAwesomeIcons.telegram, color: Colors.grey, size: 20)),
                      if (companyProv.contactEmail != null)
                        IconButton(onPressed: () => _launchURL('mailto:${companyProv.contactEmail}'), icon: const Icon(Icons.email_outlined, color: Colors.grey, size: 22)),
                      IconButton(onPressed: () => _launchURL('https://wa.me/${companyProv.contactWhatsapp ?? ""}'), icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.grey, size: 20)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
