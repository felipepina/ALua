module("alua.dht.node", package.seeall)

local identifier    = require("alua.dht.identifier")
local tcp           = require("alua.tcp")

local ip_pattern = "^(%d+%.%d+%.%d+%.%d+):(%d+)"
-- local nodeid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)"
-- local daemonid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+)"
-- 
-- function get_parentid(node)
--    return string.match(node, nodeid_pattern) 
-- end
-- 
-- function get_daemonid(node)
--     local daemon_node = string.match(node, daemonid_pattern) 
--     
--     if daemon_node then
--         daemon_node = daemon_node .. "/0"
--     end
--     
--     return daemon_node
-- end
-- 
-- 
-- function isNode(node)
--     local node_id = string.match(node, nodeid_pattern) 
--     
--     if node_id then
--         return true
--     else
--         return false
--     end
-- end

-- local Node = {}
-- local mt = {}
-- 
-- 
-- function new(node_id)
--    local node = {
--        id       = identifier.new(node_id),
--        socket   = nil
--    }
--    
--    setmetatable(node, mt)
-- 
--    return node
-- end

-- boolean connect true create a socket
function new(node_id, connect)
   local node = {
       -- id       = identifier.new(node_id),
       id       = node_id,
       socket   = nil
   }
   
   -- setmetatable(node, mt)
   
   if connect then
       local ip, port = string.match(node_id.string, ip_pattern)
       local sock, err = tcp.connect(ip, port)
       
       -- print(ip, port, sock, err)
       if not sock then
           return nil, err
       else
           node.socket = sock
       end
   end
   
   return node
end

-- function connect(node)
--     local ip, port = string.match(node_id, ip_pattern)
--     local sock, err = tcp.connect(ip, port)
--     if not sock then
--         return nil, err
--     else
--         node.socket = sock
--     end
-- end

-- TODO Colocar essas funcoes como se fossem metodos
function send_data(node, data)
    if not data then
        return false, "no data"
    end
    
    return tcp.send(node.socket, data)
end

function close_conn(node)
    if not node.socket then
        return false, "invalid socket"
    end

    return tcp.close(node.socket)
end

function equals(n1, n2)
   if not n1 or not n2 then
       return false 
   else
       return n1.id.hash == n2.id.hash
   end
end

--  0 = equals
--  1 = n1 > n2
-- -1 = n1 < n2
function compare(n1, n2)
    if n1.id.hash == n2.id.hash then
        return 0
    elseif n1.id.hash > n2.id.hash then
        return 1
    else
        return -1
    end
end

function comp(n1, n2)
    return n1.id.hash < n2.id.hash
end

-- function Node:tostring(node)
--     return node.id.string
-- end
