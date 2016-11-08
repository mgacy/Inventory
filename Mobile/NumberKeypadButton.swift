//
//  NumberKeypadButton.swift
//  Playground
//
//  http://stackoverflow.com/questions/27079681/how-to-init-a-uibutton-subclass
//
//  Created by Mathew Gacy on 10/13/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class NumberKeypadButton: UIButton {
    
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
        
        backgroundColor = ColorPalette.lightGrayColor
        setTitleColor(UIColor.white, for: .normal)
        //setTitleColor(UIColor.green, for: .highlighted)
        titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
    }
    
}
