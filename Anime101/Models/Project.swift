import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var modifiedAt: Date
}
