# Alveo - Core Business Rules & Philosophy

Este documento contiene las reglas maestras que rigen el desarrollo y la experiencia de usuario de la plataforma Alveo.

## Regla #0: Naturaleza del Proyecto (SaaS PMS)
**Definición**: Alveo es una aplicación SaaS (Software as a Service) de tipo PMS (Property Management System).
**Implicaciones**:
*   El objetivo no es solo publicar inmuebles, sino gestionar el flujo completo del negocio inmobiliario.
*   Debe ser escalable, permitiendo múltiples empresas (agencias) con total aislamiento de datos.
*   La robustez y la integridad de la información operativa (clientes, cierres, comisiones) son tan importantes como la estética visual.

## Regla #1: Captación vía Redes Sociales
**Definición**: La principal forma de captación de posibles clientes es a través de las redes sociales.
**Implicaciones**:
*   Cada inmueble debe ser "compartible" de forma atractiva.
*   Las publicaciones en redes de la Agencia o de los Agentes deben incluir siempre un link hacia la App Web.
*   La App Web debe estar optimizada para recibir tráfico móvil proveniente de redes sociales (carga rápida, botones de contacto claros, diseño responsivo).
*   Se debe priorizar la generación de leads directos (WhatsApp/Email) desde los links compartidos.

## Regla #2: Identidad de Marca (White-Label First)
**Definición**: El software debe adaptarse a la identidad de la Agencia y del Agente, no al revés.
**Implicaciones**:
*   Priorizar la personalización de colores, logos y perfiles públicos.
*   La experiencia del cliente final debe sentir que está en el portal oficial de la agencia o del agente.

## Regla #3: Transparencia Colaborativa
**Definición**: El inventario es un activo colectivo de la Agencia.
**Implicaciones**:
*   Todos los agentes pueden ver y ofrecer todos los inmuebles de la oficina.
*   El sistema debe reconocer y proteger siempre al "Captador" del inmueble en la repartición de comisiones.

## Regla #4: Privacidad Estructural (RLS)
**Definición**: La seguridad de los datos es automática y no depende del programador.
**Implicaciones**:
*   Uso estricto de Row Level Security (RLS) en Supabase.
*   Un agente solo accede a sus propios leads, cierres y datos sensibles por diseño de base de datos.

## Regla #5: Estética Premium & Confianza
**Definición**: El diseño es nuestra primera herramienta de venta.
**Implicaciones**:
*   Uso de temas modernos, modo oscuro pulido y tipografía profesional.
*   Evitar formularios tediosos; la interfaz debe ser fluida y "limpia".

## Regla #6: Velocidad de Respuesta (Speed-to-Lead)
**Definición**: Reducir la fricción entre el interés y el contacto humano.
**Implicaciones**:
*   Botones de WhatsApp prominentes y pre-configurados.
*   Notificaciones y asignación automática de leads para evitar que un cliente "se enfríe".

## Regla #7: Multi-Tenancy vía Subdominios
**Definición**: Cada agencia accede a su portal a través de un subdominio único en el dominio oficial `alveo.fyi` (ej: `agencia-uno.alveo.fyi`).
**Implicaciones**:
*   La App debe detectar automáticamente la empresa (company_id) basándose en el subdominio de la URL (ej: `www.tuhogar.alveo.fyi`).
*   Esto facilita que los agentes compartan links que ya vienen pre-configurados para su agencia.
*   Permite el aislamiento total de la experiencia de usuario desde el momento en que se carga la página.

## Regla #8: Acceso Global & Modo Demo
**Definición**: El punto de entrada principal es `www.demo.alveo.fyi`. Si un usuario entra en el dominio raíz (`www.alveo.fyi`), el sistema lo redirecciona automáticamente al modo Demo.
**Implicaciones**:
*   **Super Usuario**: Solo el Super Admin puede ver la consolidación de todos los inmuebles de todas las empresas desde este modo.
*   **Super Panel**: Opción de menú exclusiva para el Super Admin para gestionar el entorno completo (agencias, suscripciones, configuraciones globales).
*   **Modo Vitrina**: Para usuarios no logueados, el modo Demo sirve como catálogo global de ejemplo.

## Regla #9: Auto-Registro (Instant Activation)
**Definición**: Existe una página pública `/register` diseñada para la captación orgánica y rápida de nuevas agencias.
**Implicaciones**:
*   El flujo de registro es "Self-Service": al completar el formulario, **el sistema crea la empresa, el entorno y el usuario administrador de forma inmediata**.
*   No existe paso intermedio de aprobación manual para el flujo público; el objetivo es que la agencia pueda empezar a trabajar al instante.
*   **Opción Administrativa**: El Super Admin mantiene la capacidad de crear empresas manualmente desde el Super Panel para casos especiales o ventas directas fuera del flujo público.

## Regla #10: Estrategias de Crecimiento (Referidos)
**Definición**: El sistema soporta 3 estrategias principales para la captación de clientes:
1.  **Estrategia #1 (Referidos)**: Captación vía red de contactos.
    *   **Sub-Estrategia (Invita a un amigo)**: Recompensa directa al usuario que invita a otra agencia a unirse a Alveo.
2.  **Estrategia #2 (Marketing Digital)**: Tráfico directo vía pauta y SEO.
3.  **Estrategia #3 (Alianzas)**: Convenios con asociaciones inmobiliarias.
**Implicaciones**:
*   El sistema debe trackear el `acquisition_channel` de cada nueva agencia.
*   Las recompensas (descuentos, bonos de inmuebles/fotos) se aplican automáticamente según la estrategia activa.

## Regla #11: Gestión de Suscripciones (SaaS Health)
**Definición**: El acceso a las funciones de PMS está ligado al estado de la suscripción.
**Implicaciones**:
*   Las empresas con suscripción `suspended` ven un bloqueo en su panel administrativo pero mantienen su inventario público (modo lectura) para no romper links de redes sociales.

## Regla #12: Experiencia Bilingüe Nativa (i18n)
**Definición**: Alveo nace como una plataforma internacional y escalable. i18n debe ser una prioridad en cada tarea.
**Implicaciones**:
*   **Prohibido el Hardcoding**: Ningún texto visible al usuario debe estar escrito directamente en el código. Debe usarse siempre `AppLocalizations`.
*   **Mentalidad de Refactor**: En cada revisión o refactorización, se debe verificar y corregir cualquier texto que no esté internacionalizado.
*   **Soporte Multilingüe**: Todo el contenido (emails, reportes, botones, errores) debe estar disponible en Español e Inglés desde el lanzamiento.
*   **Adaptabilidad**: El sistema debe detectar el idioma del navegador, pero permitir el cambio manual fácil y persistente.

## Regla #13: Seguridad a Nivel de Datos (RLS First)
**Definición**: Cada implementación que afecte a la base de datos debe tener presente las políticas de Row Level Security (RLS) de Supabase para asegurar el aislamiento y seguridad de los datos.
**Implicaciones**:
*   **Seguridad Estructural**: No confiar únicamente en la lógica del frontend o del servicio para el aislamiento de datos entre empresas.
*   **Validación de Roles**: Verificar que las políticas de RLS permitan las operaciones de CRUD necesarias para cada rol (Admin, Agente, Super Admin).
*   **Aislamiento Multi-Tenant**: Asegurar que un usuario de una empresa nunca pueda ver ni modificar datos de otra empresa, incluso si conoce los IDs.

## Regla #14: Manejo de Dropdowns Asíncronos
**Definición**: Los dropdowns que dependen de datos externos (Supabase) deben ser resilientes a condiciones de carrera (race conditions).
**Implicaciones**:
*   **Guarda de Valor**: Siempre usar una guarda lógica (`items.any(e => e.id == value) ? value : null`) en el atributo `value` del dropdown para evitar que Flutter lance una excepción o resetee el campo a null silenciosamente si el valor llega antes que la lista.
*   **Contexto de Carga**: Al cargar listas dependientes (agentes, propietarios), usar siempre el ID de empresa del objeto que se está editando en lugar del contexto global de la sesión, para asegurar consistencia en entornos multi-tenant.

## Regla #15: Prohibido el Silencio en Validaciones
**Definición**: Un formulario nunca debe fallar la validación sin dar feedback visual inmediato y claro.
**Implicaciones**:
*   **Consistencia de Estado**: No aplicar validadores `required` a campos que están deshabilitados (`onChanged: null`) o son de solo lectura si existe la posibilidad de que su valor inicial sea nulo.
*   **Feedback de Errores**: Si la validación falla, el sistema debe asegurar que el usuario vea el error (scroll automático o SnackBar informativo) para evitar la sensación de que el botón de guardado "no hace nada".

## Regla #16: Preservación de Contexto (Super Admin Safety)
**Definición**: Las acciones de un Super Admin (con contexto global) no deben alterar accidentalmente la propiedad de los datos de una agencia.
**Implicaciones**:
*   **Integridad de IDs**: Al actualizar registros, se debe preservar el `company_id` original del objeto. No se debe sobrescribir con el `companyId` de la sesión actual si este es nulo (caso típico de los Super Admins).
*   **Aislamiento de Listas**: Las consultas para poblar selectores (agentes de una empresa) deben filtrarse por la empresa propietaria del registro, no por la empresa seleccionada en el dashboard global.

## Regla #17: Confirmación Explícita de Refresco (UI Sync)
**Definición**: La sincronización entre la base de datos y la interfaz debe ser explícita para evitar datos obsoletos (stale data).
**Implicaciones**:
*   **Señal de Éxito**: Usar siempre `Navigator.pop(context, true)` tras una operación exitosa de creación o edición. 
*   **Refresco Condicional**: La pantalla receptora debe verificar este valor de retorno (`result == true`) para disparar un refresco de sus listas, garantizando que el usuario vea sus cambios de inmediato sin necesidad de recargar manualmente.

## Regla #18: Límites de Inventario y Contenido (SaaS Quotas)
**Definición**: Para mantener la salud del entorno SaaS, existen límites predefinidos de almacenamiento y registros por agencia.
**Implicaciones**:
*   **Límites por Defecto**: Cada agencia inicia con una capacidad máxima de **35 inmuebles activos** y 10 fotos por cada inmueble.
*   **Conteo de Inmuebles Activos**: Para no penalizar el éxito de la agencia y permitir la conservación de su historial comercial, los inmuebles con estatus **Vendido** (`Vendido`) y **Alquilado** (`Alquilado`) quedan completamente excluidos del conteo del límite de inventario. Únicamente los inmuebles con estatus **Disponible** y **Reservado** consumen cupos activos. El indicador de la interfaz refleja de forma transparente `Inmuebles Activos / Límite` (ej: `3 / 35`).
*   **Incentivos de Crecimiento**: Estos límites son dinámicos y pueden expandirse automáticamente mediante el sistema de referidos ("Invita a un amigo").
*   **Gestión del Super Usuario**: El Super Admin tiene la autoridad exclusiva para modificar estos límites manualmente para agencias específicas o casos especiales desde el Super Panel.
*   **Filtros de Estado de Inventario**: El Panel de Administración de Inmuebles cuenta con una fila de botones de selección (ChoiceChips) interactivos que permiten filtrar instantáneamente la lista por estatus: **Todos**, **Disponible**, **Reservado**, **Vendido** y **Alquilado**. Esta funcionalidad está completamente internacionalizada (i18n), traduciendo automáticamente los estatus según el idioma configurado (Español / Inglés).
*   **Tarjetas Públicas con Badges de Estatus**: Las tarjetas de inmuebles en la página principal pública (`PropertyCard`) preservan sus proporciones y tamaños de diseño originales intactos. Sobrepuesto elegantemente en la esquina superior izquierda de la imagen se añade un badge de estatus semitransparente con soporte i18n (ej. **Vendido / Sold**, **Alquilado / Rented**, etc.). Para inmuebles no disponibles (vendidos o alquilados), el botón *"Me Interesa"* se deshabilita automáticamente y muestra la etiqueta *"No Disponible / Not Available"*, optimizando el embudo de captación de leads.

## Regla #19: Construcción de Enlaces Multi-Tenant (SaaS URLs)
**Definición**: Todos los enlaces públicos o vistas previas de URL generados en la interfaz deben reflejar la arquitectura multi-tenant (subdominios por agencia) y ofrecer una UX clara para campos dinámicos.
**Implicaciones**:
*   **Dominios Dinámicos**: Nunca incrustar (hardcodear) `localhost` o dominios estáticos genéricos en la UI. Extraer siempre el identificador de la agencia activa (`company.abbr`) a través de `CompanyProvider` para construir la URL (ej. `https://${company.abbr}.alveo.fyi/...`).
*   **Placeholders Claros**: Si un enlace depende de un alias o "slug" configurable por el usuario y este se encuentra vacío, mostrar siempre un placeholder ilustrativo (ej: `tu-alias`) para evitar que el enlace se vea cortado o parezca un error técnico.

## Regla #20: Enrutamiento de Leads y Experiencia de Navegación (Routing & Attribution)
**Definición**: La experiencia del visitante anónimo y la asignación de prospectos (leads) se adapta de forma dinámica según la URL de entrada.
**Implicaciones**:
1.  **Modo Agente (`/agent/alias`)**: Si el usuario entra por el link personal de un agente, la UI de todo el catálogo se personaliza con la foto y datos de ese agente. **Cualquier lead generado en esa sesión se asigna a dicho agente**, sin importar quién sea el captador original de la propiedad.
2.  **Modo Agencia (Dominio raíz)**: Si el usuario entra directamente al subdominio de la agencia (ej: `https://agencia.alveo.fyi`):
    *   La UI muestra la marca corporativa (logo, información general de contacto).
    *   **Leads Genéricos**: Si usan un formulario de contacto general, el lead va a la bandeja de la Agencia (sin agente asignado) para distribución administrativa.
    *   **Leads de Propiedad**: Si el usuario solicita información de un inmueble específico, el lead se enruta automáticamente al "Captador" (`listing_agent_id`) de ese inmueble. Si no tiene captador, va a la bandeja general.

## Regla #21: Estrategia de Enrutamiento Web (URL Strategy)
**Definición**: Alveo, como plataforma SaaS y portal inmobiliario, debe manejar sus rutas siguiendo los estándares de navegabilidad web.
**Implicaciones**:
1.  **Entorno Local (Desarrollo)**: Flutter Web utiliza por defecto el "Hash Routing" (`#`). Por lo tanto, para pruebas locales de rutas dinámicas, el formato correcto incluye el hash (ej. `http://localhost:8080/#/agent/alias`).
2.  **Entorno de Producción**: Para asegurar un aspecto corporativo (y mejorar el SEO), en producción se implementa el "Path URL Strategy". Esto permite URLs limpias.
3.  **Generación de Enlaces**: Todas las partes del código que generen un enlace para copiar al portapapeles o para compartir deben asumir siempre el formato limpio de producción (sin `#`), para garantizar que los enlaces compartidos por los agentes sean siempre profesionales.

## Regla #22: Manejo de Estado en Rutas Asíncronas (Avoid Future Loops)
**Definición**: Las consultas a la base de datos para resolver parámetros de URL (como buscar un agente por su slug) deben estar protegidas arquitectónicamente contra repintados (rebuilds) continuos de la interfaz.
**Implicaciones**:
1.  **Cero Futures al Vuelo**: Queda estrictamente prohibido instanciar llamadas de red directas (ej. `SupabaseService().getProfileBySlug()`) dentro de constructores de ruta o dentro del parámetro `future` de un `FutureBuilder` en clases sin estado (Stateless). Esto genera un bucle infinito cada vez que la app notifica un cambio global.
2.  **Uso de Wrappers (Envoltorios) con Estado**: Toda ruta que requiera cargar datos antes de mostrar la pantalla final debe envolverse en un `StatefulWidget` (ej. `AgentRouteWrapper`).
3.  **Memoria en `initState`**: Dentro del wrapper, el `Future` debe declararse como una variable protegida y ejecutarse exclusivamente dentro de `initState()`. Esto garantiza que la consulta a la base de datos se haga una sola vez por navegación, sin importar cuántas veces se refresque el árbol de widgets.

## Regla #23: Diseño de UI Responsivo y Enfoque Móvil (Mobile-First)
**Definición**: La plataforma Alveo será consumida mayoritariamente por visitantes y clientes a través de sus teléfonos móviles, por lo que toda característica debe ser 100% funcional y atractiva en pantallas pequeñas.
**Implicaciones**:
1.  **Cero Ocultamiento Injustificado**: Queda terminantemente prohibido ocultar botones o acciones críticas (ej. botones de "Contactar", llamadas a la acción, filtros) en dispositivos móviles por "falta de espacio" horizontal.
2.  **Adaptabilidad Estructural**: En lugar de ocultar, se debe readaptar el diseño. Si una fila de elementos (`Row`) no cabe en móvil, debe transformarse en una columna apilada (`Column`) o usar un flujo flexible (`Wrap`) para garantizar su correcta visualización.
3.  **Probar Siempre en Móvil**: Cualquier nueva pantalla, diálogo o componente añadido al proyecto debe conceptualizarse primero para su uso móvil (`isMobile`) y posteriormente expandirse o realinearse para aprovechar el espacio extra en pantallas de escritorio.

## Regla #24: Centralización de Formularios Administrativos
**Definición**: Para evitar la duplicación de código y mantener una única fuente de verdad (Single Source of Truth), la edición de perfiles y entidades debe centralizarse en los módulos administrativos correspondientes.
**Implicaciones**:
1.  **Eliminación de Pantallas Redundantes**: Se prohíbe tener pantallas separadas para la "Auto-Edición" de un perfil si el Administrador ya cuenta con un formulario robusto para ello. 
2.  **Jerarquía de Roles**: Los Súper Administradores y Administradores de Empresa (`company_admin`) son los encargados de configurar los perfiles públicos de sus agentes (Alias, Bio, WhatsApp, Correo de Contacto).

## Regla #25: Delegación de Correos Transaccionales (Serverless)
**Definición**: La aplicación móvil/web de Flutter nunca debe enviar correos directamente ni integrar SDKs de envío de correos (ej. SendGrid o Brevo) en el código del cliente.
**Implicaciones**:
1.  **Responsabilidad del Frontend (Flutter)**: La app solo se encarga de recopilar los datos del usuario, construir un objeto JSON (Payload) con toda la información necesaria (incluyendo los colores del branding `primaryColor` y receptores como `agentEmail`), e invocar a la base de datos o a una Edge Function (`client.functions.invoke`).
2.  **Responsabilidad del Backend (Supabase)**: Las Edge Functions (ej. `send-budget-email`) son las únicas autorizadas para poseer las API Keys de servicios de terceros y procesar el envío final del correo. Esto garantiza la seguridad de las credenciales y permite modificar la lógica de envío sin tener que actualizar la app en las tiendas.

## Regla #26: Gestión de Servidores Externos (Brevo) mediante Agentes e IAC (MCP)
**Definición**: Las interacciones de la IA (Agentes MCP) con código backend alojado en Supabase (como Edge Functions para envíos con **Brevo.com**) deben realizarse exclusivamente de forma "Local-to-Cloud" usando herramientas oficiales.
**Implicaciones**:
1.  **Estandarización de Correos**: **Brevo.com** se establece como el proveedor oficial y único para envío de correos. Toda nueva función de notificación (suscripciones, recuperación de contraseñas personalizadas) debe seguir utilizando la API HTTP de Brevo dentro de Supabase.
2.  **Flujo de Modificación vía MCP**: Dado que los Agentes MCP no tienen acceso directo a la consola web de Supabase, el administrador de la plataforma debe otorgar acceso instalando la consola local (`npx supabase`) y autenticándose (`supabase login`). El flujo de la IA siempre será: *Download* de la función -> *Edición* Local -> *Deploy* a la nube, garantizando que el historial del proyecto se mantenga intacto y seguro.

## Regla #27: Jerarquía Estricta de Seguridad en la UI (Role-Based Access)
**Definición**: La seguridad de las vistas administrativas no debe depender de "ocultar" los botones. Debe garantizarse explícitamente mediante validaciones de roles a nivel de renderizado y enrutamiento.
**Implicaciones**:
1.  **Validación de Renderizado**: Cualquier menú de navegación (ej. `AdminDrawer`) o botón que dirija a una pantalla de configuración global (Usuarios, Datos de la Empresa) DEBE estar estrictamente envuelto en un bloque `if (provider.isCompanyAdmin || provider.isSuperAdmin)`.
2.  **Prevención de Escalada de Privilegios**: Bajo ninguna circunstancia un usuario con rol de `agent` debe tener acceso a pantallas donde pueda visualizar, y mucho menos modificar, el estado o los perfiles de usuarios con permisos superiores (`admin` o `super_admin`).

## Regla #28: Aislamiento de Datos por Rol (Data Isolation - Option B)
**Definición**: Los agentes deben operar en un entorno de "Privacidad Selectiva" para proteger la integridad de los datos de la empresa y la privacidad de los prospectos.
**Implicaciones**:
1.  **Leads y Agenda**: El acceso a prospectos (Leads) y citas de calendario es estrictamente privado. Un agente solo puede visualizar y gestionar registros asociados a su ID de usuario.
2.  **Inventario (Lectura vs Escritura)**: Se aplica la "Opción B". Los agentes tienen permiso de **Lectura Global** (pueden ver todas las propiedades para vender el catálogo de la agencia), pero tienen permiso de **Escritura Restringido** (solo pueden editar o eliminar propiedades donde figuren como el Captador oficial).
3.  **Métricas de Dashboard**: Las estadísticas principales del panel deben transformarse en métricas personales cuando el usuario tiene el rol de `agent`.

## Regla #29: Autonomía de Marca Personal para Agentes
**Definición**: El sistema debe facilitar que los agentes gestionen su identidad profesional de forma autónoma para potenciar su marca personal.
**Implicaciones**:
1.  **Gestión de Perfil**: Todo agente debe tener acceso a una pantalla de "Mi Perfil" donde pueda editar su `slug` (alias de URL), `bio`, `whatsapp_number`, `contact_email` y foto sin intervención de un administrador.
2.  **Validación de Unicidad**: El sistema debe validar que el `slug` sea único a nivel global (o por empresa) antes de guardar cambios para evitar colisiones en los links de perfil.

## Regla #30: Protocolo de Asignación de Leads
**Definición**: El flujo de prospección debe permitir la transición de un Lead "Público/Agencia" a un Lead "Asignado/Privado".
**Implicaciones**:
1.  **Delegación de Administrador**: Solo los roles `admin` o `company_admin` tienen permiso para reasignar un lead a un agente específico.
2.  **Efecto de Aislamiento**: Al asignar un `assigned_agent_id` a un lead, este registro debe seguir inmediatamente la Regla #28, volviéndose invisible para otros agentes.

## Regla #31: Diseño de UI Adaptativo y Accesibilidad (Dark Mode)
**Definición**: El desarrollo de nuevas pantallas y componentes debe priorizar la compatibilidad nativa con temas claros y oscuros, evitando colores fijos que rompan la legibilidad.
**Implicaciones**:
1.  **Evitar Colores Hardcoded**: Está prohibido el uso de `Colors.black`, `Colors.white` o tonos de `grey` específicos en estilos de texto o fondos de contenedores sin una comprobación de `Theme.of(context).brightness`.
2.  **Uso de Temas Globales**: Se debe priorizar el uso de las constantes definidas en `AppThemes` y los colores semánticos del `ColorScheme` (ej. `onSurface`, `surface`) para garantizar que la UI se "vea premium" en cualquier modo.

## Regla #32: Protocolo de Notificaciones Multicanal (Lógica de Email)
**Definición**: Cada solicitud de presupuesto o contacto generada en la plataforma debe activar una notificación sincronizada a todos los actores involucrados para garantizar una respuesta rápida.
**Implicaciones**:
1.  **Destinatarios Obligatorios**: Toda notificación enviada vía **Brevo.com** (Supabase Edge Functions) debe incluir en el campo `to` a:
    *   **El Cliente**: Recibe una copia de su solicitud (Presupuesto/Contacto) como comprobante.
    *   **La Inmobiliaria (Main Email)**: El correo principal de la empresa configurado en `profiles` o `companies`.
    *   **El Agente (Captador/Asignado)**: Si el inmueble tiene un agente captador específico, este DEBE recibir una copia directa para iniciar la gestión comercial sin intermediarios.
2.  **Personalización Dinámica**: El contenido del correo debe adaptarse al `locale` (idioma) del cliente y reflejar la identidad visual (colores y logo) de la empresa emisora.
3.  **Remitente Estándar**: Mientras no se configure un dominio personalizado (DKIM), el remitente técnico se mantiene como `alveo.soporte@gmail.com`, pero el "Display Name" debe ser el nombre comercial de la inmobiliaria.

## Regla #33: RLS en `profiles` — Acceso Público por Slug (Modo Agente Anónimo)
**Contexto**: Cada agente tiene un link personal (`/agent/su-slug`) que puede compartir con clientes. Cuando un visitante anónimo entra por ese link, el sistema necesita leer el perfil del agente desde Supabase para activar el "Modo Agente".
**Solución — Política RLS aplicada en Supabase**:
```sql
CREATE POLICY "anon_read_profiles_by_slug" ON public.profiles FOR SELECT TO anon USING (slug IS NOT NULL);
```
**Seguridad**: Esta política solo expone perfiles que tienen un `slug` configurado explícitamente (agentes activos). Los perfiles de admins, super admins y clientes sin slug no son legibles por visitantes anónimos.

## Regla #34: Distinción entre Agentes y Ejecutivos de Cuenta (Freelance)
**Contexto**: Existen dos tipos de "vendedores" en el entorno, con propósitos totalmente distintos.
1. **Agentes Inmobiliarios**: Pertenecen a una Inmobiliaria específica. Su objetivo es vender/alquilar los inmuebles del inventario.
2. **Ejecutivos de Cuenta (Salespersons)**: Son contratistas de Alveo (SaaS). Su objetivo es captar nuevas inmobiliarias para la plataforma. Ganan una comisión sobre la facturación de las empresas que refieren.

## Regla #35: Funcionamiento de la Estrategia de Marketing #3 (Híbrida)
**Lógica de Negocio**: Al registrarse bajo el código de un Ejecutivo, la empresa recibe automáticamente descuentos acumulativos y bonos de capacidad. El Ejecutivo recibe un porcentaje (ej: 40%) de cada pago realizado por las empresas vinculadas a su alias.

## Regla #36: Estrategias de Crecimiento y Registro (Referidos y Afiliados)
**Contexto**: Existen 3 flujos de entrada para nuevas inmobiliarias:
1. **Estrategia 1 (Referidos B2B)**: Una agencia invita a otra (`ref_email`).
2. **Estrategia 2 (Afiliados / Ejecutivos)**: Un vendedor de Alveo comparte su link (`ref`).
3. **Estrategia 3 (Orgánico)**: El usuario llega por iniciativa propia.

## Regla #37: Gestión de Lógica en la Nube (Edge Functions)
Procesos críticos como envíos de correo (`send-budget-email`, `send-subscription-email`) y el orquestador de registros (`handle-auto-registration`) se delegan a Supabase Edge Functions usando la API de Brevo.

## Regla #38: Normalización y Reserva de Identificadores (Slugs/Alias)
Todos los alias y slugs deben guardarse y consultarse en **minúsculas**. No se permite el uso de palabras reservadas del sistema como `admin`, `login`, `register`, etc.

## Regla #39: Sincronización entre Edge Functions y Triggers de DB
Al invocar `auth.admin.createUser()` desde una función, es obligatorio pasar `company_id` en `user_metadata` para que el Trigger de DB funcione correctamente. Usar siempre `.upsert()` para evitar conflictos de duplicidad.

## Regla #40: Integridad Multi-tenant y Limpieza Atómica
Toda tabla con `company_id` debe tener Foreign Keys con `ON DELETE CASCADE`. Esto garantiza que al borrar una inmobiliaria no queden registros huérfanos.

## Regla #41: Protocolo "Apúntalo" (Meta-Regla de Documentación)
Cuando el USER escriba "**apúntalo**", la IA debe sintetizar aprendizajes técnicos o de negocio del turno y redactar nuevas reglas para prevenir errores futuros.

## Regla #42: Conflictos de Sesión por Reciclaje de Subdominios
Tras borrar y recrear una empresa con el mismo subdominio, es obligatorio limpiar Cookies y LocalStorage para evitar errores **403 Forbidden** por credenciales obsoletas.

## Regla #43: Parámetros de URL en Flutter Web (Hash Routing)
Para rutas con parámetros (ej: `/register?ref=alias`), no usar el mapa estático `routes`. Usar `onGenerateRoute` y pasar `settings` al `MaterialPageRoute` para preservar los parámetros.

## Regla #44: Despliegue en Producción con Path Routing (Vercel)
Para URLs limpias (sin `#`), configurar `vercel.json` con rewrites a `index.html` y activar `usePathUrlStrategy()` en el `main()` de Flutter.

## Regla #45: Vercel: Proyectos Múltiples y Despliegue SPA con `build/web`
El proyecto oficial en Vercel se llama **`web`**. Se debe vincular explícitamente y desplegar siempre el contenido de `build/web` (incluyendo el `vercel.json`) para evitar errores 404.

## Regla #46: Robustez en Carga de Multimedia (Image Network Safety)
Antes de usar `Image.network()`, validar que la URL comience con `http/https` y usar `errorBuilder` para mostrar placeholders descriptivos en caso de fallo.

## Regla #47: Sincronización de Flujos de Email (Frontend/Backend Payload)
Al añadir nuevos estados de correo en el frontend, verificar inmediatamente que la Edge Function tenga el caso implementado en su lógica.

## Regla #48: Automatización de Notificaciones de Facturación
El sistema gestiona eventos de Pago Reportado, Confirmado, Recordatorio y Suspensión de forma proactiva mediante la Edge Function `send-subscription-email`.

## Regla #49: Gestión de Tareas Programadas (Database Cron Jobs)
Los procesos periódicos (como recordatorios diarios) se implementan como funciones SQL y se programan con la extensión `pg_cron` de Supabase.

---

### Regla #50: Centralización de Diálogos Críticos (Utility Pattern)
**Contexto**: Acciones de alto impacto y lógica compleja (como reportar pagos bancarios) se invocan desde múltiples puntos.
**Regla**: Usar la clase `PaymentDialogUtils` para invocar el formulario de reporte, garantizando consistencia en toda la plataforma.

### Regla #51: [SUPER REGLA CRÍTICA] Despliegue en Vercel y Nombres de Proyecto
**ESTA REGLA ES ABSOLUTA Y NO PUEDE SER IGNORADA.**
1. **Proyecto Único**: El ÚNICO proyecto permitido en Vercel es **`web`**.
2. **Prohibición de Nombres**: Queda **ESTRICTAMENTE PROHIBIDO** crear o desplegar a un proyecto llamado `alveo-real-estate` o variantes.
3. **Acción ante Error**: Si existe un proyecto erróneo, ELIMINARLO inmediatamente (`vercel rm ...`).
4. **Comando Mandatorio**: `npx vercel deploy build/web --prod --yes --name web`

### Regla #52: Distinción de Terminología (Solicitudes vs Requests)
1. **Solicitudes (Leads)**: Interés de clientes en inmuebles (`budget_requests`).
2. **Registro de Empresas**: Se realiza de forma directa vía `/register` o mediante creación manual por el Super Admin. No se requiere aprobación previa para el registro público.

### Regla #53: Gestión vs Administración (Comisiones)
Se diferencia el pago único por alquiler (`default_management_pct`) de la comisión mensual por gestión de cobro (`default_admin_commission_pct`).

### Regla #54: Estados Finales de Inmuebles
Los estados válidos además de Disponible son: Vendido, Alquilado y Reservado.

### Regla #55: Permanencia de Bonos de Crecimiento
Los descuentos por referido son vitalicios mientras la agencia referida esté activa. Los bonos de capacidad afectan a toda la cuenta de forma global.

### Regla #56: Geolocalización de Precisión
La chincheta en el mapa muestra la ubicación EXACTA cargada, no un radio aproximado.

### Regla #57: Buscador por Referencia
El buscador principal debe priorizar la coincidencia exacta con el `ref_number` del inmueble.

### Regla #58: Interacción de WhatsApp
El botón de WhatsApp abre la app sin mensaje pre-cargado para permitir una interacción manual natural.

### Regla #59: Eslogan e Identidad de Marca (i18n)
El eslogan oficial es **"Alveo - Asistente Inmobiliario"**. Debe gestionarse vía i18n (`Alveo - Real Estate Assistant` en EN).

### Regla #60: Modelo de Negocio SaaS y PMS
Suscripción por cuota fija (sin porcentajes por uso). La agencia es dueña de sus datos, el software es un servicio centralizado.

### Regla #61: Diseño de Galería Inmersiva (Modo Cine)
La galería de fotos principal utiliza un diseño de pantalla completa:
- **Superposición**: Dirección y localización flotantes con sombras.
- **Responsividad**: Paddings dinámicos para móvil.
- **Foco Visual**: Sin botón CTA para priorizar la estética.
- **Botón Cerrar**: Círculo rojo sólido con "X" blanca, grande y prominente.
- **Zoom In**: Incluye efecto de lupa (magnifier) para escritorio.

---

### Regla #67: Protocolo de Despliegue en Vercel (Continuidad)
Para que las rutas limpias (Path Routing) funcionen en producción, el archivo `vercel.json` **DEBE** estar físicamente dentro de la carpeta `build/web` antes de ejecutar el comando de despliegue. Esto asegura que Vercel aplique los rewrites al SPA compilado.

### Regla #68: Brand Identity & Terminology (Entorno Alveo)
El término "Ecosistema" queda oficialmente sustituido por "**Entorno**" en todas las comunicaciones. Alveo es un "**Asistente Inmobiliario**" basado en un entorno SaaS/PMS bajo suscripción fija, enfocado en el tráfico de redes sociales y el soporte humano premium.

### Regla #69: Ubicación del ejecutable de Flutter
Para tareas de compilación y ejecución de scripts locales desde el agente, el ejecutable de Flutter está ubicado en la ruta estricta `C:\src\flutter`. Los comandos deben ejecutarse apuntando a `C:\src\flutter\bin\flutter.bat`.

### Regla #70: Integración de Redes Sociales (LinkedIn)
La plataforma soporta LinkedIn de forma unificada. La columna `linkedin_url` (nullable TEXT) mapeada en el modelo `Company` debe exponerse y persistirse en Supabase mediante el método `updateCompany`. Las interfaces de visualización pública (encabezado global, footer principal y drawer de navegación) deben renderizar dinámicamente el icono oficial de LinkedIn (`FontAwesomeIcons.linkedin`) condicionado a la existencia y validez de la URL configurada por el usuario.

