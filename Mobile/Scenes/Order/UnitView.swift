//
//  UnitView.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/20/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import UIKit

class UnitView: UIView {

    var currentUnit: CurrentUnit
    var lineWidth: CGFloat = 1

    private var baseUnit: Double {
        return Double(bounds.height / 5)
    }

    // MARK: - Animation
    private let animationDuration = 0.5
    private let animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

    // MARK: Layers

    private enum UnitLayerBounds {
        case single
        case bottomPack
        case topPack
    }

    private var singleUnitLayer: CAShapeLayer
    private var packUnitLayer: CAShapeLayer

    // MARK: - Lifecycle

    init(currentUnit: CurrentUnit = .singleUnit) {
        self.currentUnit = currentUnit
        self.singleUnitLayer = CAShapeLayer()
        self.packUnitLayer = CAShapeLayer()
        super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        self.configure()
    }

    override init(frame: CGRect) {
        self.currentUnit = .singleUnit
        self.singleUnitLayer = CAShapeLayer()
        self.packUnitLayer = CAShapeLayer()
        super.init(frame: frame)
        self.configure()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Methods

    private func configure() {
        backgroundColor = UIColor.white
        (configureLayer >>> layer.addSublayer)(singleUnitLayer)
        (configureLayer >>> layer.addSublayer)(packUnitLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        switch currentUnit {
        case .packUnit:
            singleUnitLayer.path = (makePath >>> configurePath)(.bottomPack).cgPath
            packUnitLayer.path = (makePath >>> configurePath)(.topPack).cgPath
        case .singleUnit:
            singleUnitLayer.path = (makePath >>> configurePath)(.single).cgPath
            packUnitLayer.path = (makePath >>> configurePath)(.single).cgPath
        case .invalidUnit:
            return
        }
    }

    // MARK: - A

    func toggleUnit(animated: Bool = true) {
        switch currentUnit {
        case .singleUnit:
            updateUnit(.packUnit)
        case .packUnit:
            updateUnit(.singleUnit)
        case .invalidUnit:
            updateUnit(.packUnit)
        }
    }

    func updateUnit(_ newUnit: CurrentUnit, animated: Bool = true) {
        if newUnit == currentUnit {
            return
        }
        switch (currentUnit, newUnit) {
        case (.singleUnit, .packUnit):
            print("Switching to pack ...")
            currentUnit = .packUnit
            if animated {
                animatePackUnit()
            } else {
                packUnitLayer.path = (makePath >>> configurePath)(.topPack).cgPath
                singleUnitLayer.path = (makePath >>> configurePath)(.bottomPack).cgPath
            }
        case (.packUnit, .singleUnit):
            print("Switching to single ...")
            currentUnit = .singleUnit
            if animated {
                animateSingleUnit()
            } else {
                let endPath = (makePath >>> configurePath)(.single).cgPath
                packUnitLayer.path = endPath
                singleUnitLayer.path = endPath
            }
        default:
            log.warning("Unable to handle transition: \(currentUnit) -> \(newUnit)")
        }
    }

    // MARK: - Animation

    private func animatePackUnit() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(animationTimingFunction)

        let packEndPath = (makePath >>> configurePath)(.topPack).cgPath
        animatePathTransformation(for: packUnitLayer, to: packEndPath)

        let singleEndPath = (makePath >>> configurePath)(.bottomPack).cgPath
        animatePathTransformation(for: singleUnitLayer, to: singleEndPath)

        CATransaction.commit()
    }

    private func animateSingleUnit() {
        CATransaction.begin()
        CATransaction.setAnimationDuration(animationDuration)
        CATransaction.setAnimationTimingFunction(animationTimingFunction)

        let endPath = (makePath >>> configurePath)(.single).cgPath
        animatePathTransformation(for: packUnitLayer, to: endPath)
        animatePathTransformation(for: singleUnitLayer, to: endPath)

        CATransaction.commit()
    }

    private func animatePathTransformation(for layer: CAShapeLayer, to endPath: CGPath) {
        let layerAnimation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.path))
        layerAnimation.fromValue = layer.path
        layerAnimation.toValue = endPath
        layer.path = endPath
        layer.add(layerAnimation, forKey: layerAnimation.keyPath)
    }

    // MARK: - Drawing

    private func makePath(for unitType: UnitLayerBounds) -> UIBezierPath {
        let x: Double
        let y: Double
        let width: Double

        switch unitType {
        case .single:
            x = baseUnit
            y = baseUnit
            width = 3.0 * baseUnit
        case .bottomPack:
            x = baseUnit
            y = 2.0 * baseUnit
            width = 2.0 * baseUnit
        case .topPack:
            x = 2.0 * baseUnit
            y = baseUnit
            width = 2.0 * baseUnit
        }

        /// TODO: should `cornerRadius` = `lineWidth`?
        return UIBezierPath(roundedRect: CGRect(x: x, y: y, width: width, height: width), cornerRadius: 1)
    }

    private func configurePath(_ path: UIBezierPath) -> UIBezierPath {
        path.lineWidth = lineWidth
        path.lineJoinStyle = .round
        return path
    }

    private func configureLayer(_ layer: CAShapeLayer) -> CAShapeLayer {
        layer.fillColor = UIColor.white.cgColor
        layer.strokeColor = UIColor.black.cgColor
        return layer
    }

}
