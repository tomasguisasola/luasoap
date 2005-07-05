require"soap"

---------------------------------------------------------------------
-- Register the methods.
-- @param tab_or_func Table or mapping function.
-- If a table is given, it can have one level of objects and then the
-- methods;
-- if a function is given, it will be used as the dispatcher.
-- The given function should return a Lua function that implements.
---------------------------------------------------------------------
local dispatch = error
local function srvMethods (tab_or_func)
	local t = type (tab_or_func)
	if t == "function" then
		dispatch = tab_or_func
	elseif t == "table" then
		dispatch = function (name)
--[[
			local ok, _, obj, method = string.find (name, "^([^.]+)%.(.+)$")
			if not ok then
				return tab_or_func[name]
			else
				return function (...)
					return tab_or_func[obj][method] (obj, unpack (arg))
				end
			end
--]]
			return tab_or_func[name]
		end
	else
		error ("Argument is neither a table nor a function")
	end
end

---------------------------------------------------------------------
local function respond (resp)
	--cgilua.header ("Date", os.date())
	--cgilua.header ("Server", "Me")
	cgilua.header ("Content-length", string.len (resp))
	cgilua.header ("Connection", "close")
	cgilua.contentheader ("text", "xml")
	cgilua.put (resp)
end

---------------------------------------------------------------------
--[[
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

function assert (cond, msg)
	if not cond then
		respond (xmlrpc.srvEncode (
			{ code = 2, message = msg, },
			true
		))
		os.exit() -- !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	end
end
--]]
---------------------------------------------------------------------
function builderrorenvelope (faultcode, faultstring, extra)
	return soap.encode (nil, "SOAP-ENV:Fault", {
        { tag = "faultcode", faultcode, },
        { tag = "faultstring", faultstring, },
		extra,
    })
end

---------------------------------------------------------------------
cgilua.seterroroutput (function (msg)
	respond (builderrorenvelope ("SOAP-ENV:Server", msg))
--[[
	respond (soap.encode (nil, "SOAP-ENV:Fault", {
        { tag = "faultcode", "SOAP-ENV:Server", },
        { tag = "faultstring", "Server Error", },
        {
            tag = "detail",
            {
                tag = "e:myfaultdetails",
                attr = { "xmlns:e", ["xmlns:e"] = "Some-URI", },
                { tag = "message", msg, },
                { tag = "errorcode", 1001, },
            },
        },
    }))
--]]
end)

---------------------------------------------------------------------
local function decodedata (doc)
--[[
require"cgilua.serialize"
cgilua.errorlog("xmldoc:\n")
cgilua.errorlog(type(doc).."\n")
cgilua.errorlog(doc.."\n")
--]]
	local namespace, elem_name, elems = soap.decode (doc)
--[[
cgilua.errorlog("namespace: "..tostring(namespace))
cgilua.errorlog("\n")
cgilua.errorlog("elem_name: "..tostring(elem_name))
cgilua.errorlog("\n")
cgilua.errorlog("elems: ")
cgilua.serialize(elems, cgilua.errorlog)
cgilua.errorlog("\n")
--]]

	local func = dispatch (elem_name)
cgilua.errorlog ("elem_name = "..tostring(elem_name).."\n")
cgilua.errorlog ("doc = [["..doc.."]]\n")
	assert (type(func) == "function", "Unavailable method: `"..tostring(elem_name).."'")

	return namespace, func, (elems or {})
end

---------------------------------------------------------------------
local function callfunc (func, namespace, arg_table)
	local result = { pcall (func, namespace, unpack (arg_table)) }
	local ok = result[1]
	if not ok then
		result = builderrorenvelope ("SOAP-ENV:Server", result[2])
	else
		table.remove (result, 1)
		if table.getn (result) == 1 then
			result = result[1]
		end
	end
	return ok, result
end

---------------------------------------------------------------------
local kepler_home = "http://www.keplerproject.org"
local kepler_products = { "luasql", "lualdap", "luaexpat", "luaxmlrpc", }
local kepler_sites = {
	luasql = kepler_home.."/luasql",
	lualdap = kepler_home.."/lualdap",
	luaexpat = kepler_home.."/luaexpat",
	luaxmlrpc = kepler_home.."/luaxmlrpc",
}

local __methods
__methods = {
	listMethods = function (namespace)
		local l = {}
		for name in pairs (__methods) do
			table.insert (l, { tag = "methodName", name })
		end
		return soap.encode (nil, "listMethodsResponse", l)
	end,
	products = function (self)
		local l = {}
		for i, name in ipairs (kepler_products) do
			table.insert (l, { tag = "productName", name })
		end
		return soap.encode (nil, "productList", l)
	end,
	doubler = function (namespace, num_array)
		for i, num in ipairs(num_array) do
			num[1] = num[1] * 2
		end
		return soap.encode (nil, "doublertest", num_array)
	end,
}

---------------------------------------------------------------------
-- Main
---------------------------------------------------------------------

srvMethods (__methods)
--[[
cgilua.errorlog("cgi:")
cgilua.errorlog(tostring(cgi))
c = 0
for i,v in pairs(cgi) do
c = c+1
cgilua.errorlog("#"..c.." ")
cgilua.errorlog(tostring(i))
cgilua.errorlog" = "
cgilua.errorlog(tostring(v))
cgilua.errorlog"\n"
end
cgilua.errorlog("!\n")
--]]
local namespace, func, arg_table = decodedata (cgi[1])
local ok, result = callfunc (func, namespace, arg_table)
respond (result)
