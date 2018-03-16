//
//  JsonViewerHeaderTableViewCell.swift
//  LogFileViewer//  Created by Mohankumar on 03/03/18.
//  Copyright © 2018 Mohankumar. All rights reserved.
//

import UIKit

class JsonViewerHeaderTableViewCell: UITableViewCell {
    var handlerForSelection: ((_ index: Int)->())?
    var index : Int?
    @IBOutlet weak var headerTitle: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(sender:)))
        tap.delegate = self
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer? = nil) {
        print("Tapped")
        handlerForSelection!(index!)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
