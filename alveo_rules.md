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

### Regla #71: Arquitectura del Asistente Virtual (IA)
El Asistente Virtual ("Ava") se basa en modelos de **Gemini Flash** (por soporte multimodal y velocidad). 
- **Frontend (Flutter)**: El parseo de Markdown para respuestas de la IA se debe realizar utilizando el paquete `flutter_markdown` para garantizar que los enlaces sean clickeables y el texto sea copiable (Selectable).
- **Backend (Supabase Edge Functions)**: Toda interacción con LLMs debe encapsularse en Edge Functions (ej. `alveo-ai-chat`). El rastreo de uso (tokens, modelo, tipo de input) se registra asíncronamente en la tabla `ai_usage` mediante una promesa "fire and forget" (sin `await`) usando la Service Role Key, para no bloquear la respuesta al usuario.

### Regla #72: Despliegues de Supabase sin Docker Local
Cuando el entorno local carece de Docker o existen problemas de permisos (como falta de symlinks en Windows sin modo desarrollador), no se debe frenar el flujo. Si el proyecto remoto está vinculado (`.supabase/project-ref`), se pueden desplegar migraciones y funciones directamente a la nube usando:
- `npx supabase db push` para migraciones SQL.
- `npx supabase functions deploy <nombre>` para Edge Functions.
- `npx supabase secrets set KEY=VALUE` para variables de entorno remotas.

### Regla #73: Costos y Cuotas de Modelos de Inteligencia Artificial (Gemini)
Para el Asistente Virtual ("Ava"), siempre apuntar de forma predeterminada al alias de modelo genérico **`gemini-flash-latest`** en producción y desarrollo, a menos que un modelo en específico sea requerido y costeado.
- **Evitar modelos restrictivos en capa gratuita**: Modelos específicos como `gemini-2.0-flash` o `gemini-2.5-flash` pueden tener asignadas cuotas gratuitas de "0" u ofrecer límites severamente bajos, provocando errores HTTP 500 por Rate Limit casi inmediatos.
- **Costo Operativo Mínimo**: La versión Flash ofrece márgenes gratuitos gigantescos (ej. 1,500 rpm) y costos ridículamente bajos tras superar la cuota libre (~$0.075 USD por cada 1 millón de tokens de entrada). Por lo que el costo no debe ser una preocupación para el escalamiento orgánico de las inmobiliarias. El registro asíncrono en `ai_usage` debe mantenerse activo para futura monetización si es necesaria.

### Regla #74: Consistencia de Enrutamiento de Propiedades (URLs Limpias)
Todos los enlaces públicos o vistas previas de inmuebles generados por el backend (Edge Functions) y el frontend deben coincidir estrictamente con el formato `/refXXX` (donde XXX es el número de referencia con ceros a la izquierda para completar 3 dígitos, ej: `/ref044`). Esto asegura que el router de Flutter capture la ruta directamente y evita errores de redirección 404 en plataformas SPA como Vercel.

### Regla #75: Sanitización de Errores del Asistente Virtual (Ava UI)
Toda excepción, error HTTP o fallo del backend del Asistente Virtual ("Ava") debe ser interceptado en el frontend. Queda estrictamente prohibido mostrar stack traces técnicos o mensajes crudos de error (tales como `FunctionException`, `Quota exceeded` o `429`) en las burbujas del chat. En su lugar, se deben mapear los errores a claves de traducción i18n amigables (`ava_limit_reached` en caso de límites de cuota/rate-limits y `ava_error` en cualquier otro tipo de fallo).

### Regla #76: Interceptación y Navegación SPA de Enlaces de IA
En interfaces de chat de IA (como Ava), los enlaces recomendados de propiedades (que apuntan a URIs absolutas como `https://[subdominio].alveo.fyi/refXXX`) deben interceptarse en la capa de UI de Flutter (`ChatMessageBubble` en `onTapLink`).
- **Navegación Interna**: Si el enlace corresponde a una propiedad `/refXXX` (verificado mediante `segments.last.startsWith('ref')`), el sistema debe cerrar primero el modal o bottom sheet del chat (`Navigator.pop(context)`) y luego navegar internamente utilizando `Navigator.pushNamed('/refXXX')`.
- **Independencia del Host**: Esto garantiza una navegación inmediata tipo Single Page Application (SPA), evita abrir pestañas secundarias innecesarias en producción y permite que en desarrollo local (`http://localhost:...`) el enlace cargue directamente en el servidor local de pruebas en lugar de saltar al servidor de producción.

### Regla #77: Sugerencias Rápidas Dinámicas en Chat de IA según Configuración Regional
**Contexto**: El Asistente Virtual ("Ava") requiere presentar opciones o sugerencias rápidas (chips) que sean altamente relevantes al contexto de la agencia inmobiliaria en lugar de textos estáticos o genéricos.
**Regla**: 
1. **Construcción Dinámica**: Las sugerencias rápidas de búsqueda de inmuebles deben construirse dinámicamente utilizando los datos regionales configurados por el tenant (tales como `company.city` de `CompanyProvider`).
2. **Soporte i18n y Marcadores de Posición**: Los textos de las sugerencias deben obtenerse de las traducciones oficiales (`ava_chip_houses_sale`, `ava_chip_houses_rent`, etc.) con soporte para parámetros dinámicos de reemplazo (`{0}`).
3. **Fallbacks Localizados**: Si la ciudad del tenant no está configurada, proveer fallbacks amigables y localizados en el frontend (ej: *"nuestra ciudad"* en español y *"our city"* en inglés).
4. **Optimización Táctil Móvil**: Utilizar `scrollDirection: Axis.horizontal` y la física `BouncingScrollPhysics()` en el `ListView` contenedor para ofrecer una experiencia de deslizamiento horizontal suave y nativa en dispositivos móviles.

### Regla #78: Despliegue SPA en Vercel y Redirección Edge sin Bucle 308 (Rutas a `/`)
**Contexto**: Al utilizar `"cleanUrls": true` en Vercel, cualquier redirección comodín que apunte físicamente a `/index.html` entra en bucle infinito o conflictos con la redirección permanente `308` automática de Vercel, resultando en un error **404 estático**.
**Regla**:
1. **Destino Limpio a `/`**: Las reglas de enrutamiento SPA para Vercel deben apuntar el destino (`dest`) directamente a la raíz limpia de la SPA `/` en lugar de `/index.html`.
2. **Uso de Routes con Expresiones Regulares**: Evitar la directiva `rewrites` (que inyecta verificaciones físicas `check: true` en el disco). Utilizar la directiva de bajo nivel `routes` en `vercel.json` con expresiones regulares nativas de JavaScript puras (no globs de Express).
3. **Servir Archivos Estáticos**: Incluir siempre `{ "handle": "filesystem" }` al principio de la lista de rutas para garantizar que Vercel sirva de inmediato todos los activos compilados reales (como `main.dart.js`, `assets/`, `favicon.ico`, etc.).
4. **Esquema de Configuración Infalible**:
   ```json
   {
     "cleanUrls": true,
     "trailingSlash": false,
     "routes": [
       { "handle": "filesystem" },
       { "src": "^/(ref.*)$", "dest": "/" },
       { "src": "^/agent/(.*)$", "dest": "/" },
       { "src": "^/register$", "dest": "/" },
       { "src": "^/login$", "dest": "/" }
     ]
   }
   ```
5. **Despliegue Pre-built**: Compilar localmente con `flutter build web --release`, compilar el paquete de Vercel localmente con `npx vercel build --prod` desde el directorio de compilación, y finalmente desplegar con `npx vercel deploy --prebuilt --prod`. Esto fuerza la sincronización exacta de la configuración sin procesamiento en los servidores remotos.

---

### Regla #79: Extracción de Parámetros en Simuladores de IA Sin Costo (Mock AI Simulator Rules)
**Contexto**: Los entornos SaaS de pruebas suelen requerir un simulador de Inteligencia Artificial gratis (`mock-test`) para que los usuarios prueben la plataforma sin incurrir en costos de APIs comerciales. Si el simulador carece de un analizador (parser) robusto, ignorará filtros esenciales (como la ciudad) y retornará registros fuera de contexto (ej. propiedades en Valencia al buscar en Anaco), frustrando la experiencia del usuario.
**Regla**:
1. **Consistencia de Filtros**: Todo simulador "Mock" que reemplace llamadas a LLM reales debe implementar análisis de palabras clave y segmentación de texto para emular fielmente el comportamiento de "Function Calling" del LLM real.
2. **Extracción Dinámica de Ciudad**: Utilizar un parser que segmente el texto buscando palabras precedidas por preposiciones geográficas como `"en"` (ES) o `"in"` (EN).
3. **Filtro de Exclusión de Stop Words**: Excluir estrictamente las palabras clave comunes de la consulta de base de datos (`venta`, `alquiler`, `casa`, `apto`, `inmueble`, `la`, `el`, etc.) para evitar falsos positivos al extraer la ciudad.
4. **Validación y Corte**: Asignar como filtro de ciudad el primer término válido mayor a 2 caracteres y detener el ciclo (`break`) una vez detectada la ciudad geográfica.
5. **Filtrado Secundario por Palabra Clave**: Si el usuario utiliza subcategorías o palabras específicas en su texto (como "villa" o "piscina/pool"), el simulador debe aplicar un filtro secundario en memoria sobre la lista de resultados de la base de datos. Si hay coincidencias en el título o descripción de las propiedades, se limita el resultado únicamente a ellas (ej. filtrar la "Casa de Campo" al buscar "villas", entregando solo aquellas propiedades que tengan "Villa" en su título). De igual forma, si busca genéricamente `"casa"`, se deben **excluir** las villas de los resultados para mantener las intenciones de búsqueda perfectamente separadas, emulando la precisión de un LLM real.

---

### Regla #80: Tolerancia a Errores Ortográficos en Búsquedas Geográficas (Fuzzy City Matching)
**Contexto**: Los usuarios a menudo cometen errores tipográficos comunes en el teclado móvil (ej. "lecharia" en lugar de "Lechería") o ignoran los acentos correctos al interactuar con el Asistente Virtual. Si el sistema hace una consulta exacta con `ilike`, fallará en entregar resultados válidos y reportará que no existen propiedades, afectando severamente la conversión.
**Regla**:
1. **Fuzzy Matching Geográfico**: Toda consulta de búsqueda de inmuebles por ciudad debe pasar por un interceptor de coincidencia aproximada (`findBestCityMatch`) antes de compilar la consulta final a la base de datos.
2. **Normalización y Máscara de Vocales**:
   * Primero, normalizar los caracteres quitando acentos y convirtiendo a minúsculas (`normalize("NFD").replace(/[\u0300-\u036f]/g, "")`).
   * Si no hay coincidencia directa, aplicar una **máscara de vocales** (reemplazando `a, e, i, o, u` por `*`) para comparar las estructuras consonánticas.
   * Esto permite asociar de forma instantánea e infalible términos aproximados como `"l*ch*r**"` de *"lecharia"* con el registro real de *"Lechería"* en la base de datos de la inmobiliaria.
3. **Mapeo al Nombre Real**: Al encontrar la coincidencia aproximada con alguna de las ciudades con propiedades activas registradas en la empresa, reescribir dinámicamente el parámetro `args.city` con el nombre correcto y acentuado de la base de datos, garantizando que el filtro SQL funcione de manera perfecta.

---

### Regla #81: Gestión e Integración de Claves Secretas y Entrada Multimodal de Voz (API Key Secrets)
**Contexto**: El Asistente Virtual ("Ava") requiere transicionar fluidamente entre el Simulador de Pruebas (`mock-test`) y la Inteligencia Artificial Real Multimodal (Gemini Flash) para soportar notas de voz y análisis cognitivo complejo de manera segura.
**Regla**:
1. **Configuración Centralizada de Secretos**: La clave `GEMINI_API_KEY` debe ser gestionada como un secreto de entorno en la nube de Supabase. Se configura globalmente mediante el CLI de Supabase para evitar exponer credenciales en el cliente:
   `npx supabase secrets set GEMINI_API_KEY=tu_api_key`
2. **Capa Multimodal Gratuita (Google AI Studio)**: Activar el modelo real no requiere cargos comerciales obligatorios. Se deben priorizar claves de Google AI Studio en su capa gratuita (15 RPM / 1,500 RPD), la cual soporta nativamente la recepción y procesamiento de archivos de audio (notas de voz) en formato base64 de manera 100% gratuita para pruebas de negocio.
3. **Transición Transparente**: Al cambiar el modelo en la interfaz de la inmobiliaria, la Edge Function redirige en caliente la petición del interceptor mock a la API de Gemini, permitiendo probar la voz y flujos de IA reales de inmediato y sin necesidad de realizar nuevas compilaciones en el frontend.

### Regla #82: Modelo de IA por Defecto en Auto-Registros (`mock-test` Default Model)
**Contexto**: Al auto-registrarse una nueva empresa en el portal, es fundamental que la experiencia inicial sea completamente funcional, fluida y libre de barreras de configuración o limitaciones de cuotas de API externas. Si se asigna un modelo de IA comercial como `gemini-flash-latest` por defecto antes de que el administrador configure su propia clave o active su cuenta, las primeras interacciones del usuario con el asistente virtual Ava fallarán con errores de cuota (429) o fallos de autenticación.
**Regla**:
1. **Configuración Inicial Segura y Activa**: En el flujo de auto-registro de empresas (controlado por la Edge Function `handle-auto-registration`), se debe forzar por defecto el campo `ai_model` al valor de `'mock-test'` (Simulador de Pruebas Ilimitado / Gratis) y marcar explícitamente el campo `has_ai_agent` como `true`.
2. **Experiencia de Usuario Ininterrumpida**: Esto garantiza que toda nueva inmobiliaria cuente con el asistente virtual Ava activo y 100% operativo desde el primer segundo de su creación sin requerir claves API iniciales.
3. **Migración Voluntaria**: El administrador podrá posteriormente cambiar el modelo a Gemini Flash real desde su panel de ajustes corporativos cuando esté listo para producción.

---

### Regla #83: Operación en Capa de Pago por Uso de Gemini (Pay-As-You-Go Enterprise Execution)
**Contexto**: Cuando una inmobiliaria en producción transiciona de la Capa Gratuita a la Capa de Pago por Uso (Pay-As-You-Go) en Google AI Studio, se eliminan las limitaciones severas de cuota (15 RPM) y se activan las garantías comerciales de privacidad de Google, asegurando un desempeño óptimo para escala empresarial sin necesidad de cambiar de API key.
**Regla**:
1. **Transición 100% Transparente**: Al estar la clave secreta `GEMINI_API_KEY` gestionada en la nube de Supabase a nivel de Edge Function, la activación de la capa de pago en el dashboard de Google se propaga de forma transparente. La aplicación cliente y el backend continúan operando de inmediato y sin necesidad de realizar nuevas compilaciones ni configuraciones.
2. **Garantía de Privacidad de Datos**: Bajo este esquema comercial, Google garantiza por contrato la confidencialidad total: ni los datos de la inmobiliaria, ni los chats de los usuarios, ni los prompts del sistema serán utilizados para entrenar modelos públicos.
3. **Escalabilidad de Cuota**: Los límites aumentan de inmediato, permitiendo cientos de solicitudes simultáneas por minuto para responder a campañas publicitarias masivas de captación inmobiliaria sin riesgo de bloqueos por tasa de uso.

---

### Regla #84: Grabación de Audio en Flutter Web (Transient User Activation)
**Contexto**: El botón de micrófono del Asistente Virtual (Ava) fallaba silenciosamente en producción: el navegador no mostraba el diálogo de permiso de micrófono y la grabación nunca iniciaba. El diagnóstico reveló una violación de la política de seguridad del navegador llamada **Transient User Activation**.

**Causa Raíz**: Los navegadores modernos (Chrome, Firefox, Safari) exigen que `getUserMedia()` — la API que solicita acceso al micrófono — sea invocada **directamente** dentro del stack de llamadas de un gesto del usuario (ej. un `onPressed`). Si la llamada se delega a un widget hijo que la ejecuta en su `initState()`, la cadena de activación ya expiró en el ciclo de `setState → rebuild → initState`, y el navegador **bloquea la solicitud sin mostrar ningún diálogo ni error**.

**Regla**:
1. **Prohibición de Delegación**: Queda estrictamente prohibido iniciar la grabación de audio (`_audioRecorder.start()`) dentro del `initState()` de un widget hijo creado por un `setState`. Esto rompe el contexto de activación transitoria del navegador.
2. **Invocación Directa Obligatoria**: La llamada a `_audioRecorder.start()` (que internamente llama a `getUserMedia()`) DEBE ejecutarse en la función `onPressed` del botón directamente, **antes** de cualquier `setState` o delegación que pueda interrumpir el contexto de activación.
3. **Patrón Correcto (Inline Recording)**: Toda la lógica de grabación (`AudioRecorder`, `Timer`, estado `_isRecordingVoice`, `_recordSeconds`) debe vivir en el `StatefulWidget` que contiene el botón de micrófono. La UI de grabación se renderiza condicionalmente en el mismo `build()`, sin crear nuevos widgets hijos que inicien la grabación.
4. **Anti-patrón a Evitar**:
   ```
   // ❌ INCORRECTO: getUserMedia() se llama en initState(), fuera del gesto
   onPressed: () => setState(() => _isRecordingVoice = true);
   // VoiceRecorderWidget.initState() -> _audioRecorder.start() -> BLOQUEADO
   ```
5. **Patrón Correcto**:
   ```
   // ✅ CORRECTO: getUserMedia() se llama DIRECTAMENTE en el gesto
   onPressed: () async {
     await _audioRecorder.start(...); // dentro del gesto del usuario
     if (mounted) setState(() => _isRecordingVoice = true); // DESPUÉS
   }
   ```
6. **Pre-chequeo de Permisos en Web**: Para que el navegador muestre la ventana flotante de permiso de micrófono, se debe llamar a `await _audioRecorder.hasPermission()` DIRECTAMENTE dentro del gesto del usuario (antes de cualquier delay o `setState`). Si se llama fuera de la activación transitoria del usuario (ej. después de un `await` o en un `initState`), el navegador lo bloqueará silenciosamente y retornará `false`. Al llamarlo directamente en el gesto, se abre el diálogo nativo del navegador de forma segura.
7. **MissingPluginException en Web (Caché Corrupto)**: Si al intentar interactuar con un plugin web (como `record`) se obtiene un error `MissingPluginException` para el canal de comunicación, se debe a que la compilación incremental de Flutter omitió la inyección JavaScript del plugin web. Para solucionarlo de raíz, se debe purgar el caché ejecutando `flutter clean`, re-vincular dependencias con `flutter pub get` y compilar una versión fresca con `flutter build web`.

---

### Regla #85: Sincronización Unificada de Leads y Citas en Agenda (CRM & Calendar Sync)
**Contexto**: En Alveo, el módulo de **Leads** (Solicitudes) y **Agenda** (Calendario) comparten la misma tabla subyacente (`budget_requests`). Si al agendar una cita o al vincular una solicitud preexistente no se sincronizan correctamente los campos, se pueden duplicar los registros o generar discrepancias operativas críticas.
**Regla**:
1. **Identificador de Agenda Local**: La tabla `budget_requests` tiene un constraint `NOT NULL` en `client_email`. Para citas directas creadas desde el calendario que no pertenecen originalmente a un lead preexistente, se debe usar la dirección `'agenda@local'` como correo por defecto para satisfacer el constraint.
2. **Filtrado Discriminador**: Al consultar las solicitudes generales en el CRM, para evitar que se mezclen citas directas con leads reales, se debe excluir el correo local mediante `.neq('client_email', 'agenda@local')`. Queda prohibido filtrar usando `is_appointment = false`, ya que aquellos leads reales que son convertidos a citas (híbridos) deben seguir siendo visibles en el listado de leads del CRM.
3. **Conversión Atómica a Cita**: Cuando un lead pendiente es convertido a cita (vinculación de lead preexistente), el sistema no debe crear un registro nuevo. Se debe actualizar el registro del lead existente usando su UUID, activando `is_appointment = true` y forzando su estado general (`status`) a `'responded'` (Respondido), de modo que se cumpla de forma atómica el flujo de cierre del lead y su reflejo en la agenda.

---

### Regla #86: Prevención de Crashes en Dropdowns de Flutter (Dropdown Constraint Safety)
**Contexto**: Los componentes `DropdownButton` y `DropdownButtonFormField` en Flutter exigen por aserción estricta de la biblioteca que su valor actual (`value`) esté presente exactamente dentro de la lista de opciones (`items`). Si el backend o la base de datos escribe un valor con diferencia de mayúsculas/minúsculas o una palabra no contemplada en el dropdown (ej: `'Pending'` con P mayúscula, o `'Confirmada'` en español cuando el backend usa `'confirmed'`), la aplicación de Flutter lanzará una excepción fatal inmediatamente al abrir la pantalla de edición, inutilizando el calendario administrativo.
**Regla**:
1. **Definición Estricta en Minúsculas**: Las citas en base de datos deben registrarse estrictamente con estados en minúsculas: `'pending'`, `'confirmed'`, `'cancelled'`, `'done'`.
2. **Compatibilidad en Backend**: Toda Edge Function o Agente de IA (como Ava) que registre o actualice citas en la base de datos de Supabase debe escribir de manera forzada el estado de la cita en minúsculas (ej: `'pending'`).
3. **Validación de Rango en UI**: Al renderizar el dropdown en Flutter, asegurar que el valor asignado al widget coincida con alguno de los elementos de la lista en minúsculas, evitando variaciones de idioma u ortográficas en el valor de base de datos.

---

### Regla #87: Alternancia de Roles en Gemini API & Prevención de Historial Duplicado
**Contexto**: La API de Gemini es sumamente estricta con la estructura del historial de chat, exigiendo que los roles de los mensajes alternen de forma exacta entre `user` (usuario) y `model` (asistente). Si se envían dos mensajes seguidos con el mismo rol (ej. `[..., user, user]`), la API falla inmediatamente con un error 400 Bad Request o devuelve una respuesta vacía interpretada por la interfaz de usuario como `"No response"`.
**Regla**:
1. **Exclusión del Mensaje Actual en el Historial del Frontend**: Al construir el historial de chat (`_buildHistory()`) en Flutter para enviarlo al Edge Function, se debe excluir siempre el último mensaje del listado local de la interfaz de usuario, puesto que ese mensaje ya se envía de forma independiente como el parámetro principal (`message` o `audio_base64`). Al excluirlo, evitamos que el mensaje actual se duplique al final del historial de la Edge Function.
2. **Alternancia Asegurada**: El historial de chat que recibe la Edge Function debe estar compuesto únicamente por mensajes alternantes pasados finalizados en rol `model`, garantizando que al inyectar el mensaje actual (rol `user`) al final del arreglo, el cuerpo enviado a Gemini termine de forma segura y válida en rol `user` (`[..., model, user]`).

---

### Regla #88: Uso de Cliente de Rol de Servicio (Service Role) en Operaciones Públicas de CRM (RLS SELECT Bypass)
**Contexto**: Al interactuar con el Asistente de IA (Ava) de forma pública/anónima desde la App Web, el token de autorización de Supabase representa al rol `public`. La base de datos tiene una política RLS de `INSERT` público en `budget_requests`, pero no permite la lectura (`SELECT`) de registros a usuarios no autenticados. Si la Edge Function realiza consultas de colisión horaria (SELECT) o utiliza una cláusula `RETURNING` en el insert (vía `.select().single()`) usando el `supabaseClient` del usuario anónimo, Postgres bloquea la operación y la llamada a la herramienta `registrar_solicitud_visita` falla silenciosamente por falta de privilegios SELECT.
**Regla**:
1. **Cliente de Servicio Administrativo**: Toda herramienta de IA ejecutada en el backend (Supabase Edge Functions) que requiera realizar consultas de disponibilidad (SELECT) en tablas protegidas (como `budget_requests` para citas y CRM) o necesite leer la fila recién creada (INSERT con retorno), DEBE inicializar y utilizar un cliente de Supabase administrativo (`supabaseAdmin`) con la `SUPABASE_SERVICE_ROLE_KEY`.
2. **Seguridad Controlada por Backend**: El uso de `supabaseAdmin` es seguro y necesario en este contexto ya que la ejecución está encapsulada y controlada dentro del flujo lógico validado del LLM y de la Edge Function, previniendo abusos en los accesos de lectura directos por parte de los clientes web.

---

### Regla #89: Guía de Formato Conversacional para Fechas y Horas (Alineación Conversacional)
**Contexto**: A fin de asegurar que el usuario conozca de qué manera ingresar la fecha y hora preferida para sus citas con el Agente de IA, resulta idóneo que la asistente guíe al usuario de manera clara e intuitiva.
**Regla**:
1. **Ejemplos Explícitos en el Prompt de Ava**: El prompt del sistema (`systemPrompt`) debe instruir a Ava a incorporar siempre de forma proactiva ejemplos concisos de formatos de fecha y hora cuando solicite estos datos al usuario.
2. **Formatos Soportados en los Ejemplos**: Ava debe sugerir formatos tradicionales y en lenguaje natural en su mensaje, tales como `(dd/MM/yy)` (ej. `28/05/26`) o formatos en lenguaje natural y AM/PM (ej. `el jueves a las 4pm` / `11pm (23:00)`), indicando que el sistema comprende ambos esquemas de manera fluida y flexible.

---

### Regla #90: Formato de functionResponse en Gemini API (Unwrapping and JSON Object Safety)
**Contexto**: La API de Gemini requiere estrictamente que la propiedad `response` dentro de una parte `functionResponse` sea un objeto JSON plano que coincida directamente con los campos de salida definidos en la declaración de la herramienta. Si el backend duplica o envuelve el resultado en una estructura no estándar (ej. `{ name: ..., content: ... }`) o envía un arreglo plano (como el resultado de `buscar_propiedades`), la API de Gemini no logrará interpretar la respuesta de la función y continuará llamando recursivamente a la herramienta en un bucle infinito hasta alcanzar el límite de iteraciones, lo que resulta en un fallo silencioso visible como `"No response"`.
**Regla**:
1. **Desenvolvimiento Directo**: La propiedad `response` de `functionResponse` debe recibir el resultado de la función (`functionResult`) de forma directa y plana, sin envolverlo en campos auxiliares como `name` o `content`.
2. **Cumplimiento de Objeto JSON**: Dado que Gemini exige que `response` sea un objeto y no un arreglo, si una herramienta retorna un arreglo plano (como la lista de propiedades filtradas en `buscar_propiedades`), el backend debe encapsularlo dentro de un objeto JSON con una propiedad descriptiva (ej. `{ properties: functionResult }`) antes de enviarlo a la API de Gemini, previniendo errores de validación de esquema en la API.

---

### Regla #91: Mapeo de Agentes en Tabla de Propiedades (listing_agent_id)
**Contexto**: En la base de datos de Alveo, la columna que identifica al agente asignado en la tabla de propiedades se llama `listing_agent_id`. Intentar consultar `assigned_agent_id` directamente de la tabla `properties` arrojará un error silencioso de Postgres ("column properties.assigned_agent_id does not exist") en las Edge Functions, lo cual bloqueará la herramienta `registrar_solicitud_visita` y causará respuestas vacías de `"No response"`.
**Regla**:
1. **Consulta Correcta de Columna**: Al consultar el agente de un inmueble en Supabase Edge Functions, se debe seleccionar estrictamente la columna `listing_agent_id` de la tabla `properties`.
2. **Mapeo a la Agenda**: Al insertar o asociar esta información a la tabla `budget_requests` (donde la columna sí se llama `assigned_agent_id`), se debe realizar el mapeo de forma explícita: `assigned_agent_id: property.listing_agent_id || null`.
3. **Conversión Defensiva de Tipos**: Las referencias a propiedades enviadas por la API de Gemini (como `propertyRef`) pueden ser transmitidas como strings. El backend debe parsear defensivamente este argumento como entero (`parseInt`) antes de realizar la consulta en base de datos para evitar discrepancias de tipo en Postgres.

---

### Regla #92: Discriminación de Citas Locales vs Leads de IA sin Correo (Leads vs Local Appointments)
**Contexto**: Para satisfacer el constraint `NOT NULL` de `client_email` en la tabla `budget_requests`, el sistema utiliza correos electrónicos ficticios terminados en `@local`. Si el asistente de IA o el backend utiliza la misma dirección de correo genérica que las citas locales de agenda (`'agenda@local'`), la lógica de consulta del CRM excluirá erróneamente estos leads reales (como los registrados por Ava), haciéndolos invisibles en la lista de Leads.
**Regla**:
1. **Diferenciación de Placeholders**:
   * Las citas manuales creadas en el calendario que no corresponden a un prospecto previo deben utilizar `'agenda@local'`.
   * Los leads reales registrados por el asistente de IA (Ava) u otras integraciones donde el cliente no proporcione un correo deben utilizar estrictamente `'no-email@local'` (o cualquier placeholder distinto a `'agenda@local'`).
2. **Presentación de UI Premium**: En las interfaces administrativas (como `AdminLeadsScreen` u otras vistas del CRM), los correos que terminen en `@local` deben ocultarse o formatearse de manera elegante mostrando un guión (`—`) o una cadena vacía en lugar del placeholder técnico, garantizando una estética limpia y profesional.
3. **Mantenimiento del Filtro**: Las consultas del CRM que busquen prospectos reales deben seguir filtrando únicamente mediante `.neq('client_email', 'agenda@local')`, asegurando que los leads híbridos (reales pero sin correo) sigan apareciendo.

---

### Regla #93: Protocolo de Colisiones de Agenda en el Asistente Virtual (Calendar Scheduling Conflict Resolution)
**Contexto**: El flujo de agendamiento conversacional del Asistente Virtual (Ava) debe prevenir solapamientos horarias antes de registrar una nueva cita en Supabase, garantizando que un mismo inmueble o un mismo agente no tengan múltiples citas confirmadas simultáneamente.
**Regla**:
1. **Validación de Conflicto en Nivel de Tool**: La herramienta `registrar_solicitud_visita` debe verificar de forma atómica si ya existe una cita en estado `'confirmed'` en el mismo `appointment_date` y `appointment_time` que coincida con el ID del inmueble seleccionado o con el `assigned_agent_id` del captador de la propiedad.
2. **Respuesta en Caliente ante Colisiones**: En caso de conflicto de disponibilidad, el backend debe cancelar la operación de inserción y retornar un objeto de fallo estructurado `{ success: false, conflict: true, message: "..." }`.
3. **Flujo Conversacional de Mitigación**: El LLM (Ava) debe interpretar la señal de conflicto del tool de forma amigable e informar con cortesía al cliente que la hora seleccionada ya está reservada para ese inmueble/agente, guiándolo de forma interactiva a elegir un horario alternativo.

---

### Regla #94: Navegación Dinámica por Pestañas para Selectores Jerárquicos en Móvil (Dynamic Hierarchical Tabs)
**Contexto**: Las pantallas con flujos jerárquicos multicolumna (como el Gestor de Ubicaciones: País -> Estado -> Ciudad) resultan inmanejables en pantallas móviles si se colocan lado a lado (squeezed) o en scroll horizontal infinito, ya que el usuario pierde visibilidad de la relación de dependencias y de las opciones cargadas.
**Regla**:
1. **Pestañas Adaptativas (TabBar/TabBarView)**: En dispositivos móviles (`isMobile`), se debe convertir la vista multicolumna en un contenedor controlado por un `TabController` con tres pestañas correspondientes al flujo jerárquico.
2. **Transición Táctil Asistida**: Al seleccionar un elemento padre (ej: un País), la aplicación debe actualizar el estado y disparar inmediatamente una animación suave del TabController (`_tabController.animateTo(nextIndex)`) para guiar al usuario directamente a la siguiente columna jerárquica (Estados), reduciendo la fricción.
3. **Placeholders de Estado**: Las pestañas de categorías dependientes deben renderizar un placeholder visual elegante con iconos descriptivos y leyendas instructivas claras (ej: "Selecciona un país primero") si el elemento padre requerido aún no ha sido seleccionado.
4. **Preservación Desktop**: Mantener siempre intacto el diseño clásico de tres columnas lado a lado en pantallas grandes para máxima productividad de oficina.

---

### Regla #95: Desestructuración de ListTile Semicolumnar para Listas en Móvil (ListTile Mobile Column Deconstruction)
**Contexto**: El widget `ListTile` es rígido. Cuando un listado administrativo requiere incluir múltiples metadatos, insignias de origen y acciones de edición en el `trailing` (como la bandeja de Leads/Solicitudes), el espacio horizontal disponible en móvil se agota. Esto provoca que los nombres de clientes y descripciones de inmuebles se trunquen agresivamente tras pocos caracteres, arruinando la legibilidad operativa.
**Regla**:
1. **Deconstrucción Móvil**: En pantallas móviles, evitar el uso de `ListTile` con widgets `trailing` anchos de tipo `Row` (como insignia de estado + botón eliminar).
2. **Estructura en Columna Apilada**: En su lugar, el `Card` debe reestructurarse usando una columna (`Column`) que distribuya la información en filas dedicadas de ancho completo:
   * **Fila Superior**: Avatar, nombre del cliente (con amplio espacio horizontal) y botón eliminar en la esquina derecha.
   * **Fila Media**: Descripción de la propiedad con soporte multilinea completo (máximo 2 líneas, sin truncado prematuro).
   * **Fila Inferior**: Insignias (badges) de origen y agente alineados a la izquierda, y estado administrativo a la derecha.
3. **Preservación Desktop**: En pantallas grandes, continuar renderizando la fila horizontal compacta tradicional (`ListTile`) para conservar alta densidad visual.

---

### Regla #96: Interceptación Local y Visualización Modal de Enlaces de Inmuebles en Chats (AI Link Modal Interception)
**Contexto**: Cuando el Asistente de IA (Ava) recomienda una propiedad en el chat, presenta un enlace del tipo `/refXXX`. Si el visitante hace clic en él y el sistema navega fuera del chat o recarga la página, se pierde el historial de la conversación actual y se interrumpe drásticamente el embudo de conversión del cliente.
**Regla**:
1. **Interceptación de Enlaces de Propiedades**: En la capa del chat de IA (`ChatMessageBubble` en `onTapLink`), toda URL o referencia que contenga la cadena `/refXXX` (verificado analizando la ruta y el fragmento hash para entornos locales) debe ser interceptada.
2. **Carga y Modal Nativo Directo**:
   * En vez de redirigir la ruta o abrir pestañas externas, se debe mostrar una pantalla o spinner de carga fullscreen inmediato para evitar clics dobles.
   * Consultar la propiedad a Supabase a través del servicio local de forma asíncrona.
   * Cerrar el indicador de carga y abrir de inmediato la ventana modal del visualizador multimedia existente del proyecto (**`PhotoGalleryDialog`**).
3. **Retorno Seguro**: Al cerrar el modal multimedia, el usuario debe quedar exactamente en la misma pantalla del chat interactivo con Ava, asegurando continuidad en la experiencia y reteniendo al prospecto.

---

### Regla #97: Sincronización Obligatoria con GitHub en Despliegues
**Contexto**: El control de versiones permite auditar qué código está distribuido en producción en cada momento. Realizar despliegues de frontend (en Vercel) o backend (Supabase Edge Functions) sin consolidar el código correspondiente en el repositorio remoto de GitHub puede generar discrepancias insalvables y desalineaciones de código.
**Regla**:
1. **Sincronización Atómica**: Cada vez que el agente o programador ejecute un comando de despliegue (`deploy`) a producción, hosting o CDN (como Vercel o Supabase Edge Functions), se DEBE realizar inmediatamente y de forma atómica un commit y push (summit) con los cambios de código fuente correspondientes a GitHub.
2. **Registro de Consistencia**: Ningún despliegue se considera completado hasta que la versión del repositorio remoto esté perfectamente sincronizada.

---

### Regla #98: Flujo Operativo y UI para Gestión de Leads y Citas (Manual vs. IA)
**Contexto**: El flujo de conversión de un Lead (solicitud) a una cita confirmada en la agenda varía significativamente si el proceso se inicia a través del botón tradicional en la web o si es gestionado íntegramente por el Asistente de IA (Ava). La interfaz administrativa debe proveer herramientas para que la vinculación manual sea atómica y no duplique registros, al mismo tiempo que permite registros orgánicos espontáneos.
**Regla**:
1. **Flujo Manual (Sin IA)**:
   * **Creación vía App**: Al presionar "Me interesa", se crea un Lead con fecha de creación y se notifica por correo al agente.
   * **Seguimiento**: El agente contacta al prospecto. Independientemente de si se concreta una cita o no, el agente debe entrar al módulo "Leads" y cambiar el estado del Lead (ej. respondido o rechazado).
   * **Agendamiento desde Lead (UI Requerida)**: Si acuerdan una visita proveniente de un Lead web, el agente ingresa al módulo "Agenda". Debe existir un botón que abra una **ventana emergente (modal)** con un buscador de Leads pendientes. Al seleccionar uno, su información se carga en la página de edición de la agenda. Al guardar, **no se crea un nuevo registro**, sino que se actualiza el registro del Lead seleccionado, añadiendo la información de la cita y cambiando su estado a `respondido`.
   * **Agendamiento Orgánico Directo**: El módulo de "Agenda" también permite registrar citas orgánicas (es decir, cuando un prospecto contacta espontáneamente, por redes sociales o referido por un tercero, sin haber pasado por el formulario "Me interesa"). En este caso, el agente puede crear una cita completamente nueva desde cero sin requerir asociarla a un Lead preexistente.
2. **Flujo Automatizado (Con IA)**:
   * **Recopilación y Registro Único**: Cuando Ava interactúa con el cliente, obtiene la información de interés y la disponibilidad. La IA registra en la tabla `budget_requests` **ambos conjuntos de datos** (información del Lead y detalles de la Agenda) en un **solo registro atómico**.
   * **Visibilidad Dual**: Este registro aparecerá simultáneamente como un nuevo Lead en el módulo de Solicitudes y como una cita programada en la fecha y hora correspondiente en el módulo de Agenda.
   * **Prevención de Colisiones**: La IA asume la responsabilidad de verificar previamente la disponibilidad en la base de datos para asegurar que no exista solapamiento de horarios con otras citas antes de insertar el registro.

---

### Regla #99: Proactividad e Interrogación Obligatoria (Ask Clarifying Questions)
**Contexto**: En el desarrollo de flujos complejos (como integraciones de IA, gestión de agendas y CRM), es común que la especificación inicial omita casos borde o flujos secundarios (ej. reprogramaciones, notificaciones asíncronas). Asumir el comportamiento de estos casos puede generar deuda técnica o inconsistencias operativas.
**Regla**:
1. **Preguntar sin Dudar**: El Asistente de Desarrollo (IA) DEBE identificar activamente vacíos lógicos en los requerimientos solicitados (ej. "¿Qué pasa si se cancela?", "¿Quién notifica a quién?") y formular preguntas clarificatorias al programador/usuario antes o durante la implementación.
2. **Eliminación de Suposiciones**: Queda prohibido asumir procesos de negocio no especificados explícitamente. Siempre se debe validar con el usuario para asegurar que la solución técnica se alinea perfectamente con la operación real de la inmobiliaria.

---

### Regla #100: Privacidad e Independencia en Notificaciones por Correo
**Contexto**: El sistema envía correos electrónicos automatizados (mediante Brevo u otros proveedores vía Edge Functions) cuando se generan nuevos leads, solicitudes de presupuesto o agendamientos.
**Anti-patrón (Cómo se hacía antes y por qué era un error)**: 
Antes, el código insertaba todos los correos electrónicos (ej. `admin@agencia.com`, `cliente@gmail.com`, `agente@agencia.com`) en un solo arreglo (array) y ejecutaba una única llamada a la API de Brevo. Esto causaba que todos los destinatarios recibieran el mismo correo y pudieran ver las direcciones de correo electrónico de las otras personas en la cabecera "Para:" (To:), violando la privacidad de los datos y mostrando una apariencia poco profesional.
**Regla**:
1. **Llamadas API Independientes**: Queda terminantemente prohibido agrupar correos electrónicos de distintos roles (ej. cliente, agente, administrador) dentro de un mismo arreglo `to` en una única llamada a la API de envío, ya que esto expone las direcciones de correo entre las partes.
2. **Correos de Prospectos vs. Correos Internos**: Se deben ejecutar **mínimo dos llamadas separadas** a la API de correo:
   * **Llamada 1**: Exclusiva para el Cliente/Prospecto (con un mensaje amigable o de confirmación).
     * *Tolerancia a fallos*: Dado que la IA y algunos flujos priorizan la captación del teléfono (ej. para WhatsApp), el correo del prospecto es **opcional**. Si el correo es nulo o inválido, esta llamada se omite silenciosamente sin romper el proceso.
   * **Llamada 2**: Exclusiva para el Agente asignado o el Administrador (con un prefijo claro en el asunto, ej. `[NUEVO LEAD]`, para facilitar filtros internos). Ésta llamada se ejecuta **siempre**, garantizando que el vendedor reciba el lead y el teléfono del contacto.

---

### Regla #101: Consistencia CRM/Agenda en Altas y Bajas (Manual y con Ava)
**Contexto**: El flujo de trabajo del CRM y el Calendario comparten la misma tabla `budget_requests`. Mantener sincronizados los estados de leads y citas es vital para que las bandejas administrativas reflejen la realidad sin duplicar o perder información.
**Regla**:
1. **Creación/Vinculación de Cita**: Al registrar una nueva cita manual desde un lead pendiente, o cuando la IA registra atómicamente una visita con fecha y hora, el estado general (`status`) del lead en el CRM debe actualizarse de inmediato a `'responded'` (Respondido) para reflejar la atención comercial activa.
2. **Eliminación/Desvinculación de Cita**:
   - **Leads Reales (`client_email != 'agenda@local'`)**: Al presionar "Eliminar" en el calendario para una cita que proviene de un prospecto real, **queda prohibido borrar físicamente la fila de la base de datos**. El sistema debe realizar una desvinculación lógica: establecer `is_appointment = false`, limpiar los campos de cita (`appointment_date`, `appointment_time`, `appointment_status`), y **revertir el estado general (`status`) a `'pending'`** (Pendiente). Esto garantiza que el lead regrese a la bandeja del CRM para seguimiento manual del agente y previene fugas de prospectos.
   - **Citas Orgánicas Puras (`client_email == 'agenda@local'`)**: Al borrarse del calendario, se eliminan físicamente de la base de datos de manera definitiva, ya que no corresponden a un lead previo.

---

### Regla #102: Capacitación del Asistente Virtual para CRUD Avanzado y Gestión de Conflictos
**Contexto**: Ava debe actuar como un agente de ventas autónomo y capaz de resolver cualquier consulta de agenda del cliente o del agente de manera bilingüe e interactiva, manteniendo a todos informados en tiempo real.
**Regla**:
1. **Consulta de Citas (Read)**: Ava cuenta con la herramienta `consultar_visitas_cliente` para buscar citas activas usando el teléfono del cliente. Debe usarla para verificar la información existente antes de modificar registros o para contestar preguntas sobre citas programadas.
2. **Notificaciones de Actualización en Caliente**: Cualquier cambio de estado de cita realizado a través de Ava o del panel manual (como confirmar `'confirm'`, reprogramar `'reschedule'` o finalizar `'done'`) debe disparar obligatoriamente una invocación a la Edge Function `send-budget-email` con el parámetro `isUpdate: true` para notificar de inmediato por correo electrónico al agente asignado y al administrador.
3. **Mitigación Inteligente de Conflictos**: Ante un solapamiento de horarios (colisión), el backend retorna las horas ocupadas del día. Ava debe analizar esta lista e indicarle cortésmente al cliente qué horas están reservadas, sugiriéndole de forma proactiva horarios alternativos disponibles en el mismo día.
4. **Finalización de Visita (`done`)**: Ava está capacitada para actualizar la cita al estado `'done'` (Realizada) si un agente o administrador autenticado en la sesión de chat se lo solicita, facilitando el reporte de visitas manos libres.

---

### Regla #103: Convenciones de Nombres en la Tabla de Compañías y Bypass de RLS SELECT
**Contexto**: La tabla de empresas (`companies`) almacena el subdominio del tenant en una columna llamada `domain` (con formato `subdominio.alveo.fyi`) y el correo de contacto en `contact_email`. Intentar realizar consultas a columnas inexistentes como `subdomain` o `email` en Edge Functions causará errores silenciosos de base de datos que dejarán al objeto de compañía en `null`, provocando fallos en cascada en las herramientas de IA (ej: pasar el ID `"undefined"` a consultas UUID en Postgres).
**Regla**:
1. **Acceso a Datos de Tenant**: En las Edge Functions de Supabase, para obtener la información pública y administrativa de la agencia, se debe consultar estrictamente la columna `domain` en lugar de `subdomain`, y la columna `contact_email` en lugar de `email`.
2. **Extracción Conversacional de Subdominio**: Si se requiere el prefijo abreviado del subdominio para construir URLs dinámicas o para el prompt conversacional, se debe extraer del dominio de forma segura:
   ```typescript
   const subdomain = company?.domain ? company.domain.split('.')[0] : 'demo';
   ```
3. **Uso de Cliente de Rol de Servicio para Consultar Compañías**: Dado que los visitantes de catálogo no autenticados (rol `public`) no poseen permisos RLS de lectura (`SELECT`) directa en la tabla de compañías, la Edge Function debe utilizar obligatoriamente `supabaseAdmin` instanciado con la llave de rol de servicio (`SUPABASE_SERVICE_ROLE_KEY`) para consultar la información de la compañía, previniendo que la consulta retorne vacío o cause un crash por falta de privilegios.

---

### Regla #104: Compilación de Presentaciones (Marp CLI y Seguridad de Archivos Locales)
**Contexto**: Alveo incluye dossiers y presentaciones comerciales compiladas en formatos como HTML, PDF y PowerPoint (PPTX) a partir de archivos Markdown (`.md`) usando **Marp CLI**. Si se ejecuta la compilación de forma predeterminada, Marp bloqueará por seguridad el acceso a las imágenes y capturas de pantalla guardadas localmente en la carpeta del proyecto, generando diapositivas completamente en blanco o vacías.
**Regla**:
1. **Acceso a Archivos Locales Obligatorio**: Al compilar cualquier presentación que contenga imágenes locales en la carpeta del proyecto, se DEBE usar obligatoriamente la bandera `--allow-local-files` en Marp CLI.
2. **Evitar Espera de Stream (Stdin)**: Se debe pasar siempre la bandera `--no-stdin` al invocar Marp CLI desde terminales de agentes para evitar que el comando se quede colgado esperando entrada de consola de forma indefinida.
3. **Comando de Compilación Recomendado**:
   ```bash
   npx @marp-team/marp-cli --pptx --allow-local-files --no-stdin <archivo>.md -o <archivo>.pptx
   npx @marp-team/marp-cli --pdf --allow-local-files --no-stdin <archivo>.md -o <archivo>.pdf
   ```
4. **Naturaleza Estática del Formato PPTX de Marp**: Se debe advertir al usuario que por diseño de Marp, la exportación a `.pptx` genera las diapositivas como imágenes completas no editables directamente en PowerPoint (debido a que la conversión nativa editable requiere herramientas de sistema de terceros como LibreOffice Impress que no suelen estar disponibles en los servidores o entornos de despliegue ligeros).

---

### Regla #105: Uso de Roles de Supabase en Edge Function `alveo-ai-chat`
**Contexto**: El Asistente Virtual ("Ava") interactúa con información sensible de la empresa y los clientes que está protegida bajo estrictas políticas RLS en Supabase. Si la Edge Function utiliza el cliente estándar anon con la cabecera de autenticación del usuario, la base de datos retornará listas vacías o fallará silenciosamente debido a que RLS restringe el acceso a un solo tenant o usuario.
**Regla**:
1. **Cliente anon para Consultas Públicas**: Se debe usar `supabaseClient` (configurado con la clave anónima y la cabecera de autorización del usuario) únicamente para consultar la tabla `properties`. Esto garantiza que se respeten correctamente los permisos RLS del tenant para el catálogo público.
2. **Cliente Admin (Service Role) para Operaciones Administrativas**: Se debe usar obligatoriamente `supabaseAdmin` (inicializado con la Service Role Key) para las siguientes operaciones críticas:
   * Leer información interna de la agencia en la tabla `companies`.
   * Insertar y actualizar registros en la tabla `budget_requests`.
   * Consultar perfiles en la tabla `profiles`.
   * Consultar, modificar o cancelar citas en el calendario.
   * Modificar el estado de visitas.

---

### Regla #106: Anti-colisión de Horarios y Matching Difuso de Teléfono en Ava
**Contexto**: La IA de Ava debe verificar conflictos de agenda de manera inteligente y emparejar clientes de manera flexible, tolerando variaciones en la escritura de los números telefónicos (por ejemplo, con prefijos internacionales o espacios).
**Regla**:
1. **Verificación de Colisión Inteligente**: Al comprobar conflictos de horario, la herramienta de agendamiento solo debe comparar y considerar citas confirmadas (`appointment_status = 'confirmed'`). No se deben bloquear horarios por citas con estados pendientes (`pending`) o cancelados, permitiendo una agenda fluida.
2. **Matching de Teléfono Robusto (Fuzzy Match)**: Para la consulta de citas existentes (`consultar_visitas_cliente` y `modificar_solicitud_visita`), ambos números de teléfono (el proporcionado por el usuario y el de la base de datos) deben normalizarse de forma estricta a dígitos numéricos puros (ej. `.replace(/\D/g, '')`). 
3. **Comparación Flexible**: La comparación es positiva si los números son exactamente iguales tras la normalización o si uno actúa como sufijo del otro (ej. `endsWith()`), lo cual tolera de manera automática los prefijos internacionales de país (`+58`, `+1`, etc.).

---

### Regla #107: Arquitectura de Chat de IA y Activación de Micrófono en Web (AiChatScreen Voice Input Context)
**Contexto**: En Flutter Web, la grabación de voz para enviar mensajes de audio interactivos está sujeta a políticas de seguridad estrictas del navegador relativas a la activación por usuario (User Activation Context). Si la inicialización del micrófono (`AudioRecorder.start()`) se difiere o se delega a microtareas o widgets secundarios, el navegador denegará el acceso y la grabación de voz fallará sin levantar la interfaz de permisos.
**Regla**:
1. **Estructura de Visualización**: El chat con Ava en la app de Flutter se visualiza dentro de un `DraggableScrollableSheet` contenido en un modal bottom sheet (`showModalBottomSheet`), adaptando sus dimensiones al dispositivo: 85% a 95% de alto en móviles, y hasta 70% en pantallas de escritorio.
2. **Llamada Síncrona Directa**: El método de inicio de grabación `AudioRecorder.start()` se debe invocar directamente y de forma síncrona dentro del callback `onPressed` o `onTap` del botón de grabación en la UI principal.
3. **Prohibición de Delegación Asíncrona**: Queda terminantemente prohibido diferir la grabación con `Future.microtask`, llamadas asíncronas demoradas o delegar el disparo inicial a un estado secundario tardío, asegurando que se preserve intacto el "transient user-activation context" que los navegadores modernos exigen para conceder permisos mediante `getUserMedia()`.

---

### Regla #108: Payload de Correo Transaccional — `propertyDetails` Obligatorio (No Raw UUIDs)
**Contexto**: La Edge Function `send-budget-email` usa el arreglo `propertyDetails` para mostrar el nombre del inmueble en el correo. Si una Edge Function invocadora (como `alveo-ai-chat`) solo envía `propertyIds` (arreglo de UUIDs) sin incluir `propertyDetails`, el template de correo cae al fallback y muestra el UUID crudo (`3422050c-9218-...`) en el campo **Inmueble**, lo que es técnico e ilegible para el usuario final.
**Regla**:
1. **`propertyDetails` Obligatorio**: Toda invocación a `send-budget-email` (ya sea desde `alveo-ai-chat`, el frontend Flutter u otra Edge Function) debe incluir el arreglo `propertyDetails` con al menos un objeto que contenga: `title` (en formato `Ref: XXX - Título del Inmueble`), `type`, `operation` y `price`.
2. **Formato de Título Estandarizado**: El campo `title` dentro de `propertyDetails` debe formatearse como `Ref: ${String(refNum).padStart(3, '0')} - ${property.title}` para garantizar consistencia visual en todos los correos transaccionales de la plataforma.
3. **SELECT Completo de Propiedad**: Toda consulta a la tabla `properties` que preceda el disparo de un correo debe seleccionar mínimamente: `id, title, type, operation_type, price, listing_agent_id, ref_number`. Omitir campos como `type` o `price` impide construir un `propertyDetails` completo.
4. **Fallback sin UUIDs**: El template de `send-budget-email` nunca debe mostrar UUIDs como fallback de `propertyIds`. El fallback correcto es el label genérico localizado (`"Inmueble"` / `"Property"`).

---

### Regla #109: Compresión Obligatoria de Multimedia antes de Carga (SaaS Storage Safety)
**Contexto**: Toda imagen que un agente intente subir a la galería de un inmueble debe pasar por un proceso de compresión local en el cliente antes de ser enviada al almacenamiento en la nube (Supabase Storage).
**Regla**:
1. **Compresión Local en Cliente**: Previene que los usuarios suban fotografías crudas de cámaras móviles (que pueden pesar entre 5MB y 15MB cada una).
2. **Ahorro e Integridad SaaS**: Ahorra costos de almacenamiento en el plan SaaS, reduce el consumo de datos de red móvil del agente y acelera drásticamente el tiempo de carga de las imágenes en el portal público de cara al cliente final.

---

### Regla #110: Geolocalización Híbrida Asistida por Dirección (Geocoding & Map Coordinates)
**Contexto**: Para dar cumplimiento a la **Regla #56 (Ubicación Exacta)**, el editor de inmuebles debe ofrecer un mecanismo híbrido para la obtención de coordenadas de latitud y longitud.
**Regla**:
1. **Geocodificación Automática**: Al presionar el botón de autodetectar (icono de varita), el sistema debe consultar la API de geocodificación concatenando la dirección escrita, ciudad, estado y país para ubicar las coordenadas de forma aproximada.
2. **Ajuste de Precisión Manual**: Siempre se debe proveer el botón "Asignar en mapa" que abra un diálogo flotante (`LocationPickerDialog`) con un mapa interactivo para que el agente mueva físicamente el pin y lo posicione en la coordenada exacta de la fachada de la propiedad, garantizando que el mapa final de cara al cliente sea 100% verídico.

---

### Regla #111: Heredabilidad de Comisiones por Defecto (Default Commission Policy)
**Contexto**: Las comisiones definidas en la configuración global de la empresa actúan como plantilla base al crear nuevos inmuebles para reducir la transcripción repetitiva de datos de comisiones de la oficina.
**Regla**:
1. **Plantilla Base Global**: Al registrar un nuevo inmueble en el inventario, el formulario de creación completará de forma automática estos valores heredados por defecto desde los ajustes de la empresa.
2. **Libertad de Sobrescritura**: El agente captador siempre conserva la autoridad de modificar y ajustar estos valores de forma personalizada en la ficha individual de la propiedad según los acuerdos de corretaje específicos firmados con el cliente.

---

### Regla #112: Consistencia Matemática en Reparto de Comisiones (Split Complementarity)
**Contexto**: Para evitar descuadres contables entre la administración de la agencia y los vendedores en los cálculos de honorarios de cierre de ventas.
**Regla**:
1. **Principio de Complementariedad Estricta**: El reparto de comisiones de venta entre la Agencia y el Agente se rige por un principio de complementariedad estricta (el porcentaje de los agentes es exactamente `100 - Porcentaje de la Agencia`).
2. **Bloqueo Preventivo**: El campo del porcentaje del agente es de solo lectura y se calcula dinámicamente en tiempo real para evitar ingresos manuales contradictorios u omisiones que provoquen sumas diferentes a 100%.

---

### Regla #113: Estrategias de Crecimiento y Atribución Comercial de Afiliados (Affiliate & Referral Commercial Logic)
**Contexto**: Para evitar desvíos o errores en la asignación de recompensas, el sistema gestiona tres flujos de registro completamente aislados bajo lógicas comerciales distintas.
**Regla**:
1. **Referidos B2B (`showReferralMenu`)**: Es el canal exclusivo de agencias activas para invitar a otras inmobiliarias aliadas mediante un enlace o correo personalizado. **Solo este flujo otorga beneficios mutuos** a la agencia que refiere:
    - **Beneficio Económico**: Descuento recurrente de $1.00 USD mensual por cada referido activo (acumulable con un tope máximo del 25% del valor de su plan).
    - **Beneficio Operativo**: Aumento de capacidad de +2 Inmuebles y +2 Fotos extra por cada referido exitoso (sin límite máximo de acumulación).
2. **Afiliados Comerciales (Ejecutivos)**: Es el canal exclusivo para contratistas o vendedores corporativos de Alveo, quienes captan nuevas agencias compartiendo un enlace personal con su alias único (ejemplo: `alveo.fyi/agent/nicolas`). La plataforma incrusta este identificador en la sesión del visitante, y el ejecutivo recibe de forma directa y recurrente una comisión sustancial (parametrizada en un **40% de la facturación neta**) de cada pago de suscripción realizado por las empresas vinculadas a su alias de forma vitalicia.
3. **Auto-Registro Orgánico (`showOrganicAffiliate`)**: Es el banner promocional discreto al pie del catálogo de cara al público general. **Este flujo es 100% orgánico y autogestionado**; no asocia comisiones automáticas a la agencia anfitriona ni a vendedores, aunque el nuevo usuario puede seleccionar voluntariamente el origen en el formulario público `/register`. Desactivar este interruptor asegura que la web pública quede 100% libre de publicidad o marcas de Alveo.

---

### Regla #114: Prioridad de Visualización en Enlaces de Agente con Propiedad Específica (Agent Link Property Priority)
**Contexto**: Cuando un visitante accede al portal de una agencia utilizando el enlace personal de un agente dependiente que apunta a un inmueble específico (ej: `/agent/alias/refXXX`), la expectativa principal es visualizar dicho inmueble de inmediato. Si el catálogo general aplica de forma estricta el filtro que restringe el inventario visible únicamente a las captaciones de ese agente, cualquier propiedad de un compañero de oficina (terceros) fallará en renderizarse, provocando pantallas vacías y afectando la conversión.
**Regla**:
1. **Bypass del Filtro de Portafolio**: Si la URL contiene una referencia directa a una propiedad (`_targetPropertyRef != null`), el sistema debe omitir obligatoriamente el filtro de exclusión por agente (`listingAgentId == agentContext.id`). Esto permite que la propiedad especificada cargue y se muestre con éxito al visitante.
2. **Preservación de la Marca y Contacto**: Aunque la propiedad pertenezca originalmente a otro captador, la sesión de navegación del visitante debe mantener al agente del enlace (`agentContext`) como el gestor activo en pantalla (foto de perfil, WhatsApp y correo de contacto), garantizando que cualquier lead generado se enrute y asigne a su bandeja privada.
3. **Reactivación del Portafolio Personal**: Si el usuario decide cerrar la visualización detallada del inmueble o presiona el botón para limpiar la búsqueda de la referencia, el sistema re-activará el filtro por defecto, volviendo a mostrar únicamente el inventario captado por el agente.
4. **Caso de Atribución Cruzada Histórico (`/agent/nicolas/ref048`)**: El inmueble `ref048` ("Local para Restaurante con Terraza") es propiedad y captación del agente/administrador Ricardo Cepeda. Sin embargo, al ingresar mediante el link del agente dependiente Nicolas Wayne (`/agent/nicolas/ref048`), el sistema debe realizar el bypass y mostrar con éxito la propiedad bajo la identidad corporativa y los datos de contacto y captación de prospectos (leads) de Nicolas Wayne, atribuyéndole a Nicolas cualquier contacto generado sobre esa propiedad durante esa sesión de navegación.
5. **Consideración Técnica (Ruteo y Estado)**: Para garantizar el funcionamiento de este bypass en producción (compilación `dart2js`):
    - **Ruteo de Deep Links (Web)**: Flutter evalúa la jerarquía de las rutas parte por parte (`/`, `/agent`, `/agent/nicolas`, `/agent/nicolas/ref048`). Es mandatorio mantener la palabra `'agent'` dentro de la constante `reserved` en `onGenerateRoute` de `main.dart`. Si no se incluye, el evaluador asumirá erróneamente que `'agent'` es un alias de vendedor (`SalespersonRouteWrapper`), provocando una redirección silenciosa y destructiva hacia `/` que limpia la referencia del inmueble.
    - **Gestión de Estado**: El control de cambios de agente (`_lastAgentId`) y la petición de bypass (`_targetPropertyRef`) jamás deben mutarse ni validarse directamente dentro del método `build()` del widget, ya que en producción `dart2js` esto ocasiona lecturas obsoletas del provider. Esta validación debe ocurrir siempre en `didChangeDependencies()`.

---

### Regla #115: Comunicación Objetiva (Tono de Asistencia)
**Regla**: El asistente virtual (agente) debe explicar las características, código y estrategias de la plataforma de forma objetiva, técnica y descriptiva. Se debe evitar el uso de adjetivos promocionales, valorativos o subjetivos (ej. "poderosa", "excelente", "fantástica"). La información proporcionada debe centrarse estrictamente en el mecanismo de funcionamiento, la lógica de negocio subyacente y los resultados directos del sistema.

---

### Regla #116: Normalización de Assets en GitHub Releases y URLs de Videos
**Contexto**: Alvéo utiliza GitHub Releases (ej. el tag `v1.0.0-media`) para el alojamiento (hosting) de los videos tutoriales. GitHub aplica un proceso automático de normalización a los nombres de los archivos subidos, el cual debe respetarse estrictamente para evitar errores 404 (Not Found) en el reproductor de la app Flutter.
**Regla**:
1. **Transformación de Espacios y Guiones**: Al subir un archivo, GitHub reemplaza los espacios por puntos (`.`) y comprime secuencias como `espacio-guion-espacio` (` - `) a `.-.`. Ejemplo: `11. alveo - video_manual - comissiones.mp4` se convierte en `11.alveo.-.video_manual.-.comissiones.mp4`.
2. **Sincronización Exacta en Supabase**: Los registros guardados en la tabla `instructional_videos` (columna `video_url`) deben apuntar a la URL que contiene el nombre exacto normalizado por GitHub, nunca al nombre original local.
3. **Consistencia i18n (UI)**: Las etiquetas de navegación de este módulo (y todos los menús del sistema) en los archivos de traducción (`AppLocalizations`) deben escribirse sin signos de puntuación finales innecesarios (ej. usar `Videos Tutoriales` sin punto al final) para preservar un diseño de interfaz limpio y consistente.

---

### Regla #117: Visibilidad y Resiliencia del Carrusel Manual (Manual Carousel Behavior)
**Contexto**: El carrusel de la página de inicio en su estrategia **Manual** está limitado a exactamente 10 slots controlados desde el panel administrativo. La renderización de este carrusel en producción depende de las imágenes que existan en el Storage de Supabase bajo el path `carousel/$companyId/`.
**Regla**:
1. **Ocultamiento por Ausencia de Contenido**: Si una empresa no ha subido ninguna imagen manual o el listado de Supabase retorna un arreglo vacío, la aplicación debe ocultar completamente el carrusel en la interfaz mediante un `SizedBox.shrink()`. Está **estrictamente prohibido** forzar la generación de slots vacíos o mostrar placeholders de error ("imagen no encontrada") de forma predeterminada cuando no hay imágenes cargadas en el Storage, garantizando que el diseño del portal sea limpio y profesional desde el inicio.
2. **Acciones de Clic**: Cuando el usuario interactúa con un elemento activo del carrusel manual:
   * **Enlace Externo**: Si el campo de acción inicia con `http://` o `https://`, se debe abrir mediante `launchUrl` en una pestaña externa.
   * **Propiedad Vinculada**: Si es una referencia a un inmueble (ej: `032`), se debe verificar su existencia en el inventario activo de la empresa y abrir su diálogo de detalles (`PhotoGalleryDialog`) internamente.

---

### Regla #118: Responsividad del Botón "Me Interesa" en Galerías
**Contexto**: El botón flotante "Me Interesa" en la ficha o galería del inmueble (`PhotoGalleryDialog`) debe adaptarse ergonómicamente tanto a dispositivos móviles como a ordenadores.
**Regla**:
1. **Alineación**: En dispositivos móviles (`isMobileMode`), el botón se posiciona de forma centrada para facilitar la accesibilidad del pulgar. En escritorio, se alinea al lado izquierdo, en perfecta armonía con el texto de la dirección.
2. **Dimensiones de padding**: Se debe adaptar la densidad espacial reduciendo los paddings del botón y el tamaño de texto proporcionalmente en móviles para evitar solapamientos u ocultamiento de detalles cruciales del inmueble.

---

### Regla #119: Lanzamiento de Mapas desde el Indicador de Dirección
**Contexto**: El texto de dirección y su respectivo pin en el diálogo de galería actúan como el punto de activación intuitivo para visualizar el mapa interactivo del inmueble.
**Regla**:
1. **Accionador de Fila**: Se debe envolver la fila que contiene el icono de ubicación y la dirección en un `GestureDetector` y `MouseRegion` que aplique `SystemMouseCursors.click` si la propiedad cuenta con coordenadas válidas de latitud/longitud.
2. **Indicador de Interactividad**: Para sugerir de forma elegante que el elemento es clickeable sin sobrecargar la interfaz, el texto de la dirección debe mostrar un subrayado punteado (`TextDecoration.underline` con `TextDecorationStyle.dashed`) en color blanco translúcido (`Colors.white70`), el cual solo se activa si existen coordenadas geográficas válidas para lanzar el mapa.

---

### Regla #120: Lazy-Loading de Mapas para Transiciones de Diálogos (60fps)
**Contexto**: Instanciar, procesar y descargar concurrentemente los tiles geográficos de `FlutterMap` mientras se ejecuta la animación física de escala y desvanecimiento al abrir un modal produce caídas de frames críticas en entornos web y móviles.
**Regla**:
1. **Retardo en Transición**: El inicio y montaje de la capa interactiva `FlutterMap` debe retrasarse un mínimo de **350ms** empleando un retardo asíncrono en `initState`.
2. **Cargador Placeholder**: Durante este breve lapso, se debe renderizar un widget contenedor ligero de carga con un indicador circular animado mínimo, asegurando que la animación física de entrada del diálogo sea suave y estable a 60fps constantes antes de inicializar la renderización y consumo de recursos de la red geográfica.



