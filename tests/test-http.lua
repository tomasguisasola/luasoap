-- $Id: test-http.lua,v 1.4 2009/07/22 19:02:46 tomas Exp $

local soap_client = require"soap.client"

local request = {
  url = "http://www.dneonline.com/calculator.asmx",
  soapaction = "http://tempuri.org/Add",
  namespace = "http://tempuri.org/",
  method = "Add",
  entries = {
    { tag = "intA", 1 },
    { tag = "intB", 2 },
  }
}

local ns, meth, ent = soap_client.call (request)
assert (meth == "AddResponse")
assert (type(ent) == "table")
assert (type(ent[1]) == "table")
assert (ent[1].tag == "AddResult")
assert (ent[1][1] == '3')

print(soap_client._VERSION, "Ok!")
