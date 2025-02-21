//
//  TwoColumnPairCell.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

/// A UICollectionViewCell that displays two columns (tables) side by side.
/// Each column is one (String, PartialKeyPath<SimulationData>) from the "pair".
class TwoColumnPairCell: UICollectionViewCell {

    // Two tables for the two columns
    let tableViewLeft  = UITableView(frame: .zero, style: .plain)
    let tableViewRight = UITableView(frame: .zero, style: .plain)

    // The pair itself (e.g. [("BTC Price", \.btcPriceUSD), ("Portfolio", \.portfolioValueUSD)])
    private var pair: [(String, PartialKeyPath<SimulationData>)] = []
    private var displayedData: [SimulationData] = []

    // A callback so the parent can sync vertical scrolling with the pinned table
    var onScroll: ((UIScrollView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // 1) Configure each table
        setupTable(tableViewLeft)
        setupTable(tableViewRight)

        // 2) Create containers for each table
        let leftContainer = UIView()
        let rightContainer = UIView()

        leftContainer.translatesAutoresizingMaskIntoConstraints = false
        rightContainer.translatesAutoresizingMaskIntoConstraints = false

        // 3) Add the tables to their containers
        leftContainer.addSubview(tableViewLeft)
        rightContainer.addSubview(tableViewRight)

        tableViewLeft.translatesAutoresizingMaskIntoConstraints = false
        tableViewRight.translatesAutoresizingMaskIntoConstraints = false

        // 4) Constrain tableViewLeft with a 20pt gap on the left
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

        // 6) Now stack these two containers side by side
        let mainStack = UIStackView(arrangedSubviews: [leftContainer, rightContainer])
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
        table.delegate = self
        table.separatorStyle = .none
        table.backgroundColor = .clear
        table.showsVerticalScrollIndicator = false

        // Register a row cell for each row
        table.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
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
