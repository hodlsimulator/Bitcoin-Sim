//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

enum ArrowDirection {
    case up
    case down
}

struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct TooltipBubble: View {
    let text: String
    let arrowDirection: ArrowDirection
    
    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                ArrowShape()
                    .frame(width: 20, height: 10)
                    .foregroundColor(Color.gray.opacity(0.85))
            }
            
            Text(text)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.85))
                .cornerRadius(8)
            
            if arrowDirection == .down {
                ArrowShape()
                    .rotationEffect(.degrees(180))
                    .frame(width: 20, height: 10)
                    .foregroundColor(Color.gray.opacity(0.85))
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct FactorToggleRow: View {
    let iconName: String?
    let title: String

    /// The toggle’s on/off binding (passed from parent).
    @Binding var isOn: Bool
    
    /// The factor’s numeric value, passed from parent as a binding.
    /// No local @State: the parent is the single source of truth.
    @Binding var sliderValue: Double
    
    /// The valid range for this factor’s numeric value.
    let sliderRange: ClosedRange<Double>
    
    /// The "default" numeric value for a reset (e.g., tapping the icon).
    let defaultValue: Double

    /// An optional tooltip/description for this factor.
    let parameterDescription: String?

    /// The parent's active factor (for showing tooltips).
    let activeFactor: String?

    /// Called when user taps the row’s title
    let onTitleTap: (String) -> Void

    /// Whether to display sliderValue as a percentage or raw number
    let displayAsPercent: Bool

    init(
        iconName: String? = nil,
        title: String,
        isOn: Binding<Bool>,
        sliderValue: Binding<Double>,
        sliderRange: ClosedRange<Double>,
        defaultValue: Double,
        parameterDescription: String? = nil,
        activeFactor: String? = nil,
        onTitleTap: @escaping (String) -> Void = { _ in },
        displayAsPercent: Bool = true
    ) {
        self.iconName = iconName
        self.title = title
        self._isOn = isOn
        self._sliderValue = sliderValue
        self.sliderRange = sliderRange
        self.defaultValue = defaultValue
        self.parameterDescription = parameterDescription
        self.activeFactor = activeFactor
        self.onTitleTap = onTitleTap
        self.displayAsPercent = displayAsPercent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // ─────────────────────────────────────────────────
            // MARK: Title row: icon + label + toggle
            // ─────────────────────────────────────────────────
            HStack(spacing: 8) {
                if let icon = iconName, !icon.isEmpty {
                    Button {
                        // Reset the factor to its default numeric value if desired
                        sliderValue = defaultValue
                    } label: {
                        Image(systemName: icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                }

                Text(title)
                    .font(.headline)
                    .onTapGesture {
                        onTitleTap(title)
                    }
                    // Tooltip anchor
                    .anchorPreference(key: TooltipAnchorKey.self, value: .center) { pt in
                        guard activeFactor == title,
                              let desc = parameterDescription,
                              !desc.isEmpty
                        else {
                            return []
                        }
                        return [TooltipItem(title: title, description: desc, anchor: pt)]
                    }

                Spacer()

                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.orange)
            }

            // ─────────────────────────────────────────────────
            // MARK: Slider row
            // ─────────────────────────────────────────────────
            HStack {
                // We'll normalize the slider so it goes 0...1 in the UI,
                // but the actual numeric is in sliderRange.
                let range = sliderRange.upperBound - sliderRange.lowerBound
                let normalizedBinding = Binding<Double>(
                    get: {
                        // Convert the real numeric into [0...1]
                        (sliderValue - sliderRange.lowerBound) / range
                    },
                    set: { newNormalized in
                        // Convert the normalized value back to the real numeric
                        sliderValue = sliderRange.lowerBound + newNormalized * range
                    }
                )

                Slider(value: normalizedBinding, in: 0...1)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .disabled(!isOn)

                // Decide how to display the numeric
                if title == "Halving" {
                    // Example special case
                    Text(String(format: "%.4f%%", sliderValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                        .disabled(!isOn)
                } else if displayAsPercent {
                    Text(String(format: "%.4f%%", sliderValue * 100))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                        .disabled(!isOn)
                } else {
                    Text(String(format: "%.4f", sliderValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                        .disabled(!isOn)
                }
            }
            .opacity(isOn ? 1.0 : 0.6)
        }
        .padding(.vertical, 4)
        .opacity(isOn ? 1.0 : 0.5)
    }
}
