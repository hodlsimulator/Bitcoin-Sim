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
    private let columnsCollectionVC = TwoColumnCollectionViewController()
    
    // Labels for the pinned column header & the two dynamic column titles
    private let pinnedHeaderLabel = UILabel()
    private let col1Label         = UILabel()
    private let col2Label         = UILabel()
    
    // Prevent infinite scroll-callback loops
    private var isSyncingScroll = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // Disable any auto-inset adjustments so both pinned table and column tables line up.
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
        // 4) Vertical scroll sync callback
        // ----------------------------------------------------------------
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncScroll(from: scrollView, to: self?.pinnedTableView)
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
        let topIndex = IndexPath(row: 0, section: 0)
        pinnedTableView.scrollToRow(at: topIndex, at: .top, animated: true)
    }
    
    /// Sync pinned & columns table scrolled offsets
    private func syncScroll(from source: UIScrollView?, to target: UIScrollView?) {
        guard !isSyncingScroll, let source = source, let target = target else { return }
        
        isSyncingScroll = true
        target.contentOffset = source.contentOffset
        isSyncingScroll = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("PinnedColumnTablesVC pinnedTableView frame:", pinnedTableView.frame)
        print("PinnedColumnTablesVC pinnedTableView contentInset:", pinnedTableView.contentInset)
        print("PinnedColumnTablesVC pinnedTableView adjustedContentInset:", pinnedTableView.adjustedContentInset)
        
        // Debugging columnsCollectionVC positioning issue
        if let superview = columnsCollectionVC.view.superview {
            print("columnsCollectionVC.view superview:", superview)
            print("Superview frame:", superview.frame)
            print("Superview constraints:")
            for constraint in superview.constraints {
                print("  -", constraint)
            }
        } else {
            print("columnsCollectionVC.view superview: nil")
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
        guard let rep = representable else { return }

        // near-bottom detection (unchanged)
        let offsetY      = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight   = scrollView.frame.size.height
        
        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)
        
        // Pass that up to SwiftUI
        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
        
        // Prevent infinite loops
        guard !isSyncingScroll else { return }
        isSyncingScroll = true
        
        // Now figure out which two-column cell is centered in the collection
        if let cv = columnsCollectionVC.internalCollectionView {
            let cvCenterX = cv.contentOffset.x + (cv.bounds.width / 2.0)
            let cvCenterY = cv.contentOffset.y + (cv.bounds.height / 2.0)
            let centerPoint = CGPoint(x: cvCenterX, y: cvCenterY)
            
            if let indexPath = cv.indexPathForItem(at: centerPoint),
               let cell = cv.cellForItem(at: indexPath) as? TwoColumnPairCell {
                
                // We have the 2-column cell that's currently on screen
                // Sync its left/right table offsets with the pinned table
                cell.tableViewLeft.contentOffset.y  = scrollView.contentOffset.y
                cell.tableViewRight.contentOffset.y = scrollView.contentOffset.y
            }
        }
        
        isSyncingScroll = false
    }
}
