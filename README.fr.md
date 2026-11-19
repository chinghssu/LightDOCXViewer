# Light DOCX Viewer

[English](README.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md) | [Deutsch](README.de.md) | [Español](README.es.md) | **Français**

Un lecteur natif et léger de fichiers `.docx` pour macOS, qui affiche **le texte et les images intégrées dans l'ordre de lecture**, sans reproduire la mise en page de Microsoft Word.

Conçu pour un usage simple : ouvrir un document, lire son contenu, copier du texte et copier les images intégrées vers une autre application.

> **Statut : prototype précoce (v0.1.2).** Se compile et s'exécute sous macOS. Certains fichiers DOCX peuvent ne pas s'afficher entièrement. Les contributions et les rapports de bugs sont les bienvenus.

## Fonctionnalités

- **Lecture de fichiers DOCX** dans une fenêtre AppKit native.
- **Respect de l'ordre du contenu** pour le texte et les images intégrées pris en charge (par exemple : paragraphe → image → paragraphe).
- **Copie de texte** : sélectionnez le texte et appuyez sur `⌘C`.
- **Copie des images intégrées** : cliquez sur une image, appuyez sur `⌘C`, puis collez-la avec `⌘V` dans une autre application.
- **Lecture seule** par conception : aucune modification ni sauvegarde de documents.
- **Aucun besoin de Microsoft Word, Pages, Python ou de dépendances tierces** pour exécuter l'application.
- **Icône d'application personnalisée** générée automatiquement lors de la compilation.

## Configuration requise

- macOS 12 ou version ultérieure (selon `Info.plist`)
- Apple Command Line Tools pour la compilation (`swiftc`, `sips`, `iconutil`)

## Compiler depuis les sources

1. Clonez ou téléchargez ce dépôt.
2. Installez les Command Line Tools si nécessaire :

   ```bash
   xcode-select --install
   ```

3. Dans le Terminal, placez-vous dans le dossier du projet et exécutez :

   ```bash
   bash build.command
   ```

Le script compile `Light DOCX Viewer.app` dans le dossier du projet, génère `AppIcon.icns` à partir de `AppIcon.png` et tente d'ouvrir l'application.

**Remarque :** il s'agit d'un prototype compilé localement et non signé, et non d'une version macOS notarisée. Une icône d'application barrée n'indique pas forcément une mise en quarantaine par Gatekeeper ; elle peut signaler un paquet d'application incompatible ou invalide. Vérifiez d'abord la sortie de la compilation et le paquet de l'application plutôt que de contourner les réglages de sécurité de macOS.

## Signature et notarisation (facultatif)

Pour distribuer l'application afin qu'elle s'ouvre sur d'autres Mac sans avertissement de Gatekeeper, il faut la signer avec un certificat **Developer ID Application** et la faire notariser par Apple. Un compte Apple Developer payant est nécessaire.

1. Vérifiez qu'un certificat `Developer ID Application` se trouve dans votre trousseau de session (`security find-identity -v -p codesigning`).
2. Créez un mot de passe pour app sur account.apple.com, puis enregistrez les identifiants de notarisation dans le trousseau (une seule fois) :

   ```bash
   xcrun notarytool store-credentials "notary-profile" \
     --apple-id "<Apple ID>" --team-id "<Team ID>"
   ```

3. Compilez, puis signez, notarisez et agrafez :

   ```bash
   bash build.command
   bash sign-and-notarize.command
   ```

Le script signe une copie de l'application avec le Hardened Runtime, la soumet avec `notarytool`, agrafe le ticket de notarisation, la vérifie avec `spctl` et écrit `LightDOCXViewer-<version>.zip` dans le dossier du projet, prêt à être joint à une GitHub Release.

- Pour signer sans notariser (tests locaux) :

  ```bash
  bash sign-and-notarize.command --sign-only
  ```

  Cela produit `LightDOCXViewer-<version>-unnotarized.zip`.
- Variables d'environnement facultatives : `SIGN_IDENTITY` (par défaut, la première identité Developer ID Application) et `NOTARY_PROFILE` (par défaut, `notary-profile`).
- La signature s'effectue dans un répertoire temporaire, car iCloud Drive et d'autres fournisseurs de fichiers rajoutent sans cesse des métadonnées Finder dans les dossiers synchronisés, ce qui fait échouer `codesign`.
- Ne commitez jamais votre identifiant Apple, votre mot de passe pour app ni les fichiers zip de publication dans le dépôt.

## Utilisation

Ouvrez l'application et appuyez sur `⌘O` pour choisir un fichier `.docx`. Vous pouvez aussi sélectionner un DOCX dans le Finder et choisir **Ouvrir avec → Light DOCX Viewer**.

Pour copier du texte, sélectionnez-le et appuyez sur `⌘C`. Pour copier une image, cliquez une fois sur l'image intégrée, appuyez sur `⌘C`, puis collez-la dans une autre application.

Pour en faire le lecteur DOCX par défaut, sélectionnez un fichier `.docx` dans le Finder, choisissez **Lire les informations → Ouvrir avec**, sélectionnez cette application et cliquez sur **Tout modifier**. Ne le faites qu'après avoir vérifié que l'application fonctionne correctement sur votre Mac.

## Limitations connues

Il s'agit d'un **lecteur axé sur le contenu**, et non d'un moteur de rendu fidèle à la mise en page de Word.

- Prend en charge le texte de base, les sauts de ligne, le texte des tableaux et les images DrawingML intégrées prises en charge du document principal.
- Ne reproduit pas les sauts de page, les polices, les marges, les colonnes ni les bordures de tableaux comme dans Word.
- Les fichiers DOCX sont extraits dans un répertoire temporaire, supprimé immédiatement après le chargement.
- Les images flottantes, les anciennes images VML, les zones de texte, les en-têtes, les pieds de page, les notes de bas de page, les commentaires et les images liées en externe peuvent être absents ou mal ordonnés.
- La copie d'images concerne les images chargées en tant que pièces jointes intégrées ; son comportement doit encore être testé avec différents fichiers DOCX et applications de destination.
- Certains fichiers DOCX peuvent ne pas être analysés ou ne pas s'afficher entièrement.
- Aucune suite de tests automatisés, notarisation ou binaire signé n'est encore fourni.

## Icône de l'application

- Image source : `AppIcon.png` (incluse dans le dépôt).
- `build.command` utilise les outils intégrés de macOS `sips` et `iconutil` pour générer `AppIcon.icns` dans toutes les tailles standard et le place dans `.app/Contents/Resources`.
- `Info.plist` définit `CFBundleIconFile` sur `AppIcon`.
- Si le Finder affiche encore une ancienne icône, déplacez l'application à un autre emplacement ou redémarrez le Finder pour actualiser le cache des icônes.

## Structure du projet

```text
.
├── LightDOCXViewer.swift   # Interface AppKit, analyse du XML DOCX et prise en charge du presse-papiers
├── AppIcon.png             # Image source de l'icône de l'application macOS
├── Info.plist              # Métadonnées du paquet d'application et association des fichiers DOCX
├── build.command           # Compilation macOS et génération de l'icône en une seule commande
├── sign-and-notarize.command  # Signature Developer ID, notarisation et agrafage
├── LICENSE                 # Licence MIT
├── README.md               # Documentation en anglais
└── README.*.md             # Documentation traduite
```

## Fonctionnement

Les fichiers DOCX sont des conteneurs ZIP. L'application extrait temporairement un DOCX avec l'outil `ditto` de macOS, lit `word/document.xml` et ses relations d'images avec `XMLParser`, puis affiche le texte et les images via `NSTextView` et `NSTextAttachment`. Le répertoire d'extraction temporaire est supprimé après le chargement. La copie d'images utilise le presse-papiers de macOS.

Le projet privilégie volontairement une lecture et une copie simples plutôt qu'un rendu complet d'Office Open XML.

## Contribuer

Les rapports de bugs, les documents d'exemple reproductibles (sans informations sensibles), les correctifs et les améliorations de compatibilité sont les bienvenus. La vérification des compilations sous macOS, une gestion plus sûre des archives et une prise en charge plus large des images DOCX seraient particulièrement utiles.

## Licence

Publié sous [licence MIT](LICENSE).

Microsoft et Word sont des marques commerciales de Microsoft Corporation. Ce projet n'est ni affilié à Microsoft ni approuvé par Microsoft.
