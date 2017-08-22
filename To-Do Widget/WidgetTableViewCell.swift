//
//  WidgetTableViewCell.swift
//  To-Do App
//
//  Created by Wismin Effendi on 8/18/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

class WidgetTableViewCell: UITableViewCell {
    
    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var statusButton: UIButton!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    var completed: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        visualEffectView.effect = UIVibrancyEffect.widgetPrimary()
        statusButton.setImage(#imageLiteral(resourceName: "unchecked"), for: .normal)
        title.text = "This is a title"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)


    }

    @IBAction func doneButtonTapped(_ sender: UIButton) {
        completed = !completed
        // Configure the view for the selected state
        let image = completed ? #imageLiteral(resourceName: "checked") : #imageLiteral(resourceName: "unchecked")
        statusButton.setImage(image, for: .normal)
    }
}
