//
//  ScalarSpring.swift
//  MailExample
//

import Foundation

struct ScalarSpring {
    private enum Constants {
        static let integrationStep: CGFloat = 1.0 / 240.0
        static let maximumElapsedTime: CGFloat = 1.0 / 30.0
        static let valueTolerance: CGFloat = 0.0005
        static let velocityTolerance: CGFloat = 0.005
    }

    let mass: CGFloat
    let stiffness: CGFloat
    let maximumVelocity: CGFloat
    let valueRange: ClosedRange<CGFloat>

    private(set) var value: CGFloat
    var target: CGFloat
    var velocity: CGFloat = 0

    var criticalDamping: CGFloat {
        2 * sqrt(stiffness * mass)
    }

    var isAtRest: Bool {
        abs(value - target) <= Constants.valueTolerance
            && abs(velocity) <= Constants.velocityTolerance
    }

    init(
        value: CGFloat,
        mass: CGFloat,
        stiffness: CGFloat,
        maximumVelocity: CGFloat,
        valueRange: ClosedRange<CGFloat>
    ) {
        self.mass = mass
        self.stiffness = stiffness
        self.maximumVelocity = maximumVelocity
        self.valueRange = valueRange
        self.value = value
        self.target = value
    }

    mutating func reset(to value: CGFloat) {
        self.value = value
        target = value
        velocity = 0
    }

    mutating func finish() {
        value = target
        velocity = 0
    }

    mutating func advance(by elapsedTime: CGFloat, damping: CGFloat) {
        var remainingTime = min(elapsedTime, Constants.maximumElapsedTime)

        while remainingTime > 0 {
            let time = min(remainingTime, Constants.integrationStep)
            advanceOneStep(by: time, damping: damping)
            remainingTime -= time
        }
    }

    private mutating func advanceOneStep(by time: CGFloat, damping: CGFloat) {
        let springForce = -stiffness * (value - target)
        let dampingForce = -damping * velocity
        let acceleration = (springForce + dampingForce) / mass

        velocity = clamped(
            velocity + acceleration * time,
            to: -maximumVelocity...maximumVelocity
        )
        value += velocity * time

        if value <= valueRange.lowerBound {
            value = valueRange.lowerBound
            velocity = max(velocity, 0)
        } else if value >= valueRange.upperBound {
            value = valueRange.upperBound
            velocity = min(velocity, 0)
        }
    }

    private func clamped(_ value: CGFloat, to range: ClosedRange<CGFloat>) -> CGFloat {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
