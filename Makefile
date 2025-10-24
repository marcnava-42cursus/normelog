.PHONY: lint test man release install uninstall man-install

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/share/man/man1
BASHCOMP_DIR ?= /etc/bash_completion.d
ZSHCOMP_DIR ?= /usr/share/zsh/site-functions

lint:
	./scripts/lint.sh

test:
	@echo "No tests yet (add BATS)"

man:
	./scripts/gen-man.sh

release:
	@echo "Tag with ./scripts/release-tag.sh vX.Y.Z"

install:
	install -d "$(BINDIR)"
	install -m 0755 bin/normelog "$(BINDIR)/normelog"
	install -d "$(MANDIR)"
	install -m 0644 share/man/normelog.1 "$(MANDIR)/normelog.1"
	@if [ -n "$(BASHCOMP_DIR)" ]; then \
	  if install -d "$(BASHCOMP_DIR)" >/dev/null 2>&1; then \
		install -m 0644 share/completion/normelog.bash "$(BASHCOMP_DIR)/normelog"; \
		echo "installed bash completion to $(BASHCOMP_DIR)"; \
	  else \
		echo "skip bash completion (cannot write to $(BASHCOMP_DIR))"; \
	  fi; \
	fi
	@if [ -n "$(ZSHCOMP_DIR)" ]; then \
	  if install -d "$(ZSHCOMP_DIR)" >/dev/null 2>&1; then \
		install -m 0644 share/completion/_normelog.zsh "$(ZSHCOMP_DIR)/_normelog"; \
		echo "installed zsh completion to $(ZSHCOMP_DIR)"; \
	  else \
		echo "skip zsh completion (cannot write to $(ZSHCOMP_DIR))"; \
	  fi; \
	fi
	@echo "installed $(BINDIR)/normelog"

uninstall:
	@rm -f "$(BINDIR)/normelog"
	@rm -f "$(MANDIR)/normelog.1"
	@rm -f "$(BASHCOMP_DIR)/normelog" 2>/dev/null || true
	@rm -f "$(ZSHCOMP_DIR)/_normelog" 2>/dev/null || true
	@echo "uninstalled normelog"

man-install:
	@if command -v mandb >/dev/null 2>&1; then mandb -q || true; fi
