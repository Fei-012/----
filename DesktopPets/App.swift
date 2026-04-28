import AppKit

struct PetDefinition {
    let id: String
    let fileName: String
    let defaultOrigin: NSPoint
    let size: NSSize
}

final class PetImageView: NSImageView {
    weak var petWindow: NSWindow?

    override func mouseDown(with event: NSEvent) {
        petWindow?.performDrag(with: event)
    }
}

final class PetWindowController: NSWindowController {
    let pet: PetDefinition

    init(pet: PetDefinition) {
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

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let pets: [PetDefinition] = [
        PetDefinition(
            id: "pet1",
            fileName: "IMG_3090.GIF",
            defaultOrigin: NSPoint(x: 140, y: 640),
            size: NSSize(width: 160, height: 160)
        ),
        PetDefinition(
            id: "pet2",
            fileName: "UntitledArtwork1.GIF",
            defaultOrigin: NSPoint(x: 320, y: 640),
            size: NSSize(width: 160, height: 160)
        )
    ]

    private var controllers: [String: PetWindowController] = [:]
    private var controlWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        buildControlWindow()
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func buildControlWindow() {
        let rect = NSRect(x: 220, y: 220, width: 360, height: 210)
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

        let subtitleLabel = NSTextField(labelWithString: "Drag a pet anywhere. It stays put and keeps animating until you move it again.")
        subtitleLabel.font = .systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.lineBreakMode = .byWordWrapping
        subtitleLabel.maximumNumberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let showPet1Button = makeButton(title: "Open Pet 1", action: #selector(showPet1))
        let showPet2Button = makeButton(title: "Open Pet 2", action: #selector(showPet2))
        let showBothButton = makeButton(title: "Open Both", action: #selector(showBothPets))
        let hideAllButton = makeButton(title: "Hide All", action: #selector(hideAllPets))

        let grid = NSGridView(views: [
            [showPet1Button, showPet2Button],
            [showBothButton, hideAllButton]
        ])
        grid.rowSpacing = 12
        grid.columnSpacing = 12
        grid.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(grid)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -28),

            grid.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 24),
            grid.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            grid.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24)
        ])

        controlWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    private func makeButton(title: String, action: Selector) -> NSButton {
        let button = NSButton(title: title, target: self, action: action)
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 130).isActive = true
        return button
    }

    private func controller(for petId: String) -> PetWindowController? {
        if let existing = controllers[petId] {
            return existing
        }

        guard let pet = pets.first(where: { $0.id == petId }) else {
            return nil
        }

        let controller = PetWindowController(pet: pet)
        controllers[petId] = controller
        return controller
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
    private func showBothPets() {
        showPet1()
        showPet2()
    }

    @objc
    private func hideAllPets() {
        controllers.values.forEach { $0.hidePet() }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
