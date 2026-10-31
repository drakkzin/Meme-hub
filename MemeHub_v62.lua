--[[
  Meme Hub v62
  language: Lua (Luau) · target: Roblox executor · Blade Ball style
  standalone · no key
  combat core + music + swords + heavy personalize + visuals
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
local ContentProvider   = game:GetService("ContentProvider")
local Stats             = game:GetService("Stats")
local Debris            = game:GetService("Debris")
local VirtualUser       = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer or Players.PlayerAdded:Wait()
local PG = LP:WaitForChild("PlayerGui", 25)
if not PG then return end

pcall(function()
	for _, n in ipairs({"ZyxHub","MemeHub","MemeHubFloat"}) do
		local o = PG:FindFirstChild(n)
		if o then o:Destroy() end
	end
end)

print("[Meme Hub v62] boot")

local function GG()
	local ok, g = pcall(function() return getgenv() end)
	if ok and type(g) == "table" then return g end
	return _G
end

local VERSION = "62-COMBAT"

local function loadJSON(n, def)
	local d = def
	pcall(function()
		if GG()["Meme_"..n] then d = GG()["Meme_"..n] return end
		if isfile and readfile and isfile("Meme_"..n..".json") then
			d = HttpService:JSONDecode(readfile("Meme_"..n..".json"))
		end
	end)
	return d or def
end

local function saveJSON(n, d)
	pcall(function()
		GG()["Meme_"..n] = d
		if writefile then writefile("Meme_"..n..".json", HttpService:JSONEncode(d)) end
	end)
end

local ThemeSave = loadJSON("Theme", {
	accentR = 55, accentG = 140, accentB = 255,
	bgR = 12, bgG = 14, bgB = 22,
	cardR = 22, cardG = 24, cardB = 38,
	guiTrans = 0.18, cardTrans = 0.28, sidebarTrans = 0.12, topTrans = 0.25, wallTrans = 0.25,
	wallpaper = "https://paste.rs/bNN9e",
	floatImage = "https://paste.rs/yFJBJ",
	floatSize = 56,
	uiScale = nil, winW = 820, winH = 560,
	font = "Gotham",
	cornerRadius = 12,
	strokeThick = 1.2,
	animSpeed = 0.18,
})

local function C(r,g,b) return Color3.fromRGB(r,g,b) end
local function accent() return C(ThemeSave.accentR, ThemeSave.accentG, ThemeSave.accentB) end

local T = {
	bg = C(ThemeSave.bgR, ThemeSave.bgG, ThemeSave.bgB),
	sidebar = C(14,16,26),
	panel = C(18,20,32),
	card = C(ThemeSave.cardR, ThemeSave.cardG, ThemeSave.cardB),
	card2 = C(28,30,48),
	row = C(26,28,44),
	text = C(240,242,255),
	dim = C(150,155,180),
	ghost = C(100,105,130),
	blue = accent(),
	blue2 = C(math.max(0,ThemeSave.accentR-15), math.max(0,ThemeSave.accentG-20), ThemeSave.accentB),
	green = C(30,215,96),
	ok = C(70,220,150),
	bad = C(255,90,110),
	warn = C(255,200,80),
	gold = C(255,210,90),
	line = C(40,45,70),
	on = accent(),
	off = C(50,55,75),
}

local function cr(p,r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or ThemeSave.cornerRadius or 10)
	c.Parent = p
end
local function stroke(p,col,th,tr)
	local s = Instance.new("UIStroke")
	s.Color = col or T.line
	s.Thickness = th or ThemeSave.strokeThick or 1
	s.Transparency = tr or 0.4
	s.Parent = p
end
local function pad(p,t,l,r,b)
	local x = Instance.new("UIPadding")
	x.PaddingTop = UDim.new(0,t or 0)
	x.PaddingLeft = UDim.new(0,l or 0)
	x.PaddingRight = UDim.new(0,r or 0)
	x.PaddingBottom = UDim.new(0,b or 0)
	x.Parent = p
end

local function setImage(img, srcUrl)
	if not img or not srcUrl or srcUrl == "" then return end
	task.spawn(function()
		local function tryOne(u)
			if not u or u == "" then return false end
			if string.find(u, "rbxassetid://") or string.find(u, "rbxthumb://") then
				img.Image = u return true
			end
			if string.match(u, "^%d+$") then
				img.Image = "rbxassetid://"..u return true
			end
			if string.find(u, "http") then
				if writefile and getcustomasset then
					local ext = (string.find(u, "%.png") and ".png") or ".jpg"
					local name = "meme_hub_"..tostring(math.floor(tick()*10000))..ext
					local ok, data = pcall(function() return game:HttpGet(u) end)
					if ok and type(data)=="string" and #data > 200 then
						local head = data:sub(1,20)
						if not string.find(head, "<!DOCTYPE") and not string.find(head, "<html") then
							pcall(function() writefile(name, data) end)
							local ok2, asset = pcall(function() return getcustomasset(name) end)
							if ok2 and asset then img.Image = asset return true end
						end
					end
				end
				pcall(function() img.Image = u end)
				return true
			end
			pcall(function() img.Image = u end)
			return true
		end
		tryOne(srcUrl)
	end)
end

local Combat = loadJSON("Combat", {
	autoParry = false,
	autoSpam = false,
	manualSpam = false,
	triggerBot = false,
	parryMethod = "Remote",
	curveMode = "Camera",
	spamRPS = 18,
	parryDistance = 100,
	accuracy = 75,
	pingComp = true,
	animFix = true,
	visualiser = false,
	ballStats = true,
	abilityESP = false,
	hitSounds = true,
	hitSoundId = "6607336718",
	antiAFK = false,
	infJump = false,
	walkBoost = false,
	walkSpeed = 22,
	jumpPower = 50,
	fullbright = false,
	headless = false,
	korblox = false,
	noFog = false,
	antiLag = false,
	otherFXOnly = false,
	noRender = false,
	immortality = false,
})

local function saveCombat()
	saveJSON("Combat", Combat)
end

local function getChar()
	return LP.Character
end
local function getHRP()
	local c = getChar()
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
	local c = getChar()
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function getPing()
	local ms = 60
	pcall(function()
		ms = math.floor((LP:GetNetworkPing() or 0)*1000)
	end)
	return ms
end

local function getBall()
	local balls = workspace:FindFirstChild("Balls")
	if not balls then return nil end
	for _, b in ipairs(balls:GetChildren()) do
		if b:IsA("BasePart") and (b:GetAttribute("realBall") or b.Name == "Ball" or b.Name == "CartoonBall") then
			return b
		end
		if b:IsA("Model") then
			local p = b.PrimaryPart or b:FindFirstChildWhichIsA("BasePart")
			if p then return p end
		end
	end
	for _, b in ipairs(balls:GetChildren()) do
		if b:IsA("BasePart") then return b end
	end
	return nil
end

local function getBallSpeed(ball)
	if not ball then return 0 end
	local v = ball.AssemblyLinearVelocity or ball.Velocity
	if typeof(v) == "Vector3" then return v.Magnitude end
	local z = ball:FindFirstChild("zoomies")
	if z and z:IsA("BodyVelocity") then return z.Velocity.Magnitude end
	if z and z.VectorVelocity then return z.VectorVelocity.Magnitude end
	return 0
end

local function getClosestPlayer()
	local hrp = getHRP()
	if not hrp then return nil end
	local best, dist = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local d = (plr.Character.HumanoidRootPart.Position - hrp.Position).Magnitude
			if d < dist then best, dist = plr, d end
		end
	end
	return best, dist
end

local lastParry = 0
local parryCooldown = 0.08
local spamAcc = 0
local peakBallSpeed = 0

local function getCurveCFrame()
	local hrp = getHRP()
	if not hrp then return CFrame.new() end
	local cam = workspace.CurrentCamera
	local mode = Combat.curveMode or "Camera"
	local dir = cam.CFrame.LookVector

	if mode == "Backwards" then
		dir = -cam.CFrame.LookVector
	elseif mode == "Up" then
		dir = Vector3.new(0,1,0)
	elseif mode == "Down" then
		dir = Vector3.new(0,-1,0)
	elseif mode == "Left" then
		dir = -cam.CFrame.RightVector
	elseif mode == "Right" then
		dir = cam.CFrame.RightVector
	elseif mode == "Random" then
		dir = Vector3.new(math.random()-0.5, math.random()-0.5, math.random()-0.5).Unit
	elseif mode == "Predict" then
		local t = getClosestPlayer()
		if t and t.Character and t.Character:FindFirstChild("HumanoidRootPart") then
			dir = (t.Character.HumanoidRootPart.Position - hrp.Position).Unit
		end
	elseif mode == "Dot" then
		local ball = getBall()
		if ball then
			dir = (hrp.Position - ball.Position).Unit
		end
	elseif mode == "Straight" then
		dir = Vector3.new(0,0,-1)
	end
	return CFrame.new(hrp.Position, hrp.Position + dir)
end

local function fireParry()
	local now = tick()
	if now - lastParry < parryCooldown then return end
	lastParry = now

	local method = Combat.parryMethod or "Remote"

	if method == "VIM" or method == "Legit" then
		pcall(function()
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
			task.wait(0.02)
			VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
		end)
		return
	end

	pcall(function()
		local rem = Rep:FindFirstChild("Remotes")
		if not rem then return end
		local candidates = {"Parry","ParrySuccess","UseAbility","Slash","Block"}
		for _, name in ipairs(candidates) do
			local r = rem:FindFirstChild(name)
			if r and r:IsA("RemoteEvent") then
				pcall(function()
					r:FireServer(getCurveCFrame())
				end)
			end
		end
		local packages = Rep:FindFirstChild("Packages")
		if packages then
			local idx = packages:FindFirstChild("_Index")
			if idx then
				for _, child in ipairs(idx:GetChildren()) do
					if string.find(child.Name, "sleitnick_net") then
						local net = child:FindFirstChild("net")
						if net then
							for _, r in ipairs(net:GetChildren()) do
								if r:IsA("RemoteEvent") and (string.find(r.Name:lower(),"parry") or string.find(r.Name:lower(),"slash")) then
									pcall(function() r:FireServer(getCurveCFrame()) end)
								end
							end
						end
					end
				end
			end
		end
	end)
end

local function shouldParry()
	if not Combat.autoParry then return false end
	local ball = getBall()
	local hrp = getHRP()
	if not ball or not hrp then return false end

	local speed = getBallSpeed(ball)
	if speed > peakBallSpeed then peakBallSpeed = speed end

	local dist = (hrp.Position - ball.Position).Magnitude
	local ping = Combat.pingComp and (getPing()/1000) or 0
	local reach = dist / math.max(speed, 1) - ping

	local speedFactor = math.clamp(speed / 120, 0.6, 2.2)
	local threshold = 12 * speedFactor * (Combat.accuracy or 75) / 75

	local toPlayer = (hrp.Position - ball.Position).Unit
	local vel = ball.AssemblyLinearVelocity
	if typeof(vel) ~= "Vector3" or vel.Magnitude < 1 then return false end
	local dot = toPlayer:Dot(vel.Unit)

	if dot < -0.15 then return false end
	if dist <= threshold * 8 or reach <= 0.22 then
		return true
	end
	return false
end

RS.Heartbeat:Connect(function(dt)
	if Combat.autoParry and shouldParry() then
		fireParry()
	end

	if Combat.triggerBot then
		local ball = getBall()
		local hrp = getHRP()
		if ball and hrp then
			local dist = (hrp.Position - ball.Position).Magnitude
			if dist < 18 then fireParry() end
		end
	end

	if Combat.autoSpam or Combat.manualSpam then
		local target = Combat.spamRPS or 18
		spamAcc = spamAcc + dt
		local packets = math.floor(spamAcc * target)
		if packets > 0 then
			spamAcc = spamAcc - (packets / target)
			for _ = 1, math.min(packets, 8) do
				fireParry()
			end
		end
	else
		spamAcc = 0
	end
end)

local hitSnd = Instance.new("Sound")
hitSnd.Name = "MemeHubHit"
hitSnd.Volume = 4
hitSnd.Parent = SoundService

pcall(function()
	local rem = Rep:FindFirstChild("Remotes")
	local r = rem and rem:FindFirstChild("ParrySuccess")
	if r then
		r.OnClientEvent:Connect(function()
			if Combat.hitSounds then
				hitSnd.SoundId = "rbxassetid://"..tostring(Combat.hitSoundId or "6607336718")
				hitSnd.TimePosition = 0
				hitSnd:Play()
			end
			if Combat.animFix then
				local hum = getHum()
				if hum and hum:FindFirstChildOfClass("Animator") then
					for _, track in pairs(hum.Animator:GetPlayingAnimationTracks()) do
						if track.Name == "GrabParry" or track.Name == "Grab" then
							pcall(function() track:Stop(0.05) end)
						end
					end
				end
			end
		end)
	end
end)

local visParts = {}
local function clearVisualiser()
	for _, p in ipairs(visParts) do pcall(function() p:Destroy() end) end
	visParts = {}
end

local function setVisualiser(on)
	Combat.visualiser = on
	saveCombat()
	clearVisualiser()
	if not on then return end
	local model = Instance.new("Model")
	model.Name = "MemeVisualiser"
	model.Parent = workspace
	table.insert(visParts, model)
	local edges = {}
	for i = 1, 64 do
		local e = Instance.new("Part")
		e.Anchored = true
		e.CanCollide = false
		e.CastShadow = false
		e.Material = Enum.Material.Neon
		e.Color = accent()
		e.Size = Vector3.new(0.08, 0.08, 0.2)
		e.Parent = model
		edges[i] = e
	end
	task.spawn(function()
		while Combat.visualiser do
			local hrp = getHRP()
			local speed = getBallSpeed(getBall())
			local radius = math.clamp(speed / 6.5, 6, 40)
			if hrp then
				for i, e in ipairs(edges) do
					local ang = (i-1) * (2*math.pi/#edges)
					e.CFrame = hrp.CFrame * CFrame.new(math.cos(ang)*radius, -2.5, math.sin(ang)*radius) * CFrame.Angles(0, ang+math.pi/2, 0)
					e.Color = accent()
				end
			end
			task.wait(0.03)
		end
		clearVisualiser()
	end)
end

local abilityConns = {}
local function clearAbilityESP()
	for _, c in ipairs(abilityConns) do pcall(function() if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end) end
	abilityConns = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local ch = plr.Character
		if ch then
			local h = ch:FindFirstChild("MemeAbilityESP")
			if h then h:Destroy() end
		end
	end
end

local function setAbilityESP(on)
	Combat.abilityESP = on
	saveCombat()
	clearAbilityESP()
	if not on then return end
	local function tag(plr)
		if plr == LP then return end
		local ch = plr.Character
		if not ch then return end
		local hrp = ch:FindFirstChild("HumanoidRootPart")
		if not hrp or ch:FindFirstChild("MemeAbilityESP") then return end
		local bb = Instance.new("BillboardGui")
		bb.Name = "MemeAbilityESP"
		bb.Size = UDim2.new(0,140,0,28)
		bb.StudsOffset = Vector3.new(0,3.4,0)
		bb.AlwaysOnTop = true
		bb.Adornee = hrp
		bb.Parent = ch
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1,0,1,0)
		t.BackgroundTransparency = 0.35
		t.BackgroundColor3 = Color3.fromRGB(15,15,30)
		t.TextColor3 = Color3.fromRGB(180,220,255)
		t.Font = Enum.Font.GothamBold
		t.TextSize = 11
		t.Text = plr.DisplayName
		t.Parent = bb
		cr(t,6)
		local ab = plr:GetAttribute("EquippedAbility")
		if ab then t.Text = plr.DisplayName.." ["..tostring(ab).."]" end
	end
	for _, plr in ipairs(Players:GetPlayers()) do tag(plr) end
	table.insert(abilityConns, Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function() if Combat.abilityESP then task.wait(0.4) tag(plr) end end)
	end))
	for _, plr in ipairs(Players:GetPlayers()) do
		table.insert(abilityConns, plr.CharacterAdded:Connect(function() if Combat.abilityESP then task.wait(0.4) tag(plr) end end))
	end
end

local trailConn
local function setBallTrail(on)
	if trailConn then pcall(function() trailConn:Disconnect() end) trailConn = nil end
	if not on then return end
	trailConn = RS.Heartbeat:Connect(function()
		local ball = getBall()
		if not ball then return end
		if not ball:FindFirstChild("MemeTrail") then
			local a0 = Instance.new("Attachment") a0.Name="MemeTrail" a0.Parent=ball
			local a1 = Instance.new("Attachment") a1.Name="MemeTrail2" a1.Position=Vector3.new(0,0,0.4) a1.Parent=ball
			local tr = Instance.new("Trail")
			tr.Attachment0=a0 tr.Attachment1=a1
			tr.LifetimeTime=0.3 tr.FaceCamera=true
			tr.Color = ColorSequence.new(accent())
			tr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0.2), NumberSequenceKeypoint.new(1,1)})
			tr.WidthScale = NumberSequence.new(1,0)
			tr.Parent = ball
		end
	end)
end

local function setAntiLag(on)
	Combat.antiLag = on
	saveCombat()
	if not on then return end
	pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
	pcall(function()
		Lighting.GlobalShadows = false
		Lighting.FogEnd = 9e9
		for _, fx in ipairs(Lighting:GetChildren()) do
			if fx:IsA("BloomEffect") or fx:IsA("BlurEffect") or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
				fx.Enabled = false
			end
		end
	end)
end

local function setNoRender(on)
	Combat.noRender = on
	saveCombat()
	pcall(function()
		local ps = LP:FindFirstChild("PlayerScripts")
		local es = ps and ps:FindFirstChild("EffectScripts")
		local fx = es and es:FindFirstChild("ClientFX")
		if fx then fx.Disabled = on end
	end)
end

local function setNoFog(on)
	Combat.noFog = on
	saveCombat()
	pcall(function()
		if on then
			Lighting.FogEnd = 1e6
			Lighting.FogStart = 1e6
			if Lighting:FindFirstChildOfClass("Atmosphere") then
				Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
			end
		else
			Lighting.FogEnd = 100000
		end
	end)
end

local function setFullbright(on)
	Combat.fullbright = on
	saveCombat()
	if on then
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
	end
end

local function setHeadless(on)
	Combat.headless = on
	saveCombat()
	local h = getChar() and getChar():FindFirstChild("Head")
	if not h then return end
	h.Transparency = on and 1 or 0
	for _, d in ipairs(h:GetDescendants()) do
		if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = on and 1 or 0 end
	end
end

local function setKorblox(on)
	Combat.korblox = on
	saveCombat()
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
	Combat.antiAFK = on
	saveCombat()
end

task.spawn(function()
	while true do
		if Combat.antiAFK then
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new())
			end)
		end
		task.wait(45)
	end
end)

local function setInfJump(on)
	Combat.infJump = on
	saveCombat()
end

UIS.JumpRequest:Connect(function()
	if not Combat.infJump then return end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

local function setWalkBoost(on)
	Combat.walkBoost = on
	saveCombat()
	local hum = getHum()
	if not hum then return end
	if on then
		hum.WalkSpeed = Combat.walkSpeed or 22
	else
		hum.WalkSpeed = 16
	end
end

LP.CharacterAdded:Connect(function()
	task.wait(0.8)
	if Combat.headless then setHeadless(true) end
	if Combat.korblox then setKorblox(true) end
	if Combat.walkBoost then setWalkBoost(true) end
	if Combat.fullbright then setFullbright(true) end
end)

local player = Instance.new("Sound")
player.Name = "MemeHubMusic"
player.Volume = 1.2
player.Parent = SoundService

local Catalog = {
	{id="g1", title="Lo-fi Chill", artist="APM", asset="rbxassetid://9043887091", tag="lofi"},
	{id="g2", title="Sunset Chill", artist="Queens Road", asset="rbxassetid://9046862941", tag="chill"},
	{id="g3", title="Smooth Jazz", artist="John Graham", asset="rbxassetid://1845341094", tag="jazz"},
	{id="g4", title="Claire De Lune", artist="Debussy", asset="rbxassetid://1838457617", tag="classic"},
	{id="g5", title="TOMA FUNK PHONK", artist="Symphonk", asset="rbxassetid://129098116998483", tag="phonk"},
	{id="g6", title="Neon Night", artist="APM", asset="rbxassetid://1839027540", tag="synth"},
	{id="g7", title="Raining Tacos", artist="Parry Gripp", asset="rbxassetid://142376088", tag="fun"},
	{id="g8", title="Study Session", artist="APM", asset="rbxassetid://9045766365", tag="lofi"},
}
local state = {playing=false, current=Catalog[1], index=1}
local function playTrack(t)
	if not t then return end
	state.current = t
	player.SoundId = t.asset
	player.TimePosition = 0
	pcall(function() player:Play() end)
	state.playing = true
end
player.Ended:Connect(function()
	state.index = state.index % #Catalog + 1
	playTrack(Catalog[state.index])
end)

local SwordMap = {
	bok="Black Oni Katana", cs="Chroma Seal", chroma="Chroma Seal", db="Dark Blade",
	sb="Serpentbane", bhk="Blackhole Katana", rmk="Red Moon Katana", fw="Frostwall",
}
local function resolveSword(name)
	name = tostring(name or ""):gsub("^%s+",""):gsub("%s+$","")
	local lower = string.lower(name)
	return SwordMap[lower] or name
end

local function equipSword(name)
	local resolved = resolveSword(name)
	if resolved == "" then return false, "empty" end
	local char = getChar()
	if not char then return false, "no char" end
	pcall(function()
		getgenv().skinChanger = true
		getgenv().swordModel = resolved
		getgenv().swordAnimations = resolved
		getgenv().swordFX = resolved
		if type(getgenv().updateSword) == "function" then
			getgenv().updateSword()
		end
		local rem = Rep:FindFirstChild("Remotes")
		local fire = rem and rem:FindFirstChild("FireSwordInfo")
		if fire then fire:FireServer(resolved) end
	end)
	return true, resolved
end

local Screen = Instance.new("ScreenGui")
Screen.Name = "MemeHub"
Screen.ResetOnSpawn = false
Screen.IgnoreGuiInset = true
Screen.DisplayOrder = 500
Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Screen.Parent = PG

local sc = Instance.new("UIScale")
sc.Scale = ThemeSave.uiScale or (UIS.TouchEnabled and 0.72 or 0.95)
sc.Parent = Screen

local W, H = ThemeSave.winW or 820, ThemeSave.winH or 560
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,W,0,H)
Main.Position = UDim2.new(0.5,-W/2,0.5,-H/2)
Main.BackgroundColor3 = T.bg
Main.BackgroundTransparency = ThemeSave.guiTrans or 0.18
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = Screen
cr(Main, 14)
stroke(Main, T.blue, 1.2, 0.5)

local Wall = Instance.new("ImageLabel")
Wall.Size = UDim2.new(1,0,1,0)
Wall.BackgroundTransparency = 1
Wall.ImageTransparency = ThemeSave.wallTrans or 0.25
Wall.ScaleType = Enum.ScaleType.Crop
Wall.ZIndex = 0
Wall.Parent = Main
if ThemeSave.wallpaper ~= "" then setImage(Wall, ThemeSave.wallpaper) end

local SIDE = 158
local Side = Instance.new("Frame")
Side.Size = UDim2.new(0,SIDE,1,0)
Side.BackgroundColor3 = T.sidebar
Side.BackgroundTransparency = ThemeSave.sidebarTrans or 0.12
Side.BorderSizePixel = 0
Side.ZIndex = 2
Side.Parent = Main

local brand = Instance.new("Frame")
brand.Size = UDim2.new(1,-10,0,48)
brand.Position = UDim2.new(0,5,0,8)
brand.BackgroundTransparency = 1
brand.Parent = Side

local logo = Instance.new("Frame")
logo.Size = UDim2.new(0,34,0,34)
logo.Position = UDim2.new(0,4,0,6)
logo.BackgroundColor3 = T.blue
logo.BorderSizePixel = 0
logo.Parent = brand
cr(logo,9)
local logoT = Instance.new("TextLabel")
logoT.BackgroundTransparency = 1
logoT.Size = UDim2.new(1,0,1,0)
logoT.Font = Enum.Font.GothamBold
logoT.Text = "M"
logoT.TextColor3 = Color3.new(1,1,1)
logoT.TextSize = 15
logoT.Parent = logo

local brandName = Instance.new("TextLabel")
brandName.BackgroundTransparency = 1
brandName.Position = UDim2.new(0,44,0,6)
brandName.Size = UDim2.new(1,-48,0,16)
brandName.Font = Enum.Font.GothamBold
brandName.Text = "MEME"
brandName.TextColor3 = T.text
brandName.TextSize = 14
brandName.TextXAlignment = Enum.TextXAlignment.Left
brandName.Parent = brand

local brandSub = Instance.new("TextLabel")
brandSub.BackgroundTransparency = 1
brandSub.Position = UDim2.new(0,44,0,24)
brandSub.Size = UDim2.new(1,-48,0,14)
brandSub.Font = Enum.Font.Gotham
brandSub.Text = "HUB · v"..VERSION
brandSub.TextColor3 = T.ghost
brandSub.TextSize = 10
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = brand

local sideScroll = Instance.new("ScrollingFrame")
sideScroll.Size = UDim2.new(1,-4,1,-110)
sideScroll.Position = UDim2.new(0,2,0,60)
sideScroll.BackgroundTransparency = 1
sideScroll.BorderSizePixel = 0
sideScroll.ScrollBarThickness = 4
sideScroll.CanvasSize = UDim2.new(0,0,0,0)
sideScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
sideScroll.Parent = Side
local sideLay = Instance.new("UIListLayout")
sideLay.Padding = UDim.new(0,3)
sideLay.Parent = sideScroll
pad(sideScroll,2,4,4,6)

local function sideSection(txt)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,0,15)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.Text = "  "..txt
	l.TextColor3 = T.ghost
	l.TextSize = 9
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = sideScroll
end

local tabBtns, pages, currentTab = {}, {}, "Home"
local ui = {}

local function makeNav(id, icon, label)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,32)
	b.BackgroundTransparency = 1
	b.Text = ""
	b.AutoButtonColor = false
	b.Parent = sideScroll
	cr(b,8)
	local acc = Instance.new("Frame")
	acc.Size = UDim2.new(0,3,0,16)
	acc.Position = UDim2.new(0,2,0.5,-8)
	acc.BackgroundColor3 = T.blue
	acc.BorderSizePixel = 0
	acc.Visible = false
	acc.Parent = b
	cr(acc,2)
	local ic = Instance.new("TextLabel")
	ic.BackgroundTransparency = 1
	ic.Position = UDim2.new(0,12,0,0)
	ic.Size = UDim2.new(0,20,1,0)
	ic.Font = Enum.Font.GothamBold
	ic.Text = icon
	ic.TextColor3 = T.dim
	ic.TextSize = 12
	ic.Parent = b
	local lb = Instance.new("TextLabel")
	lb.BackgroundTransparency = 1
	lb.Position = UDim2.new(0,34,0,0)
	lb.Size = UDim2.new(1,-38,1,0)
	lb.Font = Enum.Font.Gotham
	lb.Text = label
	lb.TextColor3 = T.dim
	lb.TextSize = 12
	lb.TextXAlignment = Enum.TextXAlignment.Left
	lb.Parent = b
	tabBtns[id] = {btn=b, acc=acc, ic=ic, lb=lb}
	b.MouseButton1Click:Connect(function() if ui.switch then ui.switch(id) end end)
end

sideSection("MAIN")
makeNav("Home","H","Home")
makeNav("Music","M","Music")
sideSection("COMBAT")
makeNav("Combat","C","Combat")
makeNav("Swords","S","Swords")
sideSection("VISUAL")
makeNav("Visuals","V","Visuals")
makeNav("Player","P","Player")
sideSection("SYSTEM")
makeNav("Config","G","Personalizar")

local sideBot = Instance.new("Frame")
sideBot.Size = UDim2.new(1,-10,0,34)
sideBot.Position = UDim2.new(0,5,1,-42)
sideBot.BackgroundTransparency = 1
sideBot.Parent = Side

local locked = false
local LockBtn = Instance.new("TextButton")
LockBtn.Size = UDim2.new(0.48,0,1,0)
LockBtn.BackgroundColor3 = T.card2
LockBtn.Text = "Lock"
LockBtn.TextColor3 = T.dim
LockBtn.Font = Enum.Font.GothamBold
LockBtn.TextSize = 11
LockBtn.Parent = sideBot
cr(LockBtn,8)
LockBtn.MouseButton1Click:Connect(function()
	locked = not locked
	LockBtn.Text = locked and "Locked" or "Lock"
	LockBtn.BackgroundColor3 = locked and T.blue or T.card2
end)

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0.48,0,1,0)
Close.Position = UDim2.new(0.52,0,0,0)
Close.BackgroundColor3 = Color3.fromRGB(80,35,45)
Close.Text = "Close"
Close.TextColor3 = T.text
Close.Font = Enum.Font.GothamBold
Close.TextSize = 11
Close.Parent = sideBot
cr(Close,8)
Close.MouseButton1Click:Connect(function() Screen:Destroy() end)

local Right = Instance.new("Frame")
Right.Size = UDim2.new(1,-SIDE,1,0)
Right.Position = UDim2.new(0,SIDE,0,0)
Right.BackgroundTransparency = 1
Right.ZIndex = 2
Right.Parent = Main

local TOP_H, PLAY_H = 54, 50
local Top = Instance.new("Frame")
Top.Size = UDim2.new(1,0,0,TOP_H)
Top.BackgroundColor3 = T.panel
Top.BackgroundTransparency = ThemeSave.topTrans or 0.25
Top.BorderSizePixel = 0
Top.Parent = Right

local topTitle = Instance.new("TextLabel")
topTitle.BackgroundTransparency = 1
topTitle.Position = UDim2.new(0,14,0,6)
topTitle.Size = UDim2.new(0.5,0,0,18)
topTitle.Font = Enum.Font.GothamBold
topTitle.Text = "Home"
topTitle.TextColor3 = T.text
topTitle.TextSize = 15
topTitle.TextXAlignment = Enum.TextXAlignment.Left
topTitle.Parent = Top

local verBadge = Instance.new("TextLabel")
verBadge.Size = UDim2.new(0,70,0,16)
verBadge.Position = UDim2.new(0,14,0,28)
verBadge.BackgroundColor3 = Color3.fromRGB(30,50,90)
verBadge.Text = "v"..VERSION
verBadge.TextColor3 = T.blue
verBadge.Font = Enum.Font.GothamBold
verBadge.TextSize = 10
verBadge.Parent = Top
cr(verBadge,6)

local statusLbl = Instance.new("TextLabel")
statusLbl.BackgroundTransparency = 1
statusLbl.Position = UDim2.new(0,90,0,28)
statusLbl.Size = UDim2.new(0.5,0,0,14)
statusLbl.Font = Enum.Font.Gotham
statusLbl.Text = "ready"
statusLbl.TextColor3 = T.dim
statusLbl.TextSize = 11
statusLbl.TextXAlignment = Enum.TextXAlignment.Left
statusLbl.Parent = Top
ui.statusLbl = statusLbl

local Content = Instance.new("Frame")
Content.Size = UDim2.new(1,-12,1,-(TOP_H+PLAY_H+8))
Content.Position = UDim2.new(0,6,0,TOP_H)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Right

local GHOST_H = 200
local function forceCanvas(scroll, lay)
	if not scroll or not scroll.Parent then return end
	local y = 0
	pcall(function() y = lay.AbsoluteContentSize.Y end)
	y = y + GHOST_H
	local view = scroll.AbsoluteSize.Y
	if view > 0 and y < view + 60 then y = view + GHOST_H end
	scroll.CanvasSize = UDim2.new(0,0,0,y)
end

local function makePage(id)
	local page = Instance.new("Frame")
	page.Name = id
	page.Size = UDim2.new(1,0,1,0)
	page.BackgroundTransparency = 1
	page.Visible = false
	page.Parent = Content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "Scroll"
	scroll.Size = UDim2.new(1,0,1,0)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 10
	scroll.ScrollBarImageColor3 = T.blue
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.CanvasSize = UDim2.new(0,0,0,1200)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroll.Parent = page
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0,8)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = scroll
	pad(scroll, 8, 6, 12, 0)
	local function force() forceCanvas(scroll, lay) end
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(force)
	task.defer(force)
	pages[id] = {page=page, scroll=scroll, lay=lay, force=force}
	return scroll
end

for _, id in ipairs({"Home","Music","Combat","Swords","Visuals","Player","Config"}) do
	makePage(id)
end

ui.switch = function(id)
	currentTab = id
	for n, info in pairs(pages) do
		info.page.Visible = (n == id)
		if n == id and info.force then task.defer(info.force) end
	end
	for n, t in pairs(tabBtns) do
		local on = (n == id)
		t.acc.Visible = on
		t.btn.BackgroundTransparency = on and 0 or 1
		t.btn.BackgroundColor3 = on and Color3.fromRGB(25,35,60) or T.sidebar
		t.ic.TextColor3 = on and T.blue or T.dim
		t.lb.TextColor3 = on and T.text or T.dim
		t.lb.Font = on and Enum.Font.GothamBold or Enum.Font.Gotham
	end
	local titles = {Home="Home", Music="Music", Combat="Combat", Swords="Swords", Visuals="Visuals", Player="Player", Config="Personalizar"}
	topTitle.Text = titles[id] or id
end

local dragging, d0, p0 = false, nil, nil
Top.InputBegan:Connect(function(i)
	if locked then return end
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		d0 = i.Position
		p0 = Main.Position
		i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
	end
end)
UIS.InputChanged:Connect(function(i)
	if not dragging or locked then return end
	if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
		local d = i.Position - d0
		Main.Position = UDim2.new(p0.X.Scale, p0.X.Offset+d.X, p0.Y.Scale, p0.Y.Offset+d.Y)
	end
end)

local function pageHeader(parent, title, desc)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,40)
	f.BackgroundTransparency = 1
	f.Parent = parent
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1,0,0,18)
	t.Font = Enum.Font.GothamBold
	t.Text = title
	t.TextColor3 = T.text
	t.TextSize = 16
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = f
	local d = Instance.new("TextLabel")
	d.BackgroundTransparency = 1
	d.Position = UDim2.new(0,0,0,20)
	d.Size = UDim2.new(1,0,0,16)
	d.Font = Enum.Font.Gotham
	d.Text = desc
	d.TextColor3 = T.dim
	d.TextSize = 11
	d.TextXAlignment = Enum.TextXAlignment.Left
	d.Parent = f
end

local function card(parent, title)
	local root = Instance.new("Frame")
	root.Size = UDim2.new(1,0,0,0)
	root.AutomaticSize = Enum.AutomaticSize.Y
	root.BackgroundColor3 = T.card
	root.BackgroundTransparency = ThemeSave.cardTrans or 0.28
	root.BorderSizePixel = 0
	root.Parent = parent
	cr(root,12)
	stroke(root, T.line, 1, 0.4)
	local head = Instance.new("TextLabel")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1,-16,0,28)
	head.Position = UDim2.new(0,12,0,6)
	head.Font = Enum.Font.GothamBold
	head.Text = title
	head.TextColor3 = T.text
	head.TextSize = 13
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.Parent = root
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Size = UDim2.new(1,-16,0,0)
	body.Position = UDim2.new(0,8,0,34)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.BackgroundTransparency = 1
	body.Parent = root
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0,6)
	lay.Parent = body
	pad(body,0,4,4,10)
	return body
end

local function addToggle(parent, title, desc, default, cb)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,44)
	f.BackgroundColor3 = T.card2
	f.BorderSizePixel = 0
	f.Parent = parent
	cr(f,8)
	local a = Instance.new("TextLabel")
	a.BackgroundTransparency = 1
	a.Position = UDim2.new(0,10,0,5)
	a.Size = UDim2.new(1,-60,0,14)
	a.Font = Enum.Font.GothamBold
	a.Text = title
	a.TextColor3 = T.text
	a.TextSize = 12
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = f
	local b = Instance.new("TextLabel")
	b.BackgroundTransparency = 1
	b.Position = UDim2.new(0,10,0,22)
	b.Size = UDim2.new(1,-60,0,14)
	b.Font = Enum.Font.Gotham
	b.Text = desc or ""
	b.TextColor3 = T.ghost
	b.TextSize = 10
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = f
	local st = default and true or false
	local sw = Instance.new("TextButton")
	sw.Size = UDim2.new(0,40,0,20)
	sw.Position = UDim2.new(1,-50,0.5,-10)
	sw.BackgroundColor3 = st and T.on or T.off
	sw.Text = ""
	sw.Parent = f
	cr(sw,10)
	local kn = Instance.new("Frame")
	kn.Size = UDim2.new(0,14,0,14)
	kn.Position = st and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
	kn.BackgroundColor3 = Color3.new(1,1,1)
	kn.BorderSizePixel = 0
	kn.Parent = sw
	cr(kn,7)
	sw.MouseButton1Click:Connect(function()
		st = not st
		sw.BackgroundColor3 = st and T.on or T.off
		kn.Position = st and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
		pcall(cb, st)
	end)
end

local function addBtn(parent, title, desc, btxt, col, cb)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,44)
	f.BackgroundColor3 = T.card2
	f.BorderSizePixel = 0
	f.Parent = parent
	cr(f,8)
	local a = Instance.new("TextLabel")
	a.BackgroundTransparency = 1
	a.Position = UDim2.new(0,10,0,5)
	a.Size = UDim2.new(1,-100,0,14)
	a.Font = Enum.Font.GothamBold
	a.Text = title
	a.TextColor3 = T.text
	a.TextSize = 12
	a.TextXAlignment = Enum.TextXAlignment.Left
	a.Parent = f
	local b = Instance.new("TextLabel")
	b.BackgroundTransparency = 1
	b.Position = UDim2.new(0,10,0,22)
	b.Size = UDim2.new(1,-100,0,14)
	b.Font = Enum.Font.Gotham
	b.Text = desc or ""
	b.TextColor3 = T.ghost
	b.TextSize = 10
	b.TextXAlignment = Enum.TextXAlignment.Left
	b.Parent = f
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0,84,0,26)
	btn.Position = UDim2.new(1,-94,0.5,-13)
	btn.BackgroundColor3 = col or T.blue
	btn.Text = btxt or "Run"
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 11
	btn.Parent = f
	cr(btn,8)
	btn.MouseButton1Click:Connect(function() pcall(cb, btn) end)
	return btn
end

local function addBox(parent, ph)
	local tb = Instance.new("TextBox")
	tb.Size = UDim2.new(1,0,0,28)
	tb.BackgroundColor3 = T.bg
	tb.PlaceholderText = ph or ""
	tb.Text = ""
	tb.TextColor3 = T.text
	tb.PlaceholderColor3 = T.ghost
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 12
	tb.ClearTextOnFocus = false
	tb.Parent = parent
	cr(tb,8)
	return tb
end

local function addLabel(parent, text, col)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,0,0,16)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.Text = text
	l.TextColor3 = col or T.dim
	l.TextSize = 11
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = parent
	return l
end

do
	local p = pages.Home.scroll
	pageHeader(p, "Meme Hub v62", "Combat + Visuals + Personalizar")
	local c = card(p, "Status")
	local pingL = addLabel(c, "Ping: --", T.ok)
	local ballL = addLabel(c, "Ball speed: -- | Peak: --", T.dim)
	local parryL = addLabel(c, "Auto Parry: OFF", T.ghost)
	task.spawn(function()
		while p.Parent do
			pingL.Text = "Ping: "..getPing().." ms"
			local sp = getBallSpeed(getBall())
			if sp > peakBallSpeed then peakBallSpeed = sp end
			ballL.Text = string.format("Ball: %.0f | Peak: %.0f", sp, peakBallSpeed)
			parryL.Text = "Auto Parry: "..(Combat.autoParry and "ON" or "OFF")
			parryL.TextColor3 = Combat.autoParry and T.ok or T.ghost
			task.wait(0.4)
		end
	end)
	local s = card(p, "Atalhos")
	addBtn(s, "Combat", "parry / spam / curve", "Abrir", T.blue, function() ui.switch("Combat") end)
	addBtn(s, "Visuals", "ESP / trail / visualiser", "Abrir", T.blue2, function() ui.switch("Visuals") end)
	addBtn(s, "Personalizar", "cores / wallpaper / scale", "Abrir", T.card2, function() ui.switch("Config") end)
end

do
	local p = pages.Combat.scroll
	pageHeader(p, "Combat", "Auto Parry · Spam · Curve · Trigger")
	local c = card(p, "Parry")
	addToggle(c, "Auto Parry", "parry automatico por distancia/velocidade", Combat.autoParry, function(v)
		Combat.autoParry = v saveCombat()
		ui.statusLbl.Text = v and "Auto Parry ON" or "Auto Parry OFF"
		ui.statusLbl.TextColor3 = v and T.ok or T.dim
	end)
	addToggle(c, "Trigger Bot", "parry quando bola muito perto", Combat.triggerBot, function(v)
		Combat.triggerBot = v saveCombat()
	end)
	addToggle(c, "Ping Compensation", "ajusta timing pelo ping", Combat.pingComp, function(v)
		Combat.pingComp = v saveCombat()
	end)
	addToggle(c, "Animation Fix", "para animacao de grab no hit", Combat.animFix, function(v)
		Combat.animFix = v saveCombat()
	end)
	addLabel(c, "Parry Method", T.dim)
	for _, m in ipairs({"Remote","VIM","Legit"}) do
		addBtn(c, "Method: "..m, "", "Set", m==Combat.parryMethod and T.blue or T.card2, function()
			Combat.parryMethod = m saveCombat()
			ui.statusLbl.Text = "Method: "..m
		end)
	end
	local distBox = addBox(c, "Parry Distance (50-150) atual: "..tostring(Combat.parryDistance))
	addBtn(c, "Aplicar Distance", "", "Set", T.blue, function()
		local n = math.clamp(tonumber(distBox.Text) or Combat.parryDistance, 30, 200)
		Combat.parryDistance = n saveCombat()
		ui.statusLbl.Text = "Distance: "..n
	end)
	local accBox = addBox(c, "Accuracy (40-100) atual: "..tostring(Combat.accuracy))
	addBtn(c, "Aplicar Accuracy", "", "Set", T.blue, function()
		local n = math.clamp(tonumber(accBox.Text) or Combat.accuracy, 40, 100)
		Combat.accuracy = n saveCombat()
	end)

	local sp = card(p, "Spam")
	addToggle(sp, "Auto Spam", "spam quando ativado", Combat.autoSpam, function(v)
		Combat.autoSpam = v saveCombat()
	end)
	addToggle(sp, "Manual Spam", "spam continuo (keybind RightCtrl)", Combat.manualSpam, function(v)
		Combat.manualSpam = v saveCombat()
	end)
	local rpsBox = addBox(sp, "RPS (8-40) atual: "..tostring(Combat.spamRPS))
	addBtn(sp, "Aplicar RPS", "", "Set", T.blue, function()
		local n = math.clamp(tonumber(rpsBox.Text) or Combat.spamRPS, 5, 45)
		Combat.spamRPS = n saveCombat()
		ui.statusLbl.Text = "RPS: "..n
	end)

	local cu = card(p, "Curve Mode")
	addLabel(cu, "Direcao do parry (curve)", T.dim)
	for _, m in ipairs({"Camera","Backwards","Dot","Straight","Predict","Random","Up","Left","Right"}) do
		addBtn(cu, m, "", "Set", m==Combat.curveMode and T.blue or T.card2, function()
			Combat.curveMode = m saveCombat()
			ui.statusLbl.Text = "Curve: "..m
		end)
	end
end

UIS.InputBegan:Connect(function(i, g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.RightControl then
		Combat.manualSpam = not Combat.manualSpam
		saveCombat()
		ui.statusLbl.Text = "Manual Spam: "..(Combat.manualSpam and "ON" or "OFF")
		ui.statusLbl.TextColor3 = Combat.manualSpam and T.ok or T.dim
	end
	if i.KeyCode == Enum.KeyCode.RightShift then
		Main.Visible = not Main.Visible
	end
end)

do
	local p = pages.Swords.scroll
	pageHeader(p, "Swords", "equip rapido")
	local c = card(p, "Equip")
	local box = addBox(c, "bok / chroma / dark blade / nome")
	addBtn(c, "Equip Sword", "resolve alias e equipa", "EQUIP", T.blue, function(b)
		b.Text = "..."
		task.spawn(function()
			local ok, msg = equipSword(box.Text)
			ui.statusLbl.Text = ok and ("OK "..tostring(msg)) or ("FAIL "..tostring(msg))
			ui.statusLbl.TextColor3 = ok and T.ok or T.bad
			b.Text = "EQUIP"
		end)
	end)
	addLabel(c, "Aliases: bok, cs, db, sb, bhk, rmk, fw", T.ghost)
end

do
	local p = pages.Visuals.scroll
	pageHeader(p, "Visuals", "ESP · trail · visualiser · performance")
	local c = card(p, "Combat Visuals")
	addToggle(c, "Visualiser", "circulo de range na bola", Combat.visualiser, function(v) setVisualiser(v) end)
	addToggle(c, "Ability ESP", "nome + ability nos players", Combat.abilityESP, function(v) setAbilityESP(v) end)
	addToggle(c, "Ball Trail", "rastro na bola", false, function(v) setBallTrail(v) end)
	addToggle(c, "Hit Sounds", "som no parry", Combat.hitSounds, function(v) Combat.hitSounds = v saveCombat() end)
	addToggle(c, "Ball Stats (Home)", "mostra speed/peak no Home", Combat.ballStats, function(v) Combat.ballStats = v saveCombat() end)

	local perf = card(p, "Performance")
	addToggle(perf, "Anti Lag", "qualidade baixa + sem shadows", Combat.antiLag, function(v) setAntiLag(v) end)
	addToggle(perf, "No Render", "desliga ClientFX", Combat.noRender, function(v) setNoRender(v) end)
	addToggle(perf, "No Fog", "remove nevoa", Combat.noFog, function(v) setNoFog(v) end)

	local cos = card(p, "Cosmeticos")
	addToggle(cos, "Fullbright", "", Combat.fullbright, function(v) setFullbright(v) end)
	addToggle(cos, "Headless", "", Combat.headless, function(v) setHeadless(v) end)
	addToggle(cos, "Korblox", "esconde perna direita", Combat.korblox, function(v) setKorblox(v) end)
end

do
	local p = pages.Player.scroll
	pageHeader(p, "Player", "movimento")
	local c = card(p, "Movement")
	addToggle(c, "Walk Boost", "walkspeed custom", Combat.walkBoost, function(v) setWalkBoost(v) end)
	local ws = addBox(c, "WalkSpeed (16-40) atual: "..tostring(Combat.walkSpeed))
	addBtn(c, "Aplicar Walk", "", "Set", T.blue, function()
		local n = math.clamp(tonumber(ws.Text) or 22, 16, 40)
		Combat.walkSpeed = n saveCombat()
		if Combat.walkBoost then setWalkBoost(true) end
	end)
	addToggle(c, "Infinite Jump", "", Combat.infJump, function(v) setInfJump(v) end)
	addToggle(c, "Anti AFK", "nao kick idle", Combat.antiAFK, function(v) setAntiAFK(v) end)
end

do
	local p = pages.Music.scroll
	pageHeader(p, "Music", "BGM rapido")
	local c = card(p, "Player")
	local now = addLabel(c, "-", T.text)
	addBtn(c, "Play / Pause", "", "Play", T.blue, function()
		if state.playing then player:Pause() state.playing=false else playTrack(state.current) end
	end)
	addBtn(c, "Next", "", ">>", T.card2, function()
		state.index = state.index % #Catalog + 1
		playTrack(Catalog[state.index])
		now.Text = Catalog[state.index].title
	end)
	for _, t in ipairs(Catalog) do
		addBtn(c, t.title, t.artist.." · "..t.tag, "Play", T.card2, function()
			playTrack(t)
			now.Text = t.title
		end)
	end
end

do
	local p = pages.Config.scroll
	pageHeader(p, "Personalizar", "cores · wallpaper · escala · janela")
	local pal = card(p, "Accent Color")
	addLabel(pal, "toque numa cor", T.ghost)
	local grid = Instance.new("Frame")
	grid.Size = UDim2.new(1,0,0,0)
	grid.AutomaticSize = Enum.AutomaticSize.Y
	grid.BackgroundTransparency = 1
	grid.Parent = pal
	local gLay = Instance.new("UIGridLayout")
	gLay.CellSize = UDim2.new(0,28,0,28)
	gLay.CellPadding = UDim2.new(0,5,0,5)
	gLay.Parent = grid
	local function applyAccent(col)
		ThemeSave.accentR = math.floor(col.R*255)
		ThemeSave.accentG = math.floor(col.G*255)
		ThemeSave.accentB = math.floor(col.B*255)
		saveJSON("Theme", ThemeSave)
		T.blue = col T.on = col
		pcall(function()
			for _, d in ipairs(Screen:GetDescendants()) do
				if d:IsA("UIStroke") then d.Color = col end
			end
			verBadge.TextColor3 = col
		end)
	end
	local colors = {}
	for i=0,7 do local v=i/7 table.insert(colors, Color3.new(v,v,v)) end
	for hi=0,11 do
		local h = hi/12
		table.insert(colors, Color3.fromHSV(h,1,1))
		table.insert(colors, Color3.fromHSV(h,0.7,0.9))
	end
	for _, col in ipairs({
		Color3.fromRGB(255,90,170), Color3.fromRGB(55,140,255), Color3.fromRGB(30,215,96),
		Color3.fromRGB(255,80,80), Color3.fromRGB(255,200,60), Color3.fromRGB(180,90,255),
		Color3.fromRGB(0,220,255), Color3.fromRGB(255,140,40)
	}) do table.insert(colors, col) end
	for _, col in ipairs(colors) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0,28,0,28)
		b.BackgroundColor3 = col
		b.Text = ""
		b.BorderSizePixel = 0
		b.Parent = grid
		cr(b,6)
		b.MouseButton1Click:Connect(function() applyAccent(col) end)
	end
	gLay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		grid.Size = UDim2.new(1,0,0, gLay.AbsoluteContentSize.Y)
	end)

	local wall = card(p, "Wallpaper")
	local wbox = addBox(wall, ThemeSave.wallpaper)
	addBtn(wall, "Apply Wallpaper", "URL ou rbxassetid", "Apply", T.blue, function()
		ThemeSave.wallpaper = wbox.Text
		saveJSON("Theme", ThemeSave)
		setImage(Wall, ThemeSave.wallpaper)
	end)
	addBtn(wall, "Clear", "", "Clear", T.card2, function()
		ThemeSave.wallpaper = ""
		saveJSON("Theme", ThemeSave)
		Wall.Image = ""
	end)

	local fl = card(p, "Float Button")
	local fbox = addBox(fl, ThemeSave.floatImage)
	addBtn(fl, "Apply Float Image", "", "Apply", T.blue, function()
		ThemeSave.floatImage = fbox.Text
		saveJSON("Theme", ThemeSave)
		if ui.applyFloat then ui.applyFloat() end
	end)
	for _, szv in ipairs({48,56,64,80}) do
		addBtn(fl, "Size "..szv, "", tostring(szv), T.card2, function()
			ThemeSave.floatSize = szv
			saveJSON("Theme", ThemeSave)
			if ui.applyFloat then ui.applyFloat() end
		end)
	end

	local trans = card(p, "Transparencia")
	addBtn(trans, "Gui 0%", "solido", "0%", T.card2, function() ThemeSave.guiTrans=0 Main.BackgroundTransparency=0 saveJSON("Theme",ThemeSave) end)
	addBtn(trans, "Gui 18%", "padrao", "18%", T.blue, function() ThemeSave.guiTrans=0.18 Main.BackgroundTransparency=0.18 saveJSON("Theme",ThemeSave) end)
	addBtn(trans, "Gui 35%", "mais vidro", "35%", T.card2, function() ThemeSave.guiTrans=0.35 Main.BackgroundTransparency=0.35 saveJSON("Theme",ThemeSave) end)
	addBtn(trans, "Wallpaper fraco", "", "70%", T.card2, function() ThemeSave.wallTrans=0.70 Wall.ImageTransparency=0.70 saveJSON("Theme",ThemeSave) end)
	addBtn(trans, "Wallpaper medio", "", "40%", T.blue, function() ThemeSave.wallTrans=0.40 Wall.ImageTransparency=0.40 saveJSON("Theme",ThemeSave) end)
	addBtn(trans, "Wallpaper forte", "", "15%", T.card2, function() ThemeSave.wallTrans=0.15 Wall.ImageTransparency=0.15 saveJSON("Theme",ThemeSave) end)

	local scaleC = card(p, "Escala UI")
	for _, v in ipairs({0.60,0.70,0.80,0.90,0.95,1.00,1.10,1.20}) do
		addBtn(scaleC, string.format("Scale %.2f", v), "", string.format("%.2f",v), math.abs(v-0.95)<0.01 and T.blue or T.card2, function()
			sc.Scale = v
			ThemeSave.uiScale = v
			saveJSON("Theme", ThemeSave)
		end)
	end

	local sizeC = card(p, "Tamanho da janela")
	addBtn(sizeC, "Compact 700x480", "", "Compact", T.card2, function()
		Main.Size=UDim2.new(0,700,0,480) Main.Position=UDim2.new(0.5,-350,0.5,-240)
		ThemeSave.winW,ThemeSave.winH=700,480 saveJSON("Theme",ThemeSave)
	end)
	addBtn(sizeC, "Normal 820x560", "", "Normal", T.blue, function()
		Main.Size=UDim2.new(0,820,0,560) Main.Position=UDim2.new(0.5,-410,0.5,-280)
		ThemeSave.winW,ThemeSave.winH=820,560 saveJSON("Theme",ThemeSave)
	end)
	addBtn(sizeC, "Grande 960x640", "", "Grande", T.card2, function()
		Main.Size=UDim2.new(0,960,0,640) Main.Position=UDim2.new(0.5,-480,0.5,-320)
		ThemeSave.winW,ThemeSave.winH=960,640 saveJSON("Theme",ThemeSave)
	end)

	local preset = card(p, "Presets")
	addBtn(preset, "Glass", "transparente", "Glass", T.blue, function()
		ThemeSave.guiTrans=0.25 ThemeSave.cardTrans=0.30 ThemeSave.wallTrans=0.45
		Main.BackgroundTransparency=0.25 Wall.ImageTransparency=0.45
		saveJSON("Theme", ThemeSave)
	end)
	addBtn(preset, "Solid", "opaco", "Solid", T.card2, function()
		ThemeSave.guiTrans=0 ThemeSave.cardTrans=0 ThemeSave.wallTrans=0.85
		Main.BackgroundTransparency=0 Wall.ImageTransparency=0.85
		saveJSON("Theme", ThemeSave)
	end)
	addBtn(preset, "Neon Blue", "", "Neon", T.card2, function()
		applyAccent(Color3.fromRGB(80,200,255))
		ThemeSave.guiTrans=0.12
		Main.BackgroundTransparency=0.12
		saveJSON("Theme", ThemeSave)
	end)
	addBtn(preset, "Meme Pink", "", "Pink", T.card2, function()
		applyAccent(Color3.fromRGB(255,90,170))
	end)

	local info = card(p, "Build")
	addLabel(info, "MEME HUB · v62 · combat core + personalizar", T.ok)
	addLabel(info, "RightShift = toggle UI · RightCtrl = manual spam", T.ghost)
end

local PlayerBar = Instance.new("Frame")
PlayerBar.Size = UDim2.new(1,-12,0,PLAY_H-6)
PlayerBar.Position = UDim2.new(0,6,1,-(PLAY_H))
PlayerBar.BackgroundColor3 = T.card
PlayerBar.BackgroundTransparency = ThemeSave.cardTrans or 0.28
PlayerBar.BorderSizePixel = 0
PlayerBar.Parent = Right
cr(PlayerBar,12)
stroke(PlayerBar, T.blue, 1, 0.5)
local nowTitle = Instance.new("TextLabel")
nowTitle.BackgroundTransparency = 1
nowTitle.Position = UDim2.new(0,12,0,6)
nowTitle.Size = UDim2.new(0.5,0,0,16)
nowTitle.Font = Enum.Font.GothamBold
nowTitle.Text = state.current and state.current.title or "-"
nowTitle.TextColor3 = T.text
nowTitle.TextSize = 12
nowTitle.TextXAlignment = Enum.TextXAlignment.Left
nowTitle.Parent = PlayerBar
local function mctrl(text, x, cb)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,34,0,28)
	b.Position = UDim2.new(1,x,0.5,-14)
	b.BackgroundColor3 = T.card2
	b.Text = text
	b.TextColor3 = T.text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.Parent = PlayerBar
	cr(b,8)
	b.MouseButton1Click:Connect(function() pcall(cb,b) end)
end
mctrl("|<", -110, function()
	state.index = math.max(1, state.index-1)
	playTrack(Catalog[state.index])
	nowTitle.Text = Catalog[state.index].title
end)
mctrl(">", -70, function(b)
	if state.playing then player:Pause() state.playing=false b.Text=">" else playTrack(state.current) b.Text="||" end
end)
mctrl(">|", -30, function()
	state.index = state.index % #Catalog + 1
	playTrack(Catalog[state.index])
	nowTitle.Text = Catalog[state.index].title
end)

local FloatGui = Instance.new("ScreenGui")
FloatGui.Name = "MemeHubFloat"
FloatGui.ResetOnSpawn = false
FloatGui.IgnoreGuiInset = true
FloatGui.DisplayOrder = 9999
FloatGui.Parent = PG

local sz = ThemeSave.floatSize or 56
local Chip = Instance.new("ImageButton")
Chip.Size = UDim2.new(0,sz,0,sz)
Chip.Position = UDim2.new(0,14,0.55,0)
Chip.BackgroundColor3 = T.blue
Chip.BorderSizePixel = 0
Chip.AutoButtonColor = true
Chip.Parent = FloatGui
cr(Chip,14)
local chipTxt = Instance.new("TextLabel")
chipTxt.BackgroundTransparency = 1
chipTxt.Size = UDim2.new(1,0,1,0)
chipTxt.Font = Enum.Font.GothamBlack
chipTxt.Text = "M"
chipTxt.TextColor3 = Color3.new(1,1,1)
chipTxt.TextScaled = true
chipTxt.Parent = Chip

ui.applyFloat = function()
	local s = ThemeSave.floatSize or 56
	Chip.Size = UDim2.new(0,s,0,s)
	if ThemeSave.floatImage and ThemeSave.floatImage ~= "" then
		setImage(Chip, ThemeSave.floatImage)
		task.delay(0.5, function() if Chip.Image ~= "" then chipTxt.Visible = false end end)
	else
		Chip.Image = ""
		chipTxt.Visible = true
	end
end
ui.applyFloat()

do
	local draggingF, f0, p0f, moved = false, nil, nil, false
	Chip.InputBegan:Connect(function(i)
		if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
			draggingF = true moved = false f0 = i.Position p0f = Chip.Position
			i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then draggingF=false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if not draggingF then return end
		if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
			local d = i.Position - f0
			if math.abs(d.X)+math.abs(d.Y) > 6 then moved = true end
			Chip.Position = UDim2.new(0, p0f.X.Offset+d.X, 0, p0f.Y.Offset+d.Y)
		end
	end)
	Chip.MouseButton1Click:Connect(function()
		if moved then return end
		Main.Visible = not Main.Visible
	end)
end

ui.switch("Combat")
print("[Meme Hub v62] ready · combat core live")
GG().MemeHubVersion = VERSION

end)

if not okAll then
	warn("[Meme Hub v62] ERRO:", errAll)
end
