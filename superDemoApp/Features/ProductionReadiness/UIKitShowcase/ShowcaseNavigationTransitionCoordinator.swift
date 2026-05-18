//
//  ShowcaseNavigationTransitionCoordinator.swift
//  superDemoApp
//

#if os(iOS)
import UIKit

final class ShowcaseNavigationTransitionCoordinator: NSObject, UINavigationControllerDelegate {
    func navigationController(
        _: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from _: UIViewController,
        to _: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        ShowcasePushPopAnimator(operation: operation)
    }
}

private final class ShowcasePushPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let operation: UINavigationController.Operation

    init(operation: UINavigationController.Operation) {
        self.operation = operation
    }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.28
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to)
        else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView
        let width = container.bounds.width
        let direction: CGFloat = self.operation == .pop ? -1 : 1
        toView.transform = CGAffineTransform(translationX: width * direction, y: 0)
        container.addSubview(toView)

        UIView.animate(
            withDuration: self.transitionDuration(using: transitionContext),
            delay: 0,
            usingSpringWithDamping: 0.92,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut]
        ) {
            fromView.transform = CGAffineTransform(translationX: -width * direction * 0.35, y: 0)
            toView.transform = .identity
        } completion: { finished in
            fromView.transform = .identity
            transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
        }
    }
}
#endif
