import SwiftUI

struct ContentView: View {
    @State private var navigationVisibility: NavigationSplitViewVisibility = .all
    @StateObject var service: Service = Service()
    @State var sidebarSelection: SidebarSelection?

    var body: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $navigationVisibility) {
                SidebarView(service: service, navigationVisibility: $navigationVisibility, sidebarSelection: $sidebarSelection)
                    .navigationSplitViewColumnWidth(min: 192, ideal: 256, max: 640)
            }
            detail: {
                DetailView(service: service, sidebarSelection: $sidebarSelection)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SettingsLink {
                        Image(systemName: "gear")
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

