# Light DOCX Viewer

[English](README.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | **Español** | [Français](README.fr.md)

Un lector nativo y ligero de archivos `.docx` para macOS que muestra **el texto y las imágenes insertadas en orden de lectura**, sin recrear el diseño de página de Microsoft Word.

Pensado para un flujo de trabajo sencillo: abrir un documento, leer su contenido, copiar texto y copiar imágenes insertadas a otra aplicación.

> **Estado: prototipo inicial (v0.1.2).** Se compila y se ejecuta en macOS. Es posible que algunos archivos DOCX no se muestren por completo. Se agradecen las contribuciones y los informes de errores.

## Características

- **Lee archivos DOCX** en una ventana nativa de AppKit.
- **Conserva el orden del contenido** para el texto y las imágenes insertadas compatibles (por ejemplo: párrafo → imagen → párrafo).
- **Copia texto** seleccionándolo y pulsando `⌘C`.
- **Copia imágenes insertadas** haciendo clic en una imagen y pulsando `⌘C`; después pégala con `⌘V` en otra aplicación.
- **Solo lectura** por diseño: no permite editar ni guardar documentos.
- **No requiere Microsoft Word, Pages, Python ni dependencias de terceros** para ejecutarse.
- **Icono de app personalizado** generado automáticamente durante la compilación.

## Requisitos

- macOS 12 o posterior (según la configuración de `Info.plist`)
- Apple Command Line Tools para compilar (`swiftc`, `sips`, `iconutil`)

## Compilar desde el código fuente

1. Clona o descarga este repositorio.
2. Instala las Command Line Tools si es necesario:

   ```bash
   xcode-select --install
   ```

3. En Terminal, entra en la carpeta del proyecto y ejecuta:

   ```bash
   bash build.command
   ```

El script compila `Light DOCX Viewer.app` en la carpeta del proyecto, genera `AppIcon.icns` a partir de `AppIcon.png` e intenta abrir la app.

**Nota:** Se trata de un prototipo compilado localmente y sin firmar, no de una versión notarizada de macOS. Un icono de app tachado no indica necesariamente un problema de cuarentena de Gatekeeper; puede indicar que el paquete de la app es incompatible o no válido. Revisa primero la salida de la compilación y el paquete de la app en lugar de saltarte la configuración de seguridad de macOS.

## Firma y notarización (opcional)

Para distribuir la app de modo que se abra en otros Mac sin avisos de Gatekeeper, hay que firmarla con un certificado **Developer ID Application** y notarizarla con Apple. Se necesita una cuenta de pago de Apple Developer.

1. Comprueba que tienes un certificado `Developer ID Application` en el llavero de inicio de sesión (`security find-identity -v -p codesigning`).
2. Crea una contraseña específica para apps en account.apple.com y guarda las credenciales de notarización en el llavero (solo una vez):

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. Compila y, después, firma, notariza y grapa:

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

El script firma una copia de la app con Hardened Runtime, la envía con `notarytool`, grapa el ticket de notarización, la comprueba con `spctl` y guarda `LightDOCXViewer-<versión>.zip` en la carpeta del proyecto, listo para adjuntarlo a una GitHub Release.

- Para firmar sin notarizar (pruebas locales):

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  Esto genera `LightDOCXViewer-<versión>-unnotarized.zip`.
- Variables de entorno opcionales: `SIGN_IDENTITY` (por defecto, la primera identidad Developer ID Application) y `NOTARY_PROFILE` (por defecto, `notary-profile`).
- La firma se realiza en un directorio temporal porque iCloud Drive y otros proveedores de archivos vuelven a añadir metadatos del Finder en las carpetas sincronizadas, lo que hace fallar a `codesign`.
- Nunca incluyas en el repositorio tu Apple ID, tu contraseña específica para apps ni los zip de las versiones.

## Uso

Abre la app y pulsa `⌘O` para elegir un archivo `.docx`. También puedes seleccionar un DOCX en el Finder y elegir **Abrir con → Light DOCX Viewer**.

Para copiar texto, selecciónalo y pulsa `⌘C`. Para copiar una imagen, haz clic una vez en la imagen insertada, pulsa `⌘C` y pégala en otra aplicación.

Si quieres que sea el lector predeterminado de DOCX, selecciona un `.docx` en el Finder, elige **Obtener información → Abrir con**, selecciona esta app y haz clic en **Cambiar todo**. Hazlo solo después de comprobar que la app funciona correctamente en tu Mac.

## Limitaciones conocidas

Es un **lector centrado en el contenido**, no un renderizador fiel al diseño de Word.

- Admite el texto básico, los saltos de línea, el texto de tablas y las imágenes DrawingML insertadas compatibles del documento principal.
- No reproduce saltos de página, fuentes, márgenes, columnas ni bordes de tablas como en Word.
- Los archivos DOCX se extraen en un directorio temporal que se elimina inmediatamente después de cargarlos.
- Las imágenes flotantes, las imágenes VML antiguas, los cuadros de texto, los encabezados, los pies de página, las notas al pie, los comentarios y las imágenes vinculadas externamente pueden faltar o aparecer desordenados.
- La copia de imágenes está pensada para imágenes cargadas como adjuntos en línea; su comportamiento aún debe probarse con distintos archivos DOCX y aplicaciones de destino.
- Algunos archivos DOCX pueden no analizarse o no mostrarse por completo.
- Todavía no se incluyen pruebas automatizadas, notarización ni binarios firmados.

## Icono de la app

- Imagen original: `AppIcon.png` (incluida en el repositorio).
- `build.command` usa las herramientas integradas de macOS `sips` e `iconutil` para generar `AppIcon.icns` en todos los tamaños estándar y lo coloca en `.app/Contents/Resources`.
- `Info.plist` establece `CFBundleIconFile` como `AppIcon`.
- Si el Finder sigue mostrando un icono antiguo, mueve la app a otra ubicación o reinicia el Finder para actualizar la caché de iconos.

## Estructura del proyecto

```text
.
├── LightDOCXViewer.swift   # Interfaz AppKit, análisis del XML de DOCX y soporte del portapapeles
├── AppIcon.png             # Imagen original del icono de la app para macOS
├── Info.plist              # Metadatos del paquete de la app y asociación de archivos DOCX
├── build.command           # Compilación para macOS y generación del icono con un solo comando
├── sign-and-notarize.command  # Firma con Developer ID, notarización y grapado
├── LICENSE                 # Licencia MIT
├── README.md               # Documentación en inglés
└── README.*.md             # Documentación traducida
```

## Cómo funciona

Los archivos DOCX son contenedores ZIP. La app extrae temporalmente un DOCX con la herramienta `ditto` de macOS, lee `word/document.xml` y sus relaciones de imágenes con `XMLParser` y, después, muestra el texto y las imágenes mediante `NSTextView` y `NSTextAttachment`. Tras la carga, elimina el directorio de extracción temporal. Para copiar imágenes se usa el portapapeles de macOS.

Se prioriza intencionadamente la lectura y la copia sencillas por encima de un renderizado completo de Office Open XML.

## Contribuir

Se agradecen los informes de errores, los documentos de ejemplo reproducibles (sin información sensible), las correcciones y las mejoras de compatibilidad. Serían especialmente útiles la verificación de compilaciones en macOS, un manejo más seguro de archivos comprimidos y una compatibilidad más amplia con imágenes DOCX.

## Licencia

Publicado bajo la [Licencia MIT](LICENSE).

Microsoft y Word son marcas comerciales de Microsoft Corporation. Este proyecto no está afiliado a Microsoft ni cuenta con su respaldo.
