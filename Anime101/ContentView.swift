import SwiftUI
import PencilKit
import UIKit

@MainActor
class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []

    var projectStore: ProjectStore

    init(projectStore: ProjectStore) {
        self.projectStore = projectStore
    }

    func loadProjects() {
        projects = projectStore.listProjects()
    }

    func createProject(name: String) -> Project {
        let project = projectStore.createProject(name: name)
        loadProjects()
        return project
    }

    func deleteProject(id: UUID) {
        _ = projectStore.delete(projectId: id)
        loadProjects()
    }

    func renameProject(id: UUID, newName: String) {
        _ = projectStore.rename(projectId: id, newName: newName)
        loadProjects()
    }
}

struct MainMenuView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var isCreatingNewProject = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "film.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Anime 101")
                        .font(.system(size: 32, weight: .bold))
                    Text("Create and edit anime projects")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .padding()

                Spacer()

                VStack(spacing: 12) {
                    NavigationLink(destination: ProjectListView().environmentObject(projectStore)) {
                        HStack {
                            Image(systemName: "folder.fill")
                            Text("Open Existing Project")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .background(.blue)
                        .cornerRadius(8)
                    }

                    Button(action: {
                        isCreatingNewProject = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create New Project")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .background(.green)
                        .cornerRadius(8)
                    }
                    .navigationDestination(isPresented: $isCreatingNewProject) {
                        NewProjectView()
                            .environmentObject(projectStore)
                    }
                }
                .padding(24)

                Spacer()
            }
            .navigationTitle("Welcome")
        }
    }
}

struct NewProjectView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var projectName: String = "Untitled Project"
    @State private var createdProject: Project?

    var body: some View {
        if let createdProject = createdProject {
            CanvasView(project: createdProject)
                .environmentObject(projectStore)
        } else {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Project Name", text: $projectName)
                            .textFieldStyle(.roundedBorder)
                            .font(.title2)
                            .fontWeight(.semibold)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Project Type")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Anime Project")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                Button(action: {
                    createdProject = projectStore.createProject(name: projectName)
                }) {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .background(.blue)
                        .cornerRadius(8)
                }

                CanvasView(project: Project(
                    id: UUID(),
                    name: projectName,
                    createdAt: Date(),
                    modifiedAt: Date()
                ))
                .environmentObject(projectStore)

                Spacer()
            }
            .padding()
            .navigationTitle("New Project")
        }
    }
}

struct ProjectListView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var projects: [Project] = []
    @State private var isLoading = true

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedProjectId: UUID?
    @State private var renameText = ""
    @State private var newProject: Project?
    @State private var isCreatingNewProject = false

    @Environment(\.dismiss) var dismiss

    var columns: [GridItem] {
        [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }

    var body: some View {
        ZStack {
            if projects.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.questionmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Projects Yet")
                        .font(.headline)
                    Text("Create a new project to get started")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(projects, id: \.id) { project in
                            NavigationLink(destination: CanvasView(project: project).environmentObject(projectStore)) {
                                ProjectCell(project: project)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            selectedProjectId = project.id
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            selectedProjectId = project.id
                                            renameText = project.name
                                            showRenameAlert = true
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isCreatingNewProject = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("New")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $isCreatingNewProject) {
            NewProjectView()
                .environmentObject(projectStore)
        }
        .navigationDestination(item: $newProject) { project in
            CanvasView(project: project)
                .environmentObject(projectStore)
        }
        .onAppear {
            DispatchQueue.main.async {
                projects = projectStore.listProjects()
                isLoading = false
            }
        }
        .alert("Rename Project", isPresented: $showRenameAlert, presenting: selectedProjectId) { projectId in
            TextField("Project Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                _ = projectStore.rename(projectId: projectId, newName: renameText)
                projects = projectStore.listProjects()
            }
        }
        .alert("Delete Project", isPresented: $showDeleteAlert, presenting: selectedProjectId) { projectId in
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                _ = projectStore.delete(projectId: projectId)
                projects = projectStore.listProjects()
            }
        } message: { _ in
            Text("This action cannot be undone.")
        }
    }
}

struct ProjectCell: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color(.systemGray6))
                .cornerRadius(8)

            Text(project.name)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(2)

            Text("Modified: \(project.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CanvasView: View {
    let project: Project
    @EnvironmentObject var projectStore: ProjectStore
    @State private var drawing: PKDrawing = PKDrawing()
    @State private var isDirty = false
    @State private var isSaving = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                            .font(.headline)
                        Text("Modified: \(project.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        if isDirty {
                            Text("Unsaved")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }

                        Button(action: saveDrawing) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                            }
                            .font(.caption)
                        }
                        .disabled(!isDirty || isSaving)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .border(Color(.systemGray4), width: 1)

                PKCanvasViewRepresentable(drawing: $drawing, isDirty: $isDirty)
            }

            if isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .navigationBarBackButtonHidden(false)
        .onAppear {
            loadDrawing()
        }
        .onDisappear {
            if isDirty {
                saveDrawing()
            }
        }
    }

    private func loadDrawing() {
        if let (_, loadedDrawing) = projectStore.loadProject(id: project.id) {
            drawing = loadedDrawing
        }
    }

    private func saveDrawing() {
        isSaving = true

        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = drawing.createThumbnail()
            let success = projectStore.save(project: project, drawing: drawing, thumbnail: thumbnail)

            DispatchQueue.main.async {
                isSaving = false
                if success {
                    isDirty = false
                }
            }
        }
    }
}

struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var isDirty: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.isOpaque = false
        canvas.backgroundColor = .systemBackground
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, isDirty: $isDirty)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        @Binding var isDirty: Bool

        init(drawing: Binding<PKDrawing>, isDirty: Binding<Bool>) {
            self._drawing = drawing
            self._isDirty = isDirty
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            isDirty = true
        }
    }
}

extension PKDrawing {
    func createThumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.systemBackground.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            guard !self.bounds.isEmpty else {
                return
            }

            let drawingBounds = self.bounds
            let aspectRatio = drawingBounds.width / drawingBounds.height
            let containerAspectRatio = size.width / size.height

            var targetRect = CGRect(origin: .zero, size: size)
            if aspectRatio > containerAspectRatio {
                let height = size.width / aspectRatio
                targetRect.origin.y = (size.height - height) / 2
                targetRect.size.height = height
            } else {
                let width = size.height * aspectRatio
                targetRect.origin.x = (size.width - width) / 2
                targetRect.size.width = width
            }

            let scale = targetRect.width / drawingBounds.width
            let scaledImage = self.image(from: drawingBounds, scale: scale)
            scaledImage.draw(in: targetRect)
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(ProjectStore())
}
