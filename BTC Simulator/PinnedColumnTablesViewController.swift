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
    
    // Now we embed our new ColumnsCollectionViewController on the right
    private let columnsCollectionVC = ColumnsCollectionViewController()
    
    // A label/header for the pinned column
    private let pinnedHeaderLabel = UILabel()
    
    // Two labels for the dynamic column titles
    private let col1Label = UILabel()
    private let col2Label = UILabel()
    
    // Prevent infinite scroll-callback loops
    private var isSyncingScroll = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)

        // 1) Container for the entire header row
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
        
        // 2) The pinned header (left side)
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
        
        // 3) A columns header view (right side)
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
        
        // 4) Pinned table below the header row
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        
        NSLayoutConstraint.activate([
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        // 5) Add columnsCollectionVC as a child
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
        
        // pinnedTableView properties
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.dataSource = self
        pinnedTableView.delegate = self
        pinnedTableView.separatorStyle = .none
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")

        // 6) Let each collection cell sync its scrolling with pinned table
        // We'll define how in step 4 of your plan (when we build the columns collection).
        // For now, here's a callback:
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncScroll(from: scrollView, to: self?.pinnedTableView)
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
        
        // Pass partial key paths to the columns collection
        columnsCollectionVC.allColumns = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        
        // Reload the collection
        // columnsCollectionVC.collectionView?.reloadData()
        
        columnsCollectionVC.allColumns = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        columnsCollectionVC.reloadCollectionData()
        
        // For sync
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncScroll(from: scrollView, to: self?.pinnedTableView)
        }
    }
    
    // Called by parent to scroll pinned table to the bottom
    func scrollToBottom() {
        guard let rep = representable else { return }
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            let pinnedPath = IndexPath(row: lastIndex, section: 0)
            pinnedTableView.scrollToRow(at: pinnedPath, at: .bottom, animated: true)
            
            // If you'd like, you can also scroll any visible table in columnsCollectionVC
            // But with multiple columns, you can pick a standard or skip
        }
    }

    func scrollToTop() {
        let topIndex = IndexPath(row: 0, section: 0)
        pinnedTableView.scrollToRow(at: topIndex, at: .top, animated: true)
        
        // Similarly, you can scroll the first visible column's table if you want
    }
    
    // Keep pinned & columns table scrolled together
    private func syncScroll(from source: UIScrollView?, to target: UIScrollView?) {
        guard !isSyncingScroll, let source = source, let target = target else { return }
        
        isSyncingScroll = true
        target.contentOffset = source.contentOffset
        isSyncingScroll = false
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
        
        // near-bottom detection
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.size.height
        
        let nearBottomThreshold: CGFloat = 50
        let distanceFromBottom = contentHeight - (offsetY + frameHeight)
        let atBottom = (distanceFromBottom < nearBottomThreshold)
        
        // Pass that up to SwiftUI
        rep.isAtBottom = atBottom
        onIsAtBottomChanged?(atBottom)
        
        // Sync pinned -> the "current" column's table
        // We'll just pick "some" visible column if you want.
        // Because there's multiple columns visible at once,
        // you'd pick the first visible cell or something similar if needed.
        // For now, you can skip it or implement more advanced logic.
    }
}
