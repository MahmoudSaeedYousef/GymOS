.PHONY: help \
	be-build be-test be-clean \
	app-get app-l10n app-gen app-analyze app-test app-check \
	android-clean android-apk android-release \
	ios-clean ios-pods \
	verify pr

BACKEND_DIR := ../../backend

# Default target: show all available commands
help:
	@echo "GymOS Commands (running from app/gym_os):"
	@echo "  --- Mobile (Flutter) ---"
	@echo "  make app-get          Run flutter pub get"
	@echo "  make app-l10n         Generate localization files (gen-l10n)"
	@echo "  make app-gen          Run gen-l10n + Drift build_runner"
	@echo "  make app-analyze      Run flutter analyze"
	@echo "  make app-test         Run flutter test"
	@echo "  make app-check        Run analyze + test"
	@echo ""
	@echo "  --- Android (Isolated - Safe for iOS) ---"
	@echo "  make android-clean    Clean Android/Gradle only (preserves build/ios & Pods)"
	@echo "  make android-apk      Build release arm64 APK with split debug info"
	@echo "  make android-release  Clean Android -> pub get -> build release APK"
	@echo ""
	@echo "  --- iOS (Isolated - Safe for Android) ---"
	@echo "  make ios-clean        Clean build/ios only (preserves Android & Pods)"
	@echo "  make ios-pods         Run pod install inside ios/"
	@echo ""
	@echo "  --- Backend (.NET 10) ---"
	@echo "  make be-build         Build backend solution"
	@echo "  make be-test          Run backend unit tests"
	@echo "  make be-clean         Clean backend build artifacts only"
	@echo ""
	@echo "  --- All / Git ---"
	@echo "  make verify           Run backend tests + mobile analyze & tests"
	@echo "  make pr               Create GitHub Pull Request via gh CLI"

# ==============================================================================
# MOBILE (FLUTTER)
# ==============================================================================
app-get:
	flutter pub get

app-l10n:
	flutter gen-l10n

app-gen:
	flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs

app-analyze:
	flutter analyze

app-test:
	flutter test

app-check: app-analyze app-test

# ==============================================================================
# ANDROID (ISOLATED — NEVER TOUCHES iOS)
# ==============================================================================
android-clean:
	@echo "Cleaning Android build artifacts (preserving build/ios & ios/Pods)..."
	find build -maxdepth 1 -mindepth 1 ! -name 'ios' -exec rm -rf {} + 2>/dev/null || true
	cd android && ./gradlew clean

android-apk:
	flutter build apk --release --target-platform android-arm64 --split-debug-info=build/app/intermediates/symbols/arm64
android-open:
	open build/app/outputs/flutter-apk
android-release: android-clean app-get android-apk

# ==============================================================================
# iOS (ISOLATED — NEVER TOUCHES ANDROID)
# ==============================================================================
ios-clean:
	@echo "Cleaning build/ios only (preserving Android build & ios/Pods)..."
	rm -rf build/ios

ios-pods:
	cd ios && pod install

# ==============================================================================
# BACKEND (.NET 10)
# ==============================================================================
be-build:
	cd $(BACKEND_DIR) && dotnet build GymOS.slnx

be-test:
	cd $(BACKEND_DIR) && dotnet test GymOS.slnx

be-clean:
	cd $(BACKEND_DIR) && dotnet clean GymOS.slnx

# ==============================================================================
# VERIFICATION & GIT
# ==============================================================================
verify: be-test app-check

pr:
	gh pr create --web