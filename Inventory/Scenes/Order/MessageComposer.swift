//
//  MessageComposer.swift
//  Mobile
//
//  https://www.andrewcbancroft.com/2014/10/28/send-text-message-in-app-using-mfmessagecomposeviewcontroller-with-swift/
//  http://stackoverflow.com/questions/26350220/sending-sms-in-ios-with-swift
//
//  Created by Mathew Gacy on 11/8/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import Foundation
import MessageUI

class MessageComposer: NSObject, MFMessageComposeViewControllerDelegate {

    var completionHandler: ((_ result: MessageComposeResult) -> Void?)?

    /*
    init(completionHandler: @escaping (MessageComposeResult) -> Void?) {
        self.completionHandler = completionHandler
    }
    */

    // A wrapper function to indicate whether or not a text message can be sent from the user's device
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }

    // Configures and returns a MFMessageComposeViewController instance
    func configuredMessageComposeViewController(phoneNumber: String, message: String, completionHandler: ((MessageComposeResult) -> Void)?) -> MFMessageComposeViewController {

        if let handler = completionHandler {
            self.completionHandler = handler
        }

        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self  //  Allow the controller to be dismissed

        // Configure the fields of the interface.
        messageComposeVC.recipients = [phoneNumber]
        messageComposeVC.body = message
        return messageComposeVC
    }

    // MFMessageComposeViewControllerDelegate callback - dismisses the view controller when the user is finished with it
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)

        guard let completionHandler = completionHandler else {
            log.error("\(#function) : no completion handler")
            return
        }
        completionHandler(result)
    }

}
