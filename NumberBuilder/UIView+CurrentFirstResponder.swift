//
//  UIView+CurrentFirstResponder.swift
//  NumberBuilder
//
//  Created by Micah Chollar on 10/30/19.
//  Copyright © 2019 Widgetilities. All rights reserved.
//

import UIKit

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
