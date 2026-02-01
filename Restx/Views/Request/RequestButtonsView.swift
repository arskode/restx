import SwiftUI

struct RequestButtonsView: View {
    let request: HTTPRequest
    @Binding var bodyText: String
    @ObservedObject var service: Service
    let folderID: UUID
    
    var body: some View {
        if request.bodyType == .json {
            Button(action: {
                bodyText = request.formatBody()
            }) {
                Image(systemName: "textformat")
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
            .buttonStyle(.borderless)
            .buttonBorderShape(.capsule)
            .help("Format JSON")
            .padding(.trailing, 8)
        }
        
        Button(
            action: {
                Task {
                    await service.callRequest(folderID: folderID, requestID: request.id)
                }
            },
            label: {
                Image(systemName: "play.fill")
                    .foregroundColor(.primary)
                    .imageScale(.large)
            }
        )
        .disabled(request.task != nil)
        .opacity(request.task != nil ? 0.5 : 1)
        .buttonBorderShape(.capsule)
        .help("Send Request")
    }
}
#Preview {
    let request = HTTPRequest(
        name: "Format Me",
        method: .POST,
        url: URL(string: "https://api.example.com/format")!,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: "{\"hello\":\"world\"}",
        bodyType: .json
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
    
    RequestButtonsView(
        request: request,
        bodyText: .constant(request.body),
        service: service,
        folderID: service.requestFolders[0].id
    )
}

