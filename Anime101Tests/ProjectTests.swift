import XCTest
@testable import Anime101

final class ProjectTests: XCTestCase {
    func testEncodeDecodeRoundTrip() throws {
        let project = Project(
            id: UUID(),
            name: "Round Trip",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_100)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Project.self, from: data)

        XCTAssertEqual(decoded, project)
    }

    func testEqualityIsBasedOnAllProperties() {
        let id = UUID()
        let date = Date()

        let a = Project(id: id, name: "A", createdAt: date, modifiedAt: date)
        let b = Project(id: id, name: "A", createdAt: date, modifiedAt: date)
        let differentName = Project(id: id, name: "B", createdAt: date, modifiedAt: date)

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, differentName)
    }

    func testMutatingNameAndModifiedAt() {
        var project = Project(id: UUID(), name: "Original", createdAt: Date(), modifiedAt: Date())
        let newDate = Date().addingTimeInterval(60)

        project.name = "Updated"
        project.modifiedAt = newDate

        XCTAssertEqual(project.name, "Updated")
        XCTAssertEqual(project.modifiedAt, newDate)
    }
}
