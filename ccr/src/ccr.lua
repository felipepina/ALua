-----------------------------------------------------------------------------
-- CCR
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

local core      = require("ccr.core")
local coroutine = require("coroutine")

local pairs = pairs

local print = print
local debug = debug
local os = os

module("ccr")

-- Export core functions
for k, v in pairs(core) do
    _M[k] = v
end

-- Export low-level receive
-- TODO acho que pode tirar essa exportacao pois nao eh usada
-- recv = core.receive

-- Override

self   = core.self()
ismain = core.ismain()

function receive()
    if coroutine.running() or ismain then
        return core.receive()
    else
        while true do
	        local str = core.tryreceive()
	        if str then
	            return str
	        else
	            -- TODO Comentado. Verificar se realmente pode-se retirar as duas linhas abaixos
                -- print(debug.traceback())
                -- os.exit()
	            core.yield()
	            --coroutine.yield()
	        end
        end
    end
end
