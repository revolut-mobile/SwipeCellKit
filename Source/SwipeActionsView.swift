//
//  SwipeActionsView.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

protocol SwipeActionsViewDelegate: AnyObject {
    func swipeActionsView(_ swipeActionsView: SwipeActionsView, didSelect action: SwipeAction)
}

class SwipeActionsView: UIView {
    weak var delegate: SwipeActionsViewDelegate?

    let transitionLayout: SwipeTransitionLayout
    var layoutContext: ActionsViewLayoutContext

    var feedbackGenerator: SwipeFeedback

    var expansionAnimator: SwipeAnimator?

    var expansionDelegate: SwipeExpanding? {
        return options.expansionDelegate ?? (expandableAction?.hasBackgroundColor == false ? ScaleAndAlphaExpansion.default : nil)
    }

    weak var safeAreaInsetView: UIView?
    let orientation: SwipeActionsOrientation
    let actions: [SwipeAction]
    let options: SwipeOptions
    let maxSize: CGSize
    let contentEdgeInsets: UIEdgeInsets

    var buttons: [SwipeActionButton] = []
    var buttonWidths: [CGFloat] = []

    private var hasPreparedTransitions = false
    private var wasInteractive = false
    private var visibilityUpdateSequence = 0

    var expandableButtonWidth: CGFloat {
        buttonWidths.last ?? 0
    }

    var regularActionsWidth: CGFloat {
        buttonWidths.reduce(0, +)
    }

    var preferredWidth: CGFloat {
        return regularActionsWidth + safeAreaMargin
    }

    var maximumImageHeight: CGFloat {
        return actions.reduce(0, { initial, next in max(initial, next.image?.size.height ?? 0) })
    }

    var safeAreaMargin: CGFloat {
        guard #available(iOS 11, *) else { return 0 }
        guard let scrollView = self.safeAreaInsetView else { return 0 }
        return orientation == .left ? scrollView.safeAreaInsets.left : scrollView.safeAreaInsets.right
    }

    private(set) var visibleWidth: CGFloat = 0
    private(set) var revealedWidth: CGFloat = 0

    func updateVisibleWidth(_ width: CGFloat, isInteractive: Bool = false) {
        visibilityUpdateSequence += 1

        let preLayoutVisibleWidths = transitionLayout.visibleWidthsForViews(with: layoutContext)
        let interactionDidChange = wasInteractive != isInteractive

        wasInteractive = isInteractive
        revealedWidth = max(0, width)
        visibleWidth = max(0, revealedWidth - safeAreaMargin) // If necessary, adjust for safe areas.
        layoutContext = transitionLayoutContext()
        transitionLayout.container(view: self, didChangeVisibleWidthWithContext: layoutContext)

        setNeedsLayout()
        layoutIfNeeded()

        notifyVisibleWidthChanged(
            oldWidths: preLayoutVisibleWidths,
            newWidths: transitionLayout.visibleWidthsForViews(with: layoutContext),
            isInteractive: isInteractive,
            interactionDidChange: interactionDidChange,
            updateSequence: visibilityUpdateSequence
        )
    }

    private func transitionLayoutContext() -> ActionsViewLayoutContext {
        guard options.expansionStyle?.expandedActionLayout == .fillAvailableSpace,
              visibleWidth > regularActionsWidth else {
            return ActionsViewLayoutContext.newContext(for: self)
        }

        return ActionsViewLayoutContext(
            buttonWidths: buttonWidths,
            orientation: orientation,
            contentSize: CGSize(width: regularActionsWidth, height: contentSize.height),
            visibleWidth: regularActionsWidth
        )
    }

    var contentSize: CGSize {
        if options.expansionStyle?.elasticOverscroll != true || visibleWidth < preferredWidth {
            return CGSize(width: visibleWidth, height: bounds.height)
        } else {
            let scrollRatio = max(0, visibleWidth - preferredWidth)
            return CGSize(width: preferredWidth + (scrollRatio * 0.25), height: bounds.height)
        }
    }

    override var intrinsicContentSize: CGSize {
        contentSize
    }

    private(set) var expanded: Bool = false
    private let actionContentViewBuilder: (SwipeAction) -> ActionContentView

    var expandableAction: SwipeAction? {
        return options.expansionStyle != nil ? actions.last : nil
    }

    init(contentEdgeInsets: UIEdgeInsets,
         maxSize: CGSize,
         safeAreaInsetView: UIView,
         options: SwipeOptions,
         orientation: SwipeActionsOrientation,
         actions: [SwipeAction],
         actionContentViewBuilder: @escaping (SwipeAction) -> ActionContentView
    ) {
        self.safeAreaInsetView = safeAreaInsetView
        self.options = options
        self.orientation = orientation
        self.actions = actions.reversed()
        self.actionContentViewBuilder = actionContentViewBuilder
        self.maxSize = maxSize
        self.contentEdgeInsets = contentEdgeInsets

        switch options.transitionStyle {
        case .border:
            transitionLayout = BorderTransitionLayout()
        case .reveal:
            transitionLayout = RevealTransitionLayout()
        default:
            transitionLayout = DragTransitionLayout()
        }

        self.layoutContext = ActionsViewLayoutContext(
            buttonWidths: Array(repeating: 0, count: actions.count),
            orientation: orientation
        )

        feedbackGenerator = SwipeFeedback(style: .light)
        feedbackGenerator.prepare()

        super.init(frame: .zero)

        clipsToBounds = true
        translatesAutoresizingMaskIntoConstraints = false


    #if canImport(Combine)
        if let backgroundColor = options.backgroundColor {
            self.backgroundColor = backgroundColor
        }
        else if #available(iOS 13.0, *) {
            backgroundColor = UIColor.systemGray5
        } else {
            backgroundColor = #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        }
    #else
        if let backgroundColor = options.backgroundColor {
            self.backgroundColor = backgroundColor
        }
        else {
            backgroundColor = #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
        }
    #endif
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addButtons() {
        buttons = addButtons(
            for: actions,
            withMaximum: maxSize,
            contentEdgeInsets: contentEdgeInsets
        )
    }

    private func addButtons(for actions: [SwipeAction], withMaximum size: CGSize, contentEdgeInsets: UIEdgeInsets) -> [SwipeActionButton] {
        let maximum = options.maximumButtonWidth ?? (size.width - 30) / CGFloat(actions.count)
        let minimum = options.minimumButtonWidth ?? min(maximum, 74)

        let buttons: [SwipeActionButton] = actions.map({ action in
            let actionButton = SwipeActionButton(
                action: action,
                contentViewBuilder: actionContentViewBuilder
            )
            actionButton.addTarget(self, action: #selector(actionTapped(button:)), for: .touchUpInside)
            actionButton.autoresizingMask = [
                .flexibleHeight,
                orientation == .right ? .flexibleRightMargin : .flexibleLeftMargin
            ]
            return actionButton
        })

        switch options.buttonWidthMode {
        case .equal:
            let sharedWidth = buttons.reduce(minimum) { initial, next in
                max(initial, next.preferredWidth(maximum: maximum))
            }

            buttonWidths = buttons.map { _ in sharedWidth }
        case .individual:
            buttonWidths = buttons.map { button in
                let preferredWidth = max(0, button.preferredWidth(maximum: maximum))
                let width = max(max(0, minimum), preferredWidth)
                return maximum > 0 ? min(maximum, width) : width
            }
        }

        buttons.enumerated().forEach { (index, button) in
            let action = actions[index]
            let wrapperView = SwipeActionButtonWrapperView(
                frame: .zero,
                action: action,
                orientation: orientation,
                contentWidth: buttonWidths[index],
                options: options
            )
            wrapperView.layer.cornerRadius = button.layer.cornerRadius
            wrapperView.layer.cornerCurve = button.layer.cornerCurve
            wrapperView.translatesAutoresizingMaskIntoConstraints = false
            wrapperView.addSubview(button)

            if let effect = action.backgroundEffect {
                let effectView = UIVisualEffectView(effect: effect)
                effectView.frame = wrapperView.frame
                effectView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
                effectView.contentView.addSubview(wrapperView)
                addSubview(effectView)
            } else {
                addSubview(wrapperView)
            }

            button.frame = wrapperView.contentRect
            button.shouldHighlight = action.hasBackgroundColor

            wrapperView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
            wrapperView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true

            let topConstraint = wrapperView.topAnchor.constraint(
                equalTo: topAnchor,
                constant: contentEdgeInsets.top
            )
            topConstraint.priority = contentEdgeInsets.top == 0 ? .required : .defaultHigh
            topConstraint.isActive = true

            let bottomConstraint = wrapperView.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -1 * contentEdgeInsets.bottom
            )
            bottomConstraint.priority = contentEdgeInsets.bottom == 0 ? .required : .defaultHigh
            bottomConstraint.isActive = true

            if contentEdgeInsets != .zero {
                let heightConstraint = wrapperView.heightAnchor.constraint(greaterThanOrEqualToConstant: button.intrinsicContentSize.height)
                heightConstraint.priority = .required
                heightConstraint.isActive = true
            }
        }
        return buttons
    }

    @objc func actionTapped(button: SwipeActionButton) {
        guard let index = buttons.firstIndex(of: button) else { return }

        delegate?.swipeActionsView(self, didSelect: actions[index])
    }

    func buttonEdgeInsets(fromOptions options: SwipeOptions) -> UIEdgeInsets {
        let padding = options.buttonPadding ?? 8
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }

    func setExpanded(expanded: Bool, feedback: Bool = false) {
        guard self.expanded != expanded else { return }

        self.expanded = expanded

        if feedback {
            feedbackGenerator.impactOccurred()
            feedbackGenerator.prepare()
        }

        let timingParameters = expansionDelegate?.animationTimingParameters(buttons: buttons.reversed(), expanding: expanded)

        if expansionAnimator?.isRunning == true {
            expansionAnimator?.stopAnimation(true)
        }

        if #available(iOS 10, *) {
            expansionAnimator = UIViewPropertyAnimator(duration: timingParameters?.duration ?? 0.6, dampingRatio: 1.0)
        } else {
            expansionAnimator = UIViewSpringAnimator(duration: timingParameters?.duration ?? 0.6,
                                                     damping: 1.0,
                                                     initialVelocity: 1.0)
        }

        expansionAnimator?.addAnimations {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }

        expansionAnimator?.startAnimation(afterDelay: timingParameters?.delay ?? 0)

        notifyExpansion(expanded: expanded)
    }

    func notifyVisibleWidthChanged(
        oldWidths: [CGFloat],
        newWidths: [CGFloat],
        isInteractive: Bool,
        interactionDidChange: Bool,
        updateSequence: Int
    ) {
        let notify = { [weak self] in
            guard let self = self,
                  self.visibilityUpdateSequence == updateSequence,
                  self.buttons.count == oldWidths.count,
                  oldWidths.count == newWidths.count else {
                return
            }

            oldWidths.enumerated().forEach { index, oldWidth in
                let newWidth = newWidths[index]
                if oldWidth != newWidth || interactionDidChange {
                    let buttonWidth = self.buttonWidths[index]
                    let context = SwipeActionTransitioningContext(
                        actionIdentifier: self.actions[index].identifier,
                        button: self.buttons[index],
                        newPercentVisible: self.percentVisible(newWidth, buttonWidth: buttonWidth),
                        oldPercentVisible: self.percentVisible(oldWidth, buttonWidth: buttonWidth),
                        isInteractive: isInteractive,
                        wrapperView: self.subviews[index]
                    )

                    self.actions[index].transitionDelegate?.didTransition(with: context)
                }
            }
        }

        if isInteractive {
            notify()
        } else {
            DispatchQueue.main.async(execute: notify)
        }
    }

    private func percentVisible(_ visibleWidth: CGFloat, buttonWidth: CGFloat) -> CGFloat {
        guard buttonWidth > 0 else { return 0 }
        return min(max(visibleWidth / buttonWidth, 0), 1)
    }

    func notifyExpansion(expanded: Bool) {
        guard let expandedButton = buttons.last else { return }

        expansionDelegate?.actionButton(
            expandedButton,
            didChange: expanded,
            otherActionButtons: buttons.dropLast().reversed()
        )
    }

    func createDeletionMask() -> UIView {
        let mask = UIView(frame: CGRect(x: min(0, frame.minX), y: 0, width: bounds.width * 2, height: bounds.height))
        mask.backgroundColor = UIColor.white
        return mask
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        for subview in subviews.enumerated() {
            transitionLayout.layout(view: subview.element, atIndex: subview.offset, with: layoutContext)
        }

        prepareTransitionsIfNeeded()
        layoutExpansion()
    }

    private func layoutExpansion() {
        guard let expansionStyle = options.expansionStyle else { return }

        switch expansionStyle.expandedActionLayout {
        case .edgeAligned:
            if expanded {
                subviews.last?.frame.origin.x = bounds.origin.x
            }
        case .fillAvailableSpace:
            layoutFillAvailableSpaceAction()
        }

    }

    private func layoutFillAvailableSpaceAction() {
        guard let expandedButton = buttons.last,
              let wrapperView = expandedButton.superview as? SwipeActionButtonWrapperView else {
            return
        }

        let regularButtonWidth = expandableButtonWidth
        let precedingActionsWidth = buttonWidths.dropLast().reduce(0, +)
        let maximumWidth = max(regularButtonWidth, bounds.width - precedingActionsWidth)
        let expandedWidth = min(
            max(regularButtonWidth, visibleWidth - precedingActionsWidth),
            maximumWidth
        )
        let contentRect = wrapperView.contentRect(forWidth: expandedWidth)

        // The action button may have a spring scale transform applied. A view's
        // frame is undefined while its transform is non-identity, so resizing it
        // through frame can corrupt its bounds and center during a fast swipe.
        expandedButton.bounds = CGRect(origin: .zero, size: contentRect.size)
        expandedButton.center = CGPoint(x: contentRect.midX, y: contentRect.midY)
        expandedButton.layoutIfNeeded()
        expandedButton.updateExpansion(
            SwipeActionExpansionContext(
                regularWidth: regularButtonWidth,
                currentWidth: expandedWidth,
                maximumWidth: maximumWidth
            )
        )
        expandedButton.layoutIfNeeded()
    }

    private func prepareTransitionsIfNeeded() {
        guard !hasPreparedTransitions,
              bounds.width > 0,
              bounds.height > 0,
              buttons.count == actions.count,
              subviews.count == actions.count else {
            return
        }

        hasPreparedTransitions = true

        actions.indices.forEach { index in
            actions[index].transitionDelegate?.prepareTransition(
                with: SwipeActionTransitioningContext(
                    actionIdentifier: actions[index].identifier,
                    button: buttons[index],
                    newPercentVisible: 0,
                    oldPercentVisible: 0,
                    wrapperView: subviews[index]
                )
            )
        }
    }
}

class SwipeActionButtonWrapperView: UIView {
    private let orientation: SwipeActionsOrientation
    private let contentWidth: CGFloat
    var actionBackgroundColor: UIColor?
    private let cleanBackgroundToClear: Bool

    var contentRect: CGRect {
        contentRect(forWidth: contentWidth)
    }

    init(
        frame: CGRect,
        action: SwipeAction,
        orientation: SwipeActionsOrientation,
        contentWidth: CGFloat,
        options: SwipeOptions
    ) {
        self.orientation = orientation
        self.contentWidth = contentWidth
        cleanBackgroundToClear = options.backgroundColor == .clear
        super.init(frame: frame)

        configureBackgroundColor(with: action)
        if cleanBackgroundToClear {
            backgroundColor = .clear
        } else {
            backgroundColor = actionBackgroundColor
        }
    }

    func contentRect(forWidth width: CGFloat) -> CGRect {
        let width = max(width, 0)
        let originX: CGFloat = switch orientation {
        case .left:
            bounds.width - width
        case .right:
            0
        }

        return CGRect(x: originX, y: 0, width: width, height: bounds.height)
    }

    func cleanBackground() {
        guard cleanBackgroundToClear else { return }
        self.backgroundColor = .clear
    }

    func resetBackgroundColor(with action: SwipeAction) {
        guard action.hasBackgroundColor else {
            isOpaque = false
            return
        }
        self.backgroundColor = self.actionBackgroundColor
    }

    private func configureBackgroundColor(with action: SwipeAction) {
        if let backgroundColor = action.backgroundColor {
            actionBackgroundColor = backgroundColor
        } else {
            switch action.style {
            case .destructive:
            #if canImport(Combine)
                if #available(iOS 13.0, *) {
                    actionBackgroundColor = UIColor.systemRed
                } else {
                    actionBackgroundColor = #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
                }
            #else
                actionBackgroundColor = #colorLiteral(red: 1, green: 0.2352941176, blue: 0.1882352941, alpha: 1)
            #endif
            default:
            #if canImport(Combine)
                if #available(iOS 13.0, *) {
                    actionBackgroundColor = UIColor.systemGray3
                } else {
                    actionBackgroundColor = #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
                }
            #else
                actionBackgroundColor = #colorLiteral(red: 0.7803494334, green: 0.7761332393, blue: 0.7967314124, alpha: 1)
            #endif
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
