package = "luasoap"
version = "2.0.1-0"

source = {
url = "",
   url="http://github.com/downloads/tomasguisasola/luasoap/luasoap-2.0.1.tar.gz",
   md5="ebac9d3a04a845765d498907a71429c2",
}

description = {
   summary = "Support for SOAP",
   detailed = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
   homepage = "http://luasoap.luaforge.net/",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
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

