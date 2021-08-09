.PHONY: test
test:
	nvim -u tests/minimal_init.vim --headless -c "PlenaryBustedDirectory tests"
