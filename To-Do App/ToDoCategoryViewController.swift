//
//  ToDoCategoryViewController.swift
//  To-Do App
//
//  Created by Wismin Effendi on 6/12/17.
//  Copyright © 2017 iShinobi. All rights reserved.
//

import UIKit

class ToDoCategoryViewController: UIViewController {
    
    
    @IBOutlet weak var collectionView: UICollectionView!

    // for model data 
    var categoryPhotos = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load the categoryCell
        let allCategories = Photo.Category.allCategories
        for category in allCategories {
            let description = category.description()
            categoryPhotos.append(Photo(title: description, category: category, imageName: description))
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - UICollectionViewDataSource 
extension ToDoCategoryViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryPhotos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! ToDoCategoryCell
        
        let photo = categoryPhotos[indexPath.row]
        cell.photo = photo
        
        return cell
    }
}

// MARK: -UICollectionViewDelegate 
extension ToDoCategoryViewController: UICollectionViewDelegate {
    
    
}

extension ToDoCategoryViewController: UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var itemPerRow: CGFloat {
            switch collectionView.bounds.width {
            case 300..<500:
                return 3
            case 500..<800:
                return 4
            default:
                return 5
            }
        }
        let hardCodedPadding: CGFloat = Constant.hardCodedPadding
        let itemWidth = (collectionView.bounds.width / itemPerRow) - hardCodedPadding
        let itemHeight = itemWidth
        return CGSize(width: itemWidth, height: itemHeight)
    }
    
}
