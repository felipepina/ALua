require("alua")

dofile("ping.lua")

alua.create("127.0.0.1", 8888)
alua.loop()

