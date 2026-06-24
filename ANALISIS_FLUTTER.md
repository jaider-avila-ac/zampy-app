# ANÁLISIS COMPLETO — JSX → Flutter (Módulos: Mis Menús, Crear, Editor, Suscripción)

> Generado desde lectura directa de los JSX. Suficiente para implementar sin volver a consultar los JSX.

---

## 1. MIS MENÚS (`MisMenus.jsx`)

### Pantalla principal
- Encabezado: "Mis Menús" + botón "Nuevo" (→ CreateMenu)
- Lista propia ordenada por `createdAt DESC`
- Sección separada "Colaborando en" si hay menús donde es colaborador

### Datos de cada menú en la lista
```
menu.id, menu.slug, menu.status ('draft' | 'published'), menu.hasDraftChanges
menu.draft.info: { name, slogan, bannerUrl, logoUrl }
menu.totalVistas, menu.meEncantas, menu.totalResenas
menu.createdAt
```

### Thumbnail
- Si tiene `bannerUrl`: imagen de fondo cover 56×56 px
- Si no: degradado `#6366f1 → #8b5cf6`

### Badges de estado
- Publicado → verde
- Borrador → ámbar
- Cambios sin publicar (si `isPublished && hasDraftChanges`) → azul

### Estadísticas en la fila
- Vistas: `👁 X vista(s)` — solo si > 0
- Me encanta: `❤ X` — solo si > 0
- Reseñas: `💬 X reseña(s)` — solo si > 0

### Acciones por menú
Botón principal "Editar" siempre visible.
Botón `···` (tres puntos) abre menú desplegable:
- Ver preview → navegar a preview del menú dentro de la app
- Ver publicado (solo si `isPublished`) → abrir URL pública en WebView/browser
- Editar → ir al editor
- Estadísticas → ir a stats del menú
- Despublicar (solo si `isPublished`) → `PUT /api/menus/:id/unpublish`
- Eliminar → abre modal de confirmación

### Modal eliminar
- Muestra el nombre del menú
- Genera palabra aleatoria de 5 caracteres (A-Z sin vocales ambiguas)
- Usuario debe escribir exactamente esa palabra
- Botón "Eliminar definitivamente" se activa solo cuando coincide
- API: `DELETE /api/menus/:id`

### APIs
- `GET /api/menus` → lista propia
- `GET /api/colaboraciones/mias` → menús en que colaboro
- `DELETE /api/menus/:id`
- `PUT /api/menus/:id/unpublish`

---

## 2. CREAR MENÚ — WIZARD 5 PASOS (`create/CreateMenuPage.jsx`)

### Estructura del estado inicial (EMPTY)
```dart
restaurantCategoryId: null,
name: '', slug: '', slogan: '', bannerUrl: '', logoUrl: '',
phone: '', whatsapp: '',
paisIso2: '', paisNombre: '', div1Iso2: '', div1Nombre: '', div2Nombre: '', address: '',
schedule: '',
instagram: '', facebook: '', tiktok: '', website: '',
skinId: 'fastfood', paletteId: 'ember',
```

### Navegación
- Barra de progreso con 5 círculos numerados en la parte superior
- Puede regresar a pasos completados (menores al actual)
- Bottom bar: Anterior / Paso X de 5 / Siguiente (o "Crear menú" en el último)

### Validaciones para avanzar
- Paso 0 (Categoría): `restaurantCategoryId != null`
- Paso 1 (Identidad): `name.trim().length > 0 && !slugError(slug)`
- Pasos 2, 3, 4: siempre puede avanzar (opcionales)

### PASO 0 — Categoría (`StepCategory.jsx`)
Grid de tarjetas, 25 categorías de restaurante/negocio.
Solo lectura directa de JSX necesaria. Categorías ejemplo:
Restaurante, Pizzería, Hamburguesería, Sushi, Tacos, Panadería, Cafetería,
Heladería, Comida rápida, Comida saludable, Vegano, Bar, Licorería,
Frutería, Arepería, etc.
Seleccionar una activa `restaurantCategoryId`.

### PASO 1 — Identidad (`StepIdentity.jsx`)
Sección "Nombre y slogan":
- `name` (texto, requerido, max 50) — al cambiar auto-genera `slug` con slugify si no fue editado manualmente
- `slogan` (texto, opcional, max 70)

Sección "URL de tu menú":
- `slug` (texto, requerido, min 3, max 50, solo `[a-z0-9-]`)
- Prefijo visual: `menudigital.app/menu/`
- Validación en tiempo real; error si inválido, verde si válido
- Slug se auto-genera del nombre pero el usuario puede editarlo manualmente

Sección "Imágenes (opcional — puedes agregarlas después)":
- `bannerUrl` — FileUpload deferred, recomendado 1200×400 px
- `logoUrl` — FileUpload deferred, crop 1:1

**DEFERRED**: Las imágenes NO se suben en este paso. Se guardan en memoria como `File` y se suben a Cloudinary solo cuando se llama `handleCreate`.

### PASO 2 — Contacto (`StepContact.jsx`)
Campos opcionales:
- `phone` (texto, max 15, placeholder "+57 300 000 0000")
- `whatsapp` (texto, max 15)
- `schedule` (campo especial ScheduleInput — texto libre o formato estructurado, en Flutter usar TextField)
- `paisIso2`, `paisNombre`, `div1Iso2`, `div1Nombre`, `div2Nombre`, `address`
  → LocationCascadeInput: cascada País → Departamento/Estado → Municipio + dirección libre
  → En Flutter: 4 campos en cascada (DropdownButton o TextField con búsqueda)
  → APIs: `GET /api/geografia/departamentos`, `GET /api/geografia/municipios/:dep`

### PASO 3 — Redes sociales (`StepSocial.jsx`)
Todos opcionales:
- `instagram` (max 100)
- `facebook` (max 100)
- `tiktok` (max 100)
- `website` (max 100)

### PASO 4 — Diseño (`StepDesign.jsx`)
- `skinId` — selector de tema (grid 2 col de tarjetas con vista previa)
- `paletteId` — paletas del skin seleccionado
- Ver sección 5.4 (DesignTab) para detalles

### Flujo de creación (handleCreate)
1. `POST /api/menus` con todos los datos (bannerUrl y logoUrl vacíos)
2. Upload banner → Cloudinary: `resolveImageField(bannerUrl, 'menus/{id}/banner')`
3. Upload logo → Cloudinary: `resolveImageField(logoUrl, 'menus/{id}/logo')`
4. Si hubo imágenes: `PATCH /api/menus/{id}/draft` con `{ info: { bannerUrl, logoUrl } }`
5. Navegar al editor del menú creado

**Rollback en error**: si falla después de subir imágenes, las borra de Cloudinary y elimina el menú.

---

## 3. EDITOR DE MENÚ (`editor/MenuEditorPage.jsx`)

### Estructura de datos que devuelve `GET /api/menus/:id`
```
menu: {
  id, slug, status, hasDraftChanges,
  ownerId,
  draft: {
    info: { name, slogan, bannerUrl, logoUrl, phone, whatsapp, schedule,
            paisIso2, paisNombre, div1Iso2, div1Nombre, div2Nombre, address,
            instagram, facebook, tiktok, website, rating, reviews, tags[] },
    categories: [ { id, name, icon, tipoContenido, order, isVisible } ],
    products: [ { id, name, description, price, categoryId, imageUrl, tags[],
                  isVisible, isFeatured, sizes[], ingredients[], extras[], grupoIds[],
                  components[], promoActive, promoPrice, promoEndsAt, rating, totalVotos } ],
    grupos: [ { id, name, items[], isActive } ],
    skinId, paletteId,
  },
  published: { publishedAt },
  subscription: { estado, tipoPlan, limiteProductos, diasRestantes, trialUsado, ... },
  cupon: { estado, diasTotal, diasRestantes, expiraEn },
  pendingCheckout: bool,
}
```

### Top bar del editor
- Botón ← volver a Mis Menús
- Nombre del menú + `/menu/{slug}`
- Badge de estado: Publicado (verde) / Cambios sin publicar (ámbar) / Borrador (gris) / Colaborador (violeta)
- Icono de estadísticas (solo owner)
- Botón "Info negocio" → InfoTab (pantalla separada o sheet)
- Icono de preview (ojo/enlace)

### Tabs del editor
```
Categorías   → CategoriesTab  (owner + colaborador)
Productos    → ProductsTab    (owner + colaborador)
Grupos info  → GruposTab      (owner + colaborador)
Diseño       → DesignTab      (owner + colaborador)
Publicar     → PublishTab     (owner solo) — punto naranja si hasDraftChanges
Colaboradores → ColaboradoresTab (owner solo)
```

### Guardado (handleSave)
`PATCH /api/menus/:id` con `{ categories: [...] }` o `{ products: [...] }` etc.
Devuelve el menú completo actualizado.

---

## 3.1 CATEGORÍAS TAB (`CategoriesTab.jsx`)

### Estado
Lista de categorías ordenadas por `order` ASC.

### Estructura de categoría
```dart
id, name (max 40), icon (string key), tipoContenido ('con_imagenes' | 'sin_imagenes'),
order (int), isVisible (bool)
```

### Tipos de categoría
- **`con_imagenes`** (default): los productos de esta cat pueden tener imagen; se muestran en grid/carousel
- **`sin_imagenes`**: solo texto/lista; los productos NO necesitan imagen para publicar el menú

### Acciones
- Crear → modal inmediato, se guarda en la API al instante (sin SaveBar)
- Editar → modal, requiere SaveBar para confirmar
- Visibilidad → toggle ojo, requiere SaveBar
- Reordenar → modo con flechas ↑↓, requiere SaveBar
- Eliminar → confirm modal (los productos pierden la categoría pero no se eliminan)

### Modal crear/editar campos
- `name` (texto, requerido, max 40)
- `icon` — grid 6 columnas de iconos (lucide icons), ~40 opciones
- `tipoContenido` — toggle "Con imágenes" / "Sin imágenes"

### SaveBar
Barra fija al fondo que aparece cuando `dirty=true`. Botón "Guardar cambios".
Creación es inmediata; edición/visibilidad/orden requieren SaveBar.

---

## 3.2 PRODUCTOS TAB (`ProductsTab.jsx` + `ProductForm.jsx`)

### Lista de productos
- Búsqueda por nombre
- Filtro por categoría (selector)
- Productos agrupados por categoría o listos para búsqueda
- Skeleton loader durante carga
- Cada ítem: imagen/thumbnail + nombre + precio + badges (destacado, oculto)
- Acciones: editar (tap) → ProductFormPage/Sheet; toggle visible; eliminar

### Flujo crear/editar producto
1. Al crear: primero seleccionar categoría (modal/selector)
2. Formulario completo (ProductForm)
3. Guardar → `PATCH /api/menus/:id/draft` con `{ products: [...] }`

### Estructura de producto (campos del formulario)
```dart
// OBLIGATORIOS
name: String (max 50)
price: int (> 0, <= 2_000_000, en pesos COP)
categoryId: String (requerido)

// IMAGEN (requerida para publicar si la cat es 'con_imagenes')
imageUrl: String | null
// En móvil: solo subir archivo (NO generación automática, NO pegar URL) — usuario pidió quitar IA

// OPCIONALES (controlados por toggles en la UI — ProductFieldToggles)
description: String? (max 200)
components: List<String>? (ingredientes, TagInput)
tags: List<String>? (max 5)
promoActive: bool
promoPrice: int?
promoEndsAt: String? (datetime)
grupoIds: List<String>? (checkboxes de grupos activos)
sizes: List<{name, price}>?
ingredients: List<{name, price}>? (puede ser negativo)
extras: List<{name, price}>?
isVisible: bool (default true)
isFeatured: bool (default false)
```

### Opciones/variantes (VariantListEditor)
Cada variante es `{ name: String, price: int }`.
- **Tamaños**: precios positivos. El primer tamaño reemplaza el precio base.
- **Personalización de ingredientes**: precio puede ser negativo (ej: "-500" = resta)
- **Extras**: precios positivos, suma al plato

### NOTA IMPORTANTE: Sin generación de imágenes en móvil
El JSX tiene `Generar imagen automáticamente` — el usuario pidió que NO esté disponible en móvil.
En Flutter: solo `image_picker` (galería/cámara). Sin opción de pegar URL tampoco (simplificar).
Subir imagen → `POST /api/images/upload` (multipart) → devuelve URL de Cloudinary.

---

## 3.3 GRUPOS TAB (`GruposTab.jsx`)

### ¿Qué son los grupos?
Grupos informativos reutilizables que se asocian a productos.
Ejemplo: "Alérgenos" con items ["Gluten", "Lactosa"]; "Disponibilidad" con items ["Lunes a Viernes"].
Se muestran en el modal de detalle del producto en el menú público.

### Estructura de grupo
```dart
id, name (max 50), items: List<String> (max 30), isActive: bool
```

### Acciones
- Crear → nombre + lista de items (TagInput estilo), `isActive: true` por defecto
- Editar inline
- Toggle activo/inactivo
- Eliminar

### API
`PATCH /api/menus/:id/draft` con `{ grupos: [...] }`

---

## 3.4 DISEÑO TAB (`DesignTab.jsx`)

### Flujo
1. Grid 2 columnas de "skins" (temas). Cada skin tiene: `id`, `nombre`, `thumbnail`
2. Al seleccionar un skin → se muestran sus paletas de colores
3. Al seleccionar paleta → vista previa viva del menú con ese tema

### API para obtener temas
`GET /api/temas` → lista de `{ id, nombre, paletas: [{ id, nombre, colores }] }`

### Guardado
`PATCH /api/menus/:id/draft` con `{ skinId, paletteId }`
Guardado inmediato (sin SaveBar).

---

## 3.5 INFO DEL NEGOCIO (`editor/InfoTab.jsx` / `MenuInfoPage.jsx`)

Es la pantalla de "Info negocio" accesible desde el top bar del editor.

### Secciones
1. **Identidad**: name, slogan, bannerUrl, logoUrl (con FileUpload deferred)
2. **Contacto**: phone, whatsapp, schedule, rating (0-5, visual), reviews (número visual), ubicación en cascada
3. **Redes sociales**: instagram, facebook, tiktok, website
4. **Etiquetas**: tags[] del negocio (pills en banner)
5. **URL del menú**: slug editable — guarda con botón independiente "Guardar URL"
   - Al cambiar slug: aviso "La URL anterior seguirá funcionando (redirección automática)"

### SaveBar
Barra fija al fondo. Aplica a todos los campos EXCEPTO slug (que tiene su propio botón).

### APIs
- `PATCH /api/menus/:id/draft` con `{ info: { ...campos } }`
- `PUT /api/menus/:id/slug` con `{ slug: string }` (para cambiar URL)
- Upload imágenes: `POST /api/images/upload` (multipart)

---

## 3.6 PUBLICAR TAB (`PublishTab.jsx`)

### Lógica de estados (muy importante)

**Requisitos para publicar (canPublish)**:
- `draft.info.logoUrl` existe
- `draft.info.bannerUrl` existe
- Al menos 1 categoría
- Al menos 1 producto
- Todos los productos tienen imagen (si su categoría es `con_imagenes`) Y tienen precio

**Banners contextuales según estado de suscripción**:
| Estado | Color | Acción |
|--------|-------|--------|
| `TRIAL_FREE` | verde | "Prueba activa, X días restantes" — botón "Ver plan" |
| `PAYMENT_REMINDER` | ámbar | "Período de pago: X días" — botón "Pagar ahora" |
| `PAST_DUE` | naranja | "Vencida, X días de gracia" — botón "Pagar" |
| `PENDING_PAYMENT` | violeta | "Pago pendiente" — botón "Intentar de nuevo" |
| `WAITING_ACTIVATION` | azul | "Pago aprobado, activando..." (spinner) |
| `SUSPENDED/CANCELED` | rojo | "Ya usaste tu prueba" |

**Plan badge** (si tiene suscripción): "Plan Básico" o "Plan Avanzado" + "X/Y productos"

**Upgrade prompt**: si `tipoPlan === 'basico' && productCount >= limiteProductos`

### Cupón
- Si `!tieneCupon`: campo de texto para ingresar código + botón "Aplicar"
- `POST /api/cupones/aplicar` con `{ menuId, codigo }`
- Errores: 404=no encontrado, 409=ya usado, 422=ya tienes cupón activo
- Si cupón `PENDIENTE`: banner "X días listos, se activan al publicar"
- Si cupón `ACTIVO`: banner "X días restantes"

### Botón Publicar — lógica de qué hace
- Si `tieneCupon || (!isFirstPublish && !isSuspended)` → confirm modal simple → `POST /api/menus/:id/publish`
- Si `isFirstPublish || isSuspended` → abre modal de pricing (elegir plan)

### Modal de pricing (primer publish / suspendido)
- Si `!trialUsado`: opción "Prueba gratuita 7 días" + planes de pago
- Si `trialUsado`: solo planes de pago (Básico, Avanzado)
- "Iniciar prueba" → llama directamente a `onPublish()` (`POST /api/menus/:id/publish`)
- "Pagar" → `POST /api/menus/:id/checkout` → devuelve `{ checkoutUrl }` → abrir en WebView/browser

### Preview
Dentro de la app (en Flutter): navega a `PublicMenuScreen` con los datos del draft.

### APIs
- `POST /api/menus/:id/publish`
- `POST /api/menus/:id/checkout` → `{ checkoutUrl }`
- `POST /api/cupones/aplicar` → `{ menuId, codigo }`
- `GET /api/suscripcion/precio` → `{ planes: { basico: { display }, avanzado: { display } }, precioBasicoCentavos, precioAvanzadoCentavos }`

---

## 3.7 COLABORADORES TAB (`ColaboradoresTab.jsx`)

### Funcionalidades
- Listar colaboradores actuales: avatar + nombre
- Botón "Invitar colaborador" → modal con campo de código de 6 caracteres
- Remover colaborador (confirm)

### APIs
- `GET /api/colaboraciones/:menuId` → lista de colaboradores
- `POST /api/colaboraciones/:menuId/invitar` con `{ codigo }`
- `DELETE /api/colaboraciones/:menuId/:userId`

---

## 4. SUSCRIPCIÓN Y PAGO (`SuscripcionPage.jsx`)

### Campos de la respuesta `GET /api/suscripcion/:menuId`
```dart
estado: String? (null | 'PENDING_PAYMENT' | 'WAITING_ACTIVATION' | 'TRIAL_FREE' |
                 'PAYMENT_REMINDER' | 'ACTIVE' | 'PAST_DUE' | 'SUSPENDED' | 'CANCELED')
tipoPlan: String? ('basico' | 'avanzado')
limiteProductos: int
diasRestantes: int
trialUsado: bool
pruebaInicio: DateTime?
pruebaFin: DateTime?
periodoInicio: DateTime?
periodoFin: DateTime?
precioActualCentavos: int
precioBasicoCentavos: int
precioAvanzadoCentavos: int
limiteBasicoPlan: int (default 30)
limiteAvanzadoPlan: int (default 100)
pagos: List<{
  id, montoCentavos, estado ('APPROVED'|'PENDING'|'DECLINED'|'ERROR'|'VOIDED'),
  metodo ('CARD'|'PSE'|'NEQUI'|'BANCOLOMBIA_TRANSFER'|'BANCOLOMBIA_COLLECT'),
  creadoEn, periodoInicio, periodoFin, wompiId
}>
```

### Wompi — integración
El backend genera una URL de checkout de Wompi.
- `POST /api/suscripcion/:menuId/pago` → `{ checkoutUrl }` (para renovar pago existente)
- `POST /api/suscripcion/:menuId/checkout` con `{ plan?: 'basico'|'avanzado' }` → `{ checkoutUrl }` (primer pago)
- `POST /api/suscripcion/:menuId/upgrade` → `{ checkoutUrl }` (subir de básico a avanzado)

**En web**: `window.open(checkoutUrl, '_blank')` — abre en nueva pestaña.
**En Flutter**: abrir en `WebView` interno (usando `webview_flutter`) con detección del redirect final de Wompi. Cuando el usuario complete o cancele, Wompi redirige a una URL con `?id=TRANSACTION_ID`. Detectar esa URL en el WebView y cerrar el WebView, luego hacer polling del estado cada 4 segundos hasta que cambie de `PENDING_PAYMENT`/`WAITING_ACTIVATION`.

### Polling automático
El web usa `setInterval(4000)` mientras `estado` es `PENDING_PAYMENT` o `WAITING_ACTIVATION`.
En Flutter: usar `Timer.periodic(Duration(seconds: 4), ...)` con auto-cancelación cuando estado cambia.

### Estados de pago y su color
- `APPROVED` → verde
- `PENDING` → ámbar
- `DECLINED` / `ERROR` → rojo
- `VOIDED` → gris

### Sin suscripción — selector de plan
- Si `!trialUsado`: tarjeta "Prueba gratuita" (7 días, gratis, sin tarjeta)
- Siempre: tarjeta "Básico" con precio y límite de productos
- Siempre: tarjeta "Avanzado" con precio y límite de productos
- Selección tipo radio button
- Si se elige "gratuito": botón "Iniciar prueba gratuita" → navega al editor (el publish activa la prueba)
- Si se elige "basico"/"avanzado": botón "Suscribirme" → `iniciarCheckout(menuId, plan)`

---

## 5. MENÚ PÚBLICO — PREVIEW (`PublicMenuPage.jsx` + `components/MenuPage.jsx`)

### API
`GET /api/public/menus/:slug` → estructura completa del menú publicado

### Componentes en orden visual (de arriba a abajo)
1. **Navbar**: búsqueda + botón compartir + QR
2. **Banner**: imagen de fondo + logo + nombre + slogan + rating + reviews + tags + teléfono
3. **CategoryTabs**: tabs horizontales scrolleables, "Todo" + cada categoría visible
4. **FeaturedRow**: fila horizontal de productos con `isFeatured=true` (si existen)
5. **Productos**: grid (con_imagenes) o lista (sin_imagenes), filtrado por tab activo
6. **ReviewsSection**: total de "Me encanta" + botón
7. **Footer**: links de redes sociales

### Modos de vista (solo para categorías `con_imagenes`)
- Grid (2 columnas)
- Lista
- Carousel (scroll horizontal)
El usuario puede cambiar el modo con botones en el header de la sección.

### Modal de producto
Al tocar una tarjeta de producto:
- Imagen grande
- Nombre, descripción, precio
- Si `promoActive`: precio tachado + precio promo
- Tags (primeras 2)
- Grupos informativos asociados
- Rating del producto (si tiene votos)
- Tamaños (VariantSelector)
- Personalizaciones (VariantSelector)
- Extras (VariantSelector)
- Botón "Me encanta este plato" → `POST /api/interacciones/:slug/calificar` con `{ productId }`
- Botón compartir, botón teléfono (si hay)

### Búsqueda
Filtra productos por name, description, tags (client-side).

### Interacciones
- Me encanta menú: `POST /api/interacciones/:slug/me-encanta`
- Calificar producto: `POST /api/interacciones/:slug/productos/:pid/calificar`

---

## 6. ARQUITECTURA FLUTTER PROPUESTA

### Estructura de carpetas
```
lib/
  modules/
    mis_menus/
      mis_menus_screen.dart        ← lista de menús
      widgets/
        menu_row_widget.dart
        delete_confirm_sheet.dart
    crear_menu/
      crear_menu_screen.dart       ← wizard 5 pasos
      steps/
        step_categoria.dart
        step_identidad.dart
        step_contacto.dart
        step_redes.dart
        step_diseno.dart
      services/
        crear_menu_service.dart
    editor/
      menu_editor_screen.dart      ← pantalla con tabs
      tabs/
        categorias_tab.dart
        productos_tab.dart
        grupos_tab.dart
        diseno_tab.dart
        publicar_tab.dart
        colaboradores_tab.dart
      screens/
        info_negocio_screen.dart
        product_form_screen.dart
      widgets/
        category_form_sheet.dart
        product_list_item.dart
        variant_list_editor.dart
        save_bar_widget.dart
        icon_picker_grid.dart
    suscripcion/
      suscripcion_screen.dart
      suscripcion_service.dart
      wompi_webview_screen.dart
    menu_publico/
      (ya existe public_menu_screen.dart)
```

### State management
Usar `StatefulWidget` simple con `setState` — el proyecto ya no usa Riverpod.
Para el editor, pasar el menú como parámetro y mutar localmente antes de enviar al API.

### Subida de imágenes
`POST /api/images/upload` — multipart form data.
Usar `image_picker` (ya en `pubspec.yaml`) + `http.MultipartRequest`.
Solo galería/cámara en móvil. Sin generación automática. Sin pegar URL.

### Formato de precios
COP: `NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(precio)`
O simplemente: `'\$${precio.toLocaleString()}'` para simplificar.

---

## 7. ORDEN DE IMPLEMENTACIÓN (módulo por módulo)

### BLOQUE 1 — Mis Menús + Crear Menú (primer entregable)
1. `MisMenusScreen` — lista, acciones, modal eliminar
2. `CrearMenuScreen` — wizard 5 pasos (categoría, identidad, contacto, redes, diseño)
3. Servicios: `menuService.getAll()`, `menuService.create()`, `menuService.remove()`

### BLOQUE 2 — Editor (categorías + productos)
4. `MenuEditorScreen` — top bar, tabs
5. `InfoNegocioScreen` — todos los campos, SaveBar, upload imágenes
6. `CategoriasTab` — CRUD, reordenar, tipos, icon picker
7. `ProductosTab` — lista con búsqueda/filtro
8. `ProductFormScreen` — formulario completo sin generación de imágenes

### BLOQUE 3 — Editor (grupos + diseño + publicar)
9. `GruposTab` — CRUD grupos
10. `DisenoTab` — selector skin + paleta + preview vivo
11. `PublicarTab` — estado, cupón, requisitos, botón publicar
12. `ColaboradoresTab` — invitar y listar

### BLOQUE 4 — Suscripción y pago
13. `SuscripcionScreen` — estado, historial, planes
14. `WompiWebviewScreen` — WebView con detección de redirect
15. Polling automático de estado

### BLOQUE 5 — Preview público (ya parcialmente implementado)
16. Integrar preview dentro del editor (navegar a PublicMenuScreen con draft data)

---

## 8. NOTAS IMPORTANTES

1. **InfoTab vs CreateMenuPage**: Los campos de identidad/contacto/redes se usan TANTO en el wizard de creación como en la edición (InfoTab). Crear widgets reutilizables.

2. **SaveBar**: Barra fija al fondo que aparece cuando hay cambios sin guardar. Implementar como widget posicionado con `AnimatedPositioned` o `Align`.

3. **Deferred uploads**: En el wizard de creación y en InfoTab, las imágenes se seleccionan localmente y solo se suben al servidor cuando el usuario confirma (crea/guarda). Guardar el `File` objeto en el estado y hacer la subida en el handler de save.

4. **Slug validation**: regex `^[a-z0-9-]+$`, min 3, max 50. Auto-generado desde el nombre con `slugify` pero respeta edición manual.

5. **Categorías y productos**: La creación de una categoría se guarda inmediatamente (sin SaveBar). La edición, visibilidad y reordenamiento requieren SaveBar.

6. **Wompi en Flutter**: Usar `webview_flutter` con `NavigationDelegate` que detecta la URL de retorno de Wompi. La URL tiene parámetro `?id=TX_ID`. Al detectarla, cerrar el WebView y hacer polling.

7. **Productos y categoría**: Para crear un producto, primero se selecciona la categoría. El formulario luego sabe si mostrar o no el campo de imagen (según `tipoContenido` de la categoría seleccionada).
