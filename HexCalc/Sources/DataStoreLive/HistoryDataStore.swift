import DataStore
import Dependencies
import DependenciesMacros
import Foundation
import GRDB
import Utils

extension HistoryDataStore: DependencyKey {
    public static let liveValue: Self = {
        @Dependency(\.uuid) var uuid

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
                    let lastItem = try HistoryItem
                        .order(Column("addedOn").desc)
                        .fetchOne(db)

                    // don't insert consecutive identical items
                    guard lastItem?.text != text else { return }

                    let item = HistoryItem(id: uuid(), addedOn: .now, text: text)
                    try item.insert(db)
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
