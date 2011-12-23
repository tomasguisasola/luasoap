package = "luasoap"
version = "3.0-1"

source = {
url = "",
   url="http://github.com/downloads/tomasguisasola/luasoap/luasoap-3.0.tar.gz",
   md5="",
}

description = {
   summary = "Support for SOAP",
   detailed = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
   homepage = "",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.0",
   "luaexpat >= 1.1.0-3",
   "luasocket >= 2.0.2-1",
}

build = {
   type = "builtin",
   modules = {
      soap  = "src/soap.lua",
      ["soap.server"] = "src/server.lua",
      ["soap.client"] = "src/client.lua",
   }
}

