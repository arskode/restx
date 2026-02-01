import SwiftUI

struct SidebarView: View {
    @ObservedObject var service: Service
    @Binding var navigationVisibility: NavigationSplitViewVisibility
    @State private var expandedFolders: Set<UUID> = []
    @State private var editingFolderID: UUID? = nil
    @State private var editingText: String = ""
    @FocusState private var focused: Bool
    @Binding var sidebarSelection: SidebarSelection?
    @State private var folderToDelete: UUID? = nil
    @State var searchText: String = ""

    
    func resetEditing() -> Void {
        editingText = ""
        focused = false
        editingFolderID = nil
    }
    
    private var filteredFolders: [RequestFolder] {
        if searchText.isEmpty {
            return service.requestFolders
        }
        
        return service.requestFolders.compactMap { folder in
            let filteredRequests = folder.requests.filter { request in
                request.name.localizedCaseInsensitiveContains(searchText)
            }
            
            if filteredRequests.isEmpty {
                return nil
            }
            
            var newFolder = folder
            newFolder.requests = filteredRequests
            return newFolder
        }
    }

    private var isDeleteFolderDialogPresented: Binding<Bool> {
        Binding<Bool>(
            get: { folderToDelete != nil },
            set: { isPresented in
                if !isPresented {
                    folderToDelete = nil
                }
            }
        )
    }

    private var deleteFolderMessageText: String? {
        guard
            let folderID = folderToDelete,
            let folder = service.requestFolders.first(where: { $0.id == folderID })
        else { return nil }

        return "Are you sure you want to delete the folder '\(folder.name)'? This will also delete all requests in this folder."
    }

    private func confirmDeleteFolder() {
        guard let folderID = folderToDelete else { return }
        if sidebarSelection?.folderID == folderID {
            sidebarSelection = nil
        }
        service.deleteFolder(folderID: folderID)
        folderToDelete = nil
    }

    private func isFolderExpandedBinding(folderID: UUID) -> Binding<Bool> {
        Binding<Bool>(
            get: { expandedFolders.contains(folderID) },
            set: { isExpanded in
                if isExpanded {
                    expandedFolders.insert(folderID)
                } else {
                    expandedFolders.remove(folderID)
                }
            }
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SidebarSearchView(service: service, searchText: $searchText, sidebarSelection: $sidebarSelection)
            ScrollViewReader { proxy in
                List(selection: $sidebarSelection) {
                    ForEach(filteredFolders) { folder in
                        DisclosureGroup(
                            isExpanded: isFolderExpandedBinding(folderID: folder.id),
                            content: { SidebarRequestsView(service: service, folderID: folder.id, requests: folder.requests, sidebarSelection: $sidebarSelection) },
                            label: {
                                HStack {
                                    Image(systemName: "folder")
                                        .padding(.leading, 4)
                                    if (editingFolderID != nil && editingFolderID == folder.id) {
                                        TextField(folder.name, text: $editingText)
                                            .font(.system(size: 15))
                                            .focused($focused)
                                            .onChange(of: focused) { _, isFocused in
                                                if !isFocused && editingFolderID == folder.id {resetEditing()}
                                            }
                                            .onSubmit({
                                                service.renameFolder(folderID: folder.id, name: editingText)
                                                resetEditing()
                                            })
                                            .onExitCommand(perform: {resetEditing()}
                                            )
                                    } else {
                                        Text(folder.name)
                                            .font(.system(size: 15))
                                        Spacer()
                                        Button(
                                            action: {
                                                let newRequestID = service.addRequestToFolder(folderID: folder.id)
                                                expandedFolders.insert(folder.id)
                                                if let newRequestID {
                                                    sidebarSelection = SidebarSelection(
                                                        folderID: folder.id,
                                                        requestID: newRequestID
                                                    )
                                                }
                                            },
                                            label: { Image(systemName: "plus").imageScale(.small) }
                                        ).buttonBorderShape(.circle)
                                    }
                                }
                                .lineLimit(1)
                                .listRowSeparator(.hidden)
                                .swipeActions {
                                    Button(
                                        role: .destructive,
                                        action: { folderToDelete = folder.id },
                                        label: {Label("", systemImage: "trash")}
                                    )
                                }
                                .contextMenu{
                                    Button {
                                        resetEditing()
                                        editingFolderID = folder.id
                                        editingText = folder.name
                                        focused = true
                                    } label: {
                                        Label("Rename", systemImage: "pencil")
                                    }
                                    Button {
                                        folderToDelete = folder.id
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        )
                        .tag(SidebarSelection(folderID: folder.id, requestID: nil))
                    }
                    .onMove{indices, newOffset in service.moveFolders(fromOffsets: indices, toOffset: newOffset)}
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .onChange(of: searchText) { _, newValue in
                    guard newValue.isEmpty else { return }
                    guard let firstFolderID = filteredFolders.first?.id else { return }
                    DispatchQueue.main.async { // fixes top folders slid under the search bar
                        proxy.scrollTo(firstFolderID, anchor: .top)
                    }
                }
            }
            .confirmationDialog(
                "Delete Folder",
                isPresented: isDeleteFolderDialogPresented
            ) {
                Button("Delete", role: .destructive, action: confirmDeleteFolder)
                Button("Cancel", role: .cancel) {
                    folderToDelete = nil
                }
            } message: {
                if let message = deleteFolderMessageText {
                    Text(message)
                }
            }
            .toolbar {
                if navigationVisibility == .all {
                    Button("Add Folder", systemImage: "folder.badge.plus") {
                        let newFolder = service.addFolder()
                        editingFolderID = newFolder.id
                        editingText = newFolder.name
                        focused = true
                        expandedFolders.insert(newFolder.id)
                    }.disabled(focused)
                }
            }
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
    
    SidebarView(service: service, navigationVisibility: .constant(.all), sidebarSelection: .constant(nil))
}


