# Alveo - Current Task Context

Este archivo sirve como memoria operativa corta para retomar trabajo si la conversacion se compacta o se pierde contexto.

## Contexto base

- Proyecto: Alveo.
- Naturaleza: Asistente Inmobiliario SaaS/PMS multi-tenant para agencias inmobiliarias.
- Fuente de reglas maestras: `PROJECT_KNOWLEDGE.md`.
- Antes de tocar codigo, leer `PROJECT_KNOWLEDGE.md` y este archivo.

## Reglas criticas a recordar

- No hardcodear textos visibles: usar `AppLocalizations`.
- Proteger siempre el aislamiento multi-tenant por `company_id` y RLS.
- UI mobile-first, responsiva, premium y compatible con dark mode.
- Agentes: lectura global del inventario, escritura restringida a inmuebles donde son captadores.
- Leads: privados por agente cuando estan asignados; reasignacion solo por admin/company_admin.
- Emails transaccionales: nunca desde Flutter directamente; usar Supabase Edge Functions/Brevo.
- Produccion usa URLs limpias; desarrollo local puede usar hash routing.
- Despliegue Vercel: solo proyecto `web`.
- Flutter local: `C:\src\flutter\bin\flutter.bat`.

## Estado reconstruido

La conversacion anterior se compacto/perdio. Se reconstruyo contexto leyendo `PROJECT_KNOWLEDGE.md`.

Se observaron cambios recientes el 2026-05-23 alrededor de las 21:11-21:15 en:

- `lib/services/commission_pdf_service.dart`
- `lib/screens/register_screen.dart`
- multiples archivos de `lib/screens`, `lib/widgets`, `lib/services`, `lib/models`
- `pubspec.yaml`
- `pubspec.lock`
- `analyze_after.txt`
- archivos generados de plugins Flutter en plataformas

No hay repositorio Git inicializado en esta carpeta, asi que no existe historial local para reconstruir diffs o commits.

## Tarea actual

- Crear y mantener esta memoria operativa.
- Si el usuario dice "apuntalo", sintetizar aprendizajes nuevos y actualizar `PROJECT_KNOWLEDGE.md` o este archivo segun corresponda.
- Si se empieza una tarea tecnica concreta, registrar aqui:
  - objetivo
  - archivos relevantes
  - comandos ejecutados
  - errores pendientes
  - proximo paso

## Proximo paso sugerido

Inicializar Git o copiar el proyecto a un repo con control de versiones para poder reconstruir cambios con precision si vuelve a perderse el contexto.
