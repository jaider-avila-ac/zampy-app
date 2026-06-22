# 📋 ZamPy App — Plan de Fases (Flutter/Dart)

> **Referencia principal:** Proyecto React en `../menu-digital`
> **Convención de nombres:** Archivos Dart en `snake_case`, lo más similares posible a los JSX de React.
> **Estructura de carpetas:** Idéntica a React (`modules/`, `components/`, `context/`, `services/`, `hooks/`).
> **Backend:** No se modifica bajo ninguna circunstancia.
> **API Base:** `https://menu-digital-9p3g.onrender.com`

---

## Reglas generales
- Cada fase completada → commit en rama separada (`fase-1`, `fase-2`, etc.), **nunca en `main`**.
- Después de cada fase → **detenerse** para que el usuario pruebe y valide.
- Todo ocurre dentro de la app: menús, pagos Wompi, auth Google, sin abrir navegador externo.
- Login: fondo blanco (sin el fondo azul de React). El resto idéntico a la versión móvil de React.
- Al leer este archivo el asistente debe entender el estado completo del proyecto sin explicaciones adicionales.

---

## Estado de fases

### ✅ FASE 1 — Explorador + Menú Público
**Rama:** `fase-1`
**Estado:** COMPLETADA

#### Alcance
- `ExplorePage` — página principal pública (sin login requerido)
  - Banner demo clicable
  - Barra de búsqueda con debounce 350ms
  - Secciones horizontales: Cerca de ti, Tendencias, Nuevos
  - `InfiniteExplorer` con scroll infinito (cursor-based)
  - `LocationBanner` para pedir permiso de ubicación
  - `MenuCard` y `SkeletonCard`
- `PublicMenuPage` — menú público abierto dentro de la app (no en navegador)
  - Banner con imagen, logo circular solapado
  - `CategoryTabs` sticky con scroll horizontal
  - Grid de productos (`ProductCard`) y modo lista (`ProductListItem`)
  - `ProductModal` (bottom sheet con detalles)
  - `ReviewsSection`
  - `Footer` del menú
- `DemoPreviewPage` — menú demo desde el banner principal
- Routing base con `go_router`
- `AuthContext` (proveedor base — detecta sesión guardada)
- Servicios: `explore_service.dart`, `public_api_service.dart`, `interaccion_service.dart`

#### Estructura creada
```
lib/
├── main.dart
├── app.dart
├── shared/app_colors.dart
├── context/auth_context.dart
├── context/notificacion_context.dart
├── services/api.dart
├── services/explore_service.dart
├── services/public_api_service.dart
├── services/interaccion_service.dart
├── hooks/use_geo_location.dart
├── modules/explore/
│   ├── hooks/use_explore.dart
│   ├── components/menu_card.dart
│   ├── components/skeleton_card.dart
│   ├── components/section.dart
│   ├── components/location_banner.dart
│   ├── components/infinite_explorer.dart
│   └── pages/explore_page.dart
├── modules/menu/public/
│   ├── models/public_menu_model.dart
│   ├── hooks/use_public_menu.dart
│   ├── components/banner.dart
│   ├── components/category_tabs.dart
│   ├── components/product_card.dart
│   ├── components/product_list_item.dart
│   ├── components/product_modal.dart
│   ├── components/reviews_section.dart
│   ├── components/footer.dart
│   ├── pages/public_menu_page.dart
│   └── pages/demo_preview_page.dart
├── components/menu_page.dart
└── modules/auth/pages/login_page.dart  (placeholder)
```

---

### ⬜ FASE 2 — Autenticación
**Rama:** `fase-2` (pendiente)
**Estado:** PENDIENTE

#### Alcance
- `LoginPage` — fondo blanco, campo email/password, botón Google in-app
  - `AuthLayout` (solo columna derecha en móvil, sin panel azul)
  - `useLoginForm` hook
- `RegisterPage` — registro con nombre, apellido, email, password
  - `useRegisterForm` hook
- `ForgotPasswordPage` — recuperar contraseña
  - `useForgotPassword` hook
- `ResetPasswordPage` — nueva contraseña con token
  - `useResetPasswordForm` hook
- `VerifyEmailSentPage` — confirmación de envío de email
- `VerifyEmailCodePage` — código de verificación
  - `useVerifyEmailCode` hook
- `AuthCallbackPage` — manejo del callback OAuth
- Google OAuth **in-app** con `webview_flutter` (sin abrir navegador externo)
- `AuthContext` completo: login, logout, token refresh
- Servicios: `auth_service.dart`

#### Archivos a crear
```
lib/modules/auth/
├── components/auth_layout.dart       (= AuthLayout.jsx)
├── components/google_icon.dart       (= GoogleIcon.jsx)
├── hooks/use_login_form.dart         (= useLoginForm.js)
├── hooks/use_register_form.dart      (= useRegisterForm.js)
├── hooks/use_forgot_password.dart    (= useForgotPassword.js)
├── hooks/use_reset_password_form.dart (= useResetPasswordForm.js)
├── hooks/use_verify_email_code.dart  (= useVerifyEmailCode.js)
├── hooks/use_typewriter.dart         (= useTypewriter.js)
├── pages/login_page.dart             (= LoginPage.jsx)
├── pages/register_page.dart          (= RegisterPage.jsx)
├── pages/forgot_password_page.dart   (= ForgotPasswordPage.jsx)
├── pages/reset_password_page.dart    (= ResetPasswordPage.jsx)
├── pages/verify_email_sent_page.dart (= VerifyEmailSentPage.jsx)
├── pages/verify_email_code_page.dart (= VerifyEmailCodePage.jsx)
└── pages/auth_callback_page.dart     (= AuthCallbackPage.jsx)
lib/services/auth_service.dart        (= authService.js)
```

---

### ⬜ FASE 3 — Layout Autenticado (Sidebar + Shell)
**Rama:** `fase-3` (pendiente)
**Estado:** PENDIENTE

#### Alcance
- `DashboardLayout` — shell completo con sidebar y navegación
- `Sidebar` — drawer lateral (móvil: fixed overlay, mismo comportamiento que React)
  - Logo Zammpy expandible/colapsable
  - Items de nav con iconos y etiquetas
  - Badge de notificaciones
  - Botón "Crear menú"
  - Sección perfil con avatar, nombre, email, logout
- `BottomNav` — barra inferior (móvil)
- `Header` — barra superior autenticada
- `ProfilePanel` — panel deslizable de perfil
- Navegación completa post-login (todas las rutas protegidas)

#### Archivos a crear
```
lib/components/layout/
├── dashboard_layout.dart  (= DashboardLayout.jsx)
├── sidebar.dart           (= Sidebar.jsx)
├── bottom_nav.dart        (= BottomNav.jsx)
├── header.dart            (= Header.jsx)
└── profile_panel.dart     (= ProfilePanel.jsx)
```

---

### ⬜ FASE 4 — Notificaciones
**Rama:** `fase-4` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/notifications` en React

#### Archivos a crear
```
lib/modules/notifications/
├── hooks/use_notifications.dart
├── components/notification_item.dart
└── pages/notifications_page.dart     (= NotificationsPage.jsx)
lib/services/notificacion_service.dart (= notificacionService.js)
```

---

### ⬜ FASE 5 — Logros
**Rama:** `fase-5` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/logros` en React

#### Archivos a crear
```
lib/modules/growth/achievements/
├── components/logro_card.dart       (= LogroCard.jsx)
├── components/progress_bar.dart     (= ProgressBar.jsx)
├── hooks/use_logros.dart            (= useLogros.js)
└── pages/logros_page.dart           (= LogrosPage.jsx)
lib/services/logro_service.dart      (= logroService.js)
```

---

### ⬜ FASE 6 — Invitaciones
**Rama:** `fase-6` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/invitaciones` en React

#### Archivos a crear
```
lib/modules/growth/invitations/
├── hooks/use_invitaciones.dart       (= useInvitaciones.js)
└── pages/invitaciones_page.dart      (= InvitacionesPage.jsx)
lib/services/invitacion_service.dart  (= invitacionService.js)
```

---

### ⬜ FASE 7 — Ajustes + Perfil
**Rama:** `fase-7` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/settings` y `/perfil` en React

#### Archivos a crear
```
lib/modules/profile/
├── hooks/use_settings.dart
├── pages/settings_page.dart          (= SettingsPage.jsx)
└── pages/profile_page.dart           (= ProfilePage.jsx)
lib/services/profile_service.dart
```

---

### ⬜ FASE 8 — Suscripciones + Pagos Wompi
**Rama:** `fase-8` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/suscripcion`, `/billing/*` en React

> Pagos Wompi se integran dentro de la app con `webview_flutter` — sin abrir navegador externo.

#### Archivos a crear
```
lib/modules/subscription/
├── components/plan_card.dart
├── components/coupon_section.dart
├── hooks/use_suscripcion.dart
├── pages/suscripcion_overview_page.dart (= SuscripcionOverviewPage.jsx)
├── pages/suscripcion_page.dart          (= SuscripcionPage.jsx)
├── pages/suscripcion_detail_page.dart   (= SuscripcionDetailPage.jsx)
├── pages/planes_page.dart               (= PlanesPage.jsx)
└── pages/checkout_page.dart             (= CheckoutPage.jsx)
lib/services/suscripcion_service.dart    (= suscripcionService.js)
lib/services/cupon_service.dart          (= cuponService.js)
```

---

### ⬜ FASE 9 — Mis Menús + Crear + Editor + Productos + Publicar (ÚLTIMA)
**Rama:** `fase-9` (pendiente)
**Estado:** PENDIENTE
**Equivale a:** `/menus`, `/menus/new`, `/menus/:id/edit`, `/menus/:id/products/*`

> Esta es la fase más compleja. Se desarrolla al final.

#### Archivos a crear
```
lib/modules/dashboard/
├── components/menu_row.dart          (= MenuRow.jsx)
├── components/colaborador_row.dart   (= ColaboradorRow.jsx)
├── components/delete_menu_modal.dart (= DeleteMenuModal.jsx)
├── hooks/use_mis_menus.dart          (= useMisMenus.js)
└── pages/mis_menus_page.dart         (= MisMenusPage.jsx)

lib/modules/menu/create/
├── components/steps/step_category.dart (= StepCategory.jsx)
├── components/steps/step_contact.dart  (= StepContact.jsx)
├── components/steps/... (demás steps)
└── pages/create_menu_page.dart         (= CreateMenuPage.jsx)

lib/modules/menu/editor/
├── stats/pages/estadisticas_page.dart  (= EstadisticasPage.jsx)
├── tabs/publish/publish_tab.dart       (= publish_tab components)
├── menu_editor_page.dart               (= MenuEditorPage.jsx)
├── menu_info_page.dart                 (= MenuInfoPage.jsx)
└── product_form_page.dart              (= ProductFormPage.jsx)

lib/services/menu_service.dart          (= menuService.js)
lib/services/estadisticas_service.dart  (= estadisticasService.js)
lib/services/colaboracion_service.dart  (= colaboracionService.js)
lib/services/image_service.dart         (= imageService.js)
```

---

## Rutas de la app (go_router)

| Ruta Flutter | Equivalente React | Fase |
|---|---|---|
| `/` → `/explore` | `/` → `/explore` | 1 |
| `/explore` | `/explore` | 1 |
| `/menu/:slug` | `/menu/:slug` | 1 |
| `/preview/demo` | `/preview/demo` | 1 |
| `/login` | `/login` | 2 |
| `/register` | `/register` | 2 |
| `/auth/callback` | `/auth/callback` | 2 |
| `/auth/verify-sent` | `/auth/verify-sent` | 2 |
| `/auth/verify-code` | `/auth/verify-code` | 2 |
| `/auth/forgot-password` | `/auth/forgot-password` | 2 |
| `/auth/reset-password` | `/auth/reset-password` | 2 |
| `/notifications` | `/notifications` | 4 |
| `/logros` | `/logros` | 5 |
| `/invitaciones` | `/invitaciones` | 6 |
| `/settings` | `/settings` | 7 |
| `/perfil` | `/perfil` | 7 |
| `/suscripcion` | `/suscripcion` | 8 |
| `/billing/:id` | `/billing/:id` | 8 |
| `/billing/:id/checkout` | `/billing/:id/checkout` | 8 |
| `/menus` | `/menus` | 9 |
| `/menus/new` | `/menus/new` | 9 |
| `/menus/:id/edit` | `/menus/:id/edit` | 9 |
| `/menus/:id/products/new` | `/menus/:id/products/new` | 9 |
| `/menus/:id/products/:pid` | `/menus/:id/products/:pid` | 9 |

---

*Última actualización: Fase 1 completada.*
