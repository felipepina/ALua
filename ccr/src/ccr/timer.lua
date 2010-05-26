local core = require("ccr.timer.core")

module("ccr.timer", package.seeall)

core.setfmt("ccr.timer.trigger(%llu)")

local timers = {}

now = core.now

function settimer(tm, func, ctx)
    tm = core.settimer(ccr.self, tm)
    local t = timers[tm]
    if not t then
        t = {}
        timers[tm] = t
    end
    table.insert(t, {func=func, ctx=ctx})
end

function trigger(tm)
    local cb = table.remove(timers[tm])
    cb.func(cb.ctx)
    if not next(timers[tm]) then
        timers[tm] = nil
    end
end