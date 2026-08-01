import XCTest
import PencilKit
import UIKit
@testable import Anime101

final class ProjectStoreTests: XCTestCase {
    var projectStore: ProjectStore!
    var testBaseURL: URL!

    override func setUp() {
        super.setUp()

        let tempDir = FileManager.default.temporaryDirectory
        testBaseURL = tempDir.appendingPathComponent("Anime101Tests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: testBaseURL, withIntermediateDirectories: true)

        projectStore = ProjectStore(baseDirectory: testBaseURL)
    }

    override func tearDown() {
        super.tearDown()

        if let testBaseURL {
            try? FileManager.default.removeItem(at: testBaseURL)
        }
    }

    // MARK: - Tests

    func testCreateProject() {
        let projectName = "Test Project"
        let project = projectStore.createProject(name: projectName)

        XCTAssertEqual(project.name, projectName)
        XCTAssertNotEqual(project.id, UUID())
        XCTAssertLessThanOrEqual(project.createdAt.timeIntervalSinceNow, 0.1)
        XCTAssertLessThanOrEqual(project.modifiedAt.timeIntervalSinceNow, 0.1)
    }

    func testCreateProjectWritesFilesToDisk() {
        let project = projectStore.createProject(name: "Disk Test")

        let projectURL = testBaseURL.appendingPathComponent("Projects").appendingPathComponent(project.id.uuidString)

        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.path), "Project directory should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("metadata.json").path), "Metadata file should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("drawing.data").path), "Drawing file should exist")
    }

    func testListProjects() {
        let project1 = projectStore.createProject(name: "Project 1")
        let project2 = projectStore.createProject(name: "Project 2")
        let project3 = projectStore.createProject(name: "Project 3")

        let listedProjects = projectStore.listProjects()

        XCTAssertEqual(listedProjects.count, 3)

        let projectNames = Set(listedProjects.map { $0.name })
        XCTAssertEqual(projectNames, Set([project1.name, project2.name, project3.name]))
    }

    func testLoadProject() {
        let originalProject = projectStore.createProject(name: "Load Test")

        guard let (loadedProject, _) = projectStore.loadProject(id: originalProject.id) else {
            XCTFail("Should be able to load project")
            return
        }

        XCTAssertEqual(loadedProject.id, originalProject.id)
        XCTAssertEqual(loadedProject.name, originalProject.name)
        // Metadata is persisted as ISO 8601 without fractional seconds, so
        // round-tripped dates only preserve whole-second precision.
        XCTAssertEqual(
            loadedProject.createdAt.timeIntervalSince1970,
            originalProject.createdAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testSaveProjectWithDrawing() {
        let project = projectStore.createProject(name: "Drawing Test")

        let testDrawing = PKDrawing()
        let testImage = UIImage(color: .blue, size: CGSize(width: 100, height: 100)) ?? UIImage()

        let success = projectStore.save(project: project, drawing: testDrawing, thumbnail: testImage)
        XCTAssertTrue(success, "Save should succeed")

        let projectURL = testBaseURL.appendingPathComponent("Projects").appendingPathComponent(project.id.uuidString)
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("thumbnail.png").path), "Thumbnail should exist")
    }

    func testRenameProject() {
        let project = projectStore.createProject(name: "Original Name")
        let newName = "Updated Name"

        let success = projectStore.rename(projectId: project.id, newName: newName)
        XCTAssertTrue(success, "Rename should succeed")

        guard let (renamedProject, _) = projectStore.loadProject(id: project.id) else {
            XCTFail("Should be able to load renamed project")
            return
        }

        XCTAssertEqual(renamedProject.name, newName)
    }

    func testDeleteProject() {
        let project = projectStore.createProject(name: "Delete Test")
        let projectId = project.id

        let success = projectStore.delete(projectId: projectId)
        XCTAssertTrue(success, "Delete should succeed")

        let projectURL = testBaseURL.appendingPathComponent("Projects").appendingPathComponent(projectId.uuidString)
        XCTAssertFalse(FileManager.default.fileExists(atPath: projectURL.path), "Project directory should be deleted")
    }

    func testProjectMetadataRoundTrip() {
        let originalProject = projectStore.createProject(name: "Metadata Test")

        guard let (loadedProject, _) = projectStore.loadProject(id: originalProject.id) else {
            XCTFail("Should be able to load project")
            return
        }

        XCTAssertEqual(loadedProject.id, originalProject.id)
        XCTAssertEqual(loadedProject.name, originalProject.name)
        XCTAssertEqual(
            loadedProject.createdAt.timeIntervalSince1970,
            originalProject.createdAt.timeIntervalSince1970,
            accuracy: 1.0
        )
    }

    func testProjectDrawingRoundTrip() {
        let project = projectStore.createProject(name: "Drawing Round Trip")

        guard let (_, originalDrawing) = projectStore.loadProject(id: project.id) else {
            XCTFail("Should be able to load project")
            return
        }

        // Verify the drawing data round-trips correctly
        let originalData = originalDrawing.dataRepresentation()
        let recreatedDrawing = try? PKDrawing(data: originalData)

        XCTAssertNotNil(recreatedDrawing, "Should be able to recreate drawing from data")
    }

    // MARK: - Edge Cases

    func testLoadProjectReturnsNilForNonexistentId() {
        XCTAssertNil(projectStore.loadProject(id: UUID()))
    }

    func testRenameReturnsFalseForNonexistentId() {
        XCTAssertFalse(projectStore.rename(projectId: UUID(), newName: "Doesn't Matter"))
    }

    func testDeleteReturnsFalseForNonexistentId() {
        XCTAssertFalse(projectStore.delete(projectId: UUID()))
    }

    func testListProjectsOnEmptyStoreReturnsEmptyArray() {
        XCTAssertEqual(projectStore.listProjects(), [])
    }

    func testRenameUpdatesModifiedAt() {
        let project = projectStore.createProject(name: "Before Rename")

        XCTAssertTrue(projectStore.rename(projectId: project.id, newName: "After Rename"))

        guard let (renamed, _) = projectStore.loadProject(id: project.id) else {
            XCTFail("Should be able to load renamed project")
            return
        }

        // Allow for the 1-second ISO 8601 truncation applied on disk when
        // rename() and createProject() land within the same wall-clock second.
        XCTAssertGreaterThanOrEqual(
            renamed.modifiedAt.timeIntervalSince1970,
            project.modifiedAt.timeIntervalSince1970 - 1.0
        )
    }

    func testListProjectsSortedByModifiedAtDescending() {
        let older = projectStore.createProject(name: "Older")
        var olderModified = older
        olderModified.modifiedAt = Date(timeIntervalSince1970: 1_000)
        XCTAssertTrue(projectStore.save(project: olderModified, drawing: PKDrawing(), thumbnail: UIImage()))

        let newer = projectStore.createProject(name: "Newer")
        var newerModified = newer
        newerModified.modifiedAt = Date(timeIntervalSince1970: 2_000)
        XCTAssertTrue(projectStore.save(project: newerModified, drawing: PKDrawing(), thumbnail: UIImage()))

        let listed = projectStore.listProjects()

        XCTAssertEqual(listed.first?.name, "Newer")
        XCTAssertEqual(listed.last?.name, "Older")
    }

    func testListProjectsSkipsCorruptMetadata() {
        let projectsURL = testBaseURL.appendingPathComponent("Projects")
        let corruptProjectURL = projectsURL.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: corruptProjectURL, withIntermediateDirectories: true)
        try? "not valid json".data(using: .utf8)?.write(to: corruptProjectURL.appendingPathComponent("metadata.json"))

        let validProject = projectStore.createProject(name: "Valid Project")

        let listed = projectStore.listProjects()

        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.id, validProject.id)
    }

    func testSavingDoesNotClearCanvasUndoHistory() {
        // The undo manager is only meaningfully wired up once the canvas is part of a
        // window's responder chain (see commit 0135b7f), so attach it to one here.
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let canvas = PKCanvasView(frame: window.bounds)
        window.addSubview(canvas)
        window.makeKeyAndVisible()

        canvas.undoManager?.levelsOfUndo = 50
        canvas.undoManager?.beginUndoGrouping()
        canvas.undoManager?.registerUndo(withTarget: canvas) { _ in }
        canvas.undoManager?.endUndoGrouping()
        XCTAssertTrue(canvas.undoManager?.canUndo ?? false)

        let project = projectStore.createProject(name: "Undo Safety")
        XCTAssertTrue(projectStore.save(project: project, drawing: canvas.drawing, thumbnail: UIImage()))

        XCTAssertTrue(canvas.undoManager?.canUndo ?? false, "Saving should not clear the canvas undo history")
    }

    func testListProjectsSkipsNonDirectoryEntries() {
        let projectsURL = testBaseURL.appendingPathComponent("Projects")
        try? FileManager.default.createDirectory(at: projectsURL, withIntermediateDirectories: true)
        try? Data().write(to: projectsURL.appendingPathComponent("stray-file.txt"))

        let validProject = projectStore.createProject(name: "Valid Project")

        let listed = projectStore.listProjects()

        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.id, validProject.id)
    }
}

// MARK: - Helper Extension
extension UIImage {
    convenience init?(color: UIColor, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
