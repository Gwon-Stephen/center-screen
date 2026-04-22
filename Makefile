APP_NAME     = CenterScreen
BUNDLE_NAME  = $(APP_NAME).app
RELEASE_DIR  = .build/release
DEBUG_DIR    = .build/debug
BUNDLE_DIR   = $(BUNDLE_NAME)/Contents
ICON_SRC     = Resources/AppIcon.icns

.PHONY: build release app install run clean icon

## Build debug binary (fast, for development)
build:
	swift build

## Build optimised release binary
release:
	swift build -c release

## Create a distributable .app bundle from the release binary
app: release
	@echo "Packaging $(BUNDLE_NAME)..."
	@rm -rf $(BUNDLE_NAME)
	@mkdir -p $(BUNDLE_DIR)/MacOS
	@mkdir -p $(BUNDLE_DIR)/Resources
	@cp $(RELEASE_DIR)/$(APP_NAME) $(BUNDLE_DIR)/MacOS/$(APP_NAME)
	@cp Info.plist $(BUNDLE_DIR)/Info.plist
	@if [ -f $(ICON_SRC) ]; then \
		cp $(ICON_SRC) $(BUNDLE_DIR)/Resources/AppIcon.icns; \
		echo "Icon bundled."; \
	else \
		echo "No icon found — run: make icon INPUT=your-image.png"; \
	fi
	@echo "Done → $(BUNDLE_NAME)"

## Install the app bundle to ~/Applications
install: app
	@mkdir -p ~/Applications
	@rm -rf ~/Applications/$(BUNDLE_NAME)
	@cp -r $(BUNDLE_NAME) ~/Applications/$(BUNDLE_NAME)
	@echo "Installed to ~/Applications/$(BUNDLE_NAME)"
	@echo "Open it once, then add it to System Settings → General → Login Items"

## Run the debug binary directly (no app bundle)
run: build
	$(DEBUG_DIR)/$(APP_NAME)

## Convert a PNG to AppIcon.icns  (e.g. make icon INPUT=my-ai-image.png)
icon:
	@[ -n "$(INPUT)" ] || (echo "Usage: make icon INPUT=path/to/image.png" && exit 1)
	@bash scripts/make_icon.sh $(INPUT)

## Remove all build artifacts and the app bundle
clean:
	swift package clean
	@rm -rf $(BUNDLE_NAME)
