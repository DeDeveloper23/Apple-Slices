// File: Sources/AppleSlices/ShortcutManager.swift
import Cocoa

class ShortcutManager {
    var shortcuts: [Shortcut]

    init() {
        self.shortcuts = []
        setupShortcuts()
        addCalculatorShortcut()
        addPerplexityAIShortcut()
        addCalendarShortcut()
        addAISearchShortcut() // Add this line
    }

    private func setupShortcuts() {
        shortcuts = [
            Shortcut(name: "Open Claude", keys: "CMD + Space", action: openClaude, isVisible: true),
            Shortcut(name: "Take Screenshot", keys: "CMD + 4", action: takeScreenshot, isVisible: true)
        ]
    }

    func openClaude() {
        if let url = URL(string: "https://claude.ai/new") {
            NSWorkspace.shared.open(url)
        }
    }

    func takeScreenshot() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // -i for interactive, -c for clipboard
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                print("Screenshot taken successfully")
            } else {
                print("Failed to take screenshot")
            }
        } catch {
            print("Error taking screenshot: \(error)")
        }
    }

    func addCalculatorShortcut() {
        let calculatorShortcut = Shortcut(
            name: "Open Calculator",
            keys: "⌘C",
            action: {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.calculator") {
                    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                }
            },
            isVisible: true
        )
        shortcuts.append(calculatorShortcut)
    }

    func addPerplexityAIShortcut() {
        let perplexityAIShortcut = Shortcut(
            name: "Open Perplexity AI",
            keys: "⌘P",
            action: {
                if let url = URL(string: "https://www.perplexity.ai") {
                    NSWorkspace.shared.open(url)
                }
            },
            isVisible: true  // Add this line
        )
        shortcuts.append(perplexityAIShortcut)
    }

    func addCalendarShortcut() {
        let calendarShortcut = Shortcut(
            name: "Open Calendar",
            keys: "⌘L", // You can change this key combination if needed
            action: {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") {
                    NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                }
            },
            isVisible: true  // Add this line
        )
        shortcuts.append(calendarShortcut)
    }

    func addAISearchShortcut() {
        let aiSearchShortcut = Shortcut(
            name: "AI Search",
            keys: "⌘A",
            action: {
                // This action will be overridden in the SearchViewController
            },
            isVisible: true,
            subOptions: [
                SubOption(name: "OpenAI", action: {
                    if let url = URL(string: "https://www.openai.com") {
                        NSWorkspace.shared.open(url)
                    }
                }),
                SubOption(name: "Claude", action: {
                    if let url = URL(string: "https://www.anthropic.com") {
                        NSWorkspace.shared.open(url)
                    }
                }),
                SubOption(name: "Gemini", action: {
                    if let url = URL(string: "https://gemini.google.com") {
                        NSWorkspace.shared.open(url)
                    }
                })
            ]
        )
        shortcuts.append(aiSearchShortcut)
    }

    func addShortcut(_ shortcut: Shortcut) {
        shortcuts.append(shortcut)
    }

    func addSubOption(to shortcutIndex: Int, subOption: SubOption) {
        guard shortcutIndex < shortcuts.count else { return }
        if shortcuts[shortcutIndex].subOptions == nil {
            shortcuts[shortcutIndex].subOptions = []
        }
        shortcuts[shortcutIndex].subOptions?.append(subOption)
    }

    func editSubOption(at shortcutIndex: Int, subOptionIndex: Int, newSubOption: SubOption) {
        guard shortcutIndex < shortcuts.count,
              let subOptions = shortcuts[shortcutIndex].subOptions,
              subOptionIndex < subOptions.count else { return }
        shortcuts[shortcutIndex].subOptions?[subOptionIndex] = newSubOption
    }

    func removeSubOption(from shortcutIndex: Int, at subOptionIndex: Int) {
        guard shortcutIndex < shortcuts.count,
              shortcuts[shortcutIndex].subOptions != nil,
              subOptionIndex < shortcuts[shortcutIndex].subOptions!.count else { return }
        shortcuts[shortcutIndex].subOptions?.remove(at: subOptionIndex)
    }
}

struct Shortcut {
    let name: String
    let keys: String
    let action: () -> Void
    var isVisible: Bool
    var subOptions: [SubOption]?
}

struct SubOption {
    let name: String
    let action: () -> Void
}
