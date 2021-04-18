//
//  AppDelegate.swift
//  Iris
//
//  Created by Ivailo Kanev on 26/02/21.
//

import Cocoa
import SwiftUI

@main
class AppDelegate:  NSResponder, NSApplicationDelegate {
    enum ItemAction {
        case change
        case add
        case remove
    }
    var statusItem: NSStatusItem!
    var window: NSWindow!
    var windowAbout: NSWindow?
    var mainScreen = [NSMenuItem: NSScreen]()
    var modes = [NSMenuItem: (mode: CGDisplayMode, screen: NSScreen, action: ItemAction)]()
    private var observe: NSKeyValueObservation?
    var isDark: Bool {
        let mode = NSAppearance.current
        return mode?.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let icon = NSImage(named: "MenuIcon")
        icon?.isTemplate = true
        statusItem.button?.image = icon
        statusItem.menu = NSMenu()
        statusItem.menu?.delegate = self
        
        observe = NSApp.observe(\.effectiveAppearance, options: .new) { app, value in
            NSAppearance.current = NSApp.effectiveAppearance
        }
        


    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func application(_ sender: NSApplication, delegateHandlesKey key: String) -> Bool {
        print(key)
        return true
    }
    override func keyDown(with event: NSEvent) {
        print(event)
    }

}
private extension AppDelegate {
    func isFavorite(screen: NSScreen, mode: CGDisplayMode) -> Bool {
        guard let deviceID = screen.deviceID else {
            return false
        }
        let key = "\(deviceID)\(mode.width)\(mode.height)"
        return UserDefaults.standard.bool(forKey: key)
    }
    @objc func preferences() {
        let window = NSWindow(contentRect: NSRect(x: 1, y: 0, width: 400, height: 200), styleMask: .docModalWindow, backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.styleMask = [.closable, .titled, .miniaturizable]
        window.title = "Iris Preferences"
        window.center()
        window.contentMinSize = CGSize(width:600, height: 200)
        if #available(OSX 11.0, *) {
            window.contentView = NSHostingView(rootView: PreferencesView())
            let hostingView = NSHostingView(rootView:
                                                HStack {
                                                    Link("Click me!", destination: URL(string: "https://www.apple.com")!)
                                                        .padding(/*@START_MENU_TOKEN@*/.horizontal, 4.0/*@END_MENU_TOKEN@*/)
                                                        .font(.system(size: 9, weight: .light))
                                                        .background(Color("coolGreen"))
                                                        .foregroundColor(.white)
                                                        .cornerRadius(6)
                                                }
                                                .padding(.trailing, 4.0)
            )
            hostingView.frame.size = hostingView.fittingSize

            let titlebarAccessory = NSTitlebarAccessoryViewController()
            titlebarAccessory.view = hostingView
            titlebarAccessory.layoutAttribute = .trailing
            window.addTitlebarAccessoryViewController(titlebarAccessory)
        } else {
            // Fallback on earlier versions
        }
        window.makeKeyAndOrderFront(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    @objc func about() {
        let credits = "\n\n©2021 KANEV".typeset.font(font: NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .thin)).аligment(alignment: .center).string
        let options = [NSApplication.AboutPanelOptionKey.credits: credits] as [NSApplication.AboutPanelOptionKey : Any]
        NSApp.orderFrontStandardAboutPanel(options: options)
        NSApp.activate(ignoringOtherApps: true)
    }
}
extension AppDelegate: NSMenuDelegate {
    
    func menuWillOpen(_ menu: NSMenu) {
        modes.removeAll()
        mainScreen.removeAll()
        for screen in NSScreen.screens {
            let n = NSMenuItem()
            let width = "\(Int(screen.currentResolution.width))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).color(color: .gray).string
            let x = "x".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .ultraLight)).color(color: .gray).string
            let height = "\(Int(screen.currentResolution.height))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).color(color: .gray).string
            n.attributedTitle = "\(screen.localizedName) - ".typeset.font(font: NSFont.systemFont(ofSize: 14)).string + width + x + height
            let info = screen.ioInfo()
            let newSize = CGSize(width: 24, height: 24)
            let addCanvas = CGSize(width: newSize.width + 16, height: newSize.height)
            if let icon = info?["display-resolution-preview-icon"] as? String, let image =  NSImage(contentsOfFile: icon) {
                n.image = image.resize(newSize).canvas(addCanvas, aligment: .alignRight)
            } else {
                n.image = NSImage(named: "GenericDisplay")?.resize(newSize).canvas(addCanvas, aligment: .alignRight)
            }
            if isDark {
                n.image = n.image?.inverted()
            }
            let submenu = NSMenu()
            let ordered = screen.allDisplayModes.filter{$0.isUsableForDesktopGUI()}.filter{!$0.isInterlaced}.filter{!$0.isStretched}.removeDuplicates().sorted(by: {$0.width < $1.width})
            let maxImageSize = ordered.last?.width ?? 0
            let minImageSize = ordered.first?.width ?? 0
            let favorites = ordered.filter { isFavorite(screen: screen, mode: $0) }
            let availables = ordered.filter { !isFavorite(screen: screen, mode: $0) }
            if screen.isMain {
                n.image = n.image?.current(isDark)

            } else {
                let m = NSMenuItem()
                m.attributedTitle = "Set as main".typeset.font(font: NSFont.systemFont(ofSize: 12)).string
                let newSize = CGSize(width: 8+16*minImageSize/maxImageSize, height: 8+16*minImageSize/maxImageSize)
                let newCanvas = CGSize(width: 8+16, height: 8+16*minImageSize/maxImageSize)
                let addCanvas = CGSize(width: newCanvas.width + 16, height: newCanvas.height)
                let image = NSImage(named: "MainScreen")?.resize(newSize).canvas(newCanvas).canvas(addCanvas, aligment: .alignRight)
                m.image = image
                m.action =  #selector(onSetMainClicked)
                submenu.addItem(m)
                submenu.addItem(NSMenuItem.separator())
                mainScreen[m] = screen
            }
            favorites.forEach { mode in
                do {
                    let s = NSMenuItem()
                    let width = "\(Int(mode.width))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    let x = "x".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .ultraLight)).string
                    let height = "\(Int(mode.height))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    
                    s.attributedTitle = width + x + height
                    let newSize = CGSize(width: 8+16*mode.width/maxImageSize, height: 8+16*mode.width/maxImageSize)
                    let newCanvas = CGSize(width: 8+16, height: 8+16*mode.width/maxImageSize)
                    let addCanvas = CGSize(width: newCanvas.width + 16, height: newCanvas.height)
                    let image = NSImage(named: "MenuResolution")?.resize(newSize).canvas(newCanvas).canvas(addCanvas, aligment: .alignRight)
                    if Int(screen.currentResolution.width) == mode.width,
                       Int(screen.currentResolution.height) == mode.height {
                        s.image = image?.current(isDark)
                        
                    } else {
                        s.action =  #selector(modeItemClicked)
                        s.image = image
                    }
                    
                    submenu.addItem(s)
                    modes[s] = (mode, screen, .change)
                }
                do {
                    let s = NSMenuItem()
                    s.isAlternate = true
                    
                    let width = "\(Int(mode.width))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    let x = "x".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .ultraLight)).string
                    let height = "\(Int(mode.height))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    
                    s.attributedTitle = width + x + height
                    let newSize = CGSize(width: 8+16*mode.width/maxImageSize, height: 8+16*mode.width/maxImageSize)
                    let newCanvas = CGSize(width: 8+16, height: 8+16*mode.width/maxImageSize)
                    let addCanvas = CGSize(width: newCanvas.width + 16, height: newCanvas.height)
                    let image = NSImage(named: "MenuResolution")?.resize(newSize).canvas(newCanvas).canvas(addCanvas, aligment: .alignRight)
                    
                    s.action =  #selector(modeItemClicked)
                    
                    submenu.addItem(s)
                    s.keyEquivalentModifierMask = [.option]
                    if isFavorite(screen: screen, mode: mode) {
                        s.image = image?.remove(isDark)
                        modes[s] = (mode, screen, .remove)
                    } else {
                        s.image = image?.add(isDark)
                        modes[s] = (mode, screen, .add)
                    }
                }
                
            }
            submenu.addItem(NSMenuItem.separator())
            availables.forEach { mode in
                do {
                    let s = NSMenuItem()
                    let width = "\(Int(mode.width))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    let x = "x".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .ultraLight)).string
                    let height = "\(Int(mode.height))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    
                    s.attributedTitle = width + x + height
                    let newSize = CGSize(width: 8+16*mode.width/maxImageSize, height: 8+16*mode.width/maxImageSize)
                    let newCanvas = CGSize(width: 8+16, height: 8+16*mode.width/maxImageSize)
                    let addCanvas = CGSize(width: newCanvas.width + 16, height: newCanvas.height)
                    let image = NSImage(named: "MenuResolution")?.resize(newSize).canvas(newCanvas).canvas(addCanvas, aligment: .alignRight)
                    if Int(screen.currentResolution.width) == mode.width,
                       Int(screen.currentResolution.height) == mode.height {
                        s.image = image?.current(isDark)
                        
                    } else {
                        s.action =  #selector(modeItemClicked)
                        s.image = image
                    }
                    submenu.addItem(s)
                    modes[s] = (mode, screen, .change)
                }
                do {
                    let s = NSMenuItem()
                    s.isAlternate = true
                    let width = "\(Int(mode.width))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    let x = "x".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 10, weight: .ultraLight)).string
                    let height = "\(Int(mode.height))".typeset.font(font: NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)).string
                    
                    s.attributedTitle = width + x + height
                    let newSize = CGSize(width: 8+16*mode.width/maxImageSize, height: 8+16*mode.width/maxImageSize)
                    let newCanvas = CGSize(width: 8+16, height: 8+16*mode.width/maxImageSize)
                    let addCanvas = CGSize(width: newCanvas.width + 16, height: newCanvas.height)
                    let image = NSImage(named: "MenuResolution")?.resize(newSize).canvas(newCanvas).canvas(addCanvas, aligment: .alignRight)
                    
                    s.action =  #selector(modeItemClicked)
                    
                    submenu.addItem(s)
                    s.keyEquivalentModifierMask = [.option]
                    if isFavorite(screen: screen, mode: mode) {
                        s.image = image?.remove(isDark)
                        modes[s] = (mode, screen, .remove)
                    } else {
                        s.image = image?.add(isDark)
                        modes[s] = (mode, screen, .add)
                    }
                }
                
            }
            
            n.submenu = submenu
            menu.addItem(n)

        }
        menu.addItem(NSMenuItem.separator())
        let n = NSMenuItem()
        n.attributedTitle = "Iris".typeset.font(font: NSFont.systemFont(ofSize: 14)).string
        let newSize = CGSize(width: 24, height: 24)
        let addCanvas = CGSize(width: newSize.width + 16, height: newSize.height)
        n.image = NSImage.empty(with: newSize)?.canvas(addCanvas, aligment: .alignRight)
        n.submenu = NSMenu()
        n.submenu?.addItem(NSMenuItem(title: "About", action: #selector(about), keyEquivalent: ""))
//        n.submenu?.addItem(NSMenuItem(title: "Help", action: #selector(onQuitMenuItemClicked), keyEquivalent: ""))
//        n.submenu?.addItem(NSMenuItem.separator())
        n.submenu?.addItem(NSMenuItem(title: "Preferences", action: #selector(preferences), keyEquivalent: ""))
        n.submenu?.addItem(NSMenuItem.separator())
        n.submenu?.addItem(NSMenuItem(title: "Quit", action: #selector(onQuitMenuItemClicked), keyEquivalent: ""))
        menu.addItem(n)
    }
    func menuDidClose(_ menu: NSMenu) {
        menu.removeAllItems()
    }

    @objc func onSetMainClicked(_ sender: NSMenuItem) {
        guard let screen = mainScreen[sender] else {
            return
        }
        screen.setAsMain()
    }
    
    @objc func onQuitMenuItemClicked(_ sender: NSMenuItem) {
        NSApp.terminate(self)
    }
    @objc func modeItemClicked(_ sender: NSMenuItem) {
        guard let mode = modes[sender]?.mode, let screen = modes[sender]?.screen, let action = modes[sender]?.action else {
            return
        }
        switch action {
        case .change:
            screen.set(mode: mode)
        case .add:
            guard let deviceID = screen.deviceID else {
                return
            }
            let key = "\(deviceID)\(mode.width)\(mode.height)"
            UserDefaults.standard.setValue(true, forKey: key)
        case .remove:
            guard let deviceID = screen.deviceID else {
                return
            }
            let key = "\(deviceID)\(mode.width)\(mode.height)"
            UserDefaults.standard.removeObject(forKey: key)
        }
        
    }


    
}

extension AppDelegate {
    private func createWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
    }
}
extension AppDelegate: NSWindowDelegate {
    func windowShouldClose(_ sender: NSWindow) -> Bool {

        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        return true
    }
}



extension AppDelegate {
    func listModesByDisplayID(/* let */ _displayID:CGDirectDisplayID?) -> [CGDisplayMode]? {
        if let displayID = _displayID {
            if let modeList = CGDisplayCopyAllDisplayModes(displayID, nil) {
                var modesArray = [CGDisplayMode]()

                let count = CFArrayGetCount(modeList)
                for i in 0..<count {
                    let modeRaw = CFArrayGetValueAtIndex(modeList, i)
                    // https://github.com/FUKUZAWA-Tadashi/FHCCommander
                    let mode = unsafeBitCast(modeRaw, to:CGDisplayMode.self)

                    modesArray.append(mode)
                }

                return modesArray
            }
        }
        return nil
    }
    func displayModes(/* let */ _display:CGDirectDisplayID?, /* let */ index:Int, /* let */ _modes:[CGDisplayMode]?) -> Void {
        if let display = _display {
            if let modes = _modes {
                print("Supported Modes for Display \(index):")
                let nf = NumberFormatter()
                nf.paddingPosition = NumberFormatter.PadPosition.beforePrefix
                nf.paddingCharacter = " " // XXX: Swift does not support padding yet
                nf.minimumIntegerDigits = 3 // XXX
                for i in 0..<modes.count {
                    let di = displayInfo(display:display, mode:modes[i])
                    print("       \(nf.string(from:NSNumber(value:di.width))!) * \(nf.string(from:NSNumber(value:di.height))!) @ \(di.frequency)Hz")
                }
            }
        }
    }
    func listDisplays(/* let */ displayIDs:UnsafeMutablePointer<CGDirectDisplayID>, /* let */ count:Int) -> Void {
        for i in 0..<count {
            let di = displayInfo(display:displayIDs[i], mode:nil)
            print("Display \(i):  \(di.width) * \(di.height) @ \(di.frequency)Hz")
        }
    }

    struct DisplayInfo {
        var width:UInt, height:UInt, frequency:UInt
    }
    // return with, height and frequency info for corresponding displayID
    func displayInfo(/* let */ display:CGDirectDisplayID, /* var */ mode:CGDisplayMode?) -> DisplayInfo {
        var mode = mode
        if mode == nil {
            mode = CGDisplayCopyDisplayMode(display)!
        }
        let width = UInt( mode!.width )
        let height = UInt( mode!.height )
        var frequency = UInt( mode!.refreshRate /* CGDisplayModeGetRefreshRate(mode) */ )

        if frequency == 0 {
            var link:CVDisplayLink?
            CVDisplayLinkCreateWithCGDisplay(display, &link)
            let time:CVTime = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(link!)
            // timeValue is in fact already in Int64
            let timeValue = time.timeValue as Int64
            // a hack-y way to do ceil
            let timeScale = Int64(time.timeScale) + timeValue / 2
            frequency = UInt( timeScale / timeValue )
        }
        return DisplayInfo(width:width, height:height, frequency:frequency)
    }
}
