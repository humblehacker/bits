import Dependencies
import Foundation
import GRDB
import Utils

package class Database {
    @Dependency(\.uuid) var uuid
    @Dependency(\.date.now) var now
    let inMemory: Bool

    init(inMemory: Bool = false) {
        self.inMemory = inMemory
    }

    private var _dbQueue: DatabaseQueue?

    func dbQueue() throws -> DatabaseQueue {
        guard _dbQueue == nil else { return _dbQueue! }

        let dbPath = inMemory ? ":memory:" : try FileManager.default
            .safeApplicationSupportURL()!
            .appendingPathComponent("hexcalc.db")
            .path

        let dbQueue = try DatabaseQueue(path: dbPath)

        _dbQueue = dbQueue
        return dbQueue
    }
}

extension Database: DependencyKey {
    package static let liveValue = Database()
}

package extension DependencyValues {
    var database: Database {
        get { self[Database.self] }
        set { self[Database.self] = newValue }
    }
}
