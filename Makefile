# macOS Desktop Status Widget Makefile

# Default target
all: desktop-widget

# Compile the widget
desktop-widget: desktop-widget.swift
	swiftc -o desktop-widget desktop-widget.swift -framework Cocoa -framework SwiftUI

# Install (copy to Applications)
install: desktop-widget
	mkdir -p ~/Applications/DesktopWidget
	cp desktop-widget ~/Applications/DesktopWidget/
	if [ -f background.jpg ]; then \
		cp background.jpg ~/Applications/DesktopWidget/ && \
		chmod 400 ~/Applications/DesktopWidget/background.jpg && \
		echo "Background image installed and protected"; \
	else \
		echo "No background.jpg found, skipping..."; \
	fi
	echo "Widget installed to ~/Applications/DesktopWidget/"

# Clean build artifacts
clean:
	rm -f desktop-widget
	rm -rf /tmp/DesktopWidget-AutoSave

# Run the widget
run: desktop-widget
	./desktop-widget &

# Stop any running widget instances
stop:
	pkill -f "desktop-widget" || echo "No running widget found"

# Restart the widget
restart: stop
	sleep 1
	$(MAKE) run

# Show help
help:
	@echo "Available targets:"
	@echo "  all      - Compile the widget (default)"
	@echo "  install  - Install to ~/Applications/DesktopWidget/"
	@echo "  clean    - Remove build artifacts"
	@echo "  run      - Start the widget"
	@echo "  stop     - Stop any running widget"
	@echo "  restart  - Stop and restart the widget"
	@echo "  help     - Show this help message"

.PHONY: all install clean run stop restart help