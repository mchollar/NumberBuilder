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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    private func setup() {
        
        self.backgroundColor = .clear //To make rounded corners appear
        loadPoints()
        
    }
    
    func loadPoints() {
       
        // Constants that define the number and size of points
        let pointsNumber = 25..<30
        let outsideRange = 80...110
        let insideRange = 50...70
        
        var number = Int.random(in: pointsNumber)
        if number % 2 != 0 { number += 1 }
        for i in 0 ..< number {
            var distance = 0
            if i % 2 == 0 {
                distance = Int.random(in: outsideRange)
            } else {
                distance = Int.random(in: insideRange)
            }
            //let radial = CGFloat(i) * (2 * CGFloat.pi / CGFloat(number))
            var degrees = (CGFloat(i) * (360 / CGFloat(number))) + CGFloat(Int.random(in: -2...2))
            if degrees > 360 { degrees = 360 }
            if degrees < 0 { degrees = 0 }
            let point = RadialPoint(distance: distance, degrees: degrees)
            points.append(point)
            
        }
    }
    
    
    
    override func draw(_ rect: CGRect) {
        
        //Draw rounded corners
        let roundedRect = UIBezierPath.init(roundedRect: rect, cornerRadius: 5)
        ColorPalette.slamRed.setFill()
        roundedRect.fill()
        
        //Draw grid in background
        UIColor.red.setStroke()
        let inset = CGFloat(UIDevice.current.orientation.isLandscape ? 5 : 4)
        let gridSize = CGSize(width: bounds.size.width/6, height: bounds.size.height/6)
        let squareSideLength = gridSize.width - (inset * 2)
        for row in 0 ..< 6 {
            for column in 0 ..< 6 {
                
                let newRect = CGRect(x: CGFloat(column) * gridSize.width + inset,
                                     y: CGFloat(row) * gridSize.height + inset,
                                     width: squareSideLength,
                                     height: squareSideLength)
                let square = UIBezierPath.init(roundedRect: newRect, cornerRadius: inset/2)
                square.stroke()
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
                blastPath.addLine(to: endPoint)
                //blastPath.addQuadCurve(to: endPoint, controlPoint: CGPoint(x: bounds.size.width/2, y: bounds.size.height/2))
            }
            
            //blastPath.addQuadCurve(to: startPoint, controlPoint: CGPoint(x: bounds.size.width/2, y: bounds.size.height/2))
            blastPath.addLine(to: startPoint)
        }
        
        ColorPalette.slamBlue.setFill()
        UIColor.white.setStroke()
        blastPath.lineWidth = 2.0
        blastPath.stroke()
        blastPath.fill()
        
    }
    
    
//    func rotatePoint(target: CGPoint, aroundOrigin origin: CGPoint, byRads: CGFloat) -> CGPoint {
//        let dx = target.x - origin.x
//        let dy = target.y - origin.y
//        let radius = sqrt(dx * dx + dy * dy)
//        let azimuth = atan2(dy, dx) // in radians
//        let newAzimuth = azimuth + byRads  // convert it to radians
//        let x = origin.x + radius * cos(newAzimuth)
//        let y = origin.y + radius * sin(newAzimuth)
//        return CGPoint(x: x, y: y)
//    }
    
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
