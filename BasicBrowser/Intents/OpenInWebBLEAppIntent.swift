//
//  OpenInWebBLEAppIntent.swift
//  WebBLE
//
//  Created by David Park on 21/09/2026.
//

import AppIntents
import UIKit

@available(iOS 18.0, *)
struct WebBLEOpenURLAppIntent: AppIntent {

    // MARK: - Intent metadata
    static let title: LocalizedStringResource = "Open URL in WebBLE"

    @available(iOS, obsoleted: 26.0, message: "deprecated in favour of supportedModes")
    static var openAppWhenRun: Bool { true }

    @available(iOS 26.0, *)
    static let supportedModes: IntentModes = [.foreground(.deferred)]

    @available(iOS 27.0, *)
    static var allowedExecutionTargets: IntentExecutionTargets { .main }

    // MARK: - Intent parameters
    @Parameter(title: "URL")
    var url: URL

    // MARK: - Intent implementation
    func perform() async throws -> some IntentResult {
        try await MainActor.run {
            guard
                let ad = UIApplication.shared.delegate as? AppDelegate,
                let vc = ad.firstWebBLEViewController()
            else {
                throw WebBLEError(
                    message: "Unable to open WebBLE due to internal state error (AKA a bug)"
                )
            }
            vc.loadURL(self.url)
        }
        return .result()
    }
}
