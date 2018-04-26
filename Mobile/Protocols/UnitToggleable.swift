//
//  UnitToggleable.swift
//  Mobile
//
//  Created by Mathew Gacy on 4/24/18.
//  Copyright © 2018 Mathew Gacy. All rights reserved.
//

import Foundation

enum NewCurrentUnit {
    case packUnit(Unit)
    case singleUnit(Unit)
    case invalidUnit

    func converted() -> CurrentUnit {
        switch self {
        case .packUnit:
            return .packUnit
        case .singleUnit:
            return .singleUnit
        case .invalidUnit:
            return .invalidUnit
        }
    }

}

extension NewCurrentUnit: Equatable {

    public static func == (lhs: NewCurrentUnit, rhs: NewCurrentUnit) -> Bool {
        switch (lhs, rhs) {
        case (let .packUnit(lhsUnit), let .packUnit(rhsUnit)):
            return lhsUnit == rhsUnit
        case (let .singleUnit(lhsUnit), let .singleUnit(rhsUnit)):
            return lhsUnit == rhsUnit
        case (.invalidUnit, .invalidUnit):
            return true
        default:
            return false
        }
    }

}

public enum UnitConversionError: Error {
    case missingPurchaseUnit
    case missingPurchaseSubUnit
    case missingUnits
    //case missingPackSize
}

protocol ItemProtocol {
    var purchaseUnit: Unit? { get }
    var purchaseSubUnit: Unit? { get }
    var packSize: Int16 { get }
}

// MARK: - Implementation

protocol UnitToggleable: class {
    /// TODO: rename `wrappedItem`?
    var associatedItem: ItemProtocol { get }
    var quantity: NSNumber? { get set }
    var unit: Unit? { get set }
    var currentUnit: NewCurrentUnit { get set }

    /// TODO: should these methods be part of a separate `UnitToggling` protocol?
    func switchToSingleUnit()
    func switchToPackUnit()
}

extension UnitToggleable {

    func switchToSingleUnit() {
        guard let singleUnit = associatedItem.purchaseSubUnit else {
            return
            //throw UnitConversionError.missingPurchaseSubUnit
        }
        unit = singleUnit
    }

    func switchToPackUnit() {
        guard let packUnit = associatedItem.purchaseUnit else {
            return
            //throw UnitConversionError.missingPurchaseUnit
        }
        unit = packUnit
    }

}

extension UnitToggleable {

    var currentUnit: NewCurrentUnit {
        get {
            guard let _unit = unit else {
                return .invalidUnit
            }

            if let pUnit = associatedItem.purchaseUnit, pUnit == _unit {
                return .packUnit(pUnit)
            } else if let sUnit = associatedItem.purchaseSubUnit, sUnit == _unit {
                return .singleUnit(sUnit)
            } else {
                return .invalidUnit
            }
        }
        set(newState) {
            switch newState {
            case .packUnit(let newUnit):
                log.debug("A")
                if newUnit == associatedItem.purchaseUnit {
                    unit = newUnit
                } else {
                    log.warning("Unable to update unit to: \(newUnit)")
                }
            case .singleUnit(let newUnit):
                log.debug("B")
                if newUnit == associatedItem.purchaseSubUnit {
                    unit = newUnit
                } else {
                    log.warning("Unable to update unit to: \(newUnit)")
                }
            case .invalidUnit:
                log.warning("Unable to update unit to: INVALID")
                /// TODO: set to nil?
            }
        }
    }

}
