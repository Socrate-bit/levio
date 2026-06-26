import ManagedSettings
import UIKit

// ShieldAction extension target: handles taps on the custom blocker screen's
// buttons.
//
// IMPORTANT CONSTRAINT: app extensions cannot call UIApplication.open, so a
// shield action cannot directly launch Levio. The primary "Open Levio" button
// therefore closes the blocked app (returning the user to the Home screen),
// from where they tap Levio. The `levio://` URL scheme is registered in the
// Runner Info.plist so this can be revisited if Apple expands what shield
// actions may do. Validate the chosen response on-device.
//
// NOTE: add this file to the Shield ACTION extension target in Xcode.
@available(iOS 16.0, *)
class ShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            // Close the blocked app so the user lands on the Home screen and
            // can open Levio.
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }
}
