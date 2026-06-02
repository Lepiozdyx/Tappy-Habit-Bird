import Foundation

enum HabitStoreError: LocalizedError {
    case saveFailed
    case loadFailed

    var errorDescription: String? {
        switch self {
        case .saveFailed: "The game cartridge could not be saved. Please try again."
        case .loadFailed: "The saved game could not be loaded. A fresh board is ready."
        }
    }
}

struct HabitStore: Sendable {
    private let fileURL: URL

    nonisolated init(fileManager: FileManager = .default) {
        let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        self.fileURL = (directory ?? URL(fileURLWithPath: NSTemporaryDirectory()))
            .appendingPathComponent("tappy_habits.json")
    }

    nonisolated func load() async throws -> [Habit] {
        try await Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return []
            }

            do {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode([Habit].self, from: data)
            } catch {
                throw HabitStoreError.loadFailed
            }
        }.value
    }

    nonisolated func save(_ habits: [Habit]) async throws {
        try await Task.detached(priority: .utility) {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(habits)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                throw HabitStoreError.saveFailed
            }
        }.value
    }
}
