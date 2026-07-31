--!strict
--[[
	Bunny Hub (Fixed)
	Tabs: Home, Combat, Player, Visuals, Settings
	Anti Detection removed (executor crash risk)
	Fixed corrupted middle section + completed UI
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
_G.AimbotGlobal = false
_G.AimbotNPC = false
_G.AimEnabled = true
_G.AntiStun = false
_G.FastAttackEnabled = false
_G.FADistance = 10
_G.PredictionAmount = 0.1
_G.RaceClickAutov3 = false
_G.RaceClickAutov4 = false
_G.WalkWater = false

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
local HiddenGuiGetter = get_hidden_gui or gethui

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
-- SERVER HOP
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
			pages = pages + 1
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
-- ANTI ADMIN
--------------------------------------------------------------------------------
local adminHopDebounce = false
task.spawn(function()
	while task.wait(0.75) do
		if Settings.Utility.AntiAdmin then
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
-- SIDEBAR + CONTENT
--------------------------------------------------------------------------------
local Body = Instance.new("Frame")
Body.Name = "Body"
Body.Size = UDim2.new(1, 0, 1, -TITLEBAR_H)
Body.Position = UDim2.new(0, 0, 0, TITLEBAR_H)
Body.BackgroundTransparency = 1
Body.Parent = Main

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, 0)
Sidebar.BackgroundColor3 = Theme.BgDeep
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Body

local SidebarLine = Instance.new("Frame")
SidebarLine.Size = UDim2.new(0, 1, 1, 0)
SidebarLine.Position = UDim2.new(1, -1, 0, 0)
SidebarLine.BackgroundColor3 = Theme.Border
SidebarLine.BackgroundTransparency = 0.93
SidebarLine.BorderSizePixel = 0
SidebarLine.Parent = Sidebar

local SidebarList = Instance.new("UIListLayout")
SidebarList.Padding = UDim.new(0, 6)
SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
SidebarList.SortOrder = Enum.SortOrder.LayoutOrder
SidebarList.Parent = Sidebar

pad(Sidebar, 12, 12, 0, 0)

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -SIDEBAR_W, 1, 0)
Content.Position = UDim2.new(0, SIDEBAR_W, 0, 0)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.Parent = Body

local Pages = {}
local CurrentPage = nil
local TabButtons = {}

local function SetPage(name)
	for n, page in pairs(Pages) do
		page.Visible = (n == name)
	end
	for n, btn in pairs(TabButtons) do
		local active = (n == name)
		tween(btn, {
			BackgroundColor3 = active and Theme.PanelActive or Theme.Panel,
		}, Theme.Anim.Fast)
		local icon = btn:FindFirstChild("Icon")
		if icon then
			icon.ImageColor3 = active and Theme.AccentSoft or Theme.TextDim
		end
	end
	CurrentPage = name
end

local function CreateTabButton(name, iconId, order)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.fromOffset(SIDEBAR_W - 16, SIDEBAR_W - 16)
	btn.BackgroundColor3 = Theme.Panel
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.LayoutOrder = order
	btn.Parent = Sidebar
	corner(btn, 12)
	stroke(btn, Theme.Border, 1, 0.93)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.fromOffset(22, 22)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.BackgroundTransparency = 1
	icon.Image = iconId
	icon.ImageColor3 = Theme.TextDim
	icon.Parent = btn

	btn.MouseEnter:Connect(function()
		if CurrentPage ~= name then
			tween(btn, { BackgroundColor3 = Theme.PanelHover }, Theme.Anim.Fast)
		end
	end)
	btn.MouseLeave:Connect(function()
		if CurrentPage ~= name then
			tween(btn, { BackgroundColor3 = Theme.Panel }, Theme.Anim.Fast)
		end
	end)
	btn.MouseButton1Click:Connect(function()
		SetPage(name)
	end)

	TabButtons[name] = btn
	return btn
end

local function CreatePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.new(1, 0, 1, 0)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Theme.Accent
	page.CanvasSize = UDim2.new(0, 0, 0, 0)
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.Parent = Content

	pad(page, 14, 20, 14, 14)
	list(page, Enum.FillDirection.Vertical, 10)

	Pages[name] = page
	return page
end

CreateTabButton("Home", Theme.Icons.Home, 1)
CreateTabButton("Combat", Theme.Icons.Combat, 2)
CreateTabButton("Player", Theme.Icons.Player, 3)
CreateTabButton("Visuals", Theme.Icons.Visuals, 4)
CreateTabButton("Settings", Theme.Icons.Settings, 5)

local HomePage = CreatePage("Home")
local CombatPage = CreatePage("Combat")
local PlayerPage = CreatePage("Player")
local VisualsPage = CreatePage("Visuals")
local SettingsPage = CreatePage("Settings")

SetPage("Home")

--------------------------------------------------------------------------------
-- UI COMPONENTS
--------------------------------------------------------------------------------
local function AddSection(parent, title)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 22)
	lbl.BackgroundTransparency = 1
	lbl.Text = string.upper(title)
	lbl.Font = Theme.Font.Med
	lbl.TextSize = 12
	lbl.TextColor3 = Theme.TextMute
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = parent
	return lbl
end

local function AddCard(parent)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = Theme.Panel
	card.BorderSizePixel = 0
	card.Parent = parent
	corner(card, Theme.Radius.Card)
	stroke(card, Theme.Border, 1, 0.94)
	list(card, Enum.FillDirection.Vertical, 0)
	pad(card, 4, 4, 0, 0)
	return card
end

local function AddToggle(parent, title, desc, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, desc and 58 or 44)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(1, -70, 0, 18)
	titleL.Position = UDim2.new(0, 14, 0, desc and 8 or 13)
	titleL.BackgroundTransparency = 1
	titleL.Text = title
	titleL.Font = Theme.Font.Med
	titleL.TextSize = 14
	titleL.TextColor3 = Theme.Text
	titleL.TextXAlignment = Enum.TextXAlignment.Left
	titleL.Parent = row

	if desc then
		local d = Instance.new("TextLabel")
		d.Size = UDim2.new(1, -70, 0, 16)
		d.Position = UDim2.new(0, 14, 0, 28)
		d.BackgroundTransparency = 1
		d.Text = desc
		d.Font = Theme.Font.Reg
		d.TextSize = 11
		d.TextColor3 = Theme.TextDim
		d.TextXAlignment = Enum.TextXAlignment.Left
		d.Parent = row
	end

	local track = Instance.new("Frame")
	track.Size = UDim2.fromOffset(42, 24)
	track.Position = UDim2.new(1, -56, 0.5, -12)
	track.BackgroundColor3 = default and Theme.Accent or Theme.TrackOff
	track.Parent = row
	corner(track, 12)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(18, 18)
	knob.Position = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
	knob.BackgroundColor3 = Theme.White
	knob.Parent = track
	corner(knob, 9)

	local state = default
	local hit = Instance.new("TextButton")
	hit.Size = UDim2.new(1, 0, 1, 0)
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.Parent = row

	hit.MouseButton1Click:Connect(function()
		state = not state
		tween(track, { BackgroundColor3 = state and Theme.Accent or Theme.TrackOff }, 0.15)
		tween(knob, { Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.15)
		if callback then
			callback(state)
		end
	end)

	return {
		Set = function(v)
			state = v
			track.BackgroundColor3 = v and Theme.Accent or Theme.TrackOff
			knob.Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
			if callback then
				callback(v)
			end
		end,
		Get = function()
			return state
		end,
	}
end

local function AddSlider(parent, title, min, max, default, callback)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 60)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local titleL = Instance.new("TextLabel")
	titleL.Size = UDim2.new(0.7, 0, 0, 18)
	titleL.Position = UDim2.new(0, 14, 0, 8)
	titleL.BackgroundTransparency = 1
	titleL.Text = title
	titleL.Font = Theme.Font.Med
	titleL.TextSize = 14
	titleL.TextColor3 = Theme.Text
	titleL.TextXAlignment = Enum.TextXAlignment.Left
	titleL.Parent = row

	local valueL = Instance.new("TextLabel")
	valueL.Size = UDim2.new(0.3, -14, 0, 18)
	valueL.Position = UDim2.new(0.7, 0, 0, 8)
	valueL.BackgroundTransparency = 1
	valueL.Text = tostring(default)
	valueL.Font = Theme.Font.Med
	valueL.TextSize = 13
	valueL.TextColor3 = Theme.AccentSoft
	valueL.TextXAlignment = Enum.TextXAlignment.Right
	valueL.Parent = row

	local track = Instance.new("Frame")
	track.Size = UDim2.new(1, -28, 0, 4)
	track.Position = UDim2.new(0, 14, 0, 40)
	track.BackgroundColor3 = Theme.TrackBg
	track.Parent = row
	corner(track, 2)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Theme.Accent
	fill.Parent = track
	corner(fill, 2)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(16, 16)
	knob.Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8)
	knob.BackgroundColor3 = Theme.White
	knob.ZIndex = 2
	knob.Parent = track
	corner(knob, 8)

	local value = default
	local dragging = false

	local function update(val, fire)
		val = math.clamp(val, min, max)
		value = val
		local alpha = (val - min) / (max - min)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -8, 0.5, -8)
		valueL.Text = tostring(round(val))
		if fire and callback then
			callback(val)
		end
	end

	local function inputToValue(input)
		local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		return min + math.clamp(rel, 0, 1) * (max - min)
	end

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(inputToValue(input), true)
		end
	end)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			update(inputToValue(input), true)
			dragging = true
		end
	end)

	return {
		Set = function(v)
			update(v, false)
		end,
		Get = function()
			return value
		end,
	}
end

local function AddButton(parent, title, callback)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -16, 0, 36)
	btn.Position = UDim2.new(0, 8, 0, 0)
	btn.BackgroundColor3 = Theme.PanelAlt
	btn.AutoButtonColor = false
	btn.Text = title
	btn.Font = Theme.Font.Med
	btn.TextSize = 13
	btn.TextColor3 = Theme.Text
	btn.Parent = parent
	corner(btn, 8)

	btn.MouseEnter:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.PanelHover }, Theme.Anim.Fast)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, { BackgroundColor3 = Theme.PanelAlt }, Theme.Anim.Fast)
	end)
	btn.MouseButton1Click:Connect(function()
		if callback then
			callback()
		end
	end)
	return btn
end

--------------------------------------------------------------------------------
-- POPULATE PAGES
--------------------------------------------------------------------------------
AddSection(HomePage, "Welcome")
local welcomeCard = AddCard(HomePage)
local welcomeRow = Instance.new("Frame")
welcomeRow.Size = UDim2.new(1, 0, 0, 50)
welcomeRow.BackgroundTransparency = 1
welcomeRow.Parent = welcomeCard

local welcomeTitle = Instance.new("TextLabel")
welcomeTitle.Size = UDim2.new(1, -20, 0, 20)
welcomeTitle.Position = UDim2.new(0, 14, 0, 8)
welcomeTitle.BackgroundTransparency = 1
welcomeTitle.Font = Theme.Font.Bold
welcomeTitle.TextSize = 15
welcomeTitle.TextColor3 = Theme.Text
welcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
welcomeTitle.Parent = welcomeRow

local function UpdateWelcomeText()
	if Settings.Utility.HideUserInfo then
		welcomeTitle.Text = "Welcome back, Player!"
	else
		welcomeTitle.Text = "Welcome back, " .. LocalPlayer.Name .. "!"
	end
end
UpdateWelcomeText()

local welcomeSub = Instance.new("TextLabel")
welcomeSub.Size = UDim2.new(1, -20, 0, 16)
welcomeSub.Position = UDim2.new(0, 14, 0, 28)
welcomeSub.BackgroundTransparency = 1
welcomeSub.Text = "Session started • " .. os.date("%I:%M %p")
welcomeSub.Font = Theme.Font.Reg
welcomeSub.TextSize = 12
welcomeSub.TextColor3 = Theme.AccentSoft
welcomeSub.TextXAlignment = Enum.TextXAlignment.Left
welcomeSub.Parent = welcomeRow

AddSection(HomePage, "Quick Actions")
local quickCard = AddCard(HomePage)
AddButton(quickCard, "Join Low Ping Server", JoinLowPingServer)
AddButton(quickCard, "Reset Config", function()
	Notify("Config Reset", "Settings restored to default.", 3, "Success")
end)

AddSection(CombatPage, "Aimbot")
local combatCard1 = AddCard(CombatPage)
AddToggle(combatCard1, "Aimbot Gun", "Auto-aims equipped firearm at target", false, function(v)
	Settings.Bunny.AimbotGun = v
	_G.AimbotGlobal = v
end)
AddToggle(combatCard1, "Aimbot Skill", "Assists skill targeting", false, function(v)
	Settings.Bunny.AimbotSkill = v
end)
AddToggle(combatCard1, "NPC Aimbot", "Locks aim to nearest NPC", false, function(v)
	_G.AimbotNPC = v
	Settings.Bunny.TargetMode = v and "NPC" or "Player"
end)
AddToggle(combatCard1, "Camera Lock", "Locks camera to current target", false, function(v)
	CameraLockData.Enabled = v
	Settings.Bunny.CameraLock = v
	if v then
		local hrp = GetBunnyTargetHRP()
		CameraLockData.Target = hrp
		if not hrp then
			Notify("Camera Lock", "No target found.", 2, "Error")
			CameraLockData.Enabled = false
		else
			Notify("Camera Lock", "Camera locked to target.", 2, "Success")
		end
	end
end)

AddSection(CombatPage, "Combat")
local combatCard2 = AddCard(CombatPage)
AddToggle(combatCard2, "Fast Attack (M1)", "Automatic melee attack loop", false, function(v)
	Settings.Bunny.FastAttack = v
	_G.FastAttackEnabled = v
end)
AddSlider(combatCard2, "FA Distance", 5, 60, 10, function(v)
	Settings.Bunny.FADistance = v
	_G.FADistance = v
end)
AddSlider(combatCard2, "Prediction", 0, 1, 0.1, function(v)
	Settings.Bunny.Prediction = v
	_G.PredictionAmount = v
end)

AddSection(CombatPage, "Race")
local combatCard3 = AddCard(CombatPage)
AddToggle(combatCard3, "Auto Active (V3)", "Automatically triggers ability every 30s", false, function(v)
	Settings.Bunny.AutoV3 = v
	_G.RaceClickAutov3 = v
end)
AddToggle(combatCard3, "Auto Active (V4)", "Auto-presses activation key when energy is ready", false, function(v)
	Settings.Bunny.AutoV4 = v
	_G.RaceClickAutov4 = v
end)

AddSection(PlayerPage, "Movement")
local playerCard1 = AddCard(PlayerPage)
AddToggle(playerCard1, "Walk Speed", "Override default walk speed", false, function(v)
	Settings.Player.WalkSpeedEnabled = v
end)
AddSlider(playerCard1, "Walk Speed Value", 16, 250, 16, function(v)
	Settings.Player.WalkSpeed = v
end)
AddToggle(playerCard1, "Jump Power", "Override default jump power", false, function(v)
	Settings.Player.JumpPowerEnabled = v
end)
AddSlider(playerCard1, "Jump Power Value", 50, 300, 50, function(v)
	Settings.Player.JumpPower = v
end)

AddSection(PlayerPage, "Buffs")
local playerCard2 = AddCard(PlayerPage)
AddToggle(playerCard2, "Anti-Stun", "Pushes character through stuns", false, function(v)
	Settings.Bunny.AntiStun = v
	_G.AntiStun = v
end)
AddToggle(playerCard2, "Auto Haki (Buso)", "Auto-activates armament haki", false, function(v)
	Settings.Bunny.AutoHaki = v
end)
AddToggle(playerCard2, "Walk on Water", "Raises water collision plane", false, function(v)
	Settings.Bunny.WalkWater = v
	_G.WalkWater = v
end)

AddSection(VisualsPage, "ESP")
local visualsCard = AddCard(VisualsPage)
AddToggle(visualsCard, "Player ESP", "Shows name, distance & health", false, function(v)
	Settings.Visuals.ESPPlayer = v
end)
AddSlider(visualsCard, "ESP Range", 100, 5000, 500, function(v)
	Settings.Bunny.ESPRange = v
end)

AddSection(SettingsPage, "Utility")
local utilCard = AddCard(SettingsPage)
AddToggle(utilCard, "Infinite Energy", "Keeps stamina/energy topped up", false, function(v)
	Settings.Utility.InfiniteEnergy = v
end)
AddToggle(utilCard, "Anti-AFK", "Prevents being kicked for inactivity", true, function(v)
	Settings.Utility.AntiAFK = v
end)
AddToggle(utilCard, "Notifications", "Toggles in-game notification popups", true, function(v)
	Settings.Utility.Notifications = v
end)
AddToggle(utilCard, "Hide User Info", "Hides your name from the Home tab", false, function(v)
	Settings.Utility.HideUserInfo = v
	UpdateWelcomeText()
end)
AddToggle(utilCard, "Anti Admin", "Auto hop when high level player joins", false, function(v)
	Settings.Utility.AntiAdmin = v
end)

AddSection(SettingsPage, "Session")
local secCard = AddCard(SettingsPage)
local sessionLabel = Instance.new("TextLabel")
sessionLabel.Size = UDim2.new(1, -20, 0, 30)
sessionLabel.Position = UDim2.new(0, 14, 0, 6)
sessionLabel.BackgroundTransparency = 1
sessionLabel.Text = "Session Time: 00:00:00"
sessionLabel.Font = Theme.Font.Med
sessionLabel.TextSize = 13
sessionLabel.TextColor3 = Theme.TextDim
sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
sessionLabel.Parent = secCard

task.spawn(function()
	while task.wait(1) do
		local t = os.clock() - SessionStart
		local h = mathFloor(t / 3600)
		local m = mathFloor((t % 3600) / 60)
		local s = mathFloor(t % 60)
		pcall(function()
			sessionLabel.Text = string.format("Session Time: %02d:%02d:%02d", h, m, s)
		end)
	end
end)

AddButton(secCard, "Join Low Ping Server", JoinLowPingServer)
AddButton(secCard, "Panic (Disable All)", function()
	_G.AimbotGlobal = false
	_G.AimbotNPC = false
	_G.AntiStun = false
	_G.FastAttackEnabled = false
	_G.RaceClickAutov3 = false
	_G.RaceClickAutov4 = false
	CameraLockData.Enabled = false
	Notify("Panic", "All features disabled.", 3, "Error")
end)

--------------------------------------------------------------------------------
-- MINIMIZE / TOGGLE / DRAG
--------------------------------------------------------------------------------
local isOpen = true
local minimized = false

local function CollapseToIcon()
	minimized = true
	tween(Main, { Size = UDim2.fromOffset(56, 56) }, 0.25)
	Body.Visible = false
	TopBar.Visible = false
end

local function ExpandFromIcon()
	minimized = false
	Body.Visible = true
	TopBar.Visible = true
	tween(Main, { Size = expandedSize }, 0.3)
end

MinBtn.MouseButton1Click:Connect(function()
	if minimized then
		ExpandFromIcon()
	else
		CollapseToIcon()
	end
end)

local dragging = false
local dragStart, startPos

TopBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = Main.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.K then
		isOpen = not isOpen
		Main.Visible = isOpen
	end
end)

--------------------------------------------------------------------------------
-- FEATURE LOGIC (unchanged)
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
		if _G.AimEnabled and not checkcaller() and t == Mouse then
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

		if _G.AimbotGlobal and aimTable.currentAim and (method == "FireServer" or method == "InvokeServer") then
			for i, v in pairs(args) do
				if typeof(v) == "Vector3" then
					args[i] = aimTable.currentAim
				end
			end
			return _origNC(self, unpack(args))
		end

		if _G.AimbotNPC and npcAimTable.currentNPCAim and (method == "FireServer" or method == "InvokeServer") then
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
		local hits = self:GetBladeHits(character, _G.FADistance)

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

task.spawn(function()
	while task.wait(0.5) do
		pcall(function()
			if _G.WalkWater then
				game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 112, 1000)
			else
				game:GetService("Workspace").Map["WaterBase-Plane"].Size = Vector3.new(1000, 80, 1000)
			end
		end)
	end
end)

task.spawn(function()
	while true do
		if _G.FastAttackEnabled then
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
			if _G.RaceClickAutov3 then
				repeat
					ReplicatedStorage.Remotes.CommE:FireServer("ActivateAbility")
					task.wait(30)
				until not _G.RaceClickAutov3
			end
		end)
	end
end)

task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			if _G.RaceClickAutov4 then
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

RunService.RenderStepped:Connect(function()
	local myChar = LocalPlayer.Character
	local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
	local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

	if myHum then
		if Settings.Player.WalkSpeedEnabled then
			myHum.WalkSpeed = Settings.Player.WalkSpeed
		end
		if Settings.Player.JumpPowerEnabled then
			myHum.JumpPower = Settings.Player.JumpPower
		end
	end

	if _G.AimEnabled then
		local hrp = GetNearestBunnyPlayer()
		if hrp then
			aimTable.currentAim = hrp.Position + (hrp.Velocity * _G.PredictionAmount)
		else
			aimTable.currentAim = nil
		end
	end

	if _G.AimbotNPC then
		local npc = GetNearestBunnyNPC()
		if npc then
			local root = npc:FindFirstChild("HumanoidRootPart")
			local hum = npc:FindFirstChildOfClass("Humanoid")
			if root and hum then
				if hum.WalkSpeed >= 5 then
					npcAimTable.currentNPCAim = root.Position + (root.Velocity * _G.PredictionAmount)
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

	if _G.AntiStun and myHRP and myHum and myHum.MoveDirection.Magnitude > 0 then
		myHRP.CFrame = myHRP.CFrame + myHum.MoveDirection.Unit * 0.8
	end

	if CameraLockData.Enabled then
		local tgt = CameraLockData.Target
		if tgt and tgt.Parent then
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, tgt.Position + (tgt.Velocity * _G.PredictionAmount))
		else
			CameraLockData.Enabled = false
			CameraLockData.Target = nil
			Notify("Camera Lock", "Target lost, camera unlocked.", 2, "Error")
		end
	end
end)

task.spawn(function()
	while task.wait(1) do
		if Settings.Visuals.ESPPlayer then
			for _, v in pairs(Players:GetChildren()) do
				pcall(function()
					if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("Head") and v.Character:FindFirstChild("Humanoid") then
						if not v.Character.Head:FindFirstChild("EspPlayer" .. Number) then
							local bill = Instance.new("BillboardGui", v.Character.Head)
							bill.Name = "EspPlayer" .. Number
							bill.ExtentsOffset = Vector3.new(0, 1, 0)
							bill.Size = UDim2.new(1, 200, 1, 30)
							bill.Adornee = v.Character.Head
							bill.AlwaysOnTop = true

							local nameL = Instance.new("TextLabel", bill)
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
								nameL.TextColor3 = Color3.fromRGB(255, 90, 90)
							end
						end
						local esp = v.Character.Head:FindFirstChild("EspPlayer" .. Number)
						if esp then
							local dist = round((LocalPlayer.Character.Head.Position - v.Character.Head.Position).Magnitude / 3)
							local health = round(v.Character.Humanoid.Health * 100 / v.Character.Humanoid.MaxHealth)
							esp.TextLabel.Text = v.Name .. " | " .. dist .. "m\nHealth: " .. health .. "%"
						end
					end
				end)
			end
		else
			for _, v in pairs(Players:GetChildren()) do
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

function infiniteStam()
	if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("Energy") then
		return
	end
	LocalPlayer.Character.Energy.Changed:Connect(function()
		if Settings.Utility.InfiniteEnergy then
			LocalPlayer.Character.Energy.Value = originalStam
		end
	end)
end

task.spawn(function()
	pcall(function()
		while task.wait(0.1) do
			if Settings.Utility.InfiniteEnergy and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Energy") then
				originalStam = LocalPlayer.Character.Energy.Value
				infiniteStam()
			end
		end
	end)
end)

LocalPlayer.Idled:Connect(function()
	if Settings.Utility.AntiAFK then
		VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		task.wait(1)
		VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	end
end)

Notify("Bunny Hub", "Loaded successfully. Press K to toggle.", 4, "Success")
