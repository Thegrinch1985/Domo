import Foundation
import SwiftData

/// A scanned document or receipt stored via SwiftData.
/// Can be linked to any entity via optional UUID references.
@Model
final class Document {
    var id: UUID
    var title: String
    var category: String
    @Attribute(.externalStorage) var imageData: Data
    var createdAt: Date

    // Flexible entity linking — one document can be attached to an asset, vehicle, or policy
    var linkedAssetID: UUID?
    var linkedVehicleID: UUID?
    var linkedPolicyID: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        imageData: Data,
        createdAt: Date = .now,
        linkedAssetID: UUID? = nil,
        linkedVehicleID: UUID? = nil,
        linkedPolicyID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.imageData = imageData
        self.createdAt = createdAt
        self.linkedAssetID = linkedAssetID
        self.linkedVehicleID = linkedVehicleID
        self.linkedPolicyID = linkedPolicyID
    }
}
