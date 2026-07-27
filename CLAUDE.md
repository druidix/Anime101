# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Anime101 is an iOS drawing application built with SwiftUI that allows users to create and edit anime projects with a PencilKit-based drawing canvas. The app supports project management (create, list, rename, delete) and freehand drawing with multiple tools (pencil, eraser).

## Technology Stack

- **UI Framework**: SwiftUI
- **Drawing**: PencilKit (Apple's native drawing framework)
- **Storage**: FileManager (local documents directory)
- **Testing**: XCTest
- **Build System**: Xcode

## Build & Run

**Open the project in Xcode:**
```bash
open Anime101.xcodeproj
```

**Build from the command line:**
```bash
xcodebuild build -scheme Anime101 -configuration Debug
```

**Run on simulator (11-inch iPad Pro):**
```bash
xcodebuild test -scheme Anime101 -destination 'platform=iOS Simulator,name=iPad Pro (11-inch)'
```

## Testing

**Run all tests (on 11-inch iPad Pro):**
```bash
xcodebuild test -scheme Anime101 -destination 'platform=iOS Simulator,name=iPad Pro (11-inch)'
```

**Run a specific test class:**
```bash
xcodebuild test -scheme Anime101 -only-testing Anime101Tests/ProjectStoreTests
```

**Run tests in Xcode:** Cmd+U or Product > Test

## Architecture

The app follows a simplified MVVM pattern with SwiftUI's reactive architecture:

### Models (`/Models`)
- **Project**: Codable struct representing a project with `id`, `name`, `createdAt`, `modifiedAt`. Conforms to Identifiable and Hashable for SwiftUI collections.

### Storage (`/Storage`)
- **ProjectStore**: ObservableObject managing all file I/O operations. Handles CRUD operations for projects and drawings.
  - Files are stored in `Documents/Projects/{UUID}/`
  - Each project contains: `metadata.json` (Project data), `drawing.data` (PencilKit PKDrawing), `thumbnail.png` (preview image)
  - Uses JSONEncoder/JSONDecoder with ISO8601 date strategy for metadata

### Views (`/`)
- **Anime101App**: Entry point with ProjectStore injected as environment object
- **MainMenuView**: Welcome screen with navigation to project list or creation
- **ProjectListView**: Grid view of all projects with rename/delete context menu
- **NewProjectView**: Project name input form
- **CanvasView**: Main drawing interface with PencilKit PKCanvasView
- **ProjectListViewModel**: Manages project list state and interactions

### Drawing Tools
- **DrawingTool** enum: Defines pencil and eraser tools
  - Maps to PencilKit's `PKInkingTool` (pen) and `PKEraserTool` (bitmap)
  - Tools can be switched via toolbar in CanvasView

## Key Implementation Details

### Project Storage
Projects are stored hierarchically with metadata separated from drawing data:
- Metadata is human-readable JSON for easy inspection and debugging
- Drawing data uses PencilKit's native binary format for reliability
- Thumbnails are cached PNG images for list view previews

### Drawing Canvas
The CanvasView integrates PencilKit's PKCanvasView:
- Supports tool switching (pencil ↔ eraser)
- Saves drawing on dismiss
- Generates thumbnail on save for list view

### Environment Object Pattern
`ProjectStore` is passed down as an environment object to avoid prop drilling through the navigation hierarchy. This allows any view to access and modify projects.

## Recent Milestones

- **Milestone 4** (957b01c): Eraser Tool & Tool Switching
- **Milestone 3** (b102258): PencilKit drawing canvas implementation
- **Milestone 1** (aa3126e): Data model and local storage layer

## Common Tasks

**Adding a new drawing tool:**
1. Add case to `DrawingTool` enum in ContentView.swift
2. Implement `pkTool` computed property to return corresponding PKTool
3. Add UI button in CanvasView toolbar

**Modifying storage structure:**
ProjectStore uses URLs computed from project UUIDs. Changing file organization requires updates to the URL helper methods (`projectDirectoryURL`, `drawingDataURL`, `metadataURL`, `thumbnailURL`).

**Testing storage operations:**
All storage tests use the actual Documents directory (consider injecting path for isolation). Tests clean up after themselves in `tearDown()`.

## Orientation Support

The app supports both portrait and landscape modes (configured in Info.plist via scheme).
