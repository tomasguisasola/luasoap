---------------------------------------------------------------------
-- SOAP over HTTP.
-- See Copyright notice in license.html
-- $Id: http.lua,v 1.4 2005/06/10 00:34:27 tomas Exp $
---------------------------------------------------------------------

require"socket.http"
require"ltn12"
require"soap"

local request = socket.http.request

module("soap.http")

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param namespace String with the namespace of the elements.
-- @param method String with the method's name.
-- @param entries Table of SOAP elements (LuaExpat's format).
-- @param header Table describing the header of the SOAP-ENV (optional).
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function call (url, namespace, method, entries, headers)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = soap.encode(namespace, method, entries, headers)
	local err, code, headers, status = request {
		url = url,
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = {
			["Content-Type"] = "text/xml",
			["content-length"] = tostring(string.len(request_body)),
			["SOAPAction"] = '"'..method..'"',
		},
	}
	local body = table.concat(tbody)
	if tonumber (code) == 200 then
		return soap.decode (body)
	else
		error (tostring(err or code).."\n\n"..tostring(body))
	end
end
