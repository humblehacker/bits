import Foundation
import GRDB

public struct HistoryItem: Identifiable, Equatable, Hashable {
    public var id: UUID
    public var addedOn: Date
    public var text: String

    public init(id: UUID, addedOn: Date, text: String) {
        self.id = id
        self.addedOn = addedOn
        self.text = text
    }
}

extension HistoryItem: Codable, FetchableRecord, PersistableRecord {}
