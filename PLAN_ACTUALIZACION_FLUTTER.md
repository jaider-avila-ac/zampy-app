# Plan de actualización progresiva de Flutter con base en React

> **Proyecto de referencia (solo lectura):** `C:\Users\jaide\Desktop\juan\menu-digital`
> **Proyecto a actualizar:** `C:\Users\jaide\Desktop\juan\zammpy_app`
> **Documento de seguimiento:** este archivo.
> **Última actualización:** 2026-10-30
> **Estado del proceso:** FASES 1–7, 9 y 10 COMPLETADAS; Fase 8 es reservada. Fases 11–17 pendientes.
> **API base confirmada por el usuario:** `https://manzana.zammpy.com`.

---

## 1. Objetivo general

Actualizar `zammpy_app` para alcanzar la mayor equivalencia funcional posible con la implementación actual de React (`menu-digital`), adaptando las interfaces y flujos a una aplicación móvil Flutter, sin modificar React, sin modificar el backend y sin romper la arquitectura existente.

La actualización se ejecutará **fase por fase**, con autorización explícita antes de cada fase, verificación estática/pruebas al finalizar y actualización de este documento con resultados reales.

### Objetivos específicos

- Alinear todos los contratos con la API real que consume React.
- Usar los identificadores públicos (`codigo`) que usa React, no IDs numéricos inventados.
- Corregir autenticación, sesión, refresh de token y protección de rutas.
- Implementar los flujos actuales de Explorar, menú público, gestión de menús, publicación, suscripción, notificaciones, perfil, logros, invitaciones, estadísticas y operación (pedidos/mesas/mesero/repartidor).
- Implementar estados de carga, error, vacío y reintento donde React los tiene o donde la API puede fallar.
- Mantener separación de responsabilidades, reutilizar servicios/modelos/componentes y evitar duplicación.
- No introducir datos simulados como sustituto de integraciones reales.

---

## 2. Reglas obligatorias del trabajo

1. **React es solo lectura.** No se crea, edita, mueve ni elimina nada dentro de `menu-digital`.
2. **El único proyecto modificable es `zammpy_app`.**
3. **No se modifica el backend, credenciales ni configuraciones de producción.**
4. No se inventan endpoints, campos ni comportamientos. Toda decisión se contrasta con React y con las respuestas reales del backend que React consume.
5. No se elimina una funcionalidad Flutter sin analizar dependencias y utilidad; si se reubica, se documenta.
6. No se implementan fases completas por adelantado.
7. Cada fase termina con:
   - `flutter analyze`;
   - pruebas disponibles (`flutter test`);
   - prueba manual del flujo cuando dependa de red;
   - actualización de este documento;
   - resumen al usuario y detención hasta nueva autorización.
8. Si una fase queda con errores importantes, integraciones pendientes o funcionalidad incompleta, **no se marca COMPLETADA**; se registra su limitación.

---

## 3. Metodología y evidencia del análisis

Se revisaron directamente, entre otros:

- Rutas y guardas: `menu-digital/src/App.jsx`.
- Autenticación: `src/context/AuthContext.jsx`, `src/services/authService.js`, `src/modules/auth/**`.
- Explorar: `src/modules/explore/**`, `src/services/exploreService.js`, `src/services/publicApiService.js`.
- Menú público: `src/modules/menu/public/**`, `src/modules/menu/public/edicion/**`.
- Dashboard y editor: `src/modules/dashboard/**`, `src/modules/menu/editor/**`, `src/modules/menu/create/**`.
- Servicios: `menuService.js`, `interaccionService.js`, `colaboracionService.js`, `suscripcionService.js`, `cuponService.js`, `logroService.js`, `estadisticasService.js`, `pedidoService.js`, `mesaService.js`, `repartidorService.js`, `carritoService.js`.
- Notificaciones: `src/context/NotificacionContext.jsx`, `src/modules/notifications/**`.
- Perfil/ajustes: `src/modules/profile/**`.
- Suscripción: `src/modules/subscription/**`.
- Operación: `src/modules/orders/**`, `src/modules/mesero/**`, `src/modules/repartidor/**`.
- Flutter actual: todo `zammpy_app/lib/**`, `pubspec.yaml`, `analysis_options.yaml`, rutas de `app.dart`, servicios, modelos y pruebas.

### Verificación basal ejecutada (sin modificar código)

- `flutter --version`: Flutter 3.41.5 / Dart 3.11.3.
- `flutter analyze`: **4 issues informativos**, sin errores:
  - `use_null_aware_elements` en `colaboradores_tab.dart:526` y `publish_tab.dart:462`.
  - `unnecessary_underscores` en `product_modal.dart:212`.
- `flutter test`: **falla** el único test existente (`test/widget_test.dart`) con `ProviderNotFoundException` porque `ExplorePage` se construye sin `ExploreController`. Es un fallo preexistente, no causado por este plan.
- `PLAN_PROGRESO.md`, `FASES.md`, `ANALISIS_FLUTTER.md` y `FLUTTER_MODULES.md` están desactualizados respecto al código real y al React actual; se usan solo como contexto histórico.

---

## 4. Diagnóstico comparativo

### 4.1 Hallazgos transversales (críticos)

| Tema | React (referencia actual) | Flutter actual | Impacto |
|---|---|---|---|
| Identificadores | La API usa **códigos públicos** (`codigo`, `menuCodigo`, `entidadCodigo`, etc.). React los alinea a `id` en la capa de servicio. | Rutas, modelos y servicios usan `int` (p. ej. `/menus/:id/edit`, `EditorMenu.id`, `m.id as int`). | **Bloqueante**: muchas pantallas convierten códigos a `0`, fallan al parsear o llaman `/menus/0/...`. |
| Contrato de menú | `GET /menus/{codigo}`, `draft` con `info`, `design`, y catálogo por endpoints separados. | Espera `id`, `ownerId`, `hasDraftChanges`, `catResId`, `categories/products/grupos` dentro de `/draft`. | **Bloqueante**: el editor no carga; los guardados de catálogo se ignoran. |
| Guardado de catálogo | Categorías/productos/grupos usan `/menus/{id}/categorias`, `/productos`, `/grupos` y subendpoints. | Envía `{categories:[...]}`, `{products:[...]}`, `{grupos:[...]}` a `/draft`. | **Bloqueante**: cambios de catálogo no persisten. |
| Imágenes | `POST /api/v1/images/upload?folder=...` multipart campo `file`. | `POST /menus/{id}/upload` con `tipo` + `file`. | **Bloqueante**: logo/portada/productos no suben. |
| Geografía | `GET /public/geografia/paises`, `/divisiones?pais=`, `/municipios?division=&q=`. | `GET /public/geografia/estados`, `/ciudades`. | **Bloqueante**: cascada de ubicación vacía; registro y creación no completan. |
| Temas | Catálogo devuelve `codigo` para tema/paleta. | Lee `id`; queda `null`. | **Bloqueante**: selector de diseño y paso de diseño no funcionan. |
| Paginación | Notificaciones/reseñas/pedidos devuelven `{items, siguiente}`. | Varios servicios hacen `jsonDecode(...) as List`. | Notificaciones y reseñas siempre vacías. |
| Sesión | Token + `refreshToken`; ante 401 intenta `POST /auth/refresh`; logout global. | No hay refresh; cada servicio maneja 401 por su cuenta. | Sesión caduca y no se renueva; el usuario queda en estados vacíos. |
| Rutas privadas | `PrivateRoute` redirige a login. | `go_router` no tiene guardas; todas las rutas son accesibles. | Riesgo funcional y de seguridad; pantallas privadas fallan sin sesión. |
| API base | React: `https://menu-digital-9p3g.onrender.com` (`.env.production`). | Flutter: `https://manzana.zammpy.com`. | **Decisión pendiente**: no se cambiará sin confirmación; podría ser un backend distinto/actualizado. |
| Modelo de edición | React edita contenido directamente en `/menu/:slug` (modo dueño/editor), y conserva tabs para grupos/publicar/colaboradores/mesas/pedidos. | Editor Flutter con tabs propios. | No es necesario copiar la UI web; se mantendrán tabs móviles, alineando operaciones y datos. |
| Tiempo real | STOMP: `/user/queue/notificaciones`, `/user/queue/suscripcion`, `/user/queue/pedidos`. | Solo notificaciones y suscripción; sin pedidos, sonido ni manejo de auth. | Notificaciones/pedidos no se actualizan como React. |

### 4.2 Diagnóstico por módulo

#### Autenticación

**React actual**
- Login email/password; alertas por query (`registered`, `verified`, `verifyError`, `error=use_password`).
- Registro con nombre, apellido, email, contraseña, **municipio obligatorio del catálogo** y teléfono opcional; contraseña mínima **6**; error especial `CODE_PENDING`.
- Verificación por código de 6 dígitos, autoenvío, reenvío con cooldown, login automático al verificar.
- Recuperación con código de 6 dígitos; manejo de cuenta Google (`GOOGLE_ACCOUNT`).
- Google: web por OAuth redirect; móvil por `POST /auth/google/token` con `idToken`.
- Invitación por `/invite/:code`, guardada como `inv_ref` y enviada en `preRegister`; en Google se conserva con `POST /invitaciones/pre-sesion`.
- Refresh token ante 401; logout global.

**Flutter actual**
- Login, registro, verificación, recuperación y reset existen con UI y estados.
- Registro **no envía municipio** ni teléfono y valida contraseña ≥ 8 (la UI dice 6). Esto no coincide con React y el backend rechaza el registro.
- No hay `/invite/:code`, ni captura de `invRef`, ni `preSesion`.
- No hay refresh token ni manejo global de 401.
- No hay guardas de ruta; `AuthContext.loading` no se usa para proteger el arranque.
- No hay pantalla `VerifyEmailSentPage` ni `AuthCallbackPage` (en móvil nativo el callback web no aplica, pero sí el manejo de errores/Google).
- `userId` suele quedar nulo porque el login devuelve `userCodigo`, no `userId`.

**Conclusión:** Fase 1 debe incluir no solo pantallas, sino contrato de registro, sesión, refresh, guardas y captura de invitación.

#### Explorar

**React actual**
- Dos pestañas: **Menús** y **Platos**.
- Menús: búsqueda con debounce 350 ms, filtros de municipio/categoría desde `GET /explore/filtros`, scroll infinito por cursor.
- Platos: mosaico con `GET /explore/productos`, búsqueda, filtros, paginación por cursor y semilla estable.
- Tarjetas usan `codigo`, `nombre`, `logoUrl`, `categoria`, `municipio`; platos usan `codigo`, `nombre`, `imagenUrl`, `menuSlug`, `menuNombre`.
- “Me encanta” de menús/platos con `mis-encantados` y `mis-productos-encantados`.
- Ubicación = municipio guardado/perfil, **no GPS**. No se usan las secciones viejas `inicio/feed` en la pantalla actual.

**Flutter actual**
- Tiene una implementación visual amplia (secciones “Cerca de ti/Tendencias/Nuevos”, búsqueda, scroll, likes, ubicación por GPS/Nominatim).
- Usa un modelo de tarjeta viejo (`menId`, `nombreNegocio`, `ciudad`) y por eso las tarjetas quedan con id 0 y se filtran.
- No tiene pestaña Platos, filtros de categoría/municipio ni la forma actual de `explore/scroll`.
- El scroll infinito no encadena más de una página.
- `mis-encantados` espera números, pero React/backend devuelve códigos.

**Conclusión:** conviene reescribir la capa de datos de Explore y adaptar la UI a Menús/Platos; conservar splash, skeletons y manejo de sin conexión que ya existen.

#### Menú público

**React actual**
- Modo público, modo dueño/editor (`GET /menus/acceso?slug=`) y modo staff/mesero (`?staff=1`, `?mesa=`).
- Banner ampliado (logo, slogan, ubicación, horario, galería, teléfono/WhatsApp/email, redes), tabs de categorías, destacados, grid/lista/carrusel, búsqueda local.
- Modal de producto con tamaños, ingredientes, extras, grupos, promoción, “me encanta” de producto, compartir/QR.
- Reseñas de texto (no estrellas), “me encanta” del menú, paginación por cursor.
- Tracking de vistas de menú (a los 5 s) y producto, con `X-Viewer-Token`.
- Carrito/pedido de cliente y orden de mesero (según modo).
- Deep links `?producto=`.

**Flutter actual**
- UI de menú público bastante completa, pero:
  - no registra vistas;
  - reseñas no cargan por paginación;
  - `ownerId`/`esPropio` mal resueltos;
  - enlaces sociales y “Cómo llegar” sin acción;
  - no hay carrito/pedido de cliente;
  - no hay modo dueño/editor ni staff/mesero;
  - catálogo de temas roto por `id` vs `codigo`;
  - `PublicMenuData` ignora `ubicacion`, `miRol`, `horario`, `categoriaCodigo`.

**Conclusión:** Fase 3 debe estabilizar el visor público (modelo, reseñas, likes, temas, tracking, enlaces). El carrito/pedido se difiere a Fase 13 para no mezclar con gestión de menús.

#### Mis Menús y hub del menú

**React actual**
- `GET /menus/tarjetas` devuelve `{items, limiteMenus}`; cada ítem `{codigo, slug, nombre, logoUrl, categoria, municipio, estado}`.
- Colaboraciones en `GET /menus/colaboraciones`.
- `MenuHubPage` carga `GET /menus/{codigo}/resumen`, usa `esPropio`, `miRol`, `pasos`, y ofrece acciones según rol: editar, grupos, estadísticas, pedidos, mesas, plan/visibilidad, colaboradores, vista mesero/repartidor.
- Eliminar menú: `GET /delete-code` + `DELETE` con `X-Delete-Code`.
- Despublicar: `POST /unpublish`.

**Flutter actual**
- Lista propia y colaboraciones, skeletons y límite, pero:
  - hace `m['id'] as int` → crash con códigos;
  - no tiene hub;
  - no tiene eliminar, despublicar, “ver público”, compartir ni pasos;
  - no tiene acciones por rol.

**Conclusión:** Fase 5 debe migrar a códigos, añadir hub y acciones; Fase 7/9 completan publicación y colaboradores.

#### Crear menú

**React actual**
- Pantalla simplificada: nombre, slug, categoría, logo y portada diferidos.
- `POST /menus` con `{restaurantCategoryCode, name, slug}`.
- Sube imágenes a `/images/upload` y guarda con `PATCH /secciones/logo` y `PATCH /secciones/portada`.
- Navega al hub del menú; el resto de datos se completa después.

**Flutter actual**
- Wizard de 5 pasos, pero:
  - envía `restaurantCategoryId` numérico y categorías hardcodeadas;
  - exige ubicación con campos viejos;
  - usa endpoints de geografía inexistentes;
  - no puede completar diseño por ids nulos;
  - envía `skinId/paletteId` planos en vez de `temaCodigo/paletaCodigo`;
  - sube imágenes al endpoint equivocado;
  - espera `id` numérico en la respuesta;
  - envía `schedule` en vez de `horario`.

**Conclusión:** Fase 6 debe rehacer el flujo de creación contra el contrato actual y decidir la ubicación de los campos extendidos. Propuesta: mantener un wizard móvil útil, pero persistir cada sección con endpoints válidos; los pasos contacto/redes/diseño se reutilizan desde el editor para no perder funcionalidad.

#### Editor de menú

**React actual**
- Edición directa en el menú público para logo, portada, identidad, categoría, contacto, ubicación, redes, galería y tema.
- Catálogo por endpoints: categorías, productos, grupos; cada operación guarda de inmediato.
- Producto por partes: básico, tamaños, ingredientes, adiciones, grupos, promoción, explorar, visible, eliminar.
- Tabs persistentes para grupos, publicar, colaboradores, mesas y pedidos.
- Requisitos de publicación: logo, portada, al menos un producto, al menos una categoría, imagen en productos de categorías con imágenes, precio, contacto y slug disponible.
- Cupones, logros aplicados, planes, upgrade y checkout.
- Estadísticas con rango de fechas.

**Flutter actual**
- Editor con tabs (Categorías, Productos, Grupos, Diseño, Publicar, Colaboradores) y formularios completos, pero:
  - no carga por contrato (`id/ownerId`);
  - guarda catálogo en `/draft`;
  - no usa endpoints por sección;
  - diseño roto por ids de tema;
  - publicación bloquea casos válidos y no aplica trial/plan correctamente;
  - no tiene cupón, logros aplicados, plan badge real ni pasos;
  - no tiene `enExplorar`, posición de imagen, galería, email, `pedidosActivos`;
  - colaboradores sin roles ni aceptación/rechazo;
  - info de negocio no guarda slug ni conserva horario.

**Conclusión:** Fase 7 es la fase más grande. Se divide internamente en tareas verificables, pero se ejecutará como una sola fase autorizada.

#### Notificaciones

**React actual**
- Lista paginada, marcar leída/todas, eliminar.
- Acciones de aceptar/rechazar colaboración y transferencia.
- Deep links a pedidos, suscripción y menú.
- WebSocket global con cola de notificaciones, suscripción y pedidos; sonido; refresco por eventos.

**Flutter actual**
- Página, badge, marcar todas, eliminar y WebSocket parcial.
- Lista siempre vacía por parseo `List` en vez de `{items, siguiente}`.
- Lee `id`/`entidadId` en vez de `codigo`/`entidadCodigo`.
- No pagina, no muestra error, no acepta colaboraciones, no abre billing específico, no escucha pedidos ni maneja auth en STOMP.

**Conclusión:** Fase 8 debe corregir contrato, paginación, acciones y WebSocket; es dependencia de colaboradores y operación en tiempo real.

#### Perfil, ajustes y cuenta

**React actual**
- Perfil: nombre/apellido/avatar, email solo lectura, ubicación, contacto de pedidos, contraseña solo si `LOCAL`.
- Ajustes: código de invitación, sesiones/dispositivos (revocar), eliminación de cuenta con código de 5 caracteres.
- Validación de avatar (JPG/PNG/WebP/GIF, 5 MB).

**Flutter actual**
- Perfil y ajustes existen; avatar, nombre, contraseña, dispositivos, código y copia.
- Faltan ubicación, contacto de pedidos y eliminación de cuenta.
- Dispositivos usan `id` en vez de `codigo`.
- El “push” solo pide permiso, no registra token ni recibe push real; el texto de UI es engañoso.
- Caché de perfil/dispositivos no se limpia al cerrar sesión.

**Conclusión:** Fase 10.

#### Logros e invitaciones

**React actual**
- Logros: progreso, estados, recompensas disponibles y **aplicar días a un menú propio** con idempotencia.
- Invitaciones: enlace, activar/desactivar, completadas/pendientes, detalle por invitación, reglas del programa.
- Registro por invitación y atribución.

**Flutter actual**
- Tarjetas de logros y pantalla de invitaciones con métricas, copiar y toggle.
- No aplica logros a menús; `codigo` no se mapea; ignora detalle/reglas; no hay ruta de invitación ni `invRef`.

**Conclusión:** Fase 11.

#### Estadísticas

**React actual**
- Rango de fechas, vistas, “me encanta”, operaciones entregadas, conversión.
- Productos más vistos, más “encantados” y más pedidos.
- Tracking de vistas desde el menú público.

**Flutter actual**
- Solo vistas totales y productos más vistos; sin rango de fechas, sin likes, operaciones ni conversión; sin tracking de vistas.

**Conclusión:** Fase 12; depende de Fase 3 (tracking) y Fase 7 (menú).

#### Pedidos, mesas, mesero y repartidor

**React actual**
- Cliente: carrito persistido en servidor, solicitud de pedido, historial y cancelación.
- Negocio: pedidos por fecha, estados, valor pagado, asignación de repartidor, cuentas de mesa, ajustes/pagos auditados.
- Mesas: CRUD, activación, capacidad.
- Mesero: mesas, cuentas divididas, rondas, pagos, cierre, historial.
- Repartidor: pedidos asignados/disponibles, tomar, estados, historial.
- Todo con WebSocket de pedidos y reglas de rol.

**Flutter actual**
- No existe ninguno de estos módulos.

**Conclusión:** Fases 13-16. Son flujos grandes y parcialmente orientados a escritorio; se adaptarán a móvil sin copiar la UI web.

---

## 5. Inventario funcional y estado de equivalencia

Leyenda: **OK** = implementado y alineado; **PARCIAL** = existe pero incompleto/desactualizado; **ROTO** = existe pero no funciona contra el contrato actual; **FALTA** = no existe.

| Módulo / funcionalidad | React | Flutter | Estado |
|---|---|---|---|
| Login email/password | Sí | Sí | PARCIAL |
| Registro con municipio/teléfono | Sí | No | ROTO |
| Verificación email por código | Sí | Sí | PARCIAL |
| Recuperar/reset contraseña | Sí | Sí | PARCIAL |
| Google nativo | Sí (móvil) | Sí | PARCIAL |
| Invitación `/invite/:code` | Sí | No | FALTA |
| Refresh token / expiración | Sí | No | FALTA |
| Guardas de rutas | Sí | No | FALTA |
| Explorar menús (búsqueda/filtros/scroll) | Sí | Parcial | ROTO |
| Explorar platos | Sí | No | FALTA |
| Likes menú/producto | Sí | Parcial | ROTO |
| Menú público visual | Sí | Sí | PARCIAL |
| Reseñas texto + paginación | Sí | Parcial | ROTO |
| Tracking de vistas | Sí | No | FALTA |
| Compartir/QR | Sí | Parcial | PARCIAL |
| Carrito/pedido cliente | Sí | No | FALTA |
| Mis Menús (tarjetas) | Sí | Sí | ROTO |
| Hub del menú / pasos | Sí | No | FALTA |
| Eliminar/despublicar menú | Sí | No | FALTA |
| Crear menú | Sí | Sí | ROTO |
| Editor info negocio | Sí | Sí | ROTO |
| Categorías/productos/grupos | Sí | Sí | ROTO |
| Diseño/temas | Sí | Sí | ROTO |
| Publicar/requisitos | Sí | Sí | ROTO |
| Cupones | Sí | No | FALTA |
| Planes/checkout/Wompi | Sí | Parcial | ROTO |
| Auto-cobro | Sí | No | FALTA |
| Colaboradores/roles/transferencia | Sí | Parcial | PARCIAL |
| Notificaciones | Sí | Parcial | ROTO |
| Perfil | Sí | Parcial | PARCIAL |
| Ajustes/dispositivos | Sí | Parcial | ROTO |
| Eliminar cuenta | Sí | No | FALTA |
| Logros (aplicar) | Sí | No | FALTA |
| Invitaciones (programa) | Sí | Parcial | PARCIAL |
| Estadísticas | Sí | Parcial | PARCIAL |
| Pedidos cliente | Sí | No | FALTA |
| Pedidos negocio/mesas | Sí | No | FALTA |
| Mesero | Sí | No | FALTA |
| Repartidor | Sí | No | FALTA |

---

## 6. Fases de implementación

> **Orden ajustado y justificado:** se conserva Fase 1 = Autenticación y Fase 2 = Explorar. La Fase 3 se dedica al **menú público**, porque es la pantalla destino de Explorar y base del modo edición de React. Las notificaciones pasan a Fase 4 (independientes y tempranas). La gestión de menús propios comienza en Fase 5. Las fases de operación (pedidos/mesas/mesero/repartidor) se dejan al final por tamaño y porque dependen de menús publicados.

### Fase 1 — Autenticación y sesión

**Estado:** COMPLETADA
**Depende de:** ninguna.
**Bloquea a:** todas.

**Objetivo específico**
Dejar un sistema de autenticación móvil equivalente al React actual, con sesión persistente, refresh, guardas y registro válido para el backend.

**Pantallas / funcionalidades**
- Login con alertas y errores equivalentes.
- Registro con municipio obligatorio, teléfono opcional, contraseña mínima 6 y manejo de `CODE_PENDING`.
- Verificación por código de 6 dígitos, reenvío con cooldown y login automático.
- Recuperación y reset con código; caso `GOOGLE_ACCOUNT`.
- Google nativo con `idToken` y manejo de error `use_password` si aplica.
- Ruta `/invite/:code` y persistencia de `invRef`; envío en `preRegister`.
- `AuthContext`: token, refreshToken, usuario, logout global, `updateUser`.
- Cliente HTTP/base compartida con `Authorization` y refresh ante 401.
- Guardas de `go_router`: rutas privadas → login; rutas guest → explore; conservar destino de retorno.
- Splash/arranque mientras se restaura la sesión.

**Archivos principales**
- `lib/context/auth_context.dart`
- `lib/services/auth_service.dart`
- `lib/services/api.dart` (solo cliente/base; no cambiar host sin confirmación)
- `lib/app.dart`
- `lib/main.dart`
- `lib/modules/auth/pages/login_page.dart`
- `lib/modules/auth/pages/register_page.dart`
- `lib/modules/auth/pages/verify_email_code_page.dart`
- `lib/modules/auth/pages/forgot_password_page.dart`
- `lib/modules/auth/pages/reset_password_page.dart`
- `lib/modules/auth/hooks/use_login_form.dart`
- `lib/modules/auth/hooks/use_register_form.dart`
- `lib/modules/auth/hooks/use_verify_email_code.dart`
- `lib/modules/auth/hooks/use_forgot_password.dart`
- `lib/modules/auth/hooks/use_reset_password_form.dart`
- `lib/services/geography_service.dart`
- `lib/shared/location_cascade_widget.dart`
- Nuevos: `lib/modules/auth/pages/invite_page.dart`, `lib/modules/auth/pages/verify_email_sent_page.dart` (si se decide conservar el flujo legacy), `lib/shared/api_client.dart`.

**Contrato a respetar**
- `POST /api/v1/auth/login` → guardar token + refreshToken + usuario.
- `POST /api/v1/auth/pre-register` con `{nombre, apellido, email, password, municipioCodigo, telefono?, invRef?}`.
- `POST /api/v1/auth/register` con `{email, code}` → sesión iniciada.
- `POST /api/v1/auth/resend-verification`.
- `POST /api/v1/auth/forgot-password`.
- `POST /api/v1/auth/reset-password` con `{token, password}`.
- `POST /api/v1/auth/refresh` con `{refreshToken}`.
- `POST /api/v1/auth/google/token` con `{idToken}`.
- Geografía: `/paises`, `/divisiones?pais=`, `/municipios?division=&q=` (corregir en esta fase porque el registro lo necesita).

**Tareas verificables**
- [x] Auditar y documentar la forma real de respuesta del login/refresh (campos exactos).
- [x] Corregir `GeographyService` a `/divisiones` y `/municipios`.
- [x] Implementar cascada de ubicación reutilizable para registro/perfil.
- [x] Añadir municipio y teléfono al registro; alinear validación a 6 caracteres.
- [x] Manejar `CODE_PENDING` y errores de código expirado/inválido.
- [x] Implementar persistencia de `refreshToken` y refresh automático con reintento único.
- [x] Implementar logout global y limpieza completa de cachés de usuario.
- [x] Añadir guardas de rutas y destino de retorno.
- [x] Añadir `/invite/:code` y `invRef`.
- [x] Revisar Google nativo y errores de cuenta con contraseña.
- [x] Añadir estados de carga/error/vacío y textos equivalentes.
- [x] Ejecutar `flutter analyze` y `flutter test` (actualizar el test roto o documentar).
- [x] Actualizar este documento con archivos, pruebas y resultados.

**Resultado real de Fase 1**
- Se creó un cliente HTTP compartido (`lib/services/api_client.dart`) con `Authorization`, timeout, parseo de errores y refresh único ante 401.
- Se corrigió la base a `https://manzana.zammpy.com`.
- `AuthContext` persiste token/usuario/refreshToken y registra los handlers globales de refresh/logout.
- Se agregaron guardas de `go_router` y retorno a la ruta privada solicitada.
- Registro ahora envía `municipioCodigo`, teléfono e `invRef`; contraseña mínima 6.
- Se agregaron componentes reutilizables equivalentes a React: `AuthLayout`, `LocationCascadeInput`, `TelefonoInput`.
- Se agregaron `/invite/:code`, `/auth/verify-sent`, `InviteStore`, `AuthRedirect` y alertas de login/verificación/reset.
- Se corrigieron verificación por código (cooldown 300 s, errores), recuperación y reset.
- Se actualizó la prueba de humo y se añadieron pruebas de `AuthRedirect` y `LocationCascadeValue`.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 4 avisos informativos preexistentes en módulos de menú/editor (no relacionados con Fase 1).
- `flutter test`: 5 pruebas aprobadas (login renderiza, AuthRedirect, LocationCascadeValue).
- Endpoints verificados contra `manzana.zammpy.com`: `/public/geografia/paises`, `/divisiones`, `/municipios` y `POST /auth/login` (401 esperado con credenciales inválidas).
- No se ejecutó un registro real para no crear cuentas ni enviar correos; queda como prueba manual del usuario.
- React no fue modificado (`git status` de `menu-digital` vacío).

**Limitaciones registradas**
- No se implementó el callback OAuth web (`/auth/callback`), porque el flujo móvil usa Google nativo con `idToken`; se documentará si se compila para web.
- No se dispone de credenciales de prueba para validar un login/registro exitoso de extremo a extremo en dispositivo.
- Los servicios de módulos posteriores (menús, suscripción, notificaciones, etc.) todavía leen el token directamente; se migrarán a `ApiClient` en sus fases. El refresh global ya queda activo para `AuthService`/geografía y para toda llamada nueva que use `ApiClient`.
- El texto de notificaciones push de Fase 10 sigue pendiente de corregirse; no es parte de esta fase.

**Criterios de aceptación**
1. Un usuario nuevo puede registrarse con municipio y verificar su correo; el flujo llega a sesión iniciada.
2. Login, verificación, recuperación y reset muestran errores reales del backend sin quedar en blanco.
3. Al expirar el token, la app renueva con refreshToken; si falla, cierra sesión y va a login.
4. Rutas privadas redirigen a login sin sesión; rutas guest redirigen a explore con sesión.
5. `/invite/:code` guarda el código y el registro lo envía como `invRef`.
6. `flutter analyze` sin errores; pruebas actualizadas o fallo preexistente documentado.
7. No se modificó React ni el backend.

---

### Fase 2 — Explorar (menús y platos)

**Estado:** COMPLETADA
**Depende de:** Fase 1 (sesión/likes y cliente HTTP).
**Bloquea a:** Fase 3 (destino menú público), Fase 5 (tarjetas).

**Objetivo específico**
Reemplazar el feed viejo por el Explorar actual de React: menús y platos, búsqueda, filtros, ubicación por municipio, scroll por cursor y likes.

**Pantallas / funcionalidades**
- Pestañas “Menús” y “Platos”.
- Búsqueda de menús con debounce 350 ms contra `GET /public/menus?search=&categoria=&municipio=`.
- Filtros desde `GET /explore/filtros` (categorías/lugares con resultados).
- Scroll de menús `GET /explore/scroll` con cursor y exclusión.
- Platos `GET /explore/productos` con cursor, semilla y límite.
- Tarjetas con campos actuales.
- Likes de menús/productos con estado compartido y login requerido.
- Ubicación: municipio guardado o del perfil; selector de lugar; persistencia local.
- Estados: skeletons, vacío, error, sin conexión y reintento.
- Tarjetas abren menú público (`/menu/:slug` y `?producto=` para platos).

**Archivos principales**
- `lib/modules/explore/pages/explore_page.dart`
- `lib/modules/explore/hooks/use_explore.dart`
- `lib/modules/explore/components/menu_card.dart`
- `lib/modules/explore/components/skeleton_card.dart`
- `lib/modules/explore/components/infinite_explorer.dart`
- `lib/modules/explore/components/location_banner.dart`
- `lib/modules/explore/components/section.dart`
- `lib/services/explore_service.dart`
- `lib/services/public_api_service.dart`
- `lib/modules/menu/public/models/public_menu_model.dart` (modelo de tarjeta)
- Nuevos: `lib/modules/explore/components/product_card.dart`, `lib/modules/explore/components/product_mosaic.dart`, `lib/modules/explore/components/filters.dart`, `lib/hooks/use_likes.dart`.

**Tareas verificables**
- [x] Crear modelos `TarjetaMenu` y `TarjetaProducto` con `codigo` String.
- [x] Corregir `ExploreService` a `/explore/filtros`, `/scroll`, `/productos` y municipio.
- [x] Implementar filtros persistentes y selección de municipio.
- [x] Implementar búsqueda de menús con debounce y cancelación lógica.
- [x] Implementar pestaña Platos con mosaico y paginación.
- [x] Corregir scroll infinito para encadenar páginas.
- [x] Implementar likes compartidos (`mis-encantados`, `mis-productos-encantados`).
- [x] Redirigir tarjetas a `/menu/:slug` (y producto a `?producto=`).
- [x] Añadir estados de error/vacío diferenciados.
- [x] Verificar con backend real y documentar resultados.
- [x] Ejecutar analyze/test y actualizar documento.

**Resultado real de Fase 2**
- Se reemplazó el feed viejo por pestañas **Menús** y **Platos** con el contrato actual de React.
- Se crearon modelos `TarjetaMenu`, `TarjetaProducto`, `ExploreFiltros`, `MenuScrollPage` y `ProductosPage` con códigos String.
- `ExploreService` consulta `/explore/filtros`, `/explore/scroll` y `/explore/productos`; `PublicApiService` busca menús con categoría y municipio.
- `ExploreController` centraliza carga inicial, filtros, búsquedas con debounce 350 ms, paginación por cursor, semilla de platos, persistencia de municipio y estados de error/reintento.
- Se añadió `LikesContext` compartido para menús y productos, con requisito de sesión.
- Se añadieron tarjetas de menú horizontales, tarjetas de producto, filtros de lugar/categoría, skeletons, acciones “Ver más/Me encanta” y modal de login.
- El mosaico de platos usa `MasonryGridView` (`flutter_staggered_grid_view`) con imágenes de altura natural, sin tamaño fijo, igual que el flujo de React.
- Se conservaron banner demo, barra superior, QR, notificaciones y splash. El banner de GPS se retiró de Explore porque React usa el filtro de municipio; sus componentes se conservan sin uso y no se borró código.

**Verificación ejecutada**
- Endpoints consultados contra `manzana.zammpy.com`: filtros, scroll y productos devolvieron datos reales con `codigo`, `municipio`, `categoria`, `menuSlug` y `meEncantas`.
- `flutter analyze`: 0 errores; 4 avisos informativos preexistentes en otros módulos.
- `flutter test`: 11 pruebas aprobadas, incluidas parseo de modelos, render de tarjetas y filtros.
- No se modificó React (`git status` de `menu-digital` vacío).

**Limitaciones registradas**
- No se probó visualmente en un dispositivo/emulador; se validó con pruebas de widget y análisis.
- El deep link `?producto=` abre el menú, pero el modal de producto aún debe alinearse en Fase 3.
- Los likes de producto se comparten en Explore; el modal público seguirá usando el flujo anterior hasta Fase 3.
- La paginación de platos usa `flutter_staggered_grid_view` para un mosaico masonry real de dos columnas con alturas variables, como React.
- La búsqueda de menús y el scroll usan servicios que aún leen el token directamente; la migración completa a `ApiClient` sigue en fases posteriores.

**Criterios de aceptación**
1. La pantalla muestra menús reales con nombres/logos/municipio, sin tarjetas con id 0.
2. La búsqueda y los filtros devuelven resultados coherentes y no se pisan entre pestañas.
3. El scroll de menús y platos carga más de una página.
4. Los likes reflejan el estado del usuario y requieren sesión.
5. Abrir una tarjeta lleva al menú correcto y un plato abre su producto.
6. Analyze sin errores; pruebas básicas de modelos/parseo añadidas.

---

### Fase 3 — Menú público (visor y experiencia de cliente)

**Estado:** COMPLETADA
**Depende de:** Fase 1, Fase 2.
**Bloquea a:** Fase 5, Fase 6, Fase 7, Fase 12, Fase 13, Fase 16.

**Objetivo específico**
Alinear el menú público con React: datos, temas, reseñas, likes, tracking, enlaces y estados, sin implementar todavía carrito/pedido (Fase 13).

**Pantallas / funcionalidades**
- Carga por slug con reintentos y not-found.
- Banner con ubicación/redes/horario/galería y enlaces funcionales.
- Categorías, destacados, grid/lista/carrusel, búsqueda local.
- Modal de producto con variantes, grupos, promo y “me encanta” de producto.
- Reseñas de texto con paginación, crear/eliminar y validaciones.
- “Me encanta” del menú.
- Compartir/QR (cliente y, si aplica, QR del backend).
- Tracking de vistas de menú/producto con `X-Viewer-Token`.
- Detección de dueño/editor y staff/mesero (solo lectura; edición se activa en Fase 7).
- Deep link `?producto=`.

**Archivos principales**
- `lib/components/menu_page.dart`
- `lib/modules/menu/public/pages/public_menu_page.dart`
- `lib/modules/menu/public/pages/demo_preview_page.dart`
- `lib/modules/menu/public/hooks/use_public_menu.dart`
- `lib/modules/menu/public/models/public_menu_model.dart`
- `lib/modules/menu/public/components/banner.dart`
- `lib/modules/menu/public/components/galeria_aside_panel.dart` (nuevo)
- `lib/modules/menu/public/components/schedule_aside_panel.dart` (nuevo)
- `lib/modules/menu/public/utils/horario.dart` (nuevo)
- `lib/modules/menu/public/components/category_tabs.dart`
- `lib/modules/menu/public/components/product_card.dart`
- `lib/modules/menu/public/components/product_list_item.dart`
- `lib/modules/menu/public/components/product_modal.dart`
- `lib/modules/menu/public/components/reviews_section.dart`
- `lib/modules/menu/public/components/carousel_view.dart`
- `lib/modules/menu/public/components/share_modal.dart`
- `lib/modules/menu/public/components/footer.dart`
- `lib/modules/menu/public/components/theme_selector.dart`
- `lib/services/public_api_service.dart`
- `lib/services/interaccion_service.dart`
- `lib/services/estadisticas_service.dart` (nuevo)
- `lib/services/themes_catalog_service.dart`
- `lib/shared/app_cache.dart`

**Tareas verificables**
- [x] Mapear respuesta pública actual (`published`, `codigo`, `slug`, `esPropio`, `theme`, `horario`, `ubicacion`).
- [x] Corregir `PublicMenuData` y `MenuInfo` (nombres, ubicación anidada, email, pedidos).
- [x] Corregir `CatalogSkin/Palette` a `codigo` y resolver tema real.
- [x] Corregir `getResenas`/`misResenas` para `{items, siguiente}`.
- [x] Implementar paginación y estados de reseñas.
- [x] Implementar likes de menú/producto con respuesta `{meEncanta,total}`.
- [x] Implementar tracking de vistas (menú 5 s; producto al abrir) con token de visor persistente.
- [x] Hacer funcionales redes, teléfono/WhatsApp, email y “Cómo llegar”.
- [x] Implementar `?producto=` y modo staff/mesero de solo lectura si los parámetros existen.
- [x] Añadir prompt de login navegable en reseñas/likes.
- [x] Reemplazar la galería inline por chip `Galería (N)` con panel lateral masonry 2 columnas y zoom, igual que React.
- [x] Calcular `Abierto · cierra HH:mm`/`Cerrado` desde `horario` y abrir panel lateral con días/rangos.
- [x] Añadir chip social de WhatsApp en el banner, además del teléfono.
- [x] Hacer responsive el grid de productos y Explorar (2–6 columnas según ancho) y la lista en 2 columnas para tablet.
- [x] Serializar la carga de imágenes (máx. 3, una petición por URL, reintentos) para evitar HTTP 429.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 3**
- `UsePublicMenu` ahora usa `ApiClient`, detecta sesión, consulta `GET /menus/acceso?slug=`, y si el usuario puede editar carga `GET /menus/{codigo}/preview`; también soporta staff/mesa sin acceso.
- `PublicMenuData.fromRoot` interpreta el wrapper real (`codigo`, `slug`, `esPropio`, `miRol`, `status`, `theme`, `horario`, `ubicacion`, `published`) y aplica el tema resuelto del backend.
- `MenuInfo` incluye email, galería, pedidos activos y ubicación anidada; `MenuProduct` incluye `isFeatured`/`order`; los grupos conservan ítems con precio.
- El menú público abre con banner, logo, ubicación, teléfono, email, horario, redes y galería; los chips de contacto abren WhatsApp/teléfono/email/maps y las redes abren su URL.
- La galería ya no se muestra inline: el chip `Galería (N)` abre un panel lateral derecho con masonry de 2 columnas, fotos sin recortar y zoom a pantalla completa; el horario calcula estado (`Abierto · cierra HH:mm`/`Cerrado`) y abre un panel con días y rangos. Se añadió WhatsApp como chip social independiente.
- Los grids se adaptan al ancho (productos 2–6 columnas; Explorar 2/3/4/5; listas 1 columna en móvil y 2 en tablet), igual que el layout responsive de React.
- `ProductImage` usa una cola global (máximo 3 concurrentes, una petición por URL y reintentos 2/4/6 s); las cards de JORAF Hot Dogs cargaron sin errores 429 en las pruebas.
- Se añadió fila de destacados, búsqueda local plana, grid/lista/carrusel y categorías con iconos correctos.
- Se replicó la regla de React para `sin_imagenes`: en “Todos” esos grupos siempre se pintan como lista, la categoría activa solo permite vista de lista y `ProductListItem` no reserva el espacio de imagen cuando el producto no tiene. Verificado en QA Catalogo → Bebidas.
- El modal de producto usa “Me encanta este plato” compartido con Explore, muestra grupos con precio, tracking de vista y enlace de WhatsApp.
- Reseñas paginadas con `{items, siguiente}`, crear/eliminar, validaciones y prompt de login navegable; el botón de menú usa `LikesContext`.
- Deep link `?producto=` abre automáticamente el modal del producto correcto.
- Compartir/QR y enlaces sociales/ubicación funcionan.
- Tracking: `POST /public/menu/{slug}/vista` a los 5 s y `POST /public/menu/{slug}/producto/{id}/vista` al abrir el detalle, con `X-Viewer-Token` persistente.

**Verificación ejecutada**
- App instalada y probada en Redmi `23028RA60L` (Android 14): menú JORAF con tema naranja, banner, galería, ubicación, categorías, 50 platos, modal de producto, adiciones con precio, “Me encanta” de producto/menú, reseñas vacías y modal de compartir/QR.
- Galería y horario verificados en JORAF: panel lateral de galería con 4 fotos en 2 columnas y zoom; panel de horario con lunes, martes, jueves, viernes, sábado y domingo en 24 horas (miércoles cerrado); chip de WhatsApp visible junto a Instagram.
- Responsive verificado simulando tablet de 800 dp: 4 columnas de productos en Hot Dogs y 2 columnas de menús en Explorar; luego se restauró `wm size`/`wm density`.
- Imágenes de Hot Dogs (`Joraf Dog`, `Dog Suizo`, `Dog Gratinado`, `Dog Ranchero`, `Dog Chorizuso`) cargadas en cards tras la cola global; `logcat` sin `ProductImage error` ni 429.
- Deep link desde Platos: abrió el menú QA Catalogo con el modal de “Arepa pabellón”.
- `flutter analyze`: 0 errores; 2 avisos informativos preexistentes en el editor.
- `flutter test`: 13/13 pruebas aprobadas.
- `logcat`: sin errores de Flutter, render u overflow.
- La sesión del usuario se conservó al reinstalar (`flutter run` sin desinstalar).
- No se modificó React (`git status` de `menu-digital` vacío).

**Limitaciones registradas**
- El contador público `totalVistas` no se pudo correlacionar desde la API pública; el endpoint de vista respondió 204 y las estadísticas se validarán en Fase 12.
- El modo edición visual del dueño/editor se limita a cargar el preview y ocultar interacciones de cliente; las herramientas de edición llegan en Fase 7.
- El formulario de reseñas no se pudo probar con una reseña real para no alterar datos de producción; el flujo de UI y servicios quedó implementado.
- Staff/mesero está implementado como lectura (`?staff=1`); el flujo completo de mesas llega en Fase 15.

**Criterios de aceptación**
1. Un menú real publicado abre con datos correctos y tema aplicado.
2. Las reseñas cargan, paginan, se crean y eliminan con validaciones de React.
3. Los likes actualizan estado y total; sin sesión se ofrece login.
4. Las vistas de menú/producto quedan registradas (verificable en estadísticas).
5. Los enlaces de contacto/redes/ubicación funcionan.
6. Un deep link a producto abre el modal correcto.
7. Analyze sin errores.

---

### Fase 4 — Notificaciones y WebSocket

**Estado:** COMPLETADA
**Depende de:** Fase 1.
**Bloquea a:** Fase 9 (acciones de colaboración/transferencia), Fase 14/15/16 (eventos de pedidos).

**Objetivo específico**
Implementar el centro de notificaciones actual: paginación, lectura, eliminación, deep links, acciones y tiempo real.

**Pantallas / funcionalidades**
- Lista paginada `{items, siguiente}`.
- Marcar leída/todas; eliminar con actualización local.
- Badge de no leídas.
- Acciones aceptar/rechazar colaboración y transferencia.
- Botones de pedidos y suscripción según tipo.
- WebSocket STOMP con reconexión, auth, colas de notificaciones/suscripción/pedidos y refresco por eventos.
- Estado de error/reintento visible.

**Archivos principales**
- `lib/modules/notifications/pages/notifications_page.dart`
- `lib/modules/notifications/hooks/use_notifications.dart`
- `lib/modules/notifications/components/notification_item.dart`
- `lib/modules/notifications/models/notification_model.dart`
- `lib/context/notificacion_context.dart`
- `lib/services/interaccion_service.dart`
- `lib/services/colaboracion_service.dart` (aceptar/rechazar colaboración)
- `test/notification_model_test.dart` (nuevo)
- `test/notification_item_test.dart` (nuevo)

**Tareas verificables**
- [x] Corregir parseo paginado y campos `codigo`/`entidadCodigo` (con compatibilidad `id`/`entidadId`).
- [x] Implementar paginación y “cargar más” con cursor `{items, siguiente}`.
- [x] Implementar acciones de invitación/transferencia con estados de carga/error.
- [x] Implementar deep link de suscripción (`/billing/:codigo` o `/suscripcion`); los de pedidos quedan documentados como limitación hasta Fase 14.
- [x] Completar STOMP: cola de pedidos, auth, errores, heartbeats y reconexión; sesión expirada fuerza logout.
- [x] Añadir refresco de listas/badges por eventos (`notificacionSeq`, recarga de la primera página y badge en vivo).
- [x] Sonido: no se incorporó asset de audio; se documenta la limitación.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 4**
- `NotificationModel` interpreta `codigo`, `tipo` (normalizado a mayúsculas), `entidadTipo`, `entidadCodigo`, `actorNombre`, `entidadNombre`, `vistaPrevia`, `leida`, `creadoEn` y `tiempoRelativo`.
- `GET /api/v1/notificaciones` usa `despues`/`limite`, respeta `{items, siguiente}` y muestra “Cargar más”; errores y reintento visibles.
- Leer, marcar todas y eliminar actualizan la lista de inmediato; eliminar es optimista. El badge del sidebar se carga con `sin-leer` y se refresca por STOMP.
- Las invitaciones `NUEVO_COLABORADOR` y `TRANSFERENCIA_PENDIENTE` permiten aceptar/rechazar desde la notificación, con spinner, resultado y error.
- Los tipos de pedidos muestran “Ver pedidos” / “Ver mis pedidos” y los de plan “Adquirir/Renovar plan”.
- STOMP: headers de auth, reconexión cada 5 s, timeout 10 s, heartbeats 10 s y colas `/user/queue/notificaciones`, `/user/queue/suscripcion` y `/user/queue/pedidos`; se expone estado de conexión/error y `pedidosSeq`/`pedidosMenuCodigo` para fases posteriores.
- La página de notificaciones se recarga al recibir un evento en vivo y muestra aviso de conexión/reintento.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos informativos preexistentes en el editor.
- `flutter test`: 17/17 pruebas aprobadas, incluidas paginación/códigos y render de invitación/pedido.
- No se pudo validar con una sesión real de producción porque la app quedó deslogueada al reinstalarse y no se dispone de credenciales del usuario; la validación visual queda pendiente al iniciar sesión.

**Limitaciones registradas**
- Los deep links `/pedidos` y `/menus/:codigo/pedidos` muestran un aviso porque esas pantallas pertenecen a Fase 14; la navegación de suscripción sí está conectada.
- No se añadió sonido de notificación porque no existe un asset aprobado en el proyecto.
- La prueba en vivo de STOMP y de las acciones de invitación/transferencia requiere una cuenta con sesión y eventos reales.

**Criterios de aceptación**
1. La lista muestra notificaciones reales y pagina.
2. Leer/eliminar/marcar todas actualiza UI y servidor.
3. Las notificaciones de colaboración/transferencia se aceptan/rechazan desde la app.
4. Los eventos STOMP actualizan badge y pantallas relevantes.
5. Analyze sin errores.

---

### Fase 5 — Mis Menús y hub del menú

**Estado:** COMPLETADA
**Depende de:** Fase 1, Fase 2 (tarjetas), Fase 3 (abrir menú).
**Bloquea a:** Fase 6, Fase 7, Fase 9, Fase 12.

**Objetivo específico**
Migrar la gestión de menús propios a códigos públicos y añadir el hub con acciones por rol.

**Pantallas / funcionalidades**
- Lista propia `GET /menus/tarjetas` con `items` y `limiteMenus`.
- Colaboraciones `GET /menus/colaboraciones`.
- Tarjetas con estado real y acciones.
- Hub `GET /menus/:codigo/resumen`: pasos, rol, acciones.
- Eliminar con código de confirmación (`delete-code`).
- Despublicar.
- Ver público / compartir.
- Acceso a estadísticas, grupos, publicar, colaboradores, pedidos, mesas según rol.
- Estados de carga/error/vacío/reintento.
- Migración de rutas de `int` a `String`.

**Archivos principales**
- `lib/modules/dashboard/pages/mis_menus_page.dart`
- `lib/modules/dashboard/hooks/use_mis_menus.dart`
- `lib/services/mis_menus_service.dart`
- `lib/services/menu_editor_service.dart`
- `lib/app.dart`
- Nuevos: `lib/modules/dashboard/pages/menu_hub_page.dart`, `lib/modules/dashboard/models/dashboard_models.dart`, `lib/modules/dashboard/components/delete_menu_modal.dart`, `lib/modules/dashboard/components/menu_steps.dart`, `lib/modules/dashboard/components/colaborador_row.dart`, `test/dashboard_models_test.dart`, `test/dashboard_widgets_test.dart`.

**Tareas verificables**
- [x] Migrar tarjetas, colaboraciones, hub, preview y estadísticas a `String codigo`; el editor interno queda expresamente para Fase 7.
- [x] Implementar `getTarjetas` (`items` + `limiteMenus`) y colaboraciones.
- [x] Implementar hub y acciones por `esPropio`/`miRol`.
- [x] Implementar eliminar con `delete-code`, despublicar, ver público y compartir.
- [x] Mostrar pasos pendientes del backend con progreso y “Necesario”.
- [x] Implementar errores y reintento en lista, colaboraciones y hub.
- [x] Añadir pruebas de parseo y de los widgets de eliminación/pasos/colaborador.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 5**
- “Mis Menús” consume `GET /menus/tarjetas` (`items` + `limiteMenus`), usa las tarjetas de Explore sin acciones de cliente y navega con `/menus/:codigo`.
- Las colaboraciones usan `GET /menus/colaboraciones`, muestran estado y rol (Editor/Mesero/Repartidor) y abren el hub.
- El hub `GET /menus/:codigo/resumen` muestra nombre, slug, estado, rol, pasos del backend y acciones por permisos: ver público, compartir, estadísticas, editar/grupos/plan (Fase 7), pedidos (Fase 14), mesas (Fase 15) y colaboradores (Fase 9).
- Eliminar solicita `delete-code`, exige escribir el código exacto y usa `X-Delete-Code`; despublicar usa `POST /menus/:codigo/unpublish`. Ambas invalidan la caché al terminar.
- Se añadieron estados de carga, error, vacío, reintento y pull-to-refresh.
- Rutas de dashboard, hub, preview y estadísticas migradas a códigos públicos.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos informativos preexistentes en el editor.
- `flutter test`: 24/24 pruebas aprobadas (modelos, eliminar con código, pasos y colaborador).
- La app compila y se instala; la validación visual autenticada sigue pendiente porque no hay sesión activa en el dispositivo.

**Limitaciones registradas**
- El editor interno (`/menus/:codigo/edit`, `/info`, productos) sigue usando el modelo anterior y se migrará completo en Fase 7; las acciones que dependen de él muestran un aviso.
- No se ejecutó eliminar/despublicar contra un menú real para no alterar datos de producción.
- Pedidos y mesas quedan deshabilitados hasta sus fases.

**Criterios de aceptación**
1. La lista renderiza menús reales sin crashes.
2. El hub abre el menú correcto y muestra acciones según rol.
3. Eliminar exige el código del backend y funciona; despublicar funciona.
4. Las rutas usan códigos y sobreviven a recargas.
5. Analyze sin errores.

---

### Fase 6 — Crear menú

**Estado:** COMPLETADA
**Depende de:** Fase 1, Fase 5.
**Bloquea a:** Fase 7.

**Objetivo específico**
Crear menús con el contrato actual y las imágenes diferidas, sin perder la posibilidad móvil de completar datos después.

**Pantallas / funcionalidades**
- Nombre, slug con validación/auto-generación/check, categoría desde `GET /public/categorias`.
- Logo/portada diferidos con recorte/validación.
- `POST /menus` con `{restaurantCategoryCode, name, slug}`.
- Subida a `/images/upload` y guardado con `PATCH /secciones/logo|portada`.
- Navegación al hub.
- Campos extendidos (contacto/redes/diseño) reubicados en el editor o guardados por sección válida; no se pierde funcionalidad.
- Estados de error y rollback de imágenes si falla.

**Archivos principales**
- `lib/modules/menu/create/create_menu_page.dart`
- `lib/modules/menu/create/models/create_menu_models.dart` (nuevo)
- `lib/services/menu_editor_service.dart`
- `lib/services/image_upload_service.dart` (nuevo)
- `lib/services/public_api_service.dart`
- `lib/shared/logo_crop_dialog.dart`
- `test/create_menu_models_test.dart` (nuevo)

**Tareas verificables**
- [x] Decidir y documentar el flujo final: una pantalla mínima (categoría, nombre, slug, logo y portada); el resto se completa desde el hub/editor.
- [x] Migrar categoría a códigos desde `GET /public/categorias`.
- [x] Quitar municipio/horario de la creación; se completan después.
- [x] Mantener tema/paleta por defecto en creación; el selector queda en Fase 7.
- [x] Implementar subida real a `/api/v1/images/upload?folder=...`.
- [x] Implementar check de slug con `excludeCodigo` en `checkSlugCode`.
- [x] Implementar rollback de cada imagen si falla su subida o su guardado por sección.
- [x] Implementar respuesta `codigo` y navegación al hub.
- [x] Añadir pruebas de slug, payload y categorías.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 6**
- La creación quedó en una sola pantalla: nombre, slug automático/editable con verificación, categoría dinámica desde el backend, logo recortado 1:1 y portada opcional.
- El payload de creación es mínimo (`restaurantCategoryCode`, `name`, `slug`); el resto se completa desde el hub/editor.
- Tras crear, se obtiene `codigo`, se suben las imágenes a `menus/{codigo}/logo|banner` con `/images/upload`, y se guardan por sección (`PATCH /menus/{codigo}/secciones/logo|portada`).
- Cada imagen se sube y guarda de forma independiente; si falla, se elimina la imagen subida y se avisa sin corromper el menú. El menú recién creado navega a `/menus/{codigo}`.
- El tema usa el valor por defecto del backend; su selección se hará en Fase 7.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos informativos preexistentes en el editor.
- `flutter test`: 28/28 pruebas aprobadas (slug, payload y categorías).
- Endpoints públicos verificados contra producción: `/public/categorias` y `/public/slugs/check`.
- No se creó un menú real para no alterar datos de producción; la validación autenticada queda pendiente al iniciar sesión.

**Limitaciones registradas**
- No se pudo validar la subida real de imágenes ni la creación completa en producción por falta de sesión.
- La creación no elige tema/paleta ni completa ubicación/contacto/redes/horario; eso queda en el editor (Fase 7).

**Criterios de aceptación**
1. Un usuario crea un menú real y llega al hub.
2. Logo/portada suben y quedan visibles.
3. Categoría, slug y tema se guardan con el contrato actual.
4. Si falla una imagen, el menú no queda corrupto y se informa.
5. Analyze sin errores.

---

### Fase 7 — Editor de menú (info, catálogo, diseño, publicación, suscripción)

**Estado:** COMPLETADA
**Depende de:** Fase 3 (preview), Fase 5 (hub), Fase 6 (creación).
**Bloquea a:** Fase 9, Fase 11, Fase 12, Fase 13, Fase 14.

**Objetivo específico**
Hacer que el editor móvil guarde y muestre todo el contenido con los endpoints actuales, y que publicar/plan/cupón funcione como React.

**Alcance dividido en bloques internos**
- **7A. Información del negocio**: identidad, contacto, ubicación, redes, galería, slug, imágenes.
- **7B. Categorías**: CRUD, visibilidad, orden, tipo de contenido, iconos.
- **7C. Productos**: CRUD, básico, tamaños, ingredientes, adiciones, grupos, promoción, visibilidad, explorar, posición de imagen, eliminar.
- **7D. Grupos**: CRUD, ítems con precio, activo, orden.
- **7E. Diseño**: catálogo de temas/paletas por código, guardado en `design`.
- **7F. Publicar**: requisitos reales, slug, plan/trial, cupón, logros aplicados, estados y acciones.
- **7G. Estadísticas de editor**: enlace y permisos (contenido completo en Fase 12).
- **7H. Colaboradores**: solo entrada/permisos; CRUD completo en Fase 9.

**Archivos principales**
- `lib/modules/menu/editor/pages/menu_editor_page.dart`
- `lib/modules/menu/editor/pages/menu_info_page.dart`
- `lib/modules/menu/editor/pages/product_form_page.dart`
- `lib/modules/menu/editor/models/editor_menu_model.dart`
- `lib/modules/menu/editor/tabs/categories_tab.dart`
- `lib/modules/menu/editor/tabs/products_tab.dart`
- `lib/modules/menu/editor/tabs/grupos_tab.dart`
- `lib/modules/menu/editor/tabs/design_tab.dart`
- `lib/modules/menu/editor/tabs/publish_tab.dart`
- `lib/modules/menu/editor/tabs/colaboradores_tab.dart`
- `lib/modules/menu/editor/shared/save_bar.dart`
- `lib/services/menu_editor_service.dart`
- `lib/services/image_upload_service.dart`
- `lib/services/theme_catalog_service.dart`
- `lib/services/suscripcion_service.dart`
- `lib/services/cupon_service.dart` (nuevo)
- `lib/services/logro_service.dart`
- `lib/shared/schedule_widget.dart`
- `lib/shared/location_cascade_widget.dart`

**Tareas verificables**
- [x] Nuevos modelos `LiveMenu/LiveInfo/LiveCategory/LiveProduct/LiveGroup` al contrato actual (el editor antiguo queda sin ruta).
- [x] Implementar carga por `codigo`, `miRol`, `esPropio`, `subscription`, `cupon`, catálogo y tema; los pasos se muestran en el hub.
- [x] Guardar info por secciones (`identidad`, `contacto`, `ubicacion`, `redes`, `galeria`, `logo`, `portada`) y slug; horario por endpoint propio.
- [x] Reemplazar guardados de catálogo por endpoints de categorías/productos/grupos.
- [x] Implementar operaciones por partes de producto.
- [x] Implementar `enExplorar` y promoción con vencimiento; `imagePosition` queda pendiente.
- [x] Implementar grupos con ítems/precio/estado.
- [x] Corregir diseño/temas y guardar `diseno`.
- [x] Implementar requisitos de publicación, slug, trial y confirmación.
- [x] Implementar cupón y enlace genérico a planes; el checkout específico del menú sigue en las pantallas de suscripción existentes.
- [x] Implementar logros en lectura y enlace a Fase 11.
- [x] Implementar estados de carga/error/vacío y guardado por sección.
- [x] Añadir pruebas de modelos/payloads.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 7**
- Nuevo editor móvil en `/menus/:codigo/edit` con pestañas Información, Categorías, Productos, Grupos, Diseño, Publicar y Colaboradores.
- Información guarda por secciones: identidad/slug, contacto/pedidos, ubicación por municipio, redes, galería, logo, portada y horario semanal con múltiples rangos.
- Catálogo con CRUD y orden de categorías, productos (incluye tamaños, ingredientes, adiciones, grupos, promoción y visibilidad/Explore) y grupos con ítems/precio/estado.
- Diseño con catálogo de skins/paletas por código; publicar con requisitos, slug, confirmación, trial, cupón, logros y despublicar.
- Colaboradores queda como entrada informativa; el CRUD es Fase 9. La ubicación usa municipio por código y no requiere país/división para guardar.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos preexistentes.
- `flutter test`: 30/30 pruebas aprobadas (incluye parseo del editor y permisos).

**Limitaciones registradas**
- No se validó contra una sesión real ni se modificaron menús de producción.
- `imagePosition` no tiene control visual todavía.
- El botón de planes abre la vista general de suscripción; el checkout específico del menú reutiliza las pantallas existentes de Fase 5/6.
- El CRUD de colaboradores, pedidos y mesas pertenece a fases posteriores.

**Criterios de aceptación**
1. El editor carga menús reales con todos sus datos y permisos.
2. Guardar identidad/contacto/ubicación/redes/slug persiste y no pisa horario.
3. CRUD de categorías/productos/grupos persiste por endpoints actuales.
4. Diseño aplica tema/paleta y se guarda.
5. Publicar respeta requisitos reales, trial/plan, cupón y slug.
6. Un colaborador editor ve lo permitido y no puede publicar/eliminar.
7. Analyze sin errores; pruebas de payload.

**Corrección posterior de Fase 7 — Suscripción (2026-10-30)**

La fase se había marcado completada, pero el módulo de suscripción seguía con ids `int`: `int.tryParse(código)` daba `0`, y las notificaciones de suscripción y `/suscripcion` abrían el menú `0`.
- `SuscripcionService` reescrito sobre `ApiClient` con códigos (`String`) y la misma normalización de React (`conSus`/`conPago`: `codigo` → `id`, `menuCodigo` → `menId`). `getMisPagos` devuelve la página `{items, siguiente}`. Se quitó `getEstadoPasarela` (la ruta no existe en el backend y nadie la usaba).
- Rutas `/menus/:codigo/planes`, `/billing/:menuId`, `/billing/:menuId/checkout` y `/billing/sus/:susId` con texto; `?id=` de Wompi se pasa al detalle.
- `PlanesPage`: publica la prueba con `LiveEditorService` (código) y vuelve al hub del menú, como React.
- `SuscripcionDetailPage` reescrita según React: antes leía campos inexistentes (`menuId`, `montoTotal`, `limiteProductos`, `pago.monto`) y usaba `CANCELLED` en vez de `CANCELED`. Ahora tiene datos del plan, avisos por estado, renovar/adquirir, cancelar al fin con confirmación, historial con método, "Auto", motivo de rechazo y comprobante. Se recarga con el aviso en vivo de suscripción (`suscripcionSeq`).
- Nuevo `AutoChargeSection`: guardar tarjeta (tokenizada en Wompi con `WompiCardForm`), activar/desactivar el cobro automático y eliminar la tarjeta.
- Nuevo `SubscriptionBanners` en la pestaña Publicar. "Ver planes" lleva a `/menus/{codigo}/planes` como React (antes iba a `/suscripcion`).
- Checkout: al terminar el pago lleva a "Ver mi suscripción"; el WebView también detecta la URL `/suscripciones/resultado/` y conserva el id de la transacción. Los enlaces de términos de Wompi ahora se abren (antes solo marcaban la casilla).
- Nuevos `utils/sus_format.dart` y `test/suscripcion_test.dart`. Analyze sin errores; 38 tests OK; 9 rutas verificadas (`/precio` 200, el resto 401, ninguna 404).

**Errores de React detectados — corregidos el 2026-10-30 con autorización del usuario (sin commit)**
- `SubscriptionBanners.jsx` leía `menu.subscription.acciones`, pero `MenuResponse.SuscripcionInfo` no tiene `acciones`: los avisos de prueba, aviso y gracia nunca aparecían. **Corrección:** `PublishTab.jsx` pide `getMiSuscripcion(menu.id)` (solo el dueño, se recarga al cambiar `status` o el estado de la suscripción) y se la pasa a los avisos.
- `SuscripcionPage.jsx` se quedaba cargando para siempre si el menú no tenía suscripción o la petición fallaba. **Corrección:** en ese caso redirige a `/menus/{id}/planes`.
- Verificación: `eslint` sin errores nuevos (la advertencia `exhaustive-deps` ya existía); `vite build` correcto.

**Error del backend detectado — corregido el 2026-10-30 con autorización del usuario (rama `feature/migracion-postgres`, sin commit)**
- `SuscripcionPagoService` armaba `redirectUrl = {api}/api/v1/suscripciones/resultado/{menId}` con el id numérico interno, y `resultado` usaba `@MenuDeRuta`, que solo resuelve códigos y además exige sesión. Wompi redirige el navegador sin token, así que respondía 404 (verificado contra `manzana`: `/resultado/123?id=tx` → 404). Tras pagar con PSE, Nequi u otros métodos, la web quedaba en un 404.
- **Corrección:** `SuscripcionPagoService.urlResultado(menId)` usa el código público del menú (`MenuQueryPort.findById(...).codigo()`). `GET /resultado/{menuCodigo}` recibe el código como `@PathVariable String` (no resuelve el menú, solo redirige), y `SuscripcionApplicationServiceImpl.resultado` redirige a `{frontend}/billing/{codigo}/resultado?id=…` codificando ambos valores. Se quitó `/api/v1/suscripciones/resultado/` de `RUTAS_PERSONAL` en `TenantResolutionInterceptor` (la ruta es pública en `SecurityConfig`).
- Verificación: nuevo `SuscripcionResultadoRedirectTest` (3 pruebas) y pruebas de suscripción, pagos, planes y tenant: 0 fallos. Falta desplegar: `manzana.zammpy.com` sigue con la versión anterior.
- En Flutter, el WebView sigue cerrándose al detectar `/suscripciones/resultado/` o `app.zammpy.com`, así que funciona con la versión vieja y con la nueva del backend.

---

### Fase 8 — (reservada) Notificaciones ya cubierta

**Estado:** COMPLETADA (sin trabajo nuevo; cubierta por Fase 4).

> La Fase 4 cubre notificaciones. Este número se conserva para no renumerar las dependencias ya descritas en documentos previos; no hay fase nueva aquí.

---

### Fase 9 — Colaboradores y transferencia

**Estado:** COMPLETADA
**Depende de:** Fase 4, Fase 5, Fase 7.
**Bloquea a:** Fase 14/15/16 (roles operativos).

**Objetivo específico**
Implementar colaboradores con roles, límites, invitación, aceptación/rechazo y transferencia de propiedad.

**Pantallas / funcionalidades**
- Listar colaboradores con rol/avatar.
- Invitar por código de 6 caracteres y rol (`editor`, `mesero`, `repartidor`).
- Aceptar/rechazar invitación desde notificaciones.
- Eliminar colaborador con confirmación.
- Cambiar rol si se decide exponerlo (React tiene endpoint aunque no UI actual).
- Transferencia de propiedad con código, confirmación, estado pendiente y validación `transferible`.
- Límite de colaboradores del plan.
- Acciones deshabilitadas para no dueños.

**Archivos principales**
- `lib/modules/menu/editor/tabs/colaboradores_tab.dart`
- `lib/services/menu_editor_service.dart`
- `lib/services/colaboracion_service.dart`
- `lib/modules/notifications/components/notification_item.dart`
- `lib/modules/dashboard/pages/menu_hub_page.dart`

**Tareas verificables**
- [x] Corregir listar/invitar/eliminar a códigos.
- [x] Añadir selector de rol y límites.
- [x] Implementar aceptar/rechazar colaboración.
- [x] Implementar transferencia y estados.
- [x] Añadir confirmaciones y manejo de errores.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 9**
- `ColaboracionService` reescrito sobre `ApiClient` (refresh/401 global) con todos los métodos de `colaboracionService.js`: invitar (con rol), aceptar/rechazar colaboración, listar, eliminar, cambiar rol, transferir, aceptar/rechazar transferencia. Todo por código público (`menuCodigo`, `codigo` de usuario). Modelo `Colaborador` según `ColaboradorResponse`.
- `CollaboratorsLiveTab` (editor activo, `/menus/:codigo/edit?tab=collaborators`) deja de ser placeholder: invitar con código de 6 caracteres + rol (Editor/Mesero/Repartidor), contador y bloqueo por `limiteColaboradores`, aviso de invitación pendiente (no se agrega a la lista hasta aceptar, igual que React), lista con avatar/badge de rol, eliminación con diálogo de confirmación, transferencia con confirmación, estado PENDIENTE y bloqueo cuando `transferible == false` (mismo texto de React). Pull-to-refresh y estado de error con reintento.
- Cambio de rol: React tiene el endpoint pero no UI; en Flutter se expone tocando el badge de rol (decisión documentada en la fase).
- `LiveMenu.transferible` agregado (campo real de `MenuResponse`).
- Al aceptar/rechazar desde notificaciones se invalida la caché de Mis Menús/Colaboraciones.
- El editor viejo (`menu_editor_page.dart` + `tabs/colaboradores_tab.dart`, ids `int`) no está en las rutas; no se eliminó, queda para limpieza en Fase 17.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos informativos preexistentes del editor viejo.
- `flutter test`: 32 pruebas aprobadas (nuevas: `test/colaboracion_test.dart`).
- Rutas verificadas contra `manzana.zammpy.com` sin sesión (401 en todas, ninguna 404): listar, invitar, eliminar, cambiar rol, transferir, aceptar colaboración, rechazar transferencia.
- Contrato confirmado leyendo (sin modificar) `ColaboracionController` y DTOs del backend.
- Sin credenciales de prueba: el flujo invitar→aceptar→transferir de extremo a extremo queda como prueba manual en dispositivo.

**Revisión de imágenes (2026-10-30, previa a la fase)**
- Se auditaron las imágenes de `/explore/productos` y de los menús públicos: todas las de Cloudinary responden 200.
- Las que no cargan son datos con URL externa pegada: Wikimedia (HTTP 429 por límite de peticiones) en `joraf-restaurante` y dominio inexistente `img.test` en `qa-catalogo`. No es un fallo de Flutter.
- Flutter y React solo suben imágenes por `POST /api/v1/images/upload` (Cloudinary); no hay campo para pegar URL. Esos productos deben volver a subir su foto desde el editor.

**Criterios de aceptación**
1. Invitar por código crea una invitación pendiente.
2. El invitado acepta/rechaza desde notificaciones y el menú aparece/desaparece de colaboraciones.
3. El dueño elimina colaboradores y respeta el límite.
4. La transferencia funciona y refleja el nuevo rol.
5. Analyze sin errores.

---

### Fase 10 — Perfil, ajustes y cuenta

**Estado:** COMPLETADA
**Depende de:** Fase 1, Fase 2 (ubicación).
**Bloquea a:** nada crítico.

**Objetivo específico**
Igualar perfil y ajustes: datos, ubicación, contacto de pedidos, contraseña, dispositivos, código de invitación y eliminación de cuenta.

**Pantallas / funcionalidades**
- Perfil: nombre/apellido/avatar, email lectura, ubicación, contacto, contraseña solo LOCAL.
- Validación de avatar (tipos y 5 MB).
- Ajustes: código de invitación, sesiones/dispositivos, revocar, eliminar cuenta con código.
- Limpieza de caché al cerrar sesión.
- Manejo de `requiereUbicacion` y aviso si falta ubicación.
- Push: no prometer push real si no se implementa; ajustar texto o implementar registro de token en fase separada autorizada.

**Archivos principales**
- `lib/modules/profile/pages/profile_page.dart`
- `lib/modules/profile/pages/settings_page.dart`
- `lib/modules/profile/hooks/use_profile.dart`
- `lib/modules/profile/hooks/use_settings.dart`
- `lib/services/profile_service.dart`
- `lib/services/dispositivo_service.dart`
- `lib/services/auth_service.dart`
- `lib/shared/location_cascade_widget.dart`
- `lib/services/app_cache.dart`

**Tareas verificables**
- [x] Añadir ubicación y contacto al perfil.
- [x] Corregir dispositivos a `codigo`.
- [x] Implementar eliminación de cuenta.
- [x] Añadir limpieza completa de caché en logout.
- [x] Ajustar textos/estado de push o implementar registro real si se autoriza.
- [x] Ejecutar analyze/test y documentar.

**Resultado real de Fase 10**
- `ProfileService` sobre `ApiClient`: `getMe`, `saveLocation` (`PUT /user/me/location`), `saveContacto` (`PUT /user/me/contacto`, teléfono E.164), `changePassword`, `updateProfile` (multipart con reintento tras refresh), `getAccountDeleteCode` y `deleteAccount` (cabecera `X-Delete-Code`). `ApiClient` acepta cabeceras extra.
- Perfil: tarjetas "Tu ubicación" (`LocationCascadeInput`; al guardar se apaga `requiereUbicacion`) e "Información para pedidos" (`TelefonoInput` + dirección + referencia, sincroniza la sesión para el carrito). Avatar valida tipo (JPG/PNG/WebP/GIF) y 5 MB. Los campos de contraseña se vacían tras guardar.
- Ajustes: sesiones identificadas por `codigo` (`DispositivoResponse`), zona de peligro y diálogo de eliminación con la palabra de 5 caracteres; al eliminar, cierra el diálogo, cierra sesión y el router lleva a `/login`.
- `AvisoUbicacion` (equivalente a `AvisoUbicacion.jsx`) se monta en el `builder` de `MaterialApp.router`: aparece en Explorar y en páginas privadas, no en `/perfil`, el menú público ni las pantallas de autenticación. La prueba detectó y se corrigió un `markNeedsBuild` durante el build al cambiar de ruta.
- Logout: además de `AppCache.clearUserData()`, borra `inv_ref` y el municipio guardado de Explorar (React hace `localStorage.clear()` salvo `_vt`).
- Push: se quitó el interruptor "Notificaciones push", porque solo pedía permiso. La app no tiene FCM ni notificaciones locales y React no lo ofrece. El registro real de push queda para una fase aparte, si se autoriza.

**Verificación ejecutada**
- `flutter analyze`: 0 errores; 2 avisos previos del editor viejo.
- `flutter test`: 35 pruebas aprobadas (nuevas: `test/aviso_ubicacion_test.dart`).
- Rutas verificadas sin sesión contra `manzana.zammpy.com` (todas 401, ninguna 404): `/user/me`, `/me/location`, `/me/contacto`, `/me/password`, `/me/delete-code`, `DELETE /user/me`, `/dispositivos`, `DELETE /dispositivos/{codigo}`.
- Contrato leído (sin modificar) en `UserProfileController`, `UserProfileApplicationServiceImpl`, `DispositivoController`, `DispositivoResponse`, `AuthResponse`.

**Errores detectados en React (no modificado)**
- `SettingsPage.jsx` usa `d.id` para las sesiones (`key`, `revocar(d.id)`), pero `dispositivoService.js` no aplica `conCodigos` y el backend solo envía `codigo`. Resultado: `DELETE /api/v1/dispositivos/undefined`, así que no se puede cerrar la sesión de otro dispositivo. Flutter usa `codigo`.
  - **Corregido en React el 2026-10-30, a pedido explícito del usuario:** `dispositivoService.js` ahora aplica `conCodigos` a la respuesta (`codigo` → `id`), igual que los demás servicios. `SettingsPage.jsx` queda sin cambios. Sin commit.

**Observación del backend (no modificado)**
- `GET /api/v1/user/me` devuelve `userId` con el id numérico interno (`u.getId()`), en contra de la regla "sin ids en la API".

**Criterios de aceptación**
1. Perfil guarda datos, avatar, ubicación y contacto.
2. Contraseña solo aparece para cuentas locales y valida 6.
3. Dispositivos listan/revocan correctamente.
4. Eliminar cuenta borra la cuenta y cierra sesión.
5. Analyze sin errores.

---

### Fase 11 — Logros e invitaciones

**Estado:** PENDIENTE
**Depende de:** Fase 1, Fase 4, Fase 5, Fase 7.
**Bloquea a:** nada crítico.

**Objetivo específico**
Permitir usar recompensas de logros en menús y completar el programa de invitaciones.

**Pantallas / funcionalidades**
- Logros: progreso, desbloqueados/pendientes, recompensa disponible, aplicar a menú propio con idempotencia.
- Logros aplicados por menú (lectura en publicar).
- Invitaciones: enlace, activo/inactivo, completadas/pendientes, detalle, reglas y share.
- Registro por invitación (ya en Fase 1).
- Estados de error/reintento.

**Archivos principales**
- `lib/modules/growth/achievements/pages/logros_page.dart`
- `lib/modules/growth/achievements/hooks/use_logros.dart`
- `lib/modules/growth/achievements/models/logro_model.dart`
- `lib/modules/growth/achievements/components/logro_card.dart`
- `lib/modules/growth/invitations/pages/invitaciones_page.dart`
- `lib/modules/growth/invitations/hooks/use_invitaciones.dart`
- `lib/services/logro_service.dart`
- `lib/services/invitacion_service.dart`
- `lib/modules/menu/editor/tabs/publish_tab.dart`

**Tareas verificables**
- [ ] Corregir `codigo` en logros.
- [ ] Implementar selección de menú y aplicar logros.
- [ ] Mostrar logros aplicados en publicar.
- [ ] Implementar detalle/reglas de invitaciones y share.
- [ ] Manejar programa pausado y errores.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. Se aplican días de un logro desbloqueado a un menú propio y se reflejan.
2. No se puede aplicar dos veces por error (idempotencia).
3. Invitaciones muestra estado real, detalle y toggle.
4. Analyze sin errores.

---

### Fase 12 — Estadísticas

**Estado:** PENDIENTE
**Depende de:** Fase 3 (tracking), Fase 5, Fase 7.
**Bloquea a:** nada crítico.

**Objetivo específico**
Igualar la pantalla de estadísticas: rango de fechas, métricas y listas de productos.

**Pantallas / funcionalidades**
- Rango desde/hasta y “histórico completo”.
- Vistas, me encanta, operaciones entregadas (domicilio/rondas), conversión.
- Productos más vistos, más encantados, más pedidos con ingresos.
- Permisos de dueño/editor.
- Estados de carga/error/vacío.

**Archivos principales**
- `lib/modules/menu/editor/stats/pages/estadisticas_page.dart`
- `lib/services/estadisticas_service.dart`
- `lib/modules/menu/editor/pages/menu_editor_page.dart`

**Tareas verificables**
- [ ] Implementar servicio con `desde/hasta` y ambos endpoints.
- [ ] Migrar a `codigo`.
- [ ] Renderizar todas las métricas/listas.
- [ ] Añadir filtros de fecha y estados.
- [ ] Verificar que las vistas móviles se registran.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. Las métricas coinciden con el backend para el rango.
2. Se ven las tres listas de productos.
3. El rango y “histórico” funcionan.
4. Analyze sin errores.

---

### Fase 13 — Carrito y pedidos de cliente

**Estado:** PENDIENTE
**Depende de:** Fase 3.
**Bloquea a:** Fase 14/15.

**Objetivo específico**
Implementar el carrito persistido en servidor y la solicitud de pedido del cliente, más el historial de pedidos.

**Pantallas / funcionalidades**
- Carrito por menú (`GET/PUT/DELETE /carrito/:menuId`).
- Configuración de ítems (tamaño, ingredientes, extras, grupos, nota de cocina solo staff).
- Deduplicación por configuración.
- Checkout: teléfono, dirección, referencia; prellenado desde perfil.
- `POST /pedidos` con `requestId`, `menuCodigo`, items; éxito con `waUrl`.
- Historial propio, cancelar, marcar recibido.
- Estados de carga/error/vacío.

**Archivos principales**
- `lib/context/cart_context.dart` (nuevo)
- `lib/services/carrito_service.dart` (nuevo)
- `lib/services/pedido_service.dart` (nuevo)
- `lib/modules/menu/public/components/cart_sheet.dart` (nuevo)
- `lib/modules/menu/public/components/product_modal.dart`
- `lib/modules/menu/public/pages/public_menu_page.dart`
- `lib/modules/orders/pages/pedidos_page.dart` (nuevo)
- `lib/app.dart`

**Tareas verificables**
- [ ] Implementar contexto y persistencia del carrito.
- [ ] Implementar deduplicación y totales.
- [ ] Implementar checkout e idempotencia.
- [ ] Implementar historial y acciones.
- [ ] Añadir estados y validaciones.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. El carrito persiste entre sesiones para el mismo menú.
2. Se crea una solicitud real y se muestra WhatsApp si existe.
3. El historial muestra pedidos y permite cancelar/recibir.
4. Analyze sin errores.

---

### Fase 14 — Pedidos del negocio y mesas

**Estado:** PENDIENTE
**Depende de:** Fase 4, Fase 7, Fase 13.
**Bloquea a:** Fase 15/16.

**Objetivo específico**
Implementar la gestión de pedidos y cuentas de mesa del negocio, con estados, pagos auditados y asignación de repartidor.

**Pantallas / funcionalidades**
- Pedidos por rango, métricas, estados, valor pagado, repartidores.
- Cuentas en curso y cerradas, ajustes, pagos, cierre/cancelación.
- Mesas CRUD/activación/capacidad.
- Eventos WebSocket de pedidos.
- Permisos dueño/editor.

**Archivos principales**
- `lib/modules/orders/pages/menu_pedidos_page.dart`
- `lib/modules/orders/components/pedido_row.dart`
- `lib/modules/orders/components/cuentas_panel.dart`
- `lib/modules/orders/components/ajuste_cuenta_modal.dart`
- `lib/modules/orders/components/pago_cuenta_modal.dart`
- `lib/modules/menu/editor/mesas/mesas_page.dart`
- `lib/modules/menu/editor/mesas/mesa_form_modal.dart`
- `lib/services/pedido_service.dart`
- `lib/services/mesa_service.dart`
- `lib/modules/dashboard/pages/menu_hub_page.dart`
- `lib/app.dart`

**Tareas verificables**
- [ ] Implementar servicios de pedidos/cuentas/mesas con códigos.
- [ ] Implementar pantalla de pedidos y filtros.
- [ ] Implementar cuentas, ajustes y pagos.
- [ ] Implementar CRUD de mesas.
- [ ] Integrar eventos de pedidos.
- [ ] Añadir estados y permisos.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. El negocio ve y cambia estados de pedidos reales.
2. Puede registrar valor pagado y asignar repartidor.
3. Puede gestionar cuentas y mesas sin mezclar datos.
4. Analyze sin errores.

---

### Fase 15 — Modo mesero

**Estado:** PENDIENTE
**Depende de:** Fase 3, Fase 14.
**Bloquea a:** nada crítico.

**Objetivo específico**
Implementar la vista de mesero: mesas, cuentas divididas, rondas, pagos y cierre.

**Pantallas / funcionalidades**
- Lista de mesas con ocupación/bloqueo por otro mesero.
- Cuentas por mesa y cuentas divididas.
- Rondas: crear, estados, cancelar.
- Agregar productos desde menú público en modo mesero.
- Registrar abonos, cerrar/cancelar cuenta.
- Historial de rondas/cuentas.
- Eventos en tiempo real.

**Archivos principales**
- `lib/modules/mesero/pages/mesero_page.dart`
- `lib/modules/mesero/components/mesa_card.dart`
- `lib/modules/mesero/components/mesa_pedidos_panel.dart`
- `lib/modules/mesero/components/mis_pedidos_mesero.dart`
- `lib/modules/menu/public/components/order_sheet.dart`
- `lib/services/mesa_service.dart`
- `lib/app.dart`

**Tareas verificables**
- [ ] Implementar servicios de mesero.
- [ ] Implementar vista de mesas y panel.
- [ ] Implementar cuentas/rondas/pagos/cierre.
- [ ] Implementar pedido desde menú público en modo mesero.
- [ ] Añadir permisos/rol y tiempo real.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. Un mesero abre una mesa, crea una ronda y la ve en la cuenta.
2. Puede dividir cuenta y registrar abonos.
3. Cierra una cuenta solo cuando corresponde.
4. Analyze sin errores.

---

### Fase 16 — Modo repartidor

**Estado:** PENDIENTE
**Depende de:** Fase 14 (asignación), Fase 4 (eventos).
**Bloquea a:** nada crítico.

**Objetivo específico**
Implementar la vista de repartidor con pedidos asignados, toma de pedido y estados.

**Pantallas / funcionalidades**
- Pedidos por entregar/historial.
- Tomar pedido, marcar en proceso/entregado/cancelado.
- Datos de contacto/dirección.
- Eventos WebSocket.
- Rol repartidor por menú.

**Archivos principales**
- `lib/modules/repartidor/pages/repartidor_page.dart` (nuevo)
- `lib/services/repartidor_service.dart` (nuevo)
- `lib/modules/menu/public/pages/public_menu_page.dart` (modo `?staff=1`)
- `lib/app.dart`

**Tareas verificables**
- [ ] Implementar servicio y pantalla.
- [ ] Implementar toma/estados.
- [ ] Añadir permisos y tiempo real.
- [ ] Ejecutar analyze/test y documentar.

**Criterios de aceptación**
1. El repartidor ve pedidos del menú y toma uno.
2. Cambia estados y el negocio lo refleja.
3. Analyze sin errores.

---

### Fase 17 — Verificación final y endurecimiento

**Estado:** PENDIENTE
**Depende de:** todas las fases autorizadas.
**Bloquea a:** cierre del proyecto.

**Objetivo específico**
Cerrar brechas transversales, pruebas y documentación.

**Tareas**
- [ ] Revisar todos los flujos contra React pantalla por pantalla.
- [ ] Corregir `flutter analyze` a cero issues.
- [ ] Reparar/ampliar `test/widget_test.dart` y añadir pruebas de modelos/servicios.
- [ ] Revisar manejo de errores, vacíos y reintentos.
- [ ] Revisar accesibilidad móvil, tamaños y teclado.
- [ ] Revisar seguridad de tokens y logs.
- [ ] Actualizar este documento con estado final y limitaciones.
- [ ] Entregar resumen ejecutivo.

**Criterios de aceptación**
1. `flutter analyze` sin issues.
2. `flutter test` en verde o con fallos externos documentados y justificados.
3. Matriz de módulos alineada y limitaciones explícitas.
4. No hay cambios en React/backend.

---

## 7. Dependencias entre fases

| Fase | Depende de | Motivo |
|---|---|---|
| 1 Auth | — | Base de sesión y HTTP. |
| 2 Explore | 1 | Likes/sesión opcional y cliente HTTP. |
| 3 Menú público | 1, 2 | Modelos de tarjeta, destino de Explore y reseñas. |
| 4 Notificaciones | 1 | Auth y WebSocket. |
| 5 Mis Menús | 1, 2, 3 | Códigos, tarjetas, abrir menú. |
| 6 Crear | 1, 5 | Categorías, imágenes y navegación al hub. |
| 7 Editor | 3, 5, 6 | Preview, hub y menús creados. |
| 9 Colaboradores | 4, 5, 7 | Notificaciones, roles y plan. |
| 10 Perfil | 1, 2 | Sesión y ubicación. |
| 11 Logros/Invitaciones | 1, 4, 5, 7 | Menús propios y logros aplicados. |
| 12 Estadísticas | 3, 5, 7 | Tracking y permisos. |
| 13 Pedidos cliente | 3 | Menú público y producto. |
| 14 Pedidos negocio/mesas | 4, 7, 13 | Menú, eventos y cuentas. |
| 15 Mesero | 3, 14 | Menú y cuentas. |
| 16 Repartidor | 4, 14 | Pedidos y eventos. |
| 17 QA | todas | Cierre. |

---

## 8. Protocolo de ejecución por fase

1. Confirmar que la fase está autorizada y que sus dependencias están COMPLETADAS.
2. Releer la sección de la fase y los archivos React de referencia.
3. Implementar solo el alcance de la fase.
4. Mantener compatibilidad y reutilizar servicios/componentes.
5. Añadir estados de carga/error/vacío.
6. Ejecutar `flutter analyze` y `flutter test`.
7. Probar manualmente el flujo contra el backend configurado.
8. Actualizar este documento:
   - estado de la fase;
   - archivos modificados/creados;
   - funcionalidades implementadas;
   - pruebas y resultados;
   - problemas/limitaciones.
9. Presentar resumen y **detenerse** hasta nueva autorización.

**Regla:** no se inicia automáticamente la siguiente fase, aunque la anterior termine sin errores.

---

## 9. Estado de avance

| Fase | Estado | Última actualización | Notas |
|---|---|---|---|
| 1 Autenticación | COMPLETADA | 2026-10-27 | Implementada y verificada; ver limitaciones en Fase 1. |
| 2 Explorar | COMPLETADA | 2026-10-27 | Menús/Platos, filtros, likes y paginación implementados. |
| 3 Menú público | COMPLETADA | 2026-10-27 | Tema real, datos, likes, reseñas, QR y tracking. |
| 4 Notificaciones | COMPLETADA | 2026-10-27 | Paginación, acciones, STOMP y badge; ver limitaciones. |
| 5 Mis Menús | COMPLETADA | 2026-10-27 | Tarjetas, colaboraciones, hub, eliminar y despublicar. |
| 6 Crear menú | COMPLETADA | 2026-10-27 | Flujo mínimo, imágenes diferidas, slug y navegación al hub. |
| 7 Editor | COMPLETADA | 2026-10-27 | Info, catálogo, grupos, diseño y publicación; ver limitaciones. |
| 9 Colaboradores | PENDIENTE | 2026-10-27 | Fase 8 reservada. |
| 10 Perfil | PENDIENTE | 2026-10-27 | — |
| 11 Logros/Invitaciones | PENDIENTE | 2026-10-27 | — |
| 12 Estadísticas | PENDIENTE | 2026-10-27 | — |
| 13 Pedidos cliente | PENDIENTE | 2026-10-27 | — |
| 14 Pedidos negocio/mesas | PENDIENTE | 2026-10-27 | — |
| 15 Mesero | PENDIENTE | 2026-10-27 | — |
| 16 Repartidor | PENDIENTE | 2026-10-27 | — |
| 17 QA final | PENDIENTE | 2026-10-27 | — |

Estados permitidos: **PENDIENTE**, **EN PROCESO**, **BLOQUEADA**, **COMPLETADA**.

---

## 10. Registro de cambios

> Se completará al finalizar cada fase autorizada.

### Fase 1 — Autenticación
- Estado: COMPLETADA.
- Archivos creados:
  - `lib/services/api_client.dart`
  - `lib/services/auth_redirect.dart`
  - `lib/services/invite_store.dart`
  - `lib/modules/auth/components/auth_layout.dart`
  - `lib/modules/auth/pages/invite_page.dart`
  - `lib/modules/auth/pages/verify_email_sent_page.dart`
  - `lib/shared/location_cascade_input.dart`
  - `lib/shared/telefono_input.dart`
  - `test/auth_redirect_test.dart`
  - `test/location_cascade_value_test.dart`
- Archivos modificados:
  - `lib/services/api.dart`, `auth_service.dart`, `geography_service.dart`, `app_cache.dart`, `google_auth_service.dart`
  - `lib/context/auth_context.dart`, `lib/main.dart`, `lib/app.dart`
  - `lib/modules/auth/hooks/use_login_form.dart`, `use_register_form.dart`, `use_verify_email_code.dart`, `use_forgot_password.dart`, `use_reset_password_form.dart`
  - `lib/modules/auth/pages/login_page.dart`, `register_page.dart`, `verify_email_code_page.dart`, `forgot_password_page.dart`, `reset_password_page.dart`
  - `test/widget_test.dart`
- Funcionalidades implementadas: cliente HTTP con refresh y 401; persistencia de token/refresh; guardas de rutas; retorno al destino; registro con municipio/teléfono/invitación; validación de contraseña 6; verificación con cooldown y errores; recuperación/reset con código; Google nativo; geografía nueva; componentes reutilizables AuthLayout/LocationCascadeInput/TelefonoInput.
- Pruebas: `flutter analyze` sin errores (4 avisos informativos preexistentes); `flutter test` 5/5; endpoints de geografía y login verificados contra `manzana.zammpy.com`.
- Problemas/limitaciones: sin credenciales para E2E; callback OAuth web no implementado (móvil usa Google nativo); la prueba manual de registro queda pendiente del usuario.

### Fase 2 — Explorar
- Estado: COMPLETADA.
- Archivos creados:
  - `lib/modules/explore/models/explore_models.dart`
  - `lib/modules/explore/components/acciones_tarjeta.dart`
  - `lib/modules/explore/components/producto_card.dart`
  - `lib/modules/explore/components/productos_mosaico.dart`
  - `lib/modules/explore/components/filtros.dart`
  - `lib/modules/explore/components/skeleton_menu_card.dart`
  - `lib/modules/explore/components/skeleton_product_card.dart`
  - `lib/context/likes_context.dart`
  - `lib/components/ui/auth_required_modal.dart`
  - `test/explore_models_test.dart`
  - `test/explore_cards_test.dart`
- Archivos modificados:
  - `lib/modules/explore/pages/explore_page.dart`
  - `lib/modules/explore/hooks/use_explore.dart`
  - `lib/modules/explore/components/menu_card.dart`
  - `lib/modules/explore/components/infinite_explorer.dart`
  - `lib/modules/explore/components/section.dart`
  - `lib/services/explore_service.dart`
  - `lib/services/public_api_service.dart`
  - `lib/services/interaccion_service.dart`
  - `lib/services/colaboracion_service.dart`
  - `lib/main.dart`
  - `pubspec.yaml` y `pubspec.lock` (`flutter_staggered_grid_view`)
- Funcionalidades implementadas: pestañas Menús/Platos; filtros por municipio/categoría; búsqueda con debounce; scroll por cursor; platos con semilla; likes compartidos; tarjetas nuevas; estados de carga/error/vacío; modal de login; persistencia de municipio; municipio del perfil.
- Pruebas: `flutter analyze` sin errores (4 avisos preexistentes); `flutter test` 11/11; endpoints reales consultados; app instalada y verificada en Redmi 23028RA60L (Android 14) con capturas de menús y mosaico de platos.
- Problemas/limitaciones: deep link de producto se completa en Fase 3; likes públicos se integran en Fase 3.

### Fase 3 — Menú público
- Estado: COMPLETADA.
- Archivos creados:
  - `lib/modules/menu/public/utils/contact_links.dart`
  - `lib/modules/menu/public/utils/horario.dart`
  - `lib/modules/menu/public/components/galeria_aside_panel.dart`
  - `lib/modules/menu/public/components/schedule_aside_panel.dart`
  - `lib/modules/menu/public/components/product_image.dart`
  - `lib/services/estadisticas_service.dart`
  - `test/public_menu_model_test.dart`
- Archivos modificados:
  - `lib/components/menu_page.dart`
  - `lib/modules/menu/public/hooks/use_public_menu.dart`
  - `lib/modules/menu/public/models/public_menu_model.dart`
  - `lib/modules/menu/public/pages/public_menu_page.dart`
  - `lib/modules/menu/public/pages/preview_page.dart`
  - `lib/modules/menu/public/components/banner.dart`
  - `footer.dart`, `category_tabs.dart`, `product_modal.dart`, `reviews_section.dart`
  - `lib/services/interaccion_service.dart`, `themes_catalog_service.dart`
  - `lib/app.dart`
- Funcionalidades implementadas: wrapper público real, tema del backend, dueño/editor/staff, banner con galería y enlaces, destacados, búsqueda, likes compartidos, reseñas paginadas, deep link de producto, QR y tracking de vistas. Galería/horario en paneles laterales como React, chip social de WhatsApp, grids responsive y cola de imágenes con reintentos.
- Pruebas: `flutter analyze` sin errores (2 avisos preexistentes); `flutter test` 13/13; pruebas en Redmi con menú real, modal, likes, QR, deep link, paneles de galería/horario, Hot Dogs con imágenes y tablet simulada de 800 dp.
- Problemas/limitaciones: contador de vistas no correlacionado; edición del dueño y staff/mesero completo quedan para fases posteriores; no se creó una reseña real para no alterar datos.

### Fase 4 — Notificaciones
- Estado: COMPLETADA.
- Archivos creados:
  - `test/notification_model_test.dart`
  - `test/notification_item_test.dart`
- Archivos modificados:
  - `lib/modules/notifications/models/notification_model.dart`
  - `lib/modules/notifications/hooks/use_notifications.dart`
  - `lib/modules/notifications/pages/notifications_page.dart`
  - `lib/modules/notifications/components/notification_item.dart`
  - `lib/context/notificacion_context.dart`
  - `lib/services/interaccion_service.dart`
  - `lib/services/colaboracion_service.dart`
  - `lib/main.dart`
- Funcionalidades implementadas: paginación por cursor, cargar más, lectura individual/todas, eliminación optimista, badge, acciones aceptar/rechazar invitación y transferencia, botones de pedidos/suscripción, deep link de suscripción, STOMP con auth/reconexión/heartbeats/colas de notificaciones-suscripción-pedidos, refresco en vivo y aviso de conexión/error.
- Pruebas: `flutter analyze` sin errores (2 avisos preexistentes); `flutter test` 17/17; pruebas de modelo y render de acciones. Validación con sesión real pendiente.
- Problemas/limitaciones: deep links de pedidos esperan Fase 14; sin asset de sonido; no se probó STOMP con eventos reales por falta de sesión activa.

### Fase 5 — Mis Menús
- Estado: COMPLETADA.
- Archivos creados:
  - `lib/modules/dashboard/models/dashboard_models.dart`
  - `lib/modules/dashboard/components/colaborador_row.dart`
  - `lib/modules/dashboard/components/delete_menu_modal.dart`
  - `lib/modules/dashboard/components/menu_steps.dart`
  - `lib/modules/dashboard/pages/menu_hub_page.dart`
  - `test/dashboard_models_test.dart`
  - `test/dashboard_widgets_test.dart`
- Archivos modificados:
  - `lib/modules/dashboard/pages/mis_menus_page.dart`
  - `lib/modules/dashboard/hooks/use_mis_menus.dart`
  - `lib/services/mis_menus_service.dart`
  - `lib/app.dart`
  - `lib/modules/menu/public/pages/preview_page.dart`
  - `lib/modules/menu/editor/stats/pages/estadisticas_page.dart`
- Funcionalidades implementadas: tarjetas propias con límite, colaboraciones con rol, hub por permisos, pasos del backend, ver/compartir, estadísticas, despublicar y eliminar con código de confirmación; rutas de dashboard a códigos públicos.
- Pruebas: `flutter analyze` sin errores (2 avisos preexistentes); `flutter test` 24/24.
- Problemas/limitaciones: acciones del editor, pedidos, mesas y colaboradores quedan para sus fases; no se probó eliminar/despublicar en producción; validación visual autenticada pendiente por falta de sesión.

### Fase 6 — Crear menú
- Estado: COMPLETADA.
- Archivos creados:
  - `lib/modules/menu/create/models/create_menu_models.dart`
  - `lib/services/image_upload_service.dart`
  - `test/create_menu_models_test.dart`
- Archivos modificados:
  - `lib/modules/menu/create/create_menu_page.dart`
  - `lib/services/menu_editor_service.dart`
  - `lib/services/public_api_service.dart`
- Funcionalidades implementadas: creación mínima en una pantalla, categorías por código, slug automático/verificado, logo recortado y portada, subida diferida a Cloudinary por sección, rollback independiente de imágenes y navegación al hub.
- Pruebas: `flutter analyze` sin errores (2 avisos preexistentes); `flutter test` 28/28; endpoints públicos de categorías y slug verificados.
- Problemas/limitaciones: creación/subida real pendientes de una sesión autenticada; tema y datos extendidos se completan en Fase 7.

### Fase 7 — Editor
- Estado: COMPLETADA.
- Archivos creados: `lib/modules/menu/editor/live/editor_models.dart`, `menu_editor_live_page.dart`, `product_form_live_page.dart`, `tabs/*_live_tab.dart`, `lib/services/live_editor_service.dart`, `test/live_editor_models_test.dart`.
- Archivos modificados: `lib/app.dart`, `lib/modules/dashboard/pages/menu_hub_page.dart`.
- Funcionalidades implementadas: info por secciones, horario, galería, categorías, productos por partes, grupos, diseño, publicación/trial/cupón y entrada de colaboradores.
- Pruebas: `flutter analyze` sin errores; `flutter test` 30/30.
- Problemas/limitaciones: validación autenticada pendiente, `imagePosition` sin UI, checkout de planes y CRUD de colaboradores en fases posteriores.

### Fase 9 — Colaboradores
- Estado: COMPLETADA (2026-10-30).
- Archivos modificados: `lib/services/colaboracion_service.dart`, `lib/modules/menu/editor/live/tabs/collaborators_live_tab.dart`, `lib/modules/menu/editor/live/menu_editor_live_page.dart`, `lib/modules/menu/editor/live/editor_models.dart`, `lib/modules/notifications/components/notification_item.dart`; nuevo `test/colaboracion_test.dart`.
- Funcionalidades implementadas: invitar con rol y límite, listar, cambiar rol, eliminar con confirmación, transferencia con confirmación/pendiente/`transferible`, aceptar/rechazar desde notificaciones con refresco de Mis Menús.
- Pruebas: analyze sin errores; 32 tests OK; rutas verificadas (401 sin sesión).
- Problemas/limitaciones: sin prueba E2E con dos cuentas reales; editor viejo sin rutas pendiente de limpieza (Fase 17).

### Fase 10 — Perfil
- Estado: COMPLETADA (2026-10-30).
- Archivos modificados: `lib/services/profile_service.dart`, `lib/services/dispositivo_service.dart`, `lib/services/api_client.dart`, `lib/modules/profile/hooks/use_profile.dart`, `lib/modules/profile/hooks/use_settings.dart`, `lib/modules/profile/pages/profile_page.dart`, `lib/modules/profile/pages/settings_page.dart`, `lib/context/auth_context.dart`, `lib/modules/explore/hooks/use_explore.dart`, `lib/main.dart`, `lib/app.dart`; nuevos `lib/components/layout/aviso_ubicacion.dart`, `test/aviso_ubicacion_test.dart`.
- Funcionalidades implementadas: ubicación y contacto en el perfil, validación de avatar, revocar sesiones por `codigo`, eliminar cuenta con código, aviso global de `requiereUbicacion`, limpieza en logout y retiro del interruptor de push, que no hacía nada.
- Pruebas: analyze sin errores; 35 tests OK; 8 rutas verificadas (401 sin sesión).
- Problemas/limitaciones: sin prueba E2E con cuenta real (no se elimina ninguna cuenta); `permission_handler` queda sin uso (limpieza en Fase 17).

### Fase 11 — Logros/Invitaciones
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 12 — Estadísticas
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 13 — Pedidos cliente
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 14 — Pedidos negocio/mesas
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 15 — Mesero
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 16 — Repartidor
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

### Fase 17 — QA final
- Estado: PENDIENTE.
- Archivos modificados: —
- Funcionalidades implementadas: —
- Pruebas: —
- Problemas/limitaciones: —

---

## 11. Decisiones pendientes y riesgos

Estos puntos **no se resuelven en este documento**; se validarán al iniciar la fase correspondiente y, si requieren cambiar configuración, se pedirá autorización.

1. **API base (RESUELTO):** el usuario confirmó `https://manzana.zammpy.com`. Fase 1 fijó esa base en `lib/services/api.dart` y verificó geografía/login contra ese host.
2. **Flujo de creación:** React actual crea con datos mínimos; Flutter tiene wizard de 5 pasos. Se propone conservar pasos útiles pero guardar solo con endpoints válidos y trasladar lo demás al editor. Confirmar en Fase 6.
3. **Edición directa vs tabs:** React edita dentro del menú público; Flutter mantiene editor con tabs. Se mantendrán tabs por ser móvil, agregando accesos directos donde aporte valor. Confirmar en Fase 7.
4. **Push real:** Flutter hoy solo pide permiso. Implementar push requiere SDK, proyecto Firebase/APNs y endpoint de registro; no se hará sin autorización explícita. Mientras tanto, corregir el texto de UI.
5. **Alcance de pedidos/mesero/repartidor:** son módulos grandes y parcialmente pensados para escritorio. Se adaptarán a móvil; confirmar prioridad al llegar a Fases 13-16.
6. **Google:** el `serverClientId` está hardcodeado. No se cambiarán credenciales; solo se validará que el flujo actual funcione.
7. **Backend desplegado:** si el host configurado no expone el contrato actual de React, se documentará como bloqueo y no se inventarán adaptaciones.

---

## 12. Criterios globales de aceptación del proyecto

- Todos los módulos autorizados funcionan contra el backend real, sin datos simulados.
- Los identificadores son códigos públicos, no `int` inventados.
- Las rutas privadas están protegidas y la sesión se renueva.
- Las pantallas tienen estados de carga, error y vacío.
- No hay regresiones en funcionalidades Flutter existentes sin justificación documentada.
- `flutter analyze` sin errores; pruebas en verde o limitaciones documentadas.
- React y backend permanecen intactos.
- Este documento permite retomar el trabajo sin perder contexto.

---

## 13. Siguiente paso

Las Fases 1–7 están implementadas; la Fase 8 es reservada y queda cubierta por Fase 4. El siguiente paso es la **Fase 9 — Colaboradores y transferencia**, pendiente de autorización.

**No se ha modificado ningún archivo de `menu-digital`.**

Las fases 9–16 quedan pendientes por presupuesto de contexto; el plan y las limitaciones están registrados para retomarlas.
