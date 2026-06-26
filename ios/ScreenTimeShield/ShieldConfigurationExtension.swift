import ManagedSettings
import ManagedSettingsUI
import UIKit

// ShieldConfiguration extension target: defines what the custom blocker screen
// looks like when the user opens a blocked app during a Levio window.
//
// NOTE: add this file to the Shield extension target in Xcode. The "Open Levio"
// primary button is handled by ShieldActionExtension.swift.
@available(iOS 16.0, *)
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    private func levioShield() -> ShieldConfiguration {
        ShieldConfiguration(
            backgroundBlurStyle: .systemMaterialDark,
            backgroundColor: UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1),
            icon: UIImage(named: "AppIcon"),
            title: ShieldConfiguration.Label(
                text: "Blocked by Levio",
                color: .white
            ),
            subtitle: ShieldConfiguration.Label(
                text: "This app is paused during your sleep window. Open Levio to manage it.",
                color: UIColor(white: 1, alpha: 0.7)
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Open Levio",
                color: .white
            ),
            primaryButtonBackgroundColor: UIColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1)
        )
    }

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        levioShield()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        levioShield()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        levioShield()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        levioShield()
    }
}
