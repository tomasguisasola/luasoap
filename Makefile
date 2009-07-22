# $Id: Makefile,v 1.13 2009/07/22 19:02:46 tomas Exp $

LUA_DIR= /usr/local/share/lua/5.1

LUAS= src/init.lua src/client.lua src/server.lua

build clean:

install:
	mkdir -p $(LUA_DIR)/soap
	cp $(LUAS) $(LUA_DIR)/soap
