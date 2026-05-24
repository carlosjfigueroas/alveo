import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_provider.dart';
import '../services/app_localizations.dart';
import '../providers/company_provider.dart';
import '../services/supabase_service.dart';
import 'home_screen.dart';
import 'admin/super_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = SupabaseService();

  Future<void> _login() async {
    final provider = context.read<AppProvider>();
    provider.setLoading(true);

    try {
      final response = await _service.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response.user != null) {
        final profile = await _service.getUserProfile(response.user!.id);
        provider.setUserProfile(profile);
        
        if (mounted) {
          if (profile?.role == 'super_admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const SuperAdminDashboard()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).get('invalid_login'))),
        );
      }
    } finally {
      provider.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final provider = context.watch<AppProvider>();
    final companyProv = context.watch<CompanyProvider>();
    final company = companyProv.currentCompany;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('login'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: company.logoUrl != null
                  ? Image.network(
                      company.logoUrl!,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                    )
                  : Image.asset(
                      'assets/images/logo_full.png', 
                      height: 50,
                      fit: BoxFit.contain,
                    ),
            ),
            Text(
              l10n.get('login_intro'),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: company.primaryColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.get('email'),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.get('password'),
                border: const OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: provider.isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: company.primaryColor, 
                  foregroundColor: Colors.white,
                ),
                child: provider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(l10n.get('login')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
