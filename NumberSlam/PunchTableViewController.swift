//
//  PunchTableViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/7/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class PunchTableViewController: UITableViewController {

    var punches: [Punch]?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addGradientToBackGround(color1: ColorPalette.slamRedBackground, color2: ColorPalette.backgroundGray)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return punches?.count ?? 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PunchCell", for: indexPath)
        
        if punches != nil {
            cell.textLabel?.text = "\(punches![indexPath.row])"
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Solutions Found: \(punches?.count ?? 0)"
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
