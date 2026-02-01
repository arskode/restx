import Foundation
import os
import Combine
import SwiftUI

let logger = Logger(subsystem: "com.arskode.restx", category: "application")


class Service: ObservableObject {
    @Published var requestFolders: [RequestFolder] = []
    private let fileManager = FileManager.default
    private var saveTask: Task<Void, Never>?
    
    private var collectionsFileURL: URL {
        let documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let appFolder = documents.appendingPathComponent("restx")
        try? fileManager.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )
        
        return appFolder.appendingPathComponent("collections.json")
    }
    
    init() {
        load()
    }
    
    @MainActor
    func addRequestToFolder(folderID: UUID) -> UUID? {
        let request = HTTPRequest(
            name: "HTTP Request",
            method: .GET,
            url: URL(string: "https://httpbin.org/get")!,
            headers: [ HTTPHeader(key: "Content-Type", value: "application/json")],
            body: ""
        )
        
        if let index = requestFolders.firstIndex(where: { $0.id == folderID }) {
            requestFolders[index].requests.insert(request, at: 0)
            scheduleSave()
            return request.id
        }
        return nil
    }
    
    @MainActor
    func deleteRequest(folderID: UUID, requestID: UUID) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests.remove(at: requestIndex)
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func duplicateRequest(folderID: UUID, requestID: UUID) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                let request = requestFolders[folderIndex].requests[requestIndex]
                let newRequest = HTTPRequest(
                    name: request.name + " Copy",
                    method: request.method,
                    url: request.url,
                    headers: request.headers,
                    body: request.body,
                    bodyType: request.bodyType,
                    formData: request.formData
                )
                requestFolders[folderIndex].requests.insert(newRequest, at: requestIndex + 1)
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func renameRequest(folderID: UUID, requestID: UUID, name: String) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].name = name
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func deleteFolder(folderID: UUID) -> Void {
        requestFolders.removeAll(where: { $0.id == folderID })
        scheduleSave()
    }
    
    @MainActor
    func renameFolder(folderID: UUID, name: String) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            requestFolders[folderIndex].name = name
            scheduleSave()
        }
    }
    
    @MainActor
    func moveRequests(folderID: UUID, fromOffsets: IndexSet, toOffset: Int) {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID })  {
            requestFolders[folderIndex].requests.move(fromOffsets: fromOffsets, toOffset: toOffset)
            scheduleSave()
        }
    }
    
    func getRequest(folderID: UUID, requestID: UUID) -> HTTPRequest? {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                return requestFolders[folderIndex].requests[requestIndex]
            }
        }
        return nil
    }
    
    @MainActor
    func setRequestMethod(folderID: UUID, requestID: UUID, method: HTTPMethod) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].method = method
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func setRequestUrl(folderID: UUID, requestID: UUID, url: String) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].url = URL(string: url)!
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func setRequestBodyType(folderID: UUID, requestID: UUID, bodyType: RequestType) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].bodyType = bodyType
                
                var newHeader = HTTPHeader(key: "Content-Type", value: "")
                switch bodyType {
                case .json:
                    newHeader.value = "application/json"
                case .urlEncoded:
                    newHeader.value = "application/x-www-form-urlencoded"
                case .multiPart:
                    newHeader.value = "multipart/form-data"
                }
                
                if let headerIndex = requestFolders[folderIndex].requests[requestIndex].headers.firstIndex(where: { $0.key.lowercased() == "content-type"}) {
                        requestFolders[folderIndex].requests[requestIndex].headers[headerIndex] = newHeader
                } else {
                    requestFolders[folderIndex].requests[requestIndex].headers.append(newHeader)
                }
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func setRequestHeader(folderID: UUID, requestID: UUID, headerID: UUID, key: String? = nil, value: String? = nil) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let headerIndex = requestFolders[folderIndex].requests[requestIndex].headers.firstIndex(where: { $0.id == headerID} ) {
                    if let key = key {
                        requestFolders[folderIndex].requests[requestIndex].headers[headerIndex].key = key
                    }
                    if let value = value {
                        requestFolders[folderIndex].requests[requestIndex].headers[headerIndex].value = value
                    }
                    scheduleSave()
                }
            }
        }
    }
    
    @MainActor
    func toggleRequestHeader(folderID: UUID, requestID: UUID, headerID: UUID, isEnabled: Bool) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let headerIndex = requestFolders[folderIndex].requests[requestIndex].headers.firstIndex(where: { $0.id == headerID} ) {
                    requestFolders[folderIndex].requests[requestIndex].headers[headerIndex].isEnabled = isEnabled
                    scheduleSave()
                }
            }
        }
    }
    
    @MainActor
    func deleteRequestHeader(folderID: UUID, requestID: UUID, headerID: UUID) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let headerIndex = requestFolders[folderIndex].requests[requestIndex].headers.firstIndex(where: { $0.id == headerID} ) {
                    requestFolders[folderIndex].requests[requestIndex].headers.remove(at: headerIndex)
                    scheduleSave()
                }
            }
        }
    }
    
    @MainActor
    func addRequestHeader(folderID: UUID, requestID: UUID) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].headers.append(HTTPHeader( key: "", value: ""))
                scheduleSave()
            }
        }
    }
    
    @MainActor
    func setRequestBody(folderID: UUID, requestID: UUID, body: String) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].body = body
                scheduleSave()
            }
        }
    }

    @MainActor
    func callRequest(folderID: UUID, requestID: UUID) async {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                let req = requestFolders[folderIndex].requests[requestIndex]
                requestFolders[folderIndex].requests[requestIndex].response = nil
                
                let task = Task {
                    do {
                        var request = URLRequest(url: req.url)
                        request.httpMethod = req.method.rawValue
                        request.timeoutInterval = Config.shared.requestTimeout
                        for header in req.headers where header.isEnabled {
                            if !header.key.isEmpty {
                                request.addValue(header.value, forHTTPHeaderField: header.key)
                            }
                        }
                        
                        switch req.bodyType {
                        case .json:
                            if !req.body.isEmpty && req.method != .GET {
                                request.httpBody = req.body.data(using: .utf8)!
                            }
                        case .urlEncoded:
                            if !req.formData.isEmpty && req.method != .GET {
                                let urlEncodedString = req.formData
                                    .filter { !$0.key.isEmpty && !$0.isFile && $0.isEnabled }
                                    .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }
                                    .joined(separator: "&")
                                request.httpBody = urlEncodedString.data(using: .utf8)!
                            }
                            
                        case .multiPart:
                            let validFormFields = req.formData.filter({ !$0.key.isEmpty && $0.isEnabled })
                            if !validFormFields.isEmpty && req.method != .GET {
                                let boundary = "----Boundary\(UUID())"
                                request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                                
                                var body = Data()
                                for field in validFormFields {
                                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                                    
                                    if field.isFile {
                                        do {
                                            let fileURL = URL(fileURLWithPath: field.value)
                                            let isAccessing = fileURL.startAccessingSecurityScopedResource()
                                            defer {
                                                if isAccessing {
                                                    fileURL.stopAccessingSecurityScopedResource()
                                                }
                                            }
                                            
                                            let fileData = try Data(contentsOf: fileURL)
                                            let fileName = fileURL.lastPathComponent
                                            let mimeType = getMimeType(for: fileURL)
                                            
                                            body.append("Content-Disposition: form-data; name=\"\(field.key)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
                                            body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
                                            body.append(fileData)
                                            body.append("\r\n".data(using: .utf8)!)
                                        } catch {
                                            throw error
                                        }
                                    } else {
                                        body.append("Content-Disposition: form-data; name=\"\(field.key)\"\r\n\r\n".data(using: .utf8)!)
                                        body.append("\(field.value)\r\n".data(using: .utf8)!)
                                    }
                                }
                                body.append("--\(boundary)--\r\n".data(using: .utf8)!)
                                request.httpBody = body
                            }
                        }
                        
                        let startTime = CFAbsoluteTimeGetCurrent()
                        let (data, response) = try await URLSession.shared.data(for: request)
                        let responseTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
                        
                        let httpResponse = response as! HTTPURLResponse
                        let responseHeaders = httpResponse.allHeaderFields.compactMap { (key, value) -> HTTPHeader? in guard let k = key as? String, let v = value as? String else { return nil }
                            return HTTPHeader(key: k, value: v)
                        }
                        
                        requestFolders[folderIndex].requests[requestIndex].response = HTTPResponse(
                            statusCode: httpResponse.statusCode,
                            headers: responseHeaders,
                            body: data,
                            responseTime: responseTime,
                            size: data.count,
                            error: nil
                        )
                        requestFolders[folderIndex].requests[requestIndex].task = nil
                    } catch {
                        let errorMessage = error.localizedDescription
                        requestFolders[folderIndex].requests[requestIndex].response  = HTTPResponse(
                            statusCode: 0,
                            headers: [],
                            body: Data(),
                            responseTime: 0,
                            size: 0,
                            error: errorMessage
                        )
                        requestFolders[folderIndex].requests[requestIndex].task = nil
                    }
                }
                requestFolders[folderIndex].requests[requestIndex].task = task
            }
        }
    }
    
    @MainActor
    func cancelRequest(folderID: UUID, requestID: UUID) {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].task?.cancel()
                requestFolders[folderIndex].requests[requestIndex].task = nil

                // to prevent showing the old response and `no response yet` message
                requestFolders[folderIndex].requests[requestIndex].response = HTTPResponse(
                    statusCode: 0,
                    headers: [],
                    body: Data(),
                    responseTime: 0,
                    size: 0,
                    error: "Cancelled"
                )
            }
        }
    }
    
    @MainActor
    func setFormData(folderID: UUID, requestID: UUID, formID: UUID, key: String? = nil, value: String? = nil, isFile: Bool? = nil) {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let formIndex = requestFolders[folderIndex].requests[requestIndex].formData.firstIndex(where: { $0.id == formID} ) {
                        if let key = key {
                            requestFolders[folderIndex].requests[requestIndex].formData[formIndex].key = key
                        }
                        if let value = value {
                            requestFolders[folderIndex].requests[requestIndex].formData[formIndex].value = value
                        }
                        if let isFile = isFile {
                            requestFolders[folderIndex].requests[requestIndex].formData[formIndex].isFile = isFile
                        }
                        scheduleSave()
                }
            }
        }
    }
    
    @MainActor
    func toggleFormData(folderID: UUID, requestID: UUID, formID: UUID, isEnabled: Bool) {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let formIndex = requestFolders[folderIndex].requests[requestIndex].formData.firstIndex(where: { $0.id == formID} ) {
                    requestFolders[folderIndex].requests[requestIndex].formData[formIndex].isEnabled = isEnabled
                    scheduleSave()
                }
            }
        }
    }
    
    
    @MainActor
    func deleteRequestFormDataItem(folderID: UUID, requestID: UUID, formID: UUID) {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                if let formIndex = requestFolders[folderIndex].requests[requestIndex].formData.firstIndex(where: { $0.id == formID} ) {
                    requestFolders[folderIndex].requests[requestIndex].formData.remove(at: formIndex)
                    scheduleSave()
                }
            }
        }
    }
    
    
    @MainActor
    func addRequestFormData(folderID: UUID, requestID: UUID, isFile: Bool = false) -> Void {
        if let folderIndex = requestFolders.firstIndex(where: { $0.id == folderID }) {
            if let requestIndex = requestFolders[folderIndex].requests.firstIndex(where: { $0.id == requestID }) {
                requestFolders[folderIndex].requests[requestIndex].formData.append(FormDataField( key: "", value: "", isFile: isFile))
                scheduleSave()
            }
        }
    }
    
    
    @MainActor
    func addFolder() -> RequestFolder {
        let folder = RequestFolder(name: "Untitled", requests: [])
        requestFolders.insert(folder, at: 0)
        scheduleSave()
        
        return folder
    }
    
    @MainActor
    func moveFolders(fromOffsets: IndexSet, toOffset: Int) {
        requestFolders.move(fromOffsets: fromOffsets, toOffset: toOffset)
        scheduleSave()
    }
    
    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            if !Task.isCancelled {
                save()
            }
        }
    }
    
    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes, .sortedKeys,]
            let data = try encoder.encode(requestFolders)
            try data.write(to: collectionsFileURL, options: .atomic)
            logger.debug("Saved collections to: \(self.collectionsFileURL.path)")
        } catch {
            logger.error("Failed to save collections: \(error)")
        }
    }
    
    private func load() {
        if !fileManager.fileExists(atPath: collectionsFileURL.path) {
            return
        }
        
        do {
            let data = try Data(contentsOf: collectionsFileURL)
            let decoder = JSONDecoder()
            let folders = try decoder.decode([RequestFolder].self, from: data)
            self.requestFolders = folders
        } catch {
            logger.error("Failed to load collections: \(error)")
        }
    }
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "svg":
            return "image/svg+xml"
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "json":
            return "application/json"
        case "xml":
            return "application/xml"
        case "html", "htm":
            return "text/html"
        case "css":
            return "text/css"
        case "js":
            return "application/javascript"
        case "zip":
            return "application/zip"
        case "tar":
            return "application/x-tar"
        case "gz":
            return "application/gzip"
        case "mp4":
            return "video/mp4"
        case "mov":
            return "video/quicktime"
        case "avi":
            return "video/x-msvideo"
        case "mp3":
            return "audio/mpeg"
        case "wav":
            return "audio/wav"
        case "csv":
            return "text/csv"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        default:
            return "application/octet-stream"
        }
    }
}
