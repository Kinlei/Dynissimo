local StratName = "EventFarmACEOnly";
local APIVar = "TDS";
local Map, Mode, Type = "Outpost 32", "", "Event";
--[[ 
    MAP: Name of Map
    MODE: Modes - [Normal, Molten, Fallen]
    TYPE: Types - [Survival, Hardcore, Event]
]]
local Towers = {"\"Ace Pilot\"", "nil", "nil", "nil", "nil"};
local Extension = ".lua";
local FileName = (StratName..Extension);

local OldIndex, OldNamecall = nil, nil;

writefile(FileName, string.format([[
local %s = loadstring(game:HttpGet("https://pastebin.com/raw/JCNCcYBr", true))()
%s:Loadout(%s, %s, %s, %s, %s)
%s:Map("%s", true, "%s")
%s:Mode("%s")
]], APIVar, APIVar, Towers[1], Towers[2], Towers[3], Towers[4], Towers[5], APIVar, Map, Type, APIVar, Mode));

local ReplicatedStorage = game:GetService("ReplicatedStorage");
local State = ReplicatedStorage.State;
local Wave = State.Wave;
local Timer = State.Timer;
local CurTime = Timer.Time;

local function Convert(Seconds)
    return math.floor(Seconds / 60), Seconds % 60;
end;

local Towers = {};
local GameTowers = game.Workspace.Towers;

local Events = {
    ["Troops"] = {
        ["Place"] = function(Tower, PositionData)
            local Position = PositionData.Position;
            local CurWave = Wave.Value;
            local TM, TS = Convert(CurTime.Value);
            appendfile(FileName, string.format("%s:Place(\"%s\", %f, %f, %f, %d, %d, %d)\n", APIVar, Tower, Position.X, Position.Y, Position.Z, CurWave, TM, TS));
        end;
        ["Sell"] = function(Info)
            local Index = table.find(GameTowers:GetChildren(), Info.Troop);
            local TM, TS = Convert(CurTime.Value);
            appendfile(FileName, string.format("%s:Sell(%d, %d, %d, %d)\n", APIVar, Index, Wave.Value, TM, TS));
        end;
        ["Upgrade"] = {
            ["Set"] = function(Troop)
                local Index = table.find(GameTowers:GetChildren(), Troop.Troop);
                local TM, TS = Convert(CurTime.Value);
                appendfile(FileName, string.format("%s:Upgrade(%d, %d, %d, %d)\n", APIVar, Index, Wave.Value, TM, TS));
            end;
        };
        ["Abilities"] = {
            ["Activate"] = function(Info)
                local Troop, Ability = Info.Troop, Info.Name;
                local Index = table.find(GameTowers:GetChildren(), Troop);
                local TM, TS = Convert(CurTime.Value);
                appendfile(FileName, string.format("%s:Ability(%d, \"%s\", %d, %d, %d)\n", APIVar, Index, Ability, Wave.Value, TM, TS));
            end;
        }
    },
    ["Waves"] = {
        ["Skip"] = function()
            local TM, TS = Convert(CurTime.Value);
            appendfile(FileName, string.format("%s:Skip(%d, %d, %d)\n", APIVar, Wave.Value, TM, TS));
        end;
    }
}

OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Args = {...};
    local Self = table.remove(Args, 1);
    local Method = getnamecallmethod();
    
    if (not checkcaller()) then
        if (table.find({"InvokeServer", "FireServer"}, Method)) then
            coroutine.wrap(function()
                local Select = table.remove(Args, 1);
                local Current = Events[Select];
                if (Current) then
                    local Logs = {};
                    local Next = table.remove(Args, 1);
                    table.insert(Logs, Next);
                    Current = Current[Next];
                    while (typeof(Current) == "table") do
                        Next = table.remove(Args, 1);
                        table.insert(Logs, Next);
                        Current = Current[Next];
                    end;
                    if (typeof(Current) == "function") then
                        local a, b = pcall(Current, unpack(Args));
                        warn(string.format("[A] %s [B] %s", tostring(a), tostring(b)));
                        if (not a) then
                            print("-- DEBUG --");
                            print(unpack(Logs));
                            print("-- DEBUG --");
                        end;
                    end;
                end;
            end)();
        end;
    end;
    
    return OldNamecall(...);
end));
