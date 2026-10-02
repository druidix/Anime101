import Foundation

struct Project: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var modifiedAt: Date
    /// Colors previously drawn with in this project, most recent first (max `RecentColors.capacity`).
    var recentColors: [RGBAColor]
    /// nil means the user never changed it; use `StrokeWidths.pencilDefault`.
    var pencilWidth: Double?
    /// nil means the user never changed it; use `StrokeWidths.eraserDefault`.
    var eraserWidth: Double?

    init(
        id: UUID,
        name: String,
        createdAt: Date,
        modifiedAt: Date,
        recentColors: [RGBAColor] = [],
        pencilWidth: Double? = nil,
        eraserWidth: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.recentColors = recentColors
        self.pencilWidth = pencilWidth
        self.eraserWidth = eraserWidth
    }

    /// Projects saved before Milestone 7 have no color/width keys in `metadata.json`,
    /// so those keys are decoded as optional.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        recentColors = try container.decodeIfPresent([RGBAColor].self, forKey: .recentColors) ?? []
        pencilWidth = try container.decodeIfPresent(Double.self, forKey: .pencilWidth)
        eraserWidth = try container.decodeIfPresent(Double.self, forKey: .eraserWidth)
    }

    var effectivePencilWidth: Double { pencilWidth ?? StrokeWidths.pencilDefault }
    var effectiveEraserWidth: Double { eraserWidth ?? StrokeWidths.eraserDefault }

    /// The color that is active when the project opens: the most recent history color, or black.
    var initialActiveColor: RGBAColor { recentColors.first ?? .black }

    /// An independent copy for "Save As": new identity and dates, same colors and widths.
    func copy(named name: String, at date: Date = Date()) -> Project {
        Project(
            id: UUID(),
            name: name,
            createdAt: date,
            modifiedAt: date,
            recentColors: recentColors,
            pencilWidth: pencilWidth,
            eraserWidth: eraserWidth
        )
    }
}
