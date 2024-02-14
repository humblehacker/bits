import Dependencies
import DependenciesMacros
import Foundation
import Utils

@DependencyClient
public struct HistoryDataStore {
    public var item: (_ id: HistoryItem.ID) async throws -> HistoryItem?
    public var items: () async throws -> [HistoryItem] = { [] }
    public var addItem: (_ text: String) async throws -> Void
    public var removeItem: (_ id: HistoryItem.ID) async throws -> Void
}

extension HistoryDataStore: TestDependencyKey {
    public static var testValue = Self()

    public static let previewValue = {
        @Dependency(\.date.now) var now
        @Dependency(\.uuid) var uuid
        return Self(
            item: { id in HistoryItem(id: id, addedOn: now, text: "123") },
            items: { [HistoryItem(id: uuid(), addedOn: now, text: "123")] },
            addItem: { _ in },
            removeItem: { _ in }
        )
    }()
}

public extension DependencyValues {
    var historyStore: HistoryDataStore {
        get { self[HistoryDataStore.self] }
        set { self[HistoryDataStore.self] = newValue }
    }
}
