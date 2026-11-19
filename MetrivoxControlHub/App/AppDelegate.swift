import UIKit
import SwiftUI
import AppTrackingTransparency
import AdjustSdk
import OneSignalFramework

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var orientationLock: UIInterfaceOrientationMask = .all
    static let saveJobSheetPresenter = "saveJobSheetPresenter"
    private var shootUmbrellaControl = false
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.set(
            ATTrackingManager.trackingAuthorizationStatus != .notDetermined,
            forKey: Self.saveJobSheetPresenter)
        
        if let config = ADJConfig(appToken: "j475ckt4yj9c", environment: ADJEnvironmentProduction) {
            config.logLevel = .verbose
            config.attConsentWaitingInterval = 20
            Adjust.initSdk(config)
        }
        
        OneSignal.initialize("601fcab7-afac-4ec2-9cd7-f35a4e5ac440", withLaunchOptions: launchOptions)
        return true
    }
    
    func shootLensChoice() {
        guard !shootUmbrellaControl, ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        shootUmbrellaControl = true
        
        Task {
            defer { shootUmbrellaControl = false }
            try? await Task.sleep(for: .seconds(1))
            guard UIApplication.shared.applicationState == .active else { return }
            _ = await Adjust.requestAppTrackingAuthorization()
            let sheetPresentationBinding = ATTrackingManager.trackingAuthorizationStatus != .notDetermined
            UserDefaults.standard.set(sheetPresentationBinding, forKey: AppDelegate.saveJobSheetPresenter)
        }
    }
}
