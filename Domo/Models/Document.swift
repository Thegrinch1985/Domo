import Foundation
import SwiftData

/// A scanned document or receipt stored via SwiftData.
@Model
final class Document {
    var id: UUID
    var title: String
    var category: String
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        imageData: Data,
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.imageData = imageData
        self.createdAt = createdAt
    }
}
