//
//  ColorPalette.swift
//  Mobile
//
//  Created by Mathew Gacy on 10/25/16.
//  Copyright © 2016 Mathew Gacy. All rights reserved.
//

import UIKit

public struct ColorPalette {
    //public static let lightGray =  UIColor(red:0.737, green: 0.769, blue: 0.792, alpha: 1.000)
    //public static let blue =  UIColor(red:0.353, green: 0.510, blue: 0.647, alpha: 1.000)
    //public static let gray =  UIColor(red:0.373, green: 0.373, blue: 0.376, alpha: 1.000)
    public static let panel =  UIColor(red: 0.212, green: 0.227, blue: 0.267, alpha: 1.000)
    public static let secondary =  UIColor(red: 0.141, green: 0.220, blue: 0.282, alpha: 1.000)
    public static let primary =  UIColor(red: 0.129, green: 0.133, blue: 0.145, alpha: 1.000)

    // MARK: - Basic Colors
    // Primary color
    public static let navy = UIColor(red: 0.10, green: 0.70, blue: 0.58, alpha: 1.0)
    // Default color
    public static let darkGray = UIColor(red: 0.76, green: 0.76, blue: 0.76, alpha: 1.0)
    // Success color
    public static let blue = UIColor(red: 0.11, green: 0.52, blue: 0.78, alpha: 1.0)
    // Info color
    public static let lazur = UIColor(red: 0.14, green: 0.78, blue: 0.78, alpha: 1.0)
    // Warning color
    public static let yellow = UIColor(red: 0.97, green: 0.67, blue: 0.35, alpha: 1.0)
    // Danger color
    public static let red = UIColor(red: 0.93, green: 0.33, blue: 0.40, alpha: 1.0)

    // MARK: - Various colors
    // Body text
    public static let text = UIColor(red: 0.40, green: 0.42, blue: 0.42, alpha: 1.0)
    // Background wrapper color
    public static let gray = UIColor(red: 0.95, green: 0.95, blue: 0.96, alpha: 1.0)
    // Default label, badget
    public static let lightGray = UIColor(red: 0.82, green: 0.85, blue: 0.87, alpha: 1.0)
    public static let labelBadges = UIColor(red: 0.37, green: 0.37, blue: 0.37, alpha: 1.0)
    public static let lightBlue = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)

    // MARK: - IBOX colors (default panel colors)
    // IBox border
    public static let iboxBorder = UIColor(red: 0.91, green: 0.92, blue: 0.93, alpha: 1.0)
    // IBox Background header / content
    public static let iboxBackgroundHeader = UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0)

    // MARK: - Navigation
    public static let navBackground = UIColor(red: 0.18, green: 0.25, blue: 0.31, alpha: 1.0)
    public static let navText = UIColor(red: 0.65, green: 0.69, blue: 0.76, alpha: 1.0)

    private init() {}
}
