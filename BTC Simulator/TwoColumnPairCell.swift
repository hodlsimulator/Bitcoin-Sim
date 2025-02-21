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

        // 1) Configure the two table views
        setupTable(tableViewLeft)
        setupTable(tableViewRight)

        // 2) Place them side by side in a horizontal stack
        let stack = UIStackView(arrangedSubviews: [tableViewLeft, tableViewRight])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
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
        table.translatesAutoresizingMaskIntoConstraints = false

        // Register a row cell for each row in the column
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

        // Determine which column (left = 0, right = 1).
        // If there's only 1 column in pair, the right table shows no data.
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
