import Foundation
import SwiftUI
import os


struct SidebarSelection: Hashable {
    var folderID: UUID
    var requestID: UUID?
}


struct FormDataField: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isFile: Bool
    var isEnabled: Bool
    
    init(key: String, value: String, isFile: Bool = false, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isFile = isFile
        self.isEnabled = isEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case id, key, value, isFile, isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        isFile = try container.decode(Bool.self, forKey: .isFile)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}


enum HTTPMethod: String, CaseIterable, Codable {
    case GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS
}


enum RequestTab: String, CaseIterable {
    case body = "Body"
    case headers = "Headers"
}

enum RequestType: String, CaseIterable, Hashable, Codable {
    case json = "JSON"
    case urlEncoded = "URL Encoded"
    case multiPart = "Multi-Part"
}

struct HTTPHeader: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    var key: String
    var value: String
    var isEnabled: Bool
    
    init(key: String, value: String, isEnabled: Bool = true) {
        self.id = UUID()
        self.key = key
        self.value = value
        self.isEnabled = isEnabled
    }
    
    enum CodingKeys: String, CodingKey {
        case id, key, value, isEnabled
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        value = try container.decode(String.self, forKey: .value)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
    }
}

struct HTTPResponse: Identifiable, Hashable {
    /// Caches the decoded/pretty-printed body so rendering the response view does not
    /// re-run `JSONSerialization` on every SwiftUI update.
    private final class TextCache {
        var raw: String?
        var pretty: String?
    }
    
    let id: UUID = UUID()
    let statusCode: Int
    let headers: [HTTPHeader]
    let body: Data
    let responseTime: TimeInterval
    let size: Int
    let error: String?
    
    private let textCache = TextCache()
    
    func isJSON() -> Bool {
        return self.headers.contains(where: { $0.key.lowercased() == "content-type" && $0.value.lowercased().contains("application/json") })
    }
    
    func body(format: ResponseFormat = .pretty) -> String {
        switch format {
        case .raw:
            return rawText
        case .pretty:
            if let pretty = textCache.pretty {
                return pretty
            }
            let pretty: String
            if isJSON(), let formatted = Self.prettyPrinted(rawText) {
                pretty = formatted
            } else {
                pretty = rawText
            }
            textCache.pretty = pretty
            return pretty
        }
    }
    
    private var rawText: String {
        if let raw = textCache.raw {
            return raw
        }
        // `String(decoding:as:)` replaces malformed sequences instead of trapping,
        // unlike `String(data:encoding:)!`.
        let raw = String(decoding: body, as: UTF8.self)
        textCache.raw = raw
        return raw
    }
    
    private static func prettyPrinted(_ text: String) -> String? {
        guard let data = text.data(using: .utf8) else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed]) else {
            return nil
        }
        guard let prettyData = try? JSONSerialization.data(
            withJSONObject: object,
            options: [.prettyPrinted, .withoutEscapingSlashes, .fragmentsAllowed, .sortedKeys]
        ) else {
            return nil
        }
        return String(data: prettyData, encoding: .utf8)
    }
    
    static func == (lhs: HTTPResponse, rhs: HTTPResponse) -> Bool {
        lhs.id == rhs.id
            && lhs.statusCode == rhs.statusCode
            && lhs.headers == rhs.headers
            && lhs.body == rhs.body
            && lhs.responseTime == rhs.responseTime
            && lhs.size == rhs.size
            && lhs.error == rhs.error
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct HTTPRequest: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    /// Stored as text so partially-typed URLs do not need to be valid `URL` values.
    var url: String
    var headers: [HTTPHeader]
    var body: String
    var response: HTTPResponse?
    var bodyType: RequestType
    var formData: [FormDataField]
    var task: Task<Void, Never>?
    
    init(name: String, method: HTTPMethod, url: String, headers: [HTTPHeader] = [], body: String = "", bodyType: RequestType = .json, formData: [FormDataField] = []) {
        self.id = UUID()
        self.name = name
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.bodyType = bodyType
        self.formData = formData
    }
    
    init(name: String, method: HTTPMethod, url: URL, headers: [HTTPHeader] = [], body: String = "", bodyType: RequestType = .json, formData: [FormDataField] = []) {
        self.init(
            name: name,
            method: method,
            url: url.absoluteString,
            headers: headers,
            body: body,
            bodyType: bodyType,
            formData: formData
        )
    }
    
    func formatBody() -> String {
        if bodyType != .json { return body }
        guard !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return body }
        
        do {
            let data = body.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .withoutEscapingSlashes, .fragmentsAllowed, .sortedKeys])
            
            if let formattedString = String(data: prettyData, encoding: .utf8) {
                return formattedString
            }
        } catch {
            logger.error("Failed to serialize JSON: \(error)")
        }
        
        return body
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, method, url, headers, body, bodyType, formData
    }
}

struct RequestFolder: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var requests: [HTTPRequest]
    
    init(name: String, requests: [HTTPRequest] = []) {
        self.id = UUID()
        self.name = name
        self.requests = requests
    }
}

enum ResponseFormat: String, CaseIterable {
    case raw = "Raw"
    case pretty = "Pretty"
}

enum ResponseTab: String, CaseIterable {
    case body = "Body"
    case headers = "Headers"
}
