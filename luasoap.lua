---------------------------------------------------------------------
-- LuaSoap implementation for Lua.
-- See Copyright Notice in license.html
-- $Id: luasoap.lua,v 1.1 2004/03/09 10:19:20 tomas Exp $
---------------------------------------------------------------------

local print = print

local assert, ipairs, pairs, type = assert, ipairs, pairs, type
local getn, tconcat, tinsert, tremove = table.getn, table.concat, table.insert, table.remove
local format, strlen = string.format, string.len
local max = math.max

local Public = {}
setmetatable (Public, {__index = function (t, n)
	error ("undeclared variable "..n, 2)
end })

soap = Public

setfenv (1, Public)

local serialize

---------------------------------------------------------------------
-- Serialize the table of attributes.
-- @param a Table with the attributes of an element.
-- @return String representation of the object.
---------------------------------------------------------------------
local function attrs (a)
	if not a then
		return ""
		--return "--no attrs--"
	else
		local c = {}
		if a[1] then
			for i, v in ipairs (a) do
				tinsert (c, format ("%s=%q", v, a[v]))
			end
		else
			for i, v in pairs (a) do
				tinsert (c, format ("%s=%q", i, v))
			end
		end
		local attrs = tconcat (c, " ")
		if strlen (attrs) > 0 then
			attrs = " "..attrs
		end
		return attrs
	end
end

---------------------------------------------------------------------
-- Serialize the children of an object.
-- @param obj Table with the object to be serialized.
-- @return String representation of the children.
---------------------------------------------------------------------
local function contents (obj)
	if not obj[1] then
		contents = ""
	else
		local c = {}
		for i, v in ipairs (obj) do
			c[i] = serialize (v)
		end
		return tconcat (c)
	end
end

---------------------------------------------------------------------
-- Serialize an object.
-- @param obj Table with the object to be serialized.
-- @return String with representation of the object.
---------------------------------------------------------------------
serialize = function (obj)
	local tt = type(obj)
	if tt == "string" or tt == "number" then
		return obj
	elseif tt == "table" then
		local t = obj.tag
		assert (t, "Invalid table format (no `tag' field)")
		return format ("<%s%s>%s</%s>", t, attrs(obj.attr), contents(obj), t)
	else
		return ""
	end
end

---------------------------------------------------------------------
-- Add header element (if it exists) to object.
-- Cleans old header element anyway.
---------------------------------------------------------------------
local header_template = {
	tag = "SOAP-ENV:Header",
}
local function insert_header (obj, header)
	-- remove old header
	if obj[2] then
		tremove (obj, 1)
	end
	if header then
		header_template[1] = header
		tinsert (obj, 1, header_template)
	end
end

---------------------------------------------------------------------
-- Converts a LuaExpat table into a SOAP message.
-- @param namespace String with the namespace of the elements.
---------------------------------------------------------------------
local envelope_template = {
	tag = "SOAP-ENV:Envelope",
	attr = { "xmlns:SOAP-ENV", "SOAP-ENV:encodingStyle",
		["xmlns:SOAP-ENV"] = "http://schemas.xmlsoap.org/soap/envelope/",
		["SOAP-ENV:encodingStyle"] = "http://schemas.xmlsoap.org/soap/encoding/",
	},
	{
		tag = "SOAP-ENV:Body",
		[1] = {
			tag = nil, -- must be completed
			attr = {}, -- must be completed
		},
	}
}
function encode (namespace, method, entries, header)
	-- Cleans old header and insert a new one (if it exists).
	insert_header (envelope_template, header)
	-- Sets new body contents (and erase old content).
	local body = (envelope_template[2] and envelope_template[2][1]) or envelope_template[1][1]
	for i = 1, max (getn(body), getn(entries)) do
		body[i] = entries[i]
	end
	-- Sets method (actually, the table's tag) and namespace.
	body.tag = (namespace and "m:" or "")..method
	body.attr["xmlns:m"] = namespace
	return serialize (envelope_template)
end

---------------------------------------------------------------------
--
---------------------------------------------------------------------
function decode (doc)
	local obj = assert (dom.parse (doc))
	assert (obj.tag == "SOAP-ENV:Envelope", "Not a SOAP Envelope: "..
		tostring(obj.tag))
	if obj[1].tag == "SOAP-ENV:Body" then
		obj = obj[1]
	elseif obj[2].tag == "SOAP-ENV:Body" then
		obj = obj[2]
	else
		error ("Couldn't find SOAP Body!")
	end
	local namespace = find_xmlns (obj.attr)
	local method = obj.tag
	return namespace, method, obj[1] -- ?????????????????
end
