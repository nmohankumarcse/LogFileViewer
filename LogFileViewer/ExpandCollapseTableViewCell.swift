//
//  ExpandCollapseTableViewCell.swift
//  MultilevelTable
//
//  Created by Mohankumar on 15/02/18.
//  Copyright © 2018 Learning. All rights reserved.
//

import UIKit

class ExpandCollapseTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var accessoryImage: UIImageView!
    @IBOutlet weak var labelLeadingConstraint: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
