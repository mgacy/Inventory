//
//  VendorRepView.swift
//  Mobile
//
//  Created by Mathew Gacy on 6/21/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import UIKit

class VendorRepView: UIView {

    //var viewModel: VendorRepViewModel
    //var viewModel: OrderViewModel

    // MARK: - Lifecycle

    /*
     // Only override draw() if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func draw(_ rect: CGRect) {
        // Drawing code
     }
     */

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        //let playerView: UIView = UINib.loadPlayerScoreboardMoveEditorView(self)
        //self.addSubview(playerView)
        //self.playerNibView = playerView

        //styleUI()
    }

    // MARK: -

    func callRep() {
        log.debug("Call Rep")
    }

    func emailRep() {
        log.debug("Email Rep")
    }

    func messageRep() {
        log.debug("Message Rep")
    }

    // MARK: -

}
