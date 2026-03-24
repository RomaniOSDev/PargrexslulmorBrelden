//
//  AppPolicyLink.swift
//  PargrexslulmorBrelden
//

import Foundation

/// Central place for external policy URLs (replace with your live URLs before release).
enum AppPolicyLink: String, CaseIterable {
    case privacyPolicy = "https://example.com/privacy-policy"
    case termsOfUse = "https://example.com/terms"

    var url: URL? {
        URL(string: rawValue)
    }

    var settingsLabel: String {
        switch self {
        case .privacyPolicy: return "Privacy Policy"
        case .termsOfUse: return "Terms of Use"
        }
    }
}
