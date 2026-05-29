# Módulo de Equipo - Guía para la Administración

Este módulo se accede desde la opción de menú **Equipo** en el panel administrativo. Es la sección diseñada para que el Administrador de la Agencia gestione el equipo de ventas, controle sus accesos y configure sus perfiles.

Al ingresar a la sección de **Equipo**, la interfaz expone la lista de integrantes de la oficina y el formulario de registro:

---

## 1. Pantalla de Visualización de Equipo (Listado General)

Muestra una lista vertical con los miembros registrados en la oficina:

*   **Identificador Visual de Rol:** Cada fila se inicia con un círculo de color que contiene la inicial del integrante:
    *   *Círculo Naranja con Inicial (ej: R):* Usuarios con permisos de **Administrador de Agencia**.
    *   *Círculo Azul con Inicial (ej: N):* Usuarios con rol de **Agente**.
*   **Nombre Completo:** Texto destacado en negrita con el nombre del usuario.
*   **Rol Asignado:** Etiqueta inferior que especifica el nivel de permisos (Administrador de Agencia o Agente).
*   **Botones de Acción Rápidos (Extremo derecho):**
    *   *Editar (Icono de lápiz azul):* Abre el formulario de la ficha del integrante para modificar sus datos.
    *   *Restablecer Contraseña (Icono de llave con candado naranja):* Permite la redefinición inmediata de la contraseña de acceso.
*   **Botón Nuevo Agente:** Ubicado en la esquina inferior derecha, de color azul con el texto **+ Nuevo Agente**, diseñado para desplegar el diálogo de creación de usuarios.

---

## 2. Diálogo de Registro y Creación (Nuevo Agente)

Al presionar el botón **+ Nuevo Agente** se despliega una ventana emergente que contiene los siguientes campos y elementos interactivos:

*   **Cargar Foto (Avatar Circular):** Un círculo gris con el icono de un usuario y un botón azul con icono de cámara en la esquina inferior derecha para seleccionar y subir la imagen de perfil.
*   **Nombre completo:** Campo de texto para registrar el nombre y apellido oficial.
*   **Correo de Login:** Dirección de correo electrónico requerida exclusivamente para el inicio de sesión del usuario en la plataforma.
*   **Contraseña:** Campo de entrada para definir la clave de acceso de la cuenta.
*   **Correo Público (Contacto):** Dirección de correo de cara al cliente final, donde se recibirán las consultas generadas en el catálogo web público.
*   **WhatsApp (Ej. +58412...):** Campo de entrada telefónica con formato internacional sugerido para activar el enlace directo de chat de mensajería instantánea.
*   **Enlace Personal (Alias):** Campo de texto para ingresar el nombre de usuario o alias sin espacios que conformará la URL personal del agente (ej: `/agent/alias`).
*   **Biografía / Descripción:** Área de texto libre para redactar la presentación profesional del integrante.
*   **Botones de Control (Esquina inferior derecha):**
    *   *Cancelar:* Cierra la ventana emergente sin aplicar los cambios.
    *   *Guardar:* Almacena el nuevo registro en la base de datos de la inmobiliaria.

---

## 3. Conceptos Operativos Fundamentales

*   **Autonomía de Marca Personal (El Enlace Personal del Agente):** Cada agente registrado en el sistema posee una página web personalizada (ej: `/agent/alias`) que incluye su foto, sus datos de contacto (teléfono y correo público), biografía profesional y un catálogo que muestra todos los inmuebles de la oficina. Si el agente comparte este enlace, las solicitudes de información (leads) generadas en esa sesión se asignan directamente a su bandeja personal.
*   **Privacidad Selectiva (Aislamiento de Cuentas):**
    *   *Bandeja de Leads y Agenda:* Son privadas. Un agente solo puede ver los clientes que le fueron asignados y las citas del calendario asociadas a su ID.
    *   *Catálogo de Inmuebles:* Los agentes poseen permisos de lectura global para ofrecer todas las propiedades de la oficina, pero escritura restringida (solo pueden editar o eliminar propiedades donde figuren como el captador responsable).
*   **Diferenciación de Correos de Acceso vs. Contacto:** El "Correo de Login" es la credencial privada para ingresar a la plataforma, mientras que el "Correo Público (Contacto)" es la dirección expuesta de cara al cliente final, previniendo la exposición pública de los correos internos de acceso.
*   **Restablecimiento Inmediato de Accesos:** Mediante el icono de llave con candado naranja, el Administrador de la Agencia redefine la contraseña del agente de forma directa sin requerir confirmaciones externas por correo, garantizando la continuidad operativa.
*   **Heredabilidad de Reparto Interno:** El porcentaje de comisión configurado en el perfil del agente actúa como valor por defecto al registrar un inmueble, pero puede ser sobrescrito individualmente en el editor de cada propiedad según las características del contrato.
