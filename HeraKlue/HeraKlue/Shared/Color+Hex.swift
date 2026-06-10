//
//  Color+Hex.swift
//  HeraKlue
//
//  SHARED helper. Lets us write colors straight from Figma hex values, e.g.
//  `Color(hex: 0x4A5565)` or `Color(hex: 0x030213, opacity: 0.5)`. Handy when
//  translating designs into SwiftUI.
//

import SwiftUI

extension Color {
    /// Creates a color from a hex value such as `0x4A5565`.
    init(hex: UInt32, opacity: Double = 1) {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue  = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
