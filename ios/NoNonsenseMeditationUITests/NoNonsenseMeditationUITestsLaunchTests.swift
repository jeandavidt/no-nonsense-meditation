//
//  NoNonsenseMeditationUITestsLaunchTests.swift
//  NoNonsenseMeditationUITests
//
//  Created on 2026-01-05.
//

import XCTest

final class NoNonsenseMeditationUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
