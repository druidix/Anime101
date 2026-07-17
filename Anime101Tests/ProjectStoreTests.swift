import XCTest
import PencilKit
import UIKit
@testable import Anime101

final class ProjectStoreTests: XCTestCase {
    var projectStore: ProjectStore!
    var testProjectsURL: URL!

    override func setUp() {
        super.setUp()
        projectStore = ProjectStore()

        // Set up temporary directory for test projects
        let tempDir = FileManager.default.temporaryDirectory
        testProjectsURL = tempDir.appendingPathComponent("TestProjects_\(UUID().uuidString)")

        // Override the projects directory (we'll handle this by using the default for now)
        // In a real scenario, you'd inject the base path into ProjectStore
    }

    override func tearDown() {
        super.tearDown()

        // Clean up test projects directory
        if let testURL = testProjectsURL {
            try? FileManager.default.removeItem(at: testURL)
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

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let projectURL = documentsURL.appendingPathComponent("Projects").appendingPathComponent(project.id.uuidString)

        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.path), "Project directory should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("metadata.json").path), "Metadata file should exist")
        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("drawing.data").path), "Drawing file should exist")
    }

    func testListProjects() {
        // Clean up any existing projects first
        let existingProjects = projectStore.listProjects()
        for project in existingProjects {
            projectStore.delete(projectId: project.id)
        }

        let project1 = projectStore.createProject(name: "Project 1")
        let project2 = projectStore.createProject(name: "Project 2")
        let project3 = projectStore.createProject(name: "Project 3")

        let listedProjects = projectStore.listProjects()

        XCTAssertGreaterThanOrEqual(listedProjects.count, 3, "Should have at least 3 projects")

        let projectNames = listedProjects.map { $0.name }
        XCTAssertTrue(projectNames.contains("Project 1"))
        XCTAssertTrue(projectNames.contains("Project 2"))
        XCTAssertTrue(projectNames.contains("Project 3"))

        // Clean up
        projectStore.delete(projectId: project1.id)
        projectStore.delete(projectId: project2.id)
        projectStore.delete(projectId: project3.id)
    }

    func testLoadProject() {
        let originalProject = projectStore.createProject(name: "Load Test")

        guard let (loadedProject, _) = projectStore.loadProject(id: originalProject.id) else {
            XCTFail("Should be able to load project")
            return
        }

        XCTAssertEqual(loadedProject.id, originalProject.id)
        XCTAssertEqual(loadedProject.name, originalProject.name)
        XCTAssertEqual(loadedProject.createdAt, originalProject.createdAt)

        // Clean up
        projectStore.delete(projectId: originalProject.id)
    }

    func testSaveProjectWithDrawing() {
        let project = projectStore.createProject(name: "Drawing Test")

        // Create a test drawing
        let testDrawing = PKDrawing()

        // Create a test thumbnail
        let testImage = UIImage(color: .blue, size: CGSize(width: 100, height: 100)) ?? UIImage()

        let success = projectStore.save(project: project, drawing: testDrawing, thumbnail: testImage)
        XCTAssertTrue(success, "Save should succeed")

        // Verify files exist
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let projectURL = documentsURL.appendingPathComponent("Projects").appendingPathComponent(project.id.uuidString)

        XCTAssertTrue(FileManager.default.fileExists(atPath: projectURL.appendingPathComponent("thumbnail.png").path), "Thumbnail should exist")

        // Clean up
        projectStore.delete(projectId: project.id)
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

        // Clean up
        projectStore.delete(projectId: project.id)
    }

    func testDeleteProject() {
        let project = projectStore.createProject(name: "Delete Test")
        let projectId = project.id

        let success = projectStore.delete(projectId: projectId)
        XCTAssertTrue(success, "Delete should succeed")

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let projectURL = documentsURL.appendingPathComponent("Projects").appendingPathComponent(projectId.uuidString)

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
        XCTAssertEqual(loadedProject.createdAt, originalProject.createdAt)

        // Clean up
        projectStore.delete(projectId: originalProject.id)
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

        // Clean up
        projectStore.delete(projectId: project.id)
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
