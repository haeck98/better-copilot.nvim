.PHONY: test test-local

test-local:
	nvim --headless -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = './scripts/minimal_init.vim' }"
