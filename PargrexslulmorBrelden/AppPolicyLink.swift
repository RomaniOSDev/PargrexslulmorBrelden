//
//  AppPolicyLink.swift
//  PargrexslulmorBrelden
//

import Foundation

/// Central place for external policy URLs (replace with your live URLs before release).
enum AppPolicyLink: String, CaseIterable {
    case privacyPolicy = "https://pargrexslulmorbrelden.com/privacy-policy.html"
    case termsOfUse = "https://pargrexslulmorbrelden.com/support.html"

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
