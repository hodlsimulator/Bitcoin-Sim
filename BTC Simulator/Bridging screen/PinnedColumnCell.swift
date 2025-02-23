//
//  PinnedColumnCell.swift
//  BTCMonteCarlo
//
//  Created by Conor on 17/02/2025.
//

import UIKit

/// A UITableViewCell for the pinned left column (e.g. "week" or "month").
class PinnedColumnCell: UITableViewCell {
    
    private let label = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 17) // Added font line
        contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        backgroundColor = .clear
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Configure the cell with the pinned integer value (week #) and background row index
    func configure(pinnedValue: Int, backgroundIndex: Int) {
        label.textColor = .white
        // Format the pinnedValue with a thousands separator
        label.text = pinnedValue.formattedWithSeparator()

        let bg = backgroundIndex % 2 == 0
            ? UIColor(white: 0.10, alpha: 1)
            : UIColor(white: 0.14, alpha: 1)
        contentView.backgroundColor = bg
    }
}
