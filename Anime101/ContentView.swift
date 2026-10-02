import SwiftUI
import PencilKit
import UIKit

final class CanvasViewHolder: NSObject {
    var canvasView: PKCanvasView?

    var canUndo: Bool {
        canvasView?.undoManager?.canUndo ?? false
    }

    var canRedo: Bool {
        canvasView?.undoManager?.canRedo ?? false
    }

    func undo() {
        canvasView?.undoManager?.undo()
    }

    func redo() {
        canvasView?.undoManager?.redo()
    }
}

enum DrawingTool: CaseIterable {
    case pencil
    case eraser

    var label: String {
        switch self {
        case .pencil:
            return "Pencil"
        case .eraser:
            return "Eraser"
        }
    }

    var systemImage: String {
        switch self {
        case .pencil:
            return "pencil"
        case .eraser:
            return "eraser"
        }
    }

    func pkTool(style: ToolStyle = ToolStyle()) -> PKTool {
        switch self {
        case .pencil:
            return PKInkingTool(.pen, color: style.color.uiColor, width: CGFloat(style.pencilWidth))
        case .eraser:
            return PKEraserTool(.bitmap, width: CGFloat(style.eraserWidth))
        }
    }
}

/// Color and widths applied to the drawing tools. Color and pencil width affect only the pencil.
struct ToolStyle: Equatable {
    var color: RGBAColor = .black
    var pencilWidth: Double = StrokeWidths.pencilDefault
    var eraserWidth: Double = StrokeWidths.eraserDefault
}

enum StylePanel {
    case color
    case width
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

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var selectedProjectId: UUID?
    @State private var renameText = ""
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
        .onAppear {
            projects = projectStore.listProjects()
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

struct InteractivePopGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        DisablingViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    private final class DisablingViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
}

struct CanvasView: View {
    @EnvironmentObject var projectStore: ProjectStore
    @State private var currentProject: Project
    @State private var drawing: PKDrawing = PKDrawing()
    @State private var isDirty = false
    @State private var isSaving = false
    @State private var currentTool: DrawingTool = .pencil
    @State private var canUndo = false
    @State private var canRedo = false
    @State private var canvasViewHolder = CanvasViewHolder()
    @State private var autosaveController = AutosaveController()
    @State private var showSaveAsAlert = false
    @State private var saveAsName = ""
    @State private var activeColor: RGBAColor = .black
    @State private var showColorPanel = false
    @State private var showWidthPanel = false
    @State private var colorPanelOffset = FloatingPanel<EmptyView>.restingOffset
    @State private var widthPanelOffset = FloatingPanel<EmptyView>.restingOffset
    @State private var frontPanel: StylePanel = .color

    @Environment(\.dismiss) var dismiss

    init(project: Project) {
        _currentProject = State(initialValue: project)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentProject.name)
                            .font(.headline)
                        Text("Modified: \(currentProject.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
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

                        Button(action: undo) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.caption)
                        }
                        .disabled(!canUndo)

                        Button(action: redo) {
                            Image(systemName: "arrow.uturn.forward")
                                .font(.caption)
                        }
                        .disabled(!canRedo)

                        Button(action: manualSave) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save")
                            }
                            .font(.caption)
                        }
                        .disabled(!isDirty || isSaving)

                        Button(action: {
                            saveAsName = currentProject.name
                            showSaveAsAlert = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "square.and.arrow.down")
                                Text("Save As")
                            }
                            .font(.caption)
                        }
                        .disabled(isSaving)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .border(Color(.systemGray4), width: 1)

                VStack(spacing: 0) {
                    toolRow
                    canvasArea
                }
            }

            if isSaving {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
        .background(InteractivePopGestureDisabler())
        .onAppear {
            loadDrawing()
            autosaveController.onActivitySave = { performAutosave(force: false) }
            autosaveController.onBackstopSave = { performAutosave(force: true) }
            autosaveController.start()
        }
        .onDisappear {
            autosaveController.stop()
            if isDirty {
                saveDrawing()
            }
        }
        .alert("Save As", isPresented: $showSaveAsAlert) {
            TextField("Project Name", text: $saveAsName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                saveAs(name: saveAsName)
            }
        } message: {
            Text("Enter a name to save this project as.")
        }
    }

    // MARK: - Tool row and panels

    private var toolStyle: ToolStyle {
        ToolStyle(
            color: activeColor,
            pencilWidth: currentProject.effectivePencilWidth,
            eraserWidth: currentProject.effectiveEraserWidth
        )
    }

    private var activeToolWidth: Double {
        switch currentTool {
        case .pencil: return currentProject.effectivePencilWidth
        case .eraser: return currentProject.effectiveEraserWidth
        }
    }

    private var toolRow: some View {
        HStack(spacing: 16) {
            Picker("Tool", selection: $currentTool) {
                ForEach(DrawingTool.allCases, id: \.self) { tool in
                    Label(tool.label, systemImage: tool.systemImage)
                        .tag(tool)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 260)

            Spacer()

            Button(action: { openPanel(.color) }) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(activeColor.swiftUIColor)
                        .overlay(Circle().strokeBorder(Color(.separator)))
                        .frame(width: 22, height: 22)
                    Text("Color")
                }
            }
            .accessibilityLabel("Color, current \(activeColor.hexString)")

            Button(action: { openPanel(.width) }) {
                HStack(spacing: 6) {
                    Image(systemName: "lineweight")
                    Text("Width \(Int(activeToolWidth)) pt")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }

    private var canvasArea: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                PKCanvasViewRepresentable(
                    drawing: $drawing,
                    isDirty: $isDirty,
                    currentTool: $currentTool,
                    canUndo: $canUndo,
                    canRedo: $canRedo,
                    canvasViewHolder: canvasViewHolder,
                    toolStyle: toolStyle,
                    onPencilStrokeEnded: recordActiveColor
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)

                if showColorPanel {
                    FloatingPanel(
                        title: "Color",
                        containerSize: geometry.size,
                        offset: $colorPanelOffset,
                        onClose: { closePanel(.color) },
                        onInteract: { frontPanel = .color }
                    ) {
                        ColorPickerPanelContent(color: $activeColor, recentColors: currentProject.recentColors)
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(frontPanel == .color ? 2 : 1)
                }

                if showWidthPanel {
                    FloatingPanel(
                        title: "\(currentTool.label) Width",
                        containerSize: geometry.size,
                        offset: $widthPanelOffset,
                        onClose: { closePanel(.width) },
                        onInteract: { frontPanel = .width }
                    ) {
                        WidthPickerPanelContent(
                            tool: currentTool,
                            selectedWidth: activeToolWidth,
                            inkColor: activeColor.swiftUIColor,
                            onSelect: selectWidth
                        )
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(frontPanel == .width ? 2 : 1)
                }
            }
            .clipped()
        }
    }

    /// Opens a panel at its resting position. If it is already open, it just comes to the front;
    /// panels close only via their X.
    private func openPanel(_ panel: StylePanel) {
        frontPanel = panel
        switch panel {
        case .color:
            guard !showColorPanel else { return }
            colorPanelOffset = FloatingPanel<EmptyView>.restingOffset
            withAnimation(.easeOut(duration: 0.25)) { showColorPanel = true }
        case .width:
            guard !showWidthPanel else { return }
            widthPanelOffset = FloatingPanel<EmptyView>.restingOffset
            withAnimation(.easeOut(duration: 0.25)) { showWidthPanel = true }
        }
    }

    private func closePanel(_ panel: StylePanel) {
        withAnimation(.easeIn(duration: 0.2)) {
            switch panel {
            case .color: showColorPanel = false
            case .width: showWidthPanel = false
            }
        }
    }

    /// Width changes apply to the active tool only and persist with the project.
    private func selectWidth(_ width: Double) {
        switch currentTool {
        case .pencil: currentProject.pencilWidth = width
        case .eraser: currentProject.eraserWidth = width
        }
        isDirty = true
    }

    /// Called when a pencil stroke ends. A color joins the history only once it has been drawn with,
    /// and undo never removes it.
    private func recordActiveColor() {
        let updated = RecentColors.recording(activeColor, in: currentProject.recentColors)
        guard updated != currentProject.recentColors else { return }
        currentProject.recentColors = updated
        isDirty = true
    }

    // MARK: - Persistence

    private func loadDrawing() {
        if let (loadedProject, loadedDrawing) = projectStore.loadProject(id: currentProject.id) {
            currentProject = loadedProject
            drawing = loadedDrawing
        }
        activeColor = currentProject.initialActiveColor
    }

    /// Autosave entry point. The 10s activity timer only saves when dirty; the 60s
    /// backstop timer saves unconditionally to cover the idle case.
    private func performAutosave(force: Bool) {
        guard force || isDirty else { return }
        saveDrawing(showsSpinner: false)
    }

    private func manualSave() {
        saveDrawing()
        autosaveController.resetTimers()
    }

    /// Creates a new, independent project with the given name and switches the canvas to it,
    /// leaving the original project untouched on disk.
    private func saveAs(name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        currentProject = currentProject.copy(named: trimmedName)
        saveDrawing()
        autosaveController.resetTimers()
    }

    private func saveDrawing(showsSpinner: Bool = true) {
        if showsSpinner {
            isSaving = true
        }

        var projectSnapshot = currentProject
        projectSnapshot.modifiedAt = Date()
        let drawingSnapshot = drawing

        DispatchQueue.global(qos: .userInitiated).async {
            let thumbnail = drawingSnapshot.createThumbnail()
            let success = projectStore.save(project: projectSnapshot, drawing: drawingSnapshot, thumbnail: thumbnail)

            DispatchQueue.main.async {
                if showsSpinner {
                    isSaving = false
                }
                guard success, currentProject.id == projectSnapshot.id else { return }
                currentProject.modifiedAt = projectSnapshot.modifiedAt
                // Only clear the dirty flag if nothing changed while the save was running;
                // otherwise those changes would wait for the 60s backstop.
                if drawing == drawingSnapshot && currentProject == projectSnapshot {
                    isDirty = false
                }
            }
        }
    }

    private func undo() {
        canvasViewHolder.undo()
        updateUndoRedoState()
    }

    private func redo() {
        canvasViewHolder.redo()
        updateUndoRedoState()
    }

    private func updateUndoRedoState() {
        canUndo = canvasViewHolder.canUndo
        canRedo = canvasViewHolder.canRedo
    }
}

struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    @Binding var isDirty: Bool
    @Binding var currentTool: DrawingTool
    @Binding var canUndo: Bool
    @Binding var canRedo: Bool
    let canvasViewHolder: CanvasViewHolder
    let toolStyle: ToolStyle
    let onPencilStrokeEnded: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        canvas.isOpaque = false
        // Locked to light mode: in dark mode PencilKit remaps black/white ink, so drawn colors
        // would not match the picked color.
        canvas.overrideUserInterfaceStyle = .light
        canvas.backgroundColor = .white
        canvas.isUserInteractionEnabled = true
        canvas.drawingPolicy = .anyInput
        canvas.tool = currentTool.pkTool(style: toolStyle)

        canvas.undoManager?.levelsOfUndo = 50
        canvasViewHolder.canvasView = canvas

        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        uiView.tool = currentTool.pkTool(style: toolStyle)
        context.coordinator.onPencilStrokeEnded = onPencilStrokeEnded
    }

    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(drawing: $drawing, isDirty: $isDirty, canUndo: $canUndo, canRedo: $canRedo)
        coordinator.onPencilStrokeEnded = onPencilStrokeEnded
        return coordinator
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        @Binding var isDirty: Bool
        @Binding var canUndo: Bool
        @Binding var canRedo: Bool
        var onPencilStrokeEnded: () -> Void = {}

        init(drawing: Binding<PKDrawing>, isDirty: Binding<Bool>, canUndo: Binding<Bool>, canRedo: Binding<Bool>) {
            self._drawing = drawing
            self._isDirty = isDirty
            self._canUndo = canUndo
            self._canRedo = canRedo
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            isDirty = true
            canUndo = canvasView.undoManager?.canUndo ?? false
            canRedo = canvasView.undoManager?.canRedo ?? false
        }

        /// Fires when the user lifts after a stroke, not on undo/redo or programmatic changes.
        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            if canvasView.tool is PKInkingTool {
                onPencilStrokeEnded()
            }
        }
    }
}

extension PKDrawing {
    func createThumbnail(size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false

        // Render in light mode to match the canvas, regardless of the device appearance.
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        var image = UIImage()
        lightTraits.performAsCurrent {
            image = renderThumbnail(size: size, format: format)
        }
        return image
    }

    private func renderThumbnail(size: CGSize, format: UIGraphicsImageRendererFormat) -> UIImage {
        UIGraphicsImageRenderer(size: size, format: format).image { _ in
            UIColor.white.setFill()
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
