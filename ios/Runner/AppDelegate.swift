import UIKit
import Flutter
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GMSServices.provideAPIKey("AIzaSyCSyT_K0PIfBs_9xDG0-IAJC1F2zJmfc_4")
        GeneratedPluginRegistrant.register(with: self)
        SwiftBluetoothPlugin.register(with: self.registrar(forPlugin: "SwiftBluetoothPlugin")!)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
