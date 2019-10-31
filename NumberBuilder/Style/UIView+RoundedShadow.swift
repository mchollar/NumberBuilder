//
//  UIView+RoundedShadow.swift
//  ReadingTime
//
//  Created by Micah Chollar on 2/13/19.
//  Copyright © 2019 Widgetilities. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func addRoundedShadow() {
        layer.cornerRadius = 15.0
        layer.shadowRadius = 3.0
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        
    }
    
}
