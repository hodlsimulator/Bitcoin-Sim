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
        // Let the pinned table handle tap-to-top
        collectionView?.scrollsToTop = false
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
    
    // Provided by SwiftUI
    var representable: PinnedColumnTablesRepresentable?
    
    // Called when near-bottom scrolling
    var onIsAtBottomChanged: ((Bool) -> Void)?
    
    // We track vertical offset to sync pinned + columns
    var currentVerticalOffset: CGPoint = .zero
    private var isSyncingScroll = false
    
    // The pinned table on the left
    let pinnedTableView = UITableView(frame: .zero, style: .plain)

    // The scrollable columns on the right
    let columnsCollectionVC = TwoColumnCollectionViewController()

    // The top horizontal headers
    let columnHeadersVC = ColumnHeadersCollectionVC()

    // The pinned header container
    internal let pinnedHeaderView = UIView()
    
    // Portrait label
    internal let pinnedHeaderLabel = UILabel()
    
    // For bridging code
    internal var previousColumnIndex: Int? = nil
    
    // A second label for landscape
    internal let pinnedHeaderLabelLandscape: UILabel = {
        let lbl = UILabel()
        lbl.isHidden = true
        return lbl
    }()
    
    // Pinned table width (overridden by coordinators)
    var pinnedTableWidthOverride: CGFloat = 70
    var pinnedTableWidth: CGFloat {
        return pinnedTableWidthOverride
    }
    
    // Coordinators for separate orientation logic
    lazy var portraitCoordinator = PortraitLayoutCoordinator(vc: self)
    lazy var landscapeCoordinator = LandscapeLayoutCoordinator(vc: self)
    
    // We'll do the column restore once after layout
    private var needsInitialColumnScroll = true
    
    // Track previous orientation
    private var previousSizeClass: UIUserInterfaceSizeClass?

    // ❶ -- Moved this function above its first use --
    func applyLayoutForCurrentOrientation() {
        guard representable != nil else { return }
        
        let isLandscape = traitCollection.verticalSizeClass == .compact
        if isLandscape {
            landscapeCoordinator.applyLandscapeLayout()
        } else {
            portraitCoordinator.applyPortraitLayout()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        edgesForExtendedLayout = []
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
        // Let pinned table handle tap-to-top
        pinnedTableView.scrollsToTop = true
        
        if #available(iOS 15.0, *) {
            pinnedTableView.sectionHeaderTopPadding = 0
        }
        
        // (B) top bar container
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
        
        // pinned header area
        pinnedHeaderView.backgroundColor = .black
        pinnedHeaderView.translatesAutoresizingMaskIntoConstraints = false
        headersContainer.addSubview(pinnedHeaderView)
        NSLayoutConstraint.activate([
            pinnedHeaderView.topAnchor.constraint(equalTo: headersContainer.topAnchor),
            pinnedHeaderView.bottomAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedHeaderView.leadingAnchor.constraint(equalTo: headersContainer.leadingAnchor),
            pinnedHeaderView.widthAnchor.constraint(equalToConstant: pinnedTableWidth)
        ])
        
        // portrait label
        pinnedHeaderLabel.textColor = .orange
        pinnedHeaderLabel.font = UIFont.boldSystemFont(ofSize: 14)
        pinnedHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabel)
        NSLayoutConstraint.activate([
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 18),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // landscape label (initially hidden)
        pinnedHeaderLabelLandscape.translatesAutoresizingMaskIntoConstraints = false
        pinnedHeaderView.addSubview(pinnedHeaderLabelLandscape)
        NSLayoutConstraint.activate([
            pinnedHeaderLabelLandscape.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 18),
            pinnedHeaderLabelLandscape.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
        // dynamic headers area
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
        
        // (D) columns to the right
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
        
        // Only pinned table scrolls to top
        columnHeadersVC.collectionView?.scrollsToTop = false
        columnsCollectionVC.internalCollectionView?.scrollsToTop = false
        
        // Vertical sync
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncVerticalTables(with: scrollView)
        }
        
        // Add tap gesture on pinned header
        pinnedHeaderView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePinnedHeaderTap))
        pinnedHeaderView.addGestureRecognizer(tapGesture)
        
        // ❷ -- Now the compiler sees the function --
        applyLayoutForCurrentOrientation()
    }
    
    @objc private func handlePinnedHeaderTap() {
        scrollToTop()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Let headers & columns sync horizontal scrolling
        if let headersCV = columnHeadersVC.collectionView,
           let dataCV = columnsCollectionVC.internalCollectionView {
            headersCV.delegate = self
            dataCV.delegate     = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Re-apply layout so titles appear if representable is set
        applyLayoutForCurrentOrientation()
        
        // Reload everything
        pinnedTableView.reloadData()
        columnHeadersVC.collectionView?.reloadData()
        columnsCollectionVC.reloadData()
        
        // We'll do restoreColumnIfNeeded once
        needsInitialColumnScroll = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        pinnedTableView.contentInset.bottom = view.safeAreaInsets.bottom
        pinnedTableView.verticalScrollIndicatorInsets = UIEdgeInsets(
            top: 0, left: 0, bottom: view.safeAreaInsets.bottom, right: 0
        )
        
        if needsInitialColumnScroll {
            needsInitialColumnScroll = false
            restoreColumnIfNeeded()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let isLandscape = traitCollection.verticalSizeClass == .compact
        let wasLandscape = previousSizeClass == .compact
        if isLandscape != wasLandscape {
            // On orientation change, re-apply layout & re-restore column
            needsInitialColumnScroll = true
            applyLayoutForCurrentOrientation()
        }
        previousSizeClass = traitCollection.verticalSizeClass
    }
    
    // Force column 2 if 3+ columns exist, else 0
    private func restoreColumnIfNeeded() {
        guard let rep = representable,
              !rep.columns.isEmpty,
              let dataCV = columnsCollectionVC.internalCollectionView else { return }

        let count = rep.columns.count
        let fallbackIndex = (count >= 3) ? 2 : 0
        let targetIndex   = rep.lastViewedColumnIndex ?? fallbackIndex
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let safeIdx = min(max(0, targetIndex), count - 1)
            self.columnsCollectionVC.scrollToColumnIndex(safeIdx)
            self.columnHeadersVC.collectionView?.contentOffset.x = dataCV.contentOffset.x
        }
    }
    
    // MARK: - Vertical sync
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
        if scrollView == pinnedTableView {
            // near-bottom detection
            if let rows = pinnedTableView.indexPathsForVisibleRows,
               let firstIP = rows.first,
               let rep = representable {
                rep.lastViewedRow = firstIP.row
            }
            guard let rep = representable else { return }
            
            let offsetY     = scrollView.contentOffset.y
            let contentH    = scrollView.contentSize.height
            let frameH      = scrollView.frame.size.height
            let threshold: CGFloat = 50
            let distance    = contentH - (offsetY + frameH)
            let atBottom    = (distance < threshold)
            rep.isAtBottom  = atBottom
            onIsAtBottomChanged?(atBottom)
            
            // Sync vertical offset
            syncVerticalTables(with: scrollView)
        }
        else if let dataCV = columnsCollectionVC.internalCollectionView,
                scrollView == dataCV,
                let headersCV = columnHeadersVC.collectionView {
            // columns scrolled => update header offset
            headersCV.contentOffset.x = dataCV.contentOffset.x
        }
        else if let headersCV = columnHeadersVC.collectionView,
                scrollView == headersCV,
                let dataCV = columnsCollectionVC.internalCollectionView {
            // header scrolled => match the columns
            dataCV.contentOffset.x = headersCV.contentOffset.x
        }
    }
}
