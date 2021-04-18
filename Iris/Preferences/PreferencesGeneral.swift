//
//  PreferencesGeneral.swift
//  Iris
//
//  Created by Ivailo Kanev on 11/04/21.
//

import SwiftUI
@available(OSX 11.0, *)
struct PreferencesGeneral: View {
    @ObservedObject var viewModel = PreferencesGeneralModel()
    @State private var lunchAutomatically: Bool = false
    var body: some View {
        HStack() {
            VStack(alignment: .leading, spacing: 16) {
                Text("Main preferences")
                    .font(.system(size: 14, weight: .medium))
                Toggle(isOn: $viewModel.lunchAtLogin, label: {
                    Text("Launch automatically on login")
                        .onChange(of: lunchAutomatically, perform: { value in
                            viewModel.lunchAtLogin = value
                        })
                })
                
                
                Spacer()
            }
            Spacer()
        }
    }
}
@available(OSX 11.0, *)
struct PreferencesGeneral_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesGeneral()
    }
}
