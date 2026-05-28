# Módulo de Gestión de Agentes - Guía para la Administración

Este módulo es el centro de control donde el **Administrador de la Agencia** registra a su equipo de ventas (vendedores y agentes), administra sus cuentas de acceso, configura sus porcentajes de comisiones internas y diseña sus páginas web de marca personal.

Al ingresar a la sección de **Gestión de Usuarios** desde el panel administrativo, la pantalla se divide en las siguientes secciones visuales y campos de control:

---

## 1. Pantalla del Listado de Agentes (Vista General)

Muestra una lista vertical con todas las personas registradas en la oficina:

*   **Identificador de Rol:** Cada fila inicia con un círculo de color que contiene la inicial del agente:
    *   *Círculo Azul:* Agentes de ventas o vendedores tradicionales.
    *   *Círculo Naranja:* Usuarios con permisos de Administrador de la Empresa.
*   **Nombre Completo:** Título en negrita con el nombre del integrante de la oficina.
*   **Rol Asignado:** Etiqueta que identifica su nivel de permisos en la oficina (Administrador o Agente de ventas).
*   **Botones de Acción Rápidos (Esquina derecha):**
    *   *Editar (Icono de lápiz azul):* Abre el formulario completo de la ficha del agente para modificar sus datos o su marca personal.
    *   *Restablecer Contraseña (Icono de llave naranja):* Abre una pequeña ventana flotante para que el administrador reescriba y cambie la contraseña de acceso del agente al instante, sin necesidad de correos de confirmación.
*   **Botón Agregar Agente (Esquina inferior derecha):** Botón extendido para iniciar el registro de un nuevo miembro del equipo.

---

## 2. Diálogo de Registro y Edición del Agente (Formulario)

Al presionar "Nuevo Usuario" o el icono de editar (lápiz), se despliega un formulario detallado con las siguientes opciones de configuración:

*   **Fotografía de Perfil:** Círculo interactivo con un botón de cámara que permite seleccionar y subir la foto del agente desde la galería del dispositivo.
*   **Nombre Completo:** Nombre y apellido oficial del agente.
*   **Correo de Acceso (Solo en nuevos registros):** Dirección de correo electrónico privada que el agente utilizará únicamente para iniciar sesión en la plataforma.
*   **Contraseña Inicial (Solo en nuevos registros):** Clave de acceso inicial para la cuenta del agente.
*   **Correo Público de Contacto:** Dirección de correo alternativa donde el cliente final le escribirá al agente directamente desde el catálogo público de inmuebles.
*   **WhatsApp de Contacto:** Número telefónico en formato internacional (ej. `+58412...`) para que los visitantes de la web abran un chat con un toque.
*   **Alias de la Cuenta (Nombre de Usuario):** Texto corto personalizado sin espacios para construir la dirección web personal del agente (ej: `/agent/alias-del-agente`).
*   **Biografía / Descripción:** Texto libre para que el agente redacte su perfil profesional, el cual se mostrará en su página web personal.
*   **Porcentaje de Comisión Predeterminado:** Comisión acordada por defecto para el reparto de honorarios con la oficina.

---

## 3. Conceptos Operativos Fundamentales

Para una correcta dirección del equipo de ventas, el administrador debe comprender las siguientes reglas comerciales que rigen a los agentes dependientes:

*   **Autonomía de Marca Personal (El Enlace Personal del Agente):** Cada agente registrado en el sistema posee de forma automática su página web personalizada (ej: `/agent/nombre-agente`) que incluye su foto, sus datos de contacto (teléfono y correo público), biografía profesional y un catálogo que muestra todos los inmuebles de la oficina. Si el agente comparte este enlace en sus redes sociales, **cualquier cliente que ingrese y envíe una solicitud de información (lead) se asignará directamente a su bandeja personal**, independientemente de quién sea el captador original de la propiedad visitada.
*   **Privacidad Selectiva (Aislamiento de Cuentas):** Para proteger la base de datos de la empresa y asegurar la privacidad de los clientes, los agentes operan bajo restricciones específicas:
    *   *Bandeja de Leads y Agenda:* Son estrictamente privadas. Un agente solo puede ver los clientes que le fueron asignados y las citas del calendario que le corresponden a su propio ID.
    *   *Catálogo de Inmuebles:* Los agentes poseen **Lectura Global** (pueden ver todos los inmuebles de la oficina para poder ofrecerlos a sus clientes), pero tienen **Escritura Restringido** (solo pueden editar o eliminar propiedades donde figuren como el captador responsable), garantizando que no puedan alterar por error propiedades cargadas por otros compañeros de la oficina.
*   **Diferenciación de Correos de Acceso vs. Contacto:** Para resguardar la privacidad del personal, el sistema separa de forma estricta el *"Correo de Acceso"* (credencial privada para ingresar a la plataforma administrativa) del *"Correo Público de Contacto"* (dirección visible de cara al cliente final). Esto evita que los correos corporativos internos de la empresa queden expuestos de forma pública a spammers en la web.
*   **Restablecimiento Inmediato de Accesos:** Si un agente olvida su clave o se bloquea, el Administrador de la Agencia posee la facultad exclusiva de cambiarle la contraseña de acceso de forma instantánea mediante el icono de llave, sin requerir esperas de soporte técnico o correos de confirmación en la bandeja del agente, reactivando la operatividad de su personal de inmediato.
*   **Heredabilidad de Reparto Interno:** El porcentaje de comisión configurado en la ficha del agente actúa como valor por defecto para el reparto de honorarios de la oficina cada vez que el agente capta un nuevo inmueble, pero puede ser ajustado de forma particular dentro del editor de propiedades si el negocio requiere un trato diferente.
