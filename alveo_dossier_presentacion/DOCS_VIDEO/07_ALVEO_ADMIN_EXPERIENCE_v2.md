# Experiencia del Administrador de la Agencia en Alvéo (Panel de Control).

Este video describe de manera objetiva y exhaustiva todos los elementos visuales, herramientas funcionales y opciones disponibles que tiene acceso el Administrador de una agencia inmobiliaria, inmediatamente después de iniciar sesión en la plataforma Alvéo.
El Administrador es el rol de mayor jerarquía dentro del Entorno de una agencia. Tiene acceso completo a todos los módulos operativos, de gestión de equipo, de configuración de marca y de facturación Alvéo.

---

## Inicio de Sesión.
El acceso al panel administrativo se realiza desde la URL del subdominio de la agencia (ejemplo:. tuagencia.alvéo.f-y-i/login).
El sistema presenta un formulario con los siguientes campos:.

*   **Campo de Correo Electrónico:.** El correo registrado como administrador del Entorno.
*   **Campo de Contraseña:.** Contraseña de la cuenta.
*   **Botón de Acción:.** "Iniciar Sesión" que autentica al usuario contra el sistema de base de datos.

Tras la autenticación exitosa, el sistema valida el rol del usuario (Administrador) y redirige automáticamente al Dashboard Principal.

---

## Dashboard Principal (Tablero de Control).
El Dashboard es la pantalla de inicio del panel administrativo. Sirve como centro de comando y ofrece una visión general del estado de la agencia en tiempo real:.

*   **Barra de Navegación Superior:.** Muestra el logotipo de la agencia, el nombre del Entorno activo y un botón de cierre de sesión.
*   **Menú de Navegación Lateral:.** Accesible en todo momento, lista todos los módulos del sistema (Inventario, Equipo, CRM, Agenda, Configuración, Mi Perfil). En dispositivos móviles, se convierte en un menú desplegable hamburguesa.
*   **Indicador de Rol:.** El sistema muestra visualmente el rol activo del usuario (ejemplo:. "Administrador") para confirmar el nivel de acceso.

### Panel de Métricas (KPIs — Indicadores Clave de Rendimiento):.
Conjunto de tarjetas de estadísticas en la parte superior del tablero, actualizadas en tiempo real:.

*   **Inmuebles Activos:.** Número total de propiedades publicadas actualmente frente al límite contratado del plan SaaS (ejemplo:. 18 de 30 inmuebles).
*   **Agentes Registrados:.** Número de asesores activos en la agencia.
*   **Leads Totales:.** Total de solicitudes de contacto o solicitudes recibidas en el período...
	Hagamos un Momento para definir claremente que son leads.
	Un liid en el mundo inmobiliario, es un contacto interesado en comprar, vender, alquilar o invertir en una propiedad que ha compartido voluntariamente sus datos. No es un visitante casual, sino un cliente potencial con una intención clara de interactuar con tu negocio.

*   **Citas Programadas:.** Número de visitas o reuniones agendadas próximas.

## Gestión de Inventario (Módulo de Inmuebles).
Este es el módulo central de la plataforma. Permite el control total y en tiempo real sobre todas las propiedades del catálogo de la agencia:.

### Vista General del Catálogo:.
*   **Lista de Inmuebles:.** Tabla o grilla que presenta todas las propiedades registradas, incluyendo foto principal, número de referencia, título, estado, precio, agente captador y fecha de creación.
*   **Indicadores de Estado Visual:.** Etiquetas de color diferenciadas para cada estado del inmueble (Disponible en verde, Reservado en amarillo, Vendido y Alquilado en gris).


### Herramientas de Búsqueda y Filtrado Interno:.
*   **Buscador por Texto:.** Campo de búsqueda que localiza propiedades por número de referencia, título o dirección.
*   **Filtro por Agente:.** Selector para ver únicamente los inmuebles captados o asignados a un agente específico del equipo.
*   **Filtro por Estado:.** Menú para mostrar solo las propiedades en un estado determinado (Disponible, Reservado, Vendido, Alquilado).
*   **Filtro por Tipo de Operación:.** Separación entre inmuebles en Venta y en Alquiler.

### Formulario de Creación y Edición de Inmuebles:.
Al crear un nuevo inmueble o editar uno existente, se despliega un formulario estructurado por secciones:.

**Sección A — Datos Básicos e Identificación:.**
*   Número de Referencia (asignado automáticamente por el sistema).
*   Título descriptivo de la propiedad.
*   Descripción larga (texto libre para detallar el inmueble).
*   Tipo de Inmueble (Casa, Apartamento, Oficina, Local Comercial, Terreno, Galpón, etc.).
*   Tipo de Operación (Venta, Alquiler).
*   Estado del Inmueble (Disponible, Reservado, Vendido, Alquilado).

**Sección B — Finanzas y Dimensiones:.**
*   Precio de Venta o Alquiler.
*   Moneda (Dólares, Euros, Bolívares, etc.).
*   Monto de Expensas o Mantenimiento mensual (si aplica).
*   Área Total del terreno o parcela .
*   Área Construida .
*   Número de Habitaciones.
*   Número de Baños.
*   Número de Puestos de Estacionamiento.
*   Comisión de Captación y Comisión de Gestión (porcentajes internos para el cálculo de comisiones del equipo).

**Sección C — Ubicación y Geolocalización:.**
*   País, Estado y Ciudad (selectores en cascada).
*   Dirección completa (calle, número, urbanización, municipio).
*   Mapa interactivo integrado para colocar la marcar la ubicación exacta del inmueble (con precisión de calle, no de radio aproximado).

**Sección D — Asignación de Agente:.**
*   Selector de Agente Captador (el asesor responsable del inmueble, quien recibirá parte de los beneficios generados por esa propiedad).
*   Selector de Propietario del Inmueble (registro del cliente dueño de la propiedad).

**Sección E — Multimedia (Galería de Fotos):.**
*   Gestor de carga de fotografías con arrastrar y soltar.
*   Reordenamiento de fotos mediante arrastre para definir el orden de presentación.
*   Eliminación individual de imágenes.
*   Indicador del límite de fotos permitidas por el plan SaaS (ejemplo:. 8 de 10 fotos cargadas).

**Sección F — Amenidades y Características Adicionales:.**
*   Selector múltiple de características del inmueble (ejemplo:. Piscina, Gimnasio, Seguridad 24 horas, Área de Juegos, Terraza, Depósito, Cuarto de Servicio, Generador Eléctrico, etc.).

---

## Gestión de Equipo (Módulo de Agentes).
Este módulo permite al Administrador construir, organizar y supervisar a su equipo de asesores inmobiliarios:.

### Directorio del Equipo:.
*   **Lista de Agentes:.** Tabla con todos los asesores registrados en la agencia, mostrando su foto de perfil, nombre completo, correo, número de WhatsApp, alias (slug) y estado de la cuenta.
*   **Indicador de Actividad:.** Señal visual sobre si el agente tiene su perfil público configurado y activo.

### Creación de Agentes:.
*   **Formulario de Nuevo Agente:.** Campos para registrar nombre, correo electrónico y asignar un rol (Agente).
*   **Creación Directa:.** Opción para el Administrador de crear el perfil del agente sin necesidad de que el agente complete el proceso, asignando directamente su alias, foto, bio y datos de contacto.

### Edición del Perfil del Agente (Desde el Panel Admin):.
*   **Alias (Slug de URL):.** El identificador único del agente en la plataforma (ejemplo:. "carlos-lopez"). Define la URL personalizada del agente (tuagencia.alvéo.f-y-i/agent/carlos-lopez). Debe ser único, en minúsculas y sin palabras reservadas del sistema.
*   **Fotografía de Perfil:.** Subida y actualización de la foto profesional del agente.
*   **Nombre y Apellido:.** Datos de identificación pública.
*   **Biografía Corta:.** Texto de presentación del agente que se muestra en su perfil público.
*   **Número de WhatsApp:.** Número de contacto directo del agente para los leads.
*   **Correo de Contacto:.** Correo del agente para recibir notificaciones de leads y cotizaciones.

### Visualización de Enlaces Personalizados:.
*   **Enlace de Agente:.** El sistema muestra el enlace público y personalizado de cada agente (ejemplo:. tuagencia.alveo.f-y-i/agent/carlos-lopez), listo para que el Administrador lo copie y distribuya.
*   **Enlace de Registro con Referido:.** Si la estrategia de afiliados está activa, el sistema muestra el link de captación de nuevas agencias (ejemplo:. alvéo.f-y-i/register?ref=alias_del_ejecutivo).

### Inventario Compartido y Colaborativo:.
*   **Visibilidad Global del Inventario:.** Todos los agentes de la agencia tienen acceso de lectura al catálogo completo de propiedades para poder ofrecerlas a sus clientes.
*   **Restricción de Escritura:.** Cada agente solo puede editar o eliminar las propiedades donde figura como el Captador oficial. El Administrador puede editar cualquier inmueble sin restricción.

---

## CRM (Gestión de Prospectos).
La Bandeja de Leads es el registro centralizado de todo el interés generado por el catálogo de la agencia:.

### Bandeja de Leads:.
*   **Lista de Solicitudes:.** Panel que reúne todos los contactos y solicitudes de presupuesto enviadas por visitantes desde la plataforma pública.
*   **Información por liid:.** Cada registro muestra el nombre del prospecto, su correo, el inmueble de interés, la fecha de la solicitud y el agente al que fue enrutado.
*   **Enrutamiento Automático:.** Si el visitante llegó por el enlace personal de un agente, el liid se asigna automáticamente a dicho agente. Si llegó por el dominio general de la agencia y solicitó información de un inmueble específico, el liid se enruta al captador de ese inmueble. Si no hay captador, queda en la bandeja general para distribución del Administrador.
*   **Leads Genéricos vs. Leads Asignados:.** El Administrador puede ver todos los leads (incluyendo los no asignados). Los agentes solo ven los leads asignados a ellos.

### Acciones sobre Leads:.
*   **Asignación Manual:.** El Administrador puede reasignar un liid a cualquier agente del equipo desde la bandeja.
*   **Marcar como Gestionado:.** Opción para cambiar el estado del lead (Nuevo, En Seguimiento, Cerrado).

---

## Agenda (Módulo de Calendario y Citas).
Herramienta para la organización del equipo y la gestión de visitas a propiedades:.

*   **Vista de Calendario:.** Interfaz visual de calendario mensual, semanal y diaria para tener una visión clara de todas las citas programadas.
*   **Creación de Cita:.** Formulario para registrar una nueva cita, que incluye:.
    *   Fecha y hora de la visita o reunión.
    *   Inmueble asociado (si aplica).
    *   Agente responsable de atender la cita.
    *   Nombre y datos del cliente.
    *   Notas adicionales (observaciones o instrucciones para el agente).
*   **Edición y Cancelación:.** Opciones para modificar o eliminar citas ya registradas.
*   **Visibilidad por Rol:.** El Administrador visualiza las citas de todos los agentes. Cada agente solo ve sus propias citas en su calendario personal.

---

## Mi Perfil (Perfil del Administrador).
Acceso a la configuración personal de la cuenta del Administrador:.

*   **Datos de Identificación:.** Nombre, apellido y correo electrónico de la cuenta.
*   **Alias (Slug) Personal:.** Si el Administrador también actúa como agente, puede configurar su propio alias de URL y perfil público.
*   **Foto de Perfil:.** Subida de imagen de perfil personal.
*   **Datos de Contacto Personales:.** WhatsApp y correo de contacto del propio Administrador.

---

## Configuración del Entorno de la Agencia.
El módulo de mayor impacto visual y operativo, donde el Administrador define la identidad y los parámetros de su Entorno en Alvéo:.

### Identidad Corporativa:.
*   **Logotipo de la Agencia:.** Subida y actualización del logo oficial, que se reflejará automáticamente en la barra superior de la vista pública, en las cotizaciones PDF y en los correos electrónicos transaccionales.
*   **Paleta de Colores Corporativos:.** Selector de color primario de la agencia. Este color se aplica en tiempo real a los botones principales, los acentos y los elementos destacados de la vista pública, garantizando coherencia de marca.
*   **Nombre Comercial de la Agencia:.** Nombre oficial que aparece en la interfaz pública y en las comunicaciones.

### Información de Contacto General de la Agencia:.
*   **Correo Principal de la Agencia:.** Correo institucional que recibe todos los leads y notificaciones generales que no están asignadas a un agente específico.
*   **Número de WhatsApp General:.** Número corporativo que se activa cuando un visitante hace clic en el botón de WhatsApp sin haber llegado por el enlace de un agente.
*   **Teléfono de Oficina:.** Número de contacto convencional de la agencia.

### Redes Sociales Corporativas:.
*   Campos para registrar los enlaces oficiales a las redes sociales de la agencia:.
	*   WhatsApp.
    *   Instagram.
    *   Facebook.
    *   Telegram.

*   Estos enlaces se traducen en los íconos de acceso directo visibles en la barra superior de la vista pública de la agencia.

### Configuración del Subdominio y URL del Entorno:.
*   **Abreviatura de la Agencia (Abbr):.** El identificador técnico que forma el subdominio (ejemplo:. tuagencia.alvéo.f-y-i). Este parámetro define la identidad multi-tenant de la agencia en el sistema.
*   **Vista Previa del Enlace Público:.** El sistema muestra en tiempo real la URL pública resultante para que el Administrador pueda verificarla antes de compartirla.

### Suscripción y Límites del Plan SaaS:.
*   **Plan Activo:.** Indicador del plan de suscripción vigente y su estado (Activo, Suspendido).
*   **Cuota de Inmuebles:.** Visualización del límite de inmuebles activos contratado (ejemplo:. 30 inmuebles) y el número actualmente utilizado.
*   **Cuota de Fotos por Inmueble:.** Límite de imágenes permitidas por propiedad (ejemplo:. 10 fotos).
*   **Bonos Acumulados:.** Si la agencia fue referida o participó en el programa de afiliados, puede visualizar los bonos de capacidad adicionales aplicados a su cuenta (ejemplo:. +5 inmuebles extra por haber referido a otra agencia).
*   **Historial de Pagos:.** Registro de los pagos reportados y confirmados por el equipo de Alvéo.
*   **Reporte de Pago:.** Herramienta para notificar al equipo de Alvéo que se ha realizado un pago de suscripción (con campo para adjuntar el comprobante).

---

## Notificaciones y Comunicaciones Automáticas.
El sistema genera y envía correos electrónicos automáticos en eventos clave, sin intervención manual del Administrador:.

*   **Notificación de Nuevo liid:.** Cuando un visitante solicita información o envía un presupuesto desde la vista pública, el sistema envía automáticamente un correo al Administrador, al agente asignado y una copia de confirmación al propio visitante.
*   **Notificación de Pago:.** El sistema envía correos en cada estado del ciclo de facturación (Pago Reportado, Pago Confirmado, Recordatorio de Vencimiento, Suspensión de Cuenta).
*   **Correo de Bienvenida al Nuevo Agente:.** Al crear un agente, el sistema envía automáticamente las instrucciones de acceso al correo del nuevo asesor.
*   **Personalización Automática:.** Todos los correos transaccionales llevan el nombre y los colores corporativos de la agencia como identidad visual del remitente, no la marca genérica de Alvéo.

---

## Diferencia con la Experiencia del Agente (Rol Subordinado).
A diferencia del Administrador, el Agente dentro del mismo Entorno tiene acceso restringido:.

*   **No tiene acceso** al módulo de Configuración de la Agencia (identidad, colores, suscripción).
*   **No puede** crear ni eliminar cuentas de otros agentes.
*   **No puede** ver ni reasignar leads de otros agentes.
*   **Solo ve** en su Dashboard las métricas correspondientes a su actividad personal (sus propios leads, sus propias citas, sus propios inmuebles captados).
*   **Puede ver** el inventario completo de la agencia en modo lectura para ofrecer cualquier propiedad a sus clientes.
*   **Solo puede editar** las propiedades donde figura como Captador oficial.

---

## Gestión de la Estrategia de Captación (Módulo de Crecimiento).
Desde el panel administrativo, el Administrador tiene visibilidad sobre cómo su agencia fue incorporada al sistema y puede gestionar su propio programa de referidos hacia otras agencias:.

### Información de Origen:. 
*   **Canal de Registro:.** El panel muestra si la agencia llegó a Alvéo de forma orgánica (Estrategia 3), a través de un ejecutivo de ventas (Estrategia 2), o por referido de otra agencia (Estrategia 1).
*   **Ejecutivo Asociado:.** Si la agencia fue referida por un ejecutivo de Alvéo, el sistema muestra el alias del ejecutivo vinculado a la cuenta.

### Programa de Referidos (Invita a un Amigo):. 
*   **Enlace de Referido de la Agencia:.** El sistema genera un enlace único para que la propia agencia pueda invitar a otras inmobiliarias a unirse a Alvéo y recibir bonos a cambio.
*   **Bonos por Referido:.** Al registrarse una nueva agencia con el enlace de referido, la agencia que invitó recibe automáticamente un bono de capacidad adicional (más inmuebles y fotos disponibles en su cuota) y la nueva agencia obtiene un descuento en su cuota.
*   **Permanencia del Beneficio:.** Los bonos de capacidad son vitalicios mientras la agencia referida se mantenga activa en la plataforma.
*   **Contador de Referidos:.** Visualización del número de agencias que han ingresado usando el enlace de la agencia actual.

---


## Invitar a otra Inmobiliaria (Módulo de Crecimiento Colaborativo).
Este módulo es accesible desde el menú lateral bajo la opción "Invitar a otra Inmobiliaria", visible únicamente cuando la agencia tiene habilitada la opción de referidos en su configuración. Es una herramienta de crecimiento colaborativo dentro del Entorno Alvéo:..

### Pantalla Principal — Crece con Alvéo:.
Al ingresar a este módulo, el Administrador ve una tarjeta titulada "Crece con Alvéo" que explica el programa:.

*   **Descripción del Programa:.** El texto central invita a referir otras inmobiliarias a la plataforma, explicando que la agencia recibirá bonificaciones automáticas cada vez que una agencia receptora complete su registro exitosamente gracias al enlace enviado.

### Tabla de Recompensas Automáticas:.
La pantalla muestra tres beneficios en tarjetas visuales con íconos, que el Administrador recibirá por cada agencia que se registre usando su invitación:.\

*   **Más dos Inmuebles de límite:.** La cuota de inmuebles activos de la agencia aumenta en dos unidades por cada referido exitoso. Sin tope de acumulación.
*   **Más dos Fotos por inmueble:.** El límite de fotografías permitidas por propiedad aumenta en dos unidades adicionales por cada referido. Sin tope de acumulación.
*   **Menos un dólar por mes:.** El monto de la suscripción mensual se reduce en un dólar por cada referido exitoso, con un límite acumulado del veinticinco por ciento del valor del plan contratado.
*   **Aviso Legal:.** La pantalla muestra la nota:. "Límite de rebaja acumulado:. veinticinco por ciento del valor de tu plan. Las capacidades espaciales no tienen tope."

### Formulario de Envío de Invitación:.
Debajo de la tarjeta de recompensas, el Administrador dispone de un formulario sencillo:.\

*   **Campo "Correo de la Agencia Receptora":.** Campo de texto para ingresar el correo de la inmobiliaria a invitar. El sistema muestra como ayuda el texto:. "Ejemplo:. contacto@inmobiliariaamiga.com".
*   **Campo "Agencia que Invita (Tu Inmobiliaria)":.** Muestra automáticamente el correo de contacto de la agencia que envía la invitación, precargado desde la configuración del Entorno. El campo está bloqueado para edición y actúa como remitente verificado del mensaje.
*   **Botón "Enviar Invitación":.** Botón de acción principal. Al pulsarlo, el sistema envía automáticamente un correo formal a la agencia receptora con la información del programa y el enlace de registro con el código de referido ya incorporado.

### Confirmación del Envío:.
Tras enviar la invitación, el sistema muestra una pantalla de éxito con el título "¡Invitación Enviada!", indicando que cuando la empresa receptora complete su registro, la agencia invitante recibirá sus recompensas automáticamente. Desde esa pantalla, el Administrador puede enviar otra invitación de inmediato.

---

## Auto-Registro de una Nueva Agencia (Flujo Público de Incorporación).
Alvéo permite que cualquier agencia inmobiliaria se una a la plataforma de forma autónoma, sin intervención del equipo de Alvéo. Este flujo comienza desde la propia vista pública del portal:.\

### Franja de Captación (Banner Azul en la Vista Principal):.
En la parte superior de la página de inicio, existe una franja de color azul con el texto:. "¿Eres una Agencia Inmobiliaria? Únete a Alvéo y obtén tu propio portal. Regístrate." Esta franja es el punto de entrada para que otras agencias conozcan la plataforma y accedan al formulario de registro con un solo toque. Este banner solo se muestra cuando la agencia tiene activada la opción correspondiente en su configuración.

### Formulario de Registro (Pantalla "Únete a Alvéo"):.
Al pulsar el banner, el visitante es dirigido a la ruta pública (ejemplo:. alvéo.f-y-i/register), donde se presenta el formulario de auto-activación:.

*   **Título:.** "Únete a Alvéo".
*   **Eslogan Hero:.** "Crea tu propia plataforma inmobiliaria hoy."
*   **Información de Prueba:.** "Prueba gratis por siete días. Luego veinte dólares por mes." (el precio varía según el país detectado).

El formulario incluye los siguientes campos:.

**Identidad Visual:.**
*   **Logo para PC:.** Campo para subir el logotipo en versión completa, para pantallas de escritorio.
*   **Logo Móviles:.** Campo para subir el logotipo en versión abreviada, optimizado para la barra de navegación en dispositivos móviles.

**Datos de la Agencia:.**
*   **Nombre de Inmobiliaria:.** El nombre comercial que aparecerá en la plataforma.
*   **Tu Dirección en Alvéo (Link):.** El subdominio único de la agencia (ejemplo:. "miagencia" para miagencia.alvéo.f-y-i). Solo acepta letras minúsculas y números. El sistema verifica en tiempo real la disponibilidad y muestra una vista previa de la URL resultante.
*   **Tu Nombre:.** Nombre completo del Administrador que gestionará la cuenta.
*   **Correo Electrónico:.** Dirección para el acceso al panel y para recibir notificaciones.
*   **Contraseña (Admin):.** Contraseña de acceso al panel administrativo.
*   **Teléfono:.** Número de contacto de la agencia.

**Redes Sociales:.**
*   Campos para registrar los canales de comunicación desde el momento del registro:. WhatsApp (obligatorio), Instagram, Facebook, Telegram, entre otros.

### Activación Inmediata:.
Al completar y enviar el formulario, el sistema crea automáticamente el Entorno de la agencia, el acceso del Administrador y el portal público, sin ningún paso de aprobación manual. La agencia queda operativa al instante y lista para comenzar a cargar su inventario de inmuebles.

---

## Estado de Suscripción Suspendida (Continuidad del Servicio).
En caso de que la suscripción de la agencia sea suspendida por falta de pago, el sistema aplica un modo especial de operación:.

*   **Bloqueo del Panel Administrativo:.** El Administrador y los agentes ven un aviso de suspensión al intentar acceder al panel. No pueden crear ni editar inmuebles.
*   **Preservación de la Vista Pública:.** El catálogo de inmuebles de la agencia permanece visible para los visitantes en modo lectura. Los links compartidos en redes sociales siguen funcionando para no perder el tráfico generado.
*   **Reactivación Inmediata:.** Al confirmar el pago y reactivar la suscripción, el Administrador recupera el acceso completo al panel sin pérdida de datos.
*   **Notificaciones Previas:.** El sistema envía recordatorios automáticos por correo antes de proceder a la suspensión, para dar tiempo a la agencia de regularizar su pago.

---

## Experiencia Bilingüe en el Panel Administrativo.
Todo el panel administrativo está diseñado para operar de forma nativa en dos idiomas:.

*   **Español:.** Idioma predeterminado para el mercado latinoamericano.
*   **Inglés:.** Opción completa para agencias o administradores en mercados angloparlantes o internacionales.
*   **Cambio Persistente:.** El idioma seleccionado se guarda en las preferencias de la sesión. Al iniciar sesión en futuras ocasiones, la interfaz se muestra directamente en el idioma previamente seleccionado.
*   **Alcance de la Traducción:.** La traducción cubre la totalidad de la interfaz administrativa:. botones, etiquetas, mensajes de error, confirmaciones, textos de ayuda, correos automáticos generados por el sistema y el contrato de términos de servicio mostrado durante el registro.

---

## Ciclo de Vida Completo de un Inmueble en el Sistema.
Desde el punto de vista del Administrador, un inmueble atraviesa los siguientes estados durante su ciclo en la plataforma:.

*   **Borrador (Creación):.** El Administrador o el Agente Captador completa el formulario de alta. El inmueble aún no es visible para el público.
*   **Activo (Publicado):.** El inmueble aparece en el catálogo público de la agencia y es visible para los visitantes desde las redes sociales.
*   **Reservado:.** El inmueble está en proceso de negociación o tiene una oferta pendiente. Sigue visible en el catálogo pero con una etiqueta de "Reservado" para informar al visitante.
*   **Pausado:.** El Administrador oculta temporalmente el inmueble de la vista pública sin eliminarlo. Es útil cuando el propietario necesita tiempo o cuando la propiedad requiere actualización de fotos o datos.
*   **Vendido o Alquilado:.** Estado final que registra el cierre exitoso de la operación. El inmueble puede mantenerse en el historial para reportes internos pero deja de mostrarse como disponible al público.
*   **Eliminado:.** El registro se borra permanentemente del sistema, acción que requiere confirmación explícita y es irreversible.

---

## Flujo de Trabajo Típico del Administrador (Día a Día).
Una descripción objetiva del uso cotidiano de la plataforma por parte del Administrador de una agencia activa:.

**Mañana — Revisión de Actividad Nocturna:.**
*   Ingresa al Dashboard y revisa las métricas del día anterior.
*   Verifica la bandeja de Leads para identificar nuevas solicitudes recibidas durante la noche.
*   Asigna los leads sin agente a los asesores correspondientes.
*   Revisa el calendario de Agenda para confirmar las citas del día.

**Durante el Día — Gestión Operativa:.**
*   Carga nuevos inmuebles al sistema utilizando el formulario de alta.
*   Actualiza fotos o datos de propiedades existentes que el equipo ha indicado con cambios.
*   Responde leads genéricos de la bandeja general que no han sido asignados.
*   Genera y envía cotizaciones a prospectos calificados.
*   Invita a nuevos agentes al Entorno cuando el equipo crece.

**Cierre del Día — Registro y Seguimiento:.**
*   Cambia el estado de inmuebles que han sido vendidos, alquilados o reservados durante el día.
*   Registra nuevas citas en la Agenda para los días siguientes.
*   Verifica que los correos de notificación automática hayan llegado correctamente a los agentes y prospectos.
*   Si hay un pago de suscripción pendiente, accede al módulo de Suscripción para reportarlo con el comprobante correspondiente.
