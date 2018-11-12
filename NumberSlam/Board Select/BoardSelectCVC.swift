//
//  BoardSelectCVC.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/25/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

private let reuseIdentifier = "BoardSelectCollectionCell"

class BoardSelectCVC: UICollectionViewController {

    var slamBoards = [SlamBoard]()
    var slamBoard: SlamBoard?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSlamBoards()
        
        let columnLayout = SlamBoardLayout(
            cellsPerRow: traitCollection.horizontalSizeClass == .regular ? 3 : 2,
            minimumInteritemSpacing: 10,
            minimumLineSpacing: 10,
            sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        addGradientToBackGround(color1: ColorPalette.slamRedBackground, color2: ColorPalette.backgroundGray)
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateLayout), name: UIDevice.orientationDidChangeNotification, object: nil)
        
    }

    @objc func updateLayout() {
        let columnLayout = SlamBoardLayout(
            cellsPerRow: UIDevice.current.orientation.isLandscape ? 3 : 2,
            minimumInteritemSpacing: 10,
            minimumLineSpacing: 10,
            sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        )
        
        collectionView?.collectionViewLayout = columnLayout
        columnLayout.invalidateLayout()
    }
    
    func setupSlamBoards() {
        for i in 1 ... 3 {
            var numbers = [Int]()
            for j in 1 ... 36 {
                numbers.append(j*i)
            }
            slamBoards.append(SlamBoard(numbers: numbers))
        }
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "EditCustomBoard":
            //let destinationVC = segue.destination as! CustomBoardCVC
            break
            
        case "UseStandardBoard":
            let destinationVC = segue.destination as! NumberSlamViewController
            destinationVC.slamBoard = slamBoard
            
        default:
            break
        }
    }
    

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! BoardSelectCollectionViewCell
    
        var cellText: String
        var itemText: String
        switch indexPath.row {
        case 0:
            cellText = "Classic"
            itemText = "1s"
        case 1:
            cellText = "Twos"
            itemText = "2s"
        case 2:
            cellText = "Threes"
            itemText = "3s"
        case 3:
            cellText = "Custom"
            itemText = "★"
        default:
            cellText = ""
            itemText = ""
        }
        
        cell.textLabel.text = cellText
        cell.itemLabel.text = itemText
        
        cell.itemView.dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
        
        //cell.itemView.layer.cornerRadius = 5.0
        //cell.itemView.clipsToBounds = true
        
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 3 {
            performSegue(withIdentifier: "EditCustomBoard", sender: self)
        } else {
            slamBoard = slamBoards[indexPath.row]
            performSegue(withIdentifier: "UseStandardBoard", sender: self)
        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
