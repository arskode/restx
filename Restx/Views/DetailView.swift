import SwiftUI

struct DetailView: View {
    @ObservedObject var service: Service
    @Binding var sidebarSelection: SidebarSelection?
    
    var body: some View {
        if let sidebarSelection = sidebarSelection,
           let requestID = sidebarSelection.requestID,
           let request = service.getRequest(folderID: sidebarSelection.folderID, requestID: requestID) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Picker(
                            "",
                            selection: Binding(
                                get: { request.method },
                                set: { service.setRequestMethod(
                                    folderID: sidebarSelection.folderID,
                                    requestID: requestID,
                                    method: $0)
                                }
                            )
                        ) {
                            ForEach(HTTPMethod.allCases, id: \.self) { method in
                                Text(method.rawValue)
                                    .tag(method)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .fontDesign(.monospaced)
                        
                        TextField(
                            "URL",
                            text: Binding(
                                get: { request.url.absoluteString },
                                set: { newValue in
                                    service.setRequestUrl(
                                        folderID: sidebarSelection.folderID,
                                        requestID: requestID,
                                        url: newValue
                                    )
                                }
                            ), axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .font(.body)
                        .fontDesign(.monospaced)
                        .multilineTextAlignment(.leading)
                        .lineLimit(1...10)
                    }
                }
                
                HSplitView {
                    RequestView(request: request, folderID: sidebarSelection.folderID, service: service)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                    .navigationSplitViewColumnWidth(min: 250, ideal: 250, max: 250)
                    .padding(.trailing, 10)
                    ResponseView(request: request, folderID: sidebarSelection.folderID, service: service)
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .padding(.leading, 10)
                }
            }
            .padding()
        }
    }
}


#Preview {
    let requests = [
        HTTPRequest(name: "Wow", method: .GET, url: URL(string: "https://example.com")!),
        HTTPRequest(name: "Dude", method: .GET, url: URL(string: "https://example.com")!),
    ]
    let service: Service = {
            let service = Service()
            service.requestFolders = [
                RequestFolder(name: "Wow", requests: requests),
                RequestFolder(name: "Dude", requests: requests),
            ]
            return service
        }()
    
    DetailView(service: service, sidebarSelection:
            .constant(SidebarSelection(folderID: service.requestFolders[0].id, requestID: requests[0].id))
    )
}

