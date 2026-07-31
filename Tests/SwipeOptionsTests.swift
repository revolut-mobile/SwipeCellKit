//
//  SwipeOptionsTests.swift
//  SwipeCellKitTests
//

import XCTest
@testable import SwipeCellKit

final class SwipeOptionsTests: XCTestCase {
    func testNewOptionsPreserveOriginalDefaults() {
        let options = SwipeOptions()

        switch options.buttonWidthMode {
        case .equal:
            break
        case .individual:
            XCTFail("Expected equal button widths by default")
        }

        XCTAssertNil(options.activationThreshold)
    }

    func testExpansionStyleDefaultsToEdgeAlignedLayout() {
        let style = SwipeExpansionStyle(target: .percentage(0.5))

        XCTAssertEqual(style.expandedActionLayout, .edgeAligned)
    }
}
