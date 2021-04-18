//
//  DisplayHelper.swift
//  Iris
//
//  Created by Ivailo Kanev on 26/02/21.
//

import Foundation

struct Display {
    static var main: CGDirectDisplayID {
        CGMainDisplayID()
    }
    static var mode: CGDisplayMode? {
        main.displayMode
    }
    static func allModes(for directDisplayID: CGDirectDisplayID = main) -> [CGDisplayMode] {
        directDisplayID.allDisplayModes()
    }
}
extension CGDirectDisplayID  {
    var displayMode: CGDisplayMode? {
        CGDisplayCopyDisplayMode(self)
    }
    func allDisplayModes(options: CFDictionary? = nil) -> [CGDisplayMode] {
        CGDisplayCopyAllDisplayModes(self, options) as? [CGDisplayMode] ?? []
    }
}

extension CGDisplayMode {
    var resolution: String { .init(width) + " x " + .init(height) }
}

enum Desplayhelper {
    
    
}
