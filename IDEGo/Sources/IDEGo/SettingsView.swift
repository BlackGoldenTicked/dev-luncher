import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsManager
    @EnvironmentObject private var toolManager: ToolManager
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(isPresented: $isPresented)
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScanPathsSection(settings: settings)
                    
                    Divider()
                    
                    ToolsSection(toolManager: toolManager)
                    
                    Divider()
                    
                    AboutSection()
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 500)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

struct HeaderView: View {
    @Binding var isPresented: Bool
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isPresented = false
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundColor(isHovered ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isHovered ? Color.secondary.opacity(0.1) : Color.clear)
                .cornerRadius(6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isHovered = hover
                }
            }
            
            Spacer()
            
            Text("Settings")
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Invisible placeholder to balance the header title
            Color.clear
                .frame(width: 60, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
}

struct ScanPathsSection: View {
    @ObservedObject var settings: SettingsManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Scan Paths")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    presentFolderPicker()
                }) {
                    Label("Add Folder", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VStack(spacing: 8) {
                if settings.config.pathConfigs.isEmpty {
                    Text("No paths configured")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
                } else {
                    ForEach(settings.config.pathConfigs) { pathConfig in
                        PathConfigRow(pathConfig: pathConfig, settings: settings)
                    }
                }
            }
        }
    }

    private func presentFolderPicker() {
        // MenuBarExtra(.window) runs as .accessory (no dock icon, no proper
        // foreground status).  NSOpenPanel.runModal() requires the app to be
        // a regular foreground app, otherwise macOS kills the modal session
        // the moment the MenuBarExtra popover auto-closes on focus loss.
        //
        // Fix: temporarily switch to .regular so the app owns the screen,
        // run the modal, then switch back.
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)

            let panel = NSOpenPanel()
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.prompt = "Select"

            let response = panel.runModal()
            if response == .OK, let url = panel.url {
                SettingsManager.shared.addPath(url.path)
            }

            NSApp.setActivationPolicy(.accessory)
        }
    }
}

struct ToolsSection: View {
    @ObservedObject var toolManager: ToolManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Installed Tools")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(Array(toolManager.allToolsStatus.enumerated()), id: \.offset) { index, item in
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.isInstalled ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                                .frame(width: 36, height: 36)
                            
                            ToolIcon(tool: item.tool, isSelected: false)
                                .frame(width: 20, height: 20)
                                .opacity(item.isInstalled ? 1.0 : 0.5)
                        }
                        
                        Text(item.tool.name)
                            .font(.system(size: 9))
                            .foregroundColor(item.isInstalled ? .primary : .secondary)
                            .lineLimit(1)
                    }
                    .help(item.isInstalled ? "Installed" : "Not Found")
                }
            }
        }
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 4) {
                Text("IDEGo v0.1.0")
                    .font(.footnote)
                    .fontWeight(.medium)
                
                Text("By z @ Chaordex Labs")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Link("chaordex.com", destination: URL(string: "https://chaordex.com")!)
                    .font(.caption2)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
            
            Button(action: {
                NSApp.terminate(nil)
            }) {
                Text("Quit App")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
    }
}

struct PathConfigRow: View {
    let pathConfig: SearchPathConfig
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                withAnimation {
                    settings.removePath(id: pathConfig.id)
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 12))
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .padding(6)
            .background(Color.red.opacity(0.1))
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(pathConfig.path)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundColor(.primary)
                
                Text("Max Depth: \(pathConfig.maxDepth)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Slider(
                value: Binding(
                    get: {
                        Double(settings.config.pathConfigs.first(where: { $0.id == pathConfig.id })?.maxDepth ?? ScanConfig.defaultDepth)
                    },
                    set: { newValue in
                        if let index = settings.config.pathConfigs.firstIndex(where: { $0.id == pathConfig.id }) {
                            settings.config.pathConfigs[index].maxDepth = Int(newValue)
                        }
                    }
                ),
                in: 1...10,
                step: 1
            )
            .frame(width: 80)
            .help("Adjust scanning depth (1-10)")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
    }
}
