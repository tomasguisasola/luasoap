------------------------------------------------------------------------------
-- LuaSOAP support to WSDL semi-automatic generation.
-- See Copyright Notice in license.html
------------------------------------------------------------------------------

local strformat = require"string".format
local tconcat = require"table".concat

local M = {
	_COPYRIGHT = "Copyright (C) 2015 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 4.0 WSDL generation helping functions",
}

-- internal data structure details
-- self.name -- service name
-- self.encoding -- string with XML encoding
-- self.targetNamespace -- target namespace
-- self.otherNamespaces -- optional table with other namespaces
-- self.url
-- self.wsdl -- string with complete WSDL document
-- self.types[..] -- table indexed by numbers (to guarantee the order of type definitions)
-- self.methods[methodName] -- table indexed by strings (each method name)
--	request -- table 
--		name -- string with message request name
--		[..] -- table with parameter definitions
--			name -- string with part name
--			element -- string with type element's name (optional)
--			type -- string with type (simple or complex) name (optional)
--	response -- idem
--	portTypeName -- string with portType name attribute
--	bindingName -- string with binding name attribute
--[=[
-- programador fornece a descrição abaixo:
methods = {
	GetQuote = {
		method = function (...) --[[...]] end,
		request = {
			name = "GetQuoteSoapIn",
			{ name = "parameters", element = "tns:GetQuote" },
		},
		response = {
			name = "GetQuoteSoapOut",
			{ name = "parameters", element = "tns:GetQuoteResponse" },
		},
		portTypeName = "StockQuoteSoap",
		bindingName = "StockQuoteSoap",
	},

}
=> soap.wsdl.generate_wsdl() produz a tabela abaixo e depois, serializa ela, produzindo o documento WSDL final:
{
	{
		tag = "wsdl:message",
		attr = { name = "GetQuoteSoapIn" },
		{
			tag = "wsdl:part",
			attr = { name = "parameters", element = "tns:GetQuote" }
		}
	},
	{
		tag = "wsdl:message",
		attr = { name = "GetQuoteSoapOut" },
		{
			tag = "wsdl:part",
			attr = { name = "parameters", element = "tns:GetQuoteResponse" }
		}
	},
	{
		tag = "wsdl:portType",
		attr = { name = "StockQuoteSoap" },
		{
			tag = "wsdl:operation",
			attr = { name = "GetQuote", parameterOrder = "??" },
			{
				tag = "wsdl:input",
				attr = { message = "GetQuoteSoapIn" },
			},
			{
				tag = "wsdl:output",
				attr = { message = "GetQuoteSoapOut" },
			},
		},
	},
...
}
--]=]

------------------------------------------------------------------------------
function M:gen_definitions ()
	return strformat([[
<wsdl:definitions
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/"
	xmlns:s="http://www.w3.org/2001/XMLSchema"
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
	xmlns:tns="%s"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	targetNamespace="%s"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/ %s">]],
	self.targetNamespace, self.targetNamespace, soap.attrs (self.otherNamespaces))
end

------------------------------------------------------------------------------
function M:gen_types ()
	self.types.tag = "wsdl:types"
	return soap.serialize (self.types)
end

--=---------------------------------------------------------------------------
-- wsdl:message template
-- it should be cleaned each time it is used to eliminate old values.
local tmpl = {
	tag = "wsdl:message",
	attr = { name = "to be cleaned and refilled" },
	{
		tag = "wsdl:part",
		attr = { name = "parameters", type = nil, element = nil, },
	},
}

--=---------------------------------------------------------------------------
-- generate one <wsdl:message> element with two <wsdl:part> elements inside it.
-- @param elem Table with message description.
-- @param name String with type of message ("request" or "response").
-- @return String with a <wsdl:message>.

local function gen_message (elem, name)
	if elem.element then
		tmpl.element = elem.element
		tmpl.type = nil -- cleans the other attribute (it could store an old value)
		-- pode ter os atributos type E element no mesmo <wsdl:part ...> ???
	elseif elem.type then
		tmpl.type = elem.type
		tmpl.element = nil -- cleans the other attribute (it could store an old value)
		-- pode ter os atributos type E element no mesmo <wsdl:part ...> ???
	else
		error ("Incomplete description: "..name.." parameters might have an 'element' or a 'type' attribute")
	end
	return soap.serialize (message_template)
end

------------------------------------------------------------------------------
-- generate two <wsdl:message> elements for each method.
-- @return String with all <wsdl:message>s.

function M:gen_messages ()
	local m = {}
	for name, desc in pairs (self.methods) do
		m[#m+1] = gen_message (desc.request, "request")
		m[#m+1] = gen_message (desc.response, "response")
	end
	return tconcat (m)
end

------------------------------------------------------------------------------
function M:generate_wsdl ()
	if self.wsdl then
		return self.wsdl
	end
	local doc = {}
	doc[1] = self:gen_definitions ()
	doc[2] = self:gen_types ()
	doc[3] = self:gen_messages ()
	doc[4] = self:gen_portTypes ()
	doc[5] = self:gen_bindings ()
	doc[6] = self:gen_service ()
	doc[7] = "</wsdl:definitions>"
	return tconcat (doc)
end

------------------------------------------------------------------------------
return M
