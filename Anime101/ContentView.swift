import SwiftUI

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

                    NavigationLink(isActive: $isCreatingNewProject) {
                        NewProjectView()
                            .environmentObject(projectStore)
                    } label: {
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
            CanvasStubView(project: createdProject)
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

                VStack(spacing: 16) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Canvas - Coming Soon")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("PencilKit drawing integration will be implemented here")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(8)

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
                            NavigationLink(destination: CanvasStubView(project: project)) {
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
                NavigationLink(isActive: $isCreatingNewProject) {
                    NewProjectView()
                        .environmentObject(projectStore)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("New")
                    }
                }
            }
        }
        .navigationDestination(item: $newProject) { project in
            CanvasStubView(project: project)
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

struct CanvasStubView: View {
    let project: Project

    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project Name")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(project.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Project ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(project.id.uuidString)
                        .font(.caption)
                        .monospaced()
                        .foregroundStyle(.secondary)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Created")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(project.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last Modified")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(project.modifiedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)

            VStack(spacing: 16) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)
                Text("Canvas - Coming Soon")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("PencilKit drawing integration will be implemented here")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .navigationTitle(project.name)
    }
}

#Preview {
    MainMenuView()
        .environmentObject(ProjectStore())
}
