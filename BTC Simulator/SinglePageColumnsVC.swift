//
//  SinglePageColumnsVC.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/02/2025.
//

import UIKit

// MARK: - Helper Extensions for Formatting

extension Decimal {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}

extension Double {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Int {
    func formattedWithSeparator() -> String {
        // If you don’t want decimals for Int, just do:
        // return String(self)
        // But if you want commas for large values, do:
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

class SinglePageColumnsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // The columns we'll display (up to 2 at a time),
    // allowing Decimal, Double, or Int via PartialKeyPath
    var columnsToShow: [(String, PartialKeyPath<SimulationData>)]?
    
    // The entire array of rows to be shown in this table
    var displayedData: [SimulationData] = []
    
    // A closure so the parent can sync scrolling with the pinned table
    var onScroll: ((UIScrollView) -> Void)?
    
    // A simple table that shows the 2 columns side by side
    let tableView = UITableView(frame: .zero, style: .plain)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Basic table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.backgroundColor = .clear
        
        // We'll register a custom cell class
        tableView.register(TwoColumnCell.self, forCellReuseIdentifier: "TwoColumnCell")
        
        // Add the table view to our VC’s view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constrain the table to fill the entire view
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return displayedData.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "TwoColumnCell",
                for: indexPath
              ) as? TwoColumnCell else {
            return UITableViewCell()
        }
        
        let rowData = displayedData[indexPath.row]
        
        // If we have columns, fill label1 & label2
        if let cols = columnsToShow {
            // Column #1
            if cols.indices.contains(0) {
                let (_, partial) = cols[0]
                cell.label1.text = formatValue(rowData, partial: partial)
            } else {
                cell.label1.text = nil
            }
            
            // Column #2
            if cols.indices.contains(1) {
                let (_, partial) = cols[1]
                cell.label2.text = formatValue(rowData, partial: partial)
            } else {
                cell.label2.text = nil
            }
        } else {
            // No columns => blank
            cell.label1.text = nil
            cell.label2.text = nil
        }
        
        // Alternate row colours
        let isEvenRow = (indexPath.row % 2 == 0)
        cell.contentView.backgroundColor = isEvenRow
            ? UIColor(white: 0.10, alpha: 1.0)
            : UIColor(white: 0.14, alpha: 1.0)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Let the parent know we're scrolling so it can sync
        onScroll?(scrollView)
    }
    
    // MARK: - Numeric Value Formatting
    
    /// Given a partial key path in rowData, return a nicely formatted string
    /// for Decimal/Double/Int. Otherwise, return "-"
    private func formatValue(_ rowData: SimulationData,
                             partial: PartialKeyPath<SimulationData>) -> String {
        
        // If it's a Decimal:
        if let kp = partial as? KeyPath<SimulationData, Decimal> {
            let value = rowData[keyPath: kp]
            return value.formattedWithSeparator()
        }
        // If it's a Double:
        if let kp = partial as? KeyPath<SimulationData, Double> {
            let value = rowData[keyPath: kp]
            return value.formattedWithSeparator()
        }
        // If it's an Int:
        if let kp = partial as? KeyPath<SimulationData, Int> {
            let value = rowData[keyPath: kp]
            return value.formattedWithSeparator()
        }
        
        // Fallback if none of the above
        return "-"
    }
}

// MARK: - TwoColumnCell

class TwoColumnCell: UITableViewCell {
    let label1 = UILabel()
    let label2 = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Create a horizontal stack for our two labels
        let stack = UIStackView(arrangedSubviews: [label1, label2])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        
        contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        // Quick styling
        backgroundColor = .clear
        label1.textColor = .white
        label2.textColor = .white
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
}
