//
//  NumberBuilderTVC.swift
//  NumberBuilder
//
//  Created by Micah Chollar on 10/30/19.
//  Copyright © 2019 Widgetilities. All rights reserved.
//

import UIKit

class NumberBuilderTVC: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var punchBuilder = PunchBuilder()
    var numberToBuild = 0
    
    @IBOutlet weak var dicePickerA: UIPickerView!
    @IBOutlet weak var dicePickerB: UIPickerView!
    @IBOutlet weak var dicePickerC: UIPickerView!
    
    @IBOutlet weak var numberToBuildTextField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var resultsFoundLabel: UILabel!
    @IBOutlet weak var viewResultsButton: UIButton!
    @IBOutlet weak var calculateButton: UIButton!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        punchBuilder.delegate = self
        addDoneButtonOnKeyboard()
        updateDicePickersWith(numbers: [1,2,3])
        navigationController?.navigationBar.barStyle = .black
    }
    
    
    @IBAction func rollButtonTouched(_ sender: UIButton) {
        var numbers = [Int]()
        repeat {
            numbers.removeAll()
        for _ in 0 ..< 3 {
            let randomInt = Int(arc4random() % 6) + 1
            numbers.append(randomInt)
            }
            
        } while numbers.filter({$0 == 1}).count > 1
        
        
        print("You rolled: \(numbers)")
        
        updateDicePickersWith(numbers: numbers)
        resultsFoundLabel.isHidden = true
        viewResultsButton.isEnabled = false
        
    }
    
    func updateDicePickersWith(numbers: [Int]) {
        
        guard numbers.count == 3 else { return }
        
        dicePickerA.selectRow(numbers[0]-1, inComponent: 0, animated: true)
        dicePickerB.selectRow(numbers[1]-1, inComponent: 0, animated: true)
        dicePickerC.selectRow(numbers[2]-1, inComponent: 0, animated: true)
    }
    
    @IBAction func calculateButtonTouched(_ sender: UIButton) {
        
        var numbers = [SlamNumber]()
        numbers.append(SlamNumber(value: dicePickerA.selectedRow(inComponent: 0)+1))
        numbers.append(SlamNumber(value: dicePickerB.selectedRow(inComponent: 0)+1))
        numbers.append(SlamNumber(value: dicePickerC.selectedRow(inComponent: 0)+1))
        
        
        spinner.startAnimating()
        resultsFoundLabel.isHidden = false
        viewResultsButton.isEnabled = false
        resultsFoundLabel.text = "Creating combinations"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.punchBuilder.performCalculationsOn(numbers: numbers)
        }
    }
    
    //MARK: - UIPickerView Protocol Methods
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 6
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        
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
            
            if let navController = segue.destination as? UINavigationController,
                let punchTVC = navController.viewControllers.first as? PunchTableViewController
            {
                let diceNumbers = [dicePickerA.selectedRow(inComponent: 0) + 1,
                                   dicePickerB.selectedRow(inComponent: 0) + 1,
                                   dicePickerC.selectedRow(inComponent: 0) + 1]
                punchTVC.punches = punchBuilder.results
                punchTVC.navigationItem.title = "\(diceNumbers) ➡︎ \(numberToBuild)"
                
                punchTVC.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                punchTVC.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        //items.append(next)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        numberToBuildTextField.inputAccessoryView = doneToolbar
        
    }
    @objc func doneButtonAction() {
        
        self.view?.currentFirstResponder()?.resignFirstResponder()
    }
    

}

extension NumberBuilderTVC: PunchBuilderDelegateProtocol {
    
    func resultsUpdate(number: Int) {
        DispatchQueue.main.async {
            self.resultsFoundLabel.text = "Total Solutions Found: \(number)"
            self.resultsFoundLabel.isHidden = false
        }
    }
    
    func resultsFinal(number: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.spinner.stopAnimating()
            self?.viewResultsButton.isEnabled = true
            self?.resultsFoundLabel.text = "Total Solutions Found: \(number)"
            self?.resultsFoundLabel.isHidden = false
        }
    }
    
    
}

extension NumberBuilderTVC: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        viewResultsButton.isEnabled = false
        resultsFoundLabel.text = ""
        if let text = textField.text {
            numberToBuild = Int(text) ?? 0
            punchBuilder.numberToBuild = numberToBuild
            calculateButton.isEnabled = text != ""
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        calculateButton.isEnabled = false
    }
    
}


