#! /usr/bin/lua

local nGood = 0
local nFail = 0

-- JUnit functions

local function assertEquals(parm1, parm2, parm3)
   local errmsg, expected, actual
   if (parm3 == nil) then
      errmsg = "Mismatch"
      expected = parm1
      actual = parm2
   else
      errmsg = parm1
      expected = parm2
      actual = parm3
   end
   if (expected ~= actual) then
      print("ERROR: " .. errmsg, expected, actual)
      nFail = nFail + 1
   else
      nGood = nGood + 1
   end
end

-- Tests

local base64 = require("Base64")

-- Encode an empty string

local function testEmpty()
   local input = ""
   local expected = ""
   local actual = base64.encode(input)
   assertEquals("Empty string", expected, actual)
end

local function testSingleChar()
   local input = "p"
   local expected = "cA=="
   local actual = base64.encode(input)
   assertEquals("Input = [" .. input .. "]", expected, actual)
end

local function testMyUserId()
   local input = "saspeh"
   local expected = "c2FzcGVo"
   local actual = base64.encode(input)
   assertEquals("Input = [" .. input .. "]", expected, actual)
end

local function testEmptyDecoded()
   local input = ""
   local expected = input
   local actual = base64.decode(base64.encode(input))
   assertEquals("Empty string", expected, actual)
end

local function testSingleCharDecoded()
   local input = "p"
   local expected = input
   local actual = base64.decode(base64.encode(input))
   assertEquals("Empty string", expected, actual)
end

local function testMyUserIdDecoded()
   local input = "saspeh"
   local expected = input
   local actual = base64.decode(base64.encode(input))
   assertEquals("Empty string", expected, actual)
end

--[[
************************************************************************
                              Mainline
************************************************************************
--]]

testEmpty()
testSingleChar()
testMyUserId()
testEmptyDecoded()
testSingleCharDecoded()
testMyUserIdDecoded()

print(string.format("Number of tests=%d, passed=%d, failed=%d",
                     nGood + nFail,
                     nGood,
                     nFail))
