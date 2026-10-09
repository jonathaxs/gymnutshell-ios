// ⌘
//  GymNutshell/GymNutshellApp/Helpers/Services/GymNutshellAppDelegate.swift
//
//  Propósito: AppDelegate mínimo registrado via @UIApplicationDelegateAdaptor.
//             Existe pra entregar `application(_:supportedInterfaceOrientationsFor:)`,
//             que SwiftUI sozinho não expõe. Na 1.1 o iPhone fica travado em retrato.
//
//  Created by Jonathas Motta (@jonathaxs) on 2026-04-25.
// ⌘

import UIKit

final class GymNutshellAppDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        // iPad / Mac / Vision: sempre liberado. iPhone: só retrato (sem paisagem na 1.1).
        if UIDevice.current.userInterfaceIdiom != .phone {
            return .all
        }
        return .portrait
    }
}
