//
//  Punch.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

enum PunchType {
    case simple, power, root
}

class Punch: CustomStringConvertible, Comparable {
    
    var result: SlamNumber
    var numbers: [SlamNumber]
    var operations: [Operation]
    var description: String
    var attDescription: NSAttributedString
    
    var type: PunchType
    
    init(result: SlamNumber, numbers: [SlamNumber], operations: [Operation], type: PunchType) {
        self.result = result
        self.numbers = numbers
        self.operations = operations
        self.type = type
        
        let attReturnString = NSMutableAttributedString()
        if (operations[0].description == "+" || operations[0].description == "-") &&
            (operations[1].description == "x" || operations[1].description == "÷") {
            
            self.description = "(\(numbers[0]) \(operations[0].description) \(numbers[1])) \(operations[1].description) \(numbers[2]) = \(result)"
            
            
            attReturnString.append(NSAttributedString(string: "("))
            attReturnString.append(numbers[0].attDescription)
            attReturnString.append(NSAttributedString(string: " " + operations[0].description + " "))
            attReturnString.append(numbers[1].attDescription)
            attReturnString.append(NSAttributedString(string: ") " + operations[1].description + " "))
            attReturnString.append(numbers[2].attDescription)
            
            self.attDescription = attReturnString
            
        } else {
            self.description = "\(numbers[0]) \(operations[0].description) \(numbers[1]) \(operations[1].description) \(numbers[2]) = \(result)"
            
            attReturnString.append(numbers[0].attDescription)
            attReturnString.append(NSAttributedString(string: " " + operations[0].description + " "))
            attReturnString.append(numbers[1].attDescription)
            attReturnString.append(NSAttributedString(string: " " + operations[1].description + " "))
            attReturnString.append(numbers[2].attDescription)
            self.attDescription = attReturnString
        }
    }
    
    static func < (lhs: Punch, rhs: Punch) -> Bool {
        if lhs.numbers[0].base != rhs.numbers[0].base {
            return lhs.numbers[0].base < rhs.numbers[0].base
        } else if lhs.numbers[1].base != rhs.numbers[1].base {
            return lhs.numbers[1].base < rhs.numbers[1].base
        } else  {
            return lhs.numbers[2].base < rhs.numbers[2].base
        }

    }
    
    static func == (lhs: Punch, rhs: Punch) -> Bool {
        if lhs.result.value != rhs.result.value { return false }
        
        for i in 0..<lhs.numbers.count {
            if lhs.numbers[i].value != rhs.numbers[i].value {
                return false
            }
        }
        return true
    }

}





