//
//  PinnedColumnTablesViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

class PinnedColumnTablesViewController: UIViewController {
    
    // We'll have it optional so we don't crash if it's nil
    var representable: PinnedColumnTablesRepresentable?
    
    // If needed: onIsAtBottomChanged from the representable
    var onIsAtBottomChanged: ((Bool) -> Void)?

    // Left table for the pinned (e.g. "Week") column
    let pinnedTableView = UITableView(frame: .zero, style: .plain)
    
    // Our two-column collection to the right
    let columnsCollectionVC = TwoColumnCollectionViewController()
    
    // Labels for the pinned column header & the two dynamic column titles
    private let pinnedHeaderLabel = UILabel()
    private let col1Label         = UILabel()
    private let col2Label         = UILabel()
    
    // Prevent infinite scroll-callback loops
    private var isSyncingScroll = false

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // Disable auto-inset adjustments so pinned table and column tables line up
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        if #available(iOS 11.0, *) {
            columnsCollectionVC.internalCollectionView?.contentInsetAdjustmentBehavior = .never
        }

        // ----------------------------------------------------------------
        // 1) A container for the entire "column headers" row (40 pts tall)
        // ----------------------------------------------------------------
        let headersContainer = UIView()
        headersContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headersContainer)
        
        let headerHeight: CGFloat = 40
        NSLayoutConstraint.activate([
            headersContainer.topAnchor.constraint(equalTo: view.topAnchor),
            headersContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headersContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headersContainer.heightAnchor.constraint(equalToConstant: headerHeight)
        ])
        
        // (A) The pinned header (left side)
        let pinnedHeaderView = UIView()
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(pinnedHeaderView)
        
        NSLayoutConstraint.activate([
            pinnedHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            pinnedHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: headersContainer.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 8),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // (B) The columns header view (right side)
        let columnsHeaderView = UIView()
        columnsHeaderView.backgroundColor = .black
        columnsHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(columnsHeaderView)
        
        NSLayoutConstraint.activate([
            columnsHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            columnsHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            columnsHeaderView.leadingAnchor.constraint(equalTo: pinnedHeaderView.trailingAnchor),
            columnsHeaderView.trailingAnchor.constraint(equalTo: headersContainer.trailingAnchor)
        ])
        
        // col1Label
        col1Label.textColor = .orange
        col1Label.font = UIFont.boldSystemFont(ofSize: 14)
        col1Label.translatesAutoresizingMaskIntoConstraints = false
        columnsHeaderView.addSubview(col1Label)
        
        NSLayoutConstraint.activate([
            col1Label.leadingAnchor.constraint(equalTo: columnsHeaderView.leadingAnchor, constant: 6),
            col1Label.centerYAnchor.constraint(equalTo: columnsHeaderView.centerYAnchor)
        ])
        
        // col2Label
        col2Label.textColor = .orange
        col2Label.font = UIFont.boldSystemFont(ofSize: 14)
        col2Label.translatesAutoresizingMaskIntoConstraints = false
        columnsHeaderView.addSubview(col2Label)
        
        NSLayoutConstraint.activate([
            col2Label.leadingAnchor.constraint(equalTo: columnsHeaderView.leadingAnchor, constant: 165),
            col2Label.centerYAnchor.constraint(equalTo: columnsHeaderView.centerYAnchor)
        ])
        
        // ----------------------------------------------------------------
        // 2) The pinned table, below the 40-pt headersContainer
        // ----------------------------------------------------------------
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        pinnedTableView.dataSource = self
        pinnedTableView.delegate   = self
        pinnedTableView.separatorStyle = .none
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")

        // Remove extra insets/margins
        pinnedTableView.cellLayoutMarginsFollowReadableWidth = false
        pinnedTableView.layoutMargins = .zero
        pinnedTableView.separatorInset = .zero
        
        // On iOS 15+, remove top padding if any
        if #available(iOS 15.0, *) {
            pinnedTableView.sectionHeaderTopPadding = 0
        }

        view.addSubview(pinnedTableView)
        NSLayoutConstraint.activate([
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        // ----------------------------------------------------------------
        // 3) The columns collection to the right of pinned table
        // ----------------------------------------------------------------
        addChild(columnsCollectionVC)
        columnsCollectionVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(columnsCollectionVC.view)
        columnsCollectionVC.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            columnsCollectionVC.view.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            columnsCollectionVC.view.leadingAnchor.constraint(equalTo: pinnedTableView.trailingAnchor),
            columnsCollectionVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            columnsCollectionVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // ----------------------------------------------------------------
        // 4) Sync vertical scrolling
        // ----------------------------------------------------------------
        // Whenever any table in the two-column collection scrolls, we unify offsets:
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncAllTables(with: scrollView)
        }
        
        // 5) Listen for which two-column pair is centered, update col1Label / col2Label
        columnsCollectionVC.onCenteredPairChanged = { [weak self] pair in
            guard let self = self else { return }
            self.col1Label.text = pair.first?.0
            self.col2Label.text = (pair.count > 1) ? pair[1].0 : nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // If representable is nil, do nothing
        guard let rep = representable else { return }

        // Set pinned header text
        pinnedHeaderLabel.text = rep.pinnedColumnTitle

        // Reload pinned table
        pinnedTableView.reloadData()
        
        // Convert columns to pairs => each item has up to 2 columns
        let pairs = buildPairs(from: rep.columns)
        columnsCollectionVC.pairsData = pairs
        columnsCollectionVC.displayedData = rep.displayedData
        columnsCollectionVC.reloadData()
    }
    
    // MARK: - Scroll & Sync

    /// Unify the vertical offset for the pinned table and all visible two-column tables
    private func syncAllTables(with sourceScrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        isSyncingScroll = true
        
        let newOffset = sourceScrollView.contentOffset
        
        // If the source is NOT the pinned table, update the pinned table
        if sourceScrollView != pinnedTableView {
            pinnedTableView.contentOffset = newOffset
        }

        // Update each visible two-column cell's left & right tables
        if let cv = columnsCollectionVC.internalCollectionView {
            for cell in cv.visibleCells {
                if let twoColCell = cell as? TwoColumnPairCell {
                    twoColCell.tableViewLeft.contentOffset  = newOffset
                    twoColCell.tableViewRight.contentOffset = newOffset
                }
            }
        }
        
        isSyncingScroll = false
    }

    // MARK: - Public Methods

    func scrollToBottom() {
        guard let rep = representable else { return }
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            let pinnedPath = IndexPath(row: lastIndex, section: 0)
            pinnedTableView.scrollToRow(at: pinnedPath, at: .bottom, animated: true)
        }
    }

    func scrollToTop() {
        guard let rep = representable else { return }
        if rep.displayedData.count > 0 {
            let topIndex = IndexPath(row: 0, section: 0)
            pinnedTableView.scrollToRow(at: topIndex, at: .top, animated: true)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension PinnedColumnTablesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        
        // The pinned column is "week" (or "month" or something else)
        let pinnedValue = rowData[keyPath: rep.pinnedColumnKeyPath]
        cell.configure(pinnedValue: pinnedValue, backgroundIndex: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        guard let rep = representable else { return }
        
        // near-bottom detection
        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.size.height
        
        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)
        
        // Pass that up to SwiftUI
        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
        
        // Sync pinned table + columns
        syncAllTables(with: scrollView)
    }
}
