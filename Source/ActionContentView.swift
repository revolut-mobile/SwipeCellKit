//
//  ActionContentView.swift
//  SwipeCellKit
//
//  Created by Ilia Sedov on 05.05.2022.
//

import UIKit

/// Describes the expandable action's resolved widths during fill expansion.
public struct SwipeActionExpansionContext {
    /// The action's resolved width before expansion begins.
    public let regularWidth: CGFloat

    /// The action's current width.
    public let currentWidth: CGFloat

    /// The largest width currently available to the action.
    public let maximumWidth: CGFloat

    /// The width added beyond the action's regular width.
    public var additionalWidth: CGFloat {
        currentWidth - regularWidth
    }

    init(regularWidth: CGFloat, currentWidth: CGFloat, maximumWidth: CGFloat) {
        self.regularWidth = regularWidth
        self.currentWidth = currentWidth
        self.maximumWidth = maximumWidth
    }
}

open class ActionContentView: UIView {
    public init(action: SwipeAction) {
        super.init(frame: .zero)
        setupView(with: action)
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Returns the content's preferred regular action width, capped by `maximum`.
    ///
    /// Return a value larger than the configured minimum to allow this content to
    /// influence action sizing. This value is also used independently for each
    /// action when `SwipeOptions.buttonWidthMode` is `.individual`.
    open func preferredWidth(maximum: CGFloat) -> CGFloat {
        0.0
    }

    /// Configures the content view for an action.
    ///
    /// This method is called from `init(action:)`. Subclasses should build their
    /// view hierarchy and apply the action's appearance here.
    open func setupView(with action: SwipeAction) {}

    /// Notifies the content view that the expandable action's width changed.
    ///
    /// Override this method to implement content-specific expansion, such as
    /// morphing a circle into a pill. The default implementation does nothing.
    ///
    /// - parameter context: The action's regular, current, and maximum widths.
    open func didChangeExpansion(_ context: SwipeActionExpansionContext) {}

    /// Whether the action content is currently highlighted.
    open var isHighlighted: Bool = false
}
