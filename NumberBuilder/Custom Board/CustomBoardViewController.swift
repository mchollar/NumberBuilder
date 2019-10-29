//
//  CustomBoardViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/18/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class CustomBoardViewController: UIViewController, UIScrollViewDelegate, UITextFieldDelegate {

    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var boardStackView: UIStackView!
    var slamBoard: SlamBoard?
    var textFields = [UITextField]()
    var activeField: UITextField?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setupBoard()
        registerForKeyboardNotification()
        addDoneButtonOnKeyboard()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    func setupBoard() {
        
        //Check if slamBoard is already set, if not create one full of zeroes
        if slamBoard == nil {
            var numbers = [Int]()
            for _ in 0 ..< 36 {
                numbers.append(0)
            }
            slamBoard = SlamBoard(numbers: numbers)
            
        }
        
//        boardStackView.alignment = .fill
//        boardStackView.distribution = .fillEqually
//        boardStackView.axis = .vertical
//        boardStackView.heightAnchor.constraint(equalTo: boardStackView.widthAnchor, multiplier: 1).isActive = true
        
        for row in 0 ..< 6 {
            let rowStackView = UIStackView()
            rowStackView.alignment = .fill
            rowStackView.distribution = .fillEqually
            rowStackView.axis = .horizontal
            rowStackView.spacing = 10.0
            
            for column in 0 ..< 6 {
                let frameSize = CGSize(width: boardStackView.frame.width / CGFloat(6),
                                       height: boardStackView.frame.width / CGFloat(6))
                //let label = UITextField(frame: CGRect(origin: .zero, size: frameSize))
                let numberIndex = (row * 6) + column
                let label = CustomBoardNumberView(frame: CGRect(origin: .zero, size: frameSize), number: slamBoard?.numbers[numberIndex] ?? -1)
                textFields.append(label.textField)
                label.textField.delegate = self
                
                label.tag = numberIndex
                //label.text = "\(slamBoard?.numbers[numberIndex] ?? -1)"
                
                //label.textAlignment = .center
                rowStackView.addArrangedSubview(label)
            }
            
            boardStackView.addArrangedSubview(rowStackView)
        }
    }
    
    //MARK: - Keyboard methods
    
    func addDoneButtonOnKeyboard() {
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        doneToolbar.barStyle       = UIBarStyle.default
        let flexSpace              = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem  = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(doneButtonAction))
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(done)
        
        doneToolbar.items = items
        doneToolbar.sizeToFit()
        
        for textfield in textFields {
            textfield.inputAccessoryView = doneToolbar
        }
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
        
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
        
        var aRect : CGRect = self.view.frame
        aRect.size.height -= keyboardSize!.height + 30
        if activeField != nil
        {
            if (!aRect.contains(activeField!.frame.origin))
            {
                self.scrollView.scrollRectToVisible(activeField!.frame, animated: true)
            }
        }
    }
    
    @objc private func keyboardWasHidden(notification: Notification) {
        
        //Once keyboard disappears, restore original positions
        let info : NSDictionary = notification.userInfo! as NSDictionary
        let keyboardSize = (info[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size
        let contentInsets : UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: -(keyboardSize!.height + 30), right: 0.0)
        self.scrollView.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
}

