require("alua")

alua.create("127.0.0.1", 8889)
print(alua.id)
alua.loop()
