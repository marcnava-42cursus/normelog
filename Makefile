.PHONY: lint test man release

lint:
	./normelog/scripts/lint.sh

test:
	@echo "No tests yet (add BATS)"

man:
	./normelog/scripts/gen-man.sh

release:
	@echo "Tag with ./normelog/scripts/release-tag.sh vX.Y.Z"

