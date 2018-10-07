//
//  SlamNumber.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/6/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation

class SlamNumber: CustomStringConvertible {
    
    var value: Int = 0
    var base: Int = 0
    var exponent: Int = 1 {
        didSet {
            self.value = Int(pow(Double(base), Double(exponent)))
        }
    }
    var root: Int = 1 {
        didSet {
            self.value = Int(pow(Double(base), Double(1/root)))
        }
    }
    
    init(value: Int) {
        
        self.value = value
        self.base = value
    }
    
    var description: String {
        var desc = "\(base)"
        if exponent != 1 {
            desc += " ^\(exponent)"
            if root != 1 {
                desc += "/\(root)"
            }
        }
        else if root != 1 {
            desc += " ^1/\(root)"
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
    
}

