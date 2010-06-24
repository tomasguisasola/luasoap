-- $Id: test-http.lua,v 1.4 2009/07/22 19:02:46 tomas Exp $

local soap_client = require"soap.client"

local request = {
  url = "http://validator.soapware.org",
  soapaction = "/validator1",
  namespace = nil,
  method = "easyStructTest",
  entries = {
    {
      tag = "stooges",
      { tag = "curly", attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, -5 },
      { tag = "larry", attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, 5 },
      { tag = "moe",   attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, 41 },
    },
  }
}

local ns, meth, ent = soap_client.call (request)
assert(tonumber(ent[2][1]) == 41)

request.entries[1][2][1] = "abc"
soap_client.call (request)
print"Ok!"
