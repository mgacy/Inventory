//
//  OperationKeypadButton.swift
//  Mobile
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
        setTitleColor(.white, for: .normal)
        setTitleColor(ColorPalette.yellowColor, for: .highlighted)
        setTitleColor(ColorPalette.textColor, for: .disabled)
        //setTitleColor(ColorPalette.darkGrayColor, for: .disabled)
        // NOTE - not sure about the following states for UIButton
        setTitleColor(.red, for: .selected)
        setTitleColor(.blue, for: .focused)
        titleLabel?.font = UIFont.systemFont(ofSize: 22.0)
    }

}
