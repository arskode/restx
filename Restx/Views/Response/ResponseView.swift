import SwiftUI

struct ResponseView: View {
    let request: HTTPRequest
    let folderID: UUID
    @ObservedObject var service: Service
    @State var responseFormat: ResponseFormat = .pretty
    @State var selectedResponseTab: ResponseTab = .body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if request.task != nil {
                ResponseProgressView(folderID: folderID, request: request, service: service)
            } else if let response = request.response {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center, spacing: 10) {
                        if response.isJSON() {
                            ResponsePickerView(responseFormat: $responseFormat)
                        }
                        
                        ResponseTabsView(selectedResponseTab: $selectedResponseTab)
                        
                        Spacer()
                        
                        ResponseInfoView(response: response)
                    }
                    .lineLimit(1)
                    
                    ResponseBodyView(response: response, selectedResponseTab: $selectedResponseTab, responseFormat: $responseFormat)
                }
            } else {
                VStack {
                    Text("No response yet")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Text("Click the play button to send the request")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
           
        }
    }
}

private enum ResponseViewPreviewData {
    static let bodyString: String = """
    {
      "message": "Hello from Restx"
    }
    """
    static let bodyData: Data = bodyString.data(using: .utf8) ?? Data()
    static let response: HTTPResponse = HTTPResponse(
        statusCode: 200,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: bodyData,
        responseTime: TimeInterval(142),
        size: Int(bodyData.count),
        error: nil
    )
    static let request: HTTPRequest = {
        var request = HTTPRequest(
            name: "Get Greeting",
            method: .GET,
            url: URL(string: "https://api.example.com/hello")!
        )
        request.response = response
        return request
    }()
    static let service: Service = {
        let service = Service()
        service.requestFolders = [RequestFolder(name: "Preview", requests: [request])]
        return service
    }()
}

#Preview {
    ResponseView(
        request: ResponseViewPreviewData.request,
        folderID: ResponseViewPreviewData.service.requestFolders[0].id,
        service: ResponseViewPreviewData.service
    )
    .environmentObject(Config())
}

