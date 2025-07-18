//
//  SharedTransitionAnimator.swift
//  DetailPushAnimator
//
//  Created by Kolos Foltanyi on 2023. 07. 22..
//

import UIKit

class SharedTransitionAnimator: NSObject {

    // MARK: Inner types

    enum Transition {
        case present
        case dismiss
    }

    // MARK: Public properties

    var transition: Transition = .present

    // MARK: Private properties

    private var config: SharedTransitionConfig = .default
}

// MARK: - UIViewControllerAnimatedTransitioning

extension SharedTransitionAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval { config.duration }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        prepareViewControllers(from: transitionContext, for: transition)

        switch transition {
        case .present:
            presentAnimation(context: transitionContext)
        case .dismiss:
            dismissAnimation(context: transitionContext)
        }
    }
}

// MARK: - Animations

extension SharedTransitionAnimator {
    private func presentAnimation(context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }

        let transform: CGAffineTransform = .transform(
            parent: toView.frame,
            soChild: toFrame,
            aspectFills: fromFrame
        )

        let maskFrame = fromFrame.aspectFit(to: toFrame)
        let mask = UIView(frame: maskFrame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
        }
        let overlay = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = 0
            $0.frame = fromView.frame
        }
        let placeholder = UIView().then {
            $0.backgroundColor = config.placeholderColor
            $0.frame = fromFrame
        }

        toView.mask = mask
        toView.transform = transform
        fromView.addSubview(placeholder)
        fromView.addSubview(overlay)

        UIView.animate(duration: config.duration, curve: config.curve) { [config] in
            toView.transform = .identity
            mask.frame = toView.frame
            mask.layer.cornerRadius = config.maskCornerRadius
            overlay.layer.opacity = config.overlayOpacity
        } completion: {
            toView.mask = nil
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            context.completeTransition(true)
        }
    }

    private func dismissAnimation(context: UIViewControllerContextTransitioning) {
        guard let (fromView, fromFrame, toView, toFrame) = setup(with: context) else {
            context.completeTransition(false)
            return
        }

        let transform: CGAffineTransform = .transform(
            parent: fromView.frame,
            soChild: fromFrame,
            aspectFills: toFrame
        )
        let mask = UIView(frame: fromView.frame).then {
            $0.layer.cornerCurve = .continuous
            $0.backgroundColor = .black
            $0.layer.cornerRadius = config.maskCornerRadius
        }
        let overlay = UIView().then {
            $0.backgroundColor = .black
            $0.layer.opacity = config.overlayOpacity
            $0.frame = toView.frame
        }
        let placeholder = UIView().then {
            $0.backgroundColor = config.placeholderColor
            $0.frame = toFrame
        }

        fromView.mask = mask
        toView.addSubview(placeholder)
        toView.addSubview(overlay)

        let maskFrame = toFrame.aspectFit(to: fromFrame)

        UIView.animate(duration: config.duration, curve: config.curve) {
            fromView.transform = transform
            mask.frame = maskFrame
            mask.layer.cornerRadius = 0
            overlay.layer.opacity = 0
        } completion: {
            overlay.removeFromSuperview()
            placeholder.removeFromSuperview()
            let isCancelled = context.transitionWasCancelled
            context.completeTransition(!isCancelled)
        }
    }
}

// MARK: Helpers

extension SharedTransitionAnimator {
    private func prepareViewControllers(from context: UIViewControllerContextTransitioning,
                                        for transition: Transition) {
        let fromVC = context.viewController(forKey: .from) as? SharedTransitioning
        let toVC = context.viewController(forKey: .to) as? SharedTransitioning
        if let customConfig = fromVC?.config {
            config = customConfig
        }
        fromVC?.prepare(for: transition)
        toVC?.prepare(for: transition)
    }

    private func setup(with context: UIViewControllerContextTransitioning) -> (UIView, CGRect, UIView, CGRect)? {
        guard let toView = context.view(forKey: .to),
              let fromView = context.view(forKey: .from) else {
            return nil
        }
        if transition == .present {
            context.containerView.addSubview(toView)
        } else {
            context.containerView.insertSubview(toView, belowSubview: fromView)
        }
        
        let toFrame = context.sharedFrame(forKey: .to)
        let fromFrame = context.sharedFrame(forKey: .from)
        
        guard let toFrame = toFrame, let fromFrame = fromFrame else {
            // Fallback to basic modal transition without shared element
            if transition == .present {
                context.containerView.addSubview(toView)
                toView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                UIView.animate(duration: config.duration) {
                    toView.transform = .identity
                } completion: {
                    context.completeTransition(true)
                }
            } else {
                UIView.animate(duration: config.duration) {
                    fromView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                    fromView.alpha = 0
                } completion: {
                    context.completeTransition(!context.transitionWasCancelled)
                }
            }
            return nil
        }
        return (fromView, fromFrame, toView, toFrame)
    }
}
