//
//  Punch.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

class Punch: CustomStringConvertible {
    var number: SlamNumber
    var description: String
    var attDescription: NSAttributedString
    var type: PunchType
    
    init(number: SlamNumber, description: String, attDescription: NSAttributedString, type: PunchType) {
        self.number = number
        self.description = description
        self.attDescription = attDescription
        self.type = type
    }
}

enum PunchType {
    case simple, power, root
}
