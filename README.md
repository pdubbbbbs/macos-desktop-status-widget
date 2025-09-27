# macOS Desktop Status Widget

A sleek, customizable desktop widget for macOS that displays security and privacy status indicators with a cyberpunk aesthetic.

![Widget Preview](screenshot.png)

## Features

- **Desktop Integration**: Embeds directly into the desktop background
- **Security Monitoring**: Real-time VPN, Tor, and DNS status indicators
- **Privacy Level Bar**: Visual representation of current privacy protection
- **Panic Button**: Emergency privacy protection (visible on hover)
- **Cyberpunk Styling**: Glowing borders with customizable colors
- **Auto-positioning**: Stays fixed on main display, never follows windows
- **Auto-save**: Automatic backup every 5 minutes
- **Transparent**: Blends seamlessly with desktop wallpaper

## Requirements

- macOS 11.0 or later
- Xcode Command Line Tools (for compilation)

## Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd desktop-widget
   ```

2. Compile the widget:
   ```bash
   swiftc -o desktop-widget desktop-widget.swift -framework Cocoa -framework SwiftUI
   ```

3. Run the widget:
   ```bash
   ./desktop-widget &
   ```

## Customization

### Colors & Styling
Edit the `LinearGradient` section in the Swift file to customize the glowing border colors:
```swift
LinearGradient(
    gradient: Gradient(colors: [
        Color.cyan.opacity(0.8),
        Color.blue.opacity(0.6),
        Color.purple.opacity(0.8),
        Color.pink.opacity(0.6)
    ])
)
```

### Position
The widget automatically positions itself in the upper-left area of your main display. Modify the positioning logic in `resetWidgetToFixedPosition()` to change location.

## Features Explained

### Security Status Indicators
- **VPN**: Shows connection status with shield icon
- **Tor**: Displays Tor network connectivity
- **DNS**: Indicates DNS protection status

### Privacy Level Bar
A 5-segment bar showing overall privacy protection level based on active security services.

### Panic Button
Hidden button that appears on hover - can be customized to trigger emergency privacy actions like:
- Disconnect VPN
- Clear clipboard
- Close sensitive applications
- Trigger system lockdown

### Auto-positioning
The widget uses aggressive positioning logic to:
- Stay fixed on the main display
- Never follow window movements
- Reset position every 0.5 seconds if displaced
- Handle screen configuration changes

## Development

### Project Structure
- `desktop-widget.swift` - Main application code
- Auto-generated backups in `/tmp/DesktopWidget-AutoSave/`

### Key Components
- `DesktopStatusWidgetApp` - Main SwiftUI app
- `AppDelegate` - Window management and positioning
- `WidgetContentView` - Main UI layout
- `StatusIndicator` - Individual status icon component
- `SecurityStatusModel` - Status monitoring logic

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on macOS
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Author

Philip S Wright

## Acknowledgments

- Built with SwiftUI and AppKit
- Inspired by cyberpunk aesthetics
- Designed for privacy-conscious users