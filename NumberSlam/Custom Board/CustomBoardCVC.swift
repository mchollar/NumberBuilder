//
//  CustomBoardCVC.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/16/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

private let reuseIdentifier = "CustomCell"

class CustomBoardCVC: UICollectionViewController, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {

    var activeField: UITextField?
    var textFields = [UITextField]()
    var slamBoard: SlamBoard?
    var numbers = [Int?]()
    var maxRandom = 256
    
    let columnLayout = SlamBoardLayout(
        cellsPerRow: 6,
        minimumInteritemSpacing: 10,
        minimumLineSpacing: 10,
        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
    )
    
    let fontSize = CGFloat(30)
    let smallFontSize = CGFloat(22)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.collectionViewLayout = columnLayout
        collectionView?.contentInsetAdjustmentBehavior = .always
        
        addGradientToBackGround(color1: ColorPalette.slamBlueBackground, color2: ColorPalette.backgroundGray)
        
        setupBoard()
    }

    func setupBoard() {
        for _ in 0 ..< 36 {
            numbers.append(nil)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isToolbarHidden = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isToolbarHidden = true
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
        case "SetMaxPopover":
            let destinationVC = segue.destination as! RandomSettingViewController
            destinationVC.maxValue = maxRandom
            destinationVC.delegate = self
        case "UseCustomBoard":
            let destinationVC = segue.destination as! NumberSlamViewController
            var tempNumbers = [Int]()
            for number in numbers {
                if number != nil {
                    tempNumbers.append(number!)
                } else {
                    tempNumbers.append(0)
                }
            }
            self.slamBoard = SlamBoard(numbers: tempNumbers)
            destinationVC.slamBoard = slamBoard
            
        default:
            break
        }
        
    }

    
    @IBAction func setMaxButtonTouched(_ sender: UIBarButtonItem) {
        
        guard let maxRandomVC = self.storyboard?.instantiateViewController(withIdentifier: "RandomSettingViewController") as? RandomSettingViewController else {
            return
        }
        maxRandomVC.modalPresentationStyle = .popover
        maxRandomVC.preferredContentSize = CGSize(width: 300, height: 125)
        maxRandomVC.delegate = self
        maxRandomVC.maxValue = maxRandom
        
        if let presentationController = maxRandomVC.popoverPresentationController {
            presentationController.delegate = self
            presentationController.permittedArrowDirections = [.up, .down]
            presentationController.sourceView = self.navigationController?.toolbar
            
            self.present(maxRandomVC, animated: true, completion: nil)
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        // Tells iOS that we do NOT want to adapt the presentation style for iPhone, so the random max setting pop up doesn't show up fullscreen
        return .none
    }
    
    // MARK: - UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 36
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CustomBoardCollectionViewCell
    
        cell.layer.cornerRadius = CGFloat(5)
        cell.backgroundColor = .blue
        cell.textField.textColor = .white
        if cell.textField.inputAccessoryView == nil {
            addDoneButtonOnKeyboard(textField: cell.textField)
        }
        
        if numbers[indexPath.row] != nil {
            cell.textField.text = "\(numbers[indexPath.row]!)"
            handleFontOf(cell.textField, with: numbers[indexPath.row]!)
        } else {
            cell.textField.text = ""
        }
        cell.textField.tag = indexPath.row
        cell.textField.delegate = self
        cell.dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
        
        return cell
    }

    
    @IBAction func randomButtonTouched(_ sender: UIBarButtonItem) {
        
        var randomNumbers = [Int]()
        
        for _ in 0 ..< 36 {
            var randomValue = Int.random(in: 1...maxRandom)
            while randomNumbers.contains(randomValue) {
                randomValue = Int.random(in: 1...maxRandom)
            }
            randomNumbers.append(randomValue)
            
        }
        randomNumbers.sort()
        
        for i in 0 ..< 36 {
            numbers[i] = randomNumbers[i]
            if let cell = collectionView(collectionView, cellForItemAt: IndexPath(row: i, section: 0)) as? CustomBoardCollectionViewCell {
                cell.textField.text = "\(randomNumbers[i])"
                collectionView.reloadItems(at: [IndexPath(item: i, section: 0)])
            }
        }
        
    }
    

    //MARK: - TextField methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard textField.text != nil else { return }
        if let value = Int(textField.text!) {
            
            numbers[textField.tag] = value
            handleFontOf(textField, with: value)
        } else { // Bad input, set value back to where it was
            textField.text = numbers[textField.tag] != nil ?
                "\(numbers[textField.tag]!)" : ""
        }
        
    }
    
    func handleFontOf(_ textField: UITextField, with value: Int) {
        if value > 99 {
            if let font = UIFont(name: "AvenirNext-Bold", size: smallFontSize) {
                textField.font = font
            }
        } else {
            if let font = UIFont(name: "AvenirNext-Bold", size: fontSize) {
                textField.font = font
            }
        }
    }
    
    func flagDuplicates() {
        guard let slamBoard = self.slamBoard else { return }
        
        var duplicateIndeces = [Int]()
        for index in 0 ..< slamBoard.numbers.count {
            for j in 0 ..< slamBoard.numbers.count {
                if index != j,
                    slamBoard.numbers[index] == slamBoard.numbers[j] {
                    duplicateIndeces.append(index)
                }
            }
        }
        
        for index in duplicateIndeces {
            if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? CustomBoardCollectionViewCell {
                cell.textField.textColor = .red
            }
        }
    }
    
    //MARK: - Keyboard methods
    
    func addDoneButtonOnKeyboard(textField: UITextField) {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        textField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        
        self.view?.currentFirstResponder()?.resignFirstResponder()
    }
    
}


extension UIView {
    //Extension to find current first responder, so we can dismiss it when the user is done with input
    
    func currentFirstResponder() -> UIResponder? {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder() {
                return responder
            }
        }
        
        return nil
    }
}
