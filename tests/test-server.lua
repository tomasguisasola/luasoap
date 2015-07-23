---------------------------------------------------------------------
-- $Id:$
---------------------------------------------------------------------

---------------------------------------------------------------------
-- Fake cgilua support

local function donothing() end
cgilua = {
	contentheader = donothing,
	header = donothing,
	put = print,
	seterroroutput = donothing, --function(f) f("error message") end,
}

local server = require("soap.server")

---------------------------------------------------------------------
local fake_data = {
	{
		{ codigo = 1, sequencial = 2, legenda = 'Bla', ordem = 1, },
		{ codigo = 1, sequencial = 1, legenda = 'bla', ordem = 2, },
		{ codigo = 2, sequencial = 1, legenda = 'bLA', ordem = 3, },
	},
	{
		{ codigo = 3, sequencial = 2, legenda = 'BlaBla', ordem = 1, },
		{ codigo = 3, sequencial = 1, legenda = 'blaBla', ordem = 2, },
		{ codigo = 2, sequencial = 1, legenda = 'bLABla', ordem = 3, },
	},
}

---------------------------------------------------------------------
function lista_imagens_galeria (galeria)
	assert (galeria, "Nil argument #1 to 'lista_imagens_galeria'")
	local tg = type(galeria)
	assert (tg == "table", "Bad argument #1 to 'lista_imagens_galeria' (table expected, got "..tg..")")
	local tgid = type(galeria.id)
	assert (tgid == "string", "Bad argument #1 to 'lista_imagens_galeria' (number expected, got "..tgid..")")
	assert (tonumber(galeria) and galeria ~= "inf" and galeria ~= "nan", "Bad argument #1 to 'lista_imagens_galeria' (number expected, got {"..tostring(galeria).."}")

	local imgs = fake_data[galeria.id]

	local dados = { tag = "ImagensGaleria" }
	for i = 1, #imgs do
		local row = imgs[i]
		tinsert (dados, {
			tag = "Imagem",
			{ tag = "codigo", row.codigo },
			{ tag = "sequencial", row.sequencial },
			{ tag = "legenda", row.legenda },
			{ tag = "ordem", row.ordem },
		})
	end
	return dados
end

---------------------------------------------------------------------
local namespace = server_name and string.format("http://%s/path/", server_name)
	or "http://my.server.name/path/"
local script = namespace.."this_script.lua"

local disco = string.format([=[<?xml version="1.0" encoding="iso-8859-1" ?>
<discovery
	xmlns:xsd="http://www.w3.org/2001/XMLSchema"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns="http://schemas.xmlsoap.org/disco/">
<contractRef
	ref="%s?wsdl"
	docRef="%s"
	xmlns="http://schemas.xmlsoap.org/disco/scl/" />
<soap
	address="%s"
	xmlns="listaImagensGaleriaSoapBind"
	binding="listaImagensGaleriaSoapBind"
	xmlns="http://schemas.xmlsoap.org/disco/soap/" />
</discovery>]=], script, script, script)

server.register_service_info("listaImagensGaleria",
	namespace,
	script, nil, disco)

server.export {
	name = "listaImagensGaleria",
	method = lista_imagens_galeria,
	message = {
		name = "Galeria",
		{ name = "id", occurrence = 1, type = "integer", },
	},
	response = {
		name = "ImagensGaleria",
		{
			name = "Imagem",
			{ name = "codigo", occurrence = 1, type = "integer", },
			{ name = "sequencial", occurrence = 1, type = "integer", },
			{ name = "legenda", occurrence = 1, type = "string", },
			{ name = "ordem", occurrence = 1, type = "integer", },
		},
	},
}

---------------------------------------------------------------------
server.handle_request (nil, "wsdl")
