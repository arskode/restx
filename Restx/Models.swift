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
    let id: UUID = UUID()
    let statusCode: Int
    let headers: [HTTPHeader]
    let body: Data
    let responseTime: TimeInterval
    let size: Int
    let error: String?
    
    func isJSON() -> Bool {
        return self.headers.contains(where: { $0.key.lowercased() == "content-type" && $0.value.lowercased().contains("application/json") })
    }
    
    func body(format: ResponseFormat = .pretty) -> String {
        if format == .pretty {
            if self.isJSON() {
                do {
                    let object = try JSONSerialization.jsonObject(with: self.body, options: [])
                    let prettyData = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .withoutEscapingSlashes, .fragmentsAllowed, .sortedKeys])
                    return String(data: prettyData, encoding: .utf8)!
                } catch {
                    return String(data: self.body, encoding: .utf8)!
                }
            }
        }
        
        return String(data: self.body, encoding: .utf8)!
    }
}

struct HTTPRequest: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    var url: URL
    var headers: [HTTPHeader]
    var body: String
    var response: HTTPResponse?
    var bodyType: RequestType
    var formData: [FormDataField]
    var task: Task<Void, Never>?
    
    init(name: String, method: HTTPMethod, url: URL, headers: [HTTPHeader] = [], body: String = "", bodyType: RequestType = .json, formData: [FormDataField] = []) {
        self.id = UUID()
        self.name = name
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.bodyType = bodyType
        self.formData = formData
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
