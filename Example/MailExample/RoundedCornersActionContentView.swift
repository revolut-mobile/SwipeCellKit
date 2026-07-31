//
//  RoundedCornersActionContentView.swift
//  MailExample
//
//  Created by Ilia Sedov on 05.05.2022.
//

import UIKit
import SwipeCellKit

class RoundedCornersActionContentView: ActionContentView {
    private enum Layout {
        static let circleDiameter: CGFloat = 46
        static let horizontalInset: CGFloat = 2
        static let collapsedWidth = circleDiameter + horizontalInset * 2
    }

    private let bgView = UIView()
    private let iconContainerView = UIView()
    private let titleLabel = UILabel()
    private let titleContainerView = UIView()
    private let imageView = UIImageView()
    private var backgroundWidthConstraint: NSLayoutConstraint?
    private var action: SwipeAction?
    private var usesStretchableCircularBackground = false
    private var normalBackgroundColor: UIColor?
    private var normalTitleColor: UIColor?
    private var highlightedBackgroundColor: UIColor?
    private var highlightedTextColor: UIColor?

    override func setupView(with action: SwipeAction) {
        self.action = action
        usesStretchableCircularBackground = action.backgroundColor == .clear
        normalBackgroundColor = usesStretchableCircularBackground ? action.textColor : action.backgroundColor
        normalTitleColor = action.textColor ?? .white
        highlightedBackgroundColor = action.highlightedBackgroundColor ?? normalBackgroundColor?.getHighlightedColor()
        highlightedTextColor = action.highlightedTextColor ?? normalTitleColor?.getHighlightedColor()

        buildView()

        bgView.backgroundColor = normalBackgroundColor
        titleLabel.font = action.font ?? UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        titleLabel.textColor = normalTitleColor
        titleLabel.text = action.title
        imageView.image = usesStretchableCircularBackground
            ? action.image?.withRenderingMode(.alwaysTemplate)
            : action.image
        imageView.tintColor = .white

        iconContainerView.isHidden = usesStretchableCircularBackground && imageView.image == nil
        if usesStretchableCircularBackground {
            titleContainerView.isHidden = titleLabel.text == nil
        } else {
            titleLabel.isHidden = titleLabel.text == nil
        }
    }

    private func buildView() {
        bgView.layer.cornerRadius = usesStretchableCircularBackground ? Layout.circleDiameter / 2 : 12
        bgView.layer.cornerCurve = .continuous
        bgView.clipsToBounds = true
        layer.cornerRadius = bgView.layer.cornerRadius
        layer.cornerCurve = .continuous
        addSubview(bgView)
        bgView.translatesAutoresizingMaskIntoConstraints = false


        titleLabel.textAlignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        titleLabel.numberOfLines = 1
        titleLabel.setContentHuggingPriority(.required, for: .vertical)

        if usesStretchableCircularBackground {
            buildStretchableCircularLayout()
        } else {
            buildBackgroundColorLayout()
        }
    }

    private func buildStretchableCircularLayout() {
        iconContainerView.addSubview(bgView)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        bgView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleContainerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconContainerView, titleContainerView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        let backgroundWidthConstraint = bgView.widthAnchor.constraint(equalToConstant: Layout.circleDiameter)
        self.backgroundWidthConstraint = backgroundWidthConstraint

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),

            iconContainerView.heightAnchor.constraint(equalToConstant: Layout.circleDiameter),
            bgView.centerXAnchor.constraint(equalTo: iconContainerView.centerXAnchor),
            bgView.centerYAnchor.constraint(equalTo: iconContainerView.centerYAnchor),
            bgView.heightAnchor.constraint(equalToConstant: Layout.circleDiameter),
            backgroundWidthConstraint,
            imageView.centerXAnchor.constraint(equalTo: bgView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: bgView.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: titleContainerView.centerXAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: titleContainerView.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: titleContainerView.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: titleContainerView.bottomAnchor)
        ])
    }

    private func buildBackgroundColorLayout() {
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.distribution = .equalCentering
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.horizontalInset),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.horizontalInset),
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor),

            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    override func preferredWidth(maximum: CGFloat) -> CGFloat {
        if usesStretchableCircularBackground {
            let width = maximum > 0 ? maximum : CGFloat.greatestFiniteMagnitude
            let titleWidth = titleBoundingRect(
                with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
            ).width + 8
            return min(width, max(Layout.collapsedWidth, titleWidth))
        }

        let width = maximum > 0 ? maximum : CGFloat.greatestFiniteMagnitude
        let textWidth = titleBoundingRect(with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)).width
        let imageWidth = imageView.image?.size.width ?? 0

        let leftInset: CGFloat = 4
        let rightInset: CGFloat = 4

        return min(width, max(textWidth, imageWidth) + leftInset + rightInset)
    }

    override func didChangeExpansion(_ context: SwipeActionExpansionContext) {
        guard usesStretchableCircularBackground else { return }

        let additionalWidth = max(0, context.additionalWidth)
        let regularBackgroundWidth = max(
            Layout.circleDiameter,
            context.regularWidth - Layout.horizontalInset * 2
        )
        let collapsedGap = regularBackgroundWidth - Layout.circleDiameter
        let catchUpProgress = collapsedGap > 0
            ? min(additionalWidth / collapsedGap, 1)
            : 1
        let maximumBackgroundWidth = max(
            Layout.circleDiameter,
            context.currentWidth - Layout.horizontalInset * 2
        )

        backgroundWidthConstraint?.constant = min(
            maximumBackgroundWidth,
            Layout.circleDiameter + additionalWidth + collapsedGap * catchUpProgress
        )
        setNeedsLayout()
    }

    private func titleBoundingRect(with size: CGSize) -> CGRect {
        guard let title = titleLabel.text else { return .zero }

        return title.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin],
            attributes: [NSAttributedString.Key.font: titleLabel.font as Any],
            context: nil
        ).integral
    }

    override var isHighlighted: Bool {
        didSet {
            guard action != nil else { return }

            if isHighlighted {
                bgView.backgroundColor = highlightedBackgroundColor
                titleLabel.textColor = highlightedTextColor
            } else {
                bgView.backgroundColor = normalBackgroundColor
                titleLabel.textColor = normalTitleColor
            }
        }
    }
}
