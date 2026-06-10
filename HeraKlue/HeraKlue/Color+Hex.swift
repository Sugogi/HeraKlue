//
//  Color+Hex.swift
//  HeraKlue
//
//  Lets us write colors straight from Figma hex values, e.g.
//  Color(hex: 0x4A5565) or Color(hex: 0x030213, opacity: 0.5).
//

import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue  = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
