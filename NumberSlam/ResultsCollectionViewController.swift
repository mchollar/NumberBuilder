//
//  ResultsCollectionViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/7/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

private let reuseIdentifier = "ResultsCell"

class ResultsCollectionViewController: UICollectionViewController {

    var slamBoard: SlamBoard?
    var results: [Punch]?
    var structuredResults = [[Punch]]()
    var diceNumbers = [Int]()
    
    let columnLayout = SlamBoardLayout(
        cellsPerRow: 6,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 10,
        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    )
    
    let fontSize = CGFloat(30)
    let smallFontSize = CGFloat(22)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadPunchStructure()
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        addGradientToBackGround(color1: ColorPalette.slamRed, color2: ColorPalette.backgroundGray)
        
        self.navigationItem.title = "Results \(diceNumbers)"
    }

    private func loadPunchStructure() {
        
        guard let validResults = results else { return }
        guard let slamBoard = self.slamBoard else { return }
        for i in 0 ..< 36 {
            var punches = [Punch]()
            for punch in validResults {
                if punch.number.value == slamBoard.numbers[i] {
                    punches.append(punch)
                }
            }
            structuredResults.append(punches)
        }
    }
    
    func updateShadows() {
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPunches" {
            if let punchTVC = segue.destination as? PunchTableViewController,
                let senderCell = sender as? UICollectionViewCell,
                let index = collectionView.indexPath(for: senderCell) {
                
                punchTVC.punches = structuredResults[index.row]
                punchTVC.navigationItem.title = "\(diceNumbers) ➡︎ \(slamBoard?.numbers[index.row] ?? -1)"
            }
        }
    
    }
    

    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return structuredResults.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ResultsCollectionViewCell
    
        guard let slamBoard = self.slamBoard else { return cell }
        //cell.numberLabel.text = "\(indexPath.row + 1)"
        cell.numberLabel.text = "\(slamBoard.numbers[indexPath.row])"
        
        if slamBoard.numbers[indexPath.row] > 99 {
            if let font = UIFont(name: "AvenirNext-Bold", size: smallFontSize) {
                cell.numberLabel.font = font
            }
        } else {
            if let font = UIFont(name: "AvenirNext-Bold", size: fontSize) {
                cell.numberLabel.font = font
            }
        }
        
        if structuredResults[indexPath.row].count > 0 { // This cell has results
            cell.backgroundColor = .blue
            cell.numberLabel.textColor = .white
            cell.isUserInteractionEnabled = true
            cell.dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
            
        } else { // This cell has no results
            cell.backgroundColor = .lightGray
            cell.numberLabel.textColor = .black
            cell.isUserInteractionEnabled = false
            cell.dropShadow(color: .black, opacity: 0.0, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
        }
        
        cell.layer.cornerRadius = CGFloat(5)
        
        return cell
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for index in 0 ..< structuredResults.count {
            if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
                if structuredResults[index].count > 0 {
                    cell.dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
                
                } else {
                    cell.dropShadow(color: .black, opacity: 0.0, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
                }
            }
        }
    }
    
    // MARK: UICollectionViewDelegate

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

