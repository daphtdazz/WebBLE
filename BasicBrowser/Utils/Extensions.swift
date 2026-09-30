//
//  Extensions.swift
//  WebBLE
//
//  Created by David Park on 24/09/2026.
//

import CoreGraphics

extension CGRect {
    func pointAtFraction(x xFraction: CGFloat, y yFraction: CGFloat) -> CGPoint {
        CGPoint(
            x: self.minX + self.width * xFraction,
            y: self.minY + self.height * yFraction
        )
    }
}
