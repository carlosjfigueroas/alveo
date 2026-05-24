import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../services/supabase_service.dart';
import '../services/app_themes.dart';
import '../screens/home_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_properties_screen.dart';
import '../screens/admin/admin_owners_screen.dart';
import '../screens/admin/carousel_manager_screen.dart';
import '../screens/admin/change_password_screen.dart';
import '../screens/admin/admin_leads_screen.dart';
import '../screens/admin/admin_calendar_screen.dart';
import '../screens/admin/admin_content_editor.dart';
import '../screens/admin/admin_locations_screen.dart';
import '../screens/admin/admin_company_settings.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/invite_friend_screen.dart';
import '../screens/admin/admin_profile_screen.dart';

import '../providers/company_provider.dart';
import '../screens/commissions_list_screen.dart';
import '../screens/agent_commissions_screen.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final company = context.watch<CompanyProvider>().currentCompany;
    final service = SupabaseService();
    final isSpanish = provider.locale.languageCode == 'es';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: company.primaryColor),
            accountName: Text(provider.userProfile?.fullName ?? 'Admin'),
            accountEmail: Text(service.currentUser?.email ?? ''),
            currentAccountPicture: company.logoAbbrUrl != null
                ? Image.network(company.logoAbbrUrl!, height: 48, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.business, color: Colors.white, size: 36))
                : Image.asset('assets/images/logo_abbr.png', height: 48, fit: BoxFit.contain),
          ),

          ListTile(
            leading: const Icon(Icons.person_pin, color: Colors.indigo),
            title: Text(l10n.get('my_profile') ?? (isSpanish ? 'Mi Perfil' : 'My Profile')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: Text(l10n.get('dashboard')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.business),
            title: Text(l10n.get('spaces')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminPropertiesScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text(l10n.get('owners')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminOwnersScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.image, color: AppThemes.primaryGreen),
            title: Text(l10n.get('carousel_manager')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CarouselManagerScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note, color: Colors.blue),
            title: Text(l10n.get('content_management')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminContentEditor()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.location_on, color: Colors.purple),
            title: Text(l10n.get('locations_menu')),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminLocationsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.mail, color: Colors.orange),
            title: Text(l10n.get('leads')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminLeadsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month, color: Color(0xFF6A1B9A)),
            title: Text(l10n.get('agenda')),
            trailing: FutureBuilder<int>(
              future: service.getTodayAppointmentsCount(company.id, agentId: provider.userProfile?.role == 'agent' ? provider.userProfile?.id : null),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6A1B9A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${snapshot.data}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminCalendarScreen()),
            ),
          ),
          if (provider.isCompanyAdmin || provider.isSuperAdmin)
            ListTile(
              leading: const Icon(Icons.monetization_on, color: Colors.green),
              title: Text(l10n.get('commissions')),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const CommissionsListScreen()),
              ),
            ),
          if (provider.userProfile?.role == 'agent')
            ListTile(
              leading: const Icon(Icons.monetization_on_outlined, color: Colors.teal),
              title: Text(l10n.get('my_commissions')),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AgentCommissionsScreen()),
              ),
            ),

          if (provider.isCompanyAdmin || provider.isSuperAdmin) ...[
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: Text(l10n.get('edit_company')),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminCompanySettings()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline, color: Colors.blue),
              title: Text(l10n.get('users_management')),
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
              ),
            ),
          ],
          ListTile(
            leading: const Icon(Icons.lock_reset, color: AppThemes.primaryGreen),
            title: Text(l10n.get('change_password')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          if (company.showReferralMenu)
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.pinkAccent),
            title: Text(l10n.get('invite_re_agency'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InviteFriendScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n.get('welcome')),
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.get('logout'),
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await service.signOut();
              provider.setUserProfile(null);
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
