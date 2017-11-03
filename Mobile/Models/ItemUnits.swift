//
//  ItemUnits.swift
//  Mobile
//
//  Created by Mathew Gacy on 11/2/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

// MARK: - Units

/// TODO: use abbreviation as associated value?
enum CurrentUnit {
    case packUnit
    case singleUnit
    case invalidUnit
}

struct ItemUnits {
    var packUnit: Unit?
    var singleUnit: Unit?
    var currentUnit: CurrentUnit?

    init(item: Item?, currentUnit: Unit?) {
        guard let item = item else {
            return
        }

        self.packUnit = item.purchaseUnit
        self.singleUnit = item.purchaseSubUnit

        guard let currentUnit = currentUnit else {
            self.currentUnit = nil
            return
        }

        if let pUnit = self.packUnit, currentUnit == pUnit {
            self.currentUnit = .packUnit
        } else if let sUnit = self.singleUnit, currentUnit == sUnit {
            self.currentUnit = .singleUnit
        } else {
            self.currentUnit = .invalidUnit
        }
    }

    public mutating func switchUnit(_ newUnitCase: CurrentUnit) -> Unit? {
        guard newUnitCase != currentUnit else {
            log.debug("\(#function) FAILED : tried to switchUnit to currentUnit")
            return nil
        }
        switch newUnitCase {
        case .singleUnit:
            guard let newUnit = singleUnit else {
                return nil
            }
            currentUnit = .singleUnit
            return newUnit
        case .packUnit:
            guard let newUnit = packUnit else {
                return nil
            }
            currentUnit = .packUnit
            return newUnit
        default:
            log.error("\(#function)) FAILED : tried to switch unit to .invalidUnit")
            return nil
        }
    }

    public mutating func toggle() -> Unit? {
        guard let currentUnitCase = self.currentUnit else {
            /// TODO: can we somehow still change the unit?
            return nil
        }

        switch currentUnitCase {
        case .singleUnit:
            guard let newUnit = packUnit else {
                return nil
            }
            currentUnit = .packUnit
            return newUnit
        case .packUnit:
            guard let newUnit = singleUnit else {
                return nil
            }
            currentUnit = .singleUnit
            return newUnit
        case .invalidUnit:
            log.error("\(#function) FAILED : currentUnit.invalidUnit")

            if let newUnit = packUnit {
                currentUnit = .packUnit
                return newUnit
            } else if let newUnit = singleUnit {
                currentUnit = .singleUnit
                return newUnit
            }
            return nil
        }
    }

}
