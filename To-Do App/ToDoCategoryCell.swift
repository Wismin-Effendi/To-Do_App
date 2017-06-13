//
//  ToDoCategoryCell.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

class ToDoCategoryCell: UICollectionViewCell {
    
    @IBOutlet weak var categoryImageView: UIImageView!
    
    var photo: Photo? {
        didSet {
            if let photo = photo {
                categoryImageView.image = UIImage(named: photo.imageName)
            }
        }
    }
    
    // MARK: - Properties 
    override var isSelected: Bool {
        didSet {
            // we need to segue to the particular category
        }
    }
    
    // MARK: - View Life Cycle 
    override func awakeFromNib() {
        super.awakeFromNib()
        isSelected = false
    }
}


