//
//  TwoColumnPairCell.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class TwoColumnPairCell: UICollectionViewCell {

    // Two tables for the two columns
    let tableViewLeft  = UITableView(frame: .zero, style: .plain)
    let tableViewRight = UITableView(frame: .zero, style: .plain)

    // The pair itself (e.g. [("BTC Price", \.btcPriceUSD), ("Portfolio", \.portfolioValueUSD)])
    private var pair: [(String, PartialKeyPath<SimulationData>)] = []
    private var displayedData: [SimulationData] = []

    // A callback so the parent can sync vertical scrolling with the pinned table
    var onScroll: ((UIScrollView) -> Void)?

    // Declare containers and stack view as instance properties
    private let leftContainer: UIView
    private let rightContainer: UIView
    private let mainStack: UIStackView

    override init(frame: CGRect) {
        // Initialize the properties before calling super.init
        leftContainer = UIView()
        rightContainer = UIView()
        mainStack = UIStackView(arrangedSubviews: [leftContainer, rightContainer])

        super.init(frame: frame)

        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // 1) Configure each table
        setupTable(tableViewLeft)
        setupTable(tableViewRight)

        // 2) Containers are already initialized, set their properties
        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3) Add the tables to their containers
        leftContainer.addSubview(tableViewLeft)
        rightContainer.addSubview(tableViewRight)

        tableViewLeft.translatesAutoresizingMaskIntoConstraints = false
        tableViewRight.translatesAutoresizingMaskIntoConstraints = false

        // 4) Constrain tableViewLeft with a 40pt gap on the left
        NSLayoutConstraint.activate([
            tableViewLeft.topAnchor.constraint(equalTo: leftContainer.topAnchor),
            tableViewLeft.bottomAnchor.constraint(equalTo: leftContainer.bottomAnchor),
            tableViewLeft.leadingAnchor.constraint(equalTo: leftContainer.leadingAnchor, constant: 40),
            tableViewLeft.trailingAnchor.constraint(equalTo: leftContainer.trailingAnchor)
        ])

        // 5) Constrain tableViewRight normally (no extra left offset)
        NSLayoutConstraint.activate([
            tableViewRight.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            tableViewRight.bottomAnchor.constraint(equalTo: rightContainer.bottomAnchor),
            tableViewRight.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            tableViewRight.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor)
        ])

        // 6) Configure and add mainStack
        mainStack.axis = .horizontal
        mainStack.distribution = .fillEqually
        mainStack.spacing = 0
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    /// Configure this cell with the pair of columns and the shared data array.
    func configure(pair: [(String, PartialKeyPath<SimulationData>)],
                   displayedData: [SimulationData]) {
        self.pair = pair
        self.displayedData = displayedData

        // Reload both tables so they display the correct columns
        tableViewLeft.reloadData()
        tableViewRight.reloadData()
    }

    private func setupTable(_ table: UITableView) {
        table.dataSource = self
        table.delegate   = self
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.showsVerticalScrollIndicator = false
        
        table.contentInsetAdjustmentBehavior = .never
        table.contentInset.top = 0
        
        // Force 44 pt rows, just like pinnedTableView
        table.rowHeight = 44
        
        table.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Log frames after layout is complete
        DispatchQueue.main.async {
            print("TwoColumnPairCell LEFT table frame:", self.tableViewLeft.frame)
            print("TwoColumnPairCell LEFT contentInset:", self.tableViewLeft.contentInset,
                  "adjusted:", self.tableViewLeft.adjustedContentInset)
            print("TwoColumnPairCell RIGHT table frame:", self.tableViewRight.frame)
            print("TwoColumnPairCell RIGHT contentInset:", self.tableViewRight.contentInset,
                  "adjusted:", self.tableViewRight.adjustedContentInset)
            
            // Log container and stack frames
            print("Left container frame:", self.leftContainer.frame)
            print("Right container frame:", self.rightContainer.frame)
            print("Main stack frame:", self.mainStack.frame)
            print("Content view frame:", self.contentView.frame)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension TwoColumnPairCell: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return displayedData.count
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

        // Which column? (left = 0, right = 1)
        let colIndex = (tableView == tableViewLeft) ? 0 : 1
        if colIndex < pair.count {
            let (_, partial) = pair[colIndex]
            cell.configure(with: rowData, partial: partial)
        } else {
            // If the pair had only one column, the right table is blank
            cell.configure(with: rowData, partial: nil)
        }

        // Alternate row background color
        let isEvenRow = (indexPath.row % 2 == 0)
        cell.contentView.backgroundColor = isEvenRow
            ? UIColor(white: 0.10, alpha: 1.0)
            : UIColor(white: 0.14, alpha: 1.0)

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Whenever the user scrolls vertically in either table,
        // call onScroll so the pinned table can sync
        onScroll?(scrollView)
    }
}
