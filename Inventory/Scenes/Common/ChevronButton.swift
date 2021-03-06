//
//  ChevronButton.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/1/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

// https://medium.com/@ronm333/using-idraw-s-core-graphics-code-for-button-images-in-xcode-91ac512e483e
class ChevronButton: UIButton {

    //public enum Direction {
    //    case up, down, left, right
    //}
    //public var direction: Direction = Direction.down
    public var lineColor: UIColor = UIColor(red: 0.5, green: 0.5,
                                            blue: 0.5, alpha: 0.35) // InvoiceDisplayHighlightView.indicatorColor
    public var lineWidth: CGFloat = 3

    private let inset: CGFloat = 2.0

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 38, height: 10))
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.blue
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        // In init, false - not opaque; 0.0 — no scaling
        UIGraphicsBeginImageContextWithOptions(CGSize(width: frame.width, height: frame.height), false, 0.0)
        //let ctx = UIGraphicsGetCurrentContext() // iOS

        let path = UIBezierPath()
        path.move(to: CGPoint(x: inset, y: inset))
        path.addLine(to: CGPoint(x: frame.width / 2.0, y: frame.height - inset))
        path.addLine(to: CGPoint(x: frame.width - inset, y: inset))
        lineColor.setStroke()

        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.stroke()
        //self.backgroundColor = UIColor.green

        if let img = UIGraphicsGetImageFromCurrentImageContext() {
            self.setBackgroundImage(img, for: .normal)
        }
        UIGraphicsEndImageContext()
    }

}
