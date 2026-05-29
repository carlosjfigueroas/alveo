import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/app_provider.dart';
import 'services/app_themes.dart';
import 'providers/company_provider.dart';
import 'services/company_service.dart';
import 'screens/home_screen.dart';
import 'screens/suspended_screen.dart';
import 'screens/register_screen.dart';
import 'services/supabase_service.dart';
import 'models/user_profile.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ummvqwhdidlhfybnjmzc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVtbXZxd2hkaWRsaGZ5Ym5qbXpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0NTkyMjksImV4cCI6MjA5MDAzNTIyOX0.iXh1kUXUkCTJkWSeKRKrQvghyKg7K-bpgzS3UAQZzX4',
  );

  // ── Detectar empresa activa por dominio ──────────────────────────────────
  // CompanyProvider.initialize() also loads LocationData with the correct
  // company-specific fallback, so no separate LocationData.init() needed here.
  final companyProvider = CompanyProvider();
  await companyProvider.initialize();
  // ────────────────────────────────────────────────────────────────────────

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider.value(value: companyProvider),
      ],
      child: const AlveoApp(),
    ),
  );
}

class AlveoApp extends StatelessWidget {
  const AlveoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final companyProvider = context.watch<CompanyProvider>();

    return MaterialApp(
      title: companyProvider.isLoading ? 'Alveo' : companyProvider.companyName,
      debugShowCheckedModeBanner: false,
      theme: companyProvider.isLoading
          ? ThemeData.light()
          : AppThemes.buildLightTheme(
              companyProvider.currentCompany.primaryColor,
              companyProvider.currentCompany.secondaryColor,
            ),
      darkTheme: companyProvider.isLoading
          ? ThemeData.dark()
          : AppThemes.buildDarkTheme(
              companyProvider.currentCompany.primaryColor,
              companyProvider.currentCompany.secondaryColor,
            ),
      themeMode: appProvider.themeMode,
      locale: appProvider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      onGenerateRoute: (settings) {
        final String routeName = settings.name ?? '';
        debugPrint('[ROUTER] onGenerateRoute name: $routeName');
        // Normalizar la ruta para que siempre empiece con / y no tenga slash al final
        String normalizedPath = routeName.startsWith('/') ? routeName : '/$routeName';
        if (normalizedPath.length > 1 && normalizedPath.endsWith('/')) {
          normalizedPath = normalizedPath.substring(0, normalizedPath.length - 1);
        }
        
        if (normalizedPath == '/' || normalizedPath.isEmpty) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => companyProvider.isLoading
                ? const Scaffold(
                    backgroundColor: AppThemes.primaryGreen,
                    body: Center(child: CircularProgressIndicator(color: Colors.white)),
                  )
                : (companyProvider.isSuspended ? const SuspendedScreen() : const HomeScreen()),
          );
        }

        if (normalizedPath == '/register') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const RegisterScreen(),
          );
        }

        final uri = Uri.parse(normalizedPath);
        final segments = uri.pathSegments;
        
        // Manejar /agent/:slug y /agent/:slug/:propertyRef
        if (segments.length >= 2 && segments.first == 'agent') {
          final slug = segments[1];
          final propertyRef = segments.length > 2 ? segments[2] : null;
          debugPrint('[ROUTER] Matched Agent Route - slug: $slug, propertyRef: $propertyRef');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => AgentRouteWrapper(slug: slug, propertyRef: propertyRef),
          );
        }

        // Manejar /refXXX (Link directo sin agente)
        if (segments.length == 1 && segments[0].toLowerCase().startsWith('ref')) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => HomeScreen(initialPropertyRef: segments[0]),
          );
        }

        // Manejar posibles alias de vendedores en la raíz (Estrategia 2)
        if (segments.length == 1) {
          final potentialAlias = segments[0];
          const reserved = ['register', 'login', 'faq', 'about', 'admin', 'agent'];
          
          if (!reserved.contains(potentialAlias.toLowerCase())) {
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => SalespersonRouteWrapper(alias: potentialAlias),
            );
          }
        }
        
        return null;
      },
    );
  }
}

class AgentRouteWrapper extends StatefulWidget {
  final String slug;
  final String? propertyRef;
  const AgentRouteWrapper({super.key, required this.slug, this.propertyRef});

  @override
  State<AgentRouteWrapper> createState() => _AgentRouteWrapperState();
}

class _AgentRouteWrapperState extends State<AgentRouteWrapper> {
  UserProfile? _agent;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAgent();
  }

  Future<void> _loadAgent() async {
    final agent = await SupabaseService().getProfileBySlug(widget.slug);
    if (!mounted) return;

    if (agent != null) {
      context.read<AppProvider>().setAgentContext(agent);
    }

    setState(() {
      _agent = agent;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // El agentContext ya está en el provider — HomeScreen lo verá desde el primer build
    return HomeScreen(initialPropertyRef: widget.propertyRef);
  }
}

class SalespersonRouteWrapper extends StatefulWidget {
  final String alias;
  const SalespersonRouteWrapper({super.key, required this.alias});

  @override
  State<SalespersonRouteWrapper> createState() => _SalespersonRouteWrapperState();
}

class _SalespersonRouteWrapperState extends State<SalespersonRouteWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAlias();
  }

  Future<void> _checkAlias() async {
    final salesperson = await CompanyService.getSalespersonByAlias(widget.alias);
    if (mounted) {
      if (salesperson != null) {
        context.read<AppProvider>().setReferralContext(
          salespersonAlias: salesperson['alias'],
          salespersonName: salesperson['full_name'],
        );
      }
      // Redirigir a la home limpia para que el usuario pueda navegar
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
