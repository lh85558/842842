
# TP-LINK 842N V3 LEDE Print Server Makefile

.PHONY: all clean build download config prepare

# Configuration
OPENWRT_VERSION = 21.02
OPENWRT_BRANCH = openwrt-$(OPENWRT_VERSION)
BUILD_DIR = build
OUTPUT_DIR = output
CONFIG_FILE = config/842n-v3.config

# Colors
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m

all: build

help:
	@echo "$(GREEN)TP-LINK 842N V3 LEDE Print Server Build System$(NC)"
	@echo ""
	@echo "Available targets:"
	@echo "  $(YELLOW)download$(NC)  - Download OpenWrt source code"
	@echo "  $(YELLOW)config$(NC)    - Configure build environment"
	@echo "  $(YELLOW)prepare$(NC)   - Prepare build environment"
	@echo "  $(YELLOW)build$(NC)     - Build firmware"
	@echo "  $(YELLOW)clean$(NC)     - Clean build directory"
	@echo "  $(YELLOW)all$(NC)       - Complete build process"
	@echo ""

download:
	@echo "$(GREEN)Downloading OpenWrt $(OPENWRT_VERSION)...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@cd $(BUILD_DIR) && \
		if [ ! -d "openwrt" ]; then \
			git clone --depth 1 --branch $(OPENWRT_BRANCH) https://github.com/openwrt/openwrt.git; \
		fi
	@echo "$(GREEN)Download completed!$(NC)"

config: download
	@echo "$(GREEN)Configuring build environment...$(NC)"
	@cd $(BUILD_DIR)/openwrt && \
		if [ ! -f "feeds.conf.default" ]; then \
			echo "src-git immortalwrt https://github.com/immortalwrt/packages.git;$(OPENWRT_BRANCH)" >> feeds.conf.default; \
			echo "src-git immortalwrt_luci https://github.com/immortalwrt/luci.git;$(OPENWRT_BRANCH)" >> feeds.conf.default; \
		fi
	@echo "$(GREEN)Configuration completed!$(NC)"

prepare: config
	@echo "$(GREEN)Preparing build environment...$(NC)"
	@cd $(BUILD_DIR)/openwrt && \
		./scripts/feeds update -a && \
		./scripts/feeds install -a
	@cp $(CONFIG_FILE) $(BUILD_DIR)/openwrt/.config
	@cp -r files/* $(BUILD_DIR)/openwrt/files/ 2>/dev/null || true
	@echo "$(GREEN)Preparation completed!$(NC)"

build: prepare
	@echo "$(GREEN)Building firmware...$(NC)"
	@cd $(BUILD_DIR)/openwrt && \
		make defconfig && \
		make download -j$$(nproc) && \
		make -j$$(nproc) V=s
	@mkdir -p $(OUTPUT_DIR)
	@cp $(BUILD_DIR)/openwrt/bin/targets/ath79/generic/*842n-v3*sysupgrade.bin $(OUTPUT_DIR)/ 2>/dev/null || true
	@cp $(BUILD_DIR)/openwrt/bin/targets/ath79/generic/*842n-v3*factory.bin $(OUTPUT_DIR)/ 2>/dev/null || true
	@cp $(BUILD_DIR)/openwrt/bin/targets/ath79/generic/*842n-v3*factory-us.bin $(OUTPUT_DIR)/ 2>/dev/null || true
	@echo "$(GREEN)Build completed!$(NC)"
	@echo "$(YELLOW)Output files in $(OUTPUT_DIR):$(NC)"
	@ls -la $(OUTPUT_DIR)/

clean:
	@echo "$(YELLOW)Cleaning build directory...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf $(OUTPUT_DIR)
	@echo "$(GREEN)Clean completed!$(NC)"

info:
	@echo "$(GREEN)Build Information:$(NC)"
	@echo "OpenWrt Version: $(OPENWRT_VERSION)"
	@echo "Target Device: TP-LINK TL-WR842N V3"
	@echo "Config File: $(CONFIG_FILE)"
	@echo "Build Directory: $(BUILD_DIR)"
	@echo "Output Directory: $(OUTPUT_DIR)"

# Development targets
menuconfig: prepare
	@cd $(BUILD_DIR)/openwrt && make menuconfig

kernel_menuconfig: prepare
	@cd $(BUILD_DIR)/openwrt && make kernel_menuconfig

update: download
	@cd $(BUILD_DIR)/openwrt && \
		git pull && \
		./scripts/feeds update -a && \
		./scripts/feeds install -a

# CI/CD targets
ci-build: prepare
	@cd $(BUILD_DIR)/openwrt && \
		make defconfig && \
		make download -j$$(nproc) && \
		make -j$$(nproc) V=s
	@mkdir -p $(OUTPUT_DIR)
	@cp $(BUILD_DIR)/openwrt/bin/targets/ath79/generic/*842n-v3* $(OUTPUT_DIR)/ 2>/dev/null || true

# Package targets
package-list: prepare
	@cd $(BUILD_DIR)/openwrt && make defconfig
	@echo "$(GREEN)Available packages:$(NC)"
	@cd $(BUILD_DIR)/openwrt && ./scripts/diffconfig.sh

# Utility targets
size-check:
	@echo "$(GREEN)Checking firmware sizes...$(NC)"
	@if [ -d "$(OUTPUT_DIR)" ]; then \
		for file in $(OUTPUT_DIR)/*.bin; do \
			if [ -f "$$file" ]; then \
				size=$$(stat -c%s "$$file"); \
				size_mb=$$(echo "scale=2; $$size/1048576" | bc); \
				echo "$$(basename $$file): $${size_mb}MB"; \
			fi; \
		done; \
	fi

validate:
	@echo "$(GREEN)Validating configuration...$(NC)"
	@if [ -f "$(CONFIG_FILE)" ]; then \
		echo "Config file exists: ✓"; \
	else \
		echo "Config file missing: ✗"; \
		exit 1; \
	fi
	@if [ -d "files" ]; then \
		echo "Files directory exists: ✓"; \
	else \
		echo "Files directory missing: ✗"; \
	fi

# Default target
.DEFAULT_GOAL := help
