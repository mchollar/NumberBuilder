//
//  AboutPageTVC.swift
//  ReadingTime
//
//  Created by Micah Chollar on 2/14/19.
//  Copyright © 2019 Widgetilities. All rights reserved.
//

import UIKit
import MessageUI

class AboutPageTVC: UITableViewController {

    
    @IBOutlet weak var infoView: UIView!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var ratingButtonView: UIView!
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    var appVersion: String? = {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
    }()
    var appBuild: String? = {
        return Bundle.main.infoDictionary!["CFBundleVersion"] as? String
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        
        self.navigationItem.title = NSLocalizedString("About", comment: "About page title")
        
        infoView.addRoundedShadow()
        ratingButtonView.addRoundedShadow()
        iconImageView.addRoundedShadow()
        iconImageView.clipsToBounds = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let appVersion = self.appVersion, let appBuild = self.appBuild {
            versionLabel.text = "\(appVersion)(\(appBuild))"
        }
        
    }

    
    @objc func doneButtonTouched() {
        dismiss(animated: true)
    }
    
    
    @IBAction func reviewButtonTouched(_ sender: UIButton) {
        guard let writeReviewURL = URL(string: "https://itunes.apple.com/app/id1448609572?action=write-review") // TODO: fix link
            else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
    }
    
    
    @IBAction func feedbackButtonTouched(_ sender: UIButton) {
        guard MFMailComposeViewController.canSendMail() else {
            
            let okString = NSLocalizedString("OK", comment: "OK")
            let alertTitle = NSLocalizedString("Error", comment: "Error")
            let alertMessage = NSLocalizedString("Unable to send mail. Please check settings and enable mail.", comment: "Unable to send mail. Please check settings and enable mail.")
            
            let okAction = UIAlertAction(title: okString, style: .default, handler: nil)
            let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
            alert.addAction(okAction)
            present(alert, animated: true)
            print("Unable to send email")
            return
        }
        
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = self
        mail.setToRecipients(["support@widgetilities.com"])
        let subject = "Feedback for Number Builder " + (appVersion ?? "Version error")
        mail.setSubject(subject)
        
        present(mail, animated: true)
        
    }
    
}

extension AboutPageTVC: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        
        if let error = error {
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            let alert = UIAlertController(title: "Mail Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(okAction)
            present(alert, animated: true) {
                controller.dismiss(animated: true, completion: nil)
            }
            
            return
        }
        
        controller.dismiss(animated: true, completion: nil)
    }
}
