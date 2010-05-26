local ccr  = require("ccr")
local core = require("ccr.notify.core")

module("ccr.notify")

-- XXX: In the format string, '%d' _must_ come first than '%s'
setformat = core.setformat

function add(fd, mode)
    if mode == "r" or mode == "w" then
        core.add(fd, ccr.self, mode)
        return true
    end
    return false, "invalid events"
end
