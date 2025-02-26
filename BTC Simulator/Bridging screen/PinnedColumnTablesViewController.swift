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
        
        // Let the pinned table handle "tap-to-top"
        collectionView?.scrollsToTop = false
    }
    
    override func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        label.font = .boldSystemFont(ofSize: 14)
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
    
    // Provided by SwiftUI bridging code (PinnedColumnTablesRepresentable)
    var representable: PinnedColumnTablesRepresentable?
    
    // Called when near-bottom scrolling is detected
    var onIsAtBottomChanged: ((Bool) -> Void)?
    
    // We track the table's vertical offset so columns can sync
    var currentVerticalOffset: CGPoint = .zero
    private var isSyncingScroll = false
    
    // Orientation & Layout Coordinators
    internal var pinnedTableWidthOverride: CGFloat = 70
    lazy var portraitCoordinator = PortraitLayoutCoordinator(vc: self)
    lazy var landscapeCoordinator = LandscapeLayoutCoordinator(vc: self)
    private var previousSizeClass: UIUserInterfaceSizeClass?
    
    // UI Elements
    let pinnedTableView = UITableView(frame: .zero, style: .plain)
    let columnsCollectionVC = TwoColumnCollectionViewController()
    let columnHeadersVC = ColumnHeadersCollectionVC()
    internal let pinnedHeaderView = UIView()
    internal let pinnedHeaderLabel = UILabel()
    internal let pinnedHeaderLabelLandscape: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        lbl.textColor = .orange
        lbl.font = .boldSystemFont(ofSize: 14)
        return lbl
    }()
    
    internal var previousColumnIndex: Int? = nil
    
    // We'll restore the column once each time we appear
    private var needsInitialColumnScroll = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // (A) pinned table
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.backgroundColor = .clear
        pinnedTableView.dataSource = self
        pinnedTableView.delegate   = self
        pinnedTableView.rowHeight  = 44
        pinnedTableView.estimatedRowHeight = 0
        pinnedTableView.tableFooterView = UIView()
        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")
        pinnedTableView.separatorStyle = .none
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.scrollsToTop = true
        if #available(iOS 15.0, *) {
            pinnedTableView.sectionHeaderTopPadding = 0
        }
        
        // 1) The top headers container
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
        
        // 2) The pinned header area
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(pinnedHeaderView)
        NSLayoutConstraint.activate([
            pinnedHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            pinnedHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: headersContainer.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: pinnedTableWidthOverride)
        ])
        
        // pinned header's main label
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 8),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // pinned header's secondary label (landscape)
        pinnedHeaderLabelLandscape.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabelLandscape)
        NSLayoutConstraint.activate([
            pinnedHeaderLabelLandscape.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 8),
            pinnedHeaderLabelLandscape.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // 3) The dynamic headers container
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
        
        // 4) Pinned table below
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        NSLayoutConstraint.activate([
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: pinnedTableWidthOverride)
        ])
        
        // 5) The main columns to the right
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
        
        // Bring pinned table in front
        view.bringSubviewToFront(pinnedTableView)
        pinnedTableView.layer.zPosition = 9999
        
        // Let pinned table scroll to top, not columns
        columnHeadersVC.collectionView?.scrollsToTop = false
        columnsCollectionVC.internalCollectionView?.scrollsToTop = false
        
        // For vertical sync
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncVerticalTables(with: scrollView)
        }
        
        // Orientation logic
        previousSizeClass = traitCollection.verticalSizeClass
        applyLayoutForCurrentOrientation()
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
    
    // (Row Memory) => restore the pinned table's row
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Re-apply orientation logic
        applyLayoutForCurrentOrientation()
        
        // 1) Reload pinned table & columns
        pinnedTableView.reloadData()
        columnHeadersVC.collectionView?.reloadData()
        columnsCollectionVC.reloadData()
        
        // 2) If we have row memory, clamp & scroll
        if let rep = representable {
            pinnedHeaderLabel.text = rep.pinnedColumnTitle
            
            let rowCount = rep.displayedData.count
            if rowCount > 0 {
                let safeRow = min(rep.lastViewedRow, rowCount - 1)
                print("Restoring pinned table to row = \(rep.lastViewedRow) => clamped => \(safeRow)")
                pinnedTableView.scrollToRow(at: IndexPath(row: safeRow, section: 0), at: .top, animated: false)
            }
        }
        
        // We'll do the column restore once after layout
        needsInitialColumnScroll = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pinnedTableView.contentInset.bottom = view.safeAreaInsets.bottom
        pinnedTableView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: view.safeAreaInsets.bottom, right: 0
        )
        
        // If we haven't done the column restore yet, do it once
        if needsInitialColumnScroll {
            needsInitialColumnScroll = false
            restoreColumnIfNeeded()
        }
    }
    
    // Called if orientation changes from portrait <-> landscape
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let wasLandscape = previousSizeClass == .compact
        
        // If we truly changed from portrait <-> landscape
        if isLandscape != wasLandscape {
            needsInitialColumnScroll = true
            applyLayoutForCurrentOrientation()
        }
        previousSizeClass = traitCollection.verticalSizeClass
    }
    
    // MARK: - Orientation Layout Logic
    func applyLayoutForCurrentOrientation() {
        let isLandscape = traitCollection.verticalSizeClass == .compact
        if isLandscape {
            landscapeCoordinator.applyLandscapeLayout()
        } else {
            portraitCoordinator.applyPortraitLayout()
        }
    }
    
    // MARK: - Restore Column Memory
    private func restoreColumnIfNeeded() {
        guard let rep = representable,
              !rep.columns.isEmpty,
              let dataCV = columnsCollectionVC.internalCollectionView else { return }
        
        let colCount = rep.columns.count
        let fallbackIndex = (colCount >= 3) ? 2 : 0
        let targetIndex = (rep.lastViewedColumnIndex < 0) ? fallbackIndex : rep.lastViewedColumnIndex
        
        DispatchQueue.main.async {
            let safeIndex = max(0, min(targetIndex, colCount - 1))
            self.columnsCollectionVC.scrollToColumnIndex(safeIndex)
            
            // Sync header offset
            self.columnHeadersVC.collectionView?.contentOffset.x = dataCV.contentOffset.x
            
            print("Restoring to lastViewedColumnIndex: \(rep.lastViewedColumnIndex) -> actually scrolling to \(safeIndex).")
        }
    }
    
    // MARK: - Vertical Sync
    private func syncVerticalTables(with sourceScrollView: UIScrollView) {
        guard !isSyncingScroll else { return }
        isSyncingScroll = true
        
        let newOffset = sourceScrollView.contentOffset
        if sourceScrollView != pinnedTableView {
            pinnedTableView.contentOffset = newOffset
        }
        columnsCollectionVC.updateAllColumnsVerticalOffset(newOffset)
        
        isSyncingScroll = false
        currentVerticalOffset = newOffset
    }
    
    // MARK: - External calls
    func scrollToBottom() {
        guard let rep = representable else { return }
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let ip = IndexPath(row: rowCount - 1, section: 0)
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
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    
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
        if scrollView == pinnedTableView {
            // (Row Memory) => store lastViewedRow = top visible row
            if let rep = representable,
               let visibleRows = pinnedTableView.indexPathsForVisibleRows,
               let firstIP = visibleRows.first {
                rep.lastViewedRow = firstIP.row
                print("Storing lastViewedRow = \(firstIP.row)")
            }
            
            // near-bottom detection
            guard let rep = representable else { return }
            let offsetY  = scrollView.contentOffset.y
            let contentH = scrollView.contentSize.height
            let frameH   = scrollView.frame.size.height
            let threshold: CGFloat = 50
            let distance = contentH - (offsetY + frameH)
            let atBottom = (distance < threshold)
            rep.isAtBottom = atBottom
            onIsAtBottomChanged?(atBottom)
            
            // Sync vertical offset across columns
            syncVerticalTables(with: scrollView)
        }
        else if let dataCV = columnsCollectionVC.internalCollectionView,
                scrollView == dataCV,
                let headersCV = columnHeadersVC.collectionView {
            // columns scrolled => match header offset
            headersCV.contentOffset.x = dataCV.contentOffset.x
        }
        else if let headersCV = columnHeadersVC.collectionView,
                scrollView == headersCV,
                let dataCV = columnsCollectionVC.internalCollectionView {
            // header scrolled => match columns offset
            dataCV.contentOffset.x = headersCV.contentOffset.x
        }
    }
    
    // (Column Memory) => detect which column is left
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        identifyLeftColumn(in: scrollView)
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate: Bool) {
        if !willDecelerate {
            identifyLeftColumn(in: scrollView)
        }
    }
    
    private func identifyLeftColumn(in scrollView: UIScrollView) {
        guard let rep = representable,
              scrollView == columnsCollectionVC.internalCollectionView,
              let cv = columnsCollectionVC.internalCollectionView else { return }
        
        // Because each 'page' is half the width, shift by 1/4 the width
        let quarter = scrollView.bounds.width / 4.0
        let offsetX = scrollView.contentOffset.x + quarter
        let offsetY = scrollView.bounds.height / 2.0
        let point   = CGPoint(x: offsetX, y: offsetY)
        
        if let indexPath = cv.indexPathForItem(at: point),
           indexPath.item < columnsCollectionVC.columnsData.count {
            rep.lastViewedColumnIndex = indexPath.item
            print("Storing lastViewedColumnIndex => \(indexPath.item)")
        }
    }
}
