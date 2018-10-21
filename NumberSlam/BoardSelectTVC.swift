//
//  BoardSelectTVC.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/19/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class BoardSelectTVC: UITableViewController {

    let reuseIdentifier = "BoardSelectCell"
    var slamBoards = [SlamBoard]()
    var slamBoard: SlamBoard?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSlamBoards()
        
        addGradientToBackGround(color1: ColorPalette.slamRedBackground, color2: ColorPalette.backgroundGray)
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 4
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        var cellText: String
        switch indexPath.row {
        case 0:
            cellText = "Classic"
        case 1:
            cellText = "Twos"
        case 2:
            cellText = "Threes"
        case 3:
            cellText = "Custom"
        default:
            cellText = ""
        }
        cell.textLabel?.text = cellText

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Slam Board Type"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 3 {
            performSegue(withIdentifier: "EditCustomBoard", sender: self)
        } else {
            slamBoard = slamBoards[indexPath.row]
            performSegue(withIdentifier: "UseStandardBoard", sender: self)
        }
        
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "EditCustomBoard":
            //let destinationVC = segue.destination as! CustomBoardCVC
            break
            
        case "UseStandardBoard":
            let destinationVC = segue.destination as! ViewController
            destinationVC.slamBoard = slamBoard
            
        default:
            break
        }
        
    }
    

}
