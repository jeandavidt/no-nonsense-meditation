//
//  NoNonsenseMeditationUITests.swift
//  NoNonsenseMeditationUITests
//
//  Created on 2026-01-05.
//

import XCTest

final class NoNonsenseMeditationUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["No Nonsense Meditation"].exists)
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
