import SwiftUI

struct SidebarSearchView: View {
    @ObservedObject var service: Service
    @Binding var searchText: String
    @Binding var sidebarSelection: SidebarSelection?
    
    var body: some View {
        HStack(spacing: 0) {
            TextField("Search requests...", text: $searchText)
                .textFieldStyle(.plain)
                .focusable(false)
                .autocorrectionDisabled()
                .onChange(of: searchText) { oldValue, newValue in
                    if !newValue.isEmpty {
                        sidebarSelection = nil
                    }
                }  // fixes "phantom" row
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.small)
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
        .padding(.horizontal, 10)
        .padding(.top, 2)
    }
}

#Preview {
    let service: Service = Service()
    
    SidebarSearchView(service:service, searchText: .constant(""), sidebarSelection: .constant(nil))
}

