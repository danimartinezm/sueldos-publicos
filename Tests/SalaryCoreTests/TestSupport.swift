import Foundation

enum TestSupport {
    /// Absolute path to the repository root, derived from this source file's location
    /// (`<root>/Tests/SalaryCoreTests/TestSupport.swift`).
    static var repoRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()  // SalaryCoreTests
            .deletingLastPathComponent()  // Tests
            .deletingLastPathComponent()  // root
    }

    static var inputFileURL: URL {
        repoRoot.appendingPathComponent("Retribuciones.xlsx")
    }

    static func inputData() throws -> Data {
        try Data(contentsOf: inputFileURL)
    }
}
