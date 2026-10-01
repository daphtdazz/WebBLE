//
//  WellIconContainerView.swift
//  WebBLE
//
//  Created by David Park on 28/09/2026.
//

import UIKit

@IBDesignable
class WellIconContainerView: UIView {

    private lazy var backgroundLayer: CAShapeLayer = {
        let l = CAShapeLayer()
        l.fillColor = UIColor.systemGray5.cgColor
        layer.insertSublayer(l, at: 0)
        return l
    }()

    override func layoutSubviews() {
        super.layoutSubviews()

        let cornerRadius = min(bounds.width, bounds.height) * 0.2
        backgroundLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).cgPath
    }
}
