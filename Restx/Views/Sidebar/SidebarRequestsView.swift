import SwiftUI

struct SidebarRequestsView: View {
    @ObservedObject var service: Service
    let folderID: UUID
    let requests: [HTTPRequest]
    @State var editingRequestID: UUID? = nil
    @State var editingText: String = ""
    @FocusState var focused: Bool
    @Binding var sidebarSelection: SidebarSelection?
    
    func resetEditing() -> Void {
            editingText = ""
            focused = false
            editingRequestID = nil
        }

    var body: some View {
        ForEach(requests) { request in
            Group {
                if (editingRequestID != nil && editingRequestID == request.id) {
                    TextField(request.name, text: $editingText)
                        .focused($focused)
                        .onSubmit({
                            service.renameRequest(folderID: folderID, requestID: request.id, name: editingText)
                            resetEditing()
                        })
                        .onChange(of: focused) { _, isFocused in
                            if !isFocused {
                                resetEditing()
                            }
                        }
                        .font(.system(size: 15))
                        .listRowSeparator(.hidden)
                        .onExitCommand(perform: {resetEditing()})
                } else {
                    HStack(spacing: 5) {
                        Text(request.method.rawValue).fontDesign(.monospaced).foregroundStyle(.gray)
                        Text(request.name)
                        .font(.system(size: 15))
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .lineLimit(1)
            .padding(.bottom, 1)
            .tag(SidebarSelection(folderID: folderID, requestID: request.id))
            .contextMenu {
                Button {
                    editingRequestID = request.id
                    editingText = request.name
                    focused = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button {
                    service.duplicateRequest(folderID: folderID, requestID: request.id)
                } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Button(role: .destructive) {
                    if sidebarSelection?.requestID == request.id {sidebarSelection = nil}
                    service.deleteRequest(folderID: folderID, requestID: request.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            .swipeActions {
                Button(
                    role: .destructive,
                    action: {
                        if sidebarSelection?.requestID == request.id {sidebarSelection = nil}
                        service.deleteRequest(folderID: folderID, requestID: request.id)
                    },
                    label: {Label("", systemImage: "trash")}
                )
            }
            
        }
        .onMove { indices, newOffset in
            service.moveRequests(folderID: folderID, fromOffsets: indices, toOffset: newOffset)
        }
    }
}
#Preview {
    let service = Service()
    let requests = [
        HTTPRequest(name: "Wow", method: .GET, url: URL(string: "https://example.com")!),
        HTTPRequest(name: "Dude", method: .GET, url: URL(string: "https://example.com")!),
    ]

    SidebarRequestsView(service:service, folderID: UUID(), requests: requests, sidebarSelection: .constant(nil))
}

