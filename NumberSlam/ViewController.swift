//
//  ViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    
    
    let maxPower = 5
    var operations = [Operation]()
    
    @IBOutlet weak var dicePickerA: UIPickerView!
    @IBOutlet weak var dicePickerB: UIPickerView!
    @IBOutlet weak var dicePickerC: UIPickerView!
    
    @IBOutlet weak var resultTextView: UITextView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        setup()
    }
    
    func setup() {
        
        operations.append(Operation(description: "+", function: +))
        operations.append(Operation(description: "-", function: -))
        operations.append(Operation(description: "*", function: *))
        operations.append(Operation(description: "/", function: /))
        
        
    }
    

    
    @IBAction func rollButtonTouched(_ sender: UIButton) {
        var numbers = [Int]()
        for _ in 0 ..< 3 {
            let randomInt = Int(arc4random() % 6) + 1
            numbers.append(randomInt)
        }
        
        print("You rolled: \(numbers)")
        
        updateDicePickersWith(numbers: numbers)
        //performCalculationsOn(numbers: numbers)
    }
    
    @IBAction func calculateButtonTouched(_ sender: UIButton) {
        
        var numbers = [Int]()
        numbers.append(dicePickerA.selectedRow(inComponent: 0)+1)
        numbers.append(dicePickerB.selectedRow(inComponent: 0)+1)
        numbers.append(dicePickerC.selectedRow(inComponent: 0)+1)
        resultTextView.text = "Performing calculations on: \(numbers)\n"
        performCalculationsOn(numbers: numbers)
    }
    
    
    func performCalculationsOn(numbers: [Int]) {
        //Create combinations of operations
        let opCombos = combos(elements: operations, k: 2)
        print ("\(opCombos)")
        
        var mutableNumbers = numbers
        //Create initial permutations of numbers
        var numberCombos = permutations(mutableNumbers.count, &mutableNumbers)
        
        for i in 0 ..< 3 {
            for j in 0 ... maxPower {
                let elevatedNumber = Int(pow(Double(mutableNumbers[i]), Double(j)))
                print ("\(mutableNumbers[i]) pow \(j) = \(elevatedNumber)")
                var tempSet = mutableNumbers
                tempSet[i] = elevatedNumber
                let tempNumberCombos = permutations(tempSet.count, &tempSet)
                numberCombos += tempNumberCombos
                
                for k in 2 ... maxPower {
                    let secondElevatedDouble = pow(Double(elevatedNumber), 1/Double(k))
                    print(elevatedNumber, (1/Double(k)), secondElevatedDouble)
                    if floor(secondElevatedDouble) == secondElevatedDouble {
                        
                        let secondElevatedNumber = Int(secondElevatedDouble)
                        print ("\(elevatedNumber) pow 1/\(k) = \(secondElevatedNumber)")
                        
                        var tempSet = mutableNumbers
                        tempSet[i] = secondElevatedNumber
                        let tempNumberCombos = permutations(tempSet.count, &tempSet)
                        numberCombos += tempNumberCombos
                        
                    }
                }
            }
        }
        
        print("\(numberCombos.count) values total")
        numberCombos = numberCombos.removeDuplicates()
        print("\(numberCombos.count) values after reduction")
        
        let punches = runOperations(opCombos, on: numberCombos)
        let sortedPunches = punches.sorted(by: {$0.number<$1.number})
        print("Possible Combinations are:/n \(sortedPunches)")
        
        for punch in sortedPunches {
            resultTextView.text += punch.description + "\n"
        }
    }
    
    func updateDicePickersWith(numbers: [Int]) {
        
        guard numbers.count == 3 else { return }
        
        dicePickerA.selectRow(numbers[0]-1, inComponent: 0, animated: true)
        dicePickerB.selectRow(numbers[1]-1, inComponent: 0, animated: true)
        dicePickerC.selectRow(numbers[2]-1, inComponent: 0, animated: true)
    }
    
    func runOperations(_ operations: [[Operation]], on numbers: [[Int]]) -> [Punch] {
        
        var results = [Punch]()
        
        for numberSet in numbers {
            for operationSet in operations {
                if let result = runOperation(operationSet, on: numberSet) {
                    print(result)
                    results.append(result)
                }
            }
            
        }
        
        
        return results
    }
    
    func runOperation(_ operations: [Operation], on numbers: [Int]) -> Punch? {
        guard numbers.count - operations.count == 1 else { return nil }
        
        let firstOp = operations[0].function
        let secondOp = operations[1].function
        
        //Check for division, must result in Integer
        if operations[0].description == "/" {
            if !operationReturnsInt(operations[0], on: [numbers[0], numbers[1]]) {
                print("found bad division (\(numbers[0]) / \(numbers[1]))")
                return nil
            }
        }
        if operations[1].description == "/" {
            if !operationReturnsInt(operations[1], on: [numbers[1], numbers[2]]) {
                print("found bad division (\(numbers[1]) / \(numbers[2]))")
                return nil
            }
        }
        
        let firstValue = firstOp(numbers[0], numbers[1])
        let secondValue = secondOp(firstValue, numbers[2])
        if secondValue > 36 { print("Value > 36"); return nil }
        if secondValue < 1 { print( "Value < 1"); return nil }
        let returnString = "\(numbers[0]) \(operations[0].description) \(numbers[1]) \(operations[1].description) \(numbers[2]) = \(secondValue)"
        let returnPunch = Punch(number: secondValue, description: returnString)
        return returnPunch
    }
    
    func operationReturnsInt(_ operation: Operation, on numbers: [Int]) -> Bool {
        guard numbers.count == 2 else { print("wrong number entered in operationReturnsInt function");  return false }
        if operation.description == "/" {
            if numbers[0] % numbers[1] != 0 {
                return false
            }
        }
        if operation.description == "root" {
            return false
        }
        return true
    }
    
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
    
    func powerSetOf(_ number: Int, maxPower: Int) -> [Int] {
        var results = [Int]()
        for i in 0 ... maxPower {
            results.append(Int(pow(Double(number), Double(i))))
        }
        return results
    }
    
    //MARK: - UIPickerView Protocol Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(row + 1)"
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
