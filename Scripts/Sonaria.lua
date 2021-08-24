local Player = game:GetService("Players").LocalPlayer;

local RE = Player.RemoteEvent;
local RF = Player.RemoteFunction;

getgenv().IrisAd = true;

do
    if (not _G.Hooked) then
        _G.Hooked = true;
        local OldNC;
        
        OldNC = hookmetamethod(game, "__namecall", function(...)
            local Args = {...};
            local Self = Args[1];
            local Method = getnamecallmethod();
            
            if (not checkcaller()) then
                if (Self == RE) and (Method == "FireServer") and (Args[2] == "UpdateShelter") then
                    Args[3] = "Total";
                end;
            end;
            
            return OldNC(unpack(Args));
        end);
    end;
end;

local Library = loadstring(game:HttpGet("https://pastebin.com/raw/edJT9EGX"))();
local IrisNotif = loadstring(game:HttpGet("https://api.irisapp.ca/Scripts/IrisBetterNotifications.lua"))();

IrisNotif.Notify("Credits", "Credits to Jan and Iris for their UI and Notification libraries, respectively.", {
    Duration = 2
})

local MainWindow = Library:CreateWindow("Farming");

local AutoEat = false;
local AutoDrink = false;
local Greed = 0.2;

MainWindow:AddToggle({
    text = "Auto-Eat";
    state = AutoEat;
    callback = function()
        AutoEat = not AutoEat;
    end;
});

MainWindow:AddToggle({
    text = "Auto-Drink";
    state = AutoDrink;
    callback = function()
        AutoDrink = not AutoDrink;
    end;
});

MainWindow:AddSlider({
    text = "Food Threshold";
    min = 0.2;
    max = 1;
    float = 0.1;
    callback = function(v)
        Greed = v;
    end;
});

Library:Init();

local WS = game:GetService("Workspace");
local Tween = game:GetService("TweenService");
local Run = game:GetService("RunService");

local Food = WS.Food;
local Dinos = WS.Dinosaurs;
local Water = WS.Water;

local PS = Player.PlayerScripts;

local MainScript = PS.LocalScript;
local CharacterScript = require(MainScript.Character);

local function FetchDino()
    return Player.Character;
end;

local function FetchSlotData()
    return Player.Slot.Value;
end;

local function Fire(...)
    RE:FireServer(...);
end;

local function Invoke(...)
    RF:InvokeServer(...);
end;

local function FindTableInstance(Table, InstanceName)
    for i,v in next, Table do
        if v.Name == InstanceName then
            return v;
        end;
    end;
end;

local function GetDistance(V1, V2)
    return (V1 - V2).Magnitude;
end;

local function FindClosestObjectTo(ToPart, FromTable)
    local LowestMag, ClosestPart;
    for _, Part in next, FromTable do
        local Mag = GetDistance(ToPart.Position, Part:IsA("Model") and Part.PrimaryPart.Position or Part.Position);
        if (not LowestMag) or (not ClosestPart) then
            LowestMag = Mag;
            ClosestPart = Part;
        end;
        if (Mag < LowestMag) then
            LowestMag = Mag;
            ClosestPart = Part;
        end;
    end;
    return ClosestPart, LowestMag;
end;

local function GetClosestFood()
    local Dino = FetchDino();
    if (Dino) then
        local DinoData = Dino.Data;
        local CurrentPoint = (FetchSlotData().Food.Value / DinoData.Appetite.Value);
        if (CurrentPoint < Greed) then
            local FoodType = DinoData.FoodType.Value;
            local Speed = DinoData.Speed.Value;
            local HRP = Dino.PrimaryPart;
            local PossibleFoods = nil;
            if (FoodType == "Omnivore") then
                PossibleFoods = Food:GetChildren();
            else
                local LookingFor = (FoodType == "Carnivore") and ("Meat") or ("Mesh");
                local CurrentFoods = Food:GetDescendants();
                PossibleFoods = {};
                for _, Part in next, CurrentFoods do
                    if (Part.Name == LookingFor) then
                        table.insert(PossibleFoods, Part.Parent);
                    end;
                end;
            end;
            local ClosestFood, Distance = FindClosestObjectTo(HRP, PossibleFoods);
            local Time = (Distance / Speed);
            local FoodTween = Tween:Create(HRP, TweenInfo.new(Time), {
                CFrame = ClosestFood.PrimaryPart.CFrame;
            });
            FoodTween:Play();
            FoodTween.Completed:Connect(function()
                repeat
                    Fire("eat", ClosestFood.PrimaryPart);
                    warn(ClosestFood.Food.Value);
                    wait(2);
                until (ClosestFood.Food.Value <= 1) or ((FetchSlotData().Food.Value / DinoData.Appetite.Value) >= FoodThreshold);
            end);
        end;
    end;
end;

local function Eat()
    if (FetchDino()) then
        GetClosestFood();
    end;
end;

local function Drink()
    if (FetchDino()) then
        local WP = Water:GetChildren();
        local PT = WP[math.random(1, #WP)];
        Fire("drink", PT.Part);
    end;
end;

Player.CharacterAdded:Connect(function()
    Fire("UpdateShelter", "Total");
end);

coroutine.resume(coroutine.create(function()
    while true do
        if (AutoEat) then
            Eat();
        end;
        if (AutoDrink) then
            Drink();
        end;
        wait(5);
    end;
end));
