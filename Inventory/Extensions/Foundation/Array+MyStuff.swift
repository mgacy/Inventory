//
//  Array+MyStuff.swift
//  Mobile
//
//  Created by Mathew Gacy on 12/4/16.
//

import Foundation

extension Array {

    // http://stackoverflow.com/questions/39791084/swift-3-array-to-dictionary
    public func toDictionary<Key: Hashable>(with selectKey: (Element) -> Key) -> [Key: Element] {
        var dict = [Key: Element]()
        for element in self {
            dict[selectKey(element)] = element
        }
        return dict
    }

}
