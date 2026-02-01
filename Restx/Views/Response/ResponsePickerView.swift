import SwiftUI

struct ResponsePickerView: View {
    @Binding var responseFormat: ResponseFormat
    
    var body: some View {
        Picker("", selection: $responseFormat) {
            ForEach(ResponseFormat.allCases, id: \.self) { format in
                Text(format.rawValue).tag(format)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .font(.subheadline)
    }
}
#Preview {
    ResponsePickerView(responseFormat: .constant(.pretty))
}

