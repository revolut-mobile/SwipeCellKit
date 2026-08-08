//
//  SwipeControllerTests.swift
//  SwipeCellKitTests
//

import XCTest
@testable import SwipeCellKit

final class SwipeControllerTests: XCTestCase {
    func testAbsoluteActivationThresholdUsesDistanceForClosingVelocity() {
        var options = SwipeOptions()
        options.activationThreshold = .absolute(50)
        let fixture = makeActionsView(widths: [50], options: options)
        fixture.view.updateVisibleWidth(60, isInteractive: true)
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .dragging
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        let state = controller.targetState(forVelocity: CGPoint(x: 100, y: 0))

        XCTAssertEqual(state, .right)
    }

    func testAbsoluteActivationThresholdHidesBelowDistanceForOpeningVelocity() {
        var options = SwipeOptions()
        options.activationThreshold = .absolute(50)
        let fixture = makeActionsView(widths: [50], options: options)
        fixture.view.updateVisibleWidth(49, isInteractive: true)
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .dragging
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        let state = controller.targetState(forVelocity: CGPoint(x: -100, y: 0))

        XCTAssertEqual(state, .center)
    }

    func testFractionalActivationThresholdUsesCellWidth() {
        var options = SwipeOptions()
        options.activationThreshold = .fractional(0.25)
        let fixture = makeActionsView(widths: [50], options: options)
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .dragging
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        fixture.view.updateVisibleWidth(79, isInteractive: true)
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: -100, y: 0)),
            .center
        )

        fixture.view.updateVisibleWidth(80, isInteractive: true)
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: 100, y: 0)),
            .right
        )
    }

    func testDefaultActivationBehaviorStillUsesVelocityDirection() {
        let fixture = makeActionsView(widths: [50])
        fixture.view.updateVisibleWidth(1, isInteractive: true)
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .dragging
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: -100, y: 0)),
            .right
        )
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: 100, y: 0)),
            .center
        )
    }

    func testActivationThresholdSupportsLeftOrientation() {
        var options = SwipeOptions()
        options.activationThreshold = .absolute(50)
        let fixture = makeActionsView(
            widths: [50],
            options: options,
            orientation: .left
        )
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .dragging
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        fixture.view.updateVisibleWidth(60, isInteractive: true)
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: -100, y: 0)),
            .left
        )

        fixture.view.updateVisibleWidth(49, isInteractive: true)
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: 100, y: 0)),
            .center
        )
    }

    func testActivationThresholdDoesNotChangeDefaultDeactivationBehavior() {
        var options = SwipeOptions()
        options.activationThreshold = .absolute(50)
        let fixture = makeActionsView(widths: [50], options: options)
        fixture.view.updateVisibleWidth(60, isInteractive: true)
        let swipeable = SwipeableMock(frame: fixture.view.bounds)
        swipeable.actionsView = fixture.view
        swipeable.state = .right
        let controller = SwipeController(
            swipeable: swipeable,
            actionsContainerView: swipeable
        )

        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: 100, y: 0)),
            .center
        )
        XCTAssertEqual(
            controller.targetState(forVelocity: CGPoint(x: -100, y: 0)),
            .right
        )
    }
}
