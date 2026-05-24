import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/company_provider.dart';
import '../../services/app_themes.dart';
import '../../services/app_localizations.dart';
import '../../services/app_provider.dart';

class InviteFriendScreen extends StatefulWidget {
  const InviteFriendScreen({super.key});

  @override
  State<InviteFriendScreen> createState() => _InviteFriendScreenState();
}

class _InviteFriendScreenState extends State<InviteFriendScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _client = Supabase.instance.client;
  bool _isLoading = false;
  bool _isSuccess = false;

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final company = context.read<CompanyProvider>().currentCompany;
      // Link asombroso basado en el subdominio de la empresa, incluyendo remitente
      final registerLink = 'https://${company.domain}/#/register?ref_email=${Uri.encodeComponent(company.contactEmail ?? '')}';

      // Disparar Edge Function para notificar a la agencia que invita sobre el registro del referido
      await _client.functions.invoke('send-subscription-email', body: {
        'type': 'invite_friend',
        'target_email': _emailCtrl.text.trim(),
        'referrer_company_id': company.id,
        'referrer_company_name': company.name,
        'register_link': registerLink,
        'locale': context.read<AppProvider>().locale.languageCode,
      });

      if (mounted) {
        setState(() => _isSuccess = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar la invitación: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final company = context.watch<CompanyProvider>().currentCompany;
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';
    
    if (_isSuccess) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.get('invite_re_agency')),
          backgroundColor: company.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                l10n.get('invite_success_title'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.get('invite_success_msg'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSuccess = false;
                    _emailCtrl.clear();
                  });
                },
                child: Text(l10n.get('invite_send_another')),
              )
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('invite_re_agency')),
        backgroundColor: company.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppThemes.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppThemes.primaryGreen.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.redeem, size: 48, color: AppThemes.primaryGreen),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('invite_title_card'),
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppThemes.primaryGreen),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.get('invite_desc'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(height: 1.5),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildRewardBadge(Icons.domain_add, l10n.get('invite_reward_properties'), l10n.get('invite_reward_properties_desc')),
                            const SizedBox(width: 16),
                            _buildRewardBadge(Icons.add_a_photo, l10n.get('invite_reward_photos'), l10n.get('invite_reward_photos_desc')),
                            const SizedBox(width: 16),
                            _buildRewardBadge(Icons.sell, l10n.get('invite_reward_discount'), l10n.get('invite_reward_discount_desc')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.get('invite_disclaimer'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    l10n.get('invite_recipient_email'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.get('invite_email_hint'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty || !v.contains('@')) {
                        return l10n.get('required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.get('invite_godmother_agency'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: company.contactEmail ?? 'N/A',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: l10n.get('invite_godmother_email'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.verified, color: Colors.blue),
                      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : Colors.grey[50],
                      filled: true,
                    ),
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _sendInvite,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: company.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                        : Text(l10n.get('invite_send_btn'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRewardBadge(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppThemes.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppThemes.primaryGreen, size: 28),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.blueGrey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
