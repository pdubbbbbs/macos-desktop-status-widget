#!/bin/bash

# macOS Desktop Status Widget Installation Script
# Author: Philip S Wright

set -e

echo "🚀 Installing macOS Desktop Status Widget..."

# Check for required tools
if ! command -v swiftc &> /dev/null; then
    echo "❌ Error: Swift compiler (swiftc) not found"
    echo "   Please install Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# Compile the widget
echo "🔨 Compiling widget..."
swiftc -o desktop-widget desktop-widget.swift -framework Cocoa -framework SwiftUI

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi

# Create installation directory
INSTALL_DIR="$HOME/Applications/DesktopWidget"
mkdir -p "$INSTALL_DIR"

# Copy executable
echo "📦 Installing executable..."
cp desktop-widget "$INSTALL_DIR/"
chmod 755 "$INSTALL_DIR/desktop-widget"

# Handle background image with protection
if [ -f "background.jpg" ]; then
    echo "🖼️ Installing and protecting background image..."
    cp background.jpg "$INSTALL_DIR/"
    
    # Set restrictive permissions (owner read-only)
    chmod 400 "$INSTALL_DIR/background.jpg"
    
    # Verify permissions
    PERMS=$(stat -f "%Lp" "$INSTALL_DIR/background.jpg")
    if [ "$PERMS" = "400" ]; then
        echo "🔒 Background image protected (permissions: $PERMS)"
    else
        echo "⚠️  Warning: Failed to set restrictive permissions on background image"
    fi
else
    echo "⚠️  No background.jpg found - widget will use default styling"
fi

# Create launch script
echo "📝 Creating launch script..."
cat > "$INSTALL_DIR/launch.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
./desktop-widget &
echo "Desktop widget started (PID: $!)"
EOF

chmod 755 "$INSTALL_DIR/launch.sh"

# Create stop script
echo "🛑 Creating stop script..."
cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
pkill -f "desktop-widget" && echo "Desktop widget stopped" || echo "No running widget found"
EOF

chmod 755 "$INSTALL_DIR/stop.sh"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📂 Widget installed to: $INSTALL_DIR"
echo ""
echo "🚀 To start the widget:"
echo "   $INSTALL_DIR/launch.sh"
echo ""
echo "🛑 To stop the widget:"
echo "   $INSTALL_DIR/stop.sh"
echo ""
echo "🔧 To uninstall:"
echo "   rm -rf $INSTALL_DIR"
echo ""
echo "🔒 Background image is protected with read-only permissions"
echo "   Only the owner can access it, preventing tampering by other users"
echo ""