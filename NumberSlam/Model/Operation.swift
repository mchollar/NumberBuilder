//
//  Operation.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

struct Operation: CustomStringConvertible, Equatable {
    var description: String
    var function: ((SlamNumber, SlamNumber) -> SlamNumber)
    
    static func ==(lhs: Operation, rhs: Operation) -> Bool {
        return lhs.description == rhs.description
    }
}
