//
//  SwipeActionsViewTests.swift
//  SwipeCellKitTests
//

import XCTest
@testable import SwipeCellKit

final class SwipeActionsViewTests: XCTestCase {
    func testEqualWidthModeUsesWidestPreferredWidthForEveryAction() {
        var options = SwipeOptions()
        options.minimumButtonWidth = 20
        options.maximumButtonWidth = 100

        let fixture = makeActionsView(widths: [40, 80, 60], options: options)

        XCTAssertEqual(fixture.view.buttonWidths, [80, 80, 80])
    }

    func testIndividualWidthModeUsesEachPreferredWidth() {
        var options = SwipeOptions()
        options.minimumButtonWidth = 20
        options.maximumButtonWidth = 100
        options.buttonWidthMode = .individual

        let fixture = makeActionsView(widths: [40, 80, 60], options: options)

        XCTAssertEqual(fixture.view.buttonWidths, [60, 80, 40])
        XCTAssertEqual(fixture.view.preferredWidth, 180)
    }

    func testIndividualWidthModeClampsEachWidthToConfiguredLimits() {
        var options = SwipeOptions()
        options.minimumButtonWidth = 30
        options.maximumButtonWidth = 100
        options.buttonWidthMode = .individual

        let fixture = makeActionsView(widths: [10, 120], options: options)

        XCTAssertEqual(fixture.view.buttonWidths, [100, 30])
    }

    func testTransitionPreparationOccursOnce() {
        let transition = TransitionSpy()
        let fixture = makeActionsView(widths: [40, 80, 60], transitionDelegate: transition)

        fixture.view.updateVisibleWidth(100, isInteractive: true)
        fixture.view.updateVisibleWidth(120, isInteractive: true)

        XCTAssertEqual(transition.preparationContexts.count, 3)
        XCTAssertTrue(transition.preparationContexts.allSatisfy {
            $0.newPercentVisible == 0 && $0.oldPercentVisible == 0
        })
    }

    func testTransitionContextReportsInteractionAndClampsVisibility() {
        let transition = TransitionSpy()
        let fixture = makeActionsView(widths: [50], transitionDelegate: transition)
        transition.transitionContexts.removeAll()

        fixture.view.updateVisibleWidth(500, isInteractive: true)

        XCTAssertEqual(transition.transitionContexts.count, 1)
        XCTAssertEqual(transition.transitionContexts.first?.newPercentVisible, 1)
        XCTAssertEqual(transition.transitionContexts.first?.oldPercentVisible, 0)
        XCTAssertEqual(transition.transitionContexts.first?.isInteractive, true)
    }

    func testTransitionContextReportsSettlingTarget() {
        let transition = TransitionSpy()
        var options = SwipeOptions()
        options.minimumButtonWidth = 50
        options.maximumButtonWidth = 50
        let fixture = makeActionsView(
            widths: [50],
            options: options,
            transitionDelegate: transition
        )
        fixture.view.updateVisibleWidth(25, isInteractive: true)
        transition.transitionContexts.removeAll()

        fixture.view.updateVisibleWidth(50)

        let transitionReported = expectation(description: "Transition reported")
        DispatchQueue.main.async {
            XCTAssertEqual(transition.transitionContexts.count, 1)
            XCTAssertEqual(transition.transitionContexts.first?.newPercentVisible, 1)
            XCTAssertEqual(transition.transitionContexts.first?.isInteractive, false)
            transitionReported.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    func testFillAvailableSpaceFreezesBorderLayoutAndExpandsPrimaryAction() {
        var options = SwipeOptions()
        options.minimumButtonWidth = 20
        options.maximumButtonWidth = 100
        options.buttonWidthMode = .individual
        options.transitionStyle = .border
        options.expansionStyle = SwipeExpansionStyle(
            target: .percentage(0.8),
            expandedActionLayout: .fillAvailableSpace
        )
        let fixture = makeActionsView(widths: [40, 80, 60], options: options)

        fixture.view.updateVisibleWidth(230, isInteractive: true)

        XCTAssertEqual(fixture.view.layoutContext.visibleWidth, 180)
        XCTAssertEqual(fixture.view.layoutContext.contentSize.width, 180)
        XCTAssertEqual(fixture.view.subviews.map { $0.frame.origin.x }, [0, 60, 140])
        XCTAssertEqual(fixture.view.buttons.last?.bounds.width, 90)
        XCTAssertEqual(fixture.contentViews["0"]?.expansionContexts.last?.regularWidth, 40)
        XCTAssertEqual(fixture.contentViews["0"]?.expansionContexts.last?.currentWidth, 90)
        XCTAssertEqual(fixture.contentViews["0"]?.expansionContexts.last?.maximumWidth, 180)
        XCTAssertEqual(fixture.contentViews["0"]?.expansionContexts.last?.additionalWidth, 50)
    }

    func testFillAvailableSpaceSupportsLeftOrientation() {
        var options = SwipeOptions()
        options.minimumButtonWidth = 20
        options.maximumButtonWidth = 100
        options.buttonWidthMode = .individual
        options.transitionStyle = .border
        options.expansionStyle = SwipeExpansionStyle(
            target: .percentage(0.8),
            expandedActionLayout: .fillAvailableSpace
        )
        let fixture = makeActionsView(
            widths: [40, 80, 60],
            options: options,
            orientation: .left
        )

        fixture.view.updateVisibleWidth(230, isInteractive: true)

        XCTAssertEqual(fixture.view.subviews.map { $0.frame.origin.x }, [0, -60, -140])
        XCTAssertEqual(fixture.view.buttons.last?.bounds.width, 90)
    }

    func testClearExpandableActionUsesAutomaticScaleAndAlphaExpansion() {
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        let fixture = makeActionsView(
            widths: [50, 50, 50],
            options: options,
            clearExpandableAction: true
        )

        XCTAssertTrue(fixture.view.expansionDelegate is ScaleAndAlphaExpansion)
    }

    func testCustomExpansionDelegateControlsOtherActionsAppearance() {
        let expansionDelegate = ExpansionSpy()
        var options = SwipeOptions()
        options.expansionStyle = .destructive
        options.expansionDelegate = expansionDelegate
        let fixture = makeActionsView(widths: [50, 50, 50], options: options)

        UIView.setAnimationsEnabled(false)
        fixture.view.setExpanded(expanded: true)
        fixture.view.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)

        XCTAssertEqual(expansionDelegate.changes, [true])
        XCTAssertEqual(fixture.view.buttons.dropLast().map { $0.alpha }, [0.5, 0.5])
        XCTAssertEqual(fixture.view.buttons.dropLast().map { $0.transform.a }, [0.8, 0.8])
    }
}
