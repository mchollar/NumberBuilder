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

    var results: [Punch]?
    var structuredResults = [[Punch]]()
    
    let columnLayout = SlamBoardLayout(
        cellsPerRow: 6,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 10,
        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        loadPunchStructure()
        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        // Do any additional setup after loading the view.
    }

    private func loadPunchStructure() {
        guard let validResults = results else { return }
        for i in 0 ..< 36 {
            var punches = [Punch]()
            for punch in validResults {
                if punch.number.value == i+1 {
                    punches.append(punch)
                }
            }
            structuredResults.append(punches)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPunches" {
            if let punchTVC = segue.destination as? PunchTableViewController,
                let senderCell = sender as? UICollectionViewCell,
                let index = collectionView.indexPath(for: senderCell) {
                
                punchTVC.punches = structuredResults[index.row]
                punchTVC.navigationItem.title = "\(index.row + 1)"
            }
        }
    
    }
    

    // MARK: UICollectionViewDataSource

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
    
        cell.numberLabel.text = "\(indexPath.row + 1)"
        if structuredResults[indexPath.row].count > 0 {
            cell.backgroundColor = .blue
            cell.numberLabel.textColor = .white
            cell.isUserInteractionEnabled = true
        } else {
            cell.backgroundColor = .lightGray
            cell.numberLabel.textColor = .black
            cell.isUserInteractionEnabled = false
        }
        //cell.punchesLabel.text = "\(structuredResults[indexPath.row].count) punches"
    
        return cell
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

