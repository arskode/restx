import SwiftUI
import UniformTypeIdentifiers


struct RequestBodyFormView: View {
    @ObservedObject var service: Service
    let folderID: UUID
    let request: HTTPRequest
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                ForEach(request.formData.filter { form in
                    request.bodyType == .multiPart || !form.isFile
                })
                { form in
                    HStack {
                        Toggle("", isOn: Binding(
                            get: { form.isEnabled },
                            set: { newValue in service.toggleFormData(folderID: folderID, requestID: request.id, formID: form.id, isEnabled: newValue)}
                        ))
                        .toggleStyle(.checkbox)
                        .tint(Color.gray.opacity(0.1))
                        .labelsHidden()
                        
                        TextField(
                            "Key",
                            text: Binding(
                                get: { form.key },
                                set: { newKey in
                                    service.setFormData(folderID: folderID, requestID: request.id, formID: form.id, key: newKey
                                    )
                                }
                            )
                        )
                        .textContentType(nil)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .opacity(form.isEnabled ? 1.0 : 0.5)
                        
                        Text(":")
                            .font(.system(.caption, design: .monospaced))
                            .opacity(form.isEnabled ? 1.0 : 0.5)
                        
                        if form.isFile && request.bodyType == .multiPart {
                            FilePickerView(
                                form: form,
                                folderID: folderID,
                                requestID: request.id,
                                service: service
                            )
                            .opacity(form.isEnabled ? 1.0 : 0.5)
                        } else {
                            TextField(
                                "Value",
                                text: Binding(
                                    get: { form.value },
                                    set: { newValue in
                                        service.setFormData(folderID: folderID, requestID: request.id, formID: form.id, value: newValue
                                        )
                                    }
                                )
                            )
                            .textContentType(nil)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .opacity(form.isEnabled ? 1.0 : 0.5)
                        }
                        
                        Button(action: {
                            service.deleteRequestFormDataItem(folderID: folderID, requestID: request.id, formID: form.id)
                        }) {
                            Image(systemName: "minus.circle").foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                HStack {
                    Button(action: {
                        service.addRequestFormData(folderID: folderID, requestID: request.id)
                    }) {
                        Text("add field")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.secondary)
                    
                    if request.bodyType == .multiPart {
                        Button(action: {
                            service.addRequestFormData(folderID: folderID, requestID: request.id, isFile: true)
                        }) {
                            Text("add file")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 5)
            }
            .padding(.top, 8)
            .padding(.horizontal, 4)
        }
        .cornerRadius(8)
    }
}


struct FilePickerView: View {
    let form: FormDataField
    let folderID: UUID
    let requestID: UUID
    @ObservedObject var service: Service
    @State private var isShowingFilePicker = false
    @State private var displayFileName: String = ""
    
    var body: some View {
        Button(action: {
            isShowingFilePicker = true
        }) {
            Text(displayFileName.isEmpty ? "Select File" : displayFileName)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(6)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .buttonStyle(.plain)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    displayFileName = url.lastPathComponent
                    service.setFormData(
                        folderID: folderID,
                        requestID: requestID,
                        formID: form.id,
                        value: url.path,
                        isFile: true
                    )
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .onAppear {
            if !form.value.isEmpty {
                let url = URL(fileURLWithPath: form.value)
                displayFileName = url.lastPathComponent
            }
        }
    }
}

#Preview {
    let formData = [
        FormDataField(key: "name", value: "Restx"),
        FormDataField(key: "tags", value: "swift,preview"),
        FormDataField(key: "file", value: "/tmp/demo.png", isFile: true, isEnabled: false)
    ]
    let request = HTTPRequest(
        name: "Upload Asset",
        method: .POST,
        url: URL(string: "https://api.example.com/upload")!,
        headers: [HTTPHeader(key: "Content-Type", value: "multipart/form-data")],
        bodyType: .multiPart,
        formData: formData
    )
    let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Uploads", requests: [request])]
        return service
    }()
    
    RequestBodyFormView(service: service, folderID: service.requestFolders[0].id, request: request)
}



