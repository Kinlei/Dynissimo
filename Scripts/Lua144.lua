local __OUTPUTSIZE = 512;
local __CHUNKSIZE  =  32;

table.foreach = function(t, f)
    for i, v in next, t do
        f(i, v);
    end;
end;

local function IsPrime(n)
    for i = 2, n^(1/2) do
        if (n % i) == 0 then
            return false
        end
    end
    return true
end;

local function GetFirstNPrimes(n, from)
    local C = from or 1;
    local Primes = {};
    repeat
        if (IsPrime(C)) then
            table.insert(Primes, C);
        end;
        C = C + 1;
    until (#Primes == n);
    return Primes;
end;

local function PadUntilSize(s, pad, size)
    local ns = s;
    repeat
        ns = ns .. pad;
    until (#ns == size);
    return ns;
end;

local function PolynomialCoefficientN(...)
    local N = ...;
    local FirstNPrimes = GetFirstNPrimes(#N, 2);

    local CheckSum  = 0;
    local CheckSum2 = 0;

    for i = #FirstNPrimes, 1, -1 do
        local Coefficient = FirstNPrimes[i];
        local Substitute  = N[i];
        local Evaluation  = Coefficient * Substitute;
        CheckSum  = CheckSum + Evaluation;
        CheckSum2 = CheckSum2 + (Evaluation * (2 ^ __CHUNKSIZE));
    end;

    CheckSum  = math.floor(CheckSum * (2 ^ __CHUNKSIZE));
    CheckSum  = tostring(CheckSum):reverse() .. tostring(CheckSum);
    CheckSum2 = math.floor(CheckSum2 % 3);
    CheckSum2 = tostring(CheckSum2):reverse() .. tostring(CheckSum2);
    
    local FinalString = PadUntilSize(CheckSum, CheckSum2, 36);
    return FinalString;
end;

local function HexInGroups(s, n)
    local ns = "";
    for i = 1, #s, n do
        local Chunk  = string.sub(s, i, i + (n - 1));
        local HexOut = string.format("%0" .. tostring(n) .. "x", Chunk);
        ns = ns .. HexOut;
    end;
    return ns;
end;

return function(InputString)
    local BitTable = {};
    InputString:gsub(".", function(c) table.insert(BitTable, c:byte()) end);
    local ReturnString = PolynomialCoefficientN(BitTable);
    ReturnString = HexInGroups(ReturnString, 3);
    print(ReturnString);
    return ReturnString;
end;
