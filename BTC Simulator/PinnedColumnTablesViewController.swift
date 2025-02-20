//
//  PinnedColumnTablesViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

class PinnedColumnTablesViewController: UIViewController {
    
    var representable: PinnedColumnTablesRepresentable!
    
    let pinnedTableView = UITableView(frame: .zero, style: .plain)
    let columnsTableView = UITableView(frame: .zero, style: .plain)
    
    private var isSyncingScroll = false
    
    // We'll call this whenever we detect that scrolling is near the bottom
    var onIsAtBottomChanged: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // Turn off safeArea-based auto-inset
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
    
    // Called by the parent to scroll all the way down
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

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return representable.displayedData.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let rowData = representable.displayedData[indexPath.row]
        
        if tableView == pinnedTableView {
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
        return 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == pinnedTableView {
            let headerView = UIView()
            headerView.backgroundColor = .black
            
            let label = UILabel()
            label.text = representable.pinnedColumnTitle
            label.textColor = .orange
            label.font = UIFont.boldSystemFont(ofSize: 14)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            headerView.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
                label.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
            ])
            return headerView
            
        } else {
            let headerView = UIView()
            headerView.backgroundColor = .black

            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 16
            stack.alignment = .center
            stack.translatesAutoresizingMaskIntoConstraints = false
            headerView.addSubview(stack)

            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
                stack.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
                stack.topAnchor.constraint(equalTo: headerView.topAnchor),
                stack.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
            ])

            for (title, _) in representable.columns {
                let colLabel = UILabel()
                colLabel.text = title
                colLabel.textColor = .orange
                colLabel.font = UIFont.boldSystemFont(ofSize: 14)
                stack.addArrangedSubview(colLabel)
            }
            return headerView
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    // MARK: - Sync scrolling + detect "at bottom"
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        isSyncingScroll = true

        if scrollView == pinnedTableView {
            columnsTableView.contentOffset = pinnedTableView.contentOffset
        } else if scrollView == columnsTableView {
            pinnedTableView.contentOffset = columnsTableView.contentOffset
        }

        isSyncingScroll = false

        // Update lastViewedRow for SwiftUI
        if let firstVisible = pinnedTableView.indexPathsForVisibleRows?.first {
            representable.lastViewedRow = firstVisible.row
        }

        // Check if near bottom => set representable.isAtBottom and notify parent
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)

        representable.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom) // <-- The critical call
    }
}
