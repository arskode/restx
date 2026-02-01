import SwiftUI

struct RequestView: View {
    let request: HTTPRequest
    let folderID: UUID
    @ObservedObject var service: Service
    @State var selectedRequestTab: RequestTab = .body
    @State private var bodyText: String = ""
    @EnvironmentObject var config: Config
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 10) {
                RequestPickerView(service: service, folderID: folderID, request: request)
                
                HStack(alignment: .center, spacing: 0) {
                    RequestTabsView(selectedRequestTab: $selectedRequestTab)
                    Spacer()
                    RequestButtonsView(request: request, bodyText: $bodyText, service: service, folderID: folderID)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                if selectedRequestTab == .headers {
                    RequestHeadersView(service: service, request: request, folderID: folderID)
                } else {
                    if request.bodyType == .json {
                        RequestBodyTextEditorView(request: request, bodyText: $bodyText, folderID: folderID, service: service)
                    } else {
                        RequestBodyFormView(service: service, folderID: folderID, request: request)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
}
#Preview {
    let request = HTTPRequest(
        name: "Create Note",
        method: .POST,
        url: URL(string: "https://api.example.com/notes")!,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: """
        {
          "title": "Preview",
          "body": "Hello from Restx"
        }
        """,
        bodyType: .json
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
    
    RequestView(request: request, folderID: service.requestFolders[0].id, service: service)
        .environmentObject(Config())
}

