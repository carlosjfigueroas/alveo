import 'package:flutter/material.dart';
import '../services/subscription_service.dart';

class ReferralDialog extends StatefulWidget {
  final bool isSpanish;
  final String activeStrategy;
  
  const ReferralDialog({super.key, required this.isSpanish, required this.activeStrategy});

  @override
  State<ReferralDialog> createState() => _ReferralDialogState();

  static Future<String?> show(BuildContext context, bool isSpanish, String activeStrategy) {
    return showDialog<String>(
      context: context,
      builder: (_) => ReferralDialog(isSpanish: isSpanish, activeStrategy: activeStrategy),
    );
  }
}

class _ReferralDialogState extends State<ReferralDialog> {
  final TextEditingController _emailCtrl = TextEditingController();
  final SubscriptionService _subService = SubscriptionService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = widget.isSpanish ? 'Ingrese un correo válido.' : 'Enter a valid email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final referredCompanyId = await _subService.resolveReferralByEmail(email);
      
      if (mounted) {
        if (referredCompanyId != null) {
          // Success, pass back the validated email
          Navigator.pop(context, email);
        } else {
          setState(() {
            _errorMessage = widget.isSpanish 
              ? 'No encontramos ninguna agencia con ese correo.'
              : 'We could not find any company with that email.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = widget.isSpanish ? 'Error de conexión.' : 'Connection error.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // We are passing explicit isSpanish to not depend exclusively on AppProvider's context 
    // (useful for the public registration screen outside the main app tree)
    
    return AlertDialog(
      title: Text(
        widget.isSpanish ? '¿Cómo llegaste a Alveo?' : 'How did you find Alveo?',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSpanish
                  ? (widget.activeStrategy == 'strategy_3'
                      ? 'Si alguien te recomendó esta plataforma, escribe el correo de su inmobiliaria. Esa agencia recibirá +2 inmuebles y +2 fotos de límite de capacidad, más un descuento de \$1/mes en su próxima factura.'
                      : 'Si alguien te recomendó esta plataforma, escribe su correo electrónico. Esa persona recibirá un descuento de \$1/mes por cada agencia que recomiende exitosamente.')
                  : (widget.activeStrategy == 'strategy_3'
                      ? 'If someone referred you to this platform, enter their company email address. That company will receive a capacity increase of +2 properties and +2 photos, plus a \$1/month discount on their next bill.'
                      : 'If someone referred you to this platform, enter their email address. That person will receive a \$1/month discount for every successful referral.'),
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: InputDecoration(
                labelText: widget.isSpanish ? 'Correo del Referente' : 'Referrer\'s Email',
                prefixIcon: const Icon(Icons.email),
                border: const OutlineInputBorder(),
                errorText: _errorMessage,
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verifyEmail(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          child: Text(widget.isSpanish ? 'Omitir' : 'Skip'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyEmail,
          child: _isLoading 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(widget.isSpanish ? 'Aplicar Descuento' : 'Apply Discount'),
        ),
      ],
    );
  }
}
