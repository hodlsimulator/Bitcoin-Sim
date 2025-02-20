//
//  PinnedColumnTablesViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

/// A UIKit view controller that manages two table views side by side:
/// - Left pinned table for "Week" (or pinnedColumn)
/// - Right table for the other columns
///
/// They share the same row count and sync vertical scrolling so they scroll together.
/// The SwiftUI side is wrapped in `PinnedColumnTablesRepresentable`.
class PinnedColumnTablesViewController: UIViewController {

    // Reference to the bridging struct so we can read data & update SwiftUI state
    var representable: PinnedColumnTablesRepresentable!

    /// The left pinned table
    let pinnedTableView = UITableView(frame: .zero, style: .plain)

    /// The right table with the columns
    let columnsTableView = UITableView(frame: .zero, style: .plain)

    /// Flag to prevent re-entrant scroll syncing
    private var isSyncingScroll = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // Turn off safeArea-based auto-inset for both tables:
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        columnsTableView.contentInsetAdjustmentBehavior = .never
    
        // Setup pinned table
        pinnedTableView.dataSource = self
        pinnedTableView.delegate = self
        pinnedTableView.separatorStyle = .none
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")

        // Setup columns table
        columnsTableView.dataSource = self
        columnsTableView.delegate = self
        columnsTableView.separatorStyle = .none
        columnsTableView.backgroundColor = .clear
        columnsTableView.showsVerticalScrollIndicator = true
        columnsTableView.register(ColumnsCell.self, forCellReuseIdentifier: "ColumnsCell")

        // Layout
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        columnsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        view.addSubview(columnsTableView)

        NSLayoutConstraint.activate([
            // Pinned table on the left, fixed width
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.topAnchor.constraint(equalTo: view.topAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70),

            // Columns table fills the rest
            columnsTableView.leadingAnchor.constraint(equalTo: pinnedTableView.trailingAnchor),
            columnsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            columnsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            columnsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    /// SwiftUI triggers this when it wants to scroll to bottom
    func scrollToBottom() {
        let rowCount = representable.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            let pinnedPath = IndexPath(row: lastIndex, section: 0)
            let columnsPath = IndexPath(row: lastIndex, section: 0)

            pinnedTableView.scrollToRow(at: pinnedPath, at: .bottom, animated: true)
            columnsTableView.scrollToRow(at: columnsPath, at: .bottom, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension PinnedColumnTablesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        // Both tables share the same row count
        return representable.displayedData.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rowData = representable.displayedData[indexPath.row]

        if tableView == pinnedTableView {
            // Pinned column cell
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "PinnedColumnCell",
                for: indexPath
            ) as? PinnedColumnCell else {
                return UITableViewCell()
            }
            let pinnedValue = rowData[keyPath: representable.pinnedColumnKeyPath]
            cell.configure(pinnedValue: pinnedValue, backgroundIndex: indexPath.row)
            return cell

        } else {
            // Columns cell
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "ColumnsCell",
                for: indexPath
            ) as? ColumnsCell else {
                return UITableViewCell()
            }
            cell.configure(
                rowData: rowData,
                columns: representable.columns,
                rowIndex: indexPath.row
            )
            return cell
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Adjust as needed
        return 44
    }

    // MARK: Sync the scrolling of both tables
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        isSyncingScroll = true

        if scrollView == pinnedTableView {
            // Make columns table match the pinned table's vertical offset
            columnsTableView.contentOffset = pinnedTableView.contentOffset
        } else if scrollView == columnsTableView {
            // Make pinned table match the columns table's offset
            pinnedTableView.contentOffset = columnsTableView.contentOffset
        }

        isSyncingScroll = false

        // Save the top visible row in SwiftUI's lastViewedRow, if you want
        // the first visible row:
        if let firstVisible = pinnedTableView.indexPathsForVisibleRows?.first {
            representable.lastViewedRow = firstVisible.row
        }
    }
}
