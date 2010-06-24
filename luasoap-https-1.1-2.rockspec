package = "luasoap-https"
version = "1.1-2"

source = {
   url="http://www.tecgraf.puc-rio.br/~tomas/luasoap/luasoap-2.0.0-1.tar.gz",
}

description = {
   summary = "Support for SOAP over HTTPS",
   detailed = [[LuaSOAP provides a very simple API that convert Lua tables to and from XML documents.
This module provides a way to use SOAP over HTTPS.]],
   homepage = "http://luasoap.luaforge.net/",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
   "luasoap >= 1.1-1",
   "luasec >= 0.4-1",
}

build = {
   type = "builtin",
   modules = {
      ["soap.client.https"] = "src/client/https.lua",
   }
}

