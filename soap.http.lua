---------------------------------------------------------------------
-- SOAP over HTTP.
-- See Copyright notice in license.html
-- $Id: soap.http.lua,v 1.1 2004/03/16 16:42:22 tomas Exp $
---------------------------------------------------------------------

require"luasocket"
require"soap"

local post = socket.http.post

soap.http = {}

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param namespace
---------------------------------------------------------------------
function soap.http.call (url, namespace, method, entries, headers)
	local body, headers, code, err = post {
		url = url,
		body = soap.encode (namespace, method, entries, headers),
		headers = {
			["Content-type"] = "text/xml",
			["SOAPAction"] = '"'..method..'"',
		},
	}
	if tonumber (code) == 200 then
		return soap.decode (body)
	else
		error ((err or code).."\n\n"..body)
	end
end
