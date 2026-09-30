//
//  animations.swift
//  WebBLE
//
//  Created by David Park on 24/09/2026.
//

import UIKit

func applyCurrentAnimationPaths(
    _ layersAndKeyPathEnds: [(CALayer, [(String, Any)])],
    timingFunction: CAMediaTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
) {
    let duration = UIView.inheritedAnimationDuration
    guard duration > 0 else {
        NSLog("No inherited animation")
        return
    }
    NSLog("applying animations to properties duration \(duration)")
    for (layer, keypaths) in layersAndKeyPathEnds {
        for (keypath, toValue) in keypaths {
            let anim = CABasicAnimation(keyPath: keypath)
            anim.duration = duration
            anim.timingFunction = timingFunction
            anim.fromValue = layer.value(forKeyPath: keypath)
            anim.toValue = toValue
            layer.add(anim, forKey: keypath)
        }
    }
}

