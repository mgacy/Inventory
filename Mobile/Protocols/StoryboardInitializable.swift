//
//  StoryboardInitializable.swift
//  RepoSearcher
//
//  Created by Arthur Myronenko on 7/13/17.
//  Copyright © 2017 UPTech Team. All rights reserved.
//

// Also see: https://medium.com/@dineshrajasoundrapandian/used-your-approach-and-did-some-changes-to-make-it-more-shorter-what-do-you-think-b9bce8a55fae?source=linkShare-e4df2cdc875f-1502475103
// Also see: https://medium.com/swift-programming/uistoryboard-safer-with-enums-protocol-extensions-and-generics-7aad3883b44d?source=linkShare-e4df2cdc875f-1502475138

import UIKit

protocol StoryboardInitializable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardInitializable where Self: UIViewController {

    static var storyboardIdentifier: String {
        return String(describing: Self.self)
    }

    static func initFromStoryboard(name: String = "Main") -> Self {
        let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
    }
}

extension UIViewController: StoryboardInitializable {}
