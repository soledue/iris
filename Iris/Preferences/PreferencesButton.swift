//
//  PreferencesButton.swift
//  Iris
//
//  Created by Ivailo Kanev on 11/04/21.
//

import SwiftUI

struct PreferencesButton: View {
    let title: String
    let image: String
    var action: (() -> Void)?
    var isSelected: Bool = false
//    private let selectColor = Color(NSColor.windowFrameTextColor)
//    private let selectColor = Color(Color.RGBColorSpace.displayP3, red: 42.0/255, green: 132.0/255, blue: 210.0/255, opacity: 1)
    private let color = Color(NSColor.disabledControlTextColor)
    private let selectColor = Color(Color.RGBColorSpace.displayP3, red: 64.0/255, green: 135.0/255, blue: 195.0/255, opacity: 1)
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 10, content: {
            Image(image)
                .resizable()
                .frame(width: 20, height: 18, alignment: .center)
                .clipped()
                .colorMultiply(isSelected ? selectColor : color)
            Text(title)
                .font(.system(size: 10, weight: .semibold, design: .default))
                .foregroundColor(isSelected ? selectColor : color)
        })
        .padding(.top)
        .gesture( TapGesture()
                    .onEnded({ () in
                        action?()
                    })
        )
    }
}

struct PreferencesButton_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesButton(title: "Text", image: "pref_general")
    }
}
