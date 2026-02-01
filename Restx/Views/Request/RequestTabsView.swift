import SwiftUI

struct RequestTabsView: View {
    @Binding var selectedRequestTab: RequestTab
    
    var body: some View {
        ForEach(RequestTab.allCases, id: \.self) { tab in
            Button(action: {
                selectedRequestTab = tab
            }) {
                Text(tab.rawValue)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(
                        selectedRequestTab == tab ? .primary : .secondary
                    )
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .lineLimit(1)
            }
            .buttonStyle(.borderless)
        }
    }
}
#Preview {
    RequestTabsView(selectedRequestTab: .constant(.body))
}

