//
//  ColumnsCollectionCell.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

/// A two-column approach: each collection cell has 2 tables side by side.
class ColumnsCollectionCell: UICollectionViewCell, UITableViewDataSource, UITableViewDelegate {

    // The two tables
    private let tableViewLeft  = UITableView(frame: .zero, style: .plain)
    private let tableViewRight = UITableView(frame: .zero, style: .plain)

    private var pair: [(String, PartialKeyPath<SimulationData>)] = []
    private var displayedData: [SimulationData] = []

    // Called when either table scrolls vertically,
    // so we can sync the pinned table on the left.
    var onScroll: ((UIScrollView) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        // 1) Setup left table
        tableViewLeft.dataSource = self
        tableViewLeft.delegate = self
        tableViewLeft.showsVerticalScrollIndicator = false
        tableViewLeft.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
        tableViewLeft.translatesAutoresizingMaskIntoConstraints = false

        // >>> ADD THESE LINES so the background stripes fill from the left
        tableViewLeft.cellLayoutMarginsFollowReadableWidth = false
        tableViewLeft.layoutMargins = .zero
        tableViewLeft.separatorInset = .zero

        // 2) Setup right table
        tableViewRight.dataSource = self
        tableViewRight.delegate = self
        tableViewRight.showsVerticalScrollIndicator = false
        tableViewRight.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
        tableViewRight.translatesAutoresizingMaskIntoConstraints = false

        // >>> Same fix here too
        tableViewRight.cellLayoutMarginsFollowReadableWidth = false
        tableViewRight.layoutMargins = .zero
        tableViewRight.separatorInset = .zero

        // 3) Place them side by side
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

    /// Called by the collectionView's cellForItem to pass in the two columns & row data
    func configure(pair: [(String, PartialKeyPath<SimulationData>)],
                   displayedData: [SimulationData]) {
        self.pair = pair
        self.displayedData = displayedData

        // Reload both tables
        tableViewLeft.reloadData()
        tableViewRight.reloadData()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
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
        let colIndex = (tableView == tableViewLeft) ? 0 : 1

        if colIndex < pair.count {
            let (_, partial) = pair[colIndex]
            cell.configure(rowData, partialKey: partial)
        } else {
            cell.configure(rowData, partialKey: nil)
        }
        
        // row color
        cell.backgroundColor = (indexPath.row % 2 == 0)
            ? UIColor(white: 0.10, alpha: 1.0)
            : UIColor(white: 0.14, alpha: 1.0)
        
        return cell
    }

    // MARK: - UITableViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Let the parent sync pinned table
        onScroll?(scrollView)
    }
}
