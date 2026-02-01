.PHONY: lint test man release install uninstall man-install

# Default install prefix:
# - root: /usr/local
# - user: /usr/local if writable, otherwise ~/.local
PREFIX ?= $(shell \
  if [ "$$(id -u)" -eq 0 ]; then \
    echo /usr/local; \
  elif [ -w /usr/local ] || [ -w /usr/local/bin ] || [ -w /usr/local/lib ]; then \
    echo /usr/local; \
  else \
    echo "$$HOME/.local"; \
  fi)
BINDIR ?= $(PREFIX)/bin
LIBDIR ?= $(PREFIX)/lib/normelog
MANDIR ?= $(PREFIX)/share/man/man1

# Detect if we are installing system-wide or user-local
ifeq ($(PREFIX),/usr/local)
  BASHCOMP_DIR ?= /etc/bash_completion.d
  ZSHCOMP_DIR ?= /usr/share/zsh/site-functions
else ifeq ($(PREFIX),/usr)
  BASHCOMP_DIR ?= /etc/bash_completion.d
  ZSHCOMP_DIR ?= /usr/share/zsh/site-functions
else
  # User-local install
  BASHCOMP_DIR ?= $(PREFIX)/share/bash-completion/completions
  ZSHCOMP_DIR ?= $(PREFIX)/share/zsh/site-functions
endif

lint:
	./scripts/lint.sh

test:
	./tests/run_tests.sh

man:
	./scripts/gen-man.sh

release:
	@echo "Tag with ./scripts/release-tag.sh vX.Y.Z"

install:
	install -d "$(BINDIR)"
	install -m 0755 bin/normelog "$(BINDIR)/normelog"
	install -d "$(LIBDIR)"
	install -m 0644 lib/*.sh "$(LIBDIR)/"
	install -d "$(MANDIR)"
	install -m 0644 share/man/normelog.1 "$(MANDIR)/normelog.1"
	@./scripts/install-manpath.sh "$(PREFIX)" || true
	@if [ -n "$(BASHCOMP_DIR)" ]; then \
	  if [ ! -d "$(BASHCOMP_DIR)" ]; then install -d "$(BASHCOMP_DIR)" >/dev/null 2>&1 || true; fi; \
	  if [ -d "$(BASHCOMP_DIR)" ] && [ -w "$(BASHCOMP_DIR)" ] && [ -x "$(BASHCOMP_DIR)" ]; then \
		if install -m 0644 share/completion/normelog.bash "$(BASHCOMP_DIR)/normelog" >/dev/null 2>&1; then \
		  echo "installed bash completion to $(BASHCOMP_DIR)"; \
		else \
		  echo "skip bash completion (cannot install to $(BASHCOMP_DIR))"; \
		fi; \
	  else \
		echo "skip bash completion (cannot write to $(BASHCOMP_DIR))"; \
	  fi; \
	fi
	@if [ -n "$(ZSHCOMP_DIR)" ]; then \
	  if [ ! -d "$(ZSHCOMP_DIR)" ]; then install -d "$(ZSHCOMP_DIR)" >/dev/null 2>&1 || true; fi; \
	  if [ -d "$(ZSHCOMP_DIR)" ] && [ -w "$(ZSHCOMP_DIR)" ] && [ -x "$(ZSHCOMP_DIR)" ]; then \
		if install -m 0644 share/completion/_normelog.zsh "$(ZSHCOMP_DIR)/_normelog" >/dev/null 2>&1; then \
		  echo "installed zsh completion to $(ZSHCOMP_DIR)"; \
		else \
		  echo "skip zsh completion (cannot install to $(ZSHCOMP_DIR))"; \
		fi; \
	  else \
		echo "skip zsh completion (cannot write to $(ZSHCOMP_DIR))"; \
	  fi; \
	fi
	@echo "installed $(BINDIR)/normelog"
	@case ":$$PATH:" in *:"$(BINDIR)":*) ;; *) echo "note: add $(BINDIR) to your PATH to use 'normelog'";; esac

uninstall:
	@rm -f "$(BINDIR)/normelog"
	@rm -rf "$(LIBDIR)"
	@rm -f "$(MANDIR)/normelog.1"
	@rm -f "$(BASHCOMP_DIR)/normelog" 2>/dev/null || true
	@rm -f "$(ZSHCOMP_DIR)/_normelog" 2>/dev/null || true
	@echo "uninstalled normelog"

man-install:
	@if command -v mandb >/dev/null 2>&1; then mandb -q || true; fi
