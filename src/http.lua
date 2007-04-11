---------------------------------------------------------------------
-- SOAP over HTTP.
-- See Copyright notice in license.html
-- $Id: http.lua,v 1.5 2007/04/11 00:14:28 tomas Exp $
---------------------------------------------------------------------

local error, tonumber, tostring = error, tonumber, tostring
local concat = (require"table").concat
local ltn12 = require"ltn12"
local request = (require"socket.http").request
local soap = require"soap"

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
			["content-length"] = tostring(request_body:len()),
			["SOAPAction"] = '"'..method..'"',
		},
	}
	local body = concat(tbody)
	if tonumber (code) == 200 then
		return soap.decode (body)
	else
		error (tostring(err or code).."\n\n"..tostring(body))
	end
end
