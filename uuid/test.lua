require("uuid")

id = uuid.create("str")
print(#id, id)
id = uuid.create("str", true)
print(#id, id)
id = uuid.create("siv")
print(#id, id)
