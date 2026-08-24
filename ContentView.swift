import SwiftUI
import Combine
import AppKit

// MARK: - Custom Native Vector Tray Icon
struct CustomTrayIconShape: View {
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(color, lineWidth: 2)
            
            VStack(spacing: 3) {
                Capsule()
                    .fill(color)
                    .frame(width: 13, height: 2)
                
                Capsule()
                    .fill(color)
                    .frame(width: 13, height: 2)
                
                ChevronShape()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 11, height: 5)
            }
            .padding(.top, 1)
        }
    }
}

struct ChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width / 2, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Main Content View
struct ContentView: View {
    // --- Services ---
    @StateObject private var notionService = NotionService()
    @StateObject private var localTaskManager = LocalTaskManager()
    @StateObject private var historyStore = FocusHistoryStore()
    
    @State private var selectedTask: TaskItem? = nil
    @State private var selectedLocalTaskId: String? = nil
    @State private var showStatsPopover: Bool = false
    
    enum PomodoroMode: String, CaseIterable {
        case focus = "Focus (25m)"
        case shortBreak = "Short Break (5m)"
        case longBreak = "Long Break (15m)"
        
        var duration: Int {
            switch self {
            case .focus: return 25 * 60
            case .shortBreak: return 5 * 60
            case .longBreak: return 15 * 60
            }
        }
    }
    
    @State private var currentMode: PomodoroMode = .focus
    @State private var totalTime: Int = 25 * 60
    @State private var timeRemaining: Int = 25 * 60
    @State private var timeElapsed: Int = 0
    @State private var isRunning: Bool = false
    @State private var isFlashing: Bool = false
    
    @State private var taskName: String = ""
    @State private var isEditingTask: Bool = true
    @State private var isMouseDown: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private let bgDark = Color(red: 20/255, green: 22/255, blue: 26/255)
    private let podDark = Color(red: 35/255, green: 38/255, blue: 44/255)
    
    private func selectLocalTask(_ task: LocalTaskItem) {
        selectedTask = nil
        selectedLocalTaskId = task.id
        taskName = task.title
        isEditingTask = false
        isTextFieldFocused = false
        timeElapsed = 0
    }
    
    private var currentOpacity: Double {
        if isMouseDown {
            return 0.05
        } else if isEditingTask || isTextFieldFocused || selectedTask != nil || selectedLocalTaskId != nil || showStatsPopover {
            return 0.80
        } else {
            return 0.50
        }
    }
    
    private var currentColor: Color {
        if timeRemaining <= 5 * 60 {
            return Color(red: 245/255, green: 39/255, blue: 39/255)
        } else if timeRemaining <= 15 * 60 {
            return Color(red: 245/255, green: 245/255, blue: 39/255)
        } else {
            return Color(red: 76/255, green: 217/255, blue: 100/255)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // --- Top Bar ---
            HStack {
                // --- Close Button ---
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)

                // --- Clear / Reset Task List Button ---
                Button(action: {
                    notionService.tasks = []
                    localTaskManager.tasks = []
                    selectedTask = nil
                    selectedLocalTaskId = nil
                    taskName = ""
                    isEditingTask = true
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // --- Stats Button ---
                Button(action: {
                    showStatsPopover.toggle()
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showStatsPopover, arrowEdge: .bottom) {
                    StatsView(historyStore: historyStore)
                }
                
                // --- Session Mode Menu ---
                Menu {
                    ForEach(PomodoroMode.allCases, id: \.self) { mode in
                        Button(mode.rawValue) {
                            switchMode(to: mode)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.01))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .colorScheme(.dark)
            }
            .padding(.horizontal, 12)
            .padding(.top, 17)
            
            // --- Task Selector & Display Box ---
            ZStack {
                if isEditingTask {
                    HStack(spacing: 6) {
                        TextField("Enter task...", text: $taskName)
                            .focused($isTextFieldFocused)
                            .textFieldStyle(.plain)
                            .multilineTextAlignment(.leading)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .onSubmit {
                                let trimmed = taskName.trimmingCharacters(in: .whitespaces)
                                if !trimmed.isEmpty {
                                    if notionService.tasks.isEmpty {
                                        localTaskManager.addTask(title: trimmed)
                                        if let newlyAdded = localTaskManager.tasks.last {
                                            selectedLocalTaskId = newlyAdded.id
                                        }
                                    }
                                    isEditingTask = false
                                    isTextFieldFocused = false
                                }
                            }
                        
                        if notionService.isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 28, height: 26)
                        } else {
                            ZStack {
                                CustomTrayIconShape(color: currentColor)
                                    .frame(width: 22, height: 22)
                                    .frame(width: 28, height: 26)

                                Menu {
                                    if !notionService.tasks.isEmpty {
                                        ForEach(notionService.tasks) { task in
                                            Button(task.title.isEmpty ? "Untitled Task" : task.title) {
                                                selectTask(task)
                                            }
                                        }
                                    } else if !localTaskManager.tasks.isEmpty {
                                        ForEach(localTaskManager.tasks) { localTask in
                                            Button(localTask.title) {
                                                selectLocalTask(localTask)
                                            }
                                        }
                                    } else {
                                        Text("Type a task and hit Enter")
                                    }
                                } label: {
                                    Color.white.opacity(0.01)
                                        .frame(width: 28, height: 26)
                                }
                                .menuStyle(.borderlessButton)
                                .frame(width: 28, height: 26)
                            }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(currentColor.opacity(0.8), lineWidth: 1)
                    )
                    .frame(width: 175)
                } else {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(currentColor)
                            .frame(width: 6, height: 6)
                        
                        Text(taskName.isEmpty ? "Select Task" : taskName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(currentColor)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(6)
                    .onTapGesture {
                        isEditingTask = true
                        isTextFieldFocused = true
                    }
                }
            }
            .frame(height: 26)
            .padding(.top, 10)
            .padding(.bottom, 16)

            // --- Main Ring & Content Stack ---
            ZStack {
                Circle()
                    .stroke(
                        Color.white.opacity(0.2),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [2, 5])
                    )
                    .frame(width: 172, height: 172)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        currentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .opacity(timeRemaining <= 5 && isRunning ? (isFlashing ? 0.15 : 1.0) : 1.0)
                    .animation(.easeInOut(duration: 0.4), value: isFlashing)
                    .rotationEffect(.init(degrees: -90))
                    .frame(width: 172, height: 172)
                    .shadow(color: currentColor.opacity(0.4), radius: 6, x: 0, y: 0)
                    .animation(.linear(duration: 1), value: timeRemaining)

                VStack(spacing: 8) {
                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 34, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        Button(action: toggleTimer) {
                            ZStack {
                                Circle()
                                    .fill(podDark.opacity(0.95))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(currentColor)
                            }
                        }
                        .buttonStyle(.plain)

                        Button(action: resetTimer) {
                            ZStack {
                                Circle()
                                    .fill(podDark.opacity(0.95))
                                    .frame(width: 38, height: 38)
                                
                                Image(systemName: "gobackward")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Text("\(timeString(from: timeElapsed)) elapsed")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(currentColor)
                .padding(.bottom, 12)
        }
        .frame(width: 210, height: 280)
        .background(bgDark.opacity(currentOpacity))
        .cornerRadius(16)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(isMouseDown ? 0.05 : 0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(isMouseDown ? 0.0 : 0.4), radius: 10, x: 0, y: 5)
        .animation(.easeInOut(duration: 0.6), value: currentColor)
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    if !isTextFieldFocused {
                        if abs(value.translation.width) > 1 || abs(value.translation.height) > 1 {
                            withAnimation(.easeOut(duration: 0.1)) {
                                isMouseDown = true
                            }
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeIn(duration: 0.15)) {
                        isMouseDown = false
                    }
                }
        )
        .background(WindowAccessor(isMouseDown: $isMouseDown))
        .onAppear {
            notionService.fetchTasks()
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
                timeElapsed += 1
                
                if currentMode == .focus {
                    historyStore.logFocusSession(seconds: 1, isCompletedSession: false)
                }
                
                if timeRemaining <= 5 {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        isFlashing.toggle()
                    }
                }
            } else {
                isRunning = false
                isFlashing = false
                
                NSSound(named: NSSound.Name("Glass"))?.play()
                
                if currentMode == .focus {
                    historyStore.logFocusSession(seconds: 0, isCompletedSession: true)
                }
                
                if currentMode == .focus, let task = selectedTask {
                    notionService.updateTaskStatus(pageId: task.id, status: "Done")
                    notionService.logFocusTime(pageId: task.id, elapsedSeconds: timeElapsed)
                } else if currentMode == .focus, let localId = selectedLocalTaskId {
                    localTaskManager.logTime(id: localId, seconds: timeElapsed)
                    localTaskManager.updateStatus(id: localId, status: "Done")
                }
            }
        }
    }
    
    private var progress: CGFloat {
        CGFloat(timeRemaining) / CGFloat(totalTime)
    }
    
    private func switchMode(to mode: PomodoroMode) {
        currentMode = mode
        totalTime = mode.duration
        timeRemaining = mode.duration
        timeElapsed = 0
        isRunning = false
        isFlashing = false
    }
    
    private func selectTask(_ task: TaskItem) {
        selectedTask = task
        selectedLocalTaskId = nil
        taskName = task.title.isEmpty ? "Untitled Task" : task.title
        isEditingTask = false
        isTextFieldFocused = false
        timeElapsed = 0
    }
    
    private func toggleTimer() {
        isRunning.toggle()
        if isRunning, currentMode == .focus {
            if let task = selectedTask {
                notionService.updateTaskStatus(pageId: task.id, status: "In Progress")
            } else if let localId = selectedLocalTaskId {
                localTaskManager.updateStatus(id: localId, status: "In Progress")
            }
        }
    }
    
    private func resetTimer() {
        isRunning = false
        isFlashing = false
        totalTime = currentMode.duration
        timeRemaining = currentMode.duration
        timeElapsed = 0
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let sec = seconds % 60
        return String(format: "%02d:%02d", minutes, sec)
    }
}

// MARK: - Helper to manage window background dragging & transparency natively
struct WindowAccessor: NSViewRepresentable {
    @Binding var isMouseDown: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        
        DispatchQueue.main.async {
            if let window = view.window {
                window.isOpaque = false
                window.backgroundColor = .clear
                window.hasShadow = false
                window.isMovableByWindowBackground = true
            }
        }
        
        // Reset transparency on initial click down (do not trigger transparency yet)
        let downMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { event in
            if let window = view.window, event.window == window {
                DispatchQueue.main.async {
                    isMouseDown = false
                }
            }
            return event
        }
        
        // Trigger high transparency ONLY when the mouse actually moves (dragging)
        let dragMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDragged]) { event in
            if let window = view.window, event.window == window {
                DispatchQueue.main.async {
                    isMouseDown = true
                }
            }
            return event
        }
        
        // Reset transparency when the mouse button is released
        let upMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseUp]) { event in
            if let window = view.window, event.window == window {
                DispatchQueue.main.async {
                    isMouseDown = false
                }
            }
            return event
        }
        
        // Global safety net in case the drag ends outside the window bounds
        let globalUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { _ in
            DispatchQueue.main.async {
                isMouseDown = false
            }
        }
        
        context.coordinator.monitors = [downMonitor, dragMonitor, upMonitor, globalUpMonitor]
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var monitors: [Any?] = []
        
        deinit {
            for monitor in monitors {
                if let monitor = monitor {
                    NSEvent.removeMonitor(monitor)
                }
            }
        }
    }
}
