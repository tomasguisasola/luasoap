------------------------------------------------------------------------------
-- LuaSOAP support for service development.
-- See Copyright Notice in license.html
------------------------------------------------------------------------------

local assert, getmetatable, pairs, pcall, require, setmetatable, tostring, type, unpack = assert, getmetatable, pairs, pcall, require, setmetatable, tostring, type, unpack

local cgilua = cgilua or require"cgilua"
local soap = require"soap"
local string = require"string"
local table = require"table"


------------------------------------------------------------------------------
local M = {
	_COPYRIGHT = "Copyright (C) 2004-2015 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 4.0 service helping functions",

	encoding = "utf-8", -- default encoding
	mode = 1.2, -- default mode
}
M.__index = M

------------------------------------------------------------------------------
function M:xml_header ()
	return '<?xml version="1.0" encoding="'..self.encoding..'"?>\n'
end

------------------------------------------------------------------------------
function M:respond(resp, header)
	local full_response = self:xml_header()..resp
	cgilua.header("Content-length", string.len(full_response))
	cgilua.header("Connection", "close")
	cgilua.contentheader("text", "xml")
	if header then
		cgilua.put(header)
	end
	cgilua.put(full_response)
end

------------------------------------------------------------------------------
function M:builderrorenvelope(faultcode, faultstring, extra)
	faultstring = faultstring:gsub("([<>])", { ["<"] = "&lt;", [">"] = "&gt;", })
	return soap.encode({
		entries = {
			{ tag = "faultcode", faultcode, },
			{ tag = "faultstring", faultstring, },
			extra,
		},
		method = "soap:Fault",
	})
end

------------------------------------------------------------------------------
function M:decodedata(doc)
	local namespace, elem_name, elems = soap.decode(doc)
	assert (self.methods[elem_name], "Unavailable method: `"..tostring(elem_name).."'")
	local func = self.methods[elem_name].method
	assert (type (func) == "function", "Registered method is not a function: `"..tostring(elem_name).."'")

	return namespace, func, (elems or {})
end

------------------------------------------------------------------------------
function M:callfunc(func, namespace, arg_table)
	local result = { pcall(func, namespace, arg_table) }
	local ok = result[1]
	if not ok then
		result = self:builderrorenvelope("soap:ServiceError", result[2])
	else
		table.remove(result, 1)
		if #result == 1 then
			result = result[1]
		end
	end
	return ok, result
end

---------------------------------------------------------------------
local function generate_disco()
	return self:xml_header().."<discovery></discovery>"

end

------------------------------------------------------------------------------
-- Exports methods that can be used by the server.
-- @param desc Table with the method description.
--	The programmer MUST provide different tables for different methods.
------------------------------------------------------------------------------
function M:export(desc)
	assert (getmetatable (self) == M, "Invalid argument #1: it must be a soap server (maybe you called this function with a dot (.), not with a colon (:))")
	if desc.request then
		desc.request.name = desc.request.name or (desc.name.."SoapIn")
	end
	if desc.response then
		desc.response.name = desc.response.name or (desc.name.."SoapOut")
		local f = desc.method
		desc.method = function (...) -- ( namespace, unpack(arguments) )
			local res = { f(...) }
			return soap.encode{
				namespace = self.targetNamespace,
				method = desc.response.name,
				entries = res,
			}
		end
	end
	if desc.fault then
		desc.fault.name = desc.fault.name or (desc.name.."SoapFault")
	end
	assert(desc.name, "A method must have a name!")
	desc.portTypeName =  desc.portTypeName or (desc.name.."Soap")
	desc.bindingName =  desc.bindingName or (desc.name.."Soap")
	self.methods[desc.name] = desc
end

------------------------------------------------------------------------------
-- Handles the request received by the calling script.
-- @param postdata String with POST data from the server.
-- @param querystring String with the query string.
------------------------------------------------------------------------------
function M:handle_request(postdata, querystring)
	assert(getmetatable(self) == M, "Invalid argument #1: it must be a soap server (maybe you called this function with a dot (.), not with a colon (:))")
	cgilua.seterroroutput(self.fatalerrorfunction)

	local namespace, func, arg_table
	if postdata then
		namespace, func, arg_table = self:decodedata(postdata)
	else
		if not querystring or querystring=='' or querystring:lower() == "wsdl" then -- WSDL service
			func = function ()
				-- import all wsdl functions into server
				for n, m in pairs (require"soap.wsdl") do
					if type(m) == "function" then
						assert (M[n] == nil, "Module 'soap.wsdl' not allowed to override method 'soap."..n.."'")
						M[n] = m
					end
				end
				return self:generate_wsdl ()
			end
		elseif querystring == "disco" then -- discovery service
--			func = function ()
--				return __service.disco or generate_disco()
--			end
		else
--			func = __methods["listMethods"]
		end
		arg_table = {}
	end

	local ok, result = self:callfunc(func, namespace, arg_table)
	self:respond(result)
end

------------------------------------------------------------------------------
-- Create a new SOAP server
-- @param server_description Table with SOAP server description and configuration.
-- @return Table with server representation.

function M.new (server)
	assert (server ~= M, "Incorrect creation of new server: you must call soap.server.new with a dot (.), not with a colon (:)")
	server.fatalerrorfunction = function (msg)
		server:respond (
			server:builderrorenvelope ("soap:ServerError", msg)
		)
    end
	server.methods = {}
	server.types = server.types or {}
	if type(server.mode) ~= "table" then
		server.mode = { server.mode or M.mode }
	end
	return setmetatable (server, M)
end

------------------------------------------------------------------------------
return M
