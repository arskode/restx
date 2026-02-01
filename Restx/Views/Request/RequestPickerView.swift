import SwiftUI

struct RequestPickerView: View {
    @ObservedObject var service: Service
    let folderID: UUID
    let request: HTTPRequest
    
    var body: some View {
        Picker("Body type", selection: Binding(
            get: { request.bodyType },
            set: { newType in
                service.setRequestBodyType(
                    folderID: folderID,
                    requestID: request.id,
                    bodyType: newType
                )
            }
        )) {
            ForEach(RequestType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
    }
}
#Preview {
    let requests = [
        HTTPRequest(name: "Wow", method: .GET, url: URL(string: "https://example.com")!)
    ]
    let service: Service = {
            let service = Service()
            service.requestFolders = [RequestFolder(name: "Dude", requests: requests)]
            return service
        }()
    
    RequestPickerView(service: service, folderID: service.requestFolders[0].id, request: requests[0])
    
}

