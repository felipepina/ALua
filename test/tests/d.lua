require("alua")

function cb(data)
    print(data)
    -- print(alua.inc_threads())
    -- print(alua.inc_threads())
end

alua.create("127.0.0.1", 8888)

alua._register_listener(cb)

alua.loop()

