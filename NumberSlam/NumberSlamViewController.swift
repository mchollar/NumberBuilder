//
//  NumberSlamViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/4/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class NumberSlamViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var slamBoard: SlamBoard?
    let maxPower = 5
    var operations = [Operation]()
    var results: [Punch]?
    var diceNumbers = [SlamNumber]()
    var lastUpdateTime = Date()
    
    @IBOutlet weak var dicePickerA: UIPickerView!
    @IBOutlet weak var dicePickerB: UIPickerView!
    @IBOutlet weak var dicePickerC: UIPickerView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var resultsFoundLabel: UILabel!
    @IBOutlet weak var viewResultsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        
        ColorPalette.addGradient(to: self.view, color1: .white, color2: ColorPalette.backgroundGray)
        self.view.tintColor = ColorPalette.slamRed
    }
    
    func setup() {
        
        operations.append(Operation(description: "+", function: +))
        operations.append(Operation(description: "-", function: -))
        operations.append(Operation(description: "x", function: *))
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
        resultsFoundLabel.isHidden = true
        viewResultsButton.isEnabled = false
        
    }
    
    @IBAction func calculateButtonTouched(_ sender: UIButton) {
        
        var numbers = [SlamNumber]()
        numbers.append(SlamNumber(value: dicePickerA.selectedRow(inComponent: 0)+1))
        numbers.append(SlamNumber(value: dicePickerB.selectedRow(inComponent: 0)+1))
        numbers.append(SlamNumber(value: dicePickerC.selectedRow(inComponent: 0)+1))
        performCalculationsOn(numbers: numbers)
    }
    
    
    func performCalculationsOn(numbers: [SlamNumber]) {
        
        results = nil
        spinner.startAnimating()
        resultsFoundLabel.isHidden = false
        viewResultsButton.isEnabled = false
        resultsFoundLabel.text = "Creating combinations"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            //Create combinations of operations
            //let opCombos = self?.combos(elements: self!.operations, k: 2)
            var opCombos = self?.permutations(4, &self!.operations)
            if opCombos != nil {
                self?.trimCombos(&opCombos!)
                opCombos = opCombos!.removeDuplicates()
                self?.addDoubles(&opCombos!)
            }
            
            print ("\(String(describing: opCombos))")
            
            var firstNumberSet = numbers[0].powersAndRootsSet(maxPower: self?.maxPower ?? 1)
            firstNumberSet = firstNumberSet.removeDuplicates()
            var secondNumberSet = numbers[1].powersAndRootsSet(maxPower: self?.maxPower ?? 1)
            secondNumberSet = secondNumberSet.removeDuplicates()
            var thirdNumberSet = numbers[2].powersAndRootsSet(maxPower: self?.maxPower ?? 1)
            thirdNumberSet = thirdNumberSet.removeDuplicates()
            var numberCombos = [[SlamNumber]]()
            for i in 0 ..< firstNumberSet.count {
                for j in 0 ..< secondNumberSet.count {
                    for k in 0 ..< thirdNumberSet.count {
                        var elements = [firstNumberSet[i], secondNumberSet[j], thirdNumberSet[k]]
                        if let elementCombos = self?.permutations(3, &elements)
                        {
                            for combo in elementCombos {
                            numberCombos.append(combo)
                            }
                        }
                    }
                }
            }
            
            print("\(numberCombos.count) values total")
            numberCombos = numberCombos.removeDuplicates()
            print("\(numberCombos.count) values after reduction")
            
            if let punches = self?.runOperations(opCombos!, on: numberCombos) {
                let sortedPunches = punches.sorted(by: {$0.result < $1.result})
                print("Possible Combinations are:/n \(sortedPunches)")
          
                self?.results = sortedPunches
            }
            DispatchQueue.main.async {
                self?.spinner.stopAnimating()
                self?.viewResultsButton.isEnabled = true
                self?.resultsFoundLabel.text = "Total Solutions Found: \(self?.results?.count ?? 0)"
                self?.resultsFoundLabel.isHidden = false
            }
        }
    }
    
    func updateDicePickersWith(numbers: [Int]) {
        
        guard numbers.count == 3 else { return }
        
        dicePickerA.selectRow(numbers[0]-1, inComponent: 0, animated: true)
        dicePickerB.selectRow(numbers[1]-1, inComponent: 0, animated: true)
        dicePickerC.selectRow(numbers[2]-1, inComponent: 0, animated: true)
    }
    
    func operationReturnsInt(_ operation: Operation, on numbers: [SlamNumber]) -> Bool {
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
                        
                        DispatchQueue.main.async {
                            self.lastUpdateTime = Date()
                            self.resultsFoundLabel.text = "Total Solutions Found: \(self.results?.count ?? 0)"
                            self.resultsFoundLabel.isHidden = false
                            print("Updating solutions label to: \(self.results?.count ?? -1) at \(self.lastUpdateTime)")
                            
                        }
                        //TODO: Fix this so it updates
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
        if operations[0].description == "/" {
            if !operationReturnsInt(operations[0], on: [numbers[0], numbers[1]]) {
                print("found bad division (\(numbers[0]) / \(numbers[1]))")
                return nil
            }
        }
        
        
        let firstValue = firstOp(numbers[0], numbers[1])
        
        if operations[1].description == "/" {
            if !operationReturnsInt(operations[1], on: [firstValue, numbers[2]]) {
                print("found bad division (\(firstValue) / \(numbers[2]))")
                return nil
            }
        }
        
        let secondValue = secondOp(firstValue, numbers[2])
        if secondValue > SlamNumber(value: slamBoard!.numbers.max()!) { print("Value > Max"); return nil } //TODO: Fix this code
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
                type = .root
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
    
    //MARK: - UIPickerView Protocol Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
    
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//
//        var title = ""
//        switch row {
//        case 0:
//            title = "⚀"
//        case 1:
//            title = "⚁"
//        case 2:
//            title = "⚂"
//        case 3:
//            title = "⚃"
//        case 4:
//            title = "⚄"
//        case 5:
//            title = "⚅"
//        default:
//            break
//        }
//        //"⚀ ⚁ ⚂ ⚃ ⚄ ⚅"
//
//        return title
//        //return "\(row + 1)"
//    }
    
//    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
//        var title = ""
//        switch row {
//        case 0:
//            title = "⚀"
//        case 1:
//            title = "⚁"
//        case 2:
//            title = "⚂"
//        case 3:
//            title = "⚃"
//        case 4:
//            title = "⚄"
//        case 5:
//            title = "⚅"
//        default:
//            break
//        }
//
//        var attributes: [NSAttributedString.Key: Any] = [:]
//        if let font = UIFont(name: "AvenirNext-Bold", size: 40) {
//            attributes = [.font: font]
//        }
//
//        return NSAttributedString(string: title, attributes: attributes)
//    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
//        var pickerLabel: UILabel? = (view as? UILabel)
//        if pickerLabel == nil {
//            pickerLabel = UILabel()
//            pickerLabel?.font = UIFont(name: "AvenirNext-Bold", size: 40)
//            pickerLabel?.textAlignment = .center
//        }
//
//        var title = ""
//        switch row {
//        case 0:
//            title = "⚀"
//        case 1:
//            title = "⚁"
//        case 2:
//            title = "⚂"
//        case 3:
//            title = "⚃"
//        case 4:
//            title = "⚄"
//        case 5:
//            title = "⚅"
//        default:
//            break
//        }
//
//        pickerLabel?.text = title
//        //pickerLabel?.textColor = UIColor.blue
//        //pickerLabel?.dropShadow()
//        //pickerLabel?.backgroundColor = .lightGray
//
//        return pickerLabel!
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        if let image = UIImage(named: "Dice\(row+1)") {
            imageView.image = image
        }
        return imageView
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 50
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        resultsFoundLabel.isHidden = true
        viewResultsButton.isEnabled = false
    }
    
    
    //MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowResults" {
            if let resultsCVC = segue.destination as? ResultsCollectionViewController {
                resultsCVC.slamBoard = slamBoard
                resultsCVC.results = results
                resultsCVC.diceNumbers = [dicePickerA.selectedRow(inComponent: 0) + 1,
                                          dicePickerB.selectedRow(inComponent: 0) + 1,
                                          dicePickerC.selectedRow(inComponent: 0) + 1]
            }
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
