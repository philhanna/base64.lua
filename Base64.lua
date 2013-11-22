--[[
========================================================================
NAME:             Base64

PURPOSE:          Provides static functions for encoding and decoding
                  binary data using the Base64 algorithm.

SUPPORT:          Phil Hanna

NOTES:

  The details of Base64 encoding can be found in RFC 1521, section 5.2.
  The basic idea is this:
  
    ---------------|---------------|---------------|
    0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7
    -----------|-----------|-----------|-----------|
  
  1. Split each three bytes of input into four 6-bit integers
  2. Use each integer as an index into a table of printable characters
  3. Output the four characters thus selected.

  If the number of bytes of input is not evenly divisible by three, use
  zero bits on the right to flush any remaining input, then pad the
  output with "=" characters as follows:
  
    Input Length
       Mod 3
         0          No padding
         1          Pad with two &quot;=&quot;
         2          Pad with one &quot;=&quot;
  
  The translation table consists of the uppercase alphabetic
  characters, followed by the lowercase alphabetic characters, followed
  by the digits 0 through 9, and finally "+" and "/":
  
     0 A        16 Q        32 g        48 w
     1 B        17 R        33 h        49 x
     2 C        18 S        34 i        50 y
     3 D        19 T        35 j        51 z
     4 E        20 U        36 k        52 0
     5 F        21 V        37 l        53 1
     6 G        22 W        38 m        54 2
     7 H        23 X        39 n        55 3
     8 I        24 Y        40 o        56 4
     9 J        25 Z        41 p        57 5
    10 K        26 a        42 q        58 6
    11 L        27 b        43 r        59 7
    12 M        28 c        44 s        60 8
    13 N        29 d        45 t        61 9
    14 O        30 e        46 u        62 +
    15 P        31 f        47 v        63 /
========================================================================
--]]

local M = {}

local base64Table =  "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                  .. "abcdefghijklmnopqrstuvwxyz"
                  .. "0123456789"
                  .. "+/"

------------------------------------------------------------------------
-- Encode function
------------------------------------------------------------------------

function M.encode(bytes)

   local function append(result, index)
      local c = string.sub(base64Table, index+1, index+1)
      result = result .. c
      return result
   end

   local result = ""
   local n = string.len(bytes)
   local index = 0
   local state = 0

   for i = 1, n do
      local c = bit32.band(string.byte(bytes, i), 0xFF)
      state = (i-1) % 3

      -- Take three bytes of input = 24 bits
      -- Split it into four chunks of 6 bits each
      -- Treat these chunks as indices into the base64 table

      if (state == 0) then
         -- case 0:
         index = bit32.band(bit32.rshift(c, 2), 0x3F)
         result = append(result, index)
         index = bit32.band(bit32.lshift(c, 4), 0x30)
      elseif (state == 1) then
         -- case 1:
         index = bit32.bor(index, bit32.band(bit32.rshift(c, 4), 0x0F))
         result = append(result, index)
         index = bit32.band(bit32.lshift(c, 2), 0x3C)
      elseif (state == 2) then
         -- case 2
         index = bit32.bor(index, bit32.band(bit32.rshift(c, 6), 0x03))
         result = append(result, index)
         index = bit32.band(c, 0x3F)
         result = append(result, index)
      end
   end

   -- Complete the string with zero bits and pad with "=" as necessary

   state = n % 3
   if (state == 0) then
      -- No padding necessary
   elseif (state == 1) then
      result = append(result, index)
      result = result .. '='
      result = result .. '='
   elseif (state == 2) then
      result = append(result, index)
      result = result .. '='
   end

   return result
end

------------------------------------------------------------------------
-- Decode function
------------------------------------------------------------------------
function M.decode(buffer)

   local n = buffer:len()

   if ((n % 4) ~= 0) then
      local errmsg = string.format("Buffer length %d is not a multiple of 4", n)
      error(errmsg)
   end

   local result = {}
   local ch

   for i = 1, n do

      local b = buffer:sub(i, i)
      local p = base64Table:find(b, 1, plain)
      if (p == nil) then
         if (b == '=') then
            p = 1
         else
            local errmsg = string.format("Invalid character [%s] in input", b)
            error(errmsg)
         end
      end
      p = p-1
      
      local state = (i-1) % 4

      if (state == 0) then
         ch = bit32.band(bit32.lshift(p, 2), 0xFC)
      elseif (state == 1) then
         ch = bit32.bor(ch, bit32.band(bit32.rshift(p, 4), 0x03))
         result[#result + 1] = ch
         ch = bit32.band(bit32.lshift(p, 4), 0xF0)
      elseif (state == 2) then
         ch = bit32.bor(ch, bit32.band(bit32.rshift(p, 2), 0x0F))
         result[#result + 1] = ch
         ch = bit32.band(bit32.lshift(p, 6), 0xC0)
      elseif (state == 3) then
         ch = bit32.bor(ch, bit32.band(p, 0x3F))
         result[#result + 1] = ch
      end
   end

   -- Remove the trailing nulls

   local nPad = 0
   for i = n, 1, -1 do
      local c = buffer:sub(i, i)
      if (c == '=') then
         nPad = nPad + 1
      else
         break
      end
   end
   n = math.max(#result - nPad, 0)

   -- Return the byte array

   local bytes = ""
   for i = 1, n do
      bytes = bytes .. string.char(result[i])
   end
   return bytes

end

return M
