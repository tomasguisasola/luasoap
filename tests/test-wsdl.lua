-- Fake cgilua support

local function donothing() end
local res = {}
cgilua = {
        contentheader = donothing,
        header = donothing,
        put = function(s) res[#res+1] = s end,
        seterroroutput = donothing, --function(f) f("error message") end,
}

-------------------------------------------------------------

local namespace = "http://www.webservicex.net/"
local server = require"soap.server".new {
   name = "StockQuote",
   targetNamespace = namespace,
   url = namespace.."stockquote.asmx",
	mode = { 1.2, '1.1', },
}
server:export {
   --name = "nome_do_metodo", -- vai ser a chave da tabela self.methods
   --method = function (...) --[[ implementação do método ]] end,
   -- message = ???
   -- request = ???
   -- response = ???
   -- como descrever as mensagens que podem ser usadas para a comunicação com o servidor?
	name = "GetQuote",
	method = function (...) --[[...]] end,
	namespace = "tns:",
	request = {
		name = "GetQuoteSoapIn",
		{ name = "parameters", element = "tns:GetQuote" },
	},
	response = {
		name = "GetQuoteSoapOut",
		{ name = "parameters", element = "tns:GetQuoteResponse" },
	},
	fault = {
		name = "GetQuoteSoapFault",
		{ name = "parameters", element = "tns:GetQuoteFault" },
	},
	portTypeName = "StockQuoteSoap",
	bindingName = "StockQuoteSoap",

}
server:handle_request (nil, "wsdl") --nil é o POST data
print(res[1])
--[[
local wsdl = server:handle_request (nil, "wsdl") --nil é o POST data
wsdl = server:generate_wsdl()
local fh1 = assert(io.open("resultado.xml","w+"))
fh1:write(wsdl)
fh1:close()

print("Done!")
local wsdl1 = table.concat(res)
local fh = assert(io.open"stockquoteWSDL.xml")
local conteudo = assert(fh:read"*a")
fh:close()

--assert(wsdl1 == conteudo) -- ajustes!!!
--]]
