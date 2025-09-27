import SwiftUI
import Cocoa
import Foundation

// MARK: - Desktop Widget App
@available(macOS 11.0, *)
struct DesktopStatusWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate for Desktop Widget
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusWindow: NSWindow?
    var widgetView: NSHostingView<WidgetContentView>?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupDesktopWidget()
        
        // Hide dock icon and menu bar
        NSApp.setActivationPolicy(.accessory)
    }
    
    func setupDesktopWidget() {
        // Protect background image file
        protectBackgroundImage()
        
        // Create the SwiftUI view
        let contentView = WidgetContentView()
        let hostingView = NSHostingView(rootView: contentView)
        
        // Create window with specific properties for desktop widget
        statusWindow = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 400, height: 480),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        
        guard let window = statusWindow else { return }
        
        // Configure window for desktop widget behavior
        window.contentView = hostingView
        window.backgroundColor = NSColor.clear
        window.isOpaque = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)  // Below desktop level
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .transient]
        window.isMovable = false  // Prevent any movement
        window.isMovableByWindowBackground = false  // Prevent accidental moving when embedded
        window.acceptsMouseMovedEvents = true
        window.ignoresMouseEvents = false  // Still allow interactions
        window.hidesOnDeactivate = false  // Don't hide when other apps are active
        
        // Always position widget on the main display, never follow windows to other screens
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let x = screenFrame.minX + 20  // 20 pixels from left edge of main screen
            let centerY = screenFrame.midY - (window.frame.height / 2)  // Original center position
            let y = centerY + (screenFrame.height * 0.25)  // Move 50% higher (25% of screen height up)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        window.makeKeyAndOrderFront(nil)
        
        // Store reference to hosting view
        widgetView = hostingView
        
        // Monitor screen changes to keep widget on main screen
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.resetWidgetToFixedPosition()
        }
        
        // Aggressively check and reset position every half second to prevent movement
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            self.resetWidgetToFixedPosition()
            // Also validate background image integrity
            if !self.validateBackgroundImage() {
                // Re-protect the image if validation fails
                self.protectBackgroundImage()
            }
        }
        
        // Auto-save widget files every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { _ in
            self.autoSaveWidget()
        }
    }
    
    func resetWidgetToFixedPosition() {
        guard let window = statusWindow, let mainScreen = NSScreen.main else { return }
        
        // Always reset to the same fixed position on main screen
        let screenFrame = mainScreen.visibleFrame
        let x = screenFrame.minX + 20  // Fixed 20px from left edge
        let centerY = screenFrame.midY - (window.frame.height / 2)
        let y = centerY + (screenFrame.height * 0.25)  // Fixed upper position
        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func autoSaveWidget() {
        DispatchQueue.global(qos: .background).async {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            let backupDir = "/tmp/DesktopWidget-AutoSave"
            let timestampedBackupDir = "\(backupDir)/\(timestamp)"
            
            // Create backup directory
            let fileManager = FileManager.default
            try? fileManager.createDirectory(atPath: backupDir, withIntermediateDirectories: true, attributes: nil)
            try? fileManager.createDirectory(atPath: timestampedBackupDir, withIntermediateDirectories: true, attributes: nil)
            
            // Copy files to backup
            let sourcePath = FileManager.default.currentDirectoryPath
            let filesToBackup = [
                "desktop-widget.swift",
                "desktop-widget",
                "background.jpg"
            ]
            
            for fileName in filesToBackup {
                let sourceFile = "\(sourcePath)/\(fileName)"
                let destinationFile = "\(timestampedBackupDir)/\(fileName)"
                
                if fileManager.fileExists(atPath: sourceFile) {
                    try? fileManager.copyItem(atPath: sourceFile, toPath: destinationFile)
                }
            }
            
            // Keep only the last 12 backups (1 hour worth at 5-minute intervals)
            self.cleanupOldBackups(in: backupDir)
            
            print("✅ Widget auto-saved to: \(timestampedBackupDir)")
        }
    }
    
    func cleanupOldBackups(in backupDir: String) {
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: backupDir)
            let backupFolders = contents.filter { !$0.hasPrefix(".") }.sorted()
            
            // Keep only the most recent 12 backups
            if backupFolders.count > 12 {
                let foldersToDelete = Array(backupFolders.prefix(backupFolders.count - 12))
                for folder in foldersToDelete {
                    let folderPath = "\(backupDir)/\(folder)"
                    try? fileManager.removeItem(atPath: folderPath)
                    print("🗑️ Cleaned up old backup: \(folder)")
                }
            }
        } catch {
            print("Error cleaning up backups: \(error)")
        }
    }
    
    func protectBackgroundImage() {
        let fileManager = FileManager.default
        let backgroundPath = "./background.jpg"
        
        // Check if background image exists
        guard fileManager.fileExists(atPath: backgroundPath) else {
            print("⚠️ No background.jpg found")
            return
        }
        
        do {
            // Set restrictive permissions (owner read-only, no access for others)
            let attributes: [FileAttributeKey: Any] = [
                .posixPermissions: 0o400  // Read-only for owner, no access for group/others
            ]
            
            try fileManager.setAttributes(attributes, ofItemAtPath: backgroundPath)
            
            // Get file info to verify integrity
            let fileAttributes = try fileManager.attributesOfItem(atPath: backgroundPath)
            let fileSize = fileAttributes[.size] as? Int64 ?? 0
            let modificationDate = fileAttributes[.modificationDate] as? Date ?? Date()
            
            // Store original file info for validation
            UserDefaults.standard.set(fileSize, forKey: "BackgroundImageSize")
            UserDefaults.standard.set(modificationDate, forKey: "BackgroundImageDate")
            
            print("🔒 Background image protected (size: \(fileSize) bytes)")
            
        } catch {
            print("⚠️ Failed to protect background image: \(error)")
        }
    }
    
    func validateBackgroundImage() -> Bool {
        let fileManager = FileManager.default
        let backgroundPath = "./background.jpg"
        
        guard fileManager.fileExists(atPath: backgroundPath) else {
            print("⚠️ Background image missing!")
            return false
        }
        
        do {
            let fileAttributes = try fileManager.attributesOfItem(atPath: backgroundPath)
            let currentSize = fileAttributes[.size] as? Int64 ?? 0
            let currentDate = fileAttributes[.modificationDate] as? Date ?? Date()
            
            let originalSize = UserDefaults.standard.object(forKey: "BackgroundImageSize") as? Int64 ?? 0
            let originalDate = UserDefaults.standard.object(forKey: "BackgroundImageDate") as? Date ?? Date()
            
            // Check if file has been modified
            if currentSize != originalSize || currentDate != originalDate {
                print("🚨 Background image has been tampered with!")
                print("   Original: \(originalSize) bytes, \(originalDate)")
                print("   Current:  \(currentSize) bytes, \(currentDate)")
                return false
            }
            
            return true
            
        } catch {
            print("⚠️ Failed to validate background image: \(error)")
            return false
        }
    }
}

// MARK: - Widget Content View
struct WidgetContentView: View {
    @StateObject private var statusModel = SecurityStatusModel()
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            HStack {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.blue)
                Spacer()
                Button(action: openMainApp) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 22))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(isHovered ? 1.0 : 0.3)
            }
            
            // Status Indicators
            HStack(spacing: 48) {
                StatusIndicator(
                    icon: "lock.shield",
                    status: statusModel.vpnStatus,
                    color: statusModel.vpnStatus == "Connected" ? .green : .red
                )
                
                StatusIndicator(
                    icon: "globe.badge.chevron.backward",
                    status: statusModel.torStatus,
                    color: statusModel.torStatus == "Connected" ? .green : .red
                )
                
                StatusIndicator(
                    icon: "network",
                    status: statusModel.dnsStatus,
                    color: statusModel.dnsStatus == "Protected" ? .green : .orange
                )
            }
            
            // Privacy Level Bar
            HStack {
                Text("Privacy:")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                Spacer()
                PrivacyLevelBar(level: statusModel.privacyLevel)
            }
            
            // Panic Button (only visible on hover)
            if isHovered {
                Button(action: triggerPanicMode) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 20))
                        Text("PANIC")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(40)
        .background(
            ZStack {
                // Background image
                if let nsImage = NSImage(contentsOfFile: "./background.jpg") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(0.2)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                
                // Semi-transparent overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.325))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.cyan.opacity(0.8),
                                        Color.blue.opacity(0.6),
                                        Color.purple.opacity(0.8),
                                        Color.pink.opacity(0.6)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.3), radius: 12, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            }
        )
        .frame(width: 400)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .onAppear {
            statusModel.startMonitoring()
        }
    }
    
    func openMainApp() {
        // Placeholder for opening main application
        print("🚀 Opening main application...")
    }
    
    func triggerPanicMode() {
        // Flash the widget red briefly
        withAnimation(.easeInOut(duration: 0.1)) {
            statusModel.panicActivated = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            statusModel.panicActivated = false
        }
        
        print("🚨 PANIC MODE ACTIVATED!")
        // Here you could add actual panic functionality like:
        // - Disconnect VPN
        // - Clear clipboard
        // - Close sensitive apps
        // - etc.
    }
}

// MARK: - Status Indicator Component
struct StatusIndicator: View {
    let icon: String
    let status: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundColor(color)
            
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
        }
    }
}

// MARK: - Privacy Level Bar
struct PrivacyLevelBar: View {
    let level: Double // 0.0 to 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 20, height: 8)
                    .opacity(level > Double(index) / 5.0 ? 1.0 : 0.3)
            }
        }
    }
    
    func barColor(for index: Int) -> Color {
        switch index {
        case 0, 1: return .red
        case 2, 3: return .orange
        case 4: return .green
        default: return .gray
        }
    }
}

// MARK: - Security Status Model
class SecurityStatusModel: ObservableObject {
    @Published var vpnStatus: String = "Disconnected"
    @Published var torStatus: String = "Disconnected"
    @Published var dnsStatus: String = "Protected"
    @Published var privacyLevel: Double = 0.6
    @Published var panicActivated: Bool = false
    
    private var timer: Timer?
    
    func startMonitoring() {
        // Update status every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.updateStatus()
        }
        
        // Initial update
        updateStatus()
    }
    
    func updateStatus() {
        DispatchQueue.main.async {
            // Simulate status checking - in a real app, you'd check actual VPN/Tor status
            // For now, we'll simulate some realistic behavior
            
            // Simulate VPN check
            if Bool.random() && self.vpnStatus == "Disconnected" {
                self.vpnStatus = "Connected"
            } else if Bool.random() && self.vpnStatus == "Connected" {
                self.vpnStatus = "Disconnected"
            }
            
            // Simulate Tor check  
            if Bool.random() && self.torStatus == "Disconnected" {
                self.torStatus = "Connected"
            }
            
            // Calculate privacy level based on active services
            var level = 0.2 // Base level
            if self.vpnStatus == "Connected" { level += 0.3 }
            if self.torStatus == "Connected" { level += 0.3 }
            if self.dnsStatus == "Protected" { level += 0.2 }
            
            self.privacyLevel = min(level, 1.0)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Main Entry Point
if #available(macOS 11.0, *) {
    DesktopStatusWidgetApp.main()
} else {
    fatalError("This app requires macOS 11.0 or later")
}