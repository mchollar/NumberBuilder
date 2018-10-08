//
//  Operation.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

struct Operation: CustomStringConvertible {
    var description: String
    //var function: ((Int, Int) -> Int)
    var function: ((SlamNumber, SlamNumber) -> SlamNumber)
}
