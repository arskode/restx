import SwiftUI

struct ResponseTabsView: View {
    @Binding var selectedResponseTab: ResponseTab
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(ResponseTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedResponseTab = tab
                }) {
                    Text(tab.rawValue)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(
                            selectedResponseTab == tab
                            ? .primary : .secondary
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .lineLimit(1)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
#Preview {
    ResponseTabsView(selectedResponseTab: .constant(.body))
}

