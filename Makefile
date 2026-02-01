SCHEME = Restx
CONFIG = Debug
BUILD_DIR = build

.PHONY: clean build release

clean:
	rm -rf $(BUILD_DIR)

build:
	xcodebuild -scheme $(SCHEME) -configuration $(CONFIG) -derivedDataPath $(BUILD_DIR)

release: clean
	xcodebuild -scheme $(SCHEME) -sdk macosx -configuration Release -derivedDataPath $(BUILD_DIR)
