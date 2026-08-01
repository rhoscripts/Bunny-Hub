--!strict
--[[
	Bunny Hub
	Tabs: Home, Combat, Player, Visuals, Settings
	Anti Detection removed (executor crash risk)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local mathFloor = math.floor
local round = function(n)
	return mathFloor(tonumber(n) + 0.5)
end

--------------------------------------------------------------------------------
-- THEME
--------------------------------------------------------------------------------
local Theme = {
	Bg = Color3.fromRGB(12, 12, 16),
	BgDeep = Color3.fromRGB(9, 9, 12),
	Panel = Color3.fromRGB(18, 18, 24),
	PanelAlt = Color3.fromRGB(22, 22, 30),
	PanelHover = Color3.fromRGB(28, 28, 38),
	PanelActive = Color3.fromRGB(32, 28, 48),
	Border = Color3.fromRGB(255, 255, 255),
	Accent = Color3.fromRGB(139, 92, 246),
	AccentSoft = Color3.fromRGB(167, 139, 250),
	Text = Color3.fromRGB(244, 244, 248),
	TextDim = Color3.fromRGB(150, 150, 165),
	TextMute = Color3.fromRGB(100, 100, 115),
	Success = Color3.fromRGB(52, 211, 153),
	Danger = Color3.fromRGB(248, 113, 113),
	DangerBg = Color3.fromRGB(48, 24, 30),
	Warning = Color3.fromRGB(251, 191, 36),
	TrackOff = Color3.fromRGB(42, 42, 54),
	TrackBg = Color3.fromRGB(36, 36, 46),
	White = Color3.fromRGB(255, 255, 255),
	Logo = "rbxassetid://138413388191614",

	Icons = {
		Home = "rbxassetid://105972461989047",
		Combat = "rbxassetid://109724503007348",
		Player = "rbxassetid://84037048089807",
		Visuals = "rbxassetid://106915638101653",
		Settings = "rbxassetid://97568634444241",
	},

	Radius = {
		Window = 16,
		Card = 12,
		Control = 10,
	},
	Font = {
		Title = Enum.Font.GothamBlack,
		Bold = Enum.Font.GothamBold,
		Med = Enum.Font.GothamMedium,
		Reg = Enum.Font.Gotham,
	},
	Anim = {
		Fast = 0.12,
		Normal = 0.18,
	},
}

--------------------------------------------------------------------------------
-- STATE
--------------------------------------------------------------------------------
local Flags = {
	AimbotGlobal = false,
	AimbotNPC = false,
	AimEnabled = true,
	AntiStun = false,
	FastAttackEnabled = false,
	FADistance = 10,
	PredictionAmount = 0.1,
	RaceClickAutov3 = false,
	RaceClickAutov4 = false,
	WalkWater = false,
}

local Settings = {
	Bunny = {
		AimbotGun = false,
		AimbotSkill = false,
		FastAttack = false,
		AutoHaki = false,
		WalkWater = false,
		ESPRange = 500,
		TargetMode = "Player",
		AntiStun = false,
		CameraLock = false,
		Prediction = 0.1,
		FADistance = 10,
		AutoV3 = false,
		AutoV4 = false,
	},
	Player = {
		WalkSpeedEnabled = false,
		WalkSpeed = 16,
		JumpPowerEnabled = false,
		JumpPower = 50,
	},
	Visuals = {
		ESPPlayer = false,
	},
	Utility = {
		InfiniteEnergy = false,
		AntiAFK = true,
		Notifications = true,
		HideUserInfo = false,
		AntiAdmin = false,
	},
}

local SelectWeaponGun = ""
local Number = math.random(1, 1000000)
local originalStam
local SessionStart = os.clock()
local aimTable = { currentAim = nil }
local npcAimTable = { currentNPCAim = nil }
local CameraLockData = { Enabled = false, Target = nil }
local TargetModeQuick = "None"

local MarkerPart = Instance.new("Part")
MarkerPart.Name = "BunnyAimMarker"
MarkerPart.Size = Vector3.new(0.5, 0.5, 0.5)
MarkerPart.Anchored = true
MarkerPart.CanCollide = false
MarkerPart.Transparency = 1
MarkerPart.Parent = workspace

local CombatToggles = {
	AimbotGun = nil,
	AimbotSkill = nil,
	NPCAimbot = nil,
}

--------------------------------------------------------------------------------
-- UTILS
--------------------------------------------------------------------------------
local function tween(obj, props, dur, style, dir)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(dur or Theme.Anim.Normal, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Border
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0.94
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function pad(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t)
	p.PaddingBottom = UDim.new(0, b)
	p.PaddingLeft = UDim.new(0, l)
	p.PaddingRight = UDim.new(0, r)
	p.Parent = parent
	return p
end

local function list(parent, dir, padding, hAlign, vAlign)
	local l = Instance.new("UIListLayout")
	l.FillDirection = dir or Enum.FillDirection.Vertical
	l.Padding = UDim.new(0, padding or 0)
	l.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left
	l.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

--------------------------------------------------------------------------------
-- HIDDEN GUI PARENT
--------------------------------------------------------------------------------
local HiddenGuiGetter = (function()
	local ok1, v1 = pcall(function() return get_hidden_gui end)
	if ok1 and v1 then return v1 end
	local ok2, v2 = pcall(function() return gethui end)
	if ok2 and v2 then return v2 end
	return nil
end)()

local function GetUiParent()
	if HiddenGuiGetter then
		local ok, hidden = pcall(HiddenGuiGetter)
		if ok and hidden then
			return hidden
		end
	end
	local ok2, hasRobloxGui = pcall(function()
		return CoreGui:FindFirstChild("RobloxGui")
	end)
	if ok2 and hasRobloxGui then
		return CoreGui.RobloxGui
	end
	return CoreGui
end

local function ProtectAndParent(gui)
	if HiddenGuiGetter then
		local ok, hidden = pcall(HiddenGuiGetter)
		if ok and hidden then
			gui.Parent = hidden
			return
		end
	end
	if not is_sirhurt_closure and syn and typeof(syn) == "table" and syn.protect_gui then
		pcall(function()
			syn.protect_gui(gui)
		end)
		gui.Parent = CoreGui
		return
	end
	local ok2, hasRobloxGui = pcall(function()
		return CoreGui:FindFirstChild("RobloxGui")
	end)
	if ok2 and hasRobloxGui then
		gui.Parent = CoreGui.RobloxGui
		return
	end
	gui.Parent = CoreGui
end

pcall(function()
	local parent = GetUiParent()
	if parent:FindFirstChild("BunnyHubUI") then
		parent.BunnyHubUI:Destroy()
	end
	if parent:FindFirstChild("BunnyNotify") then
		parent.BunnyNotify:Destroy()
	end
end)

local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

--------------------------------------------------------------------------------
-- NOTIFICATIONS
--------------------------------------------------------------------------------
local NotifyGui = Instance.new("ScreenGui")
NotifyGui.Name = "BunnyNotify"
NotifyGui.ResetOnSpawn = false
NotifyGui.DisplayOrder = 1000
NotifyGui.IgnoreGuiInset = true
NotifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ProtectAndParent(NotifyGui)

local NotifyWidth = IsMobile and math.clamp(Camera.ViewportSize.X * 0.72, 200, 250) or 280

local NotifyContainer = Instance.new("Frame")
NotifyContainer.Size = UDim2.new(0, NotifyWidth, 1, -32)
NotifyContainer.Position = UDim2.new(1, -(NotifyWidth + 16), 0, 16)
NotifyContainer.BackgroundTransparency = 1
NotifyContainer.Parent = NotifyGui

local NotifyLayout = Instance.new("UIListLayout")
NotifyLayout.Padding = UDim.new(0, 8)
NotifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifyLayout.Parent = NotifyContainer

local function Notify(title, text, duration, notifType)
	if Settings.Utility.Notifications == false then
		return
	end
	duration = duration or 3
	local color = Theme.AccentSoft
	if notifType == "Success" then
		color = Theme.Success
	elseif notifType == "Error" then
		color = Theme.Danger
	elseif notifType == "Warning" then
		color = Theme.Warning
	end

	local Notif = Instance.new("Frame")
	Notif.Size = UDim2.new(0, NotifyWidth, 0, 0)
	Notif.BackgroundColor3 = Theme.Panel
	Notif.BorderSizePixel = 0
	Notif.ClipsDescendants = true
	Notif.Parent = NotifyContainer
	corner(Notif, Theme.Radius.Card)
	stroke(Notif, Theme.Border, 1, 0.92)

	local accentBar = Instance.new("Frame")
	accentBar.Size = UDim2.new(0, 3, 1, -12)
	accentBar.Position = UDim2.fromOffset(6, 6)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.Parent = Notif
	corner(accentBar, 2)

	local TitleL = Instance.new("TextLabel")
	TitleL.Size = UDim2.new(1, -28, 0, 16)
	TitleL.Position = UDim2.fromOffset(16, 10)
	TitleL.BackgroundTransparency = 1
	TitleL.Text = title
	TitleL.Font = Theme.Font.Bold
	TitleL.TextSize = 12
	TitleL.TextColor3 = color
	TitleL.TextXAlignment = Enum.TextXAlignment.Left
	TitleL.Parent = Notif

	local TextL = Instance.new("TextLabel")
	TextL.Size = UDim2.new(1, -28, 0, 0)
	TextL.Position = UDim2.fromOffset(16, 28)
	TextL.BackgroundTransparency = 1
	TextL.Text = text
	TextL.Font = Theme.Font.Reg
	TextL.TextSize = 11
	TextL.TextColor3 = Theme.TextDim
	TextL.TextXAlignment = Enum.TextXAlignment.Left
	TextL.TextYAlignment = Enum.TextYAlignment.Top
	TextL.TextWrapped = true
	TextL.AutomaticSize = Enum.AutomaticSize.Y
	TextL.Parent = Notif

	task.defer(function()
		local bodyHeight = TextL.TextBounds.Y
		local totalHeight = math.max(52, 28 + bodyHeight + 12)
		tween(Notif, { Size = UDim2.new(0, NotifyWidth, 0, totalHeight) }, 0.32, Enum.EasingStyle.Quint)
	end)

	task.delay(duration, function()
		local out = tween(Notif, { Size = UDim2.new(0, NotifyWidth, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
		out.Completed:Wait()
		Notif:Destroy()
	end)
end

--------------------------------------------------------------------------------
-- SERVER HOP (single attempt, lowest ping)
--------------------------------------------------------------------------------
local PlaceId = game.PlaceId
local CurrentJobId = game.JobId
local hopBaseUrl = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"

local function listServers(cursor)
	local url = hopBaseUrl
	if cursor then
		url = url .. "&cursor=" .. cursor
	end
	local ok, result = pcall(function()
		if syn and syn.request then
			return syn.request({ Url = url, Method = "GET" }).Body
		elseif http_request then
			return http_request({ Url = url, Method = "GET" }).Body
		elseif request then
			return request({ Url = url, Method = "GET" }).Body
		elseif game.HttpGetAsync then
			return game:HttpGetAsync(url)
		else
			return game:HttpGet(url)
		end
	end)
	if not ok or not result then
		return nil
	end
	local decodeOk, data = pcall(function()
		return HttpService:JSONDecode(result)
	end)
	if not decodeOk then
		return nil
	end
	return data
end

local function JoinLowPingServer()
	Notify("Server Hop", "Searching for a server...", 2, "Info")
	task.spawn(function()
		local bestServer = nil
		local cursor = nil
		local pages = 0

		repeat
			local page = listServers(cursor)
			if not page then
				break
			end

			for _, server in ipairs(page.data or {}) do
				local notCurrent = server.id ~= CurrentJobId
				local hasSpace = (server.playing or 0) < (server.maxPlayers or 0)
				local hasPing = server.ping ~= nil

				if notCurrent and hasSpace and hasPing then
					if not bestServer or server.ping < bestServer.ping then
						bestServer = server
					end
				end
			end

			cursor = page.nextPageCursor
			pages += 1
		until not cursor or pages >= 8

		if bestServer then
			Notify("Server Hop", "Joining lowest ping server...", 2, "Success")
			pcall(function()
				TeleportService:TeleportToPlaceInstance(PlaceId, bestServer.id, LocalPlayer)
			end)
		else
			Notify("Server Hop", "No server found.", 3, "Error")
		end
	end)
end

--------------------------------------------------------------------------------
-- ANTI ADMIN (>= 2801) -> hop only
--------------------------------------------------------------------------------
local adminHopDebounce = false
task.spawn(function()
	while task.wait(0.75) do
		if not Settings.Utility.AntiAdmin then
			continue
		end
		pcall(function()
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= LocalPlayer then
					local data = plr:FindFirstChild("Data")
					local levelVal = data and data:FindFirstChild("Level")
					local level = levelVal and tonumber(levelVal.Value) or 0
					if level >= 2801 then
						if not adminHopDebounce then
							adminHopDebounce = true
							Notify("Anti Admin", "High level player detected. Hopping...", 2, "Warning")
							JoinLowPingServer()
							task.delay(8, function()
								adminHopDebounce = false
							end)
						end
						break
					end
				end
			end
		end)
	end
end)

--------------------------------------------------------------------------------
-- TARGETING
--------------------------------------------------------------------------------
local function InSafeZone()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if pg and pg:FindFirstChild("Main") and pg.Main:FindFirstChild("SafeZone") and pg.Main.SafeZone.Visible then
		return true
	end
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("ForceField") then
		return true
	end
	return false
end

local function IsValidBunnyPlayer(p)
	if not p or not p.Character then
		return false
	end
	local hum = p.Character:FindFirstChild("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	if InSafeZone() then
		return false
	end
	if p.Character:FindFirstChildOfClass("ForceField") then
		return false
	end
	return true
end

local function GetNearestBunnyPlayer()
	if InSafeZone() then
		return nil
	end
	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		return nil
	end
	local bestDist, bestHRP = math.huge, nil
	for _, v in ipairs(Players:GetPlayers()) do
		if v ~= LocalPlayer and IsValidBunnyPlayer(v) then
			local hrp = v.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local d = (hrp.Position - myHRP.Position).Magnitude
				if d < bestDist and d <= Settings.Bunny.ESPRange then
					bestDist = d
					bestHRP = hrp
				end
			end
		end
	end
	return bestHRP
end

local function GetNearestBunnyNPC()
	local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		return nil
	end
	local bestDist, bestResult = math.huge, nil
	local enemies = workspace:FindFirstChild("Enemies")
	if not enemies then
		return nil
	end
	for _, v in ipairs(enemies:GetChildren()) do
		local hrp = v:FindFirstChild("HumanoidRootPart")
		local hum = v:FindFirstChild("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - myHRP.Position).Magnitude
			if d < bestDist then
				bestDist = d
				bestResult = v
			end
		end
	end
	return bestResult
end

local function GetBunnyTargetHRP()
	if Settings.Bunny.TargetMode == "NPC" then
		local npc = GetNearestBunnyNPC()
		return npc and npc:FindFirstChild("HumanoidRootPart") or nil
	else
		return GetNearestBunnyPlayer()
	end
end

--------------------------------------------------------------------------------
-- MAIN UI SHELL
--------------------------------------------------------------------------------
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "BunnyHubUI"
MainGui.ResetOnSpawn = false
MainGui.DisplayOrder = 999
MainGui.IgnoreGuiInset = true
MainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ProtectAndParent(MainGui)

local ViewportSize = Camera.ViewportSize
local TargetW, TargetH
if IsMobile then
	TargetW = math.clamp(ViewportSize.X * 0.88, 320, 400)
	TargetH = math.clamp(ViewportSize.Y * 0.58, 340, 430)
else
	TargetW = math.clamp(ViewportSize.X * 0.40, 520, 600)
	TargetH = math.clamp(ViewportSize.Y * 0.54, 390, 470)
end

local TITLEBAR_H = IsMobile and 48 or 52
local SIDEBAR_W = IsMobile and 64 or 72
local expandedSize = UDim2.fromOffset(TargetW, TargetH)

local Main = Instance.new("CanvasGroup")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = expandedSize
Main.BackgroundColor3 = Theme.Bg
Main.BorderSizePixel = 0
Main.GroupTransparency = 0
Main.ZIndex = 1
Main.Parent = MainGui
corner(Main, Theme.Radius.Window)
stroke(Main, Theme.Accent, 1, 0.82)

local TopGlow = Instance.new("Frame")
TopGlow.Size = UDim2.new(1, 0, 0, 1)
TopGlow.BackgroundColor3 = Theme.Accent
TopGlow.BackgroundTransparency = 0.55
TopGlow.BorderSizePixel = 0
TopGlow.ZIndex = 5
TopGlow.Parent = Main

--------------------------------------------------------------------------------
-- TOP BAR
--------------------------------------------------------------------------------
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, TITLEBAR_H)
TopBar.BackgroundColor3 = Theme.BgDeep
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopBarLine = Instance.new("Frame")
TopBarLine.Size = UDim2.new(1, 0, 0, 1)
TopBarLine.Position = UDim2.new(0, 0, 1, -1)
TopBarLine.BackgroundColor3 = Theme.Border
TopBarLine.BackgroundTransparency = 0.93
TopBarLine.BorderSizePixel = 0
TopBarLine.Parent = TopBar

local LogoWrap = Instance.new("Frame")
LogoWrap.Size = UDim2.fromOffset(28, 28)
LogoWrap.Position = UDim2.new(0, 12, 0.5, -14)
LogoWrap.BackgroundColor3 = Theme.PanelAlt
LogoWrap.BorderSizePixel = 0
LogoWrap.Parent = TopBar
corner(LogoWrap, 8)
stroke(LogoWrap, Theme.Accent, 1, 0.75)

local Logo = Instance.new("ImageLabel")
Logo.Size = UDim2.fromScale(1, 1)
Logo.BackgroundTransparency = 1
Logo.Image = Theme.Logo
Logo.ScaleType = Enum.ScaleType.Crop
Logo.Parent = LogoWrap
corner(Logo, 8)

local TitleCol = Instance.new("Frame")
TitleCol.Size = UDim2.new(0, 200, 1, 0)
TitleCol.Position = UDim2.fromOffset(48, 0)
TitleCol.BackgroundTransparency = 1
TitleCol.Parent = TopBar

local TitleTxt = Instance.new("TextLabel")
TitleTxt.Size = UDim2.new(1, 0, 0, 16)
TitleTxt.Position = UDim2.fromOffset(0, IsMobile and 8 or 9)
TitleTxt.BackgroundTransparency = 1
TitleTxt.Text = "BUNNY HUB"
TitleTxt.Font = Theme.Font.Title
TitleTxt.TextSize = IsMobile and 13 or 14
TitleTxt.TextColor3 = Theme.Text
TitleTxt.TextXAlignment = Enum.TextXAlignment.Left
TitleTxt.Parent = TitleCol

local SubTxt = Instance.new("TextLabel")
SubTxt.Size = UDim2.new(1, 0, 0, 14)
SubTxt.Position = UDim2.fromOffset(0, IsMobile and 25 or 28)
SubTxt.BackgroundTransparency = 1
SubTxt.Text = "by rhoscripts"
SubTxt.Font = Theme.Font.Reg
SubTxt.TextSize = 11
SubTxt.TextColor3 = Theme.TextMute
SubTxt.TextXAlignment = Enum.TextXAlignment.Left
SubTxt.Parent = TitleCol

local VersionPill = Instance.new("TextLabel")
VersionPill.AnchorPoint = Vector2.new(1, 0.5)
VersionPill.Position = UDim2.new(1, -48, 0.5, 0)
VersionPill.Size = UDim2.fromOffset(36, 20)
VersionPill.BackgroundColor3 = Theme.Panel
VersionPill.Text = "v1"
VersionPill.Font = Theme.Font.Bold
VersionPill.TextSize = 11
VersionPill.TextColor3 = Theme.AccentSoft
VersionPill.Parent = TopBar
corner(VersionPill, 7)
stroke(VersionPill, Theme.Accent, 1, 0.8)

local MinBtn = Instance.new("TextButton")
MinBtn.AnchorPoint = Vector2.new(1, 0.5)
MinBtn.Position = UDim2.new(1, -10, 0.5, 0)
MinBtn.Size = UDim2.fromOffset(28, 28)
MinBtn.BackgroundColor3 = Theme.Panel
MinBtn.AutoButtonColor = false
MinBtn.Text = "—"
MinBtn.Font = Theme.Font.Bold
MinBtn.TextSize = 14
MinBtn.TextColor3 = Theme.TextDim
MinBtn.Parent = TopBar
corner(MinBtn, 8)
stroke(MinBtn, Theme.Border, 1, 0.93)

MinBtn.MouseEnter:Connect(function()
	tween(MinBtn, { BackgroundColor3 = Theme.PanelHover, TextColor3 = Theme.AccentSoft }, Theme.Anim.Fast)
end)
MinBtn.MouseLeave:Connect(function()
	tween(MinBtn, { BackgroundColor3 = Theme.Panel, TextColor3 = Theme.TextDim }, Theme.Anim.Fast)
end)

--------------------------------------------------------------------------------
-- SIDEBAR
--------------------------------------------------------------------------------
local SideBar = Instance.new("Frame")
SideBar.Size = UDim2.new(0, SIDEBAR_W, 1, -TITLEBAR_H)
SideBar.Position = UDim2.fromOffset(0, TITLEBAR_H)
SideBar.BackgroundColor3 = Theme.BgDeep
SideBar.BorderSizePixel = 0
SideBar.ClipsDescendants = true
SideBar.Parent = Main

local SideLine = Instance.new("Frame")
SideLine.Size = UDim2.new(0, 1, 1, 0)
SideLine.Position = UDim2.new(1, -1, 0, 0)
SideLine.BackgroundColor3 = Theme.Border
SideLine.BackgroundTransparency = 0.93
SideLine.BorderSizePixel = 0
SideLine.Parent = SideBar

local SideHolder = Instance.new("Frame")
SideHolder.Size = UDim2.new(1, 0, 0, 0)
SideHolder.AutomaticSize = Enum.AutomaticSize.Y
SideHolder.BackgroundTransparency = 1
SideHolder.Position = UDim2.fromOffset(0, 12)
SideHolder.Parent = SideBar
list(SideHolder, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

--------------------------------------------------------------------------------
-- CONTENT
--------------------------------------------------------------------------------
local ContentRoot = Instance.new("Frame")
ContentRoot.Size = UDim2.new(1, -SIDEBAR_W, 1, -TITLEBAR_H)
ContentRoot.Position = UDim2.fromOffset(SIDEBAR_W, TITLEBAR_H)
ContentRoot.BackgroundColor3 = Theme.Bg
ContentRoot.BorderSizePixel = 0
ContentRoot.Parent = Main

local HEADER_H = IsMobile and 52 or 56
local PageHeader = Instance.new("Frame")
PageHeader.Size = UDim2.new(1, 0, 0, HEADER_H)
PageHeader.BackgroundTransparency = 1
PageHeader.Parent = ContentRoot
pad(PageHeader, 0, 0, 14, 14)

local HeaderIconHolder = Instance.new("Frame")
HeaderIconHolder.Size = UDim2.fromOffset(32, 32)
HeaderIconHolder.Position = UDim2.new(0, 0, 0.5, -16)
HeaderIconHolder.BackgroundColor3 = Theme.PanelActive
HeaderIconHolder.BorderSizePixel = 0
HeaderIconHolder.Parent = PageHeader
corner(HeaderIconHolder, 10)
stroke(HeaderIconHolder, Theme.Accent, 1, 0.78)

local HeaderIcon = Instance.new("ImageLabel")
HeaderIcon.Name = "HeaderIcon"
HeaderIcon.Size = UDim2.fromOffset(16, 16)
HeaderIcon.Position = UDim2.new(0.5, -8, 0.5, -8)
HeaderIcon.BackgroundTransparency = 1
HeaderIcon.Image = Theme.Icons.Home
HeaderIcon.ImageColor3 = Theme.AccentSoft
HeaderIcon.ScaleType = Enum.ScaleType.Fit
HeaderIcon.Parent = HeaderIconHolder

local HeaderTitle = Instance.new("TextLabel")
HeaderTitle.Size = UDim2.new(1, -46, 0, 18)
HeaderTitle.Position = UDim2.fromOffset(42, 8)
HeaderTitle.BackgroundTransparency = 1
HeaderTitle.Font = Theme.Font.Bold
HeaderTitle.TextSize = IsMobile and 15 or 16
HeaderTitle.TextColor3 = Theme.Text
HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
HeaderTitle.Parent = PageHeader

local HeaderSub = Instance.new("TextLabel")
HeaderSub.Size = UDim2.new(1, -46, 0, 14)
HeaderSub.Position = UDim2.fromOffset(42, 28)
HeaderSub.BackgroundTransparency = 1
HeaderSub.Font = Theme.Font.Reg
HeaderSub.TextSize = 11
HeaderSub.TextColor3 = Theme.TextDim
HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
HeaderSub.Parent = PageHeader

local HeaderLine = Instance.new("Frame")
HeaderLine.Size = UDim2.new(1, -28, 0, 1)
HeaderLine.Position = UDim2.new(0, 14, 1, -1)
HeaderLine.BackgroundColor3 = Theme.Border
HeaderLine.BackgroundTransparency = 0.93
HeaderLine.BorderSizePixel = 0
HeaderLine.Parent = PageHeader

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -HEADER_H)
ContentArea.Position = UDim2.fromOffset(0, HEADER_H)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = ContentRoot

--------------------------------------------------------------------------------
-- TAB SYSTEM
--------------------------------------------------------------------------------
local Tabs = {}
local Pages = {}
local Controls = {}
local BTN_SIZE = IsMobile and 40 or 44
local tabCount = 0

local function SetImageIcon(imageLabel, iconKey, color)
	imageLabel.Image = Theme.Icons[iconKey] or ""
	imageLabel.ImageColor3 = color or Theme.TextMute
end

local function CreateTab(name, subtitle, iconKey)
	tabCount += 1

	local TabBtn = Instance.new("TextButton")
	TabBtn.LayoutOrder = tabCount
	TabBtn.Size = UDim2.fromOffset(BTN_SIZE, BTN_SIZE)
	TabBtn.BackgroundColor3 = Theme.Panel
	TabBtn.BackgroundTransparency = 1
	TabBtn.AutoButtonColor = false
	TabBtn.Text = ""
	TabBtn.Parent = SideHolder
	corner(TabBtn, 12)

	local Indicator = Instance.new("Frame")
	Indicator.AnchorPoint = Vector2.new(0, 0.5)
	Indicator.Position = UDim2.new(0, 0, 0.5, 0)
	Indicator.Size = UDim2.fromOffset(3, 0)
	Indicator.BackgroundColor3 = Theme.Accent
	Indicator.BorderSizePixel = 0
	Indicator.Parent = TabBtn
	corner(Indicator, 99)

	local IconImage = Instance.new("ImageLabel")
	IconImage.Name = "Icon"
	IconImage.Size = UDim2.fromOffset(18, 18)
	IconImage.Position = UDim2.new(0.5, -9, 0.5, -9)
	IconImage.BackgroundTransparency = 1
	IconImage.Image = Theme.Icons[iconKey]
	IconImage.ImageColor3 = Theme.TextMute
	IconImage.ScaleType = Enum.ScaleType.Fit
	IconImage.Parent = TabBtn

	local Page = Instance.new("ScrollingFrame")
	Page.Size = UDim2.fromScale(1, 1)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 3
	Page.ScrollBarImageColor3 = Theme.Accent
	Page.ScrollBarImageTransparency = 0.4
	Page.Visible = false
	Page.CanvasSize = UDim2.new()
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.Parent = ContentArea
	pad(Page, 4, 14, 12, 12)
	list(Page, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center)

	TabBtn.MouseEnter:Connect(function()
		if not Page.Visible then
			tween(TabBtn, { BackgroundTransparency = 0.35, BackgroundColor3 = Theme.PanelHover }, Theme.Anim.Fast)
			tween(IconImage, { ImageColor3 = Theme.TextDim }, Theme.Anim.Fast)
		end
	end)
	TabBtn.MouseLeave:Connect(function()
		if not Page.Visible then
			tween(TabBtn, { BackgroundTransparency = 1 }, Theme.Anim.Fast)
			tween(IconImage, { ImageColor3 = Theme.TextMute }, Theme.Anim.Fast)
		end
	end)

	local function Select()
		for _, t in pairs(Tabs) do
			tween(t.Btn, { BackgroundTransparency = 1 }, Theme.Anim.Fast)
			tween(t.Indicator, { Size = UDim2.fromOffset(3, 0) }, Theme.Anim.Fast)
			tween(t.IconImage, { ImageColor3 = Theme.TextMute }, Theme.Anim.Fast)
		end
		for _, p in pairs(Pages) do
			p.Visible = false
		end

		tween(TabBtn, { BackgroundTransparency = 0.15, BackgroundColor3 = Theme.PanelActive }, Theme.Anim.Fast)
		tween(Indicator, { Size = UDim2.fromOffset(3, 22) }, Theme.Anim.Normal, Enum.EasingStyle.Quint)
		tween(IconImage, { ImageColor3 = Theme.AccentSoft }, Theme.Anim.Fast)

		Page.Visible = true
		Page.CanvasPosition = Vector2.zero
		HeaderTitle.Text = name
		HeaderSub.Text = subtitle
		SetImageIcon(HeaderIcon, iconKey, Theme.AccentSoft)
	end

	TabBtn.MouseButton1Click:Connect(Select)
	table.insert(Tabs, {
		Btn = TabBtn,
		IconImage = IconImage,
		IconKey = iconKey,
		Indicator = Indicator,
		Select = Select,
	})
	table.insert(Pages, Page)

	if #Tabs == 1 then
		Select()
	end
	return Page
end

--------------------------------------------------------------------------------
-- UI COMPONENTS
--------------------------------------------------------------------------------
local function AddSection(page, title)
	local wrap = Instance.new("Frame")
	wrap.Size = UDim2.new(1, 0, 0, 20)
	wrap.BackgroundTransparency = 1
	wrap.Parent = page

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.upper(title)
	label.Font = Theme.Font.Bold
	label.TextSize = 11
	label.TextColor3 = Theme.TextMute
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = wrap
	return wrap
end

local function AddToggle(page, name, default, callback)
	local Tog = Instance.new("TextButton")
	Tog.Size = UDim2.new(1, 0, 0, 44)
	Tog.BackgroundColor3 = Theme.Panel
	Tog.AutoButtonColor = false
	Tog.Text = ""
	Tog.Parent = page
	corner(Tog, Theme.Radius.Control)
	stroke(Tog, Theme.Border, 1, 0.94)

	Tog.MouseEnter:Connect(function()
		tween(Tog, { BackgroundColor3 = Theme.PanelHover }, Theme.Anim.Fast)
	end)
	Tog.MouseLeave:Connect(function()
		tween(Tog, { BackgroundColor3 = Theme.Panel }, Theme.Anim.Fast)
	end)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -70, 1, 0)
	Title.Position = UDim2.fromOffset(14, 0)
	Title.BackgroundTransparency = 1
	Title.Text = name
	Title.Font = Theme.Font.Bold
	Title.TextSize = 13
	Title.TextColor3 = Theme.Text
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.Parent = Tog

	local ToggleFrame = Instance.new("Frame")
	ToggleFrame.Size = UDim2.fromOffset(42, 24)
	ToggleFrame.Position = UDim2.new(1, -56, 0.5, -12)
	ToggleFrame.BackgroundColor3 = default and Theme.Accent or Theme.TrackOff
	ToggleFrame.Parent = Tog
	corner(ToggleFrame, 99)

	local Circle = Instance.new("Frame")
	Circle.Size = UDim2.fromOffset(18, 18)
	Circle.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	Circle.BackgroundColor3 = Theme.White
	Circle.Parent = ToggleFrame
	corner(Circle, 99)

	local state = default

	local function SetState(v)
		state = v and true or false
		tween(ToggleFrame, { BackgroundColor3 = state and Theme.Accent or Theme.TrackOff }, Theme.Anim.Normal)
		tween(Circle, {
			Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9),
		}, Theme.Anim.Normal, Enum.EasingStyle.Back)
		if callback then
			callback(state)
		end
	end

	if callback then
		callback(state)
	end

	Tog.MouseButton1Click:Connect(function()
		SetState(not state)
	end)

	local api = {
		Set = function(_, v)
			SetState(v)
		end,
		Get = function()
			return state
		end,
		Type = "toggle",
		Default = default,
	}
	table.insert(Controls, api)
	return api
end

local function AddSlider(page, name, min, max, default, callback)
	local Sld = Instance.new("Frame")
	Sld.Size = UDim2.new(1, 0, 0, 54)
	Sld.BackgroundColor3 = Theme.Panel
	Sld.Parent = page
	corner(Sld, Theme.Radius.Control)
	stroke(Sld, Theme.Border, 1, 0.94)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -80, 0, 18)
	Title.Position = UDim2.fromOffset(14, 8)
	Title.BackgroundTransparency = 1
	Title.Text = name
	Title.Font = Theme.Font.Bold
	Title.TextSize = 13
	Title.TextColor3 = Theme.Text
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Sld

	local ValChip = Instance.new("TextLabel")
	ValChip.AnchorPoint = Vector2.new(1, 0)
	ValChip.Position = UDim2.new(1, -12, 0, 8)
	ValChip.Size = UDim2.fromOffset(52, 20)
	ValChip.BackgroundColor3 = Theme.PanelActive
	ValChip.Text = tostring(default)
	ValChip.Font = Theme.Font.Bold
	ValChip.TextSize = 11
	ValChip.TextColor3 = Theme.AccentSoft
	ValChip.Parent = Sld
	corner(ValChip, 6)

	local Bar = Instance.new("Frame")
	Bar.Size = UDim2.new(1, -28, 0, 6)
	Bar.Position = UDim2.fromOffset(14, 36)
	Bar.BackgroundColor3 = Theme.TrackBg
	Bar.Parent = Sld
	corner(Bar, 99)

	local Fill = Instance.new("Frame")
	Fill.Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.Parent = Bar
	corner(Fill, 99)

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(14, 14)
	Knob.AnchorPoint = Vector2.new(0.5, 0.5)
	Knob.Position = UDim2.new(1, 0, 0.5, 0)
	Knob.BackgroundColor3 = Theme.White
	Knob.Parent = Fill
	corner(Knob, 99)
	stroke(Knob, Theme.Accent, 1, 0.35)

	local function SetValue(v)
		v = math.clamp(mathFloor(v), min, max)
		local pct = (v - min) / math.max(max - min, 1)
		Fill.Size = UDim2.new(pct, 0, 1, 0)
		ValChip.Text = tostring(v)
		if callback then
			callback(v)
		end
	end

	local dragging = false
	local function updateFromInput(inputPos)
		local pct = math.clamp((inputPos.X - Bar.AbsolutePosition.X) / math.max(Bar.AbsoluteSize.X, 1), 0, 1)
		SetValue(min + (max - min) * pct)
	end

	Bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			updateFromInput(input.Position)
			tween(Knob, { Size = UDim2.fromOffset(16, 16) }, Theme.Anim.Fast)
		end
	end)
	Bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
			tween(Knob, { Size = UDim2.fromOffset(14, 14) }, Theme.Anim.Fast)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromInput(input.Position)
		end
	end)

	table.insert(Controls, { Type = "slider", Set = SetValue, Default = default })
	return { Set = SetValue }
end

local function AddButton(page, name, buttonText, callback, danger)
	local Btn = Instance.new("Frame")
	Btn.Size = UDim2.new(1, 0, 0, 48)
	Btn.BackgroundColor3 = Theme.Panel
	Btn.Parent = page
	corner(Btn, Theme.Radius.Control)
	stroke(Btn, Theme.Border, 1, 0.94)

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -110, 1, 0)
	Title.Position = UDim2.fromOffset(14, 0)
	Title.BackgroundTransparency = 1
	Title.Text = name
	Title.Font = Theme.Font.Bold
	Title.TextSize = 13
	Title.TextColor3 = Theme.Text
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Btn

	local ActionBtn = Instance.new("TextButton")
	ActionBtn.Size = UDim2.fromOffset(86, 30)
	ActionBtn.Position = UDim2.new(1, -98, 0.5, -15)
	ActionBtn.BackgroundColor3 = danger and Theme.DangerBg or Theme.Accent
	ActionBtn.AutoButtonColor = false
	ActionBtn.Text = buttonText
	ActionBtn.Font = Theme.Font.Bold
	ActionBtn.TextSize = 12
	ActionBtn.TextColor3 = danger and Theme.Danger or Theme.White
	ActionBtn.Parent = Btn
	corner(ActionBtn, 8)
	if danger then
		stroke(ActionBtn, Theme.Danger, 1, 0.55)
	end

	ActionBtn.MouseButton1Click:Connect(function()
		local to = danger and Color3.fromRGB(70, 30, 38) or Theme.AccentSoft
		local back = danger and Theme.DangerBg or Theme.Accent
		tween(ActionBtn, { BackgroundColor3 = to }, 0.08)
		task.delay(0.1, function()
			tween(ActionBtn, { BackgroundColor3 = back }, 0.12)
		end)
		if callback then
			callback()
		end
	end)
end

local function AddLabelStat(page, text)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 38)
	card.BackgroundColor3 = Theme.Panel
	card.Parent = page
	corner(card, Theme.Radius.Control)
	stroke(card, Theme.Border, 1, 0.94)

	local Lbl = Instance.new("TextLabel")
	Lbl.Size = UDim2.new(1, -24, 1, 0)
	Lbl.Position = UDim2.fromOffset(12, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = text
	Lbl.Font = Theme.Font.Med
	Lbl.TextSize = 12
	Lbl.TextColor3 = Theme.TextDim
	Lbl.TextXAlignment = Enum.TextXAlignment.Left
	Lbl.Parent = card
	return Lbl
end

local function MakeCard(parent, size)
	local card = Instance.new("Frame")
	card.Size = size
	card.BackgroundColor3 = Theme.Panel
	card.BorderSizePixel = 0
	card.Parent = parent
	corner(card, Theme.Radius.Card)
	stroke(card, Theme.Border, 1, 0.94)
	return card
end

--------------------------------------------------------------------------------
-- TARGET QUICK ACTION
--------------------------------------------------------------------------------
local TargetBtn
local syncingTarget = false

local function UpdateTargetButtonVisual()
	if not TargetBtn then
		return
	end
	TargetBtn.Text = "Target: " .. TargetModeQuick
	if TargetModeQuick == "None" then
		TargetBtn.BackgroundColor3 = Theme.PanelAlt
		TargetBtn.TextColor3 = Theme.TextDim
	elseif TargetModeQuick == "Player" then
		TargetBtn.BackgroundColor3 = Theme.Accent
		TargetBtn.TextColor3 = Theme.White
	else
		TargetBtn.BackgroundColor3 = Theme.PanelActive
		TargetBtn.TextColor3 = Theme.AccentSoft
	end
end

local function ApplyTargetMode(mode, fromButton)
	TargetModeQuick = mode
	syncingTarget = true

	if mode == "None" then
		if CombatToggles.AimbotGun then CombatToggles.AimbotGun:Set(false) end
		if CombatToggles.AimbotSkill then CombatToggles.AimbotSkill:Set(false) end
		if CombatToggles.NPCAimbot then CombatToggles.NPCAimbot:Set(false) end
	elseif mode == "Player" then
		if CombatToggles.NPCAimbot then CombatToggles.NPCAimbot:Set(false) end
		if CombatToggles.AimbotGun then CombatToggles.AimbotGun:Set(true) end
		if CombatToggles.AimbotSkill then CombatToggles.AimbotSkill:Set(true) end
	elseif mode == "NPC" then
		if CombatToggles.AimbotGun then CombatToggles.AimbotGun:Set(false) end
		if CombatToggles.AimbotSkill then CombatToggles.AimbotSkill:Set(false) end
		if CombatToggles.NPCAimbot then CombatToggles.NPCAimbot:Set(true) end
	end

	syncingTarget = false
	UpdateTargetButtonVisual()
	if fromButton then
		Notify("Target", "Target set to " .. mode, 2, "Success")
	end
end

local function InferTargetModeFromToggles()
	if syncingTarget then
		return
	end
	local gun = CombatToggles.AimbotGun and CombatToggles.AimbotGun:Get() or false
	local skill = CombatToggles.AimbotSkill and CombatToggles.AimbotSkill:Get() or false
	local npc = CombatToggles.NPCAimbot and CombatToggles.NPCAimbot:Get() or false

	if npc and not gun and not skill then
		TargetModeQuick = "NPC"
	elseif (gun or skill) and not npc then
		TargetModeQuick = "Player"
	else
		TargetModeQuick = "None"
	end
	UpdateTargetButtonVisual()
end

local function CycleTargetMode()
	if TargetModeQuick == "None" then
		ApplyTargetMode("Player", true)
	elseif TargetModeQuick == "Player" then
		ApplyTargetMode("NPC", true)
	else
		ApplyTargetMode("None", true)
	end
end

--------------------------------------------------------------------------------
-- DRAG + MINIMIZE
--------------------------------------------------------------------------------
local function MakeDraggable(frame, handle, onClick)
	local dragging, dragStart, startPos, moved

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			moved = false
			dragStart = input.Position
			startPos = frame.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if not moved and onClick then
						onClick()
					end
					conn:Disconnect()
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			if delta.Magnitude > 4 then
				moved = true
			end
			local parentSize = frame.Parent.AbsoluteSize
			local anchorOffsetX = frame.AnchorPoint.X * frame.AbsoluteSize.X
			local anchorOffsetY = frame.AnchorPoint.Y * frame.AbsoluteSize.Y
			local absX = startPos.X.Scale * parentSize.X + startPos.X.Offset + delta.X
			local absY = startPos.Y.Scale * parentSize.Y + startPos.Y.Offset + delta.Y
			local minX = anchorOffsetX
			local maxX = parentSize.X - frame.AbsoluteSize.X + anchorOffsetX
			local minY = anchorOffsetY
			local maxY = parentSize.Y - frame.AbsoluteSize.Y + anchorOffsetY
			absX = math.clamp(absX, minX, math.max(minX, maxX))
			absY = math.clamp(absY, minY, math.max(minY, maxY))
			frame.Position = UDim2.fromOffset(absX, absY)
		end
	end)
end

local CircleBtn = Instance.new("ImageButton")
CircleBtn.Name = "CircleBtn"
CircleBtn.AnchorPoint = Vector2.new(0.5, 0.5)
CircleBtn.Size = UDim2.fromOffset(54, 54)
CircleBtn.Position = UDim2.new(1, -68, 1, -78)
CircleBtn.BackgroundColor3 = Theme.Accent
CircleBtn.Image = Theme.Logo
CircleBtn.ScaleType = Enum.ScaleType.Crop
CircleBtn.Visible = false
CircleBtn.ZIndex = 500
CircleBtn.Parent = MainGui
corner(CircleBtn, 99)

local CircleStroke = Instance.new("UIStroke")
CircleStroke.Color = Theme.White
CircleStroke.Thickness = 2
CircleStroke.Transparency = 0.45
CircleStroke.Parent = CircleBtn

task.spawn(function()
	while task.wait() do
		if CircleBtn.Visible then
			tween(CircleStroke, { Transparency = 0.85 }, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(1)
			tween(CircleStroke, { Transparency = 0.4 }, 1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			task.wait(1)
		else
			task.wait(0.5)
		end
	end
end)

local function SquishPulse(obj, base)
	tween(obj, { Size = UDim2.fromOffset(base * 1.1, base * 1.1) }, 0.08, Enum.EasingStyle.Quad)
	task.delay(0.08, function()
		tween(obj, { Size = UDim2.fromOffset(base, base) }, 0.18, Enum.EasingStyle.Back)
	end)
end

local isOpen = true
local lastMainPosition = Main.Position

local function CollapseToIcon()
	if not isOpen then
		return
	end
	isOpen = false
	lastMainPosition = Main.Position
	CircleBtn.Visible = true
	CircleBtn.Size = UDim2.fromOffset(54, 54)
	local t = tween(Main, {
		Size = UDim2.fromOffset(0, 0),
		Position = CircleBtn.Position,
		GroupTransparency = 1,
	}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
	t.Completed:Connect(function()
		Main.Visible = false
		SquishPulse(CircleBtn, 54)
	end)
end

local function ExpandFromIcon()
	if isOpen then
		return
	end
	isOpen = true
	Main.Visible = true
	Main.GroupTransparency = 1
	Main.Size = UDim2.fromOffset(0, 0)
	Main.Position = CircleBtn.Position
	CircleBtn.Visible = false
	tween(Main, {
		Size = expandedSize,
		Position = lastMainPosition,
		GroupTransparency = 0,
	}, 0.36, Enum.EasingStyle.Quint)
end

MakeDraggable(Main, TopBar, function() end)
MakeDraggable(CircleBtn, CircleBtn, function()
	tween(CircleBtn, { Size = UDim2.fromOffset(46, 46) }, 0.08)
	task.delay(0.08, ExpandFromIcon)
end)

MinBtn.MouseButton1Click:Connect(CollapseToIcon)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.K then
		if isOpen then
			CollapseToIcon()
		else
			ExpandFromIcon()
		end
	end
end)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if not isOpen then
		return
	end
	local vp = Camera.ViewportSize
	local absX = math.clamp(Main.AbsolutePosition.X + Main.AbsoluteSize.X / 2, 0, vp.X)
	local absY = math.clamp(Main.AbsolutePosition.Y + Main.AbsoluteSize.Y / 2, 0, vp.Y)
	Main.Position = UDim2.fromOffset(absX, absY)
end)

task.defer(function()
	Main.Size = UDim2.fromOffset(42, 42)
	Main.GroupTransparency = 1
	tween(Main, { Size = expandedSize, GroupTransparency = 0 }, 0.45, Enum.EasingStyle.Back)
end)

--------------------------------------------------------------------------------
-- PANIC / RESET
--------------------------------------------------------------------------------
local function PanicDisableAll()
	for _, c in ipairs(Controls) do
		if c.Type == "toggle" then
			pcall(function()
				c:Set(false)
			end)
		end
	end
	Flags.AimbotGlobal = false
	Flags.AimbotNPC = false
	Flags.AntiStun = false
	Flags.FastAttackEnabled = false
	Flags.RaceClickAutov3 = false
	Flags.RaceClickAutov4 = false
	CameraLockData.Enabled = false
	TargetModeQuick = "None"
	UpdateTargetButtonVisual()
	Notify("Panic", "All features disabled.", 3, "Error")
end

local function ResetConfig()
	for _, c in ipairs(Controls) do
		pcall(function()
			if c.Set then
				if c.Type == "toggle" then
					c:Set(c.Default)
				else
					c.Set(c.Default)
				end
			end
		end)
	end
	TargetModeQuick = "None"
	UpdateTargetButtonVisual()
	Notify("Config Reset", "Settings restored to default.", 3, "Success")
end

--------------------------------------------------------------------------------
-- PAGES
--------------------------------------------------------------------------------
local HomePage = CreateTab("Home", "Overview & quick actions", "Home")

local WelcomeCard = MakeCard(HomePage, UDim2.new(1, 0, 0, 64))

local WelcomeAccent = Instance.new("Frame")
WelcomeAccent.Size = UDim2.new(0, 3, 1, -14)
WelcomeAccent.Position = UDim2.fromOffset(10, 7)
WelcomeAccent.BackgroundColor3 = Theme.Accent
WelcomeAccent.BorderSizePixel = 0
WelcomeAccent.Parent = WelcomeCard
corner(WelcomeAccent, 2)

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, -30, 0, 20)
WelcomeTitle.Position = UDim2.fromOffset(22, 12)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Font = Theme.Font.Bold
WelcomeTitle.TextSize = 15
WelcomeTitle.TextColor3 = Theme.Text
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.Parent = WelcomeCard

local function UpdateWelcomeText()
	if Settings.Utility.HideUserInfo then
		WelcomeTitle.Text = "Welcome back"
	else
		WelcomeTitle.Text = "Welcome back, " .. LocalPlayer.Name
	end
end
UpdateWelcomeText()

local WelcomeSub = Instance.new("TextLabel")
WelcomeSub.Size = UDim2.new(1, -30, 0, 14)
WelcomeSub.Position = UDim2.fromOffset(22, 36)
WelcomeSub.BackgroundTransparency = 1
WelcomeSub.Text = "Session • " .. os.date("%I:%M %p")
WelcomeSub.Font = Theme.Font.Reg
WelcomeSub.TextSize = 11
WelcomeSub.TextColor3 = Theme.AccentSoft
WelcomeSub.TextXAlignment = Enum.TextXAlignment.Left
WelcomeSub.Parent = WelcomeCard

local SplitRow = Instance.new("Frame")
SplitRow.Size = UDim2.new(1, 0, 0, 150)
SplitRow.BackgroundTransparency = 1
SplitRow.Parent = HomePage

local UpdatesCard = MakeCard(SplitRow, UDim2.new(0.5, -4, 1, 0))

local UpdatesTitle = Instance.new("TextLabel")
UpdatesTitle.Size = UDim2.new(1, -20, 0, 16)
UpdatesTitle.Position = UDim2.fromOffset(12, 10)
UpdatesTitle.BackgroundTransparency = 1
UpdatesTitle.Text = "What's New"
UpdatesTitle.Font = Theme.Font.Bold
UpdatesTitle.TextSize = 12
UpdatesTitle.TextColor3 = Theme.AccentSoft
UpdatesTitle.TextXAlignment = Enum.TextXAlignment.Left
UpdatesTitle.Parent = UpdatesCard

local UpdatesBody = Instance.new("TextLabel")
UpdatesBody.Size = UDim2.new(1, -20, 1, -34)
UpdatesBody.Position = UDim2.fromOffset(12, 30)
UpdatesBody.BackgroundTransparency = 1
UpdatesBody.Text = "• Smaller mobile window\n• Fixed lowest-ping hop\n• Anti Admin\n• Stable Settings tab\n• Crash-prone features removed"
UpdatesBody.Font = Theme.Font.Reg
UpdatesBody.TextSize = 11
UpdatesBody.TextColor3 = Theme.TextDim
UpdatesBody.TextXAlignment = Enum.TextXAlignment.Left
UpdatesBody.TextYAlignment = Enum.TextYAlignment.Top
UpdatesBody.TextWrapped = true
UpdatesBody.Parent = UpdatesCard

local QuickCard = MakeCard(SplitRow, UDim2.new(0.5, -4, 1, 0))
QuickCard.Position = UDim2.new(0.5, 4, 0, 0)

local QuickTitle = Instance.new("TextLabel")
QuickTitle.Size = UDim2.new(1, -20, 0, 16)
QuickTitle.Position = UDim2.fromOffset(12, 10)
QuickTitle.BackgroundTransparency = 1
QuickTitle.Text = "Quick Actions"
QuickTitle.Font = Theme.Font.Bold
QuickTitle.TextSize = 12
QuickTitle.TextColor3 = Theme.AccentSoft
QuickTitle.TextXAlignment = Enum.TextXAlignment.Left
QuickTitle.Parent = QuickCard

local ResetQuickBtn = Instance.new("TextButton")
ResetQuickBtn.Size = UDim2.new(1, -24, 0, 34)
ResetQuickBtn.Position = UDim2.fromOffset(12, 38)
ResetQuickBtn.BackgroundColor3 = Theme.DangerBg
ResetQuickBtn.AutoButtonColor = false
ResetQuickBtn.Text = "Reset Config"
ResetQuickBtn.Font = Theme.Font.Bold
ResetQuickBtn.TextSize = 12
ResetQuickBtn.TextColor3 = Theme.Danger
ResetQuickBtn.Parent = QuickCard
corner(ResetQuickBtn, 8)
stroke(ResetQuickBtn, Theme.Danger, 1, 0.6)
ResetQuickBtn.MouseButton1Click:Connect(ResetConfig)

TargetBtn = Instance.new("TextButton")
TargetBtn.Size = UDim2.new(1, -24, 0, 34)
TargetBtn.Position = UDim2.fromOffset(12, 80)
TargetBtn.BackgroundColor3 = Theme.PanelAlt
TargetBtn.AutoButtonColor = false
TargetBtn.Text = "Target: None"
TargetBtn.Font = Theme.Font.Bold
TargetBtn.TextSize = 12
TargetBtn.TextColor3 = Theme.TextDim
TargetBtn.Parent = QuickCard
corner(TargetBtn, 8)
stroke(TargetBtn, Theme.Border, 1, 0.92)
TargetBtn.MouseButton1Click:Connect(CycleTargetMode)
UpdateTargetButtonVisual()

local TipCard = MakeCard(HomePage, UDim2.new(1, 0, 0, 40))
local TipLabel = Instance.new("TextLabel")
TipLabel.Size = UDim2.new(1, -20, 1, 0)
TipLabel.Position = UDim2.fromOffset(10, 0)
TipLabel.BackgroundTransparency = 1
TipLabel.Text = "Tip  •  Press K to minimize  •  Drag top bar to move"
TipLabel.Font = Theme.Font.Reg
TipLabel.TextSize = 11
TipLabel.TextColor3 = Theme.TextMute
TipLabel.TextXAlignment = Enum.TextXAlignment.Left
TipLabel.Parent = TipCard

-- COMBAT
local CombatPage = CreateTab("Combat", "Aimbot & combat tools", "Combat")
AddSection(CombatPage, "Aiming")
CombatToggles.AimbotGun = AddToggle(CombatPage, "Aimbot Gun", false, function(v)
	Settings.Bunny.AimbotGun = v
	Flags.AimbotGlobal = v
	InferTargetModeFromToggles()
end)
CombatToggles.AimbotSkill = AddToggle(CombatPage, "Aimbot Skill", false, function(v)
	Settings.Bunny.AimbotSkill = v
	InferTargetModeFromToggles()
end)
CombatToggles.NPCAimbot = AddToggle(CombatPage, "NPC Aimbot", false, function(v)
	Flags.AimbotNPC = v
	Settings.Bunny.TargetMode = v and "NPC" or "Player"
	InferTargetModeFromToggles()
end)
AddToggle(CombatPage, "Camlock", false, function(v)
	CameraLockData.Enabled = v
	Settings.Bunny.CameraLock = v
	if v then
		local hrp = GetBunnyTargetHRP()
		CameraLockData.Target = hrp
		if not hrp then
			Notify("Camlock", "No target found.", 2, "Error")
			CameraLockData.Enabled = false
		else
			Notify("Camlock", "Camera locked.", 2, "Success")
		end
	end
end)

AddSection(CombatPage, "Melee")
AddToggle(CombatPage, "Fast Attack (M1)", false, function(v)
	Settings.Bunny.FastAttack = v
	Flags.FastAttackEnabled = v
end)
AddSlider(CombatPage, "FA Distance", 5, 60, 10, function(v)
	Settings.Bunny.FADistance = v
	Flags.FADistance = v
end)
AddSlider(CombatPage, "Prediction", 0, 1, 0, function(v)
	Settings.Bunny.Prediction = v / 10
	Flags.PredictionAmount = v / 10
end)

-- PLAYER
local PlayerPage = CreateTab("Player", "Movement, buffs & abilities", "Player")
AddSection(PlayerPage, "Movement")
AddToggle(PlayerPage, "Walk Speed", false, function(v)
	Settings.Player.WalkSpeedEnabled = v
end)
AddSlider(PlayerPage, "Walk Speed Value", 16, 250, 16, function(v)
	Settings.Player.WalkSpeed = v
end)
AddToggle(PlayerPage, "Jump Power", false, function(v)
	Settings.Player.JumpPowerEnabled = v
end)
AddSlider(PlayerPage, "Jump Power Value", 50, 300, 50, function(v)
	Settings.Player.JumpPower = v
end)
AddToggle(PlayerPage, "Walk on Water", false, function(v)
	Settings.Bunny.WalkWater = v
	Flags.WalkWater = v
end)

AddSection(PlayerPage, "Character")
AddToggle(PlayerPage, "Anti-Stun", false, function(v)
	Settings.Bunny.AntiStun = v
	Flags.AntiStun = v
end)
AddToggle(PlayerPage, "Auto Haki (Buso)", false, function(v)
	Settings.Bunny.AutoHaki = v
end)
AddToggle(PlayerPage, "Infinite Energy", false, function(v)
	Settings.Utility.InfiniteEnergy = v
end)

AddSection(PlayerPage, "Abilities")
AddToggle(PlayerPage, "Auto Active (V3)", false, function(v)
	Settings.Bunny.AutoV3 = v
	Flags.RaceClickAutov3 = v
end)
AddToggle(PlayerPage, "Auto Active (V4)", false, function(v)
	Settings.Bunny.AutoV4 = v
	Flags.RaceClickAutov4 = v
end)

-- VISUALS
local VisualsPage = CreateTab("Visuals", "ESP & overlay", "Visuals")
AddSection(VisualsPage, "ESP")
AddToggle(VisualsPage, "Player ESP", false, function(v)
	Settings.Visuals.ESPPlayer = v
end)
AddSlider(VisualsPage, "ESP Range", 100, 5000, 500, function(v)
	Settings.Bunny.ESPRange = v
end)

-- SETTINGS
local SettingsPage = CreateTab("Settings", "Preferences & safety", "Settings")
AddSection(SettingsPage, "Session")
local SessionLabel = AddLabelStat(SettingsPage, "Session Time: 00:00:00")
task.spawn(function()
	while task.wait(1) do
		local t = os.clock() - SessionStart
		local h = mathFloor(t / 3600)
		local m = mathFloor((t % 3600) / 60)
		local s = mathFloor(t % 60)
		pcall(function()
			SessionLabel.Text = string.format("Session Time: %02d:%02d:%02d", h, m, s)
		end)
	end
end)

AddSection(SettingsPage, "Preferences")
AddToggle(SettingsPage, "Anti-AFK", true, function(v)
	Settings.Utility.AntiAFK = v
end)
AddToggle(SettingsPage, "Notifications", true, function(v)
	Settings.Utility.Notifications = v
end)
AddToggle(SettingsPage, "Hide User Info", false, function(v)
	Settings.Utility.HideUserInfo = v
	UpdateWelcomeText()
end)

AddSection(SettingsPage, "Protection")
AddToggle(SettingsPage, "Anti Admin", false, function(v)
	Settings.Utility.AntiAdmin = v
	if v then
		Notify("Anti Admin", "Enabled.", 2, "Success")
	end
end)

AddSection(SettingsPage, "Actions")
AddButton(SettingsPage, "Join Low Ping Server", "Hop", JoinLowPingServer, false)
AddButton(SettingsPage, "Panic Button", "Panic", PanicDisableAll, true)

--------------------------------------------------------------------------------
-- METATABLE HOOKS
--------------------------------------------------------------------------------
pcall(function()
	if not getrawmetatable or not setreadonly then
		return
	end
	local Mouse = LocalPlayer:GetMouse()
	local _raw = getrawmetatable(game)
	local _origNC = _raw.__namecall
	local _origIndex = _raw.__index
	setreadonly(_raw, false)

	_raw.__index = newcclosure(function(t, k)
		if Flags.AimEnabled and not checkcaller() and t == Mouse then
			if k == "Hit" then
				local pos = aimTable.currentAim or npcAimTable.currentNPCAim
				if pos then
					return CFrame.new(pos)
				end
			elseif k == "Target" then
				local hrp = GetBunnyTargetHRP()
				if hrp then
					return hrp
				end
			end
		end
		return _origIndex(t, k)
	end)

	_raw.__namecall = newcclosure(function(self, ...)
		local method = getnamecallmethod()
		local args = { ... }

		if Flags.AimbotGlobal and aimTable.currentAim and (method == "FireServer" or method == "InvokeServer") then
			for i, v in pairs(args) do
				if typeof(v) == "Vector3" then
					args[i] = aimTable.currentAim
				end
			end
			return _origNC(self, unpack(args))
		end

		if Flags.AimbotNPC and npcAimTable.currentNPCAim and (method == "FireServer" or method == "InvokeServer") then
			for i, v in pairs(args) do
				if typeof(v) == "Vector3" then
					args[i] = npcAimTable.currentNPCAim
				end
			end
			return _origNC(self, unpack(args))
		end

		return _origNC(self, unpack(args))
	end)

	setreadonly(_raw, true)
end)

--------------------------------------------------------------------------------
-- FAST ATTACK
--------------------------------------------------------------------------------
local attackState = {
	Debounce = 0,
	ComboDebounce = 0,
	M1Combo = 1,

	GetBladeHits = function(self, character, maxDistance)
		local origin = character:GetPivot().Position
		local hits = {}
		local function scanFolder(folder)
			if not folder then
				return
			end
			for _, model in ipairs(folder:GetChildren()) do
				if model ~= character and model:FindFirstChild("Humanoid") and model.Humanoid.Health > 0 then
					local root = model:FindFirstChild("HumanoidRootPart")
					if root and (origin - root.Position).Magnitude <= maxDistance then
						table.insert(hits, { model, root })
					end
				end
			end
		end
		scanFolder(workspace:FindFirstChild("Enemies"))
		scanFolder(workspace:FindFirstChild("Characters"))
		return hits
	end,

	UseFruitM1 = function(self, character, tool, combo, hits)
		local remote = tool:FindFirstChild("LeftClickRemote")
		if remote then
			local dir = hits[1] and (hits[1][1].HumanoidRootPart.Position - character:GetPivot().Position).Unit or Vector3.new(0, 0, 1)
			pcall(function()
				remote:FireServer(dir, combo)
			end)
		end
	end,

	Attack = function(self)
		if (tick() - self.Debounce) < 0.01 then
			return
		end
		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("Humanoid") then
			return
		end
		local tool = character:FindFirstChildOfClass("Tool")
		if not tool then
			return
		end

		local tooltip = tool.ToolTip
		local hits = self:GetBladeHits(character, Flags.FADistance)

		if #hits > 0 then
			if (tick() - self.ComboDebounce) > 0.5 then
				self.M1Combo = 1
			else
				self.M1Combo = self.M1Combo >= 3 and 1 or self.M1Combo + 1
			end
			self.ComboDebounce = tick()

			local net = ReplicatedStorage:FindFirstChild("Modules") and ReplicatedStorage.Modules:FindFirstChild("Net")

			if tooltip == "Blox Fruit" and tool:FindFirstChild("LeftClickRemote") then
				self:UseFruitM1(character, tool, self.M1Combo, hits)
			elseif net and (tooltip == "Melee" or tooltip == "Sword") then
				pcall(function()
					net:FindFirstChild("RE/RegisterAttack"):FireServer(0.1)
				end)
				pcall(function()
					net:FindFirstChild("RE/RegisterHit"):FireServer(hits[1][2], hits)
				end)
			end

			self.Debounce = tick()
		end
	end,
}

--------------------------------------------------------------------------------
-- CORE LOOPS
--------------------------------------------------------------------------------
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			local function scan(c)
				for _, v in pairs(c:GetChildren()) do
					if v:IsA("Tool") and v:FindFirstChild("RemoteFunctionShoot") then
						SelectWeaponGun = v.Name
					end
				end
			end
			scan(LocalPlayer.Backpack)
			if LocalPlayer.Character then
				scan(LocalPlayer.Character)
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if not Settings.Bunny.AutoHaki then
				return
			end
			local char = LocalPlayer.Character
			if char and not char:FindFirstChild("HasBuso") then
				ReplicatedStorage.Remotes.CommF_:InvokeServer("Buso")
			end
		end)
	end
end)

local lastWalkWater = nil
task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if Flags.WalkWater ~= lastWalkWater then
				lastWalkWater = Flags.WalkWater
				if Flags.WalkWater then
					game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 112, 1000)
				else
					game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 80, 1000)
				end
			end
		end)
	end
end)

task.spawn(function()
	while true do
		if Flags.FastAttackEnabled then
			pcall(function()
				attackState:Attack()
			end)
			task.wait(0)
		else
			task.wait(0.1)
		end
	end
end)

task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			if Flags.RaceClickAutov3 then
				repeat
					ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
					task.wait(30)
				until not Flags.RaceClickAutov3
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			if Flags.RaceClickAutov4 then
				local char = LocalPlayer.Character
				if char and char:FindFirstChild("RaceEnergy") then
					if char.RaceEnergy.Value == 1 then
						VirtualInputManager:SendKeyEvent(true, "Y", false, game)
						VirtualInputManager:SendKeyEvent(false, "Y", false, game)
					end
				end
			end
		end)
	end
end)

RunService.Heartbeat:Connect(function()
	if Settings.Bunny.AimbotGun then
		local hrp = GetBunnyTargetHRP()
		if hrp and LocalPlayer.Character then
			local gun = SelectWeaponGun ~= "" and LocalPlayer.Character:FindFirstChild(SelectWeaponGun)
			if gun and gun:FindFirstChild("RemoteFunctionShoot") then
				pcall(function()
					gun.RemoteFunctionShoot:InvokeServer(hrp.Position, hrp)
				end)
			end
		end
	end
end)

local lastTargetUpdate = 0
RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	if not myChar then return end
	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	local myHum = myChar:FindFirstChildOfClass("Humanoid")

	if myHum then
		if Settings.Player.WalkSpeedEnabled then
			myHum.WalkSpeed = Settings.Player.WalkSpeed
		end
		if Settings.Player.JumpPowerEnabled then
			myHum.JumpPower = Settings.Player.JumpPower
		end
	end

	-- Throttle target scanning to 20x/sec instead of 60x/sec
	local now = tick()
	if now - lastTargetUpdate >= 0.05 then
		lastTargetUpdate = now

		if Flags.AimEnabled then
			local hrp = GetNearestBunnyPlayer()
			if hrp then
				aimTable.currentAim = hrp.Position + (hrp.Velocity * Flags.PredictionAmount)
			else
				aimTable.currentAim = nil
			end
		end

		if Flags.AimbotNPC then
			local npc = GetNearestBunnyNPC()
			if npc then
				local root = npc:FindFirstChild("HumanoidRootPart")
				local hum = npc:FindFirstChildOfClass("Humanoid")
				if root and hum then
					if hum.WalkSpeed >= 5 then
						npcAimTable.currentNPCAim = root.Position + (root.Velocity * Flags.PredictionAmount)
					else
						npcAimTable.currentNPCAim = root.Position
					end
					MarkerPart.Transparency = 0.4
					MarkerPart.CFrame = CFrame.new(npcAimTable.currentNPCAim)
				end
			else
				npcAimTable.currentNPCAim = nil
				MarkerPart.Transparency = 1
			end
		else
			npcAimTable.currentNPCAim = nil
			MarkerPart.Transparency = 1
		end
	end

	if Flags.AntiStun and myHRP and myHum and myHum.MoveDirection.Magnitude > 0 then
		myHRP.CFrame = myHRP.CFrame + myHum.MoveDirection.Unit * 0.8
	end

	if CameraLockData.Enabled then
		local tgt = CameraLockData.Target
		if tgt and tgt.Parent then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, tgt.Position + (tgt.Velocity * Flags.PredictionAmount))
		else
			CameraLockData.Enabled = false
			CameraLockData.Target = nil
			Notify("Camlock", "Target lost.", 2, "Error")
		end
	end
end)

local espWasOn = false
task.spawn(function()
	while task.wait(1) do
		if Settings.Visuals.ESPPlayer then
			espWasOn = true
			local myChar = LocalPlayer.Character
			local myHead = myChar and myChar:FindFirstChild("Head")
			for _, v in pairs(Players:GetPlayers()) do
				pcall(function()
					if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") then
						if not v.Character.Head:FindFirstChild("EspPlayer" .. Number) then
							local bill = Instance.new("BillboardGui")
							bill.Name = "EspPlayer" .. Number
							bill.ExtentsOffset = Vector3.new(0, 1, 0)
							bill.Size = UDim2.new(1, 200, 1, 30)
							bill.Adornee = v.Character.Head
							bill.AlwaysOnTop = true
							bill.Parent = v.Character.Head

							local nameL = Instance.new("TextLabel")
							nameL.Font = Enum.Font.GothamSemibold
							nameL.TextSize = 14
							nameL.TextWrapped = true
							nameL.Size = UDim2.new(1, 0, 1, 0)
							nameL.TextYAlignment = Enum.TextYAlignment.Top
							nameL.BackgroundTransparency = 1
							nameL.TextStrokeTransparency = 0.5

							if v.Team == LocalPlayer.Team then
								nameL.TextColor3 = Theme.AccentSoft
							else
								nameL.TextColor3 = Theme.Danger
							end
							nameL.Parent = bill
						end
						local esp = v.Character.Head:FindFirstChild("EspPlayer" .. Number)
						if esp and myHead then
							local dist = round((myHead.Position - v.Character.Head.Position).Magnitude / 3)
							local health = round(v.Character.Humanoid.Health * 100 / v.Character.Humanoid.MaxHealth)
							esp.TextLabel.Text = v.Name .. " | " .. dist .. "m\nHealth: " .. health .. "%"
						end
					end
				end)
			end
		elseif espWasOn then
			-- Only clean up when ESP was previously on
			espWasOn = false
			for _, v in pairs(Players:GetPlayers()) do
				pcall(function()
					if v.Character and v.Character:FindFirstChild("Head") then
						local esp = v.Character.Head:FindFirstChild("EspPlayer" .. Number)
						if esp then
							esp:Destroy()
						end
					end
				end)
			end
		end
	end
end)

local stamConn = nil
local function setupInfiniteStam(char)
	if stamConn then
		stamConn:Disconnect()
		stamConn = nil
	end
	local energy = char and char:FindFirstChild("Energy")
	if not energy then return end
	originalStam = energy.Value
	stamConn = energy.Changed:Connect(function()
		if Settings.Utility.InfiniteEnergy then
			energy.Value = originalStam
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Energy", 10)
	setupInfiniteStam(char)
end)

if LocalPlayer.Character then
	setupInfiniteStam(LocalPlayer.Character)
end

LocalPlayer.Idled:Connect(function()
	if Settings.Utility.AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end
end)

ApplyTargetMode("None", false)
Notify("Bunny Hub", "Loaded. Press K to toggle.", 4, "Success")
