//
//  SlamNumber.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/6/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

class SlamNumber: CustomStringConvertible, Equatable {
    
    var value: Int = 0
    var base: Int = 0
    var exponent: Int = 1 {
        didSet {
            self.value = Int(pow(Double(base), Double(exponent)/Double(root)))
        }
    }
    var root: Int = 1 {
        didSet {
            self.value = Int(pow(Double(base), Double(exponent)/Double(root)))
        }
    }
    
    init(value: Int) {
        
        self.value = value
        self.base = value
    }

    let supers = ["\u{2070}", "\u{00B9}", "\u{00B2}", "\u{00B3}", "\u{2074}", "\u{2075}", "\u{2076}", "\u{2077}", "\u{2078}", "\u{2079}", "\u{2E0D}"] //Unicode characters for superscript (exponents and roots) - 0-9 and the / symbol
    
    var description: String {
        var desc = "\(base)"
        if exponent == 0 {
            return desc + supers[0] + " (\(value))"
            
        }
        if exponent != 1 {
            desc += supers[exponent]
            if root != 1 {
                desc += supers[10] + supers[root]
            }
            desc += " (\(value))"
        }
        else if root != 1 {
            desc += supers[1] + supers[10] + supers[root]
            desc += " (\(value))"
        }
        
        return desc
    }
    
    static func +(lhs: SlamNumber, rhs: SlamNumber) -> SlamNumber {
        let ret = SlamNumber(value: lhs.value + rhs.value)
        return ret
    }
    
    static func -(lhs: SlamNumber, rhs: SlamNumber) -> SlamNumber {
        let ret = SlamNumber(value: lhs.value - rhs.value)
        return ret
    }
    
    static func *(lhs: SlamNumber, rhs: SlamNumber) -> SlamNumber {
        let ret = SlamNumber(value: lhs.value * rhs.value)
        return ret
    }
    
    static func /(lhs: SlamNumber, rhs: SlamNumber) -> SlamNumber {
        let ret = SlamNumber(value: lhs.value / rhs.value)
        return ret
    }
    
    static func ==(lhs: SlamNumber, rhs: SlamNumber) -> Bool {
        return lhs.value == rhs.value
    }
    
    static func <(lhs: SlamNumber, rhs: SlamNumber) -> Bool {
        return lhs.value < rhs.value
    }
    
    static func >(lhs: SlamNumber, rhs: SlamNumber) -> Bool {
        return lhs.value > rhs.value
    }
    
    static func %(lhs: SlamNumber, rhs: SlamNumber) -> Double {
        return Double(lhs.value % rhs.value)
    }
    
    func powersAndRootsSet(maxPower: Int) -> [SlamNumber] {
        
        var results = [SlamNumber]()
        if self.value == 1 {
            return [self]
        }
        
        for i in 0 ... maxPower {
            let tempNumber = SlamNumber(value: self.value)
            tempNumber.exponent = i
            results.append(tempNumber)
            for j in 2 ..< maxPower {
                if i != 0 {
                    
                    let tempRootDouble = pow(Double(tempNumber.value), 1/Double(j)) // Create this to see if it's a whole number
                    
                    if floor(tempRootDouble) == tempRootDouble { //Evaluates true if it's a whole number
                        let newTempNumber = SlamNumber(value: self.value)
                        newTempNumber.exponent = tempNumber.exponent
                        newTempNumber.root = j
                        results.append(newTempNumber)
                    }
                }
            }
        }
        
        return results
    }
    
}

