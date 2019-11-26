//
//  PunchBuilder.swift
//  NumberBuilder
//
//  Created by Micah Chollar on 10/29/19.
//  Copyright © 2019 Widgetilities. All rights reserved.
//

import Foundation

protocol PunchBuilderDelegateProtocol: class {
    func resultsUpdate(number: Int)
    func resultsFinal(number: Int)
}

class PunchBuilder {
    
    private let maxPower = 5
    private var operations = [Operation]()
    var results: [Punch]?
    var diceNumbers = [SlamNumber]()
    var lastUpdateTime = Date()
    weak var delegate: PunchBuilderDelegateProtocol?
    var numberToBuild = 0
    
    init() {
        setup()
    }
    
    func setup() {
        
        operations.append(Operation(description: "+", function: +))
        operations.append(Operation(description: "-", function: -))
        operations.append(Operation(description: "x", function: *))
        operations.append(Operation(description: "÷", function: /))
        
    }
    
    func performCalculationsOn(numbers: [SlamNumber]) {
        
        results = nil
        
        //Create combinations of operations
        var opCombos = permutations(4, &operations)
        
        trimCombos(&opCombos)
        opCombos = opCombos.removeDuplicates()
        addDoubles(&opCombos)
        
        print ("\(String(describing: opCombos))")
        
        var firstNumberSet = numbers[0].powersAndRootsSet(maxPower: maxPower)
        firstNumberSet = firstNumberSet.removeDuplicates()
        var secondNumberSet = numbers[1].powersAndRootsSet(maxPower: maxPower)
        secondNumberSet = secondNumberSet.removeDuplicates()
        var thirdNumberSet = numbers[2].powersAndRootsSet(maxPower: maxPower)
        thirdNumberSet = thirdNumberSet.removeDuplicates()
        var numberCombos = [[SlamNumber]]()
        for i in 0 ..< firstNumberSet.count {
            for j in 0 ..< secondNumberSet.count {
                for k in 0 ..< thirdNumberSet.count {
                    var elements = [firstNumberSet[i], secondNumberSet[j], thirdNumberSet[k]]
                    let elementCombos = permutations(3, &elements)
                    
                    for combo in elementCombos {
                        numberCombos.append(combo)
                    }
                    
                }
            }
        }
        
        print("\(numberCombos.count) values total")
        numberCombos = numberCombos.removeDuplicates()
        print("\(numberCombos.count) values after reduction")
        
        let punches = runOperations(opCombos, on: numberCombos)
        let sortedPunches = punches.sorted(by: {$0.result < $1.result})
        print("Possible Combinations are:/n \(sortedPunches)")
        let filteredPunches = sortedPunches.filter({$0.result.value == numberToBuild})
        results = filteredPunches
        
        delegate?.resultsFinal(number: self.results?.count ?? 0)
        
    }
    
    
    
    func operationReturnsInt(_ operation: Operation, on numbers: [SlamNumber]) -> Bool {
        guard numbers.count == 2 else { print("wrong number entered in operationReturnsInt function");  return false }
        if operation.description == "÷" {
            if numbers[0] % numbers[1] != 0 {
                return false
            }
        }
        if operation.description == "root" {
            return false
        }
        return true
    }
    
    func runOperations(_ operations: [[Operation]], on numbers: [[SlamNumber]]) -> [Punch] {
        
        var results = [Punch]()
        
        for numberSet in numbers {
            for operationSet in operations {
                if let result = runOperation(operationSet, on: numberSet) {
                    print(result)
                    results.append(result)
                    
                    if DateInterval(start: lastUpdateTime, end: Date()) < DateInterval(start: lastUpdateTime, duration: 0.2) {
                        print("Skipping updateProgress()")
                     
                    } else {
                        
                        DispatchQueue.main.async { [unowned self] in
                            self.lastUpdateTime = Date()
                            self.delegate?.resultsUpdate(number: results.count)
                            
                            print("Updating solutions label to: \(results.count) at \(self.lastUpdateTime)")
                            
                        }
                    }
                }
            }
            
        }
        
        return results
    }
    
    func runOperation(_ operations: [Operation], on numbers: [SlamNumber]) -> Punch? {
        guard numbers.count - operations.count == 1 else { return nil }
        
        let firstOp = operations[0].function
        let secondOp = operations[1].function
        
        //Check for division, must result in Integer
        if operations[0].description == "÷" {
            if !operationReturnsInt(operations[0], on: [numbers[0], numbers[1]]) {
                print("found bad division (\(numbers[0]) / \(numbers[1]))")
                return nil
            }
        }
        
        
        let firstValue = firstOp(numbers[0], numbers[1])
        
        if operations[1].description == "÷" {
            if !operationReturnsInt(operations[1], on: [firstValue, numbers[2]]) {
                print("found bad division (\(firstValue) / \(numbers[2]))")
                return nil
            }
        }
        
        let secondValue = secondOp(firstValue, numbers[2])
        if secondValue > SlamNumber(value: numberToBuild) { print("Value > Max"); return nil }
        if secondValue < SlamNumber(value: 1) { print( "Value < 1"); return nil }
        
        let punchType = determinePunchType(numbers: numbers)
        let returnPunch = Punch(result: secondValue, numbers: numbers, operations: operations, type: punchType)
        return returnPunch
    }
    
    func determinePunchType(numbers: [SlamNumber]) -> PunchType {
        
        var type: PunchType = .simple
        
        for number in numbers {
            if number.exponent != 1 {
                type = .power
            }
            if number.root != 1 {
                return .root
            }
        }
        
        return type
    }
    
    //MARK: - Combination Methods
    func permutations<T>(_ n:Int, _ a: inout Array<T>) -> [[T]] {
        if n == 1 {
            print(a)
            return [a]
        }
        var ret = [Array<T>]()
        for i in 0..<n-1 {
            ret += permutations(n-1,&a)
            a.swapAt(n-1, (n%2 == 1) ? 0 : i)
        }
        ret += permutations(n-1,&a)
        
        return ret
    }
    
    func combos<T>(elements: ArraySlice<T>, k: Int) -> [[T]] {
        if k == 0 {
            return [[]]
        }
        
        guard let first = elements.first else {
            return []
        }
        
        let head = [first]
        let subcombos = combos(elements: elements, k: k - 1)
        var ret = subcombos.map { head + $0 }
        ret += combos(elements: elements.dropFirst(), k: k)
        
        return ret
    }
    
    func combos<T>(elements: Array<T>, k: Int) -> [[T]] {
        return combos(elements: ArraySlice(elements), k: k)
    }
    
    func trimCombos(_ operationsArray: inout [[Operation]]) {
        for i in 0..<operationsArray.count {
            while operationsArray[i].count > 2 {
                operationsArray[i].removeLast()
            }
        }
    }
    
    func addDoubles(_ operationsArray: inout [[Operation]]) {
        for i in 0 ..< operations.count {
            operationsArray.append([operations[i], operations[i]])
        }
    }
    
}


extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()
        
        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }
        
        return result
    }
}
