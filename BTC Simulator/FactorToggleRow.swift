//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

struct FactorToggleRow: View {
    @EnvironmentObject var simSettings: SimulationSettings
    
    /// The unique name of this factor, matching the dictionary key in simSettings.factors
    let factorName: String
    
    /// Factor display properties
    let iconName: String?
    let title: String
    let parameterDescription: String?
    let sliderRange: ClosedRange<Double>
    let defaultValue: Double
    let displayAsPercent: Bool
    
    /// For tooltips
    let activeFactor: String?
    let onTitleTap: (String) -> Void
    
    /// Callback to re-trigger tilt calculation (or anything else) after toggles/sliders change
    let onFactorChange: () -> Void
    
    var body: some View {
        // Safely fetch the factor from simSettings
        guard let factor = simSettings.factors[factorName] else {
            return AnyView(
                Text("Factor '\(factorName)' not found!")
                    .foregroundColor(.red)
            )
        }
        
        // --------------------
        // Toggle binding
        // --------------------
        let toggleBinding = Binding<Bool>(
            get: { factor.isEnabled },
            set: { newVal in
                simSettings.setFactorEnabled(factorName: factorName, enabled: newVal)
                onFactorChange() // Call our callback whenever the toggle changes
            }
        )
        
        // --------------------
        // Slider binding
        // --------------------
        let sliderBinding = Binding<Double>(
            get: {
                // Show the factor's currentValue, or fall back to defaultValue if missing
                simSettings.factors[factorName]?.currentValue ?? defaultValue
            },
            set: { newVal in
                // Clamp the new value to the factor's valid range
                let clampedVal = max(min(newVal, factor.maxValue), factor.minValue)
                
                // Update offset, etc., within SimulationSettings
                simSettings.userDidDragFactorSlider(factorName, to: clampedVal)
                
                // Ensure factor is not locked after a manual drag
                if var currentFactor = simSettings.factors[factorName] {
                    currentFactor.isLocked = false
                    simSettings.factors[factorName] = currentFactor
                }
                
                onFactorChange() // Call our callback whenever the slider changes
            }
        )
        
        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                
                // --------------------
                // Title + Toggle row
                // --------------------
                HStack(spacing: 8) {
                    if let icon = iconName, !icon.isEmpty {
                        Button {
                            // Reset to default if user taps the icon (optional behaviour)
                            if var f = simSettings.factors[factorName] {
                                f.currentValue = defaultValue
                                f.isLocked = false
                                simSettings.factors[factorName] = f
                            }
                            onFactorChange()
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

                    Toggle("", isOn: toggleBinding)
                        .labelsHidden()
                        .tint(.orange)
                }
                
                // --------------------
                // Slider row
                // --------------------
                HStack {
                    Slider(
                        value: sliderBinding,
                        in: sliderRange
                    )
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .disabled(!factor.isEnabled)
                    
                    if displayAsPercent {
                        Text(String(format: "%.4f%%", sliderBinding.wrappedValue * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                            .disabled(!factor.isEnabled)
                    } else {
                        Text(String(format: "%.4f", sliderBinding.wrappedValue))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 70, alignment: .trailing)
                            .disabled(!factor.isEnabled)
                    }
                }
                .opacity(factor.isEnabled ? 1.0 : 0.6)
            }
            .padding(.vertical, 4)
            .opacity(factor.isEnabled ? 1.0 : 0.5)
        )
    }
}

// MARK: - Tooltip Helpers

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
