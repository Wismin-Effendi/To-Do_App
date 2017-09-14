//
//  CustomTaskCell.swift
//  Todododo
//
//  Created by Wismin Effendi on 9/14/17.
//  Copyright © 2017 Wismin Effendi. All rights reserved.
//

import UIKit
import MGSwipeTableCell

class CustomTaskCell: MGSwipeTableCell {

    @IBOutlet var title: UILabel!
    @IBOutlet var subtitle: UILabel!
    @IBOutlet var alarmImageView: UIImageView!
    @IBOutlet var noteImageView: UIImageView!
    @IBOutlet var disclosureImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
