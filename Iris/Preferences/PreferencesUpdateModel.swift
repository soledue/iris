//
//  PreferencesUpdateModel.swift
//  Iris
//
//  Created by Ivailo Kanev on 18/04/21.
//

import SwiftUI
class PreferencesUpdateModel: ObservableObject {
    private let checkUpdateKey = "CHECK_UPDATE"
    private let bundlePath = Bundle.main.bundlePath
    private let usdf = UserDefaults.standard
    @Published dynamic var checkUpdate: Bool {
        didSet {
            usdf.set(checkUpdate, forKey: checkUpdateKey)
        }
    }
    init() {
        checkUpdate = usdf.bool(forKey: checkUpdateKey)
    }
}
