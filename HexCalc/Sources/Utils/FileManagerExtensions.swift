import Foundation

public extension FileManager {
    func safeApplicationSupportURL() throws -> URL? {
        guard let appSupportURL = urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        if !fileExists(atPath: appSupportURL.path) {
            try createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        }
        return appSupportURL
    }
}
