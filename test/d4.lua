require("alua")

alua.create("127.0.0.1", 8891)
print(alua.id)
alua.loop()
