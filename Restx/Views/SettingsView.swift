import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var config: Config
    @State private var showFontPanel = false
    
    var body: some View {
        Form {
            HStack {
                Text("Editor Font:")
                Spacer()
                Text("\(config.editorFontFamily) \(Int(config.editorFontSize))pt")
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                Button("Choose...") {
                    showFontPanel = true
                }
                .fontPanel(isPresented: $showFontPanel,
                         fontName: $config.editorFontFamily,
                         fontSize: $config.editorFontSize)
            }
            
            HStack {
                Text("Request Timeout:")
                Spacer()
                TextField("", value: $config.requestTimeout, format: .number)
                    .textContentType(nil)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
                Text("seconds")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 150)
    }
}


class FontPanelManager: NSObject {
    var onFontChange: ((String, Double) -> Void)?
    
    func showFontPanel(currentFontName: String, currentSize: Double) {
        let fontManager = NSFontManager.shared
        let fontPanel = NSFontPanel.shared
        
        let currentFont = NSFont(name: currentFontName, size: currentSize) ??
                          NSFont.monospacedSystemFont(ofSize: currentSize, weight: .regular)
        fontManager.setSelectedFont(currentFont, isMultiple: false)
        fontManager.target = self
        fontManager.action = #selector(changeFont(_:))
        fontPanel.makeKeyAndOrderFront(nil)
    }
    
    @objc func changeFont(_ sender: Any?) {
        guard let fontManager = sender as? NSFontManager else { return }
        let oldFont = fontManager.selectedFont ?? NSFont.systemFont(ofSize: 12)
        let newFont = fontManager.convert(oldFont)
        onFontChange?(newFont.fontName, newFont.pointSize)
    }
}

struct FontPanelModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var fontName: String
    @Binding var fontSize: Double
    @State private var fontPanelManager = FontPanelManager()
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { oldValue, newValue in
                if newValue {
                    fontPanelManager.onFontChange = { name, size in
                        fontName = name
                        fontSize = size
                    }
                    fontPanelManager.showFontPanel(currentFontName: fontName, currentSize: fontSize)
                    isPresented = false
                }
            }
    }
}

extension View {
    func fontPanel(isPresented: Binding<Bool>, fontName: Binding<String>, fontSize: Binding<Double>) -> some View {
        self.modifier(FontPanelModifier(isPresented: isPresented, fontName: fontName, fontSize: fontSize))
    }
}

#Preview("Font Panel Manager Show") {
    SettingsView()
        .environmentObject(Config())
}

