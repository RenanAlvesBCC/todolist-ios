//
//  LocalizationTests.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import XCTest
import SwiftUI
@testable import TodoList

final class LocalizationTests: XCTestCase {

    func testAllL10nErrorKeysResolveToNonEmptyStrings() {
        XCTAssertFalse(L10n.Error.serverUnavailable.isEmpty)
        XCTAssertFalse(L10n.Error.unexpectedResponse.isEmpty)
        XCTAssertFalse(L10n.Error.sessionExpired.isEmpty)
        XCTAssertFalse(L10n.Error.titleRequired.isEmpty)
        XCTAssertFalse(L10n.Error.itemTextRequired.isEmpty)
    }

    func testL10nAuthKeysResolveToNonEmptyStrings() {
        XCTAssertFalse(L10n.Auth.fillCredentials.isEmpty)
        XCTAssertFalse(L10n.Auth.taglineSignIn.isEmpty)
        XCTAssertFalse(L10n.Auth.taglineRegister.isEmpty)
    }

    func testColorAssetsResolveWithoutCrashing() {
        let colors: [Color] = [
            .appDestructive,
            .appAccents[0],
            .appAccents[1],
            .appAccents[2],
            .appAccents[3]
        ]
        XCTAssertEqual(colors.count, 5)
    }
}
