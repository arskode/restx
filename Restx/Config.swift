import SwiftUI
import Combine
import AppKit
import os


class Config: ObservableObject, Codable {
    static let shared = Config.load()
    
    private static let configFileURL: URL = {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let configDirectory = homeDirectory
            .appendingPathComponent(".config")
            .appendingPathComponent("restx")
        
        try? fileManager.createDirectory(
            at: configDirectory,
            withIntermediateDirectories: true
        )
        
        return configDirectory.appendingPathComponent("config.json")
    }()
    
    private var saveTask: Task<Void, Never>?
    
    @Published var editorFontFamily: String {
        didSet { scheduleSave() }
    }
    @Published var editorFontSize: Double {
        didSet { scheduleSave() }
    }
    @Published var requestTimeout: Double {
        didSet { scheduleSave() }
    }
    
    var editorFont: Font {
        return Font.custom(editorFontFamily, size: CGFloat(editorFontSize))
    }
    
    enum CodingKeys: String, CodingKey {
        case editorFontFamily
        case editorFontSize
        case requestTimeout
    }
    
    required init(
        editorFontFamily: String = NSFont.monospacedSystemFont(ofSize: 14.0, weight: .regular).fontName,
        editorFontSize: Double = 14.0,
        requestTimeout: Double = 30.0
    ) {
        self.editorFontFamily = editorFontFamily
        self.editorFontSize = editorFontSize
        self.requestTimeout = requestTimeout
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        editorFontFamily = try container.decode(String.self, forKey: .editorFontFamily)
        editorFontSize = try container.decode(Double.self, forKey: .editorFontSize)
        requestTimeout = try container.decode(Double.self, forKey: .requestTimeout)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(editorFontFamily, forKey: .editorFontFamily)
        try container.encode(editorFontSize, forKey: .editorFontSize)
        try container.encode(requestTimeout, forKey: .requestTimeout)
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                performSave()
            }
        }
    }

    private func performSave() {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(self) else {
            logger.error("Failed to encode config")
            return
        }
        
        Task.detached(priority: .utility) {
            do {
                try await data.write(to: Self.configFileURL, options: .atomic)
            } catch {
                await logger.error("Failed to write config: \(error)")
            }
        }
    }
    
    private class func load() -> Self {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: configFileURL.path) {
            return Self()
        }
        
        do {
            let data = try Data(contentsOf: configFileURL)
            let decoder = JSONDecoder()
            let config = try decoder.decode(Self.self, from: data)
            return config
        } catch {
            logger.error("Failed to load config: \(error)")
            return Self()
        }
    }
}
