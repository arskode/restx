import SwiftUI

struct ResponseInfoView: View {
    let response: HTTPResponse
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(
                    response.error != nil
                    ? .red
                    : response.statusCode >= 200
                    && response.statusCode < 300
                    ? .green : .red
                )
                .frame(width: 8, height: 8)
            
            if response.error != nil {
                Text("Error")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            } else {
                Text("\(response.statusCode)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(
                        response.statusCode >= 200
                        && response.statusCode < 300
                        ? .green : .red)
                
                Text("•")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.0f", response.responseTime)) ms")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
            }
        }
        .lineLimit(1)
    }
}
#Preview {
    let bodyData = Data("{\"ok\":true}".utf8)
    let response = HTTPResponse(
        statusCode: 204,
        headers: [HTTPHeader(key: "Content-Type", value: "application/json")],
        body: bodyData,
        responseTime: 87,
        size: bodyData.count,
        error: nil
    )
    
    ResponseInfoView(response: response)
}

