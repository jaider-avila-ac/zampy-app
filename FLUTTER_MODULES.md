# ZamPy Flutter — Mapa de módulos

> Referencia para construir la app Flutter módulo por módulo.
> La app se conecta al mismo backend en Render.
> Variable de entorno pendiente: `API_BASE_URL` → URL del servidor real.
> No incluye Landing Page.

---

## Variable de entorno
LOS JSX NO LOS DEBES MODIFICAR
```
API_BASE_URL=https://menu-digital-9p3g.onrender.com
```

En Flutter se maneja en `lib/core/config/env.dart`.

---

## Módulo 1 — Auth

Pantallas de acceso y recuperación de cuenta.

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/auth/LoginPage.jsx`                      | `LoginScreen`            |
| `pages/auth/RegisterPage.jsx`                   | `RegisterScreen`         |
| `pages/auth/AuthCallbackPage.jsx`               | `OAuthCallbackScreen`    |
| `pages/auth/VerifyEmailSentPage.jsx`            | `VerifyEmailSentScreen`  |
| `pages/auth/ForgotPasswordPage.jsx`             | `ForgotPasswordScreen`   |
| `pages/auth/ResetPasswordPage.jsx`              | `ResetPasswordScreen`    |
| `context/AuthContext.jsx`                       | `AuthProvider` (Riverpod/Provider) |
| `services/authService.js`                       | `auth_service.dart`      |

**Endpoints usados:**
- `POST /api/auth/login`
- `POST /api/auth/register`
- `POST /api/auth/forgot-password`
- `POST /api/auth/reset-password`
- `GET  /api/auth/google` (OAuth — WebView o browser externo)

---

## Módulo 2 — Explorar

Feed público de menús con scroll infinito, búsqueda y ubicación.

| Archivo web (referencia)                        | Pantalla / Widget Flutter     |
|-------------------------------------------------|-------------------------------|
| `pages/admin/ExplorePage.jsx`                   | `ExploreScreen`               |
| `pages/admin/explore/MenuCard.jsx`              | `MenuCard` widget             |
| `pages/admin/explore/SkeletonCard.jsx`          | `MenuCardSkeleton` widget     |
| `pages/admin/explore/Section.jsx`               | `ExploreSection` widget       |
| `pages/admin/explore/InfiniteExplorer.jsx`      | `InfiniteExplorer` widget     |
| `pages/admin/explore/LocationBanner.jsx`        | `LocationBanner` widget       |
| `services/exploreService.js`                    | `explore_service.dart`        |
| `hooks/useGeoLocation.js`                       | `location_service.dart`       |

**Endpoints usados:**
- `GET /api/explore/feed?ciudad=X`
- `GET /api/explore/menus?offset=40&size=24`
- `GET /api/public/menus/search?q=X`
- `GET /api/interacciones/mis-encantados`

---

## Módulo 3 — Mis Menús

Lista de menús del usuario autenticado.

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/admin/MisMenus.jsx`                      | `MisMenusScreen`         |
| `pages/admin/DashboardHome.jsx`                 | `DashboardScreen`        |
| `services/menuService.js`                       | `menu_service.dart`      |

**Endpoints usados:**
- `GET  /api/menus`
- `DELETE /api/menus/:id`
- `PUT /api/menus/:id/estado`

---

## Módulo 4 — Crear Menú

Wizard de creación de menú en pasos.

| Archivo web (referencia)                           | Pantalla / Widget Flutter   |
|----------------------------------------------------|-----------------------------|
| `pages/admin/create/CreateMenuPage.jsx`            | `CreateMenuScreen`          |
| `pages/admin/create/steps/StepIdentity.jsx`        | `StepIdentity` widget       |
| `pages/admin/create/steps/StepCategory.jsx`        | `StepCategory` widget       |
| `pages/admin/create/steps/StepDesign.jsx`          | `StepDesign` widget         |
| `pages/admin/create/steps/StepContact.jsx`         | `StepContact` widget        |
| `pages/admin/create/steps/StepSocial.jsx`          | `StepSocial` widget         |

**Endpoints usados:**
- `POST /api/menus`
- `GET  /api/geografia/departamentos`
- `GET  /api/geografia/municipios/:dep`

---

## Módulo 5 — Editor de Menú

Edición completa del menú: info, diseño, productos, categorías, grupos, colaboradores, publicación.

| Archivo web (referencia)                           | Pantalla / Widget Flutter      |
|----------------------------------------------------|--------------------------------|
| `pages/admin/editor/MenuEditorPage.jsx`            | `MenuEditorScreen`             |
| `pages/admin/editor/InfoTab.jsx`                   | `InfoTab` widget               |
| `pages/admin/editor/DesignTab.jsx`                 | `DesignTab` widget             |
| `pages/admin/editor/ProductsTab.jsx`               | `ProductsTab` widget           |
| `pages/admin/editor/ProductForm.jsx`               | `ProductFormScreen`            |
| `pages/admin/editor/ProductFormPage.jsx`           | `ProductFormScreen` (página)   |
| `pages/admin/editor/CategoriesTab.jsx`             | `CategoriesTab` widget         |
| `pages/admin/editor/GruposTab.jsx`                 | `GruposTab` widget             |
| `pages/admin/editor/ColaboradoresTab.jsx`          | `ColaboradoresTab` widget      |
| `pages/admin/editor/PublishTab.jsx`                | `PublishTab` widget            |
| `pages/admin/editor/MenuInfoPage.jsx`              | `MenuInfoScreen`               |
| `pages/admin/editor/ImportJsonButton.jsx`          | `ImportJsonButton` widget      |
| `pages/admin/editor/ProductFieldToggles.jsx`       | `ProductFieldToggles` widget   |
| `services/menuService.js`                          | `menu_service.dart`            |
| `services/imageService.js`                         | `image_service.dart`           |

**Endpoints usados:**
- `PUT  /api/menus/:id`
- `POST /api/menus/:id/products`
- `PUT  /api/menus/:id/products/:pid`
- `DELETE /api/menus/:id/products/:pid`
- `PUT  /api/menus/:id/publish`
- `POST /api/images/upload`

---

## Módulo 6 — Notificaciones

Centro de notificaciones en tiempo real (WebSocket + REST).

| Archivo web (referencia)                        | Pantalla / Widget Flutter      |
|-------------------------------------------------|--------------------------------|
| `pages/admin/NotificationsPage.jsx`             | `NotificationsScreen`          |
| `context/NotificacionContext.jsx`               | `NotificacionProvider`         |
| `services/interaccionService.js`                | `interaccion_service.dart`     |

**Endpoints usados:**
- `GET  /api/notificaciones`
- `PUT  /api/notificaciones/:id/leer`
- `PUT  /api/notificaciones/leer-todas`
- `DELETE /api/notificaciones/:id`
- `WS  /ws` (STOMP — notificaciones en tiempo real)

---

## Módulo 7 — Logros

Sistema de logros con barra de progreso y recompensas en días.

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/admin/LogrosPage.jsx`                    | `LogrosScreen`           |
| `services/logroService.js`                      | `logro_service.dart`     |

**Endpoints usados:**
- `GET /api/logros/mi-progreso`

---

## Módulo 8 — Invitaciones

Sistema de invitaciones con enlace, estado y progreso.

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/admin/InvitacionesPage.jsx`              | `InvitacionesScreen`     |
| `services/invitacionService.js`                 | `invitacion_service.dart`|

**Endpoints usados:**
- `GET /api/invitaciones/estado`
- `PUT /api/invitaciones/toggle`

---

## Módulo 9 — Suscripción

Gestión del plan activo, pagos con Wompi y aplicación de cupones.

| Archivo web (referencia)                        | Pantalla Flutter              |
|-------------------------------------------------|-------------------------------|
| `pages/admin/SuscripcionOverviewPage.jsx`       | `SuscripcionOverviewScreen`   |
| `pages/admin/SuscripcionPage.jsx`               | `SuscripcionDetailScreen`     |
| `services/suscripcionService.js`                | `suscripcion_service.dart`    |
| `services/cuponService.js`                      | `cupon_service.dart`          |

**Endpoints usados:**
- `GET  /api/suscripcion/overview`
- `GET  /api/suscripcion/:menId`
- `POST /api/suscripcion/:menId/pagar`
- `POST /api/cupones/aplicar`

---

## Módulo 10 — Estadísticas

Métricas de visitas, interacciones y rendimiento por menú.

| Archivo web (referencia)                        | Pantalla Flutter          |
|-------------------------------------------------|---------------------------|
| `pages/admin/EstadisticasPage.jsx`              | `EstadisticasScreen`      |
| `services/estadisticasService.js`               | `estadisticas_service.dart`|

**Endpoints usados:**
- `GET /api/estadisticas/:menId`

---

## Módulo 11 — Ajustes

Sesiones activas y código de colaborador.

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/admin/SettingsPage.jsx`                  | `SettingsScreen`         |
| `services/dispositivoService.js`                | `dispositivo_service.dart`|
| `services/colaboracionService.js`               | `colaboracion_service.dart`|

**Endpoints usados:**
- `GET    /api/dispositivos`
- `DELETE /api/dispositivos/:id`
- `GET    /api/user/me`

---

## Módulo 12 — Perfil

Edición de datos personales y cambio de contraseña (solo usuarios con registro manual).

| Archivo web (referencia)                        | Pantalla Flutter         |
|-------------------------------------------------|--------------------------|
| `pages/admin/ProfilePage.jsx`                   | `ProfileScreen`          |
| `services/authService.js`                       | `auth_service.dart`      |

**Endpoints usados:**
- `GET /api/user/me`
- `PUT /api/user/profile` (multipart)
- `PUT /api/user/me/password`

---

## Módulo 13 — Menú Público (visor)

Vista pública del menú de un restaurante — accesible sin login.

| Archivo web (referencia)                        | Pantalla / Widget Flutter   |
|-------------------------------------------------|-----------------------------|
| `pages/public/PublicMenuPage.jsx`               | `PublicMenuScreen`          |
| `components/MenuPage.jsx`                       | `MenuPageWidget`            |
| `components/ProductCard.jsx`                    | `ProductCard` widget        |
| `components/ProductModal.jsx`                   | `ProductModal` widget       |
| `components/ProductListItem.jsx`                | `ProductListItem` widget    |
| `components/Banner.jsx`                         | `MenuBanner` widget         |
| `components/ReviewsSection.jsx`                 | `ReviewsSection` widget     |
| `components/CarouselView.jsx`                   | `CarouselView` widget       |
| `components/CategoryTabs.jsx`                   | `CategoryTabs` widget       |
| `components/ShareModal.jsx`                     | `ShareModal` widget         |
| `services/publicApiService.js`                  | `public_api_service.dart`   |
| `services/interaccionService.js`                | `interaccion_service.dart`  |

**Endpoints usados:**
- `GET  /api/public/menus/:slug`
- `POST /api/interacciones/:slug/resenas`
- `GET  /api/interacciones/:slug/resenas`
- `POST /api/interacciones/:slug/me-encanta`
- `GET  /api/interacciones/:slug/me-encanta`
- `POST /api/interacciones/:slug/productos/:pid/calificar`
- `POST /api/public/menus/:slug/vista`

---

## Estructura de carpetas Flutter sugerida

```
lib/
  core/
    config/
      env.dart              ← API_BASE_URL
    network/
      api_client.dart       ← Dio / http base
    storage/
      secure_storage.dart   ← token JWT
  modules/
    auth/
    explore/
    mis_menus/
    crear_menu/
    editor/
    notificaciones/
    logros/
    invitaciones/
    suscripcion/
    estadisticas/
    ajustes/
    perfil/
    menu_publico/
  shared/
    widgets/
    theme/
```

---

## Orden de construcción recomendado

1. Core (env, api_client, auth storage)
2. Auth
3. Explorar
4. Mis Menus
5. Menu Publico (visor)
6. Editor de Menu
7. Crear Menu
8. Notificaciones
9. Logros
10. Invitaciones
11. Suscripcion
12. Estadisticas
13. Ajustes
14. Perfil
