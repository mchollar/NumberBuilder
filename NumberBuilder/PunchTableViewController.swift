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
        switch section {
        case 0:
            return simplePunches.count
        case 1:
            return powerPunches.count
        case 2:
            return rootPunches.count
        default:
            return 0
            
        }
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    

}
