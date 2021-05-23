//
//  RoundRectButton.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/28/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class RoundRectButton: UIButton {

    /*
     // Override to support programmatic creation.
     override init(frame: CGRect) {
     super.init(frame: frame)

     // set other operations after super.init, if required
     backgroundColor = UIColor.blue
     }
     */

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //backgroundColor = ColorPalette.lightGrayColor
        setTitleColor(UIColor.white, for: .normal)
        //setTitleColor(UIColor.green, for: .highlighted)
        //titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
        layer.cornerRadius = 5
    }

}
