//
//  OneColumnCell.swift
//  BTCMonteCarlo
//
//  Created by . . on 22/02/2025.
//

import UIKit

class OneColumnCell: UICollectionViewCell, UITableViewDelegate, UITableViewDataSource {
    
    private let tableView = UITableView(frame: .zero, style: .plain)

    // Data for this single column
    private var partialKey: PartialKeyPath<SimulationData>?
    private var displayedData: [SimulationData] = []
    
    // Called if user scrolls vertically in this table
    var onScroll: ((UIScrollView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        
        // Don’t let iOS adjust the insets
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate   = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false

        // Register row cell
        tableView.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
        
        // Lock row height so columns don’t drift
        tableView.rowHeight = 44
        tableView.estimatedRowHeight = 0
        
        // Remove extra margins and insets
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.layoutMargins = .zero
        tableView.separatorInset = .zero
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
        tableView.separatorStyle = .none
        
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }

        contentView.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: contentView.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func configure(columnTitle: String,
                   partialKey: PartialKeyPath<SimulationData>,
                   displayedData: [SimulationData]) {
        // e.g. self.columnTitle = columnTitle
        self.partialKey = partialKey
        self.displayedData = displayedData
        tableView.reloadData()
    }
    
    // MARK: - TableView DataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        displayedData.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "OneColumnRowCell",
            for: indexPath
        ) as? OneColumnRowCell else {
            return UITableViewCell()
        }
        
        let rowData = displayedData[indexPath.row]
        
        // Alternate background stripes
        let stripeColor: UIColor = (indexPath.row % 2 == 0)
            ? UIColor(white: 0.10, alpha: 1.0)
            : UIColor(white: 0.14, alpha: 1.0)
        cell.backgroundColor = stripeColor
        
        // Show row’s numeric value
        cell.configure(rowData, partialKey: partialKey)
        return cell
    }
    
    // MARK: - TableView Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Bubble up so pinned table can sync
        onScroll?(scrollView)
    }
    
    // Let the parent sync this table’s offset
    func setVerticalOffset(_ offset: CGPoint) {
        tableView.contentOffset = offset
    }
}

// MARK: - Row cell
class OneColumnRowCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        backgroundColor = .clear
        selectionStyle  = .none
        preservesSuperviewLayoutMargins = false
        layoutMargins = .zero
        separatorInset = .zero
        
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            // 18 matches the leading used elsewhere for alignment
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func configure(_ rowData: SimulationData,
                   partialKey: PartialKeyPath<SimulationData>?) {
        guard let pk = partialKey else {
            label.text = "-"
            return
        }
        
        // 1) If key path is a Decimal property
        if let kp = pk as? KeyPath<SimulationData, Decimal> {
            let val = rowData[keyPath: kp]
            label.text = val.formattedWithSeparator()
        }
        // 2) If key path is a Double property
        else if let kp = pk as? KeyPath<SimulationData, Double> {
            let val = rowData[keyPath: kp]
            // For BTC fields => 8 decimals
            if kp == \SimulationData.startingBTC ||
               kp == \SimulationData.netBTCHoldings ||
               kp == \SimulationData.netContributionBTC {
                
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.groupingSeparator = ","
                formatter.minimumFractionDigits = 8
                formatter.maximumFractionDigits = 8
                
                label.text = formatter.string(from: NSNumber(value: val)) ?? "\(val)"
            }
            else {
                // Otherwise 2 decimals
                label.text = val.formattedWithSeparator()
            }
        }
        // 3) If key path is an Int property
        else if let kp = pk as? KeyPath<SimulationData, Int> {
            let val = rowData[keyPath: kp]
            label.text = val.formattedWithSeparator()
        }
        else {
            label.text = "-"
        }
    }
}
