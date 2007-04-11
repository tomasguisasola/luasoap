# $Id: Makefile,v 1.12 2007/04/11 00:14:28 tomas Exp $

LUA_DIR= /usr/local/share/lua/5.1

LUAS= src/init.lua src/http.lua src/server.lua


build clean:

install:
	mkdir -p $(LUA_DIR)/soap
	cp $(LUAS) $(LUA_DIR)/soap
