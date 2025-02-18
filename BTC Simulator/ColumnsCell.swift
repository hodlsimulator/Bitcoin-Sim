//
//  ColumnsCell.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

/// A UITableViewCell that shows multiple columns side by side in a horizontal UIStackView.
class ColumnsCell: UITableViewCell {
    
    private let stackView = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        backgroundColor = .clear
        selectionStyle = .none
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Fill this row with labels for each column
    func configure(rowData: SimulationData,
                   columns: [(String, PartialKeyPath<SimulationData>)],
                   rowIndex: Int)
    {
        // Clear any existing subviews in the stack
        stackView.arrangedSubviews.forEach { sub in
            stackView.removeArrangedSubview(sub)
            sub.removeFromSuperview()
        }
        
        for (title, kp) in columns {
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = .white

            // Example: get the cell text from rowData
            label.text = formatValue(rowData, kp)
            stackView.addArrangedSubview(label)
        }

        let bg = rowIndex % 2 == 0
            ? UIColor(white: 0.10, alpha: 1)
            : UIColor(white: 0.14, alpha: 1)
        contentView.backgroundColor = bg
    }

    private func formatValue(_ data: SimulationData,
                             _ keyPath: PartialKeyPath<SimulationData>) -> String {
        // Simplified example. You can replicate your entire `getValueForTable(...)` logic here.
        if let decimalVal = data[keyPath: keyPath] as? Decimal {
            let doubleVal = NSDecimalNumber(decimal: decimalVal).doubleValue
            return String(format: "%.2f", doubleVal)
        }
        else if let doubleVal = data[keyPath: keyPath] as? Double {
            return String(format: "%.2f", doubleVal)
        }
        else if let intVal = data[keyPath: keyPath] as? Int {
            return "\(intVal)"
        }
        else {
            return ""
        }
    }
}
