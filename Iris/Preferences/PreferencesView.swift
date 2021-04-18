//
//  ContentView.swift
//  Iris
//
//  Created by Ivailo Kanev on 26/02/21.
//

import SwiftUI
import ServiceManagement
@available(OSX 11.0, *)
struct PreferencesView: View {
    @State private var contentIndex = 0
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center, spacing: 16) {
                PreferencesButton(title: "General", image: "pref_general", action: {
                    contentIndex = 0
                }, isSelected: contentIndex == 0)
                
                PreferencesButton(title: "Update", image: "pref_update", action: {
                    contentIndex = 1
                }, isSelected: contentIndex == 1)
            }
            .padding([.leading])
            .frame(height: 64)
            HStack{
                if contentIndex == 0 {
                    PreferencesGeneral()
                        .frame(width: 400, height: 70, alignment: .leading)
                    
                } else if contentIndex == 1 {
                    PreferencesUpdate()
                        .frame(width: 400, height: 120, alignment: .leading)
                }
            }
            .padding([.top, .leading, .trailing])
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}


@available(OSX 11.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
    }
}
