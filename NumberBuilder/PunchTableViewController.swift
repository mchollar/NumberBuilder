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
    var simplePunches = [Punch]()
    var powerPunches = [Punch]()
    var rootPunches = [Punch]()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sortPunches()
        navigationController?.navigationBar.prefersLargeTitles = true
    }


    func sortPunches() {
        guard let punches = self.punches else { return }
        for punch in punches {
            switch punch.type {
            case .simple:
                simplePunches.append(punch)
            case .power:
                powerPunches.append(punch)
            case .root:
                rootPunches.append(punch)
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionCount: Int
        switch section {
        case 0:
            sectionCount = simplePunches.count
        case 1:
            sectionCount = powerPunches.count
        case 2:
            sectionCount = rootPunches.count
        default:
            sectionCount = 0
            
        }
        
        if sectionCount > 1 { return 2 }
        else {
            return sectionCount
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            return setupPunchCellFor(indexPath: indexPath)
            
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SeeMoreCell", for: indexPath)
            cell.textLabel?.text = "Show All Results"
            return cell
        }
        
        
    }
    
    private func setupPunchCellFor(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PunchCell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            cell.textLabel?.attributedText = simplePunches[indexPath.row].attDescription
        case 1:
            cell.textLabel?.attributedText = powerPunches[indexPath.row].attDescription
        case 2:
            cell.textLabel?.attributedText = rootPunches[indexPath.row].attDescription
        default:
            break
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch section {
        case 0:
            return "Simple Solutions: \(simplePunches.count)"
        case 1:
            return "Solutions using Powers: \(powerPunches.count)"
        case 2:
            return "Solutions using Powers and Roots: \(rootPunches.count)"
        default:
            return ""
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if segue.identifier == "ShowAllResults",
            let destination = segue.destination as? ShowAllResultsTVC,
            let sectionIndex = tableView.indexPathForSelectedRow?.section {
            
            switch sectionIndex {
            case 0:
                destination.punches = simplePunches
                destination.title = "Simple Solutions"
            case 1:
                destination.punches = powerPunches
                destination.title = "Using Powers"
            case 2:
                destination.punches = rootPunches
                destination.title = "Using Powers and Roots"
            default:
                destination.punches = [Punch]()
            }
            
        }
    }

    

}
