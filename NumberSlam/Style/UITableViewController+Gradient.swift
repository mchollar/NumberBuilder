//
//  UIViewController+Gradient.swift
//  LessonForecast
//
//  Created by Micah Chollar on 7/28/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController {
    func addGradientToBackGround(color1: UIColor, color2: UIColor) {
        
        let gradientBackground = UIView(frame: view.frame)
        if gradientBackground.frame.size.width > gradientBackground.frame.size.height {
            gradientBackground.frame.size.height = gradientBackground.frame.size.width
        } else {
            gradientBackground.frame.size.width = gradientBackground.frame.size.height
        }
        
        ColorPalette.addGradient(to: gradientBackground, color1: color1, color2: color2)
        tableView.backgroundView = gradientBackground
    }

}
