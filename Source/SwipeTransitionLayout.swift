//
//  SwipeTransitionLayout.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

// MARK: - Layout Protocol

protocol SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext)
    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext)
    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat]
}

// MARK: - Layout Context 

struct ActionsViewLayoutContext {
    let orientation: SwipeActionsOrientation
    let contentSize: CGSize
    let visibleWidth: CGFloat
    let buttonWidths: [CGFloat]

    init(
        buttonWidths: [CGFloat],
        orientation: SwipeActionsOrientation,
        contentSize: CGSize = .zero,
        visibleWidth: CGFloat = 0
    ) {
        self.buttonWidths = buttonWidths
        self.orientation = orientation
        self.contentSize = contentSize
        self.visibleWidth = visibleWidth
    }

    func offset(before index: Int) -> CGFloat {
        guard index > 0 else { return 0 }
        return buttonWidths.prefix(index).reduce(0, +)
    }

    static func newContext(for actionsView: SwipeActionsView) -> ActionsViewLayoutContext {
        return ActionsViewLayoutContext(
            buttonWidths: actionsView.buttonWidths,
            orientation: actionsView.orientation,
            contentSize: actionsView.contentSize,
            visibleWidth: actionsView.visibleWidth
        )
    }
}

// MARK: - Supported Layout Implementations 

class BorderTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
    }
    
    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        guard context.totalButtonWidth > 0 else {
            return
        }

        let diff = context.visibleWidth - context.contentSize.width
        let revealScale = context.contentSize.width / context.totalButtonWidth
        view.frame.origin.x = (context.offset(before: index) * revealScale + diff) * context.orientation.scale
    }
    
    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        guard context.totalButtonWidth > 0 else {
            return context.buttonWidths.map { _ in 0 }
        }

        let diff = context.visibleWidth - context.contentSize.width
        let revealScale = context.contentSize.width / context.totalButtonWidth

        return context.buttonWidths.map {
            max(0, $0 * revealScale + diff)
        }
    }
}

class DragTransitionLayout: SwipeTransitionLayout {
    func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
        view.bounds.origin.x = (context.contentSize.width - context.visibleWidth) * context.orientation.scale
    }
    
    func layout(view: UIView, atIndex index: Int, with context: ActionsViewLayoutContext) {
        view.frame.origin.x = context.offset(before: index) * context.orientation.scale
    }
    
    func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        var remainingWidth = context.visibleWidth

        return context.buttonWidths.map { buttonWidth in
            let visibleWidth = max(0, min(buttonWidth, remainingWidth))
            remainingWidth -= buttonWidth
            return visibleWidth
        }
    }
}

class RevealTransitionLayout: DragTransitionLayout {
    override func container(view: UIView, didChangeVisibleWidthWithContext context: ActionsViewLayoutContext) {
        view.bounds.origin.x = (context.totalButtonWidth - context.visibleWidth) * context.orientation.scale
    }
    
    override func visibleWidthsForViews(with context: ActionsViewLayoutContext) -> [CGFloat] {
        var remainingWidth = context.visibleWidth
        var visibleWidths = context.buttonWidths.map { _ in CGFloat(0) }

        for index in context.buttonWidths.indices.reversed() {
            let buttonWidth = context.buttonWidths[index]
            visibleWidths[index] = max(0, min(buttonWidth, remainingWidth))
            remainingWidth -= buttonWidth
        }

        return visibleWidths
    }
}

private extension ActionsViewLayoutContext {
    var totalButtonWidth: CGFloat {
        buttonWidths.reduce(0, +)
    }
}
