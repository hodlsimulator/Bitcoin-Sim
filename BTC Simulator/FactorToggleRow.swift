//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

struct FactorToggleRow: View {
    let iconName: String?
    let title: String
    @Binding var isOn: Bool
    @Binding var sliderValue: Double
    let sliderRange: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                if let iconName = iconName, !iconName.isEmpty {
                    Image(systemName: iconName)
                        .imageScale(.medium)
                        .foregroundColor(.orange)
                }

                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .layoutPriority(1)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.orange)
            }

            HStack {
                Slider(value: $sliderValue, in: sliderRange)
                    .tint(Color(red: 189/255.0, green: 213/255.0, blue: 234/255.0))
                    .disabled(!isOn)

                Text(String(format: "%.4f", sliderValue))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
                    .disabled(!isOn)
            }
            .opacity(isOn ? 1.0 : 0.5)
        }
        .padding(.vertical, 4)
        .opacity(isOn ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.4), value: isOn)
    }
}
