//
//  RandomSettingViewController.swift
//  NumberSlam
//
//  Created by Micah Chollar on 10/27/18.
//  Copyright © 2018 Widgetilities. All rights reserved.
//

import UIKit

class RandomSettingViewController: UIViewController {

    var maxValue: Int? {
        didSet {
            if maxValueLabel != nil {
                maxValueLabel.text = "\(maxValue ?? -1)"
            }
        }
    }
    
    var delegate: CustomBoardCVC?
    
    @IBOutlet weak var maxValueLabel: UILabel!
    @IBOutlet weak var slider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if maxValue != nil {
            slider.value = Float(maxValue!)
            maxValueLabel.text = "\(maxValue!)"
        }
        
        ColorPalette.addGradient(to: self.view, color1: .white, color2: ColorPalette.backgroundGray)
    }
    

    @IBAction func sliderChanged(_ sender: UISlider) {
        
        maxValue = Int(sender.value)
        
    }
    
    
//    @IBAction func doneButtonTouched(_ sender: UIButton) {
//        
//        if maxValue != nil {
//            delegate?.maxRandom = maxValue!
//        }
//        self.dismiss(animated: true, completion: nil)
//    }
//    
//    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
//        if maxValue != nil {
//            delegate?.maxRandom = maxValue!
//        }
//        super.dismiss(animated: flag, completion: nil)
//    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if maxValue != nil {
            delegate?.maxRandom = maxValue!
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
