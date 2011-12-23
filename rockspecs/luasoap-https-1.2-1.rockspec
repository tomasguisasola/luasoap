package = "luasoap-https"
version = "1.2-1"

source = {
	url="https://github.com/downloads/tomasguisasola/luasoap/luasoap-3.0.tar.gz",
	md5 = "",
}

description = {
   summary = "Support for SOAP over HTTPS",
   detailed = [[LuaSOAP provides a very simple API that convert Lua tables to and from XML documents.
This module provides a way to use SOAP over HTTPS.]],
   homepage = "http://luasoap.luaforge.net/",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.0",
   "luasoap >= 3.0-1",
   "luasec >= 0.4-1",
}

build = {
   type = "builtin",
   modules = {
      ["soap.client.https"] = "src/client/https.lua",
   }
}

