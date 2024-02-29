# Makefile for ripgrep, a wrapper for cargo plus install/dist targets

# don't let make do anything in parallel, cargo build handles that
.NOTPARALLEL:

# install paths
prefix  ?= /usr/local
bindir  ?= $(prefix)/bin
datadir ?= $(prefix)/share
mandir  ?= $(datadir)/man
bashcompdir ?= $(datadir)/bash-completion/completions
fishcompdir ?= $(datadir)/fish/vendor_completions.d
zshcompdir  ?= $(datadir)/zsh/site-functions

# tools
CARGO   ?= cargo
INSTALL ?= install
STRIP   ?= strip
RM      ?= rm -f
ifeq ($(NOSTRIP),)
INSTALL_STRIP ?= $(INSTALL) -s --strip-program=$(STRIP)
else
INSTALL_STRIP ?= $(INSTALL)
endif
TAR ?= tar

# build configuration
# release build default for install/dist, otherwise debug build
ifneq ($(filter install dist,$(MAKECMDGOALS)),)
BUILD_TYPE ?= release
else
BUILD_TYPE ?= debug
endif
# 'make R=1' as a shortcut for 'make BUILD_TYPE=release'
ifeq ($(R),1)
BUILD_TYPE := release
endif
# set flags for release build
ifeq ($(BUILD_TYPE),release)
CARGO_BUILD_FLAGS += --release --locked
endif

# whether to run install commands with sudo
ifeq ($(SUDO_INSTALL),1)
INSTALL := sudo $(INSTALL)
RM      := sudo $(RM)
endif

ifneq ($(TARGET),)
TARGET_DIR = target/$(TARGET)
CARGO_BUILD_FLAGS += --target $(TARGET)
else
TARGET_DIR = target
TARGET := $(shell ci/default_target.sh)
endif

ifeq ($(findstring windows,$(TARGET)),windows)
EXEEXT := .exe
else
EXEEXT :=
endif

EXE := $(TARGET_DIR)/$(BUILD_TYPE)/rg$(EXEEXT)
ASSET_DIR := target/generated

# easy hack to avoid re-running cargo when not needed
SOURCES = $(shell find crates -type f) build.rs Cargo.toml

.PHONY: build
build: $(EXE)
$(EXE): $(SOURCES)
	$(CARGO) build $(CARGO_BUILD_FLAGS)

.PHONY: clean
clean:
	$(CARGO) clean

.PHONY: completions
completions: $(ASSET_DIR)/rg.bash $(ASSET_DIR)/rg.fish $(ASSET_DIR)/_rg

.PHONY: man
man: $(ASSET_DIR)/rg.1

.PHONY: assets
assets: completions man

$(ASSET_DIR)/rg.bash: $(EXE)
	@mkdir -p $(ASSET_DIR)
	$(EXE) --generate complete-bash >$@

$(ASSET_DIR)/rg.fish: $(EXE)
	@mkdir -p $(ASSET_DIR)
	$(EXE) --generate complete-fish >$@

$(ASSET_DIR)/_rg: $(EXE)
	@mkdir -p $(ASSET_DIR)
	$(EXE) --generate complete-zsh >$@

$(ASSET_DIR)/rg.1: $(EXE)
	@mkdir -p $(ASSET_DIR)
	$(EXE) --generate man >$@

.PHONY: install
install: assets
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL_STRIP) -m755 $(EXE) $(DESTDIR)$(bindir)/
	$(INSTALL) -Dm644 $(ASSET_DIR)/rg.bash $(DESTDIR)$(bashcompdir)/rg
	$(INSTALL) -Dm644 $(ASSET_DIR)/rg.fish $(DESTDIR)$(fishcompdir)/rg.fish
	$(INSTALL) -Dm644 $(ASSET_DIR)/_rg $(DESTDIR)$(zshcompdir)/_rg
	$(INSTALL) -Dm644 $(ASSET_DIR)/rg.1 $(DESTDIR)$(mandir)/man1/rg.1

.PHONY: uninstall
uninstall:
	$(RM) $(DESTDIR)$(bindir)/$(notdir $(EXE))
	$(RM) $(DESTDIR)$(bashcompdir)/rg
	$(RM) $(DESTDIR)$(fishcompdir)/rg.fish
	$(RM) $(DESTDIR)$(zshcompdir)/_rg
	$(RM) $(DESTDIR)$(mandir)/man1/rg.1

# this has no dependencies, the build-deb script handles building everything.
# The leading + silences jobserver warnings, since build-deb internally calls "make completions"
.PHONY: deb
deb:
	+ci/build-deb
