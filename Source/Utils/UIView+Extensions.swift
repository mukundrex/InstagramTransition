//
//  UIView+Extensions.swift
//  InstagramTransition
//
//  Created by Kolos Foltanyi on 2023. 07. 22..
//

import UIKit

extension UIView {
    var frameInWindow: CGRect? {
        // First, try the standard conversion
        if let superview = superview {
            return superview.convert(frame, to: nil)
        }
        
        // Fallback: try to get the window directly and convert from self
        if let window = window {
            return convert(bounds, to: window)
        }
        
        // Last resort: try to find a superview up the chain
        var currentView: UIView? = self
        while let view = currentView {
            if let superview = view.superview, superview.window != nil {
                return superview.convert(frame, to: nil)
            }
            currentView = view.superview
        }
        
        return nil
    }

    static func animate(
        duration: TimeInterval,
        curve: CAMediaTimingFunction? = nil,
        options: UIView.AnimationOptions = [],
        animations: @escaping () -> Void,
        completion: (() -> Void)? = nil
    ) {
        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(curve)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: animations,
            completion: { _ in completion?() }
        )
        CATransaction.commit()
    }
}
