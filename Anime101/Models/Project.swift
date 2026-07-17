import Foundation

struct Project: Codable {
    let id: UUID
    var name: String
    let createdAt: Date
    var modifiedAt: Date
}
