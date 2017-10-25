//
//  String+MyStuff.swift
//  Mobile
//
//  Mobile Dan
//  https://stackoverflow.com/a/41668104
//
//  Created by Mathew Gacy on 10/11/17.
//  Copyright © 2017 Mathew Gacy. All rights reserved.
//

import Foundation

extension String {

    /// This method makes it easier extract a substring by character index where a character is viewed as a human-readable character (grapheme cluster).
    internal func substring(start: Int, offsetBy: Int) -> String? {
        guard let substringStartIndex = self.index(startIndex, offsetBy: start, limitedBy: endIndex) else {
            return nil
        }
        guard let substringEndIndex = self.index(startIndex, offsetBy: start + offsetBy, limitedBy: endIndex) else {
            return nil
        }
        return String(self[substringStartIndex ..< substringEndIndex])
    }

}
