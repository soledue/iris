//
//  ContentViewModel.swift
//  Iris
//
//  Created by Ivailo Kanev on 14/03/21.
//

import ServiceManagement
import SwiftUI
class ContentViewModel: ObservableObject {
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
