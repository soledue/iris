//
//  PreferencesGeneralModel.swift
//  Iris
//
//  Created by Ivailo Kanev on 11/04/21.
//

import SwiftUI

import SwiftUI
class PreferencesGeneralModel: ObservableObject {
    private let bundlePath = Bundle.main.bundlePath
    @Published dynamic var lunchAtLogin: Bool {
        didSet {
            if lunchAtLogin {
                LoginManager.add(for: bundlePath)
            } else {
                LoginManager.remove(for: bundlePath)
            }
        }
    }
    init() {
        lunchAtLogin = LoginManager.isExists(for: bundlePath)
    }
}
