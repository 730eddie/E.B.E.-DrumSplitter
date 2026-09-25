import Foundation

actor DrumSeparationService {
    enum SeparationError: LocalizedError {
        case missingInput
        case processingFailed

        var errorDescription: String? {
            switch self {
            case .missingInput: return "Choose an audio file first."
            case .processingFailed: return "The audio could not be processed."
            }
        }
    }

    /// Placeholder pipeline. Replace this implementation with a Core ML model
    /// (or a licensed/server-side separator) that outputs true drum stems.
    func separate(inputURL: URL, kinds: [DrumStem.Kind]) async throws -> [DrumStem] {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw SeparationError.missingInput
        }

        let outputFolder = FileManager.default.temporaryDirectory
            .appendingPathComponent("EBE-DrumSplitter", isDirectory: true)
        try? FileManager.default.createDirectory(at: outputFolder, withIntermediateDirectories: true)

        var stems: [DrumStem] = []
        for kind in kinds {
            try Task.checkCancellation()
            let safeName = kind.rawValue.replacingOccurrences(of: "/", with: "-")
            let destination = outputFolder.appendingPathComponent("\(safeName).m4a")
            try? FileManager.default.removeItem(at: destination)
            do {
                // Keeps the UI/export flow functional until the ML separator is integrated.
                try FileManager.default.copyItem(at: inputURL, to: destination)
                stems.append(DrumStem(kind: kind, outputURL: destination))
            } catch {
                throw SeparationError.processingFailed
            }
        }
        return stems
    }
}
