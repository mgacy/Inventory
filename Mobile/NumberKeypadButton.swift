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
        
        // let blueColor = UIColor(red: 0/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1.0)
        backgroundColor = UIColor.lightGray
        setTitleColor(UIColor.black, for: .normal)
    }
    
}
