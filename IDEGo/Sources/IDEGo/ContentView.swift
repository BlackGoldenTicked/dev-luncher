import SwiftUI

struct ToolIcon: View {
    let tool: DevTool
    let isSelected: Bool

    private var fallbackIcon: String {
        return tool.iconName
    }

    private var iconResourceName: String {
        let safeName = tool.name.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ".", with: "")
        return "icon_\(safeName)_color"
    }

    var body: some View {
        if let url = Bundle.module.url(forResource: iconResourceName, withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(isSelected ? 1.0 : 0.8)
        } else {
            Image(systemName: fallbackIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

struct ContentView: View {
    @State private var query = ""
    @State private var projects: [Project] = []
    @State private var filteredProjects: [Project] = []

    @EnvironmentObject private var toolManager: ToolManager
    @StateObject private var usageManager = UsageManager.shared
    @StateObject private var indexManager = ProjectIndexManager.shared

    // Focus & Selection State
    enum FocusArea {
        case projects
        case tools
    }
    @State private var focusArea: FocusArea = .projects
    @State private var selectedProjectIndex: Int = 0
    @State private var selectedToolIndex: Int? = nil
    @State private var showSettings = false
    @State private var isLaunching = false
    @State private var launchingToolName = ""
    @State private var launchToastVisibleAt: Date?
    @State private var hideLaunchToastWorkItem: DispatchWorkItem?

    @State private var eventMonitor: Any?

    var body: some View {
        ZStack {
            if showSettings {
                SettingsView(isPresented: $showSettings)
                    .transition(.opacity)
                    .onDisappear {
                        indexManager.forceRefresh()
                    }
                    .zIndex(1)
            } else {
                HStack(spacing: 0) {
                    // Main Content (Left)
                    MainContent(
                        query: $query,
                        filteredProjects: filteredProjects,
                        selectedProjectIndex: $selectedProjectIndex,
                        focusArea: $focusArea,
                        showSettings: $showSettings,
                        selectedToolIndex: $selectedToolIndex
                    )

                    Divider()

                    // Sidebar (Right)
                    SidebarContent(
                        focusArea: $focusArea,
                        toolManager: toolManager,
                        selectedToolIndex: $selectedToolIndex,
                        filteredProjects: filteredProjects,
                        selectedProjectIndex: selectedProjectIndex,
                        onLaunch: { tool in
                            launchWithSelectedTool(tool)
                        }
                    )
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .opacity(focusArea == .tools ? 1.0 : 0.6)
                    .overlay(
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if focusArea == .projects {
                                    focusArea = .tools
                                    if selectedToolIndex == nil && !toolManager.tools.isEmpty {
                                        selectedToolIndex = 0
                                    }
                                }
                            }
                            .allowsHitTesting(focusArea == .projects)
                    )
                }
                .transition(.opacity)
                .zIndex(0)
            }

            VStack(spacing: 10) {
                ProgressView()
                    .controlSize(.regular)
                Text("正在使用 \(launchingToolName) 打开项目…")
                    .font(.system(size: 13, weight: .medium))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isLaunching ? 1 : 0)
            .scaleEffect(isLaunching ? 1 : 0.98)
            .animation(.easeOut(duration: 0.2), value: isLaunching)
            .allowsHitTesting(false)
            .zIndex(2)

            if indexManager.isScanning {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ProgressView()
                            .controlSize(.small)
                            .scaleEffect(0.7)
                        Text("Indexing...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.bottom, 10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(3)
            }
        }
        .frame(width: 460, height: 500)
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .onAppear {
            indexManager.start()
            projects = indexManager.projects
            filteredProjects = indexManager.search(query: query)
            setupEventMonitor()
        }
        .onDisappear {
            removeEventMonitor()
        }
        .onChange(of: query) { newValue in
            filteredProjects = indexManager.search(query: newValue)
            selectedProjectIndex = 0
            focusArea = .projects
            selectedToolIndex = nil
        }
        .onReceive(indexManager.$projects) { newProjects in
            projects = newProjects
            filteredProjects = indexManager.search(query: query)
        }
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if self.showSettings {
                return event
            }

            if event.modifierFlags.contains(.command) ||
               event.modifierFlags.contains(.control) ||
               event.modifierFlags.contains(.option) {
                return event
            }

            switch event.keyCode {
            case 125: // Down Arrow
                if focusArea == .tools {
                    if let index = selectedToolIndex {
                        if index < toolManager.tools.count - 1 {
                            selectedToolIndex = index + 1
                        }
                    } else if !toolManager.tools.isEmpty {
                        selectedToolIndex = 0
                    }
                    return nil
                } else if selectedProjectIndex < filteredProjects.count - 1 {
                    selectedProjectIndex += 1
                    return nil
                }
            case 126: // Up Arrow
                if focusArea == .tools {
                    if let index = selectedToolIndex {
                        if index > 0 {
                            selectedToolIndex = index - 1
                        }
                    } else if !toolManager.tools.isEmpty {
                        selectedToolIndex = toolManager.tools.count - 1
                    }
                    return nil
                } else if selectedProjectIndex > 0 {
                    selectedProjectIndex -= 1
                    return nil
                }
            case 124: // Right Arrow — only intercept when focus is on projects list
                if focusArea == .projects && !toolManager.tools.isEmpty {
                    focusArea = .tools
                    if selectedToolIndex == nil {
                        selectedToolIndex = 0
                    }
                    return nil
                }
            case 123: // Left Arrow — only intercept when focus is on tools sidebar
                if focusArea == .tools {
                    focusArea = .projects
                    selectedToolIndex = nil
                    return nil
                }
            case 36: // Enter
                if !filteredProjects.isEmpty {
                    if focusArea == .projects {
                        focusArea = .tools
                        if selectedToolIndex == nil && !toolManager.tools.isEmpty {
                            selectedToolIndex = 0
                        }
                        return nil
                    } else {
                        if let index = selectedToolIndex, toolManager.tools.indices.contains(index) {
                            let tool = toolManager.tools[index]
                            launchWithSelectedTool(tool)
                        }
                        return nil
                    }
                }
            default:
                break
            }
            return event
        }
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    private func launchWithSelectedTool(_ tool: DevTool) {
        guard !filteredProjects.isEmpty else { return }
        let index = min(max(selectedProjectIndex, 0), filteredProjects.count - 1)
        let project = filteredProjects[index]
        launchingToolName = tool.name
        hideLaunchToastWorkItem?.cancel()
        if !isLaunching {
            launchToastVisibleAt = Date()
        }
        withAnimation(.easeOut(duration: 0.2)) {
            isLaunching = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Launcher.open(project: project, with: tool)
            let minimumVisibleTime: TimeInterval = 1.2
            let elapsed = Date().timeIntervalSince(launchToastVisibleAt ?? Date())
            let remaining = max(0.0, minimumVisibleTime - elapsed)
            let hideTask = DispatchWorkItem {
                withAnimation(.easeOut(duration: 0.25)) {
                    isLaunching = false
                }
                launchToastVisibleAt = nil
                query = ""
                NSApp.hide(nil)
            }
            hideLaunchToastWorkItem = hideTask
            DispatchQueue.main.asyncAfter(deadline: .now() + remaining, execute: hideTask)
        }
    }

}

struct MainContent: View {
    @Binding var query: String
    let filteredProjects: [Project]
    @Binding var selectedProjectIndex: Int
    @Binding var focusArea: ContentView.FocusArea
    @Binding var showSettings: Bool
    @Binding var selectedToolIndex: Int?

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search projects...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)

                Spacer()

                Button(action: {
                    withAnimation {
                        showSettings = true
                    }
                }) {
                    Image(systemName: "gear")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
            }
            .padding()
            .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))

            Divider()

            // Project List
            ScrollViewReader { proxy in
                List(filteredProjects) { project in
                    let index = filteredProjects.firstIndex(of: project) ?? 0
                    let isSelected = (selectedProjectIndex == index)
                    let isFocused = (focusArea == .projects)

                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(isSelected ? .white.opacity(0.9) : .blue)
                            .font(.title2)

                        VStack(alignment: .leading) {
                            Text(project.name)
                                .font(.headline)
                                .foregroundColor(isSelected ? .white : .primary)
                            Text(project.path)
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()

                        if isSelected && isFocused {
                            Text("↩")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProjectIndex = index
                        focusArea = .tools
                        if selectedToolIndex == nil {
                            selectedToolIndex = 0
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                    .listRowSeparator(.hidden)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isSelected ? (isFocused ? Color.accentColor : Color.gray.opacity(0.5)) : Color.clear)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                    )
                    .id(project.id)
                }
                .listStyle(.plain)
                .onChange(of: selectedProjectIndex) { newIndex in
                    if let project = filteredProjects.indices.contains(newIndex) ? filteredProjects[newIndex] : nil {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            proxy.scrollTo(project.id, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: 260)
    }
}

struct SidebarContent: View {
    @Binding var focusArea: ContentView.FocusArea
    @ObservedObject var toolManager: ToolManager
    @Binding var selectedToolIndex: Int?
    let filteredProjects: [Project]
    let selectedProjectIndex: Int
    let onLaunch: (DevTool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Text("Open with")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.vertical, 8)

            Divider()

            ScrollViewReader { toolProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 2) {
                        ForEach(Array(toolManager.tools.enumerated()), id: \.element.id) { index, tool in
                            let isSelected = (index == selectedToolIndex)

                            Button(action: {
                                selectedToolIndex = index
                                focusArea = .tools
                                onLaunch(tool)
                            }) {
                                HStack(spacing: 8) {
                                    // Selection Indicator
                                    if isSelected {
                                        Rectangle()
                                            .fill(Color.accentColor)
                                            .frame(width: 3)
                                            .cornerRadius(1.5)
                                    } else {
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: 3)
                                    }

                                    // Tool Icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
                                            .frame(width: 32, height: 32)

                                        ToolIcon(tool: tool, isSelected: isSelected)
                                            .frame(width: 20, height: 20)
                                    }

                                    // Tool Name
                                    Text(tool.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .frame(height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? Color.accentColor : Color.clear)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(index)
                        }
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 4)
                }
                .onChange(of: selectedToolIndex) { newIndex in
                    if let index = newIndex {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            toolProxy.scrollTo(index, anchor: .center)
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(width: 200)
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
