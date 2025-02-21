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
    
    // Instead of a single columns table, we now embed a ColumnsPagerViewController on the right
    private let columnsPagerVC = ColumnsPagerViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal,
        options: nil
    )
    
    // A label/header for the pinned column
    private let pinnedHeaderLabel = UILabel()
    
    // We'll call this whenever we detect scrolling is near the bottom
    var onIsAtBottomChanged: ((Bool) -> Void)?
    
    private var isSyncingScroll = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // 1) Create a container for the entire header row.
        let headersContainer = UIView()
        headersContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headersContainer)
        
        // Constrain this headersContainer to the top of our VC’s view.
        // We'll give it a fixed height of 40 for the headers.
        let headerHeight: CGFloat = 40
        NSLayoutConstraint.activate([
            headersContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headersContainer.heightAnchor.constraint(equalToConstant: headerHeight)
        ])
        
        // 2) The pinned header (left side, for "Week")
        let pinnedHeaderView = UIView()
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(pinnedHeaderView)
        
        // Give it the same width as the pinned table (70).
        NSLayoutConstraint.activate([
            pinnedHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            pinnedHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: headersContainer.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        // Add the "Week" label
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 8),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // 3) A columns header view (right side) for the two column titles
        let columnsHeaderView = UIView()
        columnsHeaderView.backgroundColor = .black
        columnsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(columnsHeaderView)
        
        // Fill the remaining width to the right
        NSLayoutConstraint.activate([
            columnsHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            columnsHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            columnsHeaderView.leadingAnchor.constraint(equalTo: pinnedHeaderView.trailingAnchor),
            columnsHeaderView.trailingAnchor.constraint(equalTo: headersContainer.trailingAnchor)
        ])
        
        // --- REMOVE UIStackView. Instead, add two labels with explicit constraints ---
        // (1) BTC Price label near the left
        let col1Label = UILabel()
        col1Label.text = "BTC Price (USD)"
        col1Label.textColor = .orange
        col1Label.font = UIFont.boldSystemFont(ofSize: 14)
        col1Label.translatesAutoresizingMaskIntoConstraints = false
        columnsHeaderView.addSubview(col1Label)
        
        NSLayoutConstraint.activate([
            col1Label.leadingAnchor.constraint(equalTo: columnsHeaderView.leadingAnchor, constant: 6),
            col1Label.centerYAnchor.constraint(equalTo: columnsHeaderView.centerYAnchor)
        ])
        
        // (2) Portfolio label, shifted left by adjusting the constant to your preference
        let col2Label = UILabel()
        col2Label.text = "Portfolio (USD)"
        col2Label.textColor = .orange
        col2Label.font = UIFont.boldSystemFont(ofSize: 14)
        col2Label.translatesAutoresizingMaskIntoConstraints = false
        columnsHeaderView.addSubview(col2Label)
        
        NSLayoutConstraint.activate([
            // Adjust the 165 constant to position the Portfolio label as needed
            col2Label.leadingAnchor.constraint(equalTo: columnsHeaderView.leadingAnchor, constant: 165),
            col2Label.centerYAnchor.constraint(equalTo: columnsHeaderView.centerYAnchor)
        ])
        
        // 4) Now set up the pinned table below the header row
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        
        NSLayoutConstraint.activate([
            // pinned table is directly beneath the headersContainer
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        // 5) Embed the columns pager to the right of the pinned table
        addChild(columnsPagerVC)
        columnsPagerVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(columnsPagerVC.view)
        columnsPagerVC.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            columnsPagerVC.view.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            columnsPagerVC.view.leadingAnchor.constraint(equalTo: pinnedTableView.trailingAnchor),
            columnsPagerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            columnsPagerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // 6) Set up pinnedTableView properties
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.dataSource = self
        pinnedTableView.delegate = self
        pinnedTableView.separatorStyle = .none
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If representable is nil, bail
        guard let rep = representable else { return }

        // Update the pinned header text
        pinnedHeaderLabel.text = rep.pinnedColumnTitle

        // Reload pinned table
        pinnedTableView.reloadData()
        
        // Convert the partial keypaths in rep.columns to KeyPath<SimulationData, Decimal>
        // Filter out any columns that aren’t Decimal:
        let decimalColumns = rep.columns.compactMap { (title, partial) -> (String, KeyPath<SimulationData, Decimal>)? in
            guard let kp = partial as? KeyPath<SimulationData, Decimal> else {
                return nil
            }
            return (title, kp)
        }
        
        // If you want to skip the pinned column in the pager, do .dropFirst()
        // columnsPagerVC.allColumns = Array(decimalColumns.dropFirst())
        // Otherwise, use the full list:
        columnsPagerVC.allColumns = decimalColumns
        
        // Pass all the row data to the pager
        columnsPagerVC.displayedData = rep.displayedData
        
        // Force the pager to rebuild its pages
        columnsPagerVC.reloadPages()
    }
    
    // Called by the parent to scroll pinned table to the bottom
    func scrollToBottom() {
        guard let rep = representable else { return }
        
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            let pinnedPath = IndexPath(row: lastIndex, section: 0)
            pinnedTableView.scrollToRow(at: pinnedPath, at: .bottom, animated: true)
        }
        // The pager side would also scroll if you code that in SinglePageColumnsVC,
        // but that requires more advanced sync logic across each page’s table.
    }
}

// MARK: - UITableViewDataSource & Delegate (For pinned table)
extension PinnedColumnTablesViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return representable?.displayedData.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let rep = representable else {
            return UITableViewCell()
        }
        
        let rowData = rep.displayedData[indexPath.row]
        
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PinnedColumnCell",
            for: indexPath
        ) as? PinnedColumnCell else {
            return UITableViewCell()
        }
        
        let pinnedValue = rowData[keyPath: rep.pinnedColumnKeyPath]
        cell.configure(pinnedValue: pinnedValue, backgroundIndex: indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }

    // If you want the pinned table to sync scrolling with the pager’s table,
    // you’d need to detect which SinglePageColumnsVC is active and sync its scrollView.
    // That’s more advanced, so we’ll skip for now.
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // We'll still do the "near bottom" detection
        guard let rep = representable else { return }

        // Check if near bottom => set rep.isAtBottom and notify parent
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height

        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)

        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
        
        // (No direct sync to columns, because we have a pager now.)
    }
}
