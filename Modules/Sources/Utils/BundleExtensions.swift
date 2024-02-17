import Foundation

public extension Bundle {
     var appName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as! String? ??
        object(forInfoDictionaryKey: "CFBundleName") as! String?
    }
}
