import SwiftUI

struct ResponseBodyView: View {
    let response: HTTPResponse
    @Binding var selectedResponseTab: ResponseTab
    @Binding var responseFormat: ResponseFormat
    @EnvironmentObject var config: Config
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let error = response.error {
                VStack(alignment: .center, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("Request Failed")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    Text(error.capitalized)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            } else if selectedResponseTab == .headers {
                ScrollView {
                    ForEach(response.headers, id: \.id) { header in
                        HStack {
                            Text("\(header.key) : \(header.value)")
                                .font(.system(.body, design: .monospaced))
                                .fontWeight(.medium)
                                .textSelection(.enabled)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 2)
                        .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 4)
                .scrollIndicators(.hidden)
            } else {
                TextEditor(text: .constant(response.body(format: responseFormat)))
                    .textContentType(nil)
                    .font(config.editorFont)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .scrollContentBackground(.hidden)
                    .background(.clear)
                    .scrollContentBackground(.hidden)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}
#Preview {
    let bodyData = Data("""
    {
      "status": "ok",
      "items": [1, 2, 3]
    }
    """.utf8)
    let response = HTTPResponse(
        statusCode: 200,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: bodyData,
        responseTime: 201,
        size: bodyData.count,
        error: nil
    )
    
    ResponseBodyView(
        response: response,
        selectedResponseTab: .constant(.body),
        responseFormat: .constant(.pretty)
    )
    .environmentObject(Config())
}

