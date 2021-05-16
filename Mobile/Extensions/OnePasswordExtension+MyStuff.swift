//
//  OnePasswordExtension+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/24/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

//import UIKit
import OnePasswordExtension

extension OnePasswordExtension {

    /// TODO: add enum for different images
    // "onepassword-button.png"
    // "onepassword-button-light.png"

    func getButton(ofWidth width: Int) -> UIButton? {
        let onePasswordButton = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: width))
        onePasswordButton.contentMode = UIViewContentMode.center

        guard let path = Bundle(for: type(of: OnePasswordExtension.shared())).path(
            forResource: "OnePasswordExtensionResources", ofType: "bundle") as String? else {
                return nil
        }
        let onepasswordBundle = Bundle(path: path)
        let image = UIImage(named: "onepassword-button.png", in: onepasswordBundle, compatibleWith: nil)
        onePasswordButton.setImage(image, for: .normal)

        return onePasswordButton
    }

}
