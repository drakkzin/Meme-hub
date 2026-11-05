--[[
  Zenthra-Style Blade Ball Script v1
  language: Lua (Luau) · target: Roblox executor · Blade Ball
  standalone · no key
  Strong Auto Parry + Smart Spam + Visuals + Personalize
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local okAll, errAll = pcall(function()

local Players           = game:GetService("Players")
local UIS               = game:GetService("UserInputService")
local TS                = game:GetService("TweenService")
local RS                = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local Rep               = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local HttpService       = game:GetService("HttpService")
local Stats             = game:GetService("Stats")
local Debris            = game:GetService("Debris")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local CoreGui           = game:GetService("CoreGui")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PG = LP:WaitForChild("PlayerGui", 25)
if not PG then return end

pcall(function()
	for _, n in ipairs({"ZenthraStyle","MemeHub","MemeHubFloat","ZyxHub"}) do
		local o = PG:FindFirstChild(n) or CoreGui:FindFirstChild(n)
		if o then o:Destroy() end
	end
end)

print("[ZenthraStyle v1] boot")

local function GG()
	local ok, g = pcall(function() return getgenv() end)
	if ok and type(g) == "table" then return g end
	return _G
end
local genv = GG()

local Config = {
	autoParry       = false,
	triggerBot      = false,
	pingComp        = true,
	animFix         = true,
	parryMethod     = "Remote",
	parryDist       = 95,
	parryAccuracy   = 92,
	autoSpam        = false,
	spamRange       = 18,
	spamSpeedThresh = 85,
	smartSpam       = true,
	curve           = false,
	curveChance     = 55,
	fullbright      = false,
	headless        = false,
	korblox         = false,
	antiAFK         = true,
	infJump         = false,
	walkBoost       = false,
	walkSpeed       = 22,
	esp             = false,
	ballHighlight   = true,
	trail           = false,
	uiScale         = 1,
	theme           = "Dark",
	accentR         = 120,
	accentG         = 60,
	accentB         = 255,
}

local function saveConfig()
	pcall(function()
		if writefile then
			writefile("ZenthraStyle_BB.json", HttpService:JSONEncode(Config))
		end
	end)
end

local function loadConfig()
	pcall(function()
		if isfile and isfile("ZenthraStyle_BB.json") then
			local d = HttpService:JSONDecode(readfile("ZenthraStyle_BB.json"))
			for k,v in pairs(d) do Config[k] = v end
		end
	end)
end
loadConfig()

local function getChar()
	return LP.Character or LP.CharacterAdded:Wait()
end

local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end

local function getPing()
	local ok, p = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	return (ok and tonumber(p)) or 60
end

local function fireParry()
	if Config.parryMethod == "VIM" then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
			task.wait(0.02)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
		end)
	elseif Config.parryMethod == "Legit" then
		pcall(function()
			local vim = game:GetService("VirtualInputManager")
			vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
			task.wait(0.015)
			vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
		end)
	else
		pcall(function()
			local remotes = Rep:FindFirstChild("Remotes") or Rep
			local parryRemote = remotes:FindFirstChild("ParrySuccess") 
				or remotes:FindFirstChild("Parry") 
				or remotes:FindFirstChild("Block")
			if parryRemote and parryRemote:IsA("RemoteEvent") then
				parryRemote:FireServer()
			else
				VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
				task.wait(0.02)
				VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
			end
		end)
	end
end

local currentBall = nil
local lastBallSpeed = 0
local lastParryTime = 0
local spamActive = false

local function findBall()
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("sphere")) then
			if obj.Size.Magnitude < 8 and obj.Size.Magnitude > 0.5 then
				return obj
			end
		end
	end
	local balls = workspace:FindFirstChild("Balls") or workspace:FindFirstChild("Ball")
	if balls then
		if balls:IsA("BasePart") then return balls end
		for _, b in ipairs(balls:GetChildren()) do
			if b:IsA("BasePart") then return b end
		end
	end
	return nil
end

local function doAutoParry()
	if not Config.autoParry then return end
	local ball = findBall()
	if not ball then return end
	currentBall = ball

	local hrp = getHRP()
	if not hrp then return end

	local dist = (ball.Position - hrp.Position).Magnitude
	local vel = ball.AssemblyLinearVelocity or ball.Velocity
	local speed = vel.Magnitude
	lastBallSpeed = speed

	local ping = getPing()
	local pingOffset = Config.pingComp and (ping / 1000 * speed * 0.55) or 0
	local effectiveDist = Config.parryDist + pingOffset

	local acc = Config.parryAccuracy / 100
	if math.random() > acc then return end

	if dist <= effectiveDist and speed > 12 then
		local now = tick()
		if now - lastParryTime > 0.12 then
			fireParry()
			lastParryTime = now

			if Config.smartSpam and Config.autoSpam then
				local closest = nil
				local closestDist = Config.spamRange
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr ~= LP and plr.Character then
						local pHrp = plr.Character:FindFirstChild("HumanoidRootPart")
						if pHrp then
							local d = (pHrp.Position - hrp.Position).Magnitude
							if d < closestDist then
								closestDist = d
								closest = plr
							end
						end
					end
				end
				if closest and speed > Config.spamSpeedThresh then
					spamActive = true
					task.delay(0.65, function() spamActive = false end)
				end
			end
		end
	end
end

local function doSpam()
	if not Config.autoSpam then return end
	if not spamActive and not Config.smartSpam then
		local hrp = getHRP()
		if not hrp then return end
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LP and plr.Character then
				local pHrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if pHrp and (pHrp.Position - hrp.Position).Magnitude < Config.spamRange then
					fireParry()
					break
				end
			end
		end
	elseif spamActive then
		fireParry()
	end
end

RS.Heartbeat:Connect(function()
	pcall(doAutoParry)
	pcall(doSpam)
end)

RS.RenderStepped:Connect(function()
	if not Config.triggerBot then return end
	local ball = findBall()
	local hrp = getHRP()
	if ball and hrp then
		if (ball.Position - hrp.Position).Magnitude < 12 then
			fireParry()
		end
	end
end)

local ballHighlightInst = nil
local function updateBallHighlight()
	if not Config.ballHighlight then
		if ballHighlightInst then ballHighlightInst:Destroy() ballHighlightInst = nil end
		return
	end
	local ball = findBall()
	if ball then
		if not ballHighlightInst or ballHighlightInst.Parent ~= ball then
			if ballHighlightInst then ballHighlightInst:Destroy() end
			local h = Instance.new("Highlight")
			h.FillColor = Color3.fromRGB(Config.accentR, Config.accentG, Config.accentB)
			h.OutlineColor = Color3.new(1,1,1)
			h.FillTransparency = 0.45
			h.Parent = ball
			ballHighlightInst = h
		end
	end
end

RS.Heartbeat:Connect(function()
	pcall(updateBallHighlight)
end)

local espFolder = Instance.new("Folder")
espFolder.Name = "ZenthraESP"
espFolder.Parent = CoreGui

local function clearESP()
	for _, c in ipairs(espFolder:GetChildren()) do c:Destroy() end
end

local function updateESP()
	if not Config.esp then clearESP() return end
	clearESP()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local bill = Instance.new("BillboardGui")
				bill.Size = UDim2.new(0, 120, 0, 30)
				bill.AlwaysOnTop = true
				bill.StudsOffset = Vector3.new(0, 3, 0)
				bill.Adornee = hrp
				bill.Parent = espFolder

				local txt = Instance.new("TextLabel")
				txt.Size = UDim2.new(1,0,1,0)
				txt.BackgroundTransparency = 1
				txt.Text = plr.Name .. " [" .. math.floor(hum.Health) .. "]"
				txt.TextColor3 = Color3.fromRGB(Config.accentR, Config.accentG, Config.accentB)
				txt.TextStrokeTransparency = 0.4
				txt.Font = Enum.Font.GothamBold
				txt.TextSize = 13
				txt.Parent = bill
			end
		end
	end
end

task.spawn(function()
	while true do
		pcall(updateESP)
		task.wait(1.2)
	end
end)

local function setFullbright(on)
	Config.fullbright = on
	saveConfig()
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false
	else
		Lighting.Brightness = 1
		Lighting.GlobalShadows = true
	end
end

local function setHeadless(on)
	Config.headless = on
	saveConfig()
	local char = getChar()
	if not char then return end
	local head = char:FindFirstChild("Head")
	if head then
		head.Transparency = on and 1 or 0
		for _, d in ipairs(head:GetDescendants()) do
			if d:IsA("Decal") then d.Transparency = on and 1 or 0 end
		end
	end
end

local function setKorblox(on)
	Config.korblox = on
	saveConfig()
	local char = getChar()
	if not char then return end
	for _, name in ipairs({"RightUpperLeg","RightLowerLeg","RightFoot","Right Leg"}) do
		local p = char:FindFirstChild(name)
		if p then
			p.Transparency = on and 1 or 0
			for _, d in ipairs(p:GetDescendants()) do
				if d:IsA("BasePart") or d:IsA("MeshPart") or d:IsA("Decal") then
					d.Transparency = on and 1 or 0
				end
			end
		end
	end
end

local function setAntiAFK(on)
	Config.antiAFK = on
	saveConfig()
end

task.spawn(function()
	while true do
		if Config.antiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
		task.wait(50)
	end
end)

local function setInfJump(on)
	Config.infJump = on
	saveConfig()
end

UIS.JumpRequest:Connect(function()
	if not Config.infJump then return end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local function setWalkBoost(on)
	Config.walkBoost = on
	saveConfig()
	local hum = getHum()
	if not hum then return end
	if on then
		hum.WalkSpeed = Config.walkSpeed or 22
	else
		hum.WalkSpeed = 16
	end
end

LP.CharacterAdded:Connect(function()
	task.wait(0.9)
	if Config.headless then setHeadless(true) end
	if Config.korblox then setKorblox(true) end
	if Config.walkBoost then setWalkBoost(true) end
	if Config.fullbright then setFullbright(true) end
end)

local T = {
	bg      = Color3.fromRGB(18, 18, 24),
	card    = Color3.fromRGB(28, 28, 36),
	card2   = Color3.fromRGB(38, 38, 48),
	accent  = Color3.fromRGB(Config.accentR, Config.accentG, Config.accentB),
	text    = Color3.fromRGB(240, 240, 245),
	dim     = Color3.fromRGB(150, 150, 165),
	ok      = Color3.fromRGB(80, 220, 120),
	bad     = Color3.fromRGB(220, 80, 80),
	blue    = Color3.fromRGB(80, 140, 255),
}

local Screen = Instance.new("ScreenGui")
Screen.Name = "ZenthraStyle"
Screen.ResetOnSpawn = false
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = PG

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 420 * Config.uiScale, 0, 520 * Config.uiScale)
Main.Position = UDim2.new(0.5, -210, 0.5, -260)
Main.BackgroundColor3 = T.bg
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = Main

local stroke = Instance.new("UIStroke")
stroke.Color = T.accent
stroke.Thickness = 1.5
stroke.Parent = Main

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = T.card
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Zenthra Style  ·  Blade Ball"
Title.TextColor3 = T.text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0, 5)
CloseBtn.BackgroundColor3 = T.card2
CloseBtn.Text = "×"
CloseBtn.TextColor3 = T.text
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 18
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function()
	Screen.Enabled = false
end)

local Status = Instance.new("TextLabel")
Status.Name = "Status"
Status.Size = UDim2.new(1, -20, 0, 22)
Status.Position = UDim2.new(0, 10, 0, 48)
Status.BackgroundTransparency = 1
Status.Text = "Status: Ready"
Status.TextColor3 = T.dim
Status.Font = Enum.Font.Gotham
Status.TextSize = 13
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -20, 0, 34)
TabBar.Position = UDim2.new(0, 10, 0, 74)
TabBar.BackgroundTransparency = 1
TabBar.Parent = Main

local tabs = {"Combat", "Visuals", "Player", "Config"}
local pages = {}
local currentTab = "Combat"

local function makeTab(name, order)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 92, 1, 0)
	btn.Position = UDim2.new(0, (order-1)*96, 0, 0)
	btn.BackgroundColor3 = T.card2
	btn.Text = name
	btn.TextColor3 = T.dim
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Parent = TabBar
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, -20, 1, -120)
	page.Position = UDim2.new(0, 10, 0, 114)
	page.BackgroundTransparency = 1
	page.ScrollBarThickness = 4
	page.CanvasSize = UDim2.new(0, 0, 0, 600)
	page.Visible = (name == "Combat")
	page.Parent = Main
	pages[name] = page

	btn.MouseButton1Click:Connect(function()
		currentTab = name
		for n, p in pairs(pages) do
			p.Visible = (n == name)
		end
		for _, b in ipairs(TabBar:GetChildren()) do
			if b:IsA("TextButton") then
				b.BackgroundColor3 = (b.Text == name) and T.accent or T.card2
				b.TextColor3 = (b.Text == name) and Color3.new(1,1,1) or T.dim
			end
		end
	end)
	if name == "Combat" then
		btn.BackgroundColor3 = T.accent
		btn.TextColor3 = Color3.new(1,1,1)
	end
end

for i, t in ipairs(tabs) do makeTab(t, i) end

local function addToggle(parent, text, desc, default, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 52)
	f.BackgroundColor3 = T.card
	f.BorderSizePixel = 0
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -70, 0, 22)
	l.Position = UDim2.new(0, 12, 0, 6)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = T.text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 14
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local d = Instance.new("TextLabel")
	d.Size = UDim2.new(1, -70, 0, 18)
	d.Position = UDim2.new(0, 12, 0, 28)
	d.BackgroundTransparency = 1
	d.Text = desc
	d.TextColor3 = T.dim
	d.Font = Enum.Font.Gotham
	d.TextSize = 11
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.Parent = f

	local toggle = Instance.new("TextButton")
	toggle.Size = UDim2.new(0, 48, 0, 26)
	toggle.Position = UDim2.new(1, -58, 0.5, -13)
	toggle.BackgroundColor3 = default and T.ok or T.card2
	toggle.Text = default and "ON" or "OFF"
	toggle.TextColor3 = Color3.new(1,1,1)
	toggle.Font = Enum.Font.GothamBold
	toggle.TextSize = 12
	toggle.Parent = f
	Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

	local state = default
	toggle.MouseButton1Click:Connect(function()
		state = not state
		toggle.BackgroundColor3 = state and T.ok or T.card2
		toggle.Text = state and "ON" or "OFF"
		callback(state)
		Status.Text = text .. (state and " ON" or " OFF")
		Status.TextColor3 = state and T.ok or T.dim
	end)

	local layout = parent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = parent
	end
end

local function addSlider(parent, text, min, max, default, callback)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 58)
	f.BackgroundColor3 = T.card
	f.BorderSizePixel = 0
	f.Parent = parent
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1, -20, 0, 20)
	l.Position = UDim2.new(0, 12, 0, 4)
	l.BackgroundTransparency = 1
	l.Text = text .. ": " .. tostring(default)
	l.TextColor3 = T.text
	l.Font = Enum.Font.GothamBold
	l.TextSize = 13
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = f

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, -24, 0, 10)
	bar.Position = UDim2.new(0, 12, 0, 34)
	bar.BackgroundColor3 = T.card2
	bar.BorderSizePixel = 0
	bar.Parent = f
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 5)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
	fill.BackgroundColor3 = T.accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 5)

	local dragging = false
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
			local val = math.floor(min + (max-min)*rel)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			l.Text = text .. ": " .. tostring(val)
			callback(val)
		end
	end)

	local layout = parent:FindFirstChildOfClass("UIListLayout")
	if not layout then
		layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = parent
	end
end

local combatPage = pages["Combat"]
addToggle(combatPage, "Auto Parry", "Parry automático por distância/velocidade", Config.autoParry, function(v)
	Config.autoParry = v
	saveConfig()
end)
addToggle(combatPage, "Trigger Bot", "Parry quando a bola está muito perto", Config.triggerBot, function(v)
	Config.triggerBot = v
	saveConfig()
end)
addToggle(combatPage, "Ping Compensation", "Ajusta timing pelo ping", Config.pingComp, function(v)
	Config.pingComp = v
	saveConfig()
end)
addToggle(combatPage, "Auto Spam", "Spam de parry quando perto", Config.autoSpam, function(v)
	Config.autoSpam = v
	saveConfig()
end)
addToggle(combatPage, "Smart Spam", "Ativa spam só quando oponente perto + bola rápida", Config.smartSpam, function(v)
	Config.smartSpam = v
	saveConfig()
end)
addToggle(combatPage, "Curve", "Tenta curvar a bola", Config.curve, function(v)
	Config.curve = v
	saveConfig()
end)

addSlider(combatPage, "Parry Distance", 50, 150, Config.parryDist, function(v)
	Config.parryDist = v
	saveConfig()
end)
addSlider(combatPage, "Parry Accuracy %", 60, 100, Config.parryAccuracy, function(v)
	Config.parryAccuracy = v
	saveConfig()
end)
addSlider(combatPage, "Spam Range", 8, 30, Config.spamRange, function(v)
	Config.spamRange = v
	saveConfig()
end)

local visPage = pages["Visuals"]
addToggle(visPage, "Ball Highlight", "Destaca a bola", Config.ballHighlight, function(v)
	Config.ballHighlight = v
	saveConfig()
end)
addToggle(visPage, "ESP Players", "Mostra nomes e vida", Config.esp, function(v)
	Config.esp = v
	saveConfig()
end)
addToggle(visPage, "Fullbright", "Iluminação máxima", Config.fullbright, function(v)
	setFullbright(v)
end)

local playerPage = pages["Player"]
addToggle(playerPage, "Anti AFK", "Evita kick por inatividade", Config.antiAFK, function(v)
	setAntiAFK(v)
end)
addToggle(playerPage, "Infinite Jump", "Pulo infinito", Config.infJump, function(v)
	setInfJump(v)
end)
addToggle(playerPage, "Walk Boost", "Velocidade de caminhada aumentada", Config.walkBoost, function(v)
	setWalkBoost(v)
end)
addToggle(playerPage, "Headless", "Remove a cabeça", Config.headless, function(v)
	setHeadless(v)
end)
addToggle(playerPage, "Korblox", "Perna direita invisível", Config.korblox, function(v)
	setKorblox(v)
end)

local configPage = pages["Config"]
addSlider(configPage, "UI Scale", 80, 130, Config.uiScale * 100, function(v)
	Config.uiScale = v / 100
	saveConfig()
	Main.Size = UDim2.new(0, 420 * Config.uiScale, 0, 520 * Config.uiScale)
end)

local methodLabel = Instance.new("TextLabel")
methodLabel.Size = UDim2.new(1, 0, 0, 24)
methodLabel.BackgroundTransparency = 1
methodLabel.Text = "Parry Method: " .. Config.parryMethod
methodLabel.TextColor3 = T.text
methodLabel.Font = Enum.Font.GothamBold
methodLabel.TextSize = 14
methodLabel.Parent = configPage

for _, m in ipairs({"Remote", "VIM", "Legit"}) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = (m == Config.parryMethod) and T.accent or T.card2
	b.Text = "Method: " .. m
	b.TextColor3 = T.text
	b.Font = Enum.Font.Gotham
	b.TextSize = 13
	b.Parent = configPage
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.MouseButton1Click:Connect(function()
		Config.parryMethod = m
		saveConfig()
		methodLabel.Text = "Parry Method: " .. m
		Status.Text = "Method set to " .. m
	end)
end

local Float = Instance.new("TextButton")
Float.Name = "Float"
Float.Size = UDim2.new(0, 48, 0, 48)
Float.Position = UDim2.new(0, 20, 0.5, -24)
Float.BackgroundColor3 = T.accent
Float.Text = "Z"
Float.TextColor3 = Color3.new(1,1,1)
Float.Font = Enum.Font.GothamBold
Float.TextSize = 20
Float.Parent = Screen
Instance.new("UICorner", Float).CornerRadius = UDim.new(1, 0)
Float.MouseButton1Click:Connect(function()
	Screen.Enabled = true
	Main.Visible = true
end)

print("[ZenthraStyle v1] loaded — use the floating Z button if you close the menu")

end)

if not okAll then
	warn("[ZenthraStyle] error:", errAll)
end
