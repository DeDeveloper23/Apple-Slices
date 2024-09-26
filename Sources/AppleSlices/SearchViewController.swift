// File: Sources/AppleSlices/SearchViewController.swift
import Cocoa

class SearchViewController: NSViewController, NSSearchFieldDelegate, NSTableViewDelegate, NSTableViewDataSource, NSWindowDelegate {
    var searchField: NSSearchField!
    var tableView: NSTableView!
    var shortcutManager: ShortcutManager?
    var settingsButton: NSButton!
    weak var settingsWindow: NSWindow?
    var visibilityDisclosureButton: NSButton!
    var aiOptionsDisclosureButton: NSButton!
    var visibilityView: NSView!
    var aiOptionsView: NSView!
    var settingsContentView: NSView!
    var subOptionsMenu: NSMenu?
    var subOptionsView: NSView?
    var subOptionsTableView: NSTableView?
    var settingsSplitView: NSSplitView!
    var settingsLeftPane: NSView!
    var settingsRightPane: NSView!
    var settingsCategoryList: NSTableView!
    
    init(shortcutManager: ShortcutManager) {
        self.shortcutManager = shortcutManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 300))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        
        setupSearchField()
        setupTableView()
        setupSettingsButton()
        setupSubOptionsView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Number of shortcuts: \(shortcutManager?.shortcuts.count ?? 0)")
        if let shortcuts = shortcutManager?.shortcuts {
            for (index, shortcut) in shortcuts.enumerated() {
                print("Shortcut \(index): \(shortcut.name) (\(shortcut.keys))")
            }
        }
        
        addVoiceControlShortcut()
        
        tableView.reloadData()
        
        // Add click handler for table view rows
        tableView.target = self
        tableView.action = #selector(tableViewRowClicked)  // Change to single click action
    }
    
    func setupSearchField() {
        searchField = NSSearchField(frame: NSRect(x: 10, y: 270, width: 250, height: 24))
        searchField.delegate = self
        view.addSubview(searchField)
    }
    
    func setupTableView() {
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: 10, width: 280, height: 250))
        tableView = NSTableView(frame: scrollView.bounds)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("shortcut"))
        column.title = "Shortcuts"
        column.width = 270
        tableView.addTableColumn(column)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 30  // Increase the row height to 30
        
        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        
        view.addSubview(scrollView)
    }
    
    func setupSettingsButton() {
        settingsButton = NSButton(frame: NSRect(x: 270, y: 270, width: 24, height: 24))
        settingsButton.bezelStyle = .texturedRounded
        if #available(macOS 11.0, *) {
            settingsButton.image = NSImage(systemSymbolName: "gear", accessibilityDescription: "Settings")
        } else {
            settingsButton.image = NSImage(named: NSImage.actionTemplateName)
        }
        settingsButton.imagePosition = .imageOnly
        settingsButton.action = #selector(openSettingsWindow)
        settingsButton.target = self
        view.addSubview(settingsButton)
    }
    
    func setupSubOptionsView() {
        // Implement this method to set up the sub-options view
    }
    
    @objc func openSettingsWindow() {
        print("Opening settings window")
        if settingsWindow == nil {
            print("Settings window is nil, creating new window")
            createSettingsWindow()
        }
        
        if let window = settingsWindow {
            print("Settings window exists")
            if !window.isVisible {
                print("Making settings window visible")
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        } else {
            print("Settings window is still nil after creation attempt")
        }
    }
    
    func createSettingsWindow() {
        print("Creating settings window")
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 600, height: 400),
                              styleMask: [.titled, .closable, .miniaturizable, .resizable],
                              backing: .buffered,
                              defer: false)
        window.title = "Settings"
        window.isReleasedWhenClosed = false
        
        settingsContentView = NSView(frame: window.contentRect(forFrameRect: window.frame))
        
        settingsSplitView = NSSplitView(frame: settingsContentView.bounds)
        settingsSplitView.isVertical = true
        settingsSplitView.dividerStyle = .thin
        
        settingsLeftPane = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: settingsContentView.bounds.height))
        settingsRightPane = NSView(frame: NSRect(x: 200, y: 0, width: settingsContentView.bounds.width - 200, height: settingsContentView.bounds.height))
        
        settingsSplitView.addArrangedSubview(settingsLeftPane)
        settingsSplitView.addArrangedSubview(settingsRightPane)
        
        settingsContentView.addSubview(settingsSplitView)
        
        window.contentView = settingsContentView
        settingsWindow = window
        
        window.delegate = self
        
        print("Setting up category list")
        setupSettingsCategoryList()
        print("Updating window size")
        updateSettingsWindowSize()
        print("Settings window creation complete")
    }
    
    func setupSettingsCategoryList() {
        guard let settingsLeftPane = settingsLeftPane else {
            print("Error: settingsLeftPane is nil")
            return
        }
        
        let scrollView = NSScrollView(frame: settingsLeftPane.bounds)
        settingsCategoryList = NSTableView(frame: scrollView.bounds)
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("category"))
        column.title = "Categories"
        column.width = settingsLeftPane.bounds.width - 20 // Adjust width to fit the pane
        settingsCategoryList.addTableColumn(column)
        
        settingsCategoryList.delegate = self
        settingsCategoryList.dataSource = self
        settingsCategoryList.rowHeight = 30 // Increase row height
        settingsCategoryList.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        
        scrollView.documentView = settingsCategoryList
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        
        settingsLeftPane.addSubview(scrollView)
        
        // Select the first category by default
        settingsCategoryList.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        updateSettingsRightPane(for: 0)
    }
    
    func createVisibilityView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 200))
        let scrollView = NSScrollView(frame: view.bounds)
        let contentSize = NSSize(width: 280, height: CGFloat(shortcutManager?.shortcuts.count ?? 0) * 30)
        scrollView.documentView = NSView(frame: NSRect(origin: .zero, size: contentSize))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        if let shortcuts = shortcutManager?.shortcuts {
            for (index, shortcut) in shortcuts.enumerated() {
                let checkbox = NSButton(checkboxWithTitle: shortcut.name, target: self, action: #selector(toggleShortcutVisibility(_:)))
                checkbox.frame = NSRect(x: 0, y: contentSize.height - CGFloat(index + 1) * 30, width: 260, height: 20)
                checkbox.state = shortcut.isVisible ? .on : .off
                checkbox.tag = index
                scrollView.documentView?.addSubview(checkbox)
            }
        }
        
        view.addSubview(scrollView)
        return view
    }
    
    func createAIOptionsView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 130))
        
        let openAILabel = NSTextField(labelWithString: "OpenAI API Key:")
        openAILabel.frame = NSRect(x: 0, y: 100, width: 280, height: 20)
        view.addSubview(openAILabel)
        
        let openAIField = NSSecureTextField(frame: NSRect(x: 0, y: 70, width: 280, height: 24))
        openAIField.placeholderString = "Enter OpenAI API Key"
        view.addSubview(openAIField)
        
        let claudeLabel = NSTextField(labelWithString: "Claude Anthropic API Key:")
        claudeLabel.frame = NSRect(x: 0, y: 40, width: 280, height: 20)
        view.addSubview(claudeLabel)
        
        let claudeField = NSSecureTextField(frame: NSRect(x: 0, y: 10, width: 280, height: 24))
        claudeField.placeholderString = "Enter Claude Anthropic API Key"
        view.addSubview(claudeField)
        
        return view
    }
    
    func createSubOptionsView() -> NSView {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 100))

        let shortcutPopup = NSPopUpButton(frame: NSRect(x: 0, y: 70, width: 280, height: 24))
        shortcutPopup.addItems(withTitles: shortcutManager?.shortcuts.filter { $0.subOptions != nil }.map { $0.name } ?? [])
        view.addSubview(shortcutPopup)

        let subOptionsTable = NSTableView(frame: NSRect(x: 0, y: 30, width: 280, height: 60))
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("subOption"))
        column.title = "Sub-options"
        column.width = 260
        subOptionsTable.addTableColumn(column)
        subOptionsTable.delegate = self
        subOptionsTable.dataSource = self
        view.addSubview(subOptionsTable)

        let addButton = NSButton(title: "Add", target: self, action: #selector(addSubOption))
        addButton.frame = NSRect(x: 0, y: 0, width: 80, height: 24)
        view.addSubview(addButton)

        let editButton = NSButton(title: "Edit", target: self, action: #selector(editSubOption))
        editButton.frame = NSRect(x: 100, y: 0, width: 80, height: 24)
        view.addSubview(editButton)

        let removeButton = NSButton(title: "Remove", target: self, action: #selector(removeSubOption))
        removeButton.frame = NSRect(x: 200, y: 0, width: 80, height: 24)
        view.addSubview(removeButton)

        return view
    }
    
    @objc func toggleVisibilityView() {
        visibilityView.isHidden = !visibilityView.isHidden
        updateSettingsLayout()
    }
    
    @objc func toggleAIOptionsView() {
        aiOptionsView.isHidden = !aiOptionsView.isHidden
        updateSettingsLayout()
    }
    
    @objc func toggleSubOptionsView(_ sender: NSButton) {
        if let subOptionsView = settingsContentView.subviews.last(where: { $0 is NSTableView }) {
            subOptionsView.isHidden = !subOptionsView.isHidden
            updateSettingsLayout()
        }
    }
    
    @objc func addSubOption() {
        let alert = NSAlert()
        alert.messageText = "Add Sub-option"
        alert.informativeText = "Enter the details for the new sub-option:"
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        nameField.placeholderString = "Sub-option Name"
        urlField.placeholderString = "URL"

        alert.accessoryView = NSStackView(views: [nameField, urlField])

        if alert.runModal() == .alertFirstButtonReturn {
            guard let name = nameField.stringValue.isEmpty ? nil : nameField.stringValue,
                  let urlString = urlField.stringValue.isEmpty ? nil : urlField.stringValue,
                  let shortcutName = (settingsContentView.subviews.first(where: { $0 is NSPopUpButton }) as? NSPopUpButton)?.selectedItem?.title,
                  let shortcutIndex = shortcutManager?.shortcuts.firstIndex(where: { $0.name == shortcutName }) else {
                return
            }

            let newSubOption = SubOption(name: name) {
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }

            shortcutManager?.addSubOption(to: shortcutIndex, subOption: newSubOption)
            updateSubOptionsTable()
        }
    }
    
    @objc func editSubOption() {
        guard let subOptionsTable = settingsContentView.subviews.last(where: { $0 is NSTableView }) as? NSTableView,
              let shortcutName = (settingsContentView.subviews.first(where: { $0 is NSPopUpButton }) as? NSPopUpButton)?.selectedItem?.title,
              let shortcutIndex = shortcutManager?.shortcuts.firstIndex(where: { $0.name == shortcutName }),
              let selectedRow = subOptionsTable.selectedRowIndexes.first else {
            return
        }

        let alert = NSAlert()
        alert.messageText = "Edit Sub-option"
        alert.informativeText = "Edit the details for the sub-option:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        nameField.stringValue = shortcutManager?.shortcuts[shortcutIndex].subOptions?[selectedRow].name ?? ""
        urlField.stringValue = "" // You'll need to store URLs separately in the SubOption struct

        alert.accessoryView = NSStackView(views: [nameField, urlField])

        if alert.runModal() == .alertFirstButtonReturn {
            guard let name = nameField.stringValue.isEmpty ? nil : nameField.stringValue,
                  let urlString = urlField.stringValue.isEmpty ? nil : urlField.stringValue else {
                return
            }

            let editedSubOption = SubOption(name: name) {
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
            }

            shortcutManager?.editSubOption(at: shortcutIndex, subOptionIndex: selectedRow, newSubOption: editedSubOption)
            updateSubOptionsTable()
        }
    }
    
    @objc func removeSubOption() {
        guard let subOptionsTable = settingsContentView.subviews.last(where: { $0 is NSTableView }) as? NSTableView,
              let shortcutName = (settingsContentView.subviews.first(where: { $0 is NSPopUpButton }) as? NSPopUpButton)?.selectedItem?.title,
              let shortcutIndex = shortcutManager?.shortcuts.firstIndex(where: { $0.name == shortcutName }),
              let selectedRow = subOptionsTable.selectedRowIndexes.first else {
            return
        }

        shortcutManager?.removeSubOption(from: shortcutIndex, at: selectedRow)
        updateSubOptionsTable()
    }
    
    func updateSubOptionsTable() {
        if let subOptionsTable = settingsContentView.subviews.last(where: { $0 is NSTableView }) as? NSTableView {
            subOptionsTable.reloadData()
        }
    }
    
    func updateSettingsLayout() {
        var yOffset: CGFloat = 10
        
        // AI Options
        aiOptionsDisclosureButton.frame.origin.y = yOffset
        yOffset += aiOptionsDisclosureButton.frame.height + 10
        
        if !aiOptionsView.isHidden {
            aiOptionsView.frame.origin.y = yOffset
            yOffset += aiOptionsView.frame.height + 10
        }
        
        // Visibility Settings
        visibilityDisclosureButton.frame.origin.y = yOffset
        yOffset += visibilityDisclosureButton.frame.height + 10
        
        if !visibilityView.isHidden {
            visibilityView.frame.origin.y = yOffset
            yOffset += visibilityView.frame.height + 10
        }
        
        // Sub-options Settings
        if let subOptionsDisclosureButton = settingsContentView.subviews.first(where: { 
            if let button = $0 as? NSButton {
                return button.title == "Sub-options Settings"
            }
            return false
        }) as? NSButton {
            subOptionsDisclosureButton.frame.origin.y = yOffset
            yOffset += subOptionsDisclosureButton.frame.height + 10

            if let subOptionsView = settingsContentView.subviews.last(where: { $0 is NSTableView }) {
                if !subOptionsView.isHidden {
                    subOptionsView.frame.origin.y = yOffset
                    yOffset += subOptionsView.frame.height + 10
                }
            }
        }
        
        let newHeight = yOffset
        settingsContentView.frame.size.height = newHeight
        settingsWindow?.setContentSize(NSSize(width: 300, height: newHeight))
    }
    
    func updateSettingsWindowSize() {
        settingsWindow?.setContentSize(settingsContentView.frame.size)
    }
    
    @objc func toggleShortcutVisibility(_ sender: NSButton) {
        guard let index = shortcutManager?.shortcuts.indices[sender.tag] else { return }
        shortcutManager?.shortcuts[index].isVisible = (sender.state == .on)
        tableView.reloadData()
    }
    
    @objc func addNewShortcut() {
        let alert = NSAlert()
        alert.messageText = "Add New Shortcut"
        alert.informativeText = "Enter the details for the new shortcut:"
        
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        
        let nameField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let keysField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        let urlField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        
        nameField.placeholderString = "Shortcut Name"
        keysField.placeholderString = "Shortcut Keys (e.g., ⌘K)"
        urlField.placeholderString = "URL or Bundle Identifier"
        
        alert.accessoryView = NSStackView(views: [nameField, keysField, urlField])
        
        if alert.runModal() == .alertFirstButtonReturn {
            guard let name = nameField.stringValue.isEmpty ? nil : nameField.stringValue,
                  let keys = keysField.stringValue.isEmpty ? nil : keysField.stringValue,
                  let urlString = urlField.stringValue.isEmpty ? nil : urlField.stringValue else {
                return
            }
            
            let newShortcut = Shortcut(
                name: name,
                keys: keys,
                action: {
                    if let url = URL(string: urlString) {
                        NSWorkspace.shared.open(url)
                    } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: urlString) {
                        NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration())
                    }
                },
                isVisible: true  // Add this line
            )
            
            shortcutManager?.shortcuts.append(newShortcut)
            tableView.reloadData()
        }
    }
    
    func addVoiceControlShortcut() {
        let voiceControlShortcut = Shortcut(
            name: "Enable Voice Control",
            keys: "⌘⌥V",  // Command + Option + V
            action: {
                self.enableAndOpenVoiceControl()
            },
            isVisible: true
        )
        
        shortcutManager?.shortcuts.append(voiceControlShortcut)
    }
    
    func enableAndOpenVoiceControl() {
        requestAccessibilityPermissions()
        
        let script = """
        tell application "System Settings"
            activate
            set current pane to pane id "com.apple.preference.universalaccess"
            delay 1
            tell application "System Events"
                tell process "System Settings"
                    click button "Voice Control" of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
                    delay 1
                    click checkbox "Enable Voice Control" of group 1 of scroll area 1 of group 1 of group 2 of splitter group 1 of group 1 of window 1
                end tell
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("Error executing AppleScript: \(error)")
            }
        }
    }
    
    func requestAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options)
        
        // ... (rest of the method remains unchanged)
    }
    
    // MARK: - NSSearchFieldDelegate methods
    func controlTextDidChange(_ obj: Notification) {
        // Implement search functionality
        tableView.reloadData()
    }
    
    // MARK: - NSTableViewDelegate and NSTableViewDataSource methods
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == self.tableView {
            let visibleShortcutsCount = shortcutManager?.shortcuts.filter { $0.isVisible }.count ?? 0
            print("Number of visible shortcuts: \(visibleShortcutsCount)")
            return visibleShortcutsCount
        } else if tableView == self.subOptionsTableView {
            let subOptionsCount = getSelectedShortcutWithSubOptions()?.subOptions?.count ?? 0
            print("Number of sub-options: \(subOptionsCount)")
            return subOptionsCount
        } else if tableView == self.settingsCategoryList {
            return 3 // Number of settings categories
        }
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == self.settingsCategoryList {
            let cellIdentifier = NSUserInterfaceItemIdentifier("CategoryCell")
            var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            
            if cell == nil {
                cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
                cell?.identifier = cellIdentifier
                
                let textField = NSTextField(frame: NSRect(x: 5, y: 0, width: tableView.frame.width - 10, height: 30))
                textField.isEditable = false
                textField.isSelectable = false
                textField.drawsBackground = false
                textField.isBordered = false
                textField.textColor = .labelColor
                textField.lineBreakMode = .byTruncatingTail
                textField.cell?.truncatesLastVisibleLine = true
                cell?.textField = textField
                cell?.addSubview(textField)
            }
            
            let categories = ["General", "Shortcuts", "AI Options"]
            cell?.textField?.stringValue = categories[row]
            
            return cell
        }
        
        if tableView == self.tableView {
            let cellIdentifier = NSUserInterfaceItemIdentifier("ShortcutCell")
            var cell = tableView.makeView(withIdentifier: cellIdentifier, owner: nil) as? NSTableCellView
            
            if cell == nil {
                cell = NSTableCellView(frame: NSRect(x: 0, y: 0, width: tableView.frame.width, height: 30))
                cell?.identifier = cellIdentifier
                
                let textField = NSTextField(frame: NSRect(x: 5, y: 5, width: tableView.frame.width - 10, height: 20))  // Adjust the text field's frame
                textField.isEditable = false
                textField.isSelectable = false
                textField.drawsBackground = false
                textField.isBordered = false
                textField.textColor = .labelColor
                cell?.textField = textField
                cell?.addSubview(textField)
            }
            
            if let shortcut = shortcutManager?.shortcuts.filter({ $0.isVisible })[row] {
                cell?.textField?.stringValue = "\(shortcut.name) (\(shortcut.keys))"
            }
            
            return cell
        }
        
        // Implement views for other table views (sub-options)
        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else { return }
        
        if tableView == self.settingsCategoryList {
            let selectedRow = tableView.selectedRow
            updateSettingsRightPane(for: selectedRow)
        }
        
        // Implement selection changes for other table views
    }
    
    func updateSettingsRightPane(for categoryIndex: Int) {
        // Remove existing subviews
        settingsRightPane.subviews.forEach { $0.removeFromSuperview() }
        
        switch categoryIndex {
        case 0: // General
            setupGeneralSettingsView()
        case 1: // Shortcuts
            setupShortcutsSettingsView()
        case 2: // AI Options
            setupAIOptionsSettingsView()
        default:
            break
        }
    }
    
    func setupGeneralSettingsView() {
        let generalView = NSView(frame: settingsRightPane.bounds)
        // Add general settings controls here
        settingsRightPane.addSubview(generalView)
    }
    
    func setupShortcutsSettingsView() {
        let shortcutsView = createVisibilityView()
        shortcutsView.frame = settingsRightPane.bounds
        settingsRightPane.addSubview(shortcutsView)
    }
    
    func setupAIOptionsSettingsView() {
        let aiOptionsView = createAIOptionsView()
        aiOptionsView.frame = settingsRightPane.bounds
        settingsRightPane.addSubview(aiOptionsView)
    }
    
    // MARK: - NSWindowDelegate methods
    func windowWillClose(_ notification: Notification) {
        // Reset the settingsWindow property when the window is closed
        settingsWindow = nil
    }
    
    // Helper method
    private func getSelectedShortcutWithSubOptions() -> Shortcut? {
        guard let selectedRow = tableView.selectedRowIndexes.first,
              let visibleShortcuts = shortcutManager?.shortcuts.filter({ $0.isVisible }),
              selectedRow < visibleShortcuts.count else {
            return nil
        }
        let selectedShortcut = visibleShortcuts[selectedRow]
        return selectedShortcut.subOptions != nil ? selectedShortcut : nil
    }
    
    @objc func tableViewRowClicked() {
        let clickedRow = tableView.clickedRow
        if clickedRow >= 0, let shortcut = shortcutManager?.shortcuts.filter({ $0.isVisible })[clickedRow] {
            shortcut.action()
        }
    }
}

