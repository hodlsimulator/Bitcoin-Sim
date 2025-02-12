//
//  FactorToggleRow.swift
//  BTCMonteCarlo
//
//  Created by . . on 27/12/2024.
//

import SwiftUI

struct FactorToggleRow: View {
    @EnvironmentObject var weeklySimSettings: SimulationSettings
    @EnvironmentObject var monthlySimSettings: MonthlySimulationSettings

    // The unique name for this factor
    let factorName: String

    // Factor display properties
    let iconName: String?
    let title: String
    let parameterDescription: String?
    let sliderRange: ClosedRange<Double>
    let defaultValue: Double
    let tiltBarValue: Double
    let displayAsPercent: Bool

    // Tooltip
    let activeFactor: String?
    let onTitleTap: (String) -> Void

    // Called after toggles/sliders change
    let onFactorChange: () -> Void

    var body: some View {
        // Decide which factor state to use based on the monthly object's period unit.
        let factor = currentFactor()
        guard let factor = factor else {
            return AnyView(
                Text("Factor '\(factorName)' not found!")
                    .foregroundColor(.red)
            )
        }

        // Toggle binding
        let toggleBinding = Binding<Bool>(
            get: { factor.isEnabled },
            set: { newVal in
                print("Toggle set for \(factorName): \(newVal)")
                setFactorEnabled(newVal)
                onFactorChange()
            }
        )

        // Slider binding
        let sliderBinding = Binding<Double>(
            get: {
                factor.currentValue
            },
            set: { newVal in
                let clampedVal = max(min(newVal, factor.maxValue), factor.minValue)
                
                // Replace `if monthlySimSettings.periodUnitMonthly == .months` with:
                if weeklySimSettings.periodUnit == .months {
                    print("Calling monthly userDidDragFactorSliderMonthly for \(factorName)")
                    monthlySimSettings.userDidDragFactorSliderMonthly(factorName, to: clampedVal)
                } else {
                    print("Calling weekly userDidDragFactorSlider for \(factorName)")
                    weeklySimSettings.userDidDragFactorSlider(factorName, to: clampedVal)
                }
                
                // Always unlock factor after a manual drag.
                unlockFactor()
                onFactorChange()
            }
        )

        return AnyView(
            VStack(alignment: .leading, spacing: 4) {
                // Title + Toggle row
                HStack(spacing: 8) {
                    if let icon = iconName, !icon.isEmpty {
                        Button {
                            // Reset to default if user taps icon.
                            resetFactorToDefault()
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
                
                // Slider row
                HStack {
                    Slider(
                        value: sliderBinding,
                        in: sliderRange
                    )
                    .tint(Color(red: 189/255, green: 213/255, blue: 234/255))
                    .disabled(!factor.isEnabled)
                    
                    Text(String(format: "%.2f", tiltBarValue * (sliderBinding.wrappedValue / defaultValue)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 70, alignment: .trailing)
                        .disabled(!factor.isEnabled)
                }
                .opacity(factor.isEnabled ? 1.0 : 0.6)
            }
            .padding(.vertical, 4)
            .opacity(factor.isEnabled ? 1.0 : 0.5)
        )
    }
    
    // -------------------------------------------
    // Helpers to pick factor from weekly or monthly.
    private func currentFactor() -> FactorState? {
        if monthlySimSettings.periodUnitMonthly == .months {
            return monthlySimSettings.factorsMonthly[factorName]
        } else {
            return weeklySimSettings.factors[factorName]
        }
    }
    
    private func setFactorEnabled(_ enabled: Bool) {
        if monthlySimSettings.periodUnitMonthly == .months {
            monthlySimSettings.setFactorEnabled(factorName: factorName, enabled: enabled)
        } else {
            weeklySimSettings.setFactorEnabled(factorName: factorName, enabled: enabled)
        }
    }
    
    private func resetFactorToDefault() {
        if monthlySimSettings.periodUnitMonthly == .months {
            if var f = monthlySimSettings.factorsMonthly[factorName] {
                f.currentValue = defaultValue
                f.isLocked = false
                monthlySimSettings.factorsMonthly[factorName] = f
            }
        } else {
            if var f = weeklySimSettings.factors[factorName] {
                f.currentValue = defaultValue
                f.isLocked = false
                weeklySimSettings.factors[factorName] = f
            }
        }
    }
    
    private func unlockFactor() {
        if monthlySimSettings.periodUnitMonthly == .months {
            if var f = monthlySimSettings.factorsMonthly[factorName] {
                f.isLocked = false
                monthlySimSettings.factorsMonthly[factorName] = f
            }
        } else {
            if var f = weeklySimSettings.factors[factorName] {
                f.isLocked = false
                weeklySimSettings.factors[factorName] = f
            }
        }
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
