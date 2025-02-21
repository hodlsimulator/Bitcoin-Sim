//
//  SinglePageColumnsVC.swift
//  BTCMonteCarlo
//
//  Created by . . on 20/02/2025.
//

import UIKit

// Helper extension for formattedWithSeparator()
extension Decimal {
    func formattedWithSeparator() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.groupingSeparator = ","
        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}

class SinglePageColumnsVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    // The columns we'll display for this page (up to 2).
    var columnsToShow: [(String, KeyPath<SimulationData, Decimal>)]?
    
    // The entire array of rows to be shown in this table.
    var displayedData: [SimulationData] = []
    
    // A closure the parent can set to sync scrolling
    var onScroll: ((UIScrollView) -> Void)?
    
    // A simple table to list the 2 columns side by side.
    let tableView = UITableView(frame: .zero, style: .plain)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Basic table setup
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.backgroundColor = .clear
        
        // We'll register a custom cell class.
        tableView.register(TwoColumnCell.self, forCellReuseIdentifier: "TwoColumnCell")
        
        // Add the table view to our VC’s view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Constrain the table to fill the VC
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TwoColumnCell", for: indexPath)
                as? TwoColumnCell else {
            return UITableViewCell()
        }
        
        let rowData = displayedData[indexPath.row]
        
        // If we have exactly 2 columns, we display them in the cell’s 2 labels.
        // If there's only 1 column, we show one label.
        if let cols = columnsToShow {
            // Column #1
            if cols.indices.contains(0) {
                let (_, keypath) = cols[0]
                let val1 = rowData[keyPath: keypath]
                cell.label1.text = val1.formattedWithSeparator()
            } else {
                cell.label1.text = nil
            }
            
            // Column #2
            if cols.indices.contains(1) {
                let (_, keypath) = cols[1]
                let val2 = rowData[keyPath: keypath]
                cell.label2.text = val2.formattedWithSeparator()
            } else {
                cell.label2.text = nil
            }
        } else {
            cell.label1.text = nil
            cell.label2.text = nil
        }
        
        // NEW: alternate row colours, matching the pinned table
        let isEvenRow = (indexPath.row % 2 == 0)
        cell.contentView.backgroundColor = isEvenRow
            ? UIColor(white: 0.10, alpha: 1)
            : UIColor(white: 0.14, alpha: 1)
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Let the parent know we're scrolling so it can sync
        onScroll?(scrollView)
    }
}

// MARK: - Custom TwoColumnCell

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
