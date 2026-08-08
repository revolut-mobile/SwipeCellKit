//
//  SwipeTransitionLayoutTests.swift
//  SwipeCellKitTests
//

import XCTest
@testable import SwipeCellKit

final class SwipeTransitionLayoutTests: XCTestCase {
    func testDragTransitionUsesIndividualButtonWidths() {
        let context = ActionsViewLayoutContext(
            buttonWidths: [40, 80, 60],
            orientation: .right,
            contentSize: CGSize(width: 100, height: 80),
            visibleWidth: 100
        )

        let visibleWidths = DragTransitionLayout().visibleWidthsForViews(with: context)

        XCTAssertEqual(visibleWidths, [40, 60, 0])
    }

    func testRevealTransitionUsesIndividualButtonWidthsFromCellEdge() {
        let context = ActionsViewLayoutContext(
            buttonWidths: [40, 80, 60],
            orientation: .right,
            contentSize: CGSize(width: 100, height: 80),
            visibleWidth: 100
        )

        let visibleWidths = RevealTransitionLayout().visibleWidthsForViews(with: context)

        XCTAssertEqual(visibleWidths, [0, 40, 60])
    }

    func testBorderTransitionDistributesWidthProportionally() {
        let context = ActionsViewLayoutContext(
            buttonWidths: [40, 80, 60],
            orientation: .right,
            contentSize: CGSize(width: 90, height: 80),
            visibleWidth: 90
        )

        let visibleWidths = BorderTransitionLayout().visibleWidthsForViews(with: context)

        XCTAssertEqual(visibleWidths[0], 20)
        XCTAssertEqual(visibleWidths[1], 40)
        XCTAssertEqual(visibleWidths[2], 30)
    }

    func testLayoutsUseCumulativeOriginsForIndividualWidths() {
        let views = (0..<3).map { _ in UIView() }
        let context = ActionsViewLayoutContext(
            buttonWidths: [40, 80, 60],
            orientation: .right,
            contentSize: CGSize(width: 180, height: 80),
            visibleWidth: 180
        )

        views.enumerated().forEach {
            DragTransitionLayout().layout(view: $0.element, atIndex: $0.offset, with: context)
        }

        let origins = views.map { $0.frame.origin.x }
        XCTAssertEqual(origins, [0, 40, 120])
    }
}
