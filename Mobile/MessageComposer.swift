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
    
    // TODO - this really how I want to do this, or should I just move this into the controller?
    var completionHandler: ((_ succeeded: Bool) -> Void?)? = nil
    
    /*
    init(completionHandler: @escaping (Bool) -> Void?) {
        self.completionHandler = completionHandler
    }
    */
 
    // A wrapper function to indicate whether or not a text message can be sent from the user's device
    func canSendText() -> Bool {
        return MFMessageComposeViewController.canSendText()
    }
    
    // Configures and returns a MFMessageComposeViewController instance
    // TODO - simply pass the Order instance and let this handle everything?
    func configuredMessageComposeViewController(phoneNumber: String, message: String, completionHandler: ((Bool) -> Void)?) -> MFMessageComposeViewController {
        
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
        
        switch result.rawValue {
        case 0:  // cancelled
            print("Message was cancelled")
            controller.dismiss(animated: true, completion: nil)
            
            if let completionHandler = completionHandler {
                // TODO - change to false
                completionHandler(true)
            }
        case 1: // sent
            print("Message was sent")
            controller.dismiss(animated: true, completion: nil)
            
            if let completionHandler = completionHandler {
                completionHandler(true)
            }
            
        case 2: // failed
            print("Message failed")
            controller.dismiss(animated: true, completion: nil)
            
            if let completionHandler = completionHandler {
                completionHandler(false)
            }
        default:
            break;
        }
    }

}
