import Foundation

// Values are substituted into Info.plist from xcconfig at build time.
// Developer overrides: config/local.xcconfig. Personal build overrides: config/personal.xcconfig.
enum Secrets {
    static let appCenterSecret = Bundle.main.object(forInfoDictionaryKey: "AppCenterSecret") as! String
}
