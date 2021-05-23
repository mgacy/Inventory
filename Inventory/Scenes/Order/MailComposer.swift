//
//  MailComposer.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/6/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//
//  http://www.andrewcbancroft.com/2014/08/25/send-email-in-app-using-mfmailcomposeviewcontroller-with-swift/
//

import Foundation
import MessageUI

class MailComposer: NSObject, MFMailComposeViewControllerDelegate {

    //var completionHandler: ((_ result: MFMailComposeResult) -> Void?)?
    var completionHandler: ((_ result: MessageComposeResult) -> Void?)?

    /*
     init(completionHandler: @escaping (MFMailComposeResult) -> Void?) {
        self.completionHandler = completionHandler
     }
     */

    // A wrapper function to indicate whether or not an email can be sent from the user's device
    func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }

    // Configures and returns a MFMailComposeViewController instance
    func configuredMailComposeViewController(recipients: [String], subject: String, message: String, completionHandler: ((MessageComposeResult) -> Void)?) -> MFMailComposeViewController {

        if let handler = completionHandler {
            self.completionHandler = handler
        }

        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self  //  Allow the controller to be dismissed

        // Configure the fields of the interface.
        mailComposerVC.setToRecipients(recipients)
        mailComposerVC.setSubject(subject)
        mailComposerVC.setMessageBody(message, isHTML: false)

        return mailComposerVC
    }

    // MFMailComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        guard let completionHandler = completionHandler else {
            log.error("\(#function) : no completion handler")
            return
        }
        //completionHandler(result)

        switch result {
        case .cancelled:
            completionHandler(.cancelled)
        case .saved:
            // TODO: is this the best way to handle this?
            completionHandler(.cancelled)
        case .sent:
            completionHandler(.sent)
        case .failed:
            completionHandler(.failed)
        }

    }

}
