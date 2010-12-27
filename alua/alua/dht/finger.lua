module("alua.dht.finger", package.seeall)

local identifier    = require("alua.dht.identifier")




function new(id)
    local finger =  {}
    for i = 1, #id.hash * 8 do
        finger[i] = {
            start   = identifier.addPowerOfTwo(id, i),
            node    = nil
        }
    end
    return finger
end

-- TODO Colocar as funcoes como se fossem metodos
-- Para aproveitar uma finger table do seu vizinho
function update(finger, start, node)
    -- TODO Verificar se é necessário fazer uma cópia da variável node
    for i = 1, #finger do
        if identifier.is_between(finger[i].start, start, node.id) then
            finger[i].node = node
        end
    end
end


function print_finger(finger)
    for i, node in ipairs(finger) do
        print(i, node.id.string)
    end
end