------------------------------------------------------------------------------
-- LuaSOAP support to WSDL semi-automatic generation.

-- See Copyright Notice in license.html
------------------------------------------------------------------------------

local assert, error, ipairs, pairs = assert, error, ipairs, pairs

local soap = require"soap"
local strformat = require"string".format
local tconcat = require"table".concat

local qname_patt = "^%w*%:%w*$"

local M = {
	_COPYRIGHT = "Copyright (C) 2015-2020 Kepler Project",
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
--	namespace -- string with qualifying namespace (optional)
--	portTypeName -- string with portType name attribute
--	bindingName -- string with binding name attribute

--=---------------------------------------------------------------------------
-- Copy a table to a new one using depth-first traversal.

local function tabcopy (tab)
	local t = {}
	for i, v in pairs(tab) do
		local tv = type(v)
		if tv == "table" then
			t[i] = tabcopy (v)
		else
			t[i] = v
		end
	end
	return t
end

------------------------------------------------------------------------------
-- Produce WSDL definitions tag.
------------------------------------------------------------------------------
function M:gen_definitions ()
	return strformat([[
<wsdl:definitions
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:wsoap12="http://schemas.xmlsoap.org/wsdl/soap12/"
	xmlns:s="http://www.w3.org/2001/XMLSchema"
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
	xmlns:tns="%s"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	targetNamespace="%s"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" %s>]],
	self.targetNamespace, self.targetNamespace, soap.attrs (self.otherNamespaces))
end

------------------------------------------------------------------------------
-- Produce WSDL types tag.
------------------------------------------------------------------------------
function M:gen_types ()
	if not self.types then
		return ''
	end

	local all_types = {
		tag = "wsdl:types",
		{
			tag = "s:schema",
			attr = {
				elementFormDefault = "qualified",
				targetNamespace = self.targetNamespace,
			},
		}
	}

	for _ , elem in ipairs (self.types) do
		all_types[1][ #all_types[1] + 1] = elem
	end
	return soap.serialize (all_types)
end

--=--------------------------------------------------------------------------
-- Produce a message tag.
-- generate one <wsdl:message> element with N <wsdl:part> elements inside it.
-- @param elem Table with message description.
-- @param method_name String with type of message ("request" or "response" or "fault").
-- @return String with a <wsdl:message>.
--=--------------------------------------------------------------------------
local function gen_message (elem, method_name, mode)
	if elem[mode] then
		return gen_message (elem[mode], method_name, mode)
	end
	local message = {
		tag = "wsdl:message",
		attr = {
			name = (elem.name) or (method_name..mode),
		},
	}

	for i=1, #elem do
		message[i] = {
			tag = "wsdl:part",
			attr = {
				name = assert (elem[i].name , method_name.." Message part MUST have a name!"),
			},
		}
		if elem[i].element then
			message[i].attr.element = assert (elem[i].element:match(qname_patt), method_name.." Element must be qualified: expected "..qname_patt..", got '"..elem[i].element.."'")
		elseif elem[i].type then
			message[i].attr.type =  assert (elem[i].type:match(qname_patt), method_name.." Type must be qualified: expected "..qname_patt..", got '"..elem[i].type.."'")
		else
			error ("Incomplete description: "..method_name.." in "..elem[i].name.." parameters MUST have an 'element' or a 'type' attribute")
		end
	end
	return soap.serialize (message)
end

------------------------------------------------------------------------------
-- Produce the message tags for each method: request, response, fault.
-- generate two <wsdl:message> elements for each method.
-- @return String with all <wsdl:message>s.
------------------------------------------------------------------------------
function M:gen_messages ()
	local m = {}
	for _, mode in ipairs(self._modes) do
		for method_name, desc in pairs (self.methods) do
			if desc.request then
				m[#m+1] = gen_message (desc.request, method_name, mode.."In")
			end
			if desc.response then
				m[#m+1] = gen_message (desc.response, method_name, mode.."Out")
			end
			if desc.fault then
				m[#m+1] = gen_message (desc.fault, method_name, mode)
			end
		end
	end
	return tconcat (m)
end

--=---------------------------------------------------------------------------
-- Produce portType tag.
-- @param desc Table describing a method.
-- @param method_name String with the method name.
--=---------------------------------------------------------------------------
function M:gen_portType (mode)
	local portType = {
		tag = "wsdl:portType",
		attr = {
			name = assert (self.portTypeName , "The server MUST have a portTypeName!")..mode,
		},
	}
	for method_name, desc in pairs (self.methods) do
		local op = {
			tag = "wsdl:operation",
			attr = {
				name = method_name,
				--[parameterOrder], why would you need that in Lua?!
			},
		}

		local ns = desc.namespace or "tns:"
		if desc.documentation then
			op[#op+1] = {
				tag = "wsdl:documentation",
				desc.documentation,
			}
		end
		if desc.request then
			op[ #op + 1] = {
				tag = "wsdl:input",
				--attr = { message = ns..assert (desc.request.name, "The field 'name' is mandatory when there is a request") },
				attr = { message = ns..method_name..mode.."In", },
			}
		end
		if desc.response then
			op[ #op + 1] = {
				tag = "wsdl:output",
				--attr = { message = ns..assert (desc.response.name, "The field 'name' is mandatory when there is a response") },
				attr = { message = ns..method_name..mode.."Out", },
			}
		end
		if desc.fault then
			op[ #op + 1] = {
				tag = "wsdl:fault",
				attr = {
					name = assert (desc.fault.name, "Fault name for '"..method_name.."' is mandatory when there is a fault element"),
					message = ns..desc.fault.name,
				},
			}
		end

		portType[#portType+1] = op
	end

	return soap.serialize (portType)
end

------------------------------------------------------------------------------
-- Produce the portType tags for each method.
------------------------------------------------------------------------------
function M:gen_portTypes ()
	local p = {}

	for _, mode in ipairs(self._modes) do
		p[#p+1] = self:gen_portType (mode)
	end
	return tconcat (p)
end

--=---------------------------------------------------------------------------
local soap_attr = {
	transport = "http://schemas.xmlsoap.org/soap/http", -- Other URI may be used
	style = "document", --TODO "rpc"
}

local get_attr = {
	verb = "GET",
}

local post_attr = {
	verb = "POST",
}

local binding_tags = {
	Soap = { tag = "soap:binding", attr = soap_attr, },
	Soap12 = { tag = "wsoap12:binding", attr = soap_attr, },
	HttpGet = { tag = "http:binding", attr = get_attr, },
	HttpPost = { tag = "http:binding", attr = post_attr, },
}

local function gen_binding_mode (mode)
	return binding_tags[mode]
end

--=---------------------------------------------------------------------------
local operation_tags = {
	Soap = { tag = "soap:operation", attr = { soapAction = "To be filled", style = "document"}, }, --TODO "rpc"
	Soap12 = { tag = "wsoap12:operation", attr = { soapAction = "To be filled", style = "document"}, },
	HttpGet = { tag = "http:operation", attr = { location = "To be filled", }, },
	HttpPost = { tag = "http:operation", attr = { location = "To be filled", }, },
}

function M:gen_binding_operation (method_name, mode)
	local op = tabcopy (operation_tags[mode])
	if op.attr.soapAction then
		local SA_pattern = self.methods[method_name].operation_soapAction_pattern
		if SA_pattern then
local _old_method_name = self.method_name
self.method_name = method_name
			op.attr.soapAction = SA_pattern:gsub ("([_%w]+)", self)
self.method_name = _old_method_name
			op.attr.soapAction = op.attr.soapAction:gsub ("%/+", "/")
		else
			op.attr.soapAction = self.url
		end
	elseif op.attr.location then
		op.attr.location = '/'..method_name
	end
	return op
end

--=---------------------------------------------------------------------------
local body_in_tags = {
	Soap = { tag = "soap:body", attr = { use = "literal" }, },
	Soap12 = { tag = "wsoap12:body", attr = { use = "literal" }, },
	HttpGet = { tag = "http:urlEncoded", attr = {}, },
	HttpPost = { tag = "mime:content", attr = { type = "application/x-www-form-urlencoded" }, },
}

local function gen_binding_op_body_in (mode, desc)
	return body_in_tags[mode]
end

--=---------------------------------------------------------------------------
local body_out_tags = {
	Soap = { tag = "soap:body", attr = { use = "literal" }, },
	Soap12 = { tag = "wsoap12:body", attr = { use = "literal" }, },
	HttpGet = { tag = "mime:mimeXml", attr = { part = "Body" }, },
	HttpPost = { tag = "mime:mimeXml", attr = { part = "Body" }, },
}

local function gen_binding_op_body_out (mode, desc)
	return tabcopy (body_out_tags[mode])
end

--=---------------------------------------------------------------------------
local body_fault_tags = {
	Soap = { tag = "soap:body", attr = { name = "To be filled", use = "literal" }, },
	Soap12 = { tag = "wsoap12:body", attr = { name = "To be filled", use = "literal" }, },
	HttpGet = { tag = "http:binding", attr = {}, },
	HttpPost = { tag = "http:binding", attr = {}, },
}

local function gen_binding_op_body_fault (mode, desc)
	local body = tabcopy (body_fault_tags[mode])
	if body.attr.name then
		body.attr.name = desc.fault.name
	end
	return body
end

--=---------------------------------------------------------------------------
-- Generate binding

function M:gen_binding (mode)
	local _mode = mode
	if _mode == "Soap12" then
		_mode = "Soap"
	end
	local binding = {
		tag = "wsdl:binding",
		attr = {
			name = assert (self.bindingName, " The server MUST have a bindingName!")..mode,
			type = ( self.namespace or "tns:")..self.portTypeName.._mode,
		},
		gen_binding_mode(mode),
	}
	for method_name, desc in pairs (self.methods) do
		local op = {
			tag = "wsdl:operation",
			attr = { name = method_name },
			self:gen_binding_operation (method_name, mode)
		}

		if desc.request then
			op[ #op +1] = {
				tag = "wsdl:input",
				gen_binding_op_body_in (mode, desc),
			}
		end
		if desc.response then
			op[ #op +1] = {
				tag = "wsdl:output",
				gen_binding_op_body_out (mode, desc),
			}
		end
		if desc.fault then
			op[ #op +1] = {
				tag = "wsdl:fault",
				gen_binding_op_body_fault (mode, desc),
			}
		end
		binding[#binding+1] = op
	end

	return soap.serialize (binding)
end

------------------------------------------------------------------------------
-- Produce the bindings for each method according to each mode.
-- @return String.
------------------------------------------------------------------------------
function M:gen_bindings ()
	local b = {}
	for _, mode in ipairs(self._mode) do
		b[#b+1] = self:gen_binding (mode)
	end
	return tconcat (b)
end

--=---------------------------------------------------------------------------
-- Generate port

local address_tags = {
	Soap = "soap:address",
	Soap12 = "wsoap12:address",
	HttpGet = "http:address",
	HttpPost = "http:address",
}

function M:gen_port (mode)
	local port = {
		tag = "wsdl:port",
		attr = {
			name = self.bindingName..mode,
			binding = (self.namespace or "tns:")..self.bindingName..mode,
		},
		[1] = {
			tag = address_tags[mode],
			attr = { location = self.url },
		},
	}
	return port
end

------------------------------------------------------------------------------
-- Produce the service tag.
------------------------------------------------------------------------------
function M:gen_service ()
	local service = {
		tag = "wsdl:service",
		attr = {
			name = self.name,
		},
	}
	for _, mode in ipairs(self._mode) do
		service[#service+1] = self:gen_port (mode)
	end
	return soap.serialize (service)
end

------------------------------------------------------------------------------
-- Produce the WSDL document.
-- @return String with the WSDL definition.
------------------------------------------------------------------------------
function M:generate_wsdl ()
	if self.wsdl then
		return self.wsdl
	end
	local tm = type (self.mode)
	assert (tm == "table", "Unexpected 'mode' type: "..tm.." (expecting a table)")
	self._mode = {}
	self._modes = {}
	local _11, _12 = false, false
	for i, mode in ipairs(self.mode) do
		if mode == 1.1 or mode == "1.1" then
			self._mode[i] = "Soap"
			_11 = i
			self._modes[i] = "Soap"
		elseif mode == 1.2 or mode == "1.2" then
			self._mode[i] = "Soap12"
			_12 = i
			self._modes[i] = "Soap"
		elseif mode == "GET" or mode == "Get" or mode == "HttpGet" then
			self._mode[i] = "HttpGet"
			self._modes[i] = "HttpGet"
		elseif mode == "POST" or mode == "Post" or mode == "HttpPost" then
			self._mode[i] = "HttpPost"
			self._modes[i] = "HttpPost"
		else
			error ("Invalid mode '"..tostring(mode).."': expected one of 1.1, 1.2, Get or Post")
		end
	end
	if _11 and _12 then
		table.remove (self._modes, _12)
	end
	local doc = {
		self:gen_definitions (),
		self:gen_types (),
		self:gen_messages (),
		self:gen_portTypes (),
		self:gen_bindings (),
		self:gen_service (),
		"</wsdl:definitions>",
	}
	return tconcat (doc)
end

------------------------------------------------------------------------------
return M
