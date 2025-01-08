//
//  CheckboxToggleStyle.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

//
//  CheckboxToggleStyle.swift
//  BTCMonteCarlo
//
//  Created by . . on 08/01/2025.
//

import SwiftUI

// MARK: - Custom Checkbox Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square" : "square")
                    .foregroundColor(configuration.isOn ? .orange : .gray)
                configuration.label
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
