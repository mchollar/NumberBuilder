//
//  SlamView.swift
//  SlamView
//
//  Created by Micah Chollar on 11/7/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class SlamView: UIView {
    
    var points: [RadialPoint] = [RadialPoint]()
    //var textLabel = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = 5.0
        layer.masksToBounds = true
        self.backgroundColor = UIColor.red
        loadPoints()
//        if let font = UIFont(name: "AvenirNext-Bold", size: 60) {
//            textLabel.font = font
//        }
//        textLabel.text = "1s"
//        textLabel.textColor = .white
//        textLabel.sizeToFit()
//        self.addSubview(textLabel)
//        textLabel.center = CGPoint(x: bounds.size.width/2, y: bounds.size.height/2)
        
    }
    
    func loadPoints() {
        
        let number = Int.random(in: 10..<15)
        for i in 0 ..< number {
            let distance = Int.random(in: 80...150)
            //let radial = CGFloat(i) * (2 * CGFloat.pi / CGFloat(number))
            let degrees = (CGFloat(i) * (360 / CGFloat(number))) + CGFloat(Int.random(in: -10...10))
            let point = RadialPoint(distance: distance, degrees: degrees)
            points.append(point)
            
        }
    }
    
    
    
    override func draw(_ rect: CGRect) {
        
        //Draw grid in background
                ColorPalette.slamBlue.setFill()
                let inset = CGFloat(5)
                let gridSize = CGSize(width: bounds.size.width/6, height: bounds.size.height/6)
                let squareSideLength = gridSize.width - (inset * 2)
                for row in 0 ..< 6 {
                    for column in 0 ..< 6 {
        
                        let newRect = CGRect(x: CGFloat(column) * gridSize.width + inset,
                                             y: CGFloat(row) * gridSize.height + inset,
                                             width: squareSideLength,
                                             height: squareSideLength)
                        let square = UIBezierPath.init(roundedRect: newRect, cornerRadius: 5)
                        square.fill()
                    }
                }
        
        //Draw blast
        let blastPath = UIBezierPath()
        if let point = points.first {
            
            let startX = self.bounds.size.width / 2
            let startY = self.bounds.size.height / 2 - (self.bounds.size.height / 2 * CGFloat(point.distance)/100)
            let startPoint = CGPoint(x: startX, y: startY)
            blastPath.move(to: startPoint)
            
            for point in points {
                let startX = self.bounds.size.width / 2
                let startY = self.bounds.size.height / 2 - (self.bounds.size.height / 2 * CGFloat(point.distance)/100)
                let startPoint = CGPoint(x: startX, y: startY)
                
                let endPoint = rotatePoint(target: startPoint, aroundOrigin: CGPoint(x: bounds.size.width/2, y: bounds.size.height/2), byDegrees: point.degrees)
                //blastPath.addLine(to: endPoint)
                blastPath.addQuadCurve(to: endPoint, controlPoint: CGPoint(x: bounds.size.width/2, y: bounds.size.height/2))
            }
            
            blastPath.addQuadCurve(to: startPoint, controlPoint: CGPoint(x: bounds.size.width/2, y: bounds.size.height/2))
        }
        
        UIColor.blue.setFill()
        UIColor.black.setStroke()
        blastPath.lineWidth = 2.0
        blastPath.stroke()
        blastPath.fill()
        
    }
    
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byRads: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byRads  // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
    
    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byDegrees: CGFloat) -> CGPoint {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx) // in radians
        let newAzimuth = azimuth + byDegrees * CGFloat(Double.pi / 180.0) // convert it to radians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return CGPoint(x: x, y: y)
    }
}

struct RadialPoint {
    var distance: Int
    //var radial: CGFloat
    var degrees: CGFloat
    
}
