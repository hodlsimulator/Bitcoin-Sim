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

    @Binding var isOn: Bool
    @Binding var sliderValue: Double
    let sliderRange: ClosedRange<Double>
    let defaultValue: Double

    /// A descriptive text for the tooltip
    let parameterDescription: String?

    /// The parent's active factor. If it matches `title`, we publish an anchor.
    let activeFactor: String?

    /// Called when user taps the row’s title
    let onTitleTap: (String) -> Void

    /// NEW: decide whether we show X% or just X
    let displayAsPercent: Bool

    // Provide default values so existing calls don’t need to specify them.
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
            // Title row
            HStack(spacing: 8) {
                if let icon = iconName, !icon.isEmpty {
                    Button {
                        // Reset slider to default on icon tap
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

            // Slider row
            HStack {
                Slider(value: $sliderValue, in: sliderRange)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .disabled(!isOn)

                // If this is Halving, show 0.48% directly.
                if title == "Halving" {
                    Text(String(format: "%.4f%%", sliderValue))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                        .disabled(!isOn)
                }
                else if displayAsPercent {
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
