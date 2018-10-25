//
//  CustomBoardCVC.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/16/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

private let reuseIdentifier = "CustomCell"

class CustomBoardCVC: UICollectionViewController, UITextFieldDelegate {

    var activeField: UITextField?
    var textFields = [UITextField]()
    var slamBoard: SlamBoard?
    var numbers = [Int?]()
    
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
        //registerForKeyboardNotification()
        //flagDuplicates()
    }

    func setupBoard() {
//        for index in 0 ..< 36 {
//            let textField = UITextField()
//            textField.tag = index
//            textFields.append(textField)
//        }
//        //addDoneButtonOnKeyboard()
        //Check if slamBoard is already set, if not create one full of zeroes
//        if slamBoard == nil {
//            var numbers = [Int]()
//            for _ in 0 ..< 36 {
//                numbers.append(0)
//            }
//            slamBoard = SlamBoard(numbers: numbers)
//
//        }
        for _ in 0 ..< 36 {
            numbers.append(nil)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        for index in 0 ..< 36 {
            if let cell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) {
                
                cell.dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
                
            }
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        let destinationVC = segue.destination as! ViewController
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
        
    
    }
    

    // MARK: UICollectionViewDataSource

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
            addDoneButtonOnKeyboard(textField: cell.textField) // Need to not do this every time
        }
        
        //cell.textField.text = "\(slamBoard?.numbers[indexPath.row] ?? 0)"
        
        cell.textField.tag = indexPath.row
        cell.textField.delegate = self
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

    //MARK: - TextField methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        guard textField.text != nil else { return }
        if let value = Int(textField.text!) {
            
            numbers[textField.tag] = value
            
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
        //Find duplicate values and flag them
        //flagDuplicates()
        
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
        
//        for textfield in textFields {
//            textfield.inputAccessoryView = doneToolbar
//        }
        textField.inputAccessoryView = doneToolbar
    }
    
    @objc func doneButtonAction() {
        
        self.view?.currentFirstResponder()?.resignFirstResponder()
    }
    
    private func registerForKeyboardNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasShown(notification:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWasHidden(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc private func keyboardWasShown(notification: Notification) {
        
        //self.scrollView.isScrollEnabled = true
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize!.height, right: 0.0)
        
        self.collectionView.contentInset = contentInsets
        self.collectionView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height + 30
        if activeField != nil
        {
            if (!aRect.contains(activeField!.frame.origin))
            {
                self.collectionView.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWasHidden(notification: Notification) {
        
        //Once keyboard disappears, restore original positions
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -(keyboardSize!.height + 30), right: 0.0)
        self.collectionView.contentInset = contentInsets
        self.collectionView.scrollIndicatorInsets = contentInsets
    }
}


extension UIView {
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
