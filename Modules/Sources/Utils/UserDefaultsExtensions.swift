import Foundation

public extension UserDefaults {
    func dump() {
        guard let appDomain = Bundle.main.bundleIdentifier else { return }
        let userDefaultsDictionary = persistentDomain(forName: appDomain)
        print("defaults: ", userDefaultsDictionary ?? [:])
    }

    func wipe() {
        guard let appDomain = Bundle.main.bundleIdentifier else { return }
        removePersistentDomain(forName: appDomain)
    }
}
