//
//  LocalizedString.swift
//  TodoList
//
//  Created by Renan Alves on 23/06/26.
//

import Foundation

enum L10n {
    enum Auth {
        static let fillCredentials = String(localized: "error.fill_credentials")
        static let taglineSignIn = String(localized: "auth.tagline.signin")
        static let taglineRegister = String(localized: "auth.tagline.register")
    }
    enum Error {
        static let serverUnavailable = String(localized: "error.server_unavailable")
        static let unexpectedResponse = String(localized: "error.unexpected_response")
        static let sessionExpired = String(localized: "error.session_expired")
        static let titleRequired = String(localized: "error.title_required")
        static let itemTextRequired = String(localized: "error.item_text_required")
        static let fetchFailed = String(localized: "error.fetch_failed")
        static let listNotFound = String(localized: "error.list_not_found")
    }
    enum Biometric {
        static let reason = String(localized: "biometric.reason")
        static let fallback = String(localized: "biometric.fallback")
    }
}
