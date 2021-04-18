//
//  PreferencesUpdate.swift
//  Iris
//
//  Created by Ivailo Kanev on 11/04/21.
//

import SwiftUI
@available(OSX 11.0, *)
struct PreferencesUpdate: View {
    @ObservedObject var viewModel = PreferencesUpdateModel()
    @State private var checkUpdate: Bool = false
    var body: some View {
        HStack() {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $viewModel.checkUpdate, label: {
                    Text("Check for updates automaticaly")
                        .onChange(of: checkUpdate, perform: { value in
                            viewModel.checkUpdate = value
                        })
                })
                HStack(spacing: 16) {
                    Button("Check Now") {
                        
                    }
                    Button("Visit Iris's Website") {
                        if let url = URL(string: "https://iris.tangra.it") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                VStack {
                    HStack {
                        Text("Last check: Never")
                            .foregroundColor(.init(white: 80))
                            .fontWeight(.light)
                    }
                    HStack {
                        Text("Iris is up to date.")
                            .fontWeight(.medium)
                    }
                }
                Spacer()
            }
            Spacer()
        }
    }
}
@available(OSX 11.0, *)
struct PreferencesUpdate_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesUpdate()
    }
}
