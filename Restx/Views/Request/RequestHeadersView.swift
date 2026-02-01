import SwiftUI

struct RequestHeadersView: View {
    @ObservedObject var service: Service
    let request: HTTPRequest
    let folderID: UUID
    
    var body: some View {
        ScrollView(showsIndicators: false){
            LazyVStack(spacing: 8) {
                ForEach(Array(request.headers.enumerated()), id: \.element.id) { _, header in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { header.isEnabled },
                            set: { newValue in service.toggleRequestHeader(folderID: folderID, requestID: request.id, headerID: header.id, isEnabled: newValue)}
                        ))
                        .toggleStyle(.checkbox)
                        .tint(Color.gray.opacity(0.1))
                        .labelsHidden()
                        
                        
                        TextField("Key", text: Binding(
                            get: {header.key},
                            set: {newKey in service.setRequestHeader(folderID: folderID, requestID: request.id, headerID: header.id, key: newKey)}
                        ))
                        .textContentType(nil)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .opacity(header.isEnabled ? 1.0 : 0.5)
                        
                        Text(":").font(.system(.caption, design: .monospaced))
                            .opacity(header.isEnabled ? 1.0 : 0.5)
                        
                        TextField("Value", text: Binding(
                            get: {header.value},
                            set: {newValue in service.setRequestHeader(folderID: folderID, requestID: request.id, headerID: header.id, value: newValue)}
                        ))
                        .textContentType(nil)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .opacity(header.isEnabled ? 1.0 : 0.5)
                        
                        Button(action: {service.deleteRequestHeader(folderID: folderID, requestID: request.id, headerID: header.id)}) {
                            Image(systemName: "minus.circle").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button(action: {service.addRequestHeader(folderID: folderID, requestID: request.id)}) {
                    Text("add header")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 5)
                .buttonStyle(.bordered)
                .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
        .cornerRadius(8)
    }
}
#Preview {
    let request = HTTPRequest(
        name: "Get Profile",
        method: .GET,
        url: URL(string: "https://api.example.com/profile")!,
        headers: [
            HTTPHeader(key: "Accept", value: "application/json"),
            HTTPHeader(key: "Authorization", value: "Bearer token", isEnabled: false)
        ]
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
    
    RequestHeadersView(service: service, request: request, folderID: service.requestFolders[0].id)
}

