//
//  ColorPalette.swift
//  LessonForecast
//
//  Created by Micah Chollar on 7/28/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//
import UIKit
import Foundation

struct ColorPalette {
    static let leafGreen = UIColor(red:0.435, green:0.882, blue:0.431, alpha:1.0)
    static let backgroundGreen = UIColor(red:0.624, green:0.882, blue:0.631, alpha:1.0)
    static let skyBlue = UIColor(red:0.463, green:0.804, blue:0.980, alpha:1.0)
    static let backgroundBlue = UIColor(red:0.663, green:0.914, blue:0.984, alpha:1.0)
    static let darkSkyBlue = UIColor(red: 0.245, green: 0.633, blue: 0.903, alpha: 1.0)
    static let appleRed = UIColor(red:0.925, green:0.369, blue:0.271, alpha:1.0)
    static let backgroundGray = UIColor(red: 0.843, green: 0.847, blue: 0.851, alpha:1.0)
    //static let slamRed = UIColor(red: 0.709, green: 0.146, blue: 0.098, alpha: 1.0)
    static let slamRed = UIColor(red: 198, green: 0, blue: 1)
    static let slamRedBackground = UIColor(red: 0.709, green: 0.146, blue: 0.098, alpha: 0.5)
    static let slamBlue = UIColor(red: 0.104, green: 0.156, blue: 0.671, alpha: 1.0)
    static let slamBlueBackground = UIColor(red: 0.104, green: 0.156, blue: 0.671, alpha: 0.5)
    
    static func addGradient(to view: UIView, color1: UIColor, color2: UIColor, alpha: Float = 1.0){
        
        if let oldLayerIndex = view.layer.sublayers?.firstIndex(where: {$0.name == "gradientLayer"}) {
            view.layer.sublayers?.remove(at: oldLayerIndex)
        }
        
        let gradient:CAGradientLayer = CAGradientLayer()
        let maxSide = view.frame.size.width > view.frame.size.height ? view.frame.size.width : view.frame.size.height
        let maxSize = CGSize(width: maxSide, height: maxSide)
        gradient.frame.size = maxSize
        gradient.colors = [color1.cgColor, color2.cgColor]
        gradient.opacity = alpha
        gradient.name = "gradientLayer"
        view.layer.insertSublayer(gradient, at: 0)
        
    }
    
    
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
}
