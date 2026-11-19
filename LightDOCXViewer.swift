import Cocoa
import UniformTypeIdentifiers

/// Stores the full-resolution image so copying never uses the reduced display preview.
final class DocumentImageAttachment: NSTextAttachment {
    let originalImage: NSImage

    /// Creates an attachment scaled for reading while retaining the original pixels.
    init(image: NSImage, maxWidth: CGFloat = 760) {
        self.originalImage = image
        super.init(data: nil, ofType: nil)
        let source = image.size
        let scale = source.width > 0 ? min(1, maxWidth / source.width) : 1
        self.image = image
        self.bounds = CGRect(x: 0, y: 0, width: source.width * scale, height: source.height * scale)
    }

    /// Required for NSCoding-based attachment initialization; unused in normal opening.
    required init?(coder: NSCoder) { return nil }
}

/// Parses document relationships and records image paths keyed by relationship ID.
final class RelationshipsParser: NSObject, XMLParserDelegate {
    private(set) var paths: [String: String] = [:]

    /// Extracts only image relationships from start tags, ignoring unsupported targets.
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        guard elementName == "Relationship" || elementName.hasSuffix(":Relationship"),
              let type = attributeDict["Type"], type.hasSuffix("/image"),
              let id = attributeDict["Id"], let target = attributeDict["Target"],
              attributeDict["TargetMode"] != "External" else { return }
        paths[id] = target
    }
}

/// Converts the main WordprocessingML document into ordered text and image events.
final class DocumentXMLParser: NSObject, XMLParserDelegate {
    enum Event { case text(String), image(String), lineBreak }
    private(set) var events: [Event] = []
    private var collectingText = false
    private var textBuffer = ""
    private var inParagraph = false

    /// Begins collecting paragraphs, text runs, embedded image references, and line breaks.
    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        switch elementName {
        case "w:p": inParagraph = true
        case "w:t": collectingText = true; textBuffer = ""
        case "w:tab": if inParagraph { events.append(.text("\t")) }
        case "w:br", "w:cr": if inParagraph { events.append(.text("\n")) }
        case "a:blip":
            if inParagraph, let id = attributeDict["r:embed"] { events.append(.image(id)) }
        default: break
        }
    }

    /// Accumulates character chunks, which XMLParser may split arbitrarily.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if collectingText { textBuffer += string }
    }

    /// Finalizes text spans and paragraph boundaries in original document order.
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "w:t":
            if !textBuffer.isEmpty { events.append(.text(textBuffer)) }
            textBuffer = ""; collectingText = false
        case "w:p": events.append(.lineBreak); inParagraph = false
        default: break
        }
    }
}

/// Extracts a DOCX using macOS's built-in ditto and renders only its inline reading order.
enum DOCXReader {
    enum ReaderError: LocalizedError {
        case missingDocument, invalidXML(String), extractionFailed(String)
        var errorDescription: String? {
            switch self {
            case .missingDocument: return "word/document.xml was not found in the DOCX."
            case .invalidXML(let name): return "Unable to parse document content: \(name)"
            case .extractionFailed(let message): return "Unable to extract DOCX: \(message)"
            }
        }
    }

    /// Opens a DOCX archive and returns attributed content with original images attached.
    static func read(_ url: URL) throws -> NSAttributedString {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", url.path, root.path]
        let errors = Pipe()
        process.standardError = errors
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
            throw ReaderError.extractionFailed(message)
        }

        let documentURL = root.appendingPathComponent("word/document.xml")
        guard let documentData = try? Data(contentsOf: documentURL) else { throw ReaderError.missingDocument }
        let documentParser = DocumentXMLParser()
        let xml = XMLParser(data: documentData)
        xml.delegate = documentParser
        guard xml.parse() else { throw ReaderError.invalidXML(xml.parserError?.localizedDescription ?? "document.xml") }

        var relationships: [String: String] = [:]
        let relsURL = root.appendingPathComponent("word/_rels/document.xml.rels")
        if let data = try? Data(contentsOf: relsURL) {
            let parser = RelationshipsParser()
            let xmlRels = XMLParser(data: data)
            xmlRels.delegate = parser
            if xmlRels.parse() { relationships = parser.paths }
        }

        let output = NSMutableAttributedString(string: "")
        let normal: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.textColor
        ]
        let imageBase = root.appendingPathComponent("word", isDirectory: true).standardizedFileURL
        for event in documentParser.events {
            switch event {
            case .text(let text): output.append(NSAttributedString(string: text, attributes: normal))
            case .lineBreak: output.append(NSAttributedString(string: "\n", attributes: normal))
            case .image(let relationshipID):
                guard let target = relationships[relationshipID] else { continue }
                let candidate = imageBase.appendingPathComponent(target).standardizedFileURL
                guard candidate.path.hasPrefix(imageBase.path + "/"),
                      let image = NSImage(contentsOf: candidate) else { continue }
                let attachment = DocumentImageAttachment(image: image)
                output.append(NSAttributedString(attachment: attachment))
            }
        }
        return output
    }
}

/// Read-only text view that copies a clicked inline image as actual image data.
final class ReaderTextView: NSTextView {
    /// Selects an image attachment when the user clicks it, enabling Command-C copying.
    override func mouseDown(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard let manager = layoutManager, let container = textContainer else {
            super.mouseDown(with: event); return
        }
        let point = NSPoint(x: location.x - textContainerOrigin.x, y: location.y - textContainerOrigin.y)
        let glyph = manager.glyphIndex(for: point, in: container)
        let character = manager.characterIndexForGlyph(at: glyph)
        if character < textStorage?.length ?? 0,
           textStorage?.attribute(.attachment, at: character, effectiveRange: nil) is DocumentImageAttachment {
            setSelectedRange(NSRange(location: character, length: 1))
            return
        }
        super.mouseDown(with: event)
    }

    /// Copies the original image to the system clipboard, otherwise uses normal text copying.
    override func copy(_ sender: Any?) {
        let range = selectedRange()
        if range.length == 1, range.location < (textStorage?.length ?? 0),
           let attachment = textStorage?.attribute(.attachment, at: range.location, effectiveRange: nil) as? DocumentImageAttachment {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.writeObjects([attachment.originalImage])
            return
        }
        super.copy(sender)
    }
}

/// Owns the app window, Open command, Finder file-opening, and document presentation.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var textView: ReaderTextView!

    /// Creates a native read-only viewer and opens any file passed on the command line.
    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 720),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "Light DOCX Viewer"
        window.center()
        let scroll = NSScrollView(frame: window.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder
        let viewer = ReaderTextView(frame: scroll.bounds)
        viewer.isEditable = false
        viewer.isSelectable = true
        viewer.isRichText = true
        viewer.drawsBackground = true
        viewer.backgroundColor = .textBackgroundColor
        viewer.textContainerInset = NSSize(width: 24, height: 28)
        viewer.isVerticallyResizable = true
        viewer.isHorizontallyResizable = false
        viewer.autoresizingMask = [.width]
        viewer.textContainer?.widthTracksTextView = true
        viewer.textContainer?.containerSize = NSSize(width: scroll.bounds.width, height: CGFloat.greatestFiniteMagnitude)
        scroll.documentView = viewer
        window.contentView?.addSubview(scroll)
        window.makeKeyAndOrderFront(nil)
        self.window = window
        self.textView = viewer
        buildMenu()

        if CommandLine.arguments.count > 1 {
            showDocument(URL(fileURLWithPath: CommandLine.arguments[1]))
        } else {
            showWelcome()
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Accepts Finder's Open With / double-click document requests.
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        showDocument(URL(fileURLWithPath: filename))
        return true
    }

    /// Sets up standard Open, Copy, and Quit shortcuts without a storyboard.
    private func buildMenu() {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Light DOCX Viewer", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        let fileItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let open = NSMenuItem(title: "Open DOCX…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        open.target = self
        fileMenu.addItem(open)
        fileItem.submenu = fileMenu
        mainMenu.addItem(fileItem)

        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu
        mainMenu.addItem(editItem)
        NSApp.mainMenu = mainMenu
    }

    /// Presents an open panel restricted to DOCX files.
    @objc private func openDocument(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "docx")!]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url { showDocument(url) }
    }

    /// Renders a friendly instruction before the first document is opened.
    private func showWelcome() {
        textView.textStorage?.setAttributedString(NSAttributedString(
            string: "Press ⌘O to open a DOCX file.\n\nClick an image and press ⌘C to paste it into another app.\nText can be selected and copied directly.",
            attributes: [.font: NSFont.systemFont(ofSize: 17)]))
    }

    /// Loads a document and displays a native alert if the archive cannot be parsed.
    private func showDocument(_ url: URL) {
        do {
            let content = try DOCXReader.read(url)
            textView.textStorage?.setAttributedString(content)
            window.title = "\(url.lastPathComponent) — Light DOCX Viewer"
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            textView.scrollRangeToVisible(NSRange(location: 0, length: 0))
        } catch {
            let alert = NSAlert()
            alert.messageText = "Unable to Open DOCX"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
    }

    /// Quits the standalone viewer when its final window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

/// Starts the Cocoa run loop without requiring Xcode project files or storyboards.
let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
