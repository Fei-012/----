import AppKit

struct PetDefinition {
    let id: String
    let fileName: String
    let defaultOrigin: NSPoint
    let size: NSSize
}

final class PetImageView: NSImageView {
    weak var petWindow: NSWindow?
    var onPress: (() -> Void)?

    override func mouseDown(with event: NSEvent) {
        onPress?()
        petWindow?.performDrag(with: event)
    }
}

final class PetWindowController: NSWindowController {
    let pet: PetDefinition

    init(pet: PetDefinition, onPress: @escaping () -> Void) {
        self.pet = pet

        let rect = NSRect(origin: pet.defaultOrigin, size: pet.size)
        let window = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.isMovable = true
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let imageView = PetImageView(frame: NSRect(origin: .zero, size: pet.size))
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = true
        imageView.wantsLayer = true
        imageView.petWindow = window
        imageView.onPress = onPress

        if let url = Bundle.main.url(forResource: pet.fileName, withExtension: nil) {
            imageView.image = NSImage(contentsOf: url)
        }

        window.contentView = imageView
        window.setFrameOrigin(pet.defaultOrigin)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPet() {
        showWindow(nil)
        window?.orderFrontRegardless()
    }

    func hidePet() {
        window?.orderOut(nil)
    }
}

final class SpeechBubbleWindowController: NSWindowController {
    init() {
        let size = NSSize(width: 360, height: 220)
        let rect = NSRect(origin: .zero, size: size)
        let window = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .screenSaver
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false

        super.init(window: window)

        let imageView = NSImageView(frame: rect)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.animates = false

        if let url = Bundle.main.url(forResource: "Speaking Box.png", withExtension: nil) {
            imageView.image = NSImage(contentsOf: url)
        }

        window.contentView = imageView
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showNearBottomCenter() {
        guard let window else { return }

        let targetScreen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) }) ?? NSScreen.main
        let visibleFrame = targetScreen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: visibleFrame.midX - (window.frame.width / 2),
            y: visibleFrame.minY + 70
        )

        window.setFrameOrigin(origin)
        showWindow(nil)
        window.orderFrontRegardless()
    }

    func hideBubble() {
        window?.orderOut(nil)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pets: [PetDefinition] = [
        PetDefinition(
            id: "pet1",
            fileName: "Sunny.GIF",
            defaultOrigin: NSPoint(x: 140, y: 640),
            size: NSSize(width: 160, height: 160)
        ),
        PetDefinition(
            id: "pet2",
            fileName: "Grace.gif",
            defaultOrigin: NSPoint(x: 320, y: 640),
            size: NSSize(width: 160, height: 160)
        ),
        PetDefinition(
            id: "pet3",
            fileName: "Gracie.gif",
            defaultOrigin: NSPoint(x: 500, y: 640),
            size: NSSize(width: 160, height: 160)
        )
    ]

    private var controllers: [String: PetWindowController] = [:]
    private var controlWindow: NSWindow?
    private var speechBubbleController: SpeechBubbleWindowController?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        speechBubbleController = SpeechBubbleWindowController()
        buildControlWindow()
        installMouseMonitors()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
        }
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func buildControlWindow() {
        let rect = NSRect(x: 220, y: 220, width: 430, height: 260)
        let window = NSWindow(
            contentRect: rect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Desktop Pets"
        window.isReleasedWhenClosed = false

        let contentView = NSView(frame: rect)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = contentView

        let titleLabel = NSTextField(labelWithString: "Choose which pets to show")
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.alignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = NSTextField(labelWithString: "Press a pet to show the speaking box. Click anywhere else to hide it.")
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let showPet1Button = makeButton(title: "Open Pet 1", action: #selector(showPet1))
        let showPet2Button = makeButton(title: "Open Pet 2", action: #selector(showPet2))
        let showPet3Button = makeButton(title: "Open Pet 3", action: #selector(showPet3))
        let showAllButton = makeButton(title: "Open All 3", action: #selector(showAllPets))
        let hideAllButton = makeButton(title: "Hide All", action: #selector(hideAllPets))

        let firstRow = NSStackView(views: [showPet1Button, showPet2Button])
        firstRow.orientation = .horizontal
        firstRow.spacing = 12
        firstRow.alignment = .centerY

        let secondRow = NSStackView(views: [showPet3Button, showAllButton])
        secondRow.orientation = .horizontal
        secondRow.spacing = 12
        secondRow.alignment = .centerY

        let controlsStack = NSStackView(views: [firstRow, secondRow, hideAllButton])
        controlsStack.orientation = .vertical
        controlsStack.spacing = 12
        controlsStack.alignment = .centerX
        controlsStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(controlsStack)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),

            controlsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            controlsStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            controlsStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])

        controlWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    private func makeButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 150).isActive = true
        return button
    }

    private func installMouseMonitors() {
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            self?.handleMouseDown(event.window)
            return event
        }

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] _ in
            self?.hideSpeechBubble()
        }
    }

    private func handleMouseDown(_ clickedWindow: NSWindow?) {
        guard let bubbleWindow = speechBubbleController?.window else {
            return
        }

        if clickedWindow !== bubbleWindow {
            hideSpeechBubble()
        }
    }

    private func controller(for petId: String) -> PetWindowController? {
        if let existing = controllers[petId] {
            return existing
        }

        guard let pet = pets.first(where: { $0.id == petId }) else {
            return nil
        }

        let controller = PetWindowController(pet: pet) { [weak self] in
            self?.showSpeechBubble()
        }
        controllers[petId] = controller
        return controller
    }

    private func showSpeechBubble() {
        speechBubbleController?.showNearBottomCenter()
    }

    private func hideSpeechBubble() {
        speechBubbleController?.hideBubble()
    }

    @objc
    private func showPet1() {
        controller(for: "pet1")?.showPet()
    }

    @objc
    private func showPet2() {
        controller(for: "pet2")?.showPet()
    }

    @objc
    private func showPet3() {
        controller(for: "pet3")?.showPet()
    }

    @objc
    private func showAllPets() {
        showPet1()
        showPet2()
        showPet3()
    }

    @objc
    private func hideAllPets() {
        hideSpeechBubble()
        controllers.values.forEach { $0.hidePet() }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
