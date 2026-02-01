import SwiftUI

struct ResponseProgressView: View {
    let folderID: UUID
    let request: HTTPRequest
    @ObservedObject var service: Service
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .controlSize(.large)
            
            Text("Sending request...")
                .font(.body)
                .foregroundColor(.secondary)
            
            
            Button(action: {
                service.cancelRequest(folderID: folderID, requestID: request.id)
            }) {
                Text("Cancel")
                    .font(.body)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .cornerRadius(8)
            }
            .buttonStyle(.bordered)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
#Preview {
    let request = HTTPRequest(
        name: "Fetching Data",
        method: .GET,
        url: URL(string: "https://api.example.com/status")!
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
    
    ResponseProgressView(folderID: service.requestFolders[0].id, request: request, service: service)
}

