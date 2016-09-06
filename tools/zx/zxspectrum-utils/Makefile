CXX=gcc
CXXFLAGS=-Wall
INSTALL=install -c
UNINSTALL=rm -f
TARGETS = breplace mb2tap mbdir mbload d802tap tap2d80 tap2mbd tap2mbhdd bin2tap bin2mbd binto0 dirhob dirtap dir0 hobto0 lstbas tapto0 tsttap 0tobin 0tohob 0totap makesna tzx2tap tap2tzx permutor lstrd createtrd hobeta2trd

all:
	cd ./src; make ${TARGETS}

install:
	cd ./bin; make install

uninstall:
	cd ./bin; make uninstall

clean:
	cd ./bin; make clean
