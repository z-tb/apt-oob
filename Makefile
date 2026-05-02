.PHONY: test update

test:
	bash unit-tests/run.sh

update:
	bash live-update.sh $(DEST)
