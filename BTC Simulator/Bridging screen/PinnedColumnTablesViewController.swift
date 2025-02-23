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

    var currentVerticalOffset: CGPoint = .zero
    
    // Left table for the pinned (e.g. "Week") column
    let pinnedTableView = UITableView(frame: .zero, style: .plain)
    
    // Our single-column-collection to the right
    // (renamed for clarity, but you can keep the old name if you like)
    let columnsCollectionVC = TwoColumnCollectionViewController()

    // Labels for pinned column header & the two dynamic column titles
    private let pinnedHeaderLabel = UILabel()
    private let col1Label         = UILabel()
    private let col2Label         = UILabel()
    
    // Prevent infinite scroll-callback loops
    private var isSyncingScroll = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.contentInset = .zero
        pinnedTableView.scrollIndicatorInsets = .zero
        if #available(iOS 11.0, *) {
            columnsCollectionVC.internalCollectionView?.contentInsetAdjustmentBehavior = .never
            columnsCollectionVC.internalCollectionView?.contentInset = .zero
            columnsCollectionVC.internalCollectionView?.scrollIndicatorInsets = .zero
        }
        
        // Temporary for debugging
        pinnedTableView.backgroundColor = .red
        
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
        pinnedTableView.separatorStyle = .singleLine  // Changed to show separators
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")

        // Remove table insets
        pinnedTableView.cellLayoutMarginsFollowReadableWidth = false
        pinnedTableView.layoutMargins = .zero
        pinnedTableView.separatorInset = .zero
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
        // 3) The single-column collection to the right of pinned table
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
        // 4) Vertical scroll sync callback
        // ----------------------------------------------------------------
        // If the user scrolls inside a OneColumnCell, we unify offsets:
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncAllTables(with: scrollView)
        }
        
        // 5) Which column is centered?
        columnsCollectionVC.onCenteredColumnChanged = { [weak self] columnIndex in
            guard let self = self else { return }
            
            // Update col1Label/col2Label based on the centered column + 1
            let allColumns = self.columnsCollectionVC.columnsData
            
            if columnIndex < allColumns.count {
                self.col1Label.text = allColumns[columnIndex].0  // the "title"
            } else {
                self.col1Label.text = nil
            }
            
            let secondIndex = columnIndex + 1
            if secondIndex < allColumns.count {
                self.col2Label.text = allColumns[secondIndex].0
            } else {
                self.col2Label.text = nil
            }
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
        
        // Just pass the columns & data directly to columnsCollectionVC
        columnsCollectionVC.columnsData   = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        columnsCollectionVC.reloadData()
    }
    
    // Called by a parent if you want to scroll pinned table to the bottom
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

            // After the table view finishes animating, update offsets
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                // This ensures pinnedTableView.contentOffset is fresh
                self.syncAllTables(with: self.pinnedTableView)
            }
        }
    }
    
    /// Sync pinned table & all visible single-column cells
    private func syncAllTables(with sourceScrollView: UIScrollView) {
            guard !isSyncingScroll else { return }
            isSyncingScroll = true
            
            let newOffset = sourceScrollView.contentOffset
            
            if sourceScrollView != pinnedTableView {
                pinnedTableView.contentOffset = newOffset
            }
            
            // Update each visible OneColumnCell
            if let cv = columnsCollectionVC.internalCollectionView {
                for cell in cv.visibleCells {
                    if let oneColCell = cell as? OneColumnCell {
                        // We can’t do oneColCell.tableView directly if it's private
                        // So either make tableView internal or add a method:
                        oneColCell.setVerticalOffset(newOffset)
                    }
                }
            }
        
            currentVerticalOffset = newOffset
            
            isSyncingScroll = false
        }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bottomSafeArea = view.safeAreaInsets.bottom
        
        pinnedTableView.contentInset.bottom = bottomSafeArea
        
        // For iOS 13+:
        if #available(iOS 13.0, *) {
            pinnedTableView.verticalScrollIndicatorInsets =
                UIEdgeInsets(top: 0, left: 0, bottom: bottomSafeArea, right: 0)
        } else {
            // Fallback if you need iOS < 13 support
            pinnedTableView.scrollIndicatorInsets.bottom = bottomSafeArea
        }
    }
}

// MARK: - UITableViewDataSource & Delegate

extension PinnedColumnTablesViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
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
        
        // The pinned column is "week" (or "month" or something else)
        let pinnedValue = rowData[keyPath: rep.pinnedColumnKeyPath]
        cell.configure(pinnedValue: pinnedValue, backgroundIndex: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        44
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Don’t do anything if we’re already syncing
        guard !isSyncingScroll else { return }

        // Sync pinned + visible column offsets
        syncAllTables(with: scrollView)

        // near-bottom detection
        guard let rep = representable else { return }
        
        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.size.height
        
        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)

        // Pass that to SwiftUI or your parent
        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
    }

    
    // In PinnedColumnTablesViewController:
    private func checkIfNearBottom(_ scrollView: UIScrollView) {
        guard let rep = representable else { return }

        let offsetY       = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.size.height
        
        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)

        // Pass that to SwiftUI or your parent callback
        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
    }
}
