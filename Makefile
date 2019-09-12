test:
	luacheck .
	busted -c --lpath=./lib/?.lua
	luacov lib/
	cat luacov.report.out
