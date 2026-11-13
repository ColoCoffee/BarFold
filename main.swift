import AppKit

@MainActor
final class BarFold: NSObject, NSApplicationDelegate {
    private let statusBar = NSStatusBar.system
    private let dividerWidth: CGFloat = 13
    private let collapsedWidth: CGFloat = 10_000
    private var toggleItem: NSStatusItem!
    private var dividerItem: NSStatusItem!
    private var isCollapsed = false
    private var controlsWindow: NSWindow?
    private var controlsButton: NSButton?

    private let toggleName = "BarFoldArrow"
    private let dividerName = "BarFoldSeparator"

    private func registerInitialPositions() {
        // AppKit restores these offsets from the right edge by autosave name.
        // Place a fresh pair near the right end, clear of the notch.
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "NSStatusItem Preferred Position " + toggleName: 240,
            "NSStatusItem Preferred Position " + dividerName: 285,
        ])
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        registerInitialPositions()
        toggleItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        toggleItem.autosaveName = toggleName
        toggleItem.button?.target = self
        toggleItem.button?.action = #selector(toggleClicked(_:))
        toggleItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])

        dividerItem = statusBar.statusItem(withLength: dividerWidth)
        dividerItem.autosaveName = dividerName
        dividerItem.button?.title = "│"
        dividerItem.button?.toolTip = "按住 ⌘ 拖动分隔线。左边的图标可以折叠。"
        dividerItem.button?.setAccessibilityLabel("BarFold 分隔线")
        updateToggle()

        if !UserDefaults.standard.bool(forKey: "DidShowBarFoldControls") {
            UserDefaults.standard.set(true, forKey: "DidShowBarFoldControls")
            showControls()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showControls()
        return false
    }

    @objc private func toggleFromWindow() {
        setCollapsed(!isCollapsed)
    }

    @objc private func toggleClicked(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showMenu(for: sender, event: event)
        } else {
            setCollapsed(!isCollapsed)
        }
    }

    private func setCollapsed(_ collapsed: Bool) {
        isCollapsed = collapsed
        // A wide, empty item pushes the items on its left out of the available menu bar.
        dividerItem.button?.title = collapsed ? "" : "│"
        dividerItem.length = collapsed ? collapsedWidth : dividerWidth
        updateToggle()
    }

    private func updateToggle() {
        let label = isCollapsed ? "展开左侧图标" : "隐藏左侧图标"
        controlsButton?.title = label
        let symbol = isCollapsed ? "chevron.left" : "chevron.right"
        if let button = toggleItem.button {
            button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)?
                .withSymbolConfiguration(.init(pointSize: 12, weight: .semibold))
            button.image?.isTemplate = true
            button.setAccessibilityLabel(label)
            button.toolTip = label + " · 右键显示菜单"
        }
    }

    private func showMenu(for button: NSStatusBarButton, event: NSEvent) {
        let menu = NSMenu()
        let helpItem = menu.addItem(withTitle: "打开 BarFold 控制", action: #selector(showControls), keyEquivalent: "")
        helpItem.target = self
        menu.addItem(.separator())
        let quitItem = menu.addItem(withTitle: "退出 BarFold", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApp
        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    @objc private func showControls() {
        if controlsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 168),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "BarFold"
            window.isReleasedWhenClosed = false

            let help = NSTextField(wrappingLabelWithString:
                "在屏幕右上方找竖线和箭头。按住 ⌘ 拖动竖线，把要隐藏的图标放在它左边，箭头留在右边。")
            help.maximumNumberOfLines = 0
            let toggle = NSButton(title: "", target: self, action: #selector(toggleFromWindow))
            let quit = NSButton(title: "退出 BarFold", target: NSApp, action: #selector(NSApplication.terminate(_:)))
            let buttons = NSStackView(views: [toggle, quit])
            buttons.spacing = 8
            let stack = NSStackView(views: [help, buttons])
            stack.orientation = .vertical
            stack.alignment = .leading
            stack.spacing = 18
            stack.translatesAutoresizingMaskIntoConstraints = false

            if let content = window.contentView {
                content.addSubview(stack)
                NSLayoutConstraint.activate([
                    stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 24),
                    stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -24),
                    stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
                    help.widthAnchor.constraint(equalTo: stack.widthAnchor),
                ])
            }

            window.center()
            controlsWindow = window
            controlsButton = toggle
        }
        updateToggle()
        NSApp.activate(ignoringOtherApps: true)
        controlsWindow?.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        statusBar.removeStatusItem(dividerItem)
        statusBar.removeStatusItem(toggleItem)
    }
}

MainActor.assumeIsolated {
    let application = NSApplication.shared
    let delegate = BarFold()
    application.setActivationPolicy(.accessory)
    application.delegate = delegate
    withExtendedLifetime(delegate) {
        application.run()
    }
}
