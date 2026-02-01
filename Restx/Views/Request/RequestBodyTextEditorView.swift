import SwiftUI

struct RequestBodyTextEditorView: View {
    @EnvironmentObject var config: Config
    let request: HTTPRequest
    @Binding var bodyText: String
    let folderID: UUID
    @ObservedObject var service: Service
    
    var body: some View {
        TextEditor(text: $bodyText)
            .textContentType(nil)
            .font(config.editorFont)
            .cornerRadius(8)
            .scrollContentBackground(.hidden)
            .onAppear {
                bodyText = request.body
            }
            .onChange(of: request.body) { _, newValue in
                if bodyText != newValue {
                    bodyText = newValue
                }
            }
            .onChange(of: bodyText) { _, newValue in
                if request.body != newValue {
                    service.setRequestBody(folderID: folderID, requestID: request.id, body: newValue)
                }
            }
    }
}
#Preview {
    let request = HTTPRequest(
        name: "Create User",
        method: .POST,
        url: URL(string: "https://api.example.com/users")!,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: """
        {
          "name": "Taylor",
          "role": "editor"
        }
        """,
        bodyType: .json
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
    
    RequestBodyTextEditorView(
        request: request,
        bodyText: .constant(request.body),
        folderID: service.requestFolders[0].id,
        service: service
    )
    .environmentObject(Config())
}

