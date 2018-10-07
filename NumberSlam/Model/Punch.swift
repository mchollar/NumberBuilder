//
//  Punch.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

class Punch: CustomStringConvertible {
    var number: Int
    var description: String
    
    init(number: Int, description: String) {
        self.number = number
        self.description = description
    }
}
