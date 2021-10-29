local __CHUNKSIZE = 512;
local __ENTRYSIZE =  32;

local Bit = require("bitop");

local MOD  = (2 ^ 32);
local MODM = MOD - 1;

---- Credits to MaHuJa on GitHub ----
local function memoize(f)
	local mt = {}
	local t = setmetatable({}, mt)
	function mt:__index(k)
		local v = f(k)
		t[k] = v
		return v
	end
	return t
end

local function make_bitop_uncached(t, m)
	local function bitop(a, b)
		local res,p = 0,1
		while a ~= 0 and b ~= 0 do
			local am, bm = a % m, b % m
			res = res + t[am][bm] * p
			a = (a - am) / m
			b = (b - bm) / m
			p = p*m
		end
		res = res + (a + b) * p
		return res
	end
	return bitop
end

local function make_bitop(t)
	local op1 = make_bitop_uncached(t,2^1)
	local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
	return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end

local bxor1 = make_bitop({[0] = {[0] = 0,[1] = 1}, [1] = {[0] = 1, [1] = 0}, n = 4})
------------------------------------

local _bxor = Bit.bit.bxor;
local bxor = function(a, b, c,...)
    local z;
    if (a) then
        if (b) then
            a = a % MOD;
            b = b % MOD;
            z = bxor1(a, b);
            if (c) then z = _bxor(z, c,...) end;
            return z;
        else
            return a % MOD;
        end;
    else
        return MODM;
    end;
end;
local _band = Bit.band;
local band = function(a, b)
    if (a) then
        if (b) then
            return _band(a, b);
        else
            return a % MOD;
        end;
    else
        return MODM;
    end;
end;
local _brsh = Bit.rshift;
local brsh = function(a, b)
    if (a) then
        return math.floor((a % MOD) % 2 ^ 32 / 2 ^ b);
    else
        return MODM;
    end;
end;
local _blsh = Bit.lshift;
local blsh = function(a, b)
    if (a) then
        return (a * 2 ^ b) % 2 ^ 32;
    else
        return MODM;
    end
end;
local _bror = Bit.rrotate;
local bror = function(a, b)
    if (a) then
        a = a % MOD;
        b = b % 32;
        local l = band(a, 2 ^ b - 1);
        return brsh(a, b) + blsh(l, 32 - b);
    else
        return MODM;
    end;
end;

local _bnot = Bit.bnot;
local bnot = function(a)
    return (-1 - a) % MOD;
end;
local function DecToBin(Dec, Bytes)
    local BinTable = {};
    for i = Bytes and (Bytes - 1) or 7, 0, -1 do
        local j = (2 ^ i);
        local b = (Dec >= j);
        if (b) then
            Dec = Dec - j;
        end
        table.insert(BinTable, b and "1" or "0");
    end
    return table.concat(BinTable, "");
end;

local function StringToBinary(String)
    local StringTable = {};
    
    for Character in String:gmatch(".") do
        table.insert(StringTable, DecToBin(Character:byte()));
    end;

    return table.concat(StringTable, "");
end;

local function Pad(String, Multiple, Space, With, Before)
    local Padded = String;
    repeat
        Padded = (Before and (With or "0") or "") .. Padded .. (Before and "" or (With or "0"));
    until ((Padded:len() + Space) % Multiple == 0);
    return Padded;
end;

local function IsPrime(n)
    for i = 2, math.sqrt(n) do
        if (n % i) == 0 then
            return false;
        end;
    end;
    return true;
end;

local function GetFirstNPrimes(n, From)
    local Primes = {};
    local C = From or 1;
    repeat
        if (IsPrime(C)) then
            table.insert(Primes, C);
        end;
        C = C + 1;
    until (#Primes == n);
    return Primes;
end;

local function NthRoot(n, Root)
    return n ^ (1 / Root);
end;

local function InitHashValues()
    local HashValues, Constants = {}, {};
    local First64Primes = GetFirstNPrimes(64, 2);

    for Idx = 1, 8 do
        local Prime = First64Primes[Idx];
        local SQRT  = math.sqrt(Prime);
        local REM   = math.fmod(SQRT, 1);
        local WHOLE = math.floor(REM * (2 ^ 32));
        HashValues[Idx] = WHOLE;
    end;

    for _, Prime in pairs(First64Primes) do
        local CBRT  = NthRoot(Prime, 3);
        local REM   = math.fmod(CBRT, 1);
        local WHOLE = math.floor(REM * (2 ^ 32));
        table.insert(Constants, WHOLE);
    end;

    return HashValues, Constants;
end;

local function GetChunks(Message, BlockSize)
    local Chunks = {};
    local ChunksNeeded = Message:len() / BlockSize;
    for Idx = 1, ChunksNeeded do
        local Chunk = string.sub(Message, (BlockSize * (Idx - 1)) + 1, (BlockSize * Idx));
        table.insert(Chunks, Chunk);
    end;
    return Chunks;
end;

local function PreProcess(String)
    ---- Convert String To Bin ----
    local OriginString = StringToBinary(String);
    local BinString = Pad(OriginString .. "1", 512, 64, nil, false);
    local BinLength = Pad(DecToBin(#OriginString), 64, 0, nil, true);
    local FinalString = BinString .. BinLength;
    -------------------------------
    ---- Initialise Hash Values ----
    local H, K = InitHashValues();
    --------------------------------
    ---- Iterate Through Chunks ----
    local Chunks = GetChunks(FinalString, __CHUNKSIZE);

    for _, Chunk in pairs(Chunks) do
        local W = GetChunks(Chunk, __ENTRYSIZE);

        for i = 1, 16 do
            W[i] = tonumber(W[i], 2);
        end;

        ---- Entry Mutation ----
        for i = 17, 64 do
            local s  = W[i - 15];
            local S1 = bxor(bror(s,  8), bror(s, 20), brsh(s,  2));
                  s  = W[i -  2];
            local S2 = bxor(bror(s, 17), bror(s, 19), brsh(s, 10));
            W[i] = math.floor(W[i - 16] + S1 + W[i - 7] + S2);
        end;
        ------------------------

        ---- Hash Values Mutation ----
        local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8];

        for i = 1, 64 do
            local S1 = bxor(bror(a, 3), bror(a, 14), bror(a, 21));
            local MJ = bxor(band(a, b), band(a, c), band(b, c));
            local T2 = S1 + MJ;
            local S2 = bxor(bror(e, 5), bror(e, 12), bror(e, 25));
            local CH = bxor(band(e, f), band(bnot(e), g));
            local T1 = h + S2 + CH + K[i] + W[i];
            h, g, f, e, d, c, b, a = g, f, e, d + T1, c, b, a, T1 + T2;
        end;

        H[1] = math.floor(band(H[1] + a));
        H[2] = math.floor(band(H[2] + b));
        H[3] = math.floor(band(H[3] + c));
        H[4] = math.floor(band(H[4] + d));
        H[5] = math.floor(band(H[5] + e));
        H[6] = math.floor(band(H[6] + f));
        H[7] = math.floor(band(H[7] + g));
        H[8] = math.floor(band(H[8] + h));
        ------------------------------
    end;
    --------------------------------

    local function decimalToHex(num)
        num = (type(num) == "string") and tonumber(num) or num;
        if num == 0 then
            return '0'
        end
        local neg = false
        if num < 0 then
            neg = true
            num = num * -1
        end
        local hexstr = "0123456789ABCDEF"
        local result = ""
        while num > 0 do
            local n = num % 16;
            result = string.sub(hexstr, n + 1, n + 1) .. result
            num = math.floor(num / 16)
        end
        if neg then
            result = '-' .. result
        end
        return result
    end

    local FinalString = "";

    for _, Value in pairs(H) do
        FinalString = FinalString .. decimalToHex(Value);
    end;

    return FinalString;
end;

return function(InputString)
    return PreProcess(InputString);
end;
