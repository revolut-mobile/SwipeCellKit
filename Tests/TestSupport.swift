//
//  TestSupport.swift
//  SwipeCellKitTests
//

import UIKit
@testable import SwipeCellKit

final class TestActionContentView: ActionContentView {
    let width: CGFloat
    var expansionContexts: [SwipeActionExpansionContext] = []

    init(action: SwipeAction, width: CGFloat) {
        self.width = width
        super.init(action: action)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func preferredWidth(maximum: CGFloat) -> CGFloat {
        width
    }

    override func didChangeExpansion(_ context: SwipeActionExpansionContext) {
        expansionContexts.append(context)
    }
}

final class TransitionSpy: SwipeActionTransitioning {
    var preparationContexts: [SwipeActionTransitioningContext] = []
    var transitionContexts: [SwipeActionTransitioningContext] = []

    func prepareTransition(with context: SwipeActionTransitioningContext) {
        preparationContexts.append(context)
    }

    func didTransition(with context: SwipeActionTransitioningContext) {
        transitionContexts.append(context)
    }
}

final class ExpansionSpy: SwipeExpanding {
    var changes: [Bool] = []

    func animationTimingParameters(
        buttons: [UIView],
        expanding: Bool
    ) -> SwipeExpansionAnimationTimingParameters {
        SwipeExpansionAnimationTimingParameters(duration: 0)
    }

    func actionButton(
        _ button: UIView,
        didChange expanding: Bool,
        otherActionButtons: [UIView]
    ) {
        changes.append(expanding)
        otherActionButtons.forEach {
            $0.alpha = expanding ? 0.5 : 1
            $0.transform = expanding
                ? CGAffineTransform(scaleX: 0.8, y: 0.8)
                : .identity
        }
    }
}

final class SwipeableMock: UIView, Swipeable {
    var state: SwipeState = .center
    var actionsView: SwipeActionsView?
    var scrollView: UIScrollView?
    var indexPath: IndexPath?
    let testPanGestureRecognizer = UIPanGestureRecognizer()

    var panGestureRecognizer: UIGestureRecognizer {
        testPanGestureRecognizer
    }
}

struct ActionsViewFixture {
    let containerView: UIView
    let view: SwipeActionsView
    let actions: [SwipeAction]
    let contentViews: [String: TestActionContentView]
}

func makeActionsView(
    widths: [CGFloat],
    options: SwipeOptions = SwipeOptions(),
    orientation: SwipeActionsOrientation = .right,
    transitionDelegate: SwipeActionTransitioning? = nil,
    clearExpandableAction: Bool = false,
    size: CGSize = CGSize(width: 320, height: 80)
) -> ActionsViewFixture {
    let actions = widths.enumerated().map { index, _ -> SwipeAction in
        let action = SwipeAction(style: .default, title: nil, handler: nil)
        action.identifier = String(index)
        action.transitionDelegate = transitionDelegate
        return action
    }

    if clearExpandableAction {
        actions.first?.backgroundColor = .clear
    }

    let widthsByIdentifier = Dictionary(
        uniqueKeysWithValues: zip(actions, widths).map { action, width in
            (action.identifier!, width)
        }
    )
    var contentViews: [String: TestActionContentView] = [:]
    let containerView = UIView()

    let view = SwipeActionsView(
        contentEdgeInsets: .zero,
        maxSize: size,
        safeAreaInsetView: containerView,
        options: options,
        orientation: orientation,
        actions: actions,
        actionContentViewBuilder: { action in
            let identifier = action.identifier!
            let contentView = TestActionContentView(
                action: action,
                width: widthsByIdentifier[identifier]!
            )
            contentViews[identifier] = contentView
            return contentView
        }
    )

    containerView.addSubview(view)
    NSLayoutConstraint.activate([
        view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        view.topAnchor.constraint(equalTo: containerView.topAnchor),
        view.widthAnchor.constraint(equalToConstant: size.width),
        view.heightAnchor.constraint(equalToConstant: size.height)
    ])
    view.addButtons()

    return ActionsViewFixture(
        containerView: containerView,
        view: view,
        actions: actions,
        contentViews: contentViews
    )
}
