repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer
print("KAMI•APA SAFE")

-- SERVICES
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

-- SAFE PROMPT FUNCTION (INI PENTING)
local firePrompt = typeof(fireproximityprompt) == "function"
	and fireproximityprompt
	or function() end

-- CONFIG
getgenv().TARGET_UNITS = getgenv().TARGET_UNITS or {}
getgenv().GRAB_RADIUS = getgenv().GRAB_RADIUS or 8
getgenv().WEBHOOK_URL = getgenv().WEBHOOK_URL or ""
local SPIN_INTERVAL = 5

-- BASIC
local function char()
	return player.Character
end

local function hrp()
	local c = char()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function humanoid()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function send(msg)
	if getgenv().WEBHOOK_URL == "" then return end
	pcall(function()
		HttpService:PostAsync(
			getgenv().WEBHOOK_URL,
			HttpService:JSONEncode({ content = msg }),
			Enum.HttpContentType.ApplicationJson
		)
	end)
end

-- TARGET CHECK
local function isTarget(model)
	local idx = model:GetAttribute("Index")
	if not idx then return false end
	for _,v in ipairs(getgenv().TARGET_UNITS) do
		if v == idx then return true end
	end
	return false
end

-- STATE
local currentTarget
local pendingName
local lastMoney

-- MONEY DETECT
task.spawn(function()
	local stats = player:WaitForChild("leaderstats")
	for _,v in ipairs(stats:GetChildren()) do
		if v:IsA("IntValue") or v:IsA("NumberValue") then
			lastMoney = v.Value
			v.Changed:Connect(function(nv)
				if nv < lastMoney and pendingName then
					send("🛒 Bought: "..pendingName)
					currentTarget = nil
					pendingName = nil
				end
				lastMoney = nv
			end)
			break
		end
	end
end)

-- TARGET SPAWN
workspace.DescendantAdded:Connect(function(obj)
	if currentTarget then return end
	if obj:IsA("Model") and isTarget(obj) then
		currentTarget = obj
		pendingName = obj:GetAttribute("Index") or obj.Name
	end
end)

-- AUTO PROMPT (ANTI NIL)
ProximityPromptService.PromptShown:Connect(function(prompt)
	if currentTarget and prompt:IsDescendantOf(currentTarget) then
		firePrompt(prompt)
	end
end)

-- MOVE LOOP
task.spawn(function()
	while true do
		if currentTarget then
			local part = currentTarget:FindFirstChildWhichIsA("BasePart")
			local h = humanoid()
			local r = hrp()
			if part and h and r then
				if (r.Position - part.Position).Magnitude > getgenv().GRAB_RADIUS then
					h:MoveTo(part.Position)
				end
			end
		end
		task.wait(0.5)
	end
end)

-- AUTO SPIN (PCALL SAFE)
task.spawn(function()
	local Packages = ReplicatedStorage:WaitForChild("Packages")
	local ok, Net = pcall(require, Packages:WaitForChild("Net"))
	if not ok then return end

	local SpinEvent = Net:RemoteEvent("ChristmasEventService/Spin")
	local last = 0

	while true do
		if tick() - last >= SPIN_INTERVAL then
			pcall(function()
				SpinEvent:FireServer()
			end)
			last = tick()
		end
		task.wait(0.5)
	end
end)

-- ANTI AFK (SAFE)
player.Idled:Connect(function()
	VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
	task.wait(1)
	VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)
