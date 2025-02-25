//
//  PinnedColumnTablesViewController.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

// MARK: - ColumnHeadersCollectionVC
class ColumnHeadersCollectionVC: UICollectionViewController {
    var columnsData: [(String, PartialKeyPath<SimulationData>)] = []
    
    init() {
        let layout = SnapHalfPageFlowLayout()
        super.init(collectionViewLayout: layout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.backgroundColor = .black
        collectionView?.showsHorizontalScrollIndicator = false
        collectionView?.register(HeaderCell.self, forCellWithReuseIdentifier: "HeaderCell")
        collectionView?.clipsToBounds = true
    }
    
    override func collectionView(_ cv: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        columnsData.count
    }
    
    override func collectionView(_ cv: UICollectionView,
                                 cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "HeaderCell", for: indexPath) as! HeaderCell
        let (title, _) = columnsData[indexPath.item]
        cell.configure(title: title)
        return cell
    }
}

class HeaderCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .black
        label.textColor = .orange
        label.font      = .boldSystemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }
    
    func configure(title: String) {
        label.text = title
    }
}

// MARK: - PinnedColumnTablesViewController
class PinnedColumnTablesViewController: UIViewController {
    
    // Provided by SwiftUI wrapper:
    var representable: PinnedColumnTablesRepresentable?
    
    // Called when we detect near-bottom scrolling
    var onIsAtBottomChanged: ((Bool) -> Void)?
    
    // Track the "previous" column index for animation direction
    var previousColumnIndex: Int? = nil

    // We track the current vertical offset so all columns can scroll together
    var currentVerticalOffset: CGPoint = .zero
    private var isSyncingScroll = false
    
    // The pinned table on the left
    let pinnedTableView = UITableView(frame: .zero, style: .plain)

    // The horizontally scrollable columns on the right
    let columnsCollectionVC = TwoColumnCollectionViewController()

    // The separate horizontal collection for column headers
    let columnHeadersVC = ColumnHeadersCollectionVC()

    // The pinned column's header (left side)
    private let pinnedHeaderLabel = UILabel()
    
    // We'll do the "restore column" exactly once after layout
    private var needsInitialColumnScroll = true

    // This lets us override the pinned table width in subclasses (e.g. for landscape).
    // For portrait we keep it at 70 to stay exactly the same as before.
    var pinnedTableWidth: CGFloat {
        return 70
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Don’t extend under nav bars
        edgesForExtendedLayout = []

        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // (A) pinned table
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.dataSource = self
        pinnedTableView.delegate   = self
        pinnedTableView.rowHeight = 44
        pinnedTableView.estimatedRowHeight = 0
        pinnedTableView.tableFooterView = UIView()
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")
        pinnedTableView.separatorStyle = .none
        pinnedTableView.showsVerticalScrollIndicator = false
        if #available(iOS 15.0, *) {
            pinnedTableView.sectionHeaderTopPadding = 0
        }
        
        // (B) top bar with pinnedHeaderLabel + columnHeaders
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
        
        // pinned left area
        let pinnedHeaderView = UIView()
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(pinnedHeaderView)
        NSLayoutConstraint.activate([
            pinnedHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            pinnedHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: headersContainer.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: pinnedTableWidth)
        ])
        
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 18),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // dynamic headers
        let dynamicHeadersContainer = UIView()
        dynamicHeadersContainer.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(dynamicHeadersContainer)
        NSLayoutConstraint.activate([
            dynamicHeadersContainer.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            dynamicHeadersContainer.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            dynamicHeadersContainer.leadingAnchor.constraint(equalTo: pinnedHeaderView.trailingAnchor),
            dynamicHeadersContainer.trailingAnchor.constraint(equalTo: headersContainer.trailingAnchor)
        ])
        
        addChild(columnHeadersVC)
        dynamicHeadersContainer.addSubview(columnHeadersVC.view)
        columnHeadersVC.view.translatesAutoresizingMaskIntoConstraints = false
        columnHeadersVC.didMove(toParent: self)
        NSLayoutConstraint.activate([
            columnHeadersVC.view.topAnchor.constraint(equalTo: dynamicHeadersContainer.topAnchor),
            columnHeadersVC.view.bottomAnchor.constraint(equalTo: dynamicHeadersContainer.bottomAnchor),
            columnHeadersVC.view.leadingAnchor.constraint(equalTo: dynamicHeadersContainer.leadingAnchor),
            columnHeadersVC.view.trailingAnchor.constraint(equalTo: dynamicHeadersContainer.trailingAnchor)
        ])
        
        // (C) pinnedTable below top bar
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        NSLayoutConstraint.activate([
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: pinnedTableWidth)
        ])
        
        // (D) the main columns to the right
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
        
        // bring pinned table in front
        view.bringSubviewToFront(pinnedTableView)
        pinnedTableView.layer.zPosition = 9999

        // Hook up vertical sync from columns
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncVerticalTables(with: scrollView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Let them sync horizontally
        if let headersCV = columnHeadersVC.collectionView,
           let dataCV = columnsCollectionVC.internalCollectionView {
            headersCV.delegate = self
            dataCV.delegate    = self
        }
    }
    
    // MARK: - viewWillAppear => reload data, scroll to row
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let rep = representable else { return }
        
        pinnedHeaderLabel.text = rep.pinnedColumnTitle
        
        // Reload pinned table so it’s not empty
        pinnedTableView.reloadData()
        
        // If there is row data, scroll to lastViewedRow
        let totalRows = rep.displayedData.count
        if totalRows > 0 {
            let safeRow = min(rep.lastViewedRow, totalRows - 1)
            let ip = IndexPath(row: safeRow, section: 0)
            pinnedTableView.scrollToRow(at: ip, at: .top, animated: false)
        }
        
        // Setup the column headers
        columnHeadersVC.columnsData = rep.columns
        columnHeadersVC.collectionView?.reloadData()

        // Setup the columns collection
        columnsCollectionVC.columnsData   = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        columnsCollectionVC.reloadData()
        
        // We'll do the column scroll in viewDidLayoutSubviews exactly once
        needsInitialColumnScroll = true
    }

    // MARK: - viewDidLayoutSubviews => restore the column index once
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Adjust pinned table bottom inset for safe area
        let bottomSafeArea = view.safeAreaInsets.bottom
        pinnedTableView.contentInset.bottom = bottomSafeArea
        pinnedTableView.verticalScrollIndicatorInsets =
            UIEdgeInsets(top: 0, left: 0, bottom: bottomSafeArea, right: 0)

        guard needsInitialColumnScroll else { return }

        // If the layout’s content size is still zero, we try one dispatch-later attempt
        // so the layout can finalize. (Prevents "invalid item size" or partial layout.)
        if let dataCV = columnsCollectionVC.internalCollectionView,
           dataCV.contentSize.width <= 0 {
            DispatchQueue.main.async { [weak self] in
                self?.restoreColumnIfNeeded()
            }
        } else {
            restoreColumnIfNeeded()
        }
    }
    
    private func restoreColumnIfNeeded() {
        guard needsInitialColumnScroll else { return }
        needsInitialColumnScroll = false

        guard let rep = representable,
              !rep.columns.isEmpty,
              let dataCV = columnsCollectionVC.internalCollectionView else { return }

        // SUGGESTED DEBUG PRINT
        print("Debug: lastViewedColumnIndex on first load is \(rep.lastViewedColumnIndex)")

        // If lastViewedColumnIndex == -1, interpret that as “no memory” => default to 0
        var targetIndex = rep.lastViewedColumnIndex
        if targetIndex == -1 {
            targetIndex = 0
            print("No stored column memory. Defaulting to BTC Price & Portfolio (column 0).")
        }

        // Clamp so we don’t go out of range
        let safeIndex = max(0, min(targetIndex, rep.columns.count - 1))

        // Perform the actual scroll now
        columnsCollectionVC.scrollToColumnIndex(safeIndex)
        columnHeadersVC.collectionView?.contentOffset.x = dataCV.contentOffset.x

        print("Restoring to lastViewedColumnIndex: \(rep.lastViewedColumnIndex) -> actually scrolling to \(safeIndex).")
    }
    
    // MARK: - Snap-based detection
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == columnsCollectionVC.internalCollectionView {
            identifyLeftColumn(in: scrollView)
        }
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if scrollView == columnsCollectionVC.internalCollectionView && !willDecelerate {
            identifyLeftColumn(in: scrollView)
        }
    }
    
    private func identifyLeftColumn(in scrollView: UIScrollView) {
        guard let cv = columnsCollectionVC.internalCollectionView,
              let rep = representable else { return }

        // Because each 'page' is half the width, we shift by 1/4 of the width
        // to figure out which column is in the left half
        let quarterWidth = scrollView.bounds.width / 4.0
        let offsetX = scrollView.contentOffset.x + quarterWidth
        let offsetY = scrollView.bounds.height / 2.0
        let point   = CGPoint(x: offsetX, y: offsetY)

        if let indexPath = cv.indexPathForItem(at: point),
           indexPath.item < columnsCollectionVC.columnsData.count {
            rep.lastViewedColumnIndex = indexPath.item
        }
    }

    // MARK: - Vertical sync
    private func syncVerticalTables(with sourceScrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        isSyncingScroll = true
        let newOffset = sourceScrollView.contentOffset
        
        // If the scroll is from a column, match pinned table offset
        if sourceScrollView != pinnedTableView {
            pinnedTableView.contentOffset = newOffset
        }
        // Also update all column cells
        columnsCollectionVC.updateAllColumnsVerticalOffset(newOffset)
        
        isSyncingScroll = false
        currentVerticalOffset = newOffset
    }

    // MARK: - External calls
    func scrollToBottom() {
        guard let rep = representable else { return }
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            let ip = IndexPath(row: lastIndex, section: 0)
            pinnedTableView.scrollToRow(at: ip, at: .bottom, animated: true)
        }
    }
    func scrollToTop() {
        guard let rep = representable else { return }
        if rep.displayedData.count > 0 {
            pinnedTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

// MARK: - UITableViewDataSource
extension PinnedColumnTablesViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { return 1 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        representable?.displayedData.count ?? 0
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let rep = representable else { return UITableViewCell() }
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PinnedColumnCell", for: indexPath
        ) as? PinnedColumnCell else {
            return UITableViewCell()
        }
        
        let rowData = rep.displayedData[indexPath.row]
        let pinnedValue = rowData[keyPath: rep.pinnedColumnKeyPath]
        cell.configure(pinnedValue: pinnedValue, backgroundIndex: indexPath.row)
        return cell
    }
}

// MARK: - UITableViewDelegate, UICollectionViewDelegate, UIScrollViewDelegate
extension PinnedColumnTablesViewController: UITableViewDelegate, UICollectionViewDelegate, UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 1) If the pinned table scrolled => update lastViewedRow, near-bottom
        if scrollView == pinnedTableView {
            if let rows = pinnedTableView.indexPathsForVisibleRows,
               let firstIP = rows.first,
               let rep = representable {
                rep.lastViewedRow = firstIP.row
            }
            
            guard let rep = representable else { return }
            
            // near-bottom detection
            let offsetY       = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let frameHeight   = scrollView.frame.size.height
            let threshold: CGFloat = 50
            let distance = contentHeight - (offsetY + frameHeight)
            let atBottom = (distance < threshold)
            rep.isAtBottom = atBottom
            onIsAtBottomChanged?(atBottom)
            
            // sync vertical offset
            syncVerticalTables(with: scrollView)
        }
        // 2) If columns scrolled => update header offset
        else if let dataCV = columnsCollectionVC.internalCollectionView,
                scrollView == dataCV,
                let headersCV = columnHeadersVC.collectionView {
            headersCV.contentOffset.x = dataCV.contentOffset.x
        }
        // 3) If header scrolled => match the columns
        else if let headersCV = columnHeadersVC.collectionView,
                scrollView == headersCV,
                let dataCV = columnsCollectionVC.internalCollectionView {
            dataCV.contentOffset.x = headersCV.contentOffset.x
        }
    }
}
