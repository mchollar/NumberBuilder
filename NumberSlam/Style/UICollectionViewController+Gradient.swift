//
//  UICollectionViewController+Gradient.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/14/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation
import UIKit

extension UICollectionViewController {
    func addGradientToBackGround(color1: UIColor, color2: UIColor) {
        
        let gradientBackground = UIView(frame: view.frame)
        if gradientBackground.frame.size.width > gradientBackground.frame.size.height {
            gradientBackground.frame.size.height = gradientBackground.frame.size.width
        } else {
            gradientBackground.frame.size.width = gradientBackground.frame.size.height
        }
        
        ColorPalette.addGradient(to: gradientBackground, color1: color1, color2: color2)
        collectionView.backgroundView = gradientBackground
    }
    
}
