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
        // Replace the normal layout with SnapHalfPageFlowLayout
        let layout = SnapHalfPageFlowLayout()
        // optional: layout.pinnedColumnWidth = 0 // if you have that property
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
        return columnsData.count
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
        
        // Match 18 leading so the title lines up over its column data
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
    
    var representable: PinnedColumnTablesRepresentable?
    var onIsAtBottomChanged: ((Bool) -> Void)?

    // We'll track the current vertical offset to sync across columns
    var currentVerticalOffset: CGPoint = .zero
    private var isSyncingScroll = false
    var previousColumnIndex: Int? = nil

    // The pinned table on the left
    let pinnedTableView = UITableView(frame: .zero, style: .plain)

    // The horizontally scrollable columns
    let columnsCollectionVC = TwoColumnCollectionViewController()

    // The separate horizontal collection for column headers
    let columnHeadersVC = ColumnHeadersCollectionVC()

    // The pinned column's header (left side)
    private let pinnedHeaderLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent iOS from extending layout under nav bars
        edgesForExtendedLayout = []

        view.backgroundColor = UIColor(white: 0.12, alpha: 1.0)
        
        // (A) Pinned table setup
        pinnedTableView.contentInsetAdjustmentBehavior = .never
        pinnedTableView.contentInset = .zero
        pinnedTableView.scrollIndicatorInsets = .zero
        pinnedTableView.backgroundColor = .clear
        
        pinnedTableView.dataSource = self
        pinnedTableView.delegate   = self

        // Lock row height to match columns
        pinnedTableView.rowHeight = 44
        pinnedTableView.estimatedRowHeight = 0
        pinnedTableView.tableFooterView = UIView()

        pinnedTableView.register(PinnedColumnCell.self, forCellReuseIdentifier: "PinnedColumnCell")
        
        pinnedTableView.separatorStyle = .none
        pinnedTableView.showsVerticalScrollIndicator = false
        pinnedTableView.cellLayoutMarginsFollowReadableWidth = false
        pinnedTableView.layoutMargins = .zero
        pinnedTableView.separatorInset = .zero
        if #available(iOS 15.0, *) {
            pinnedTableView.sectionHeaderTopPadding = 0
        }
        
        // (B) Top bar => pinnedHeaderLabel + columnHeadersVC
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
            pinnedHeaderLabel.leadingAnchor.constraint(equalTo: pinnedHeaderView.leadingAnchor, constant: 18),
            pinnedHeaderLabel.centerYAnchor.constraint(equalTo: pinnedHeaderView.centerYAnchor)
        ])
        
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
        
        // (C) pinnedTableView below the headers
        pinnedTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pinnedTableView)
        NSLayoutConstraint.activate([
            pinnedTableView.topAnchor.constraint(equalTo: headersContainer.bottomAnchor),
            pinnedTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinnedTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinnedTableView.widthAnchor.constraint(equalToConstant: 70)
        ])
        
        // (D) The main columns to the right
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
        
        // Make sure pinned column is in front
        view.bringSubviewToFront(pinnedTableView)
        pinnedTableView.layer.zPosition = 9999

        // For vertical scroll sync
        columnsCollectionVC.onScrollSync = { [weak self] scrollView in
            self?.syncVerticalTables(with: scrollView)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Also let them sync horizontally
        if let headersCV = columnHeadersVC.collectionView,
           let dataCV    = columnsCollectionVC.internalCollectionView {
            headersCV.delegate = self
            dataCV.delegate    = self
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let rep = representable else { return }
        
        pinnedHeaderLabel.text = rep.pinnedColumnTitle
        
        columnHeadersVC.columnsData = rep.columns
        columnHeadersVC.collectionView?.reloadData()
        
        columnsCollectionVC.columnsData   = rep.columns
        columnsCollectionVC.displayedData = rep.displayedData
        columnsCollectionVC.reloadData()
        
        DispatchQueue.main.async {
            // e.g. show columns 2 & 3
            self.columnsCollectionVC.scrollToColumnIndex(2)
            if let dataCV = self.columnsCollectionVC.internalCollectionView,
               let headersCV = self.columnHeadersVC.collectionView {
                headersCV.contentOffset.x = dataCV.contentOffset.x
            }
            // Restore scroll position to last viewed row
            if let rep = self.representable, rep.displayedData.count > 0 {
                let row = min(rep.lastViewedRow, rep.displayedData.count - 1)
                let indexPath = IndexPath(row: row, section: 0)
                self.pinnedTableView.scrollToRow(at: indexPath, at: .top, animated: false)
            }
        }
        
        // **Reload pinned table** so it doesn't start off empty
        pinnedTableView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adjust pinned table bottom inset for safe area
        let bottomSafeArea = view.safeAreaInsets.bottom
        pinnedTableView.contentInset.bottom = bottomSafeArea
        pinnedTableView.verticalScrollIndicatorInsets =
            UIEdgeInsets(top: 0, left: 0, bottom: bottomSafeArea, right: 0)
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
        // Update all columns (including off-screen)
        columnsCollectionVC.updateAllColumnsVerticalOffset(newOffset)
        
        isSyncingScroll = false
        currentVerticalOffset = newOffset
    }
    
    func scrollToBottom() {
        guard let rep = representable else { return }
        let rowCount = rep.displayedData.count
        if rowCount > 0 {
            let lastIndex = rowCount - 1
            pinnedTableView.scrollToRow(
                at: IndexPath(row: lastIndex, section: 0),
                at: .bottom,
                animated: true
            )
        }
    }
    
    func scrollToTop() {
        guard let rep = representable else { return }
        if rep.displayedData.count > 0 {
            let topIndex = IndexPath(row: 0, section: 0)
            pinnedTableView.scrollToRow(at: topIndex, at: .top, animated: true)
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
        guard let rep = representable else {
            return UITableViewCell()
        }
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
            // Update lastViewedRow with the topmost visible row
            if let indexPaths = pinnedTableView.indexPathsForVisibleRows,
               let firstIndexPath = indexPaths.first {
                representable?.lastViewedRow = firstIndexPath.row
            }
            guard let rep = representable else { return }
            
            let offsetY       = scrollView.contentOffset.y
            let contentHeight = scrollView.contentSize.height
            let frameHeight   = scrollView.frame.size.height
            let nearBottomThreshold: CGFloat = 50
            let distanceFromBottom = contentHeight - (offsetY + frameHeight)
            let atBottom = (distanceFromBottom < nearBottomThreshold)
            
            rep.isAtBottom = atBottom
            onIsAtBottomChanged?(atBottom)
            
            // Also sync vertical offset
            syncVerticalTables(with: scrollView)
        }
        else if let dataCV = columnsCollectionVC.internalCollectionView,
                scrollView == dataCV,
                let headersCV = columnHeadersVC.collectionView {
            // Sync horizontal offset to the headers
            headersCV.contentOffset.x = dataCV.contentOffset.x
        }
        else if let headersCV = columnHeadersVC.collectionView,
                scrollView == headersCV,
                let dataCV = columnsCollectionVC.internalCollectionView {
            // Sync horizontal offset to the main columns
            dataCV.contentOffset.x = headersCV.contentOffset.x
        }
    }
}
