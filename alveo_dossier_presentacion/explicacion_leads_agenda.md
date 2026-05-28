# Guía Operativa de Solicitudes (Leads) y Agenda (Citas) - Alveo App

Esta sección explica cómo interactúan los prospectos de clientes (leads) y las citas del calendario dentro del sistema de Alveo. El sistema opera bajo un principio de **cero duplicidad de datos**, lo que significa que la información del cliente y la programación de su visita están integradas en una sola ficha de control interna.

---

## 1. El Concepto de Integración Total (CRM y Calendario)

En Alveo, las solicitudes de los clientes y las citas de la agenda no son registros separados. El sistema maneja una ficha única para cada prospecto. Si un cliente solicita información de un inmueble y posteriormente agenda una visita, toda esa interacción se almacena en el mismo expediente digital del cliente. 

Esto permite que cualquier cambio realizado en la cita del calendario actualice de inmediato el estado del cliente en el panel de control del vendedor, y viceversa, sin necesidad de transcribir información.

---

## 2. La Pantalla de Solicitudes (Leads) en el CRM

Al acceder a la sección de **Solicitudes**, los agentes y administradores visualizan la bandeja de entrada de clientes interesados:

*   **Identificación del Estado:** Cada solicitud muestra el estado actual de la gestión comercial mediante un código de colores y etiquetas:
    *   *Pendiente (Color amarillo):* Registros nuevos que requieren contacto inicial por parte del vendedor.
    *   *Respondida (Color verde):* Prospectos que ya han sido atendidos o que ya poseen una cita agendada en el calendario.
    *   *Rechazada (Color rojo):* Prospectos que no calificaron o desistieron de la operación.
*   **Identificación del Origen del Lead:** Cada ficha muestra una insignia que le indica al vendedor cómo llegó ese cliente a la inmobiliaria:
    *   *Insignia de Web (Color verde):* Clientes orgánicos que completaron el formulario de contacto en el catálogo público del inmueble.
    *   *Insignia de Agente IA Ava (Color violeta):* Clientes captados y agendados de forma interactiva por el asistente virtual.
    *   *Insignia de Manual (Color azul):* Citas registradas directamente por el agente de ventas.
*   **Asignación de Vendedores:** Mientras que los agentes de ventas solo visualizan los clientes que tienen asignados directamente, los administradores de la agencia tienen la capacidad de ver todo el inventario de prospectos y utilizar la opción de **Asignar Agente** para delegar la atención a un vendedor específico.

---

## 3. La Agenda (Calendario) y los Dos Tipos de Citas

El módulo de Agenda organiza cronológicamente las visitas programadas. El sistema clasifica estas visitas en dos categorías según su procedencia:

### A. Citas Orgánicas Directas
Son aquellas que el agente de ventas agenda en el calendario para clientes que lo contactaron de manera espontánea por medios externos (como una llamada directa, un referido o redes sociales personales) y que no pasaron previamente por el catálogo web de la agencia.
*   *Gestión en el CRM:* Estas citas se muestran exclusivamente en la Agenda para no saturar la bandeja de prospectos del CRM con tareas cotidianas del agente.

### B. Citas Vinculadas (Provenientes de un Lead)
Son las visitas programadas a partir de una solicitud de información previa cargada en la sección de Leads del CRM.

---

## 4. Flujos de Trabajo en el Día a Día de la Agencia

Los agentes de ventas operan bajo tres flujos principales de gestión de clientes y citas:

### Flujo A: Agendamiento Manual de un Lead del CRM
1.  Un cliente solicita información en la web y entra a la bandeja del CRM en estado **Pendiente**.
2.  El agente de ventas contacta al cliente por teléfono o WhatsApp y acuerda una visita física al inmueble.
3.  El agente abre el módulo de **Agenda** y presiona la opción para agregar una nueva cita.
4.  El sistema le despliega un selector donde puede buscar y seleccionar la solicitud del cliente que estaba pendiente en el CRM.
5.  Al seleccionarlo, los datos del cliente se asocian de forma automática a la cita.
6.  Al guardar la cita, el estado del cliente en la sección de Leads del CRM cambia automáticamente a **Respondido**, indicando que la atención comercial se encuentra en marcha y liberando la bandeja de pendientes.

### Flujo B: Agendamiento Automatizado por la Inteligencia Artificial (Ava)
1.  Un cliente interactúa con el asistente virtual Ava en el catálogo web para coordinar una visita.
2.  Ava verifica que el horario y fecha solicitados estén libres para ese inmueble y ese agente en la base de datos (prevención de colisiones horarias).
3.  Si el horario está disponible, Ava solicita los datos del cliente (nombre, teléfono) y confirma la cita.
4.  De forma simultánea e instantánea, el sistema registra el cliente en la bandeja de Leads del CRM con la insignia de Ava, y posiciona la cita directamente en el calendario de la Agenda en el horario acordado.

### Flujo C: La Regla de Oro en la Cancelación de Citas
Cuando una cita es cancelada o eliminada de la agenda por el agente o el administrador, el sistema evalúa el origen del registro para proteger los contactos de la agencia:

*   *Si la cita era Orgánica Directa:* Al no tener un historial previo en el CRM, el registro de la cita se borra definitivamente de la base de datos.
*   *Si la cita provenía de un Lead Real o fue agendada por Ava:* **El registro del cliente nunca se elimina.** El sistema limpia la fecha y hora del calendario de la agenda y devuelve de forma automática la ficha del cliente a la bandeja del CRM de Leads en estado **Pendiente**. Esto garantiza que el cliente vuelva a aparecer como una tarea por atender, asegurando que el vendedor retome el contacto para ofrecer otras opciones y previniendo la pérdida de prospectos comerciales.
