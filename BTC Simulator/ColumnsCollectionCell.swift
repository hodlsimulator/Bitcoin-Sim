//
//  ColumnsCollectionCell.swift
//  BTCMonteCarlo
//
//  Created by . . on 21/02/2025.
//

import UIKit

class ColumnsCollectionCell: UICollectionViewCell {

    private let titleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)

    // We might store the partial key path & data
    private var columnTitle: String = ""
    private var partial: PartialKeyPath<SimulationData>?
    private var displayedData: [SimulationData] = []

    // So we can call back when scrolling
    var onScroll: ((UIScrollView)->Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.backgroundColor = UIColor(white: 0.15, alpha: 1.0)

        // 1) Title label at top
        titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
        titleLabel.textColor = .orange
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8)
        ])

        // 2) Table below the label
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.register(OneColumnRowCell.self, forCellReuseIdentifier: "OneColumnRowCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func configure(columnTitle: String,
                   partialKeyPath: PartialKeyPath<SimulationData>,
                   displayedData: [SimulationData]) {

        self.columnTitle = columnTitle
        self.partial = partialKeyPath
        self.displayedData = displayedData

        titleLabel.text = columnTitle
        // Force table reload
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource & Delegate
extension ColumnsCollectionCell: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedData.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OneColumnRowCell",
                                                       for: indexPath) as? OneColumnRowCell else {
            return UITableViewCell()
        }
        
        let rowData = displayedData[indexPath.row]
        // Format the partial key path
        cell.configure(with: rowData, partial: partial)
        
        // Alternate color
        let isEven = (indexPath.row % 2 == 0)
        cell.contentView.backgroundColor = isEven
            ? UIColor(white: 0.10, alpha: 1.0)
            : UIColor(white: 0.14, alpha: 1.0)
        
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Let the parent (ColumnsCollectionViewController) or pinned table sync
        onScroll?(scrollView)
    }
}

class OneColumnRowCell: UITableViewCell {
    private let label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    func configure(with rowData: SimulationData, partial: PartialKeyPath<SimulationData>?) {
        guard let partial = partial else {
            label.text = "-"
            return
        }
        // Check if it's Decimal, Double, or Int...
        if let kp = partial as? KeyPath<SimulationData, Decimal> {
            label.text = rowData[keyPath: kp].formattedWithSeparator()
        } else if let kp = partial as? KeyPath<SimulationData, Double> {
            label.text = rowData[keyPath: kp].formattedWithSeparator()
        } else if let kp = partial as? KeyPath<SimulationData, Int> {
            label.text = rowData[keyPath: kp].formattedWithSeparator()
        } else {
            label.text = "-"
        }
    }
}
