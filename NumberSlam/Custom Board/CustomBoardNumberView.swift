//
//  CustomBoardNumberView.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/18/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class CustomBoardNumberView: UIView {

    //@IBOutlet weak var contentView: UIView!
    var textField = UITextField()
    var value = 0
    //var textField = UITextField() { didSet {setNeedsDisplay()} }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        //setup()
//        
//    }
    
    init(frame: CGRect, number: Int = 0) {
        super.init(frame: frame)
        value = number
        
        setup()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        
        //Bundle.main.loadNibNamed("CustomBoardNumberViewNib", owner: self, options: nil)
        self.autoresizesSubviews = true
        self.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleRightMargin, . flexibleBottomMargin]
        layer.cornerRadius = CGFloat(5)
        backgroundColor = .blue
        textField.textColor = .white
        textField.text = "\(value)"
        
        if let font = UIFont(name: "AvenirNext-Bold", size: 30) {
            textField.font = font
        }
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.frame = self.bounds
        addSubview(textField)
        
        textField.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        textField.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        textField.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        textField.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
        dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)

        
    }
    
//    override func draw(_ rect: CGRect) {
//        //dropShadow(color: .black, opacity: 0.5, offSet: CGSize(width: 2, height: 2), radius: 2, scale: true)
//        //textField.frame = self.frame
//    }
    

}
