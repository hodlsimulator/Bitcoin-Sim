//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

/// Whether arrow is physically up (apex at top) or down (apex at bottom).
enum ArrowDirection {
    case up
    case down
}

/// We define ArrowShape with apex at top => physically up.
/// If arrowDirection == .down, rotate 180°.
struct ArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Apex at top-center
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        // Bottom-right
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        // Bottom-left
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// A bubble with text and a triangular arrow physically up (top) or down (bottom).
struct TooltipBubble: View {
    let text: String
    let arrowDirection: ArrowDirection

    var body: some View {
        VStack(spacing: 0) {
            if arrowDirection == .up {
                // Arrow physically up => apex at top
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
                // Arrow physically down => apex at bottom
                ArrowShape()
                    .rotationEffect(.degrees(180))
                    .frame(width: 20, height: 10)
                    .foregroundColor(Color.gray.opacity(0.85))
            }
        }
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

/// A row that publishes an anchor if `activeFactor == title`.
/// Tapping the title calls `onTitleTap(title)`.
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title row
            HStack {
                if let icon = iconName, !icon.isEmpty {
                    Button {
                        // Tapping icon resets slider to default
                        sliderValue = defaultValue
                    } label: {
                        Image(systemName: icon)
                            .foregroundColor(.orange)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 6)
                    }
                    .buttonStyle(.plain)
                }

                Text(title)
                    .font(.headline)
                    .onTapGesture {
                        onTitleTap(title)
                    }
                    // Only publish anchor if this row is active & has a non-empty description
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
                // Here's the original slider tint colour
                Slider(value: $sliderValue, in: sliderRange)
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .disabled(!isOn)

                Text(String(format: "%.4f", sliderValue))
                    .font(.caption)           // <--- Smaller font size
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
                    .disabled(!isOn)
            }
            .opacity(isOn ? 1.0 : 0.6)
        }
        .padding(.vertical, 4)
        .opacity(isOn ? 1.0 : 0.5)
    }
}
