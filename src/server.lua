---------------------------------------------------------------------
-- LuaSOAP support for service development.
-- See Copyright Notice in license.html
-- $Id:$
---------------------------------------------------------------------
local next, type, tostring, pcall, unpack, pairs, ipairs = next, type, tostring, pcall, unpack, pairs, ipairs
local error, assert = error, assert
local table = require"table"
local string = require"string"
local cgilua = cgilua or require"cgilua"
local soap = require"soap"


local encoding = "iso-8859-1"
local xml_header = '<?xml version="1.0" encoding="'..encoding..'"?>\n'

local __methods
__methods = {
	listMethods = function (namespace)
		local l = {}
		for name in pairs(__methods) do
			table.insert(l, { tag = "methodName", name })
		end
		return soap.encode({method = "listMethodsResponse", entries = l})
	end,
}

local __service = {
	-- name
	-- namespace
	-- url
	-- soap_action
	-- wsdl (opt)
	-- disco (opt)
}

---------------------------------------------------------------------
local function respond(resp, header)
	cgilua.header("Content-length", string.len(resp))
	cgilua.header("Connection", "close")
	cgilua.contentheader("text", "xml")
	if header then
		cgilua.put(header)
	end
	cgilua.put(resp)
end

---------------------------------------------------------------------
local function builderrorenvelope(faultcode, faultstring, extra)
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

---------------------------------------------------------------------
local function decodedata(doc)
	local namespace, elem_name, elems = soap.decode(doc)
	local func = __methods[elem_name].method
	assert(type(func) == "function", "Unavailable method: `"..tostring(elem_name).."'")

	return namespace, func, (elems or {})
end

---------------------------------------------------------------------
local function callfunc(func, namespace, arg_table)
	local result = { pcall(func, namespace, arg_table) }
	local ok = result[1]
	if not ok then
		result = builderrorenvelope("soap:ServiceError", result[2])
	else
		table.remove(result, 1)
		if #result == 1 then
			result = result[1]
		end
	end
	return ok, result
end

---------------------------------------------------------------------
local function wsdl_gen_type_aux(message)
	if not next(message, nil) then
		return ""
	end
	local buffer = { string.format([[ 
      <s:element name="%s">
        <s:complexType>
          <s:sequence>]],
		message.name)
	}

	for _, field in ipairs(message) do
		local min, max
		if type(field.occurrence) == "table" then
			min, max = field.occurrence[1], field.occurrence[2]
		elseif type(field.occurrence) == "string" then
			min, max = field.occurrence, field.occurrence
		else
			min, max = 1, 1
		end

		local _type = field.type or "string"

		table.insert(buffer, string.format([[ 
            <s:element minOccurs="%d" maxOccurs="%d" name="%s" type="s:%s" />]],
			min, max, field.name, _type))
	end

	table.insert(buffer, [[ 
          </s:sequence>
        </s:complexType>
      </s:element>]])

	return table.concat(buffer)
end

local function wsdl_gen_type(desc)
	return wsdl_gen_type_aux(desc.message) .. 
		wsdl_gen_type_aux(desc.response)
end

---------------------------------------------------------------------
local function wsdl_gen_message(desc)
	local in_params, out_params = "", ""
	if desc.message.name then
		in_params = '\n    <wsdl:part name="parameters" element="tns:'
			..desc.message.name..'" />\n  '
	end
	if desc.response.name then
		out_params = '\n    <wsdl:part name="parameters" element="tns:'
			..desc.response.name..'" />\n  '
	end
	return string.format([[ 
  <wsdl:message name="%sSoapIn">%s</wsdl:message>
  <wsdl:message name="%sSoapOut">%s</wsdl:message>]],
		desc.name, in_params,
		desc.name, out_params)
end

---------------------------------------------------------------------
local function wsdl_gen_port_type(desc)
	return string.format([[ 
    <wsdl:operation name="%s">
      <wsdl:input message="tns:%sSoapIn" />
      <wsdl:output message="tns:%sSoapOut" />
    </wsdl:operation>]],
		desc.name, desc.name, desc.name)
end

---------------------------------------------------------------------
local function wsdl_gen_binding(desc)
	local soap_action = ''
	if __service.soap_action then
		soap_action = 'soapAction="'..__service.soap_action..desc.name..'"'
	end
	return string.format([[ 
    <wsdl:operation name="%s">
      <soap:operation %s style="document" />
      <wsdl:input><soap:body use="literal" /></wsdl:input>
      <wsdl:output><soap:body use="literal" /></wsdl:output>
    </wsdl:operation>]],
		desc.name, soap_action)
end

---------------------------------------------------------------------
local function wsdl_gen_http_binding(desc)
	return string.format([[ 
    <wsdl:operation name="%s">
      <http:operation location="/%s"/>
      <wsdl:input><mime:content type="application/x-www-form-urlencoded"/></wsdl:input>
      <wsdl:output><mime:mimeXml part="Body"/></wsdl:output>
    </wsdl:operation>]],
		desc.name, desc.name)
end

---------------------------------------------------------------------
local function generate_wsdl()
	local buffer = {
		xml_header,
		string.format([[
<wsdl:definitions
	xmlns:http="http://schemas.xmlsoap.org/wsdl/http/"
	xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
	xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/"
	xmlns:s="http://www.w3.org/2001/XMLSchema"
	xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/"
	xmlns:tns="%s"
	xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/"
	targetNamespace="%s"
	xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">]], __service.namespace, __service.namespace) }

	-- types
	---------------------------------------------
	table.insert(buffer, string.format([[ 
  <wsdl:types>
    <s:schema elementFormDefault="qualified" targetNamespace="%s">]], __service.namespace))

	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, method.wsdl_type)
		end
	end

	table.insert(buffer, [[ 
    </s:schema>
  </wsdl:types>]])

	-- message
	---------------------------------------------
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, method.wsdl_message)
		end
	end

	-- portType
	---------------------------------------------
	table.insert(buffer, string.format([[ 
  <wsdl:portType name="%sServiceSoap">]], __service.name))
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, method.wsdl_port_type)
		end
	end
	table.insert(buffer, "\n  </wsdl:portType>")

	table.insert(buffer, string.format([[ 
  <wsdl:portType name="%sServiceHttpPost">]], __service.name))
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, (method.wsdl_port_type:gsub("Soap", "HttpPost")))
		end
	end
	table.insert(buffer, "\n  </wsdl:portType>")

	-- binding
	---------------------------------------------
	-- Soap
	table.insert(buffer, string.format([[ 
  <wsdl:binding name="%sServiceSoap" type="tns:%sServiceSoap">
    <soap:binding transport="http://schemas.xmlsoap.org/soap/http" style="document" />]],
    	__service.name, __service.name))
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, method.wsdl_binding)
		end
	end
	table.insert(buffer, "  </wsdl:binding>")
	-- Soap12
	table.insert(buffer, string.format([[ 
  <wsdl:binding name="%sServiceSoap12" type="tns:%sServiceSoap">
    <soap12:binding transport="http://schemas.xmlsoap.org/soap/http" style="document" />]],
    	__service.name, __service.name))
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, (method.wsdl_binding:gsub("<soap:", "<soap12:")))
		end
	end
	table.insert(buffer, "  </wsdl:binding>")
	-- HttpPost
	table.insert(buffer, string.format([[ 
  <wsdl:binding name="%sServiceHttpPost" type="tns:%sServiceHttpPost">
    <http:binding verb="POST"/>]],
    	__service.name, __service.name))
	for _, method in pairs(__methods) do
		if type(method) == "table" then
			table.insert(buffer, method.wsdl_http_binding)
		end
	end
	table.insert(buffer, "  </wsdl:binding>")

	-- service
	---------------------------------------------
	table.insert(buffer, string.format([[ 
  <wsdl:service name="%sService">
    <wsdl:port name="%sServiceSoap" binding="tns:%sServiceSoap">
      <soap:address location="%s" />
    </wsdl:port>
    <wsdl:port name="%sServiceSoap12" binding="tns:%sServiceSoap12">
      <soap12:address location="%s" />
    </wsdl:port>
    <wsdl:port name="%sServiceHttpPost" binding="tns:%sServiceHttpPost">
      <http:address location="%s" />
    </wsdl:port>
  </wsdl:service>]], __service.name, __service.name, __service.name, __service.url, __service.name, __service.name, __service.url, __service.name, __service.name, __service.url))

	table.insert(buffer, [[ 
</wsdl:definitions>]])

	return table.concat(buffer)
end

---------------------------------------------------------------------
local function generate_disco()
	return xml_header.."<discovery></discovery>"

end

---------------------------------------------------------------------
-- Registers information needed to respond to WSDL and discovery
-- requests
-- @param name String with the name of the service
-- @param namespace String with the namespace of the service
-- @param url String with the url of the service
-- @param wsdl String with a WSDL response message (optional)
-- @param disco String with a discovery response message (optional)
---------------------------------------------------------------------
local function register_service_info(name, namespace, url, wsdl, disco)
	__service.name = name
	__service.namespace = namespace
	__service.url = url
	__service.wsdl = wsdl
	__service.disco = disco

	__service.soap_action = string.gsub(url, "[^/]*$", "")
end

---------------------------------------------------------------------
-- Exports methods that can be used by the server.
-- @param desc Table with the method description.
---------------------------------------------------------------------
local function export(desc)
	desc.response.name = desc.response.name or desc.message.name.."Response"

	__methods[desc.name] = {
		message = desc.message.name,
		response = desc.response.name,
		wsdl_type = wsdl_gen_type(desc),
		wsdl_message = wsdl_gen_message(desc),
		wsdl_port_type = wsdl_gen_port_type(desc),
		wsdl_binding = wsdl_gen_binding(desc),
		wsdl_http_binding = wsdl_gen_http_binding(desc),

		method = function (...) -- ( namespace, unpack(arguments) )
			local res = desc.method(...)
			return soap.encode({namespace = __service.namespace, method = desc.response.name, entries = res})
		end,
	}
end

---------------------------------------------------------------------
local function fatalerrorfunction(msg)
	respond(builderrorenvelope("soap:ServerError", msg))
end

---------------------------------------------------------------------
-- Handles the request received by the calling script.
-- @param postdata String with POST data from the server.
-- @param querystring String with the query string.
---------------------------------------------------------------------
local function handle_request(postdata, querystring)
	cgilua.seterroroutput(fatalerrorfunction)

	local namespace, func, arg_table
	local header
	if postdata then
		namespace, func, arg_table = decodedata(postdata)
		header = xml_header
	else
		if querystring and querystring:lower() == "wsdl" then -- WSDL service
			func = function ()
				return __service.wsdl or generate_wsdl()
			end
		elseif querystring == "disco" then -- discovery service
			func = function ()
				return __service.disco or generate_disco()
			end
		else
			func = __methods["listMethods"]
			header = xml_header
		end
		arg_table = {}
	end

	local ok, result = callfunc(func, namespace, arg_table)
	respond(result, header)
end

---------------------------------------------------------------------
return {
	_COPYRIGHT = "Copyright (C) 2004-2013 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 3.0 service helping functions",

	builderrorenvelope = builderrorenvelope,
	export = export,
	generate_disco = generate_disco,
	generate_wsdl = generate_wsdl,
	handle_request = handle_request,
	register_service_info = register_service_info,
}
