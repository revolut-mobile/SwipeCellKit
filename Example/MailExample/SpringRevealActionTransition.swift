//
//  SpringRevealActionTransition.swift
//  MailExample
//

import QuartzCore
import SwipeCellKit
import UIKit

/// A reveal transition whose opacity follows swipe progress while its scale
/// continuously follows that progress using a spring.
final class SpringRevealActionTransition: NSObject, SwipeActionTransitioning {
    struct Configuration {
        var revealStart: CGFloat = 0.2
        var tension: CGFloat = 573
        var friction: CGFloat = 26
        var mass: CGFloat = 1
        var hiddenScale: CGFloat = 0.001
        var maximumScale: CGFloat = 1.06
        var maximumVelocity: CGFloat = 8
    }

    private let configuration: Configuration
    private let isReduceMotionEnabled: () -> Bool

    private weak var button: UIView?
    private var displayLink: CADisplayLink?
    private var previousTimestamp: CFTimeInterval?
    private var spring: ScalarSpring
    private var isInteractive = false

    init(
        configuration: Configuration = Configuration(),
        isReduceMotionEnabled: @escaping () -> Bool = { UIAccessibility.isReduceMotionEnabled }
    ) {
        var configuration = configuration
        configuration.revealStart = min(max(configuration.revealStart, 0), 0.999)
        configuration.tension = max(configuration.tension, 0.001)
        configuration.friction = max(configuration.friction, 0)
        configuration.mass = max(configuration.mass, 0.001)
        configuration.hiddenScale = min(max(configuration.hiddenScale, 0.0001), 1)
        configuration.maximumScale = max(configuration.maximumScale, 1)
        configuration.maximumVelocity = max(configuration.maximumVelocity, 0.001)

        self.configuration = configuration
        self.isReduceMotionEnabled = isReduceMotionEnabled
        self.spring = ScalarSpring(
            value: configuration.hiddenScale,
            mass: configuration.mass,
            stiffness: configuration.tension,
            maximumVelocity: configuration.maximumVelocity,
            valueRange: configuration.hiddenScale...configuration.maximumScale
        )
        super.init()
    }

    deinit {
        stopSpring()
    }

    func prepareTransition(with context: SwipeActionTransitioningContext) {
        stopSpring()
        button = context.button
        isInteractive = false
        spring.reset(to: configuration.hiddenScale)

        context.button.alpha = 0
        context.button.transform = isReduceMotionEnabled()
            ? .identity
            : transform(for: spring.value)
    }

    func didTransition(with context: SwipeActionTransitioningContext) {
        button = context.button

        let progress = normalizedProgress(for: context.newPercentVisible)

        guard !isReduceMotionEnabled() else {
            stopSpring()
            context.button.alpha = progress
            context.button.transform = .identity
            return
        }

        spring.target = scale(for: progress)
        isInteractive = context.isInteractive

        if !isInteractive {
            spring.velocity = 0
        }

        startSpringIfNeeded()
    }

    private func normalizedProgress(for percentVisible: CGFloat) -> CGFloat {
        let progress = (percentVisible - configuration.revealStart)
            / (1 - configuration.revealStart)
        return min(max(progress, 0), 1)
    }

    private func scale(for progress: CGFloat) -> CGFloat {
        configuration.hiddenScale
            + (1 - configuration.hiddenScale) * progress
    }

    private func progress(for scale: CGFloat) -> CGFloat {
        let progress = (scale - configuration.hiddenScale)
            / (1 - configuration.hiddenScale)
        return min(max(progress, 0), 1)
    }

    private func transform(for scale: CGFloat) -> CGAffineTransform {
        CGAffineTransform(scaleX: scale, y: scale)
    }

    private func startSpringIfNeeded() {
        guard displayLink == nil, !spring.isAtRest else { return }

        previousTimestamp = nil
        let displayLink = CADisplayLink(target: self, selector: #selector(updateSpring(_:)))
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }

    private func stopSpring() {
        displayLink?.invalidate()
        displayLink = nil
        previousTimestamp = nil
    }

    @objc private func updateSpring(_ displayLink: CADisplayLink) {
        guard let button = button else {
            stopSpring()
            return
        }

        let elapsed = previousTimestamp.map {
            CGFloat(displayLink.timestamp - $0)
        } ?? CGFloat(displayLink.duration)
        previousTimestamp = displayLink.timestamp

        let damping = isInteractive
            ? configuration.friction
            : spring.criticalDamping
        spring.advance(by: elapsed, damping: damping)

        if spring.isAtRest {
            spring.finish()
            stopSpring()
        }

        button.transform = transform(for: spring.value)
        button.alpha = progress(for: spring.value)
    }
}
