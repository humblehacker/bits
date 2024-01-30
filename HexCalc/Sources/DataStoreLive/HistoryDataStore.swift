import DataStore
import Dependencies
import DependenciesAdditions
import DependenciesMacros
import Foundation
import GRDB
import Utils

extension HistoryDataStore: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.uuid) var uuid
        @Dependency(\.date.now) var now

        var _dbQueue: DatabaseQueue? = nil

        func dbQueue() throws -> DatabaseQueue {
            guard _dbQueue == nil else { return _dbQueue! }

            let dbPath = try FileManager.default
                .safeApplicationSupportURL()!
                .appendingPathComponent("hexcalc.db")
                .path

            let dbQueue = try DatabaseQueue(path: dbPath)

            try! dbQueue.write { db in
                try db.create(table: "historyItem", options: .ifNotExists) { t in
                    t.primaryKey("id", .text)
                    t.column("addedOn", .datetime).notNull()
                    t.column("text", .text).notNull()
                }
            }

            _dbQueue = dbQueue
            return dbQueue
        }

        return Self(
            item: { id in
                try await dbQueue().read { db in
                    try HistoryItem.fetchOne(db, id: id)
                }
            },
            items: {
                try await dbQueue().read { db in
                    try HistoryItem
                        .order(Column("addedOn").asc)
                        .fetchAll(db)
                }
            },
            addItem: { text in
                guard !text.isEmpty else { return }

                try await dbQueue().write { db in
                    let matchingItemID = try HistoryItem
                        .select(Column("id"), as: UUID.self)
                        .filter(Column("text") == text)
                        .fetchOne(db)

                    let item = HistoryItem(id: matchingItemID ?? uuid(), addedOn: now, text: text)

                    try item.upsert(db)
                }
            },
            removeItem: { id in
                try await dbQueue().write { db in
                    _ = try HistoryItem.deleteOne(db, id: id)
                }
            }
        )
    }()
}
