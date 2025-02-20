//
//  PinnedColumnTablesViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

class PinnedColumnTablesViewController: UIViewController {
    
    // Make it optional so we don't crash if it's nil
    var representable: PinnedColumnTablesRepresentable?

    // Left table for the pinned column
    let pinnedTableView = UITableView(frame: .zero, style: .plain)
    // Right table for the rest of the columns
    let columnsTableView = UITableView(frame: .zero, style: .plain)
    
    // We'll create references to the header labels/stacks so we can fill them in later:
    private let pinnedHeaderLabel = UILabel()
    private let columnsHeaderStack = UIStackView()
    
    private var isSyncingScroll = false
    
    // We'll call this whenever we detect scrolling is near the bottom
    var onIsAtBottomChanged: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // 1) Create "pinned" header view (left side)
        let pinnedHeaderView = UIView()
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 8),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // 2) Create "columns" header view (right side)
        let columnsHeaderView = UIView()
        columnsHeaderView.backgroundColor = .black
        columnsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        
        columnsHeaderStack.axis = .horizontal
        columnsHeaderStack.spacing = 16
        columnsHeaderStack.alignment = .center
        columnsHeaderStack.translatesAutoresizingMaskIntoConstraints = false
        
        columnsHeaderView.addSubview(columnsHeaderStack)
        NSLayoutConstraint.activate([
            columnsHeaderStack.leadingAnchor.constraint(equalTo: columnsHeaderView.leadingAnchor, constant: 8),
            columnsHeaderStack.trailingAnchor.constraint(equalTo: columnsHeaderView.trailingAnchor, constant: -8),
            columnsHeaderStack.topAnchor.constraint(equalTo: columnsHeaderView.topAnchor),
            columnsHeaderStack.bottomAnchor.constraint(equalTo: columnsHeaderView.bottomAnchor)
        ])

        // 3) Add subviews
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        columnsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        columnsTableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(pinnedHeaderView)
        view.addSubview(columnsHeaderView)
        view.addSubview(pinnedTableView)
        view.addSubview(columnsTableView)
        
        // 4) Layout constraints
        let headerHeight: CGFloat = 40
        
        NSLayoutConstraint.activate([
            // Pinned header on the left
            pinnedHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: 70),
            pinnedHeaderView.heightAnchor.constraint(equalToConstant: headerHeight),
            
            // Columns header on the right
            columnsHeaderView.topAnchor.constraint(equalTo: view.topAnchor),
            columnsHeaderView.leadingAnchor.constraint(equalTo: pinnedHeaderView.trailingAnchor),
            columnsHeaderView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            columnsHeaderView.heightAnchor.constraint(equalToConstant: headerHeight),
            
            // Pinned table below pinnedHeaderView
            pinnedTableView.topAnchor.constraint(equalTo: pinnedHeaderView.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70),
            
            // Columns table below columnsHeaderView
            columnsTableView.topAnchor.constraint(equalTo: columnsHeaderView.bottomAnchor),
            columnsTableView.leadingAnchor.constraint(equalTo: pinnedTableView.trailingAnchor),
            columnsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            columnsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // 5) Table setup
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        columnsTableView.contentInsetAdjustmentBehavior = .never
        
        pinnedTableView.dataSource = self
        pinnedTableView.delegate = self
        pinnedTableView.separatorStyle = .none
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")
        
        columnsTableView.dataSource = self
        columnsTableView.delegate = self
        columnsTableView.separatorStyle = .none
        columnsTableView.backgroundColor = .clear
        columnsTableView.showsVerticalScrollIndicator = true
        columnsTableView.register(ColumnsCell.self, forCellReuseIdentifier: "ColumnsCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If representable is set, update the header label/stack now:
        guard let rep = representable else { return }

        pinnedHeaderLabel.text = rep.pinnedColumnTitle
        
        // Clear out old labels (in case we reload)
        columnsHeaderStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Rebuild column title labels
        for (title, _) in rep.columns {
            let colLabel = UILabel()
            colLabel.text = title
            colLabel.textColor = .orange
            colLabel.font = UIFont.boldSystemFont(ofSize: 14)
            columnsHeaderStack.addArrangedSubview(colLabel)
        }
        
        // Finally reload data in the tables
        pinnedTableView.reloadData()
        columnsTableView.reloadData()
    }
    
    // Called by the parent to scroll both tables all the way down
    func scrollToBottom() {
        guard let rep = representable else { return }
        
        let rowCount = rep.displayedData.count
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
        // If representable is nil, show 0 rows
        return representable?.displayedData.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let rep = representable else {
            return UITableViewCell()
        }
        
        let rowData = rep.displayedData[indexPath.row]
        
        if tableView == pinnedTableView {
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "PinnedColumnCell",
                for: indexPath
            ) as? PinnedColumnCell else {
                return UITableViewCell()
            }
            let pinnedValue = rowData[keyPath: rep.pinnedColumnKeyPath]
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
                columns: rep.columns,
                rowIndex: indexPath.row
            )
            return cell
        }
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
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

        guard let rep = representable else { return }

        // Update lastViewedRow for SwiftUI
        if let firstVisible = pinnedTableView.indexPathsForVisibleRows?.first {
            rep.lastViewedRow = firstVisible.row
        }

        // Check if near bottom => set rep.isAtBottom and notify parent
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)

        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
    }
}
