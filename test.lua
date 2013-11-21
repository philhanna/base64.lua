#! /usr/bin/lua
local base64 = require("Base64")

local input = "saspeh"
local actual = base64.encode(input)
local expected = "c2FzcGVo"
local decoded = base64.decode(expected)
print(decoded)
