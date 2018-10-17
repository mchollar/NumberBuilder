//
//  ResultsCollectionViewCell.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/7/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class ResultsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var numberLabel: UILabel!
    
    override var isSelected: Bool {
        didSet{
            if self.isSelected
            {
                self.backgroundColor = .black
            }
            else
            {
                self.backgroundColor = .blue
            }
        }
    }
    
    var isEmpty = true
    
}
