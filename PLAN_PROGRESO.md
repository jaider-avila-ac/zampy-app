# Plan de implementación — ZamPy Flutter
> Actualizado automáticamente. Si se corta el chat, retomar desde aquí.
> Backend: https://menu-digital-9p3g.onrender.com
> Análisis completo: ANALISIS_FLUTTER.md

---

## Estado general
- [x] Auth (login / registro) — COMPLETADO, rediseño minimalista aplicado
- [x] Bloque 1 — Mis Menús + Crear Menú — COMPLETADO ✅
- [ ] Bloque 2 — Editor: Info Negocio + Categorías + Productos
- [ ] Bloque 3 — Editor: Grupos + Diseño + Publicar + Colaboradores
- [ ] Bloque 4 — Suscripción + Pago Wompi en WebView
- [ ] Bloque 5 — Preview en vivo desde el editor

---

## BLOQUE 1 — Mis Menús + Crear Menú

### Archivos nuevos / modificados — COMPLETADOS
- [x] `lib/modules/mis_menus/mis_menus_screen.dart` — actualizado: Nuevo y Editar → Flutter
- [x] `lib/modules/mis_menus/mis_menus_service.dart` — ya existía completo
- [x] `lib/modules/mis_menus/mis_menus_model.dart` — ya existía completo
- [x] `lib/modules/crear_menu/crear_menu_screen.dart` — wizard 5 pasos completo (inline)
- [x] `lib/modules/crear_menu/crear_menu_service.dart` — create(), updateDraftImages(), getThemes()
- [x] `lib/modules/editor/menu_editor_screen.dart` — placeholder (se rellena en Bloque 2)
- [x] `lib/shared/services/image_upload_service.dart` — upload multipart a /api/images/upload

### Lo que debe hacer Mis Menús
- Lista de menús propios (GET /api/menus) ordenados por fecha DESC
- Thumbnail (bannerUrl como imagen de fondo o degradado si no hay)
- Badges: Publicado (verde) / Borrador (ámbar) / Cambios (azul, si published+hasDraftChanges)
- Stats: vistas, me-encanta, reseñas (solo si > 0)
- Botón "Editar" visible + menú 3 puntos (preview, ver público, editar, estadísticas, despublicar, eliminar)
- Sección "Colaborando en" (GET /api/colaboraciones/mias)
- FAB o botón "Nuevo menú"
- Skeleton loader mientras carga
- Estado vacío si no tiene menús
- Modal eliminar: muestra nombre, genera palabra 5 chars aleatoria, usuario la escribe, confirmar activa

### Lo que debe hacer Crear Menú
Wizard 5 pasos con barra de progreso superior y navegación inferior:

**Paso 0 — Categoría**
  Grid 3 columnas de tarjetas, 25 categorías de negocio con emoji/icono + nombre
  Validación: debe seleccionar una para avanzar

**Paso 1 — Identidad**
  - name (max 50, requerido)
  - slug (auto desde nombre con slugify, editable, min 3 max 50, solo [a-z0-9-])
  - slogan (max 70, opcional)
  - bannerUrl (ImagePicker, deferred — no sube hasta crear)
  - logoUrl (ImagePicker, deferred, cuadrada)
  Validación: name no vacío y slug válido

**Paso 2 — Contacto** (todos opcionales)
  - phone, whatsapp (max 15)
  - schedule (TextField libre)
  - paisNombre, div1Nombre, div2Nombre, address (campos de texto, sin API de geografía por ahora — simplificar)

**Paso 3 — Redes** (todos opcionales)
  - instagram, facebook, tiktok, website (max 100 cada uno)

**Paso 4 — Diseño**
  - GET /api/temas → lista de skins
  - Grid 2 col de skins → al seleccionar, muestra paletas del skin
  - Seleccionar paleta confirma la elección

**Al crear:**
  1. POST /api/menus (sin imágenes)
  2. Si hay imágenes: POST /api/images/upload (multipart) por cada una
  3. Si se subieron: PATCH /api/menus/{id}/draft con { info: { bannerUrl, logoUrl } }
  4. Navegar al editor del menú

---

## BLOQUE 2 — Editor: Info + Categorías + Productos
> No empezar hasta que Bloque 1 esté aprobado

### Archivos
- [ ] `lib/modules/editor/menu_editor_screen.dart` — scaffold con tabs
- [ ] `lib/modules/editor/tabs/info_negocio_screen.dart`
- [ ] `lib/modules/editor/tabs/categorias_tab.dart`
- [ ] `lib/modules/editor/tabs/productos_tab.dart`
- [ ] `lib/modules/editor/screens/product_form_screen.dart`
- [ ] `lib/modules/editor/widgets/category_form_sheet.dart`
- [ ] `lib/modules/editor/widgets/variant_list_editor.dart`
- [ ] `lib/modules/editor/widgets/icon_picker_grid.dart`
- [ ] `lib/modules/editor/menu_editor_service.dart`
- [ ] `lib/modules/editor/menu_editor_model.dart`

### Lógica clave
- CategoriesTab: 2 tipos (con_imagenes / sin_imagenes), icon picker grid, reordenar
- ProductsTab: búsqueda + filtro por cat, lista con thumbnail
- ProductForm: sin generación de imágenes (solo galería/cámara), variantes (tamaños/ingredientes/extras)
- SaveBar: barra fija al fondo, aparece cuando dirty=true
- Deferred image upload

---

## BLOQUE 3 — Editor: Grupos + Diseño + Publicar + Colaboradores
> No empezar hasta que Bloque 2 esté aprobado

### Archivos
- [ ] `lib/modules/editor/tabs/grupos_tab.dart`
- [ ] `lib/modules/editor/tabs/diseno_tab.dart`
- [ ] `lib/modules/editor/tabs/publicar_tab.dart`
- [ ] `lib/modules/editor/tabs/colaboradores_tab.dart`

### Lógica clave
- PublicarTab: requisitos, 8 estados de suscripción, cupón, modal pricing, botón publicar
- DisenoTab: GET /api/temas, grid skins, paletas, preview del tema
- ColaboradoresTab: invitar con código 6 chars, listar, remover

---

## BLOQUE 4 — Suscripción + Wompi
> No empezar hasta que Bloque 3 esté aprobado

### Archivos
- [ ] `lib/modules/suscripcion/suscripcion_screen.dart`
- [ ] `lib/modules/suscripcion/suscripcion_service.dart`
- [ ] `lib/modules/suscripcion/wompi_webview_screen.dart`
- [ ] `lib/modules/suscripcion/suscripcion_model.dart`

### Lógica clave
- Wompi: WebView con NavigationDelegate detecta redirect con ?id=TX_ID, cierra y hace polling
- Polling: Timer.periodic(4s) mientras estado es PENDING_PAYMENT o WAITING_ACTIVATION
- 3 planes: gratuito / básico / avanzado (radio buttons)
- Historial de pagos con badges de estado y método

---

## BLOQUE 5 — Preview en vivo
> No empezar hasta que Bloque 4 esté aprobado

### Archivos
- [ ] Modificar `PublicMenuScreen` para aceptar datos del draft (no solo slug)
- [ ] Integrar botón "Preview" en el editor que navega con los datos locales

---

## Dependencias ya en pubspec.yaml
- http: ^1.2.1 ✅
- flutter_svg: ^2.0.10 ✅
- image_picker: ^1.1.2 ✅
- flutter_secure_storage: ^9.2.2 ✅
- url_launcher: ^6.3.1 ✅
- webview_flutter: ^4.10.0 ✅

## Posibles dependencias a agregar
- `cached_network_image` — para cargar imágenes de menús eficientemente
- `intl` — para formatear precios COP

---

## Notas técnicas importantes
- API base: https://menu-digital-9p3g.onrender.com
- Auth: token JWT en flutter_secure_storage, key "jwt_token"
- Imágenes: Cloudinary vía POST /api/images/upload (multipart, campo "file")
- Slug: auto-generado de name pero respeta edición manual. Regex ^[a-z0-9-]+$ min 3 max 50
- SaveBar: reutilizable, fija al fondo, solo visible cuando dirty=true
- Precios: en pesos COP enteros (no centavos en productos). En suscripción vienen en centavos.
- Categorías: 2 tipos — con_imagenes (requiere imagen en producto para publicar) / sin_imagenes (no)
- Wompi: backend genera checkoutUrl, abrir en webview_flutter con detección de redirect
