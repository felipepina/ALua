module("alua.util", package.seeall)

local nodeid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)"
local daemonid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+)"

function isTable(table)
    return type(table) == "table"
end

function copyTable(table)
    local copy = {}
    for k,v in pairs(table) do
        if isTable(v) then
            copy[k] = copyTable(v)
        else
            copy[k] = v
        end
    end
    
    return copy
end



function get_parentid(proc)
   return string.match(proc, nodeid_pattern) 
end


function get_daemonid(proc)
    local proc_daemon = string.match(proc, daemonid_pattern) 
    
    if proc_daemon then
        proc_daemon = proc_daemon .. "/0"
    end
    
    return proc_daemon
end


function isNode(node_id)
    local node = string.match(node_id, nodeid_pattern) 
    
    if node then
        return true
    else
        return false
    end
end
