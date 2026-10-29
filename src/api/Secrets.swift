import Foundation

// Values are substituted into Info.plist from xcconfig at build time.
// Developer overrides: config/local.xcconfig. Custom build overrides: config/custom.xcconfig.
enum Secrets {
    static let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as! String
}
