-----------------------------------------------------------------------------
-- Test script
-- Scenario 10.1
-----------------------------------------------------------------------------

local cen = "10.1"
suc_msg = "Scenario " .. cen .. ": ok!"
err_msg = "Scenario " .. cen .. ": erro!"
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0", "127.0.0.1:8892/0"}
local count = 0

local function sendcb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
end

local function setfuncb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)

    count = count + 1
    if count == 5 then
        alua.send(daemonlist[1], string.format("start(%q)", daemonlist[1]))
        alua.send(daemonlist[2], string.format("start(%q)", daemonlist[1]))
        alua.send(daemonlist[3], string.format("start(%q)", daemonlist[1]))
        alua.send(daemonlist[4], string.format("start(%q)", daemonlist[1]))
        alua.send(daemonlist[5], string.format("start(%q)", daemonlist[1]))
    end
end

function main()
	local funcode = [[
    	local cen = "10.1"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"
        
        local key, value
        local hub
        local count = 0
        local list = {}

        function finalize(src)
            count = count + 1
            table.insert(list, src)
            if count == 5 then
                print(suc_msg)
                for i,v in ipairs(list) do
                    alua.send(list[i], "alua.quit()")
                end
            end
        end

        local function finish()
            alua.send(hub, string.format("finalize(%q)", alua.id))
        end

        function retrievecb(reply)
            print("Key retrieved", reply.key)
            local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and
                        assert(reply.key == key, err_msg) and
                        assert(reply.value == value, err_msg)

            if ret then
                -- finish()
            end
        end

        function storecb(reply)
            print("Key stored", reply.key)
            local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and assert(reply.key == key, err_msg)

            if ret then
                alua.dht_lookup(reply.key, retrievecb)
            end
        end

        function start(hub_node)
            hub = hub_node
            local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
            key = port
            value = alua.id
            print("Key", key, "Value", value)
            alua.dht_insert(key, value, storecb)
        end
        ]]
        
    alua.send(daemonlist[1], funcode, setfuncb)
    alua.send(daemonlist[2], funcode, setfuncb)
    alua.send(daemonlist[3], funcode, setfuncb)
    alua.send(daemonlist[4], funcode, setfuncb)
    alua.send(daemonlist[5], funcode, setfuncb)
end
