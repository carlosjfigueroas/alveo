# Manual de Estrategias de Crecimiento en Alvéo.

Este documento describe los tres canales de adquisición de clientes configurados en Alvéo. Cada estrategia opera de forma independiente y cuenta con una lógica comercial específica para la asignación de recompensas y comisiones.

---

## 1. Referidos B2B (Agencia invita a Agencia).
Este canal está estructurado para que las inmobiliarias actuales inviten a colegas del sector a unirse a la plataforma.

*   **Mecanismo:** La agencia envía un enlace de invitación desde su panel de control a una agencia extérna. Cuando el destinatario utiliza este enlace para crear su cuenta, el sistema vincula automáticamente a ambas empresas.
*   **Beneficios Comerciales:** La agencia que envió la invitación recibe incentivos directos y cuantificables en su cuenta, divididos en dos áreas:
    1.  **Reducciones recurrentes (Económico):** Obtienen un descuento de **$1.00 USD mensual** por cada agencia invitada que mantenga una suscripción activa. Este descuento es acumulativo hasta un máximo del 25% del valor total de su plan base.
    2.  **Expansiones de límite (Operativo):** El sistema aumenta de forma automatizada la capacidad de almacenamiento otorgando **+2 Inmuebles y +2 Fotos extra** sin límite acumulable por cada agencia referida.
    3.  **Opciones disponibles:** Si una agencia prefiere no mostrar Referidos B2B en su web, puede desactivarlo desde su panel de configuración.    

---

## 2. Afiliados Comerciales (Ejecutivos Vendedores-soporte).
Este canal es de uso exclusivo para el equipo de ventas de Alvéo.

*   **Mecanismo:** A cada vendedor se le asigna un enlace personalizado con su alias único (ejemplo: `alveo.fyi/agent/nicolas`). Al compartir este enlace con prospectos, la plataforma incrusta el identificador del ejecutivo de manera transparente en la sesión del visitante. Cuando el prospecto completa su registro de agencia, su empresa queda "etiquetada" y vinculada de forma vitalicia al perfil del vendedor en la base de datos.
*   **Beneficios Comerciales:** El sistema automatiza completamente la liquidación de comisiones. Por cada pago de suscripción mensual o anual que realice la agencia, el ejecutivo recibe de forma directa y recurrente un porcentaje sustancial del ingreso (parametrizado en un **40% de la facturación neta** de la cuenta). Estos fondos son calculados y transferidos periódicamente a la cuenta del afiliado, garantizando una fuente de ingresos continuos a largo plazo por cada agencia que mantenga activa en el sistema.

---

## 3. Registro Orgánico (Iniciativa Propia).
Este canal administra a los clientes que llegan directamente a la plataforma a través de buscadores, redes sociales o publicidad extérna, sin la intervención de un enlace de recomendación.

*   **Mecanismo:** El sistema permite activar un discreto banner promocional (controlado por la variable `showOrganicAffiliate`) ubicado en los catálogos públicos de las propiedades. Los visitantes que hacen clic allí son dirigidos al formulario de registro general (`/register`).
*   **Impacto para Ejecutivos de Ventas:** Este flujo es **100% autogestionado y neutro**. A diferencia de los enlaces personalizados (estrategia 2), el registro orgánico **no asocia comisiones automáticas** al vendedor. Por lo tanto, es vital que los ejecutivos aseguren que sus prospectos utilicen siempre su enlace oficial. Si un prospecto usa la vía orgánica, el sistema solo le pedirá seleccionar voluntariamente cómo conoció la plataforma para fines estadísticos, pero no generará liquidación automática del 40%.
*   **Impacto para la Agencia (Administrador y Agentes):** El administrador de la inmobiliaria tiene control total sobre este banner. Al desactivarlo desde su panel de configuración, se asegura de que todo su catálogo público y el de sus **agentes dependientes** quede 100% libre de publicidad o marcas de Alvéo (*White-label* puro). Además, a diferencia de la estrategia B2B, si otra empresa se registra haciendo clic en este banner orgánico, la agencia anfitriona **no** recibe el descuento de $1.00 USD ni el aumento de capacidad.
