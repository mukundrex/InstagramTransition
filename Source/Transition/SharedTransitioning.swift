//
//  SharedTransitioning.swift
//  InstagramTransition
//
//  Created by Kolos Foltanyi on 2023. 07. 23..
//

import UIKit

protocol SharedTransitioning {
    var sharedFrame: CGRect { get }
    var config: SharedTransitionConfig? { get }
    func prepare(for transition: SharedTransitionAnimator.Transition)
}

extension SharedTransitioning {
    func prepare(for transition: SharedTransitionAnimator.Transition) {}
    var config: SharedTransitionConfig? { nil }
}

extension UIViewControllerContextTransitioning {
    func sharedFrame(forKey key: UITransitionContextViewControllerKey) -> CGRect? {
        let viewController = viewController(forKey: key)
        viewController?.view.layoutIfNeeded()
        
        // First, try the view controller directly
        var sharedTransitioningVC = viewController as? SharedTransitioning
        
        // If not found and it's a navigation controller, look at the top view controller
        if sharedTransitioningVC == nil, let navController = viewController as? UINavigationController {
            sharedTransitioningVC = navController.topViewController as? SharedTransitioning
        }
        
        // If still not found and it's a navigation controller, look at the visible view controller
        if sharedTransitioningVC == nil, let navController = viewController as? UINavigationController {
            sharedTransitioningVC = navController.visibleViewController as? SharedTransitioning
        }
        
        return sharedTransitioningVC?.sharedFrame
    }
}
