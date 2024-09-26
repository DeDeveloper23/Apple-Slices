// File: Sources/AppleSlices/AppDelegate.swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var shortcutManager: ShortcutManager?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        shortcutManager = ShortcutManager()
        // No need to call addCalculatorShortcut() or addPerplexityAIShortcut() here anymore
        setupMenuBarItem()
        setupPopover()
    }
    
    func setupMenuBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.title = "🍎"
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
    }
    
    func setupPopover() {
        popover = NSPopover()
        popover?.contentViewController = SearchViewController(shortcutManager: shortcutManager!)
        popover?.behavior = .transient
    }
    
    @objc func togglePopover(_ sender: Any?) {
        if let popover = popover {
            if popover.isShown {
                popover.performClose(sender)
            } else if let button = statusItem?.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                
                // Ensure the popover becomes the key window
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    @objc func closePopover(_ sender: Any?) {
        popover?.performClose(sender)
    }
}
