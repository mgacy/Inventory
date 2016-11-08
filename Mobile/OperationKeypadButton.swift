//
//  OperationKeypadButton.swift
//  Playground
//
//  http://stackoverflow.com/questions/27079681/how-to-init-a-uibutton-subclass
//
//  Created by Mathew Gacy on 10/13/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

class OperationKeypadButton: UIButton {

    required init?(coder aDecoder: NSCoder) {        
        super.init(coder: aDecoder)
        
        // set other operations after super.init, if required
        backgroundColor = ColorPalette.secondaryColor
        setTitleColor(UIColor.white, for: .normal)
        //setTitleColor(UIColor.green, for: .highlighted)
        titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
    }

}
