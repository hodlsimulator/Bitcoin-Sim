//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

/// A reusable row showing:
///  - (Optional) iconName: for an SF Symbol
///  - A title
///  - A toggle (on the same line as the title)
///  - A slider + numeric readout below, if toggled on
///  - Animate the height changes
///
///  The toggle is tinted .orange, and the slider is tinted with #bdd5ea.
struct FactorToggleRow: View {
    /// Optional SF Symbol name, e.g. "lock.shield"
    let iconName: String?

    let title: String
    @Binding var isOn: Bool
    @Binding var sliderValue: Double
    let sliderRange: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // LINE 1: optional icon + title + toggle
            HStack {
                if let iconName = iconName, !iconName.isEmpty {
                    Image(systemName: iconName)
                        .imageScale(.medium)
                        .foregroundColor(.orange)
                }

                Text(title)
                    .font(.headline)

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.orange) // Tinted toggle
            }

            // LINE 2: slider row if toggled on
            if isOn {
                HStack {
                    Slider(value: $sliderValue, in: sliderRange)
                        .tint(
                            Color(
                                red: 189.0/255.0,
                                green: 213.0/255.0,
                                blue: 234.0/255.0
                            )
                        )

                    Text(String(format: "%.4f", sliderValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                // If you’d like to remove the slider instantly on toggle-off to avoid
                // the bubble glitch, use an asymmetric transition. For example:
                // .transition(.asymmetric(insertion: .opacity, removal: .identity))
            }
        }
        .padding(.vertical, 4)
        // Animate height changes
        .animation(.easeInOut(duration: 0.4), value: isOn)
    }
}
