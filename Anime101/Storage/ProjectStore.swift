import Foundation
import PencilKit
import UIKit

class ProjectStore {
    private let fileManager = FileManager.default

    // MARK: - Public Methods

    /// List all projects from disk
    func listProjects() -> [Project] {
        let projectsURL = ensureProjectsDirectoryExists()

        do {
            let projectDirs = try fileManager.contentsOfDirectory(at: projectsURL, includingPropertiesForKeys: nil)
            var projects: [Project] = []

            for dirURL in projectDirs {
                var isDir: ObjCBool = false
                if fileManager.fileExists(atPath: dirURL.path, isDirectory: &isDir), isDir.boolValue {
                    if let project = loadProjectMetadata(from: dirURL) {
                        projects.append(project)
                    }
                }
            }

            return projects.sorted { $0.modifiedAt > $1.modifiedAt }
        } catch {
            print("Error listing projects: \(error)")
            return []
        }
    }

    /// Create a new project with empty PKDrawing
    func createProject(name: String) -> Project {
        let project = Project(
            id: UUID(),
            name: name,
            createdAt: Date(),
            modifiedAt: Date()
        )

        let projectURL = projectDirectoryURL(id: project.id)

        do {
            try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)

            // Save empty drawing
            let emptyDrawing = PKDrawing()
            let drawingData = emptyDrawing.dataRepresentation()
            try drawingData.write(to: drawingDataURL(id: project.id))

            // Save metadata
            try saveProjectMetadata(project, to: projectURL)

            return project
        } catch {
            print("Error creating project: \(error)")
            return project
        }
    }

    /// Load project metadata and drawing
    func loadProject(id: UUID) -> (project: Project, drawing: PKDrawing)? {
        let projectURL = projectDirectoryURL(id: id)

        guard let project = loadProjectMetadata(from: projectURL) else {
            return nil
        }

        guard let drawingData = try? Data(contentsOf: drawingDataURL(id: id)),
              let drawing = try? PKDrawing(data: drawingData) else {
            return nil
        }

        return (project, drawing)
    }

    /// Save project metadata, drawing, and thumbnail
    func save(project: Project, drawing: PKDrawing, thumbnail: UIImage) -> Bool {
        let projectURL = projectDirectoryURL(id: project.id)

        do {
            try fileManager.createDirectory(at: projectURL, withIntermediateDirectories: true)

            // Save drawing
            let drawingData = drawing.dataRepresentation()
            try drawingData.write(to: drawingDataURL(id: project.id))

            // Save thumbnail
            if let pngData = thumbnail.pngData() {
                try pngData.write(to: thumbnailURL(id: project.id))
            }

            // Save metadata
            try saveProjectMetadata(project, to: projectURL)

            return true
        } catch {
            print("Error saving project: \(error)")
            return false
        }
    }

    /// Rename project (updates metadata only)
    func rename(projectId: UUID, newName: String) -> Bool {
        let projectURL = projectDirectoryURL(id: projectId)

        guard var project = loadProjectMetadata(from: projectURL) else {
            return false
        }

        project.name = newName
        project.modifiedAt = Date()

        do {
            try saveProjectMetadata(project, to: projectURL)
            return true
        } catch {
            print("Error renaming project: \(error)")
            return false
        }
    }

    /// Delete project directory
    func delete(projectId: UUID) -> Bool {
        let projectURL = projectDirectoryURL(id: projectId)

        do {
            try fileManager.removeItem(at: projectURL)
            return true
        } catch {
            print("Error deleting project: \(error)")
            return false
        }
    }

    // MARK: - Private Helpers

    private func ensureProjectsDirectoryExists() -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let projectsURL = documentsURL.appendingPathComponent("Projects")

        if !fileManager.fileExists(atPath: projectsURL.path) {
            try? fileManager.createDirectory(at: projectsURL, withIntermediateDirectories: true)
        }

        return projectsURL
    }

    private func projectDirectoryURL(id: UUID) -> URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsURL.appendingPathComponent("Projects").appendingPathComponent(id.uuidString)
    }

    private func drawingDataURL(id: UUID) -> URL {
        return projectDirectoryURL(id: id).appendingPathComponent("drawing.data")
    }

    private func metadataURL(id: UUID) -> URL {
        return projectDirectoryURL(id: id).appendingPathComponent("metadata.json")
    }

    private func thumbnailURL(id: UUID) -> URL {
        return projectDirectoryURL(id: id).appendingPathComponent("thumbnail.png")
    }

    private func saveProjectMetadata(_ project: Project, to projectURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(project)
        try data.write(to: metadataURL(id: project.id))
    }

    private func loadProjectMetadata(from projectURL: URL) -> Project? {
        let metadataURL = projectURL.appendingPathComponent("metadata.json")

        guard let data = try? Data(contentsOf: metadataURL) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try? decoder.decode(Project.self, from: data)
    }
}
