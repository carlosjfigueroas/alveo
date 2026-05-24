import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../services/app_localizations.dart';
import '../screens/admin/admin_company_settings.dart';

class SuspensionWrapper extends StatelessWidget {
  final Widget child;

  const SuspensionWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isSuspended = context.watch<CompanyProvider>().isSuspended;
    final isSpanish = AppLocalizations.of(context).locale.languageCode == 'es';

    if (!isSuspended) return child;

    return Stack(
      children: [
        // La UI original detrás (borrosa)
        child,
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_clock_outlined, size: 80, color: Colors.orange),
                          const SizedBox(height: 24),
                          Text(
                            isSpanish ? '¡Suscripción Suspendida!' : 'Subscription Suspended!',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSpanish 
                              ? 'Tu periodo de uso ha finalizado. Para reactivar tu panel y seguir gestionando tus inmuebles, por favor reporta tu pago.'
                              : 'Your usage period has ended. To reactivate your panel and continue managing your properties, please report your payment.',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.send_to_mobile),
                            label: Text(
                              isSpanish ? 'REPORTAR PAGO AHORA' : 'REPORT PAYMENT NOW',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const AdminCompanySettings()),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isSpanish 
                              ? 'Tus datos están seguros, se activarán de inmediato tras la aprobación.'
                              : 'Your data is safe, it will be activated immediately upon approval.',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
