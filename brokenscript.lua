--[[

Sync
v.1.5.0

]]

-- Configuration
local TEST_VERIFIED = true -- Set to true to bypass verification for testing

-- Compatibility Layer: Ignore missing functions
if not getgenv then
	function getgenv() return _G end
end

if not isfolder then
	function isfolder(path) return false end
end

if not makefolder then
	function makefolder(path) end
end

if not isfile then
	function isfile(path) return false end
end

if not readfile then
	function readfile(path) return "" end
end

if not writefile then
	function writefile(path, content) end
end

if not identifyexecutor then
	function identifyexecutor() return "Unknown" end
end

if not setclipboard then
	function setclipboard(text) end
end

local function UrlEncode(str)
	if not str then return "" end
	str = tostring(str)
	if string.gsub then
		return (string.gsub(str, "[^%w _~%.%-]", function (c)
			return string.format("%%%02X", string.byte(c))
		end):gsub(" ", "+"))
	end
	return str
end

local function SafeHttpGet(url, cache)
	local s, res = pcall(function()
		return game:HttpGet(url, cache)
	end)
	if s then return res end
	return ""
end

if getgenv().SyncExecuted then
	local localplr = game.Players.LocalPlayer
	local gui = localplr:WaitForChild("PlayerGui")

	local notifscreen = gui:FindFirstChild("SyncNotifications")
	if not notifscreen then
		notifscreen = Instance.new("ScreenGui")
		notifscreen.Name = "SyncNotifications"
		notifscreen.ResetOnSpawn = false
		notifscreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		notifscreen.DisplayOrder = 999
		notifscreen.Parent = gui
	end

	local container = Instance.new("Frame")
	container.Name = "Notification"
	container.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	container.BorderSizePixel = 0
	container.Size = UDim2.new(0, 300, 0, 80)
	container.Position = UDim2.new(0, -320, 0, 10)
	container.Parent = notifscreen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.Text = "Sync"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	local sep = Instance.new("Frame")
	sep.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
	sep.BorderSizePixel = 0
	sep.Size = UDim2.new(1, -20, 0, 2)
	sep.Position = UDim2.new(0, 10, 0, 30)
	sep.Parent = container

	local msglabel = Instance.new("TextLabel")
	msglabel.BackgroundTransparency = 1
	msglabel.Size = UDim2.new(1, -20, 0, 40)
	msglabel.Position = UDim2.new(0, 10, 0, 35)
	msglabel.Text = "Already executed!"
	msglabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	msglabel.TextSize = 12
	msglabel.Font = Enum.Font.Gotham
	msglabel.TextXAlignment = Enum.TextXAlignment.Left
	msglabel.TextYAlignment = Enum.TextYAlignment.Top
	msglabel.TextWrapped = true
	msglabel.Parent = container

	game:GetService("TweenService")
		:Create(
			container,
			TweenInfo.new(0.5, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, 10, 0, 10) }
		)
		:Play()

	task.wait(3)

	game:GetService("TweenService")
		:Create(
			container,
			TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, -320, 0, 10) }
		)
		:Play()
	task.wait(0.4)
	container:Destroy()

	return
end

getgenv().SyncExecuted = true
if not isfolder("sync") then
	makefolder("sync")
end

local localplr = game.Players.LocalPlayer
local gui = localplr:WaitForChild("PlayerGui")
local tween = game:GetService("TweenService")
local http = game:GetService("HttpService")
local uis = game:GetService("UserInputService")
local runservice = game:GetService("RunService")

local function anim(obj, time, props, style)
	style = style or Enum.EasingStyle.Quint
	return tween:Create(obj, TweenInfo.new(time, style, Enum.EasingDirection.Out), props)
end

-- Theme System
local themes = {
	Dark = {
		Main = Color3.fromRGB(20, 20, 20),
		Secondary = Color3.fromRGB(30, 30, 30),
		Accent = Color3.fromRGB(150, 100, 255),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(200, 200, 200)
	},
	Light = {
		Main = Color3.fromRGB(240, 240, 240),
		Secondary = Color3.fromRGB(255, 255, 255),
		Accent = Color3.fromRGB(0, 120, 215),
		Text = Color3.fromRGB(20, 20, 20),
		TextDark = Color3.fromRGB(80, 80, 80)
	},
	Midnight = {
		Main = Color3.fromRGB(10, 10, 15),
		Secondary = Color3.fromRGB(20, 20, 35),
		Accent = Color3.fromRGB(100, 200, 255),
		Text = Color3.fromRGB(220, 220, 255),
		TextDark = Color3.fromRGB(150, 150, 180)
	},
	Ocean = {
		Main = Color3.fromRGB(10, 25, 40),
		Secondary = Color3.fromRGB(20, 45, 60),
		Accent = Color3.fromRGB(0, 200, 200),
		Text = Color3.fromRGB(220, 240, 255),
		TextDark = Color3.fromRGB(150, 180, 200)
	},
	Rose = {
		Main = Color3.fromRGB(30, 20, 25),
		Secondary = Color3.fromRGB(45, 30, 35),
		Accent = Color3.fromRGB(255, 100, 150),
		Text = Color3.fromRGB(255, 230, 235),
		TextDark = Color3.fromRGB(200, 160, 170)
	},
	Forest = {
		Main = Color3.fromRGB(20, 30, 20),
		Secondary = Color3.fromRGB(30, 45, 30),
		Accent = Color3.fromRGB(100, 200, 100),
		Text = Color3.fromRGB(230, 255, 230),
		TextDark = Color3.fromRGB(160, 200, 160)
	},
	Amethyst = {
		Main = Color3.fromRGB(30, 20, 40),
		Secondary = Color3.fromRGB(45, 30, 60),
		Accent = Color3.fromRGB(180, 100, 255),
		Text = Color3.fromRGB(240, 230, 255),
		TextDark = Color3.fromRGB(200, 180, 220)
	},
	Sunset = {
		Main = Color3.fromRGB(40, 20, 20),
		Secondary = Color3.fromRGB(60, 30, 30),
		Accent = Color3.fromRGB(255, 150, 50),
		Text = Color3.fromRGB(255, 240, 230),
		TextDark = Color3.fromRGB(220, 200, 180)
	}
}

local ThemeManager = {}
ThemeManager.Objects = {}
ThemeManager.Customs = {}

function ThemeManager:Register(obj, type, prop)
	if not obj then return end
	if not prop then
		if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
			prop = "TextColor3"
		elseif obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
			prop = "ImageColor3"
		elseif obj:IsA("Frame") or obj:IsA("ScrollingFrame") then
			prop = "BackgroundColor3"
		elseif obj:IsA("UIStroke") then
			prop = "Color"
		end
	end

	-- Handle special properties
	if obj:IsA("TextBox") and not prop then
		-- We might want to register PlaceholderColor3 too, but we can only register one prop per call with this system
		-- So we'll just stick to TextColor3 by default
	end

	table.insert(self.Objects, {Obj = obj, Prop = prop, Type = type})

	-- Apply current
	local current = (_G.SyncSettings and _G.SyncSettings.theme) or "Dark"
	if not themes[current] then current = "Dark" end
	pcall(function() obj[prop] = themes[current][type] end)
	return obj
end

function ThemeManager:RegisterCustom(callback)
	table.insert(self.Customs, callback)
	local current = (_G.SyncSettings and _G.SyncSettings.theme) or "Dark"
	if not themes[current] then current = "Dark" end
	pcall(function() callback(themes[current]) end)
end

function ThemeManager:Apply(themeName)
	if not themes[themeName] then themeName = "Dark" end
	if _G.SyncSettings then
		_G.SyncSettings.theme = themeName
	end
	local palette = themes[themeName]

	for _, item in pairs(self.Objects) do
		if item.Obj and item.Obj.Parent then
			pcall(function() item.Obj[item.Prop] = palette[item.Type] end)
		end
	end

	for _, callback in pairs(self.Customs) do
		pcall(function() callback(palette) end)
	end

	if writefile and _G.SyncSettings then
		writefile("sync/settings.json", http:JSONEncode(_G.SyncSettings))
	end
end

local function createDropdown(parent, name, options, current, callback)
	local container = Instance.new("Frame")
	container.Name = name .. "Dropdown"
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	ThemeManager:Register(container, "Secondary", "BackgroundColor3")
	container.Size = UDim2.new(1, -40, 0, 60)
	container.Position = UDim2.new(0, 20, 0, 0) -- Position set by layout
	container.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, -20, 0, 20)
	label.Position = UDim2.new(0, 10, 0, 10)
	label.Text = name
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	ThemeManager:Register(label, "Text", "TextColor3")
	label.TextSize = 14
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = container

	local btn = Instance.new("TextButton")
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	ThemeManager:Register(btn, "Main", "BackgroundColor3")
	btn.Size = UDim2.new(0, 140, 0, 28)
	btn.Position = UDim2.new(0, 10, 0, 28)
	btn.Text = current
	btn.TextColor3 = Color3.fromRGB(200, 200, 200)
	ThemeManager:Register(btn, "TextDark", "TextColor3")
	btn.TextSize = 12
	btn.Font = Enum.Font.GothamMedium
	btn.Parent = container

	local btncorner = Instance.new("UICorner")
	btncorner.CornerRadius = UDim.new(0, 8)
	btncorner.Parent = btn

	local arrow = Instance.new("TextLabel")
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.new(0, 20, 1, 0)
	arrow.Position = UDim2.new(1, -25, 0, 0)
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromRGB(150, 150, 150)
	ThemeManager:Register(arrow, "TextDark", "TextColor3")
	arrow.TextSize = 10
	arrow.Font = Enum.Font.Gotham
	arrow.Parent = btn

	-- Dropdown List
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	ThemeManager:Register(list, "Secondary", "BackgroundColor3")
	list.BorderSizePixel = 0
	list.Size = UDim2.new(0, 140, 0, 0)
	list.Visible = false
	list.ZIndex = 100
	list.ScrollBarThickness = 4
	list.ScrollBarImageColor3 = Color3.fromRGB(150, 100, 255)
	ThemeManager:Register(list, "Accent", "ScrollBarImageColor3")

	-- Parent to screen to avoid clipping
	local screen = parent:FindFirstAncestorOfClass("ScreenGui")
	list.Parent = screen

	local listcorner = Instance.new("UICorner")
	listcorner.CornerRadius = UDim.new(0, 8)
	listcorner.Parent = list

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = list

	local open = false

	local function toggle()
		open = not open
		arrow.Text = open and "▲" or "▼"

		if open then
			-- Calculate position
			local btnAbsPos = btn.AbsolutePosition
			local btnAbsSize = btn.AbsoluteSize
			local screenAbsSize = screen.AbsoluteSize

			local listHeight = math.min(#options * 30, 200)
			local yPos = btnAbsPos.Y + btnAbsSize.Y + 5

			-- Check if it goes off screen
			if yPos + listHeight > screenAbsSize.Y then
				yPos = btnAbsPos.Y - listHeight - 5
			end

			list.Position = UDim2.new(0, btnAbsPos.X, 0, yPos)
			list.Size = UDim2.new(0, btnAbsSize.X, 0, 0)
			list.CanvasSize = UDim2.new(0, 0, 0, #options * 30)
			list.Visible = true

			-- Clear old items
			for _, c in ipairs(list:GetChildren()) do
				if c:IsA("TextButton") then c:Destroy() end
			end

			-- Add items
			for _, opt in ipairs(options) do
				local item = Instance.new("TextButton")
				item.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				ThemeManager:Register(item, "Main", "BackgroundColor3")
				item.Size = UDim2.new(1, 0, 0, 28)
				item.Text = opt
				item.TextColor3 = Color3.fromRGB(200, 200, 200)
				ThemeManager:Register(item, "TextDark", "TextColor3")
				item.TextSize = 12
				item.Font = Enum.Font.Gotham
				item.ZIndex = 101
				item.Parent = list

				item.MouseButton1Click:Connect(function()
					callback(opt)
					btn.Text = opt
					toggle()
				end)
			end

			anim(list, 0.3, {Size = UDim2.new(0, btnAbsSize.X, 0, listHeight)}, Enum.EasingStyle.Exponential):Play()
		else
			anim(list, 0.2, {Size = UDim2.new(0, btn.AbsoluteSize.X, 0, 0)}, Enum.EasingStyle.Exponential):Play()
			task.delay(0.2, function()
				if not open then list.Visible = false end
			end)
		end
	end

	btn.MouseButton1Click:Connect(toggle)

	return container
end

local serverurl = "https://requested-conclusions-attacks-rent.trycloudflare.com"
local currentcode = ""
local currenttab = "home"
local cmdbaropen = false
local cmdtogglekey
pcall(function()
	if isfile("sync/keybind.json") then
		cmdtogglekey = Enum.KeyCode[readfile("sync/keybind.json")]
	else
		writefile("sync/keybind.json", "F6")
		cmdtogglekey = Enum.KeyCode.F6
	end
end)

-- Theme System
-- Settings System
local defaultSettings = {
	theme = "Dark",
	notifDuration = 3,
	showWelcome = true
}
_G.SyncSettings = defaultSettings

local function saveSettings()
	if writefile then
		writefile("sync/settings.json", http:JSONEncode(_G.SyncSettings))
	end
end

pcall(function()
	if isfile("sync/settings.json") then
		local saved = http:JSONDecode(readfile("sync/settings.json"))
		for k, v in pairs(saved) do
			_G.SyncSettings[k] = v
		end
	else
		saveSettings()
	end
end)
local ismobile = uis.TouchEnabled and not uis.KeyboardEnabled
local isdragging = false
local dragstart = nil
local startpos = nil
local topbarposition = "top"

---------- NOTIFICATION MODULE ----------
local notify = {}
notify.notifications = {}
notify.yoffset = 10

function notify.anim(obj, time, props, style)
	style = style or Enum.EasingStyle.Quint
	return tween:Create(obj, TweenInfo.new(time, style, Enum.EasingDirection.Out), props)
end

function notify.new(message, duration)
	duration = duration or _G.SyncSettings.notifDuration or 3

	local screen = gui:FindFirstChild("SyncNotifications")
	if not screen then
		screen = Instance.new("ScreenGui")
		screen.Name = "SyncNotifications"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.DisplayOrder = 999
		screen.Parent = gui
	end

	local container = Instance.new("Frame")
	container.Name = "Notification"
	ThemeManager:Register(container, "Main", "BackgroundColor3")
	container.BorderSizePixel = 0
	container.Size = UDim2.new(0, 300, 0, 60)
	container.Position = UDim2.new(0, -320, 0, notify.yoffset)
	container.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -20, 0, 20)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.Text = "Sync"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 14
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = container

	local sep = Instance.new("Frame")
	sep.Name = "Sep"
	ThemeManager:Register(sep, "Accent", "BackgroundColor3")
	sep.BorderSizePixel = 0
	sep.Size = UDim2.new(1, -20, 0, 2)
	sep.Position = UDim2.new(0, 10, 0, 30)
	sep.Parent = container

	local msglabel = Instance.new("TextLabel")
	msglabel.Name = "Message"
	msglabel.BackgroundTransparency = 1
	msglabel.Size = UDim2.new(1, -20, 0, 1000)
	msglabel.Position = UDim2.new(0, 10, 0, 35)
	msglabel.Text = message
	ThemeManager:Register(msglabel, "TextDark", "TextColor3")
	msglabel.TextSize = 12
	msglabel.Font = Enum.Font.Gotham
	msglabel.TextXAlignment = Enum.TextXAlignment.Left
	msglabel.TextYAlignment = Enum.TextYAlignment.Top
	msglabel.TextWrapped = true
	msglabel.Parent = container

	local textbounds = msglabel.TextBounds.Y
	local finalheight = math.max(60, 40 + textbounds)
	container.Size = UDim2.new(0, 300, 0, finalheight)

	table.insert(notify.notifications, { frame = container, height = finalheight })

	notify.anim(container, 0.5, { Position = UDim2.new(0, 10, 0, notify.yoffset) }, Enum.EasingStyle.Exponential):Play()

	notify.yoffset = notify.yoffset + finalheight + 10

	task.delay(duration, function()
		notify
			.anim(
				container,
				0.4,
				{ Position = UDim2.new(0, -320, 0, container.Position.Y.Offset) },
				Enum.EasingStyle.Exponential
			)
			:Play()

		task.wait(0.4)

		for i, notif in ipairs(notify.notifications) do
			if notif.frame == container then
				table.remove(notify.notifications, i)
				notify.yoffset = notify.yoffset - finalheight - 10
				break
			end
		end

		for i, notif in ipairs(notify.notifications) do
			local targetypos = 10
			for j = 1, i - 1 do
				targetypos = targetypos + notify.notifications[j].height + 10
			end
			notify
				.anim(notif.frame, 0.3, { Position = UDim2.new(0, 10, 0, targetypos) }, Enum.EasingStyle.Exponential)
				:Play()
		end

		container:Destroy()
	end)
end

---------- SYNC CMD MODULE ----------
local synccmd = {}
synccmd.__index = synccmd

function synccmd.new(config)
	local self = setmetatable({}, synccmd)

	self.prefix = config.prefix or ";"
	self.premium = config.premium or false
	self.premiumusers = config.premiumusers or {}
	self.checkpremium = config.checkpremium or nil
	self.commands = {}
	self.functions = {}

	return self
end

function synccmd:cmd(data)
	table.insert(self.commands, {
		name = data.name,
		desc = data.desc or "",
		aliases = data.aliases or {},
		premium = data.premium or false,
		func = data.func,
		args = data.args or 0,
		popup = data.popup or nil,
	})
end

function synccmd:func(name, func)
	self.functions[name] = func
end

function synccmd:ispremium(userid)
	if not self.premium then
		return true
	end

	if self.checkpremium then
		return self.checkpremium(userid)
	end

	for _, id in pairs(self.premiumusers) do
		if id == userid then
			return true
		end
	end

	return false
end

function synccmd:parse(msg)
	if not msg:sub(1, #self.prefix) == self.prefix then
		return nil
	end

	local args = {}
	for word in msg:sub(#self.prefix + 1):gmatch("%S+") do
		table.insert(args, word)
	end

	if #args == 0 then
		return nil
	end

	local cmdname = table.remove(args, 1):lower()
	return cmdname, args
end

function synccmd:fuzzy(input, target)
	input = input:lower()
	target = target:lower()

	if target:sub(1, #input) == input then
		return true, 100
	end

	if target:find(input, 1, true) then
		return true, 50
	end

	local score = 0
	local lastpos = 0

	for i = 1, #input do
		local char = input:sub(i, i)
		local pos = target:find(char, lastpos + 1, true)

		if pos then
			score = score + 1
			lastpos = pos
		end
	end

	if score == #input then
		return true, score
	end

	return false, 0
end

function synccmd:findcmd(cmdname)
	local best = nil
	local bestscore = 0

	for _, cmd in pairs(self.commands) do
		local match, score = self:fuzzy(cmdname, cmd.name)

		if match and score > bestscore then
			best = cmd
			bestscore = score
		end

		if cmd.aliases then
			for _, alias in pairs(cmd.aliases) do
				local amatch, ascore = self:fuzzy(cmdname, alias)
				if amatch and ascore > bestscore then
					best = cmd
					bestscore = ascore
				end
			end
		end
	end

	return best
end

function synccmd:exec(msg, providedargs)
	local cmdname, args

	if providedargs then
		cmdname = msg
		args = providedargs
	else
		cmdname, args = self:parse(msg)
	end

	if not cmdname then
		return false
	end

	local cmd = self:findcmd(cmdname)

	if cmd then
		if cmd.premium and not self:ispremium(game.Players.LocalPlayer.UserId) then
			notify.new("This is a premium command!")
			return false
		end

		local success, err = pcall(function()
			cmd.func(args, self)
		end)

		if not success then
			warn(err)
		end

		return true
	end

	return false
end

local config = {
	prefix = ";",
	premium = true,
	premiumusers = {},
	checkpremium = function(userid)
		return false
	end,
}

local cmdcore = synccmd.new(config)

cmdcore:cmd({
	name = "speed",
	desc = "Change walkspeed",
	aliases = { "ws" },
	premium = false,
	args = 1,
	func = function(args, core)
		local char = localplr.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.WalkSpeed = tonumber(args[1]) or 16
			notify.new("WalkSpeed set to " .. (tonumber(args[1]) or 16))
		end
	end,
})

cmdcore:cmd({
	name = "noclip",
	desc = "Toggle noclip",
	aliases = { "nc" },
	premium = false,
	args = 0,
	func = function(args, core)
		local char = localplr.Character
		if not char then return end

		if _G.noclipConnection then
			_G.noclipConnection:Disconnect()
			_G.noclipConnection = nil

			-- Force collision back on immediately
			for _, v in pairs(char:GetDescendants()) do
				if v:IsA("BasePart") then
					v.CanCollide = true
				end
			end

			notify.new("Noclip disabled")
		else
			_G.noclipConnection = game:GetService("RunService").Stepped:Connect(function()
				if localplr.Character then
					for _, v in pairs(localplr.Character:GetDescendants()) do
						if v:IsA("BasePart") and v.CanCollide then
							v.CanCollide = false
						end
					end
				end
			end)
			notify.new("Noclip enabled")
		end
	end,
})

cmdcore:cmd({
	name = "goto",
	desc = "Teleport to player",
	aliases = { "tp" },
	premium = false,
	args = 1,
	func = function(args, core)
		if #args > 0 then
			local target = args[1]:lower()
			local targetplr = nil

			for _, plr in ipairs(game.Players:GetPlayers()) do
				if plr.Name:lower():sub(1, #target) == target or plr.DisplayName:lower():sub(1, #target) == target then
					targetplr = plr
					break
				end
			end

			if targetplr and targetplr.Character and targetplr.Character:FindFirstChild("HumanoidRootPart") and localplr.Character and localplr.Character:FindFirstChild("HumanoidRootPart") then
				localplr.Character.HumanoidRootPart.CFrame = targetplr.Character.HumanoidRootPart.CFrame
				notify.new("Teleported to " .. targetplr.DisplayName)
			else
				notify.new("Player not found or character missing")
			end
		else
			notify.new("Please specify a player")
		end
	end,
})

cmdcore:cmd({
	name = "fly",
	desc = "Toggle flight",
	aliases = { "f" },
	premium = false,
	args = 0,
	func = function(args, core)
		local char = localplr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")

		if not root or not hum then return end

		local isFlying = root:FindFirstChild("FlyVelocity")

		if not isFlying then
			notify.new("Flight enabled")

			local bv = Instance.new("BodyVelocity", root)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
			bv.Name = "FlyVelocity"

			local bg = Instance.new("BodyGyro", root)
			bg.P = 9e4
			bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
			bg.CFrame = root.CFrame
			bg.Name = "FlyGyro"

			hum.PlatformStand = true

			spawn(function()
				while bv.Parent do
					local cam = workspace.CurrentCamera
					local speed = 50
					local v = Vector3.new()

					if uis:IsKeyDown(Enum.KeyCode.W) then v = v + cam.CFrame.LookVector end
					if uis:IsKeyDown(Enum.KeyCode.S) then v = v - cam.CFrame.LookVector end
					if uis:IsKeyDown(Enum.KeyCode.A) then v = v - cam.CFrame.RightVector end
					if uis:IsKeyDown(Enum.KeyCode.D) then v = v + cam.CFrame.RightVector end
					if uis:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0, 1, 0) end
					if uis:IsKeyDown(Enum.KeyCode.LeftControl) then v = v - Vector3.new(0, 1, 0) end

					bv.Velocity = v * speed
					bg.CFrame = cam.CFrame
					task.wait()
				end
				hum.PlatformStand = false
			end)
		else
			notify.new("Flight disabled")
			if root:FindFirstChild("FlyVelocity") then root.FlyVelocity:Destroy() end
			if root:FindFirstChild("FlyGyro") then root.FlyGyro:Destroy() end
			hum.PlatformStand = false
		end
	end,
})

cmdcore:cmd({
	name = "invisible",
	desc = "Become invisible",
	aliases = { "invis" },
	premium = false,
	args = 0,
	func = function(args, core)
		if _G.invisEnabled then
			local clone = localplr.Character
			local realChar = _G.RealCharacter

			if realChar then
				localplr.Character = realChar
				workspace.CurrentCamera.CameraSubject = realChar:FindFirstChild("Humanoid")

				local realRoot = realChar:FindFirstChild("HumanoidRootPart")
				local cloneRoot = clone and clone:FindFirstChild("HumanoidRootPart")
				local realHum = realChar:FindFirstChild("Humanoid")

				if realRoot then
					-- Unanchor everything
					for _, v in pairs(realChar:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Anchored = false
						end
					end

					if cloneRoot then
						realRoot.CFrame = cloneRoot.CFrame
					end

					if realHum then
						realHum.PlatformStand = false
					end
				end
			end

			if clone and clone ~= realChar then
				clone:Destroy()
			end

			_G.invisEnabled = false
			_G.RealCharacter = nil
			notify.new("Invisibility disabled")
		else
			local char = localplr.Character
			if not char then return end

			char.Archivable = true
			local clone = char:Clone()
			clone.Name = char.Name .. " (Clone)"
			clone.Parent = workspace

			for _, v in pairs(clone:GetDescendants()) do
				if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
					v.Transparency = 0.5
				end
			end

			_G.RealCharacter = char

			local root = char:FindFirstChild("HumanoidRootPart")
			local hum = char:FindFirstChild("Humanoid")

			if root and hum then
				-- Anchor everything to keep real char in place
				for _, v in pairs(char:GetDescendants()) do
					if v:IsA("BasePart") then
						v.Anchored = true
					end
				end
				hum.PlatformStand = true
			end

			-- Move clone in front
			local cloneRoot = clone:FindFirstChild("HumanoidRootPart")
			if cloneRoot and root then
				cloneRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
			end

			localplr.Character = clone
			workspace.CurrentCamera.CameraSubject = clone:FindFirstChild("Humanoid")

			-- Fix Clone Animations by restarting the Animate script
			local animate = clone:FindFirstChild("Animate")
			if animate then
				animate.Disabled = true
				task.wait()
				animate.Disabled = false
			end

			_G.invisEnabled = true
			notify.new("Invisibility enabled")
		end
	end,
})

---------- FAVORITES SYSTEM ----------
local syncfolder = workspace:FindFirstChild("Sync") or Instance.new("Folder")
syncfolder.Name = "Sync"
syncfolder.Parent = workspace

local favfile = syncfolder:FindFirstChild("favorites.json")
local favorites = {}

if favfile and favfile:IsA("StringValue") then
	local success, data = pcall(function()
		return http:JSONDecode(favfile.Value)
	end)
	if success then
		favorites = data
	end
else
	favfile = Instance.new("StringValue")
	favfile.Name = "favorites.json"
	favfile.Value = http:JSONEncode({})
	favfile.Parent = syncfolder
end

local function savefavorites()
	favfile.Value = http:JSONEncode(favorites)
end

local function isfavorite(cmdname)
	for _, name in ipairs(favorites) do
		if name == cmdname then
			return true
		end
	end
	return false
end

local function togglefavorite(cmdname)
	if isfavorite(cmdname) then
		for i, name in ipairs(favorites) do
			if name == cmdname then
				table.remove(favorites, i)
				break
			end
		end
	else
		table.insert(favorites, cmdname)
	end
	savefavorites()
end

---------- KEYBINDS SYSTEM ----------
local keybindfile = syncfolder:FindFirstChild("keybinds.json")
local keybinds = {}

if keybindfile and keybindfile:IsA("StringValue") then
	local success, data = pcall(function()
		return http:JSONDecode(keybindfile.Value)
	end)
	if success then
		keybinds = data
	end
else
	keybindfile = Instance.new("StringValue")
	keybindfile.Name = "keybinds.json"
	keybindfile.Value = http:JSONEncode({})
	keybindfile.Parent = syncfolder
end

local function savekeybinds()
	keybindfile.Value = http:JSONEncode(keybinds)
end

---------- ENCRYPTION/DECRYPTION ----------
local function b64e(d)
	local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	return (
		(d:gsub(".", function(x)
			local r, b = "", x:byte()
			for i = 8, 1, -1 do
				r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0")
			end
			return r
		end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
			if #x < 6 then
				return ""
			end
			local c = 0
			for i = 1, 6 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0)
			end
			return b64c:sub(c + 1, c + 1)
		end) .. ({ "", "==", "=" })[#d % 3 + 1]
	)
end

local function b64d(d)
	local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	d = string.gsub(d, "[^" .. b64c .. "=]", "")
	return (
		d:gsub(".", function(x)
			if x == "=" then
				return ""
			end
			local r, f = "", (b64c:find(x) - 1)
			for i = 5, 0, -1 do
				r = r .. (f % 2 ^ (i + 1) >= 2 ^ i and "1" or "0")
			end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then
				return ""
			end
			local c = 0
			for i = 1, 8 do
				c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
			end
			return string.char(c)
		end)
	)
end

local function xor(s, k)
	local r = {}
	local kl = #k
	local salt = 47
	for i = 1, #s do
		local sc = string.byte(s, i)
		local kc = string.byte(k, ((i - 1) % kl) + 1)
		r[i] = string.char((sc + kc + salt + i) % 256)
	end
	return table.concat(r)
end

local function xorr(s, k)
	local r = {}
	local kl = #k
	local salt = 47
	for i = 1, #s do
		local sc = string.byte(s, i)
		local kc = string.byte(k, ((i - 1) % kl) + 1)
		r[i] = string.char((sc - kc - salt - i) % 256)
	end
	return table.concat(r)
end

local function enc(s)
	local x = xor(s, "k3y!@#987zXqW")
	local r = x:reverse()
	local b = b64e(r)
	return b64e(b .. string.rep("=", math.random(2, 8)))
end

local function dec(e)
	local d1 = b64d(e)
	local stripped = d1:gsub("=+$", "")
	local d2 = b64d(stripped)
	local r = d2:reverse()
	return xorr(r, "k3y!@#987zXqW")
end

local function checkstatus()
	if TEST_VERIFIED then
		return { s = 1, t = 4 }
	end
	local url = serverurl .. "/check/" .. UrlEncode(localplr.Name)

	local s, res = pcall(function()
		return SafeHttpGet(url, true)
	end)

	if not s then
		return nil
	end

	local s2, data = pcall(function()
		return http:JSONDecode(res)
	end)

	if not s2 or not data.d then
		return nil
	end

	local s3, decrypted = pcall(function()
		return dec(data.d)
	end)

	if not s3 then
		return nil
	end

	local s4, status = pcall(function()
		return http:JSONDecode(decrypted)
	end)

	if not s4 then
		return nil
	end

	return status
end

local allDraggable = false

local function makeDraggable(obj, respectToggle)
	local dragging, dragInput, dragStart, startPos

	local function update(input)
		local delta = input.Position - dragStart
		obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	obj.InputBegan:Connect(function(input)
		if respectToggle and not allDraggable then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = obj.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	obj.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	uis.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

local status = checkstatus()
local userpremium = status and status.t == 4

local screen = Instance.new("ScreenGui")
screen.Name = "SyncGui"
screen.ResetOnSpawn = false
screen.DisplayOrder = 100
screen.Parent = gui

local viewportsize = workspace.CurrentCamera.ViewportSize


local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = game.Lighting

local container = Instance.new("Frame")
container.Name = "Container"
container.AnchorPoint = Vector2.new(0.5, 0)
container.BackgroundTransparency = 1
container.Size = UDim2.new(0, 260, 0, 50)
container.Position = UDim2.new(0.5, 0, 0, -60)
container.Parent = screen
container.ClipsDescendants = true
makeDraggable(container, false)

local ball = Instance.new("Frame")
ball.Name = "Ball"
ThemeManager:Register(ball, "Main", "BackgroundColor3")
ball.Size = UDim2.new(0, 50, 0, 50)
ball.Position = UDim2.new(0, 0, 0, 0)
ball.BackgroundTransparency = 1
ball.Parent = container

local ballcorner = Instance.new("UICorner")
ballcorner.CornerRadius = UDim.new(1, 0)
ballcorner.Parent = ball

local pfp = Instance.new("ImageLabel")
pfp.Name = "Pfp"
pfp.BackgroundTransparency = 1
pfp.Size = UDim2.new(0.8, 0, 0.8, 0)
pfp.Position = UDim2.new(0.1, 0, 0.1, 0)
pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. localplr.UserId .. "&w=150&h=150"
pfp.ImageTransparency = 1
pfp.Parent = ball

local pfpcorner = Instance.new("UICorner")
pfpcorner.CornerRadius = UDim.new(1, 0)
pfpcorner.Parent = pfp

local island = Instance.new("Frame")
island.Name = "Island"
island.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
island.Size = UDim2.new(0, 200, 0, 50)
island.Position = UDim2.new(0, 60, 0, 0)
island.BackgroundTransparency = 1
island.Parent = container

local islandcorner = Instance.new("UICorner")
islandcorner.CornerRadius = UDim.new(1, 0)
islandcorner.Parent = island

local welcome = Instance.new("TextLabel")
welcome.Name = "Welcome"
welcome.BackgroundTransparency = 1
welcome.Size = UDim2.new(1, -20, 1, 0)
welcome.Position = UDim2.new(0, 10, 0, 0)
welcome.Text = "Welcome, " .. localplr.DisplayName .. " 👋"
welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
welcome.TextSize = 16
welcome.Font = Enum.Font.GothamBold
welcome.TextXAlignment = Enum.TextXAlignment.Left
welcome.TextTransparency = 1
welcome.Parent = island

local txtwidth = welcome.TextBounds.X + 30
island.Size = UDim2.new(0, txtwidth, 0, 50)
container.Size = UDim2.new(0, txtwidth + 60, 0, 50)
container.Position = UDim2.new(0.5, -(txtwidth + 60) / 2, 0, -60)

local function onplayerchatted(msg)
	if msg:sub(1, #cmdcore.prefix) == cmdcore.prefix then
		cmdcore:exec(msg)
	end
end

localplr.Chatted:Connect(onplayerchatted)

if status and status.s == 1 then
	anim(
		container,
		0.8,
		{ Position = UDim2.new(0.5, 0, 0, 20) },
		Enum.EasingStyle.Exponential
	):Play()
	task.wait(0.15)
	anim(ball, 0.4, { BackgroundTransparency = 0 }):Play()
	anim(island, 0.4, { BackgroundTransparency = 0 }):Play()
	anim(welcome, 0.4, { TextTransparency = 0 }):Play()
	anim(pfp, 0.4, { ImageTransparency = 0 }):Play()

	task.wait(2)

	anim(welcome, 0.3, { TextTransparency = 1 }, Enum.EasingStyle.Sine):Play()
	anim(pfp, 0.3, { ImageTransparency = 1 }, Enum.EasingStyle.Sine):Play()

	task.wait(0.3)

	local shrink = anim(
		island,
		0.6,
		{ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 0, 0, 0) },
		Enum.EasingStyle.Exponential
	)
	local fade = anim(island, 0.3, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)

	-- Smoothly move and shrink container to center
	local moveAndShrink = anim(
		container,
		0.8,
		{ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0.5, 0, 0, 20) },
		Enum.EasingStyle.Exponential
	)

	shrink:Play()
	moveAndShrink:Play()
	task.wait(0.3)
	fade:Play()
	moveAndShrink.Completed:Wait()

	island:Destroy()
	welcome:Destroy()
	pfp:Destroy()

	ball.Size = UDim2.new(1, 0, 1, 0)
	ball.Position = UDim2.new(0, 0, 0, 0)

	local navw = 240
	local navh = 44

	local expand = anim(
		container,
		0.9,
		{ Size = UDim2.new(0, navw, 0, navh) },
		Enum.EasingStyle.Exponential
	)
	local roundcorner = anim(ballcorner, 0.9, { CornerRadius = UDim.new(1, 0) }, Enum.EasingStyle.Exponential)
	expand:Play()
	roundcorner:Play()
	expand.Completed:Wait()

	local icondata = {
		{ id = "77152639636456", name = "Home" },
		{ id = "139500470994801", name = "Commands" },
		{ id = "122415709139083", name = "Script Search" },
		{ id = "136992103957458", name = "Environment" },
		{ id = "86095856062452", name = "Settings" },
	}

	local iconsize = 30
	local iconspacing = 10
	local totalwidth = (#icondata * iconsize) + ((#icondata - 1) * iconspacing)
	local startx = (navw - totalwidth) / 2

	local lavalamp = Instance.new("Frame")
	lavalamp.Name = "Lavalamp"
	ThemeManager:Register(lavalamp, "Accent", "BackgroundColor3")
	lavalamp.Size = UDim2.new(0, iconsize + 6, 0, iconsize + 6)
	lavalamp.Position = UDim2.new(0, startx - 3, 0, (navh - iconsize) / 2 - 3)
	lavalamp.BorderSizePixel = 0
	lavalamp.ZIndex = 1
	lavalamp.BackgroundTransparency = 1
	lavalamp.Parent = ball

	local lavalampcorner = Instance.new("UICorner")
	lavalampcorner.CornerRadius = UDim.new(0, 12)
	lavalampcorner.Parent = lavalamp

	-- Top Bar Clock
	local topclock = Instance.new("TextLabel")
	topclock.Name = "TopClock"
	topclock.BackgroundTransparency = 1
	topclock.Size = UDim2.new(0, 60, 1, 0)
	topclock.Position = UDim2.new(1, -70, 0, 0)
	topclock.Text = "00:00"
	ThemeManager:Register(topclock, "TextDark", "TextColor3")
	topclock.TextSize = 14
	topclock.Font = Enum.Font.GothamBold
	topclock.TextXAlignment = Enum.TextXAlignment.Right
	topclock.Parent = ball

	local icons = {}
	local currenthover = nil
	local icons = {}
	local currenthover = nil
	local tabopen = false

	local tabcontainer = Instance.new("Frame")
	tabcontainer.Name = "TabContainer"
	tabcontainer.AnchorPoint = Vector2.new(0.5, 0)
	ThemeManager:Register(tabcontainer, "Main", "BackgroundColor3")
	tabcontainer.Size = UDim2.new(0, 700, 0, 450)
	tabcontainer.Position = UDim2.new(0.5, 0, 0, 80)
	tabcontainer.BorderSizePixel = 0
	tabcontainer.ClipsDescendants = true
	tabcontainer.Visible = false
	tabcontainer.Parent = screen
	makeDraggable(tabcontainer, true)

	local tabcorner = Instance.new("UICorner")
	tabcorner.CornerRadius = UDim.new(0, 16)
	tabcorner.Parent = tabcontainer

	---------- HOME TAB ----------
	local hometab = Instance.new("Frame")
	hometab.Name = "HomeTab"
	hometab.BackgroundTransparency = 1
	hometab.Size = UDim2.new(1, 0, 1, 0)
	hometab.BorderSizePixel = 0
	hometab.Visible = false
	hometab.Parent = tabcontainer

	tabcontainer.BackgroundTransparency = 1

	local userwidget = Instance.new("Frame")
	userwidget.Name = "UserWidget"
	ThemeManager:Register(userwidget, "Secondary", "BackgroundColor3")
	userwidget.Size = UDim2.new(0, 420, 0, 100)
	userwidget.Position = UDim2.new(0, 20, 0, 20)
	userwidget.BorderSizePixel = 0
	userwidget.BackgroundTransparency = 1
	userwidget.Parent = hometab

	local userwidgetcorner = Instance.new("UICorner")
	userwidgetcorner.CornerRadius = UDim.new(0, 16)
	userwidgetcorner.Parent = userwidget

	local useravatar = Instance.new("ImageLabel")
	ThemeManager:Register(useravatar, "Main", "BackgroundColor3")
	useravatar.Size = UDim2.new(0, 70, 0, 70)
	useravatar.Position = UDim2.new(0, 15, 0, 15)
	useravatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. localplr.UserId .. "&w=150&h=150"
	useravatar.BorderSizePixel = 0
	useravatar.BackgroundTransparency = 1
	useravatar.Parent = userwidget

	local useravatarcorner = Instance.new("UICorner")
	useravatarcorner.CornerRadius = UDim.new(0, 12)
	useravatarcorner.Parent = useravatar

	local userinfo = Instance.new("Frame")
	userinfo.BackgroundTransparency = 1
	userinfo.Size = UDim2.new(0, 300, 0, 70)
	userinfo.Position = UDim2.new(0, 95, 0, 15)
	userinfo.Parent = userwidget

	local userdisplay = Instance.new("TextLabel")
	userdisplay.BackgroundTransparency = 1
	userdisplay.Size = UDim2.new(1, 0, 0, 22)
	userdisplay.Position = UDim2.new(0, 0, 0, 0)
	userdisplay.Text = "Hello, " .. localplr.DisplayName .. " 👋"
	ThemeManager:Register(userdisplay, "Text", "TextColor3")
	userdisplay.TextSize = 16
	userdisplay.Font = Enum.Font.GothamBold
	userdisplay.TextXAlignment = Enum.TextXAlignment.Left
	userdisplay.TextTransparency = 1
	userdisplay.Parent = userinfo

	local usersep = Instance.new("Frame")
	ThemeManager:Register(usersep, "Accent", "BackgroundColor3")
	usersep.Size = UDim2.new(0, 2, 0, 14)
	usersep.Position = UDim2.new(0, 0, 0, 26)
	usersep.BorderSizePixel = 0
	usersep.BackgroundTransparency = 1
	usersep.Parent = userinfo

	local username = Instance.new("TextLabel")
	username.BackgroundTransparency = 1
	username.Size = UDim2.new(1, 0, 0, 16)
	username.Position = UDim2.new(0, 8, 0, 24)
	username.Text = "@" .. localplr.Name
	ThemeManager:Register(username, "TextDark", "TextColor3")
	username.TextSize = 13
	username.Font = Enum.Font.Gotham
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.Parent = userinfo

	spawn(function()
		while true do
			local date = os.date("*t")
			local hour = string.format("%02d", date.hour)
			local min = string.format("%02d", date.min)
			local sec = string.format("%02d", date.sec)

			topclock.Text = hour .. ":" .. min
			task.wait(1)
		end
	end)
	username.Font = Enum.Font.Gotham
	username.TextXAlignment = Enum.TextXAlignment.Left
	username.TextTransparency = 1
	username.Parent = userinfo

	local typecontainer = Instance.new("Frame")
	typecontainer.BackgroundTransparency = 1
	typecontainer.Size = UDim2.new(1, 0, 0, 20)
	typecontainer.Position = UDim2.new(0, 0, 0, 46)
	typecontainer.Parent = userinfo

	local typelabel = Instance.new("TextLabel")
	typelabel.BackgroundTransparency = 1
	typelabel.Size = UDim2.new(0, 40, 0, 20)
	typelabel.Position = UDim2.new(0, 0, 0, 0)
	typelabel.Text = "Type:"
	typelabel.TextColor3 = Color3.fromRGB(180, 180, 180)
	typelabel.TextSize = 12
	typelabel.Font = Enum.Font.Gotham
	typelabel.TextXAlignment = Enum.TextXAlignment.Left
	typelabel.TextTransparency = 1
	typelabel.Parent = typecontainer

	local typebadge = Instance.new("Frame")
	typebadge.BackgroundColor3 = userpremium and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(40, 40, 40)
	typebadge.Size = UDim2.new(0, 70, 0, 20)
	typebadge.Position = UDim2.new(0, 45, 0, 0)
	typebadge.BorderSizePixel = 0
	typebadge.BackgroundTransparency = 1
	typebadge.Parent = typecontainer

	local typebadgecorner = Instance.new("UICorner")
	typebadgecorner.CornerRadius = UDim.new(1, 0)
	typebadgecorner.Parent = typebadge

	local typebadgetext = Instance.new("TextLabel")
	typebadgetext.BackgroundTransparency = 1
	typebadgetext.Size = UDim2.new(1, 0, 1, 0)
	typebadgetext.Text = userpremium and "Premium" or "Free"
	typebadgetext.TextColor3 = userpremium and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 200)
	typebadgetext.TextSize = 11
	typebadgetext.Font = Enum.Font.GothamBold
	typebadgetext.TextTransparency = 1
	typebadgetext.Parent = typebadge

	local datewidget = Instance.new("Frame")
	datewidget.Name = "DateWidget"
	ThemeManager:Register(datewidget, "Secondary", "BackgroundColor3")
	datewidget.Size = UDim2.new(0, 240, 0, 100)
	datewidget.Position = UDim2.new(0, 460, 0, 20)
	datewidget.BorderSizePixel = 0
	datewidget.BackgroundTransparency = 1
	datewidget.Parent = hometab

	local datewidgetcorner = Instance.new("UICorner")
	datewidgetcorner.CornerRadius = UDim.new(0, 16)
	datewidgetcorner.Parent = datewidget

	local datelabel = Instance.new("TextLabel")
	datelabel.BackgroundTransparency = 1
	datelabel.Size = UDim2.new(1, -30, 0, 25)
	datelabel.Position = UDim2.new(0, 15, 0, 15)
	datelabel.Text = os.date("%A, %d. %b %Y")
	ThemeManager:Register(datelabel, "Text", "TextColor3")
	datelabel.TextSize = 15
	datelabel.Font = Enum.Font.GothamBold
	datelabel.TextXAlignment = Enum.TextXAlignment.Left
	datelabel.TextTransparency = 1
	datelabel.Parent = datewidget

	local timebox = Instance.new("Frame")
	ThemeManager:Register(timebox, "Main", "BackgroundColor3")
	timebox.Size = UDim2.new(0, 120, 0, 35)
	timebox.Position = UDim2.new(0, 15, 0, 50)
	timebox.BorderSizePixel = 0
	timebox.BackgroundTransparency = 1
	timebox.Parent = datewidget

	local timeboxcorner = Instance.new("UICorner")
	timeboxcorner.CornerRadius = UDim.new(0, 10)
	timeboxcorner.Parent = timebox

	local timelabel = Instance.new("TextLabel")
	timelabel.BackgroundTransparency = 1
	timelabel.Size = UDim2.new(1, 0, 1, 0)
	timelabel.Text = os.date("%I:%M %p")
	ThemeManager:Register(timelabel, "TextDark", "TextColor3")
	timelabel.TextSize = 14
	timelabel.Font = Enum.Font.GothamBold
	timelabel.TextTransparency = 1
	timelabel.Parent = timebox

	spawn(function()
		while true do
			timelabel.Text = os.date("%I:%M:%S %p")
			task.wait(1)
		end
	end)

	local execwidget = Instance.new("Frame")
	execwidget.Name = "ExecWidget"
	ThemeManager:Register(execwidget, "Secondary", "BackgroundColor3")
	execwidget.Size = UDim2.new(0, 320, 0, 80)
	execwidget.Position = UDim2.new(0, 20, 0, 140)
	execwidget.BorderSizePixel = 0
	execwidget.BackgroundTransparency = 1
	execwidget.Parent = hometab

	local execwidgetcorner = Instance.new("UICorner")
	execwidgetcorner.CornerRadius = UDim.new(0, 16)
	execwidgetcorner.Parent = execwidget

	local execgradient = Instance.new("UIGradient")
	execgradient.Rotation = 45
	execgradient.Parent = execwidget

	ThemeManager:RegisterCustom(function(palette)
		execgradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, palette.Secondary),
			ColorSequenceKeypoint.new(1, palette.Accent)
		})
	end)

	local execlabel = Instance.new("TextLabel")
	execlabel.BackgroundTransparency = 1
	execlabel.Size = UDim2.new(1, -30, 0, 20)
	execlabel.Position = UDim2.new(0, 15, 0, 15)
	execlabel.Text = "Executor"
	ThemeManager:Register(execlabel, "Text", "TextColor3")
	execlabel.TextSize = 14
	execlabel.Font = Enum.Font.GothamBold
	execlabel.TextXAlignment = Enum.TextXAlignment.Left
	execlabel.TextTransparency = 1
	execlabel.Parent = execwidget

	local execname = Instance.new("TextLabel")
	execname.BackgroundTransparency = 1
	execname.Size = UDim2.new(1, -30, 0, 30)
	execname.Position = UDim2.new(0, 15, 0, 40)
	execname.Text = identifyexecutor and identifyexecutor() or "Unknown"
	ThemeManager:Register(execname, "TextDark", "TextColor3")
	execname.TextSize = 18
	execname.Font = Enum.Font.GothamBold
	execname.TextXAlignment = Enum.TextXAlignment.Left
	execname.TextTransparency = 1
	execname.Parent = execwidget

	task.wait(0.3)
	anim(userwidget, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(useravatar, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(userdisplay, 0.5, { TextTransparency = 0 }):Play()
	task.wait(0.1)
	anim(usersep, 0.4, { BackgroundTransparency = 0 }):Play()
	anim(username, 0.5, { TextTransparency = 0 }):Play()
	task.wait(0.1)
	anim(typelabel, 0.5, { TextTransparency = 0 }):Play()
	anim(typebadge, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(typebadgetext, 0.5, { TextTransparency = 0 }):Play()
	task.wait(0.1)
	anim(datewidget, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(datelabel, 0.5, { TextTransparency = 0 }):Play()
	anim(timebox, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(timelabel, 0.5, { TextTransparency = 0 }):Play()
	task.wait(0.1)
	anim(execwidget, 0.5, { BackgroundTransparency = 0 }):Play()
	anim(execlabel, 0.5, { TextTransparency = 0 }):Play()
	anim(execname, 0.5, { TextTransparency = 0 }):Play()

	---------- COMMANDS TAB ----------
	local commandstab = Instance.new("ScrollingFrame")
	commandstab.Name = "CommandsTab"
	commandstab.BackgroundTransparency = 1
	commandstab.Size = UDim2.new(1, 0, 1, 0)
	commandstab.Position = UDim2.new(0, 0, 0, 0)
	commandstab.ScrollBarThickness = 6
	ThemeManager:Register(commandstab, "Accent", "ScrollBarImageColor3")
	commandstab.BorderSizePixel = 0
	commandstab.Visible = false
	commandstab.CanvasSize = UDim2.new(0, 0, 0, 0)
	commandstab.Parent = tabcontainer

	local cmdtitle = Instance.new("TextLabel")
	cmdtitle.BackgroundTransparency = 1
	cmdtitle.Size = UDim2.new(1, -40, 0, 30)
	cmdtitle.Position = UDim2.new(0, 20, 0, 20)
	cmdtitle.Text = "Commands"
	ThemeManager:Register(cmdtitle, "Text", "TextColor3")
	cmdtitle.TextSize = 24
	cmdtitle.Font = Enum.Font.GothamBold
	cmdtitle.TextXAlignment = Enum.TextXAlignment.Left
	cmdtitle.Parent = commandstab

	local cmdsearch = Instance.new("TextBox")
	cmdsearch.Name = "Search"
	ThemeManager:Register(cmdsearch, "Secondary", "BackgroundColor3")
	cmdsearch.Size = UDim2.new(0, 200, 0, 32)
	cmdsearch.Position = UDim2.new(1, -220, 0, 20)
	cmdsearch.PlaceholderText = "Search commands..."
	ThemeManager:Register(cmdsearch, "TextDark", "PlaceholderColor3")
	cmdsearch.Text = ""
	ThemeManager:Register(cmdsearch, "Text", "TextColor3")
	cmdsearch.TextSize = 13
	cmdsearch.Font = Enum.Font.Gotham
	cmdsearch.Parent = commandstab

	local searchcorner = Instance.new("UICorner")
	searchcorner.CornerRadius = UDim.new(0, 8)
	searchcorner.Parent = cmdsearch

	local cmdgrid = Instance.new("Frame")
	cmdgrid.Name = "Grid"
	cmdgrid.BackgroundTransparency = 1
	cmdgrid.Size = UDim2.new(1, -40, 1, -80)
	cmdgrid.Position = UDim2.new(0, 20, 0, 60)
	cmdgrid.Parent = commandstab

	local popupcontainer = Instance.new("Frame")
	popupcontainer.Name = "PopupContainer"
	ThemeManager:Register(popupcontainer, "Main", "BackgroundColor3")
	popupcontainer.Size = UDim2.new(0, 350, 0, 200)
	popupcontainer.Position = UDim2.new(0.5, -175, 0.5, -100)
	popupcontainer.BorderSizePixel = 0
	popupcontainer.Visible = false
	popupcontainer.ZIndex = 200
	popupcontainer.Parent = screen
	makeDraggable(popupcontainer, true)

	local popupcorner = Instance.new("UICorner")
	popupcorner.CornerRadius = UDim.new(0, 16)
	popupcorner.Parent = popupcontainer

	local popuptitle = Instance.new("TextLabel")
	popuptitle.BackgroundTransparency = 1
	popuptitle.Size = UDim2.new(1, -40, 0, 30)
	popuptitle.Position = UDim2.new(0, 20, 0, 15)
	popuptitle.Text = "Enter Arguments"
	ThemeManager:Register(popuptitle, "Text", "TextColor3")
	popuptitle.TextSize = 18
	popuptitle.Font = Enum.Font.GothamBold
	popuptitle.TextXAlignment = Enum.TextXAlignment.Left
	popuptitle.Parent = popupcontainer

	local popupsep = Instance.new("Frame")
	ThemeManager:Register(popupsep, "Accent", "BackgroundColor3")
	popupsep.Size = UDim2.new(1, -40, 0, 2)
	popupsep.Position = UDim2.new(0, 20, 0, 50)
	popupsep.BorderSizePixel = 0
	popupsep.Parent = popupcontainer

	local popupinput = Instance.new("TextBox")
	ThemeManager:Register(popupinput, "Secondary", "BackgroundColor3")
	popupinput.Size = UDim2.new(1, -40, 0, 40)
	popupinput.Position = UDim2.new(0, 20, 0, 70)
	popupinput.PlaceholderText = "Enter value..."
	ThemeManager:Register(popupinput, "TextDark", "PlaceholderColor3")
	popupinput.Text = ""
	ThemeManager:Register(popupinput, "Text", "TextColor3")
	popupinput.TextSize = 14
	popupinput.Font = Enum.Font.Gotham
	popupinput.ClearTextOnFocus = false
	popupinput.Parent = popupcontainer

	local popupinputcorner = Instance.new("UICorner")
	popupinputcorner.CornerRadius = UDim.new(0, 10)
	popupinputcorner.Parent = popupinput

	local popupexec = Instance.new("TextButton")
	ThemeManager:Register(popupexec, "Accent", "BackgroundColor3")
	popupexec.Size = UDim2.new(0, 140, 0, 40)
	popupexec.Position = UDim2.new(0, 20, 0, 130)
	popupexec.Text = "Execute"
	ThemeManager:Register(popupexec, "Text", "TextColor3")
	popupexec.TextSize = 14
	popupexec.Font = Enum.Font.GothamBold
	popupexec.AutoButtonColor = false
	popupexec.Parent = popupcontainer

	local popupexeccorner = Instance.new("UICorner")
	popupexeccorner.CornerRadius = UDim.new(0, 10)
	popupexeccorner.Parent = popupexec

	local popupcancel = Instance.new("TextButton")
	ThemeManager:Register(popupcancel, "Secondary", "BackgroundColor3")
	popupcancel.Size = UDim2.new(0, 140, 0, 40)
	popupcancel.Position = UDim2.new(1, -160, 0, 130)
	popupcancel.Text = "Cancel"
	ThemeManager:Register(popupcancel, "TextDark", "TextColor3")
	popupcancel.TextSize = 14
	popupcancel.Font = Enum.Font.GothamBold
	popupcancel.AutoButtonColor = false
	popupcancel.Parent = popupcontainer

	local popupcancelcorner = Instance.new("UICorner")
	popupcancelcorner.CornerRadius = UDim.new(0, 10)
	popupcancelcorner.Parent = popupcancel

	local keybindpopup = Instance.new("Frame")
	keybindpopup.Name = "KeybindPopup"
	ThemeManager:Register(keybindpopup, "Main", "BackgroundColor3")
	keybindpopup.Size = UDim2.new(0, 300, 0, 150)
	keybindpopup.Position = UDim2.new(0.5, -150, 0.5, -75)
	keybindpopup.BorderSizePixel = 0
	keybindpopup.Visible = false
	keybindpopup.ZIndex = 200
	keybindpopup.Parent = screen
	makeDraggable(keybindpopup, true)

	local keybindpopupcorner = Instance.new("UICorner")
	keybindpopupcorner.CornerRadius = UDim.new(0, 16)
	keybindpopupcorner.Parent = keybindpopup

	local keybindtitle = Instance.new("TextLabel")
	keybindtitle.BackgroundTransparency = 1
	keybindtitle.Size = UDim2.new(1, -40, 0, 30)
	keybindtitle.Position = UDim2.new(0, 20, 0, 15)
	keybindtitle.Text = "Press a key..."
	ThemeManager:Register(keybindtitle, "Text", "TextColor3")
	keybindtitle.TextSize = 18
	keybindtitle.Font = Enum.Font.GothamBold
	keybindtitle.TextXAlignment = Enum.TextXAlignment.Center
	keybindtitle.Parent = keybindpopup

	local keybindsep = Instance.new("Frame")
	ThemeManager:Register(keybindsep, "Accent", "BackgroundColor3")
	keybindsep.Size = UDim2.new(1, -40, 0, 2)
	keybindsep.Position = UDim2.new(0, 20, 0, 50)
	keybindsep.BorderSizePixel = 0
	keybindsep.Parent = keybindpopup

	local keybindlabel = Instance.new("TextLabel")
	keybindlabel.BackgroundTransparency = 1
	keybindlabel.Size = UDim2.new(1, -40, 0, 40)
	keybindlabel.Position = UDim2.new(0, 20, 0, 65)
	keybindlabel.Text = "Waiting for input..."
	ThemeManager:Register(keybindlabel, "TextDark", "TextColor3")
	keybindlabel.TextSize = 14
	keybindlabel.Font = Enum.Font.Gotham
	keybindlabel.TextXAlignment = Enum.TextXAlignment.Center
	keybindlabel.Parent = keybindpopup

	local currentkeybindcmd = nil

	local function showkeybindpopup(cmdname)
		currentkeybindcmd = cmdname
		keybindpopup.Visible = true
		anim(blur, 0.3, { Size = 15 }):Play()

		local conn
		conn = uis.InputBegan:Connect(function(input, gpe)
			if gpe then
				return
			end

			if input.UserInputType == Enum.UserInputType.Keyboard then
				keybinds[cmdname] = input.KeyCode.Name
				savekeybinds()
				keybindpopup.Visible = false
				anim(blur, 0.3, { Size = 0 }):Play()
				notify.new("Keybind set to " .. input.KeyCode.Name)
				conn:Disconnect()
			end
		end)
	end

	uis.InputBegan:Connect(function(input, gpe)
		if gpe then
			return
		end

		if input.UserInputType == Enum.UserInputType.Keyboard then
			for cmdname, keyname in pairs(keybinds) do
				if input.KeyCode.Name == keyname then
					cmdcore:exec(";" .. cmdname)
				end
			end
		end
	end)

	local function refreshcmds(filter)
		for _, child in ipairs(cmdgrid:GetChildren()) do
			child:Destroy()
		end

		local ypos = 0
		local xpos = 0
		local count = 0

		for _, cmd in ipairs(cmdcore.commands) do
			if not filter or filter == "" or cmd.name:lower():find(filter:lower()) then
				local cmdbox = Instance.new("TextButton")
				cmdbox.Name = cmd.name
				ThemeManager:Register(cmdbox, "Secondary", "BackgroundColor3")
				cmdbox.Size = UDim2.new(0, 155, 0, 90)
				cmdbox.Position = UDim2.new(0, xpos, 0, ypos)
				cmdbox.Text = ""
				cmdbox.AutoButtonColor = false
				cmdbox.Parent = cmdgrid

				local cmdboxcorner = Instance.new("UICorner")
				cmdboxcorner.CornerRadius = UDim.new(0, 12)
				cmdboxcorner.Parent = cmdbox

				local cmdname = Instance.new("TextLabel")
				cmdname.BackgroundTransparency = 1
				cmdname.Size = UDim2.new(1, -50, 0, 18)
				cmdname.Position = UDim2.new(0, 10, 0, 8)
				cmdname.Text = cmd.name
				ThemeManager:Register(cmdname, "Text", "TextColor3")
				cmdname.TextSize = 14
				cmdname.Font = Enum.Font.GothamBold
				cmdname.TextXAlignment = Enum.TextXAlignment.Left
				cmdname.Parent = cmdbox

				if cmd.premium then
					local premiumbadge = Instance.new("Frame")
					premiumbadge.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
					premiumbadge.Size = UDim2.new(0, 55, 0, 14)
					premiumbadge.Position = UDim2.new(0, 10, 1, -22)
					premiumbadge.BorderSizePixel = 0
					premiumbadge.Parent = cmdbox

					local premiumbadgecorner = Instance.new("UICorner")
					premiumbadgecorner.CornerRadius = UDim.new(0, 7)
					premiumbadgecorner.Parent = premiumbadge

					local premiumbadgetext = Instance.new("TextLabel")
					premiumbadgetext.BackgroundTransparency = 1
					premiumbadgetext.Size = UDim2.new(1, 0, 1, 0)
					premiumbadgetext.Text = "PREMIUM"
					premiumbadgetext.TextColor3 = Color3.fromRGB(255, 255, 255)
					premiumbadgetext.TextSize = 7
					premiumbadgetext.Font = Enum.Font.GothamBold
					premiumbadgetext.Parent = premiumbadge
				end

				local cmddesc = Instance.new("TextLabel")
				cmddesc.BackgroundTransparency = 1
				cmddesc.Size = UDim2.new(1, -20, 0, 40)
				cmddesc.Position = UDim2.new(0, 10, 0, 28)
				cmddesc.Text = cmd.desc
				ThemeManager:Register(cmddesc, "TextDark", "TextColor3")
				cmddesc.TextSize = 11
				cmddesc.Font = Enum.Font.Gotham
				cmddesc.TextXAlignment = Enum.TextXAlignment.Left
				cmddesc.TextYAlignment = Enum.TextYAlignment.Top
				cmddesc.TextWrapped = true
				cmddesc.Parent = cmdbox

				local star = Instance.new("TextButton")
				star.Name = "Star"
				star.BackgroundTransparency = 1
				star.Size = UDim2.new(0, 20, 0, 20)
				star.Position = UDim2.new(1, -25, 0, 5)
				star.Text = isfavorite(cmd.name) and "★" or "☆"
				star.TextColor3 = isfavorite(cmd.name) and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(150, 150, 150)
				star.TextSize = 18
				star.Font = Enum.Font.Gotham
				star.ZIndex = 5
				star.Parent = cmdbox

				star.MouseButton1Click:Connect(function()
					togglefavorite(cmd.name)
					star.Text = isfavorite(cmd.name) and "★" or "☆"
					star.TextColor3 = isfavorite(cmd.name) and Color3.fromRGB(255, 220, 0)
						or Color3.fromRGB(150, 150, 150)
				end)

				if cmd.args == 0 and not ismobile then
					local keybindbtn = Instance.new("TextButton")
					ThemeManager:Register(keybindbtn, "Main", "BackgroundColor3")
					keybindbtn.Size = UDim2.new(0, 50, 0, 20)
					keybindbtn.Position = UDim2.new(1, -60, 1, -28)
					keybindbtn.Text = keybinds[cmd.name] or "KEY"
					ThemeManager:Register(keybindbtn, "TextDark", "TextColor3")
					keybindbtn.TextSize = 10
					keybindbtn.Font = Enum.Font.GothamBold
					keybindbtn.AutoButtonColor = false
					keybindbtn.ZIndex = 5
					keybindbtn.Parent = cmdbox

					local keybindbtncorner = Instance.new("UICorner")
					keybindbtncorner.CornerRadius = UDim.new(0, 6)
					keybindbtncorner.Parent = keybindbtn

					keybindbtn.MouseButton1Click:Connect(function()
						keybindbtn.Text = "..."
						local input
						repeat
							input = uis.InputBegan:Wait()
						until input.UserInputType == Enum.UserInputType.Keyboard

						keybinds[cmd.name] = input.KeyCode.Name
						savekeybinds()
						keybindbtn.Text = input.KeyCode.Name
						notify.new("Keybind set to " .. input.KeyCode.Name)
					end)
				end

				if cmd.name == "speed" then
					local speedinput = Instance.new("TextBox")
					ThemeManager:Register(speedinput, "Main", "BackgroundColor3")
					speedinput.Size = UDim2.new(0, 50, 0, 24)
					speedinput.Position = UDim2.new(1, -115, 1, -30)
					speedinput.Text = "16"
					speedinput.PlaceholderText = "16"
					ThemeManager:Register(speedinput, "Text", "TextColor3")
					speedinput.TextSize = 12
					speedinput.Font = Enum.Font.GothamBold
					speedinput.Parent = cmdbox

					local speedcorner = Instance.new("UICorner")
					speedcorner.CornerRadius = UDim.new(0, 6)
					speedcorner.Parent = speedinput

					local resetbtn = Instance.new("TextButton")
					resetbtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
					resetbtn.Size = UDim2.new(0, 50, 0, 24)
					resetbtn.Position = UDim2.new(1, -60, 1, -30)
					resetbtn.Text = "Reset"
					resetbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
					resetbtn.TextSize = 10
					resetbtn.Font = Enum.Font.GothamBold
					resetbtn.Parent = cmdbox

					local resetcorner = Instance.new("UICorner")
					resetcorner.CornerRadius = UDim.new(0, 6)
					resetcorner.Parent = resetbtn

					speedinput:GetPropertyChangedSignal("Text"):Connect(function()
						local num = tonumber(speedinput.Text)
						if num then
							local char = localplr.Character
							local hum = char and char:FindFirstChildOfClass("Humanoid")
							if hum then
								hum.WalkSpeed = num
							end
						end
					end)

					resetbtn.MouseButton1Click:Connect(function()
						speedinput.Text = "16"
						local char = localplr.Character
						local hum = char and char:FindFirstChildOfClass("Humanoid")
						if hum then
							hum.WalkSpeed = 16
						end
					end)
				end

				if cmd.name == "goto" then
					local gotoinput = Instance.new("TextBox")
					ThemeManager:Register(gotoinput, "Main", "BackgroundColor3")
					gotoinput.Size = UDim2.new(0, 115, 0, 24)
					gotoinput.Position = UDim2.new(0, 10, 1, -30)
					gotoinput.Text = ""
					gotoinput.PlaceholderText = "Search player..."
					ThemeManager:Register(gotoinput, "Text", "TextColor3")
					gotoinput.TextSize = 12
					gotoinput.Font = Enum.Font.GothamBold
					gotoinput.TextXAlignment = Enum.TextXAlignment.Left
					gotoinput.Parent = cmdbox

					local gotocorner = Instance.new("UICorner")
					gotocorner.CornerRadius = UDim.new(0, 6)
					gotocorner.Parent = gotoinput

					local dropdown = Instance.new("ScrollingFrame")
					dropdown.Name = "Dropdown"
					ThemeManager:Register(dropdown, "Secondary", "BackgroundColor3")
					dropdown.Size = UDim2.new(0, 135, 0, 120)
					dropdown.Position = UDim2.new(0, 10, 1, 0)
					dropdown.BorderSizePixel = 0
					dropdown.Visible = false
					dropdown.ZIndex = 10
					dropdown.ScrollBarThickness = 2
					dropdown.Parent = cmdbox

					local dropcorner = Instance.new("UICorner")
					dropcorner.CornerRadius = UDim.new(0, 6)
					dropcorner.Parent = dropdown

					local droplayout = Instance.new("UIListLayout")
					droplayout.Padding = UDim.new(0, 2)
					droplayout.Parent = dropdown

					local function updatedropdown(text)
						for _, c in ipairs(dropdown:GetChildren()) do
							if c:IsA("TextButton") then c:Destroy() end
						end

						local count = 0
						for _, plr in ipairs(game.Players:GetPlayers()) do
							if text == "" or plr.Name:lower():find(text:lower()) or plr.DisplayName:lower():find(text:lower()) then
								local item = Instance.new("TextButton")
								ThemeManager:Register(item, "Secondary", "BackgroundColor3")
								item.Size = UDim2.new(1, 0, 0, 24)
								item.Text = plr.DisplayName .. " (@" .. plr.Name .. ")"
								ThemeManager:Register(item, "TextDark", "TextColor3")
								item.TextSize = 11
								item.Font = Enum.Font.Gotham
								item.ZIndex = 11
								item.Parent = dropdown

								item.MouseButton1Click:Connect(function()
									gotoinput.Text = plr.Name
									dropdown.Visible = false
									cmdcore:exec(";goto " .. plr.Name)
								end)

								count = count + 1
							end
						end
						dropdown.CanvasSize = UDim2.new(0, 0, 0, count * 26)
					end

					gotoinput.Focused:Connect(function()
						dropdown.Visible = true
						updatedropdown(gotoinput.Text)
					end)

					gotoinput.FocusLost:Connect(function(enter)
						task.wait(0.2) -- Wait for click
						dropdown.Visible = false
						if enter and gotoinput.Text ~= "" then
							cmdcore:exec(";goto " .. gotoinput.Text)
						end
					end)

					gotoinput:GetPropertyChangedSignal("Text"):Connect(function()
						updatedropdown(gotoinput.Text)
					end)
				end

				cmdbox.MouseEnter:Connect(function()
					anim(
						cmdbox,
						0.3,
						{ BackgroundColor3 = Color3.fromRGB(150, 100, 255) },
						Enum.EasingStyle.Exponential
					):Play()
				end)

				cmdbox.MouseLeave:Connect(function()
					anim(cmdbox, 0.3, { BackgroundColor3 = Color3.fromRGB(30, 30, 30) }, Enum.EasingStyle.Exponential):Play()
				end)

				cmdbox.MouseButton1Click:Connect(function()
					if cmd.premium and not userpremium then
						notify.new("This is a premium command!")
						return
					end

					if cmd.name == "speed" or cmd.name == "goto" then return end -- Custom UI handles this

					if cmd.args > 0 and cmd.popup then
						popupcontainer.Visible = true
						anim(blur, 0.3, { Size = 15 }):Play()
						popupinput.Text = ""
						popupinput:CaptureFocus()

						local currentcmd = cmd

						popupexec.MouseButton1Click:Connect(function()
							if popupinput.Text ~= "" then
								local args = {}
								for word in popupinput.Text:gmatch("%S+") do
									table.insert(args, word)
								end
								currentcmd.func(args, cmdcore)
								popupcontainer.Visible = false
								anim(blur, 0.3, { Size = 0 }):Play()
							end
						end)

						popupcancel.MouseButton1Click:Connect(function()
							popupcontainer.Visible = false
							anim(blur, 0.3, { Size = 0 }):Play()
						end)
					else
						cmd.func({}, cmdcore)
					end
				end)

				count = count + 1
				xpos = xpos + 165
				if count % 4 == 0 then
					xpos = 0
					ypos = ypos + 100
				end
			end
		end

		commandstab.CanvasSize = UDim2.new(0, 0, 0, ypos + 100)
	end

	cmdsearch:GetPropertyChangedSignal("Text"):Connect(function()
		refreshcmds(cmdsearch.Text)
	end)

	refreshcmds("")

	---------- SCRIPT SEARCH TAB ----------
	local searchtab = Instance.new("Frame")
	searchtab.Name = "SearchTab"
	searchtab.BackgroundTransparency = 1
	searchtab.Size = UDim2.new(1, 0, 1, 0)
	searchtab.Visible = false
	searchtab.Parent = tabcontainer

	local searchtitle = Instance.new("TextLabel")
	searchtitle.BackgroundTransparency = 1
	searchtitle.Size = UDim2.new(1, -40, 0, 30)
	searchtitle.Position = UDim2.new(0, 20, 0, 20)
	searchtitle.Text = "Script Search"
	ThemeManager:Register(searchtitle, "Text", "TextColor3")
	searchtitle.TextSize = 24
	searchtitle.Font = Enum.Font.GothamBold
	searchtitle.TextXAlignment = Enum.TextXAlignment.Left
	searchtitle.Parent = searchtab

	---------- ENVIRONMENT TAB ----------
	local environmenttab = Instance.new("ScrollingFrame")
	environmenttab.Name = "EnvironmentTab"
	environmenttab.BackgroundTransparency = 1
	environmenttab.Size = UDim2.new(1, 0, 1, 0)
	environmenttab.ScrollBarThickness = 6
	ThemeManager:Register(environmenttab, "Accent", "ScrollBarImageColor3")
	environmenttab.BorderSizePixel = 0
	environmenttab.Visible = false
	environmenttab.CanvasSize = UDim2.new(0, 0, 0, 560)
	environmenttab.Parent = tabcontainer

	local envtitle = Instance.new("TextLabel")
	envtitle.BackgroundTransparency = 1
	envtitle.Size = UDim2.new(1, -40, 0, 30)
	envtitle.Position = UDim2.new(0, 20, 0, 20)
	envtitle.Text = "Environment"
	ThemeManager:Register(envtitle, "Text", "TextColor3")
	envtitle.TextSize = 24
	envtitle.Font = Enum.Font.GothamBold
	envtitle.TextXAlignment = Enum.TextXAlignment.Left
	envtitle.Parent = environmenttab

	-- Performance Optimizer
	local perfbox = Instance.new("Frame")
	perfbox.Name = "PerformanceBox"
	ThemeManager:Register(perfbox, "Secondary", "BackgroundColor3")
	perfbox.Size = UDim2.new(1, -40, 0, 180)
	perfbox.Position = UDim2.new(0, 20, 0, 60)
	perfbox.Parent = environmenttab

	local perfcorner = Instance.new("UICorner")
	perfcorner.CornerRadius = UDim.new(0, 12)
	perfcorner.Parent = perfbox

	local perflabel = Instance.new("TextLabel")
	perflabel.BackgroundTransparency = 1
	perflabel.Size = UDim2.new(1, -20, 0, 20)
	perflabel.Position = UDim2.new(0, 10, 0, 10)
	perflabel.Text = "Performance Optimizer"
	ThemeManager:Register(perflabel, "Text", "TextColor3")
	perflabel.TextSize = 14
	perflabel.Font = Enum.Font.GothamBold
	perflabel.TextXAlignment = Enum.TextXAlignment.Left
	perflabel.Parent = perfbox

	local perfdesc = Instance.new("TextLabel")
	perfdesc.BackgroundTransparency = 1
	perfdesc.Size = UDim2.new(1, -20, 0, 30)
	perfdesc.Position = UDim2.new(0, 10, 0, 35)
	perfdesc.Text = "Reduce visual effects to prevent lag. Higher strength = better performance."
	ThemeManager:Register(perfdesc, "TextDark", "TextColor3")
	perfdesc.TextSize = 11
	perfdesc.Font = Enum.Font.Gotham
	perfdesc.TextXAlignment = Enum.TextXAlignment.Left
	perfdesc.TextWrapped = true
	perfdesc.Parent = perfbox

	-- Store original settings
	_G.OriginalPerfSettings = _G.OriginalPerfSettings or {}
	local currentPerfLevel = 0

	local function applyPerformanceLevel(level)
		local lighting = game:GetService("Lighting")
		local workspace = game:GetService("Workspace")
		
		if level == 0 then
			-- Restore original settings
			if _G.OriginalPerfSettings.GlobalShadows ~= nil then
				lighting.GlobalShadows = _G.OriginalPerfSettings.GlobalShadows
			end
			if _G.OriginalPerfSettings.Brightness ~= nil then
				lighting.Brightness = _G.OriginalPerfSettings.Brightness
			end
			if _G.OriginalPerfSettings.OutdoorAmbient ~= nil then
				lighting.OutdoorAmbient = _G.OriginalPerfSettings.OutdoorAmbient
			end
			if _G.OriginalPerfSettings.Technology ~= nil then
				lighting.Technology = _G.OriginalPerfSettings.Technology
			end
			
			-- Re-enable particles
			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
					obj.Enabled = true
				end
			end
			
			notify.new("Performance optimizer disabled")
		else
			-- Save original settings on first use
			if not _G.OriginalPerfSettings.GlobalShadows then
				_G.OriginalPerfSettings.GlobalShadows = lighting.GlobalShadows
				_G.OriginalPerfSettings.Brightness = lighting.Brightness
				_G.OriginalPerfSettings.OutdoorAmbient = lighting.OutdoorAmbient
				_G.OriginalPerfSettings.Technology = lighting.Technology
			end
			
			-- Apply performance settings based on level
			if level == 1 then -- Low
				lighting.GlobalShadows = true
				lighting.Technology = Enum.Technology.ShadowMap
				-- Disable some particles
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") and obj.Rate > 50 then
						obj.Enabled = false
					end
				end
				notify.new("Performance: Low (Minimal optimization)")
			elseif level == 2 then -- Medium
				lighting.GlobalShadows = false
				lighting.Technology = Enum.Technology.ShadowMap
				-- Disable more particles
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
						obj.Enabled = false
					end
				end
				notify.new("Performance: Medium (Balanced)")
			elseif level == 3 then -- High
				lighting.GlobalShadows = false
				lighting.Technology = Enum.Technology.Legacy
				lighting.Brightness = 1.5
				-- Disable all particles and effects
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
						obj.Enabled = false
					end
					if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
						obj.Enabled = false
					end
				end
				notify.new("Performance: High (Maximum optimization)")
			elseif level == 4 then -- Ultra
				lighting.GlobalShadows = false
				lighting.Technology = Enum.Technology.Legacy
				lighting.Brightness = 2
				lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
				-- Disable all visual effects
				for _, obj in pairs(workspace:GetDescendants()) do
					if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
						obj.Enabled = false
					end
					if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
						obj.Enabled = false
					end
					if obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
						obj.Enabled = false
					end
				end
				notify.new("Performance: Ultra (Extreme optimization)")
			end
		end
		
		currentPerfLevel = level
	end

	-- Strength buttons
	local perflevels = {
		{name = "Disabled", level = 0, color = Color3.fromRGB(100, 100, 100)},
		{name = "Low", level = 1, color = Color3.fromRGB(100, 200, 100)},
		{name = "Medium", level = 2, color = Color3.fromRGB(255, 200, 0)},
		{name = "High", level = 3, color = Color3.fromRGB(255, 140, 0)},
		{name = "Ultra", level = 4, color = Color3.fromRGB(255, 50, 50)}
	}

	local perfbuttons = {}
	for i, data in ipairs(perflevels) do
		local row = math.floor((i-1) / 3)
		local col = (i-1) % 3
		
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = data.color
		btn.Size = UDim2.new(0, 100, 0, 32)
		btn.Position = UDim2.new(0, 10 + col * 110, 0, 75 + row * 42)
		btn.Text = data.name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 12
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = false
		btn.Parent = perfbox
		
		local btncorner = Instance.new("UICorner")
		btncorner.CornerRadius = UDim.new(0, 8)
		btncorner.Parent = btn
		
		-- Add indicator for active state
		local indicator = Instance.new("Frame")
		indicator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		indicator.Size = UDim2.new(0, 4, 0, 4)
		indicator.Position = UDim2.new(0, 4, 0, 4)
		indicator.BorderSizePixel = 0
		indicator.Visible = (data.level == 0) -- Disabled by default
		indicator.Parent = btn
		
		local indicatorcorner = Instance.new("UICorner")
		indicatorcorner.CornerRadius = UDim.new(1, 0)
		indicatorcorner.Parent = indicator
		
		perfbuttons[data.level] = {btn = btn, indicator = indicator, color = data.color}
		
		btn.MouseButton1Click:Connect(function()
			applyPerformanceLevel(data.level)
			
			-- Update indicators
			for _, btndata in pairs(perfbuttons) do
				btndata.indicator.Visible = false
			end
			indicator.Visible = true
		end)
		
		btn.MouseEnter:Connect(function()
			anim(btn, 0.2, {BackgroundColor3 = Color3.new(
				math.min(data.color.R * 1.2, 1),
				math.min(data.color.G * 1.2, 1),
				math.min(data.color.B * 1.2, 1)
			)}):Play()
		end)
		
		btn.MouseLeave:Connect(function()
			anim(btn, 0.2, {BackgroundColor3 = data.color}):Play()
		end)
	end

	-- Time of Day Control
	local timebox = Instance.new("Frame")
	timebox.Name = "TimeBox"
	ThemeManager:Register(timebox, "Secondary", "BackgroundColor3")
	timebox.Size = UDim2.new(1, -40, 0, 100)
	timebox.Position = UDim2.new(0, 20, 0, 250)
	timebox.Parent = environmenttab

	local timecorner = Instance.new("UICorner")
	timecorner.CornerRadius = UDim.new(0, 12)
	timecorner.Parent = timebox

	local timelabel = Instance.new("TextLabel")
	timelabel.BackgroundTransparency = 1
	timelabel.Size = UDim2.new(1, -20, 0, 20)
	timelabel.Position = UDim2.new(0, 10, 0, 10)
	timelabel.Text = "Time of Day"
	ThemeManager:Register(timelabel, "Text", "TextColor3")
	timelabel.TextSize = 14
	timelabel.Font = Enum.Font.GothamBold
	timelabel.TextXAlignment = Enum.TextXAlignment.Left
	timelabel.Parent = timebox

	local timevalue = Instance.new("TextLabel")
	timevalue.BackgroundTransparency = 1
	timevalue.Size = UDim2.new(0, 100, 0, 20)
	timevalue.Position = UDim2.new(1, -110, 0, 10)
	timevalue.Text = "12:00"
	ThemeManager:Register(timevalue, "TextDark", "TextColor3")
	timevalue.TextSize = 13
	timevalue.Font = Enum.Font.GothamMedium
	timevalue.TextXAlignment = Enum.TextXAlignment.Right
	timevalue.Parent = timebox

	local sliderback = Instance.new("Frame")
	ThemeManager:Register(sliderback, "Main", "BackgroundColor3")
	sliderback.Size = UDim2.new(1, -40, 0, 6)
	sliderback.Position = UDim2.new(0, 20, 0, 50)
	sliderback.BorderSizePixel = 0
	sliderback.Parent = timebox

	local sliderbackcorner = Instance.new("UICorner")
	sliderbackcorner.CornerRadius = UDim.new(1, 0)
	sliderbackcorner.Parent = sliderback

	local sliderfill = Instance.new("Frame")
	ThemeManager:Register(sliderfill, "Accent", "BackgroundColor3")
	sliderfill.Size = UDim2.new(0.5, 0, 1, 0)
	sliderfill.BorderSizePixel = 0
	sliderfill.Parent = sliderback

	local sliderfillcorner = Instance.new("UICorner")
	sliderfillcorner.CornerRadius = UDim.new(1, 0)
	sliderfillcorner.Parent = sliderfill

	local sliderknob = Instance.new("Frame")
	ThemeManager:Register(sliderknob, "Accent", "BackgroundColor3")
	sliderknob.Size = UDim2.new(0, 16, 0, 16)
	sliderknob.Position = UDim2.new(0.5, -8, 0.5, -8)
	sliderknob.BorderSizePixel = 0
	sliderknob.Parent = sliderback

	local sliderknobcorner = Instance.new("UICorner")
	sliderknobcorner.CornerRadius = UDim.new(1, 0)
	sliderknobcorner.Parent = sliderknob

	local draggingSlider = false
	local function updateTimeSlider(input)
		local pos = math.clamp((input.Position.X - sliderback.AbsolutePosition.X) / sliderback.AbsoluteSize.X, 0, 1)
		sliderfill.Size = UDim2.new(pos, 0, 1, 0)
		sliderknob.Position = UDim2.new(pos, -8, 0.5, -8)

		local hour = math.floor(pos * 24)
		local minute = math.floor((pos * 24 - hour) * 60)
		timevalue.Text = string.format("%02d:%02d", hour, minute)

		game:GetService("Lighting").ClockTime = hour + (minute / 60)
	end

	sliderback.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = true
			updateTimeSlider(input)
		end
	end)

	sliderback.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingSlider = false
		end
	end)

	uis.InputChanged:Connect(function(input)
		if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateTimeSlider(input)
		end
	end)

	-- Quick time buttons
	local quicktimes = {
		{name = "Dawn", time = 6},
		{name = "Noon", time = 12},
		{name = "Dusk", time = 18},
		{name = "Night", time = 0}
	}

	for i, data in ipairs(quicktimes) do
		local btn = Instance.new("TextButton")
		ThemeManager:Register(btn, "Main", "BackgroundColor3")
		btn.Size = UDim2.new(0, 70, 0, 24)
		btn.Position = UDim2.new(0, 20 + (i-1) * 80, 0, 68)
		btn.Text = data.name
		ThemeManager:Register(btn, "TextDark", "TextColor3")
		btn.TextSize = 11
		btn.Font = Enum.Font.GothamMedium
		btn.AutoButtonColor = false
		btn.Parent = timebox

		local btncorner = Instance.new("UICorner")
		btncorner.CornerRadius = UDim.new(0, 6)
		btncorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			game:GetService("Lighting").ClockTime = data.time
			local pos = data.time / 24
			sliderfill.Size = UDim2.new(pos, 0, 1, 0)
			sliderknob.Position = UDim2.new(pos, -8, 0.5, -8)
			timevalue.Text = string.format("%02d:00", data.time)
		end)

		btn.MouseEnter:Connect(function()
			anim(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
		end)

		btn.MouseLeave:Connect(function()
			local palette = themes[(_G.SyncSettings and _G.SyncSettings.theme) or "Dark"]
			anim(btn, 0.2, {BackgroundColor3 = palette.Main}):Play()
		end)
	end

	-- Sky Color Control
	local skybox = Instance.new("Frame")
	skybox.Name = "SkyBox"
	ThemeManager:Register(skybox, "Secondary", "BackgroundColor3")
	skybox.Size = UDim2.new(1, -40, 0, 120)
	skybox.Position = UDim2.new(0, 20, 0, 360)
	skybox.Parent = environmenttab

	local skycorner = Instance.new("UICorner")
	skycorner.CornerRadius = UDim.new(0, 12)
	skycorner.Parent = skybox

	local skylabel = Instance.new("TextLabel")
	skylabel.BackgroundTransparency = 1
	skylabel.Size = UDim2.new(1, -20, 0, 20)
	skylabel.Position = UDim2.new(0, 10, 0, 10)
	skylabel.Text = "Sky & Atmosphere"
	ThemeManager:Register(skylabel, "Text", "TextColor3")
	skylabel.TextSize = 14
	skylabel.Font = Enum.Font.GothamBold
	skylabel.TextXAlignment = Enum.TextXAlignment.Left
	skylabel.Parent = skybox

	-- Sky color presets
	local skypresets = {
		{name = "Default", color = Color3.fromRGB(135, 206, 235)},
		{name = "Sunset", color = Color3.fromRGB(255, 140, 60)},
		{name = "Night", color = Color3.fromRGB(25, 25, 50)},
		{name = "Purple", color = Color3.fromRGB(180, 100, 255)},
	}

	for i, preset in ipairs(skypresets) do
		local btn = Instance.new("TextButton")
		btn.BackgroundColor3 = preset.color
		btn.Size = UDim2.new(0, 60, 0, 28)
		btn.Position = UDim2.new(0, 10 + (i-1) * 70, 0, 40)
		btn.Text = preset.name
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 10
		btn.Font = Enum.Font.GothamBold
		btn.AutoButtonColor = false
		btn.Parent = skybox

		local btncorner = Instance.new("UICorner")
		btncorner.CornerRadius = UDim.new(0, 8)
		btncorner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			local lighting = game:GetService("Lighting")
			lighting.Ambient = preset.color
			lighting.OutdoorAmbient = preset.color
			notify.new("Sky color set to " .. preset.name)
		end)
	end

	-- Brightness control
	local brightlabel = Instance.new("TextLabel")
	brightlabel.BackgroundTransparency = 1
	brightlabel.Size = UDim2.new(0, 100, 0, 20)
	brightlabel.Position = UDim2.new(0, 10, 0, 78)
	brightlabel.Text = "Brightness"
	ThemeManager:Register(brightlabel, "TextDark", "TextColor3")
	brightlabel.TextSize = 12
	brightlabel.Font = Enum.Font.Gotham
	brightlabel.TextXAlignment = Enum.TextXAlignment.Left
	brightlabel.Parent = skybox

	local brightinput = Instance.new("TextBox")
	ThemeManager:Register(brightinput, "Main", "BackgroundColor3")
	brightinput.Size = UDim2.new(0, 60, 0, 24)
	brightinput.Position = UDim2.new(0, 110, 0, 76)
	brightinput.Text = "2"
	brightinput.PlaceholderText = "0-10"
	ThemeManager:Register(brightinput, "Text", "TextColor3")
	brightinput.TextSize = 11
	brightinput.Font = Enum.Font.Gotham
	brightinput.Parent = skybox

	local brightcorner = Instance.new("UICorner")
	brightcorner.CornerRadius = UDim.new(0, 6)
	brightcorner.Parent = brightinput

	brightinput.FocusLost:Connect(function()
		local val = tonumber(brightinput.Text)
		if val then
			game:GetService("Lighting").Brightness = math.clamp(val, 0, 10)
			notify.new("Brightness set to " .. val)
		end
	end)

	-- Reset button
	local resetbtn = Instance.new("TextButton")
	resetbtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	resetbtn.Size = UDim2.new(0, 150, 0, 36)
	resetbtn.Position = UDim2.new(0, 20, 0, 500)
	resetbtn.Text = "Reset to Default"
	resetbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	resetbtn.TextSize = 13
	resetbtn.Font = Enum.Font.GothamBold
	resetbtn.AutoButtonColor = false
	resetbtn.Parent = environmenttab

	local resetcorner = Instance.new("UICorner")
	resetcorner.CornerRadius = UDim.new(0, 10)
	resetcorner.Parent = resetbtn

	resetbtn.MouseButton1Click:Connect(function()
		local lighting = game:GetService("Lighting")
		lighting.ClockTime = 14
		lighting.Brightness = 2
		lighting.Ambient = Color3.fromRGB(135, 206, 235)
		lighting.OutdoorAmbient = Color3.fromRGB(135, 206, 235)
		
		-- Reset performance optimizer
		applyPerformanceLevel(0)
		for _, btndata in pairs(perfbuttons) do
			btndata.indicator.Visible = false
		end
		perfbuttons[0].indicator.Visible = true
		
		-- Reset UI
		sliderfill.Size = UDim2.new(14/24, 0, 1, 0)
		sliderknob.Position = UDim2.new(14/24, -8, 0.5, -8)
		timevalue.Text = "14:00"
		brightinput.Text = "2"
		
		notify.new("Environment reset to default")
	end)

	resetbtn.MouseEnter:Connect(function()
		anim(resetbtn, 0.2, {BackgroundColor3 = Color3.fromRGB(255, 70, 70)}):Play()
	end)

	resetbtn.MouseLeave:Connect(function()
		anim(resetbtn, 0.2, {BackgroundColor3 = Color3.fromRGB(200, 50, 50)}):Play()
	end)

	---------- SETTINGS TAB ----------
	local settingstab = Instance.new("ScrollingFrame")
	settingstab.Name = "SettingsTab"
	settingstab.BackgroundTransparency = 1
	settingstab.Size = UDim2.new(1, 0, 1, 0)
	settingstab.ScrollBarThickness = 6
	ThemeManager:Register(settingstab, "Accent", "ScrollBarImageColor3")
	settingstab.BorderSizePixel = 0
	settingstab.Visible = false
	settingstab.CanvasSize = UDim2.new(0, 0, 0, 300)
	settingstab.Parent = tabcontainer

	local settingstitle = Instance.new("TextLabel")
	settingstitle.BackgroundTransparency = 1
	settingstitle.Size = UDim2.new(1, -40, 0, 30)
	settingstitle.Position = UDim2.new(0, 20, 0, 20)
	settingstitle.Text = "Settings"
	ThemeManager:Register(settingstitle, "Text", "TextColor3")
	settingstitle.TextSize = 24
	settingstitle.Font = Enum.Font.GothamBold
	settingstitle.TextXAlignment = Enum.TextXAlignment.Left
	settingstitle.Parent = settingstab

	-- Draggable Toggle
	local dragbox = Instance.new("Frame")
	dragbox.Name = "DragBox"
	ThemeManager:Register(dragbox, "Secondary", "BackgroundColor3")
	dragbox.Size = UDim2.new(1, -40, 0, 60)
	dragbox.Position = UDim2.new(0, 20, 0, 60)
	dragbox.Parent = settingstab

	local dragcorner = Instance.new("UICorner")
	dragcorner.CornerRadius = UDim.new(0, 12)
	dragcorner.Parent = dragbox

	local draglabel = Instance.new("TextLabel")
	draglabel.BackgroundTransparency = 1
	draglabel.Size = UDim2.new(1, -20, 0, 20)
	draglabel.Position = UDim2.new(0, 10, 0, 10)
	draglabel.Text = "Enable All Draggable GUIs"
	ThemeManager:Register(draglabel, "Text", "TextColor3")
	draglabel.TextSize = 14
	draglabel.Font = Enum.Font.GothamBold
	draglabel.TextXAlignment = Enum.TextXAlignment.Left
	draglabel.Parent = dragbox

	local dragbtn = Instance.new("TextButton")
	ThemeManager:Register(dragbtn, "Main", "BackgroundColor3")
	dragbtn.Size = UDim2.new(0, 80, 0, 28)
	dragbtn.Position = UDim2.new(0, 10, 0, 28)
	dragbtn.Text = "OFF"
	ThemeManager:Register(dragbtn, "TextDark", "TextColor3")
	dragbtn.TextSize = 12
	dragbtn.Font = Enum.Font.GothamMedium
	dragbtn.Parent = dragbox

	local dragbtncorner = Instance.new("UICorner")
	dragbtncorner.CornerRadius = UDim.new(0, 8)
	dragbtncorner.Parent = dragbtn

	dragbtn.MouseButton1Click:Connect(function()
		allDraggable = not allDraggable
		dragbtn.Text = allDraggable and "ON" or "OFF"
		dragbtn.TextColor3 = allDraggable and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
	end)

	if not ismobile then
		local settingbox = Instance.new("Frame")
		settingbox.Name = "KeybindBox"
		ThemeManager:Register(settingbox, "Secondary", "BackgroundColor3")
		settingbox.Size = UDim2.new(1, -40, 0, 60)
		settingbox.Position = UDim2.new(0, 20, 0, 130) -- Adjusted position
		settingbox.Parent = settingstab

		local settingcorner = Instance.new("UICorner")
		settingcorner.CornerRadius = UDim.new(0, 12)
		settingcorner.Parent = settingbox

		local settinglabel = Instance.new("TextLabel")
		settinglabel.BackgroundTransparency = 1
		settinglabel.Size = UDim2.new(1, -20, 0, 20)
		settinglabel.Position = UDim2.new(0, 10, 0, 10)
		settinglabel.Text = "Command Bar Toggle Key"
		ThemeManager:Register(settinglabel, "Text", "TextColor3")
		settinglabel.TextSize = 14
		settinglabel.Font = Enum.Font.GothamBold
		settinglabel.TextXAlignment = Enum.TextXAlignment.Left
		settinglabel.Parent = settingbox

		local keybindbutton = Instance.new("TextButton")
		ThemeManager:Register(keybindbutton, "Main", "BackgroundColor3")
		keybindbutton.Size = UDim2.new(0, 80, 0, 28)
		keybindbutton.Position = UDim2.new(0, 10, 0, 28)
		keybindbutton.Text = cmdtogglekey.Name
		ThemeManager:Register(keybindbutton, "TextDark", "TextColor3")
		keybindbutton.TextSize = 12
		keybindbutton.Font = Enum.Font.GothamMedium
		keybindbutton.Parent = settingbox
		keybindbutton.MouseButton1Click:Connect(function()
			keybindbutton.Text = "..."
			local input
			repeat
				input = uis.InputBegan:Wait()
			until input.UserInputType == Enum.UserInputType.Keyboard
			cmdtogglekey = input.KeyCode
			keybindbutton.Text = cmdtogglekey.Name
			writefile("sync/keybind.json", cmdtogglekey.Name)

			-- Prevent immediate trigger
			task.delay(0.1, function()
				cmdtogglekey = Enum.KeyCode[readfile("sync/keybind.json")]
			end)
		end)

		local keybindcorner = Instance.new("UICorner")
		keybindcorner.CornerRadius = UDim.new(0, 8)
		keybindcorner.Parent = keybindbutton
	end

	-- Notification Duration Setting
	local notifbox = Instance.new("Frame")
	notifbox.Name = "NotifBox"
	ThemeManager:Register(notifbox, "Secondary", "BackgroundColor3")
	notifbox.Size = UDim2.new(1, -40, 0, 60)
	notifbox.Position = UDim2.new(0, 20, 0, 200)
	notifbox.Parent = settingstab

	local notifcorner = Instance.new("UICorner")
	notifcorner.CornerRadius = UDim.new(0, 12)
	notifcorner.Parent = notifbox

	local notiflabel = Instance.new("TextLabel")
	notiflabel.BackgroundTransparency = 1
	notiflabel.Size = UDim2.new(1, -20, 0, 20)
	notiflabel.Position = UDim2.new(0, 10, 0, 10)
	notiflabel.Text = "Notification Duration (s)"
	ThemeManager:Register(notiflabel, "Text", "TextColor3")
	notiflabel.TextSize = 14
	notiflabel.Font = Enum.Font.GothamBold
	notiflabel.TextXAlignment = Enum.TextXAlignment.Left
	notiflabel.Parent = notifbox

	local notifinput = Instance.new("TextBox")
	ThemeManager:Register(notifinput, "Main", "BackgroundColor3")
	notifinput.Size = UDim2.new(0, 80, 0, 28)
	notifinput.Position = UDim2.new(0, 10, 0, 28)
	notifinput.Text = tostring(_G.SyncSettings.notifDuration)
	ThemeManager:Register(notifinput, "TextDark", "TextColor3")
	notifinput.TextSize = 12
	notifinput.Font = Enum.Font.GothamMedium
	notifinput.Parent = notifbox

	local notifinputcorner = Instance.new("UICorner")
	notifinputcorner.CornerRadius = UDim.new(0, 8)
	notifinputcorner.Parent = notifinput

	notifinput.FocusLost:Connect(function()
		local num = tonumber(notifinput.Text)
		if num then
			_G.SyncSettings.notifDuration = num
			saveSettings()
		else
			notifinput.Text = tostring(_G.SyncSettings.notifDuration)
		end
	end)

	-- Welcome Animation Toggle
	local welcomebox = Instance.new("Frame")
	welcomebox.Name = "WelcomeBox"
	ThemeManager:Register(welcomebox, "Secondary", "BackgroundColor3")
	welcomebox.Size = UDim2.new(1, -40, 0, 60)
	welcomebox.Position = UDim2.new(0, 20, 0, 270)
	welcomebox.Parent = settingstab

	local welcomecorner = Instance.new("UICorner")
	welcomecorner.CornerRadius = UDim.new(0, 12)
	welcomecorner.Parent = welcomebox

	local welcomelabel = Instance.new("TextLabel")
	welcomelabel.BackgroundTransparency = 1
	welcomelabel.Size = UDim2.new(1, -20, 0, 20)
	welcomelabel.Position = UDim2.new(0, 10, 0, 10)
	welcomelabel.Text = "Show Welcome Animation"
	ThemeManager:Register(welcomelabel, "Text", "TextColor3")
	welcomelabel.TextSize = 14
	welcomelabel.Font = Enum.Font.GothamBold
	welcomelabel.TextXAlignment = Enum.TextXAlignment.Left
	welcomelabel.Parent = welcomebox

	local welcomebtn = Instance.new("TextButton")
	ThemeManager:Register(welcomebtn, "Main", "BackgroundColor3")
	welcomebtn.Size = UDim2.new(0, 80, 0, 28)
	welcomebtn.Position = UDim2.new(0, 10, 0, 28)
	welcomebtn.Text = _G.SyncSettings.showWelcome and "ON" or "OFF"
	ThemeManager:Register(welcomebtn, "TextDark", "TextColor3")
	welcomebtn.TextSize = 12
	welcomebtn.Font = Enum.Font.GothamMedium
	welcomebtn.Parent = welcomebox

	local welcomebtncorner = Instance.new("UICorner")
	welcomebtncorner.CornerRadius = UDim.new(0, 8)
	welcomebtncorner.Parent = welcomebtn

	welcomebtn.MouseButton1Click:Connect(function()
		_G.SyncSettings.showWelcome = not _G.SyncSettings.showWelcome
		welcomebtn.Text = _G.SyncSettings.showWelcome and "ON" or "OFF"
		welcomebtn.TextColor3 = _G.SyncSettings.showWelcome and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
		saveSettings()
	end)

	-- Theme Selector (Dropdown)
	local themes = {"Dark", "Light", "Midnight", "Ocean", "Rose", "Forest", "Amethyst", "Sunset"}
	local themebox = createDropdown(settingstab, "Theme", themes, _G.SyncSettings.theme, function(val)
		ThemeManager:Apply(val)
		notify.new("Theme changed to " .. val)
	end)
	themebox.Position = UDim2.new(0, 20, 0, 340)

	settingstab.CanvasSize = UDim2.new(0, 0, 0, 420)

	---------- ICON SETUP ----------
	local tabs = {hometab, commandstab, searchtab, environmenttab, settingstab}
	local currentTabIndex = 1



	for i, data in ipairs(icondata) do
		local xpos = startx + (i - 1) * (iconsize + iconspacing)

		local iconbtn = Instance.new("TextButton")
		iconbtn.Name = "Icon" .. i
		ThemeManager:Register(iconbtn, "Secondary", "BackgroundColor3")
		iconbtn.Size = UDim2.new(0, iconsize, 0, iconsize)
		iconbtn.Position = UDim2.new(0, xpos, 0, (navh - iconsize) / 2)
		iconbtn.Text = ""
		iconbtn.AutoButtonColor = false
		iconbtn.BackgroundTransparency = 1
		iconbtn.ZIndex = 2
		iconbtn.Parent = ball

		local iconcorner = Instance.new("UICorner")
		iconcorner.CornerRadius = UDim.new(0, 10)
		iconcorner.Parent = iconbtn

		local iconimg = Instance.new("ImageLabel")
		iconimg.Name = "Img"
		iconimg.BackgroundTransparency = 1
		iconimg.Size = UDim2.new(0, 18, 0, 18)
		iconimg.Position = UDim2.new(0.5, -9, 0.5, -9)
		iconimg.Image = "rbxassetid://" .. data.id
		ThemeManager:Register(iconimg, "Text", "ImageColor3")
		iconimg.ImageTransparency = 1
		iconimg.ZIndex = 3
		iconimg.Parent = iconbtn

		local label = Instance.new("TextLabel")
		label.Name = "Label"
		ThemeManager:Register(label, "Secondary", "BackgroundColor3")
		label.Size = UDim2.new(0, 0, 0, 24)
		label.Position = UDim2.new(0.5, 0, 1, 6)
		label.AnchorPoint = Vector2.new(0.5, 0)
		label.Text = data.name
		ThemeManager:Register(label, "Text", "TextColor3")
		label.TextSize = 11
		label.Font = Enum.Font.GothamMedium
		label.TextTransparency = 1
		label.BackgroundTransparency = 1
		label.ZIndex = 5
		label.Parent = iconbtn

		local labelcorner = Instance.new("UICorner")
		labelcorner.CornerRadius = UDim.new(0, 6)
		labelcorner.Parent = label

		iconbtn.MouseEnter:Connect(function()
			currenthover = i
			local targetx = xpos - 3
			anim(lavalamp, 0.5, {
				Position = UDim2.new(0, targetx, 0, (navh - iconsize) / 2 - 3),
				BackgroundTransparency = 0,
			}, Enum.EasingStyle.Exponential):Play()

			local txtbounds = label.TextBounds.X
			label.Size = UDim2.new(0, 0, 0, 24)
			anim(label, 0.3, {
				Size = UDim2.new(0, txtbounds + 12, 0, 24),
				BackgroundTransparency = 0,
				TextTransparency = 0,
			}):Play()
		end)

		iconbtn.MouseLeave:Connect(function()
			currenthover = nil
			anim(lavalamp, 0.4, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine):Play()
			anim(label, 0.2, {
				Size = UDim2.new(0, 0, 0, 24),
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}):Play()
		end)

		iconbtn.MouseButton1Click:Connect(function()
			local tabname = data.name:lower():gsub(" ", "")

			if tabopen and currentTabIndex == i then
				-- Close current tab
				tabopen = false
				anim(blur, 0.3, { Size = 0 }):Play()

				-- Smooth close animation
				anim(tabcontainer, 0.3, {
					Size = UDim2.new(0, 0, 0, 0),
					Position = UDim2.new(0.5, 0, 0, 80),
					BackgroundTransparency = 1
				}, Enum.EasingStyle.Exponential):Play()

				task.delay(0.3, function()
					if not tabopen then
						tabcontainer.Visible = false
						tabcontainer.BackgroundTransparency = 0
					end
				end)
				return
			end

			-- Open or Switch Tab
			if not tabopen then
				-- Opening from closed state
				currentTabIndex = i
				for _, t in ipairs(tabs) do t.Visible = false end
				tabs[i].Visible = true
				tabs[i].Position = UDim2.new(0, 0, 0, 0)

				tabopen = true
				tabcontainer.Visible = true
				tabcontainer.Size = UDim2.new(0, 0, 0, 0)
				tabcontainer.Position = UDim2.new(0.5, 0, 0, 80)
				anim(blur, 0.3, { Size = 15 }):Play()
				anim(tabcontainer, 0.7, {
					Size = UDim2.new(0, 700, 0, 450),
					Position = UDim2.new(0.5, 0, 0, 80),
				}, Enum.EasingStyle.Exponential):Play()
			else
				-- Switching tabs (Sliding animation)
				local oldTab = tabs[currentTabIndex]
				local newTab = tabs[i]
				local direction = (i > currentTabIndex) and 1 or -1

				newTab.Visible = true
				newTab.Position = UDim2.new(direction, 0, 0, 0)

				anim(oldTab, 0.5, { Position = UDim2.new(-direction, 0, 0, 0) }, Enum.EasingStyle.Exponential):Play()
				anim(newTab, 0.5, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Exponential):Play()

				currentTabIndex = i

				task.delay(0.5, function()
					if currentTabIndex ~= i then return end -- changed while waiting
					oldTab.Visible = false
				end)
			end

			if tabname == "home" then
				tabcontainer.BackgroundTransparency = 1
			else
				tabcontainer.BackgroundTransparency = 0
			end
		end)

		table.insert(icons, { btn = iconbtn, img = iconimg, xpos = xpos, label = label })
	end

	task.wait(0.3)

	for i, icon in ipairs(icons) do
		task.wait(0.08)
		anim(icon.btn, 0.3, { BackgroundTransparency = 0 }):Play()
		anim(icon.img, 0.3, { ImageTransparency = 0 }):Play()
	end

	---------- DRAGGING SYSTEM ----------
    --[[
    
    kann einer das adden? 
    
    also sodass wenn es minimized ist und man draufdrückt und zieht

    dass es dann draggable ist und kommt drauf an ob man es oben/unten oder links/rechts macht

    wenn oben/unten dann soll es normal expanden

    wenn links/rechts dann soll es seitlich expanden.

    ]]



	---------- COMMAND BAR ----------
	if not ismobile then
		local cmdbarcontainer = Instance.new("Frame")
		cmdbarcontainer.Name = "CmdBar"
		ThemeManager:Register(cmdbarcontainer, "Main", "BackgroundColor3")
		cmdbarcontainer.Size = UDim2.new(0, 500, 0, 50)
		cmdbarcontainer.Position = UDim2.new(0.5, -250, 0, -170)
		cmdbarcontainer.BorderSizePixel = 0
		cmdbarcontainer.Parent = screen
		makeDraggable(cmdbarcontainer, true)

		local cmdbarcorner = Instance.new("UICorner")
		cmdbarcorner.CornerRadius = UDim.new(0, 14)
		cmdbarcorner.Parent = cmdbarcontainer

		local cmdbarinput = Instance.new("TextBox")
		cmdbarinput.BackgroundTransparency = 1
		cmdbarinput.Size = UDim2.new(1, -20, 1, 0)
		cmdbarinput.Position = UDim2.new(0, 10, 0, 0)
		cmdbarinput.PlaceholderText = "Type a command..."
		ThemeManager:Register(cmdbarinput, "TextDark", "PlaceholderColor3")
		cmdbarinput.Text = ""
		ThemeManager:Register(cmdbarinput, "Text", "TextColor3")
		cmdbarinput.TextSize = 15
		cmdbarinput.Font = Enum.Font.Gotham
		cmdbarinput.TextXAlignment = Enum.TextXAlignment.Left
		cmdbarinput.ClearTextOnFocus = false
		cmdbarinput.Parent = cmdbarcontainer

		uis.InputBegan:Connect(function(input, gpe)
			if gpe then
				return
			end

			if input.KeyCode == cmdtogglekey then
				cmdbaropen = not cmdbaropen

				if cmdbaropen then
					anim(
						cmdbarcontainer,
						0.6,
						{ Position = UDim2.new(0.5, -250, 0, 150) },
						Enum.EasingStyle.Exponential
					):Play()
					task.wait(0.6)
					cmdbarinput:CaptureFocus()
				else
					cmdbarinput.Text = ""
					cmdbarinput:ReleaseFocus()
					anim(
						cmdbarcontainer,
						0.6,
						{ Position = UDim2.new(0.5, -250, 0, -170) },
						Enum.EasingStyle.Exponential
					):Play()
				end
			end
		end)

		cmdbarinput.FocusLost:Connect(function(enter)
			if enter and cmdbarinput.Text ~= "" then
				cmdcore:exec(";" .. cmdbarinput.Text)
				cmdbarinput.Text = ""
			end

			if cmdbaropen then
				cmdbarinput.Text = ""
				anim(cmdbarcontainer, 0.6, { Position = UDim2.new(0.5, -250, 0, -170) }, Enum.EasingStyle.Exponential):Play()
				cmdbaropen = false
			end
		end)
	end

	notify.new("Welcome to Sync!")

	return
end

---------- NEW USER PATH (VERIFICATION) ----------
if _G.SyncSettings.showWelcome then
	anim(container, 0.4, { Position = UDim2.new(0.5, 0, 0, 30) }, Enum.EasingStyle.Exponential):Play()
	task.wait(0.1)
	anim(ball, 0.2, { BackgroundTransparency = 0 }):Play()
	anim(island, 0.2, { BackgroundTransparency = 0 }):Play()
	anim(welcome, 0.2, { TextTransparency = 0 }):Play()
	anim(pfp, 0.2, { ImageTransparency = 0 }):Play()

	task.wait(1)

	anim(welcome, 0.2, { TextTransparency = 1 }, Enum.EasingStyle.Sine):Play()
	anim(pfp, 0.2, { ImageTransparency = 1 }, Enum.EasingStyle.Sine):Play()

	task.wait(0.2)

	local shrink = anim(
		island,
		0.4,
		{ Size = UDim2.new(0, 50, 0, 50), Position = UDim2.new(0, 0, 0, 0) },
		Enum.EasingStyle.Exponential
	)
	local fade = anim(island, 0.2, { BackgroundTransparency = 1 }, Enum.EasingStyle.Sine)
	shrink:Play()
	task.wait(0.2)
	fade:Play()
	shrink.Completed:Wait()

	island:Destroy()
	welcome:Destroy()

	container.AnchorPoint = Vector2.new(0.5, 0.5)
	local move =
		anim(container, 0.4, { Position = UDim2.new(0.5, 0, 0.5, 0) }, Enum.EasingStyle.Exponential)
	move:Play()
	move.Completed:Wait()
else
	-- Skip animation setup
	island:Destroy()
	welcome:Destroy()
	pfp:Destroy()

	ball.BackgroundTransparency = 0
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.Position = UDim2.new(0.5, 0, 0.5, 0)
end

local mainw = 600
local mainh = 400

local expand = anim(
	ball,
	0.5,
	{ Size = UDim2.new(0, mainw, 0, mainh), Position = UDim2.new(0, -mainw / 2 + 25, 0, -mainh / 2 + 25) },
	Enum.EasingStyle.Exponential
)
local roundcorner = anim(ballcorner, 0.5, { CornerRadius = UDim.new(0, 20) }, Enum.EasingStyle.Exponential)
expand:Play()
roundcorner:Play()
expand.Completed:Wait()

pfp:Destroy()
container.Size = UDim2.new(0, mainw, 0, mainh)
container.Position = UDim2.new(0.5, 0, 0.5, 0)
ball.Size = UDim2.new(1, 0, 1, 0)
ball.Position = UDim2.new(0, 0, 0, 0)

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Size = UDim2.new(0, 200, 0, 30)
title.Position = UDim2.new(0, 25, 0, 25)
title.Text = "Sync"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 26
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTransparency = 1
title.Parent = ball

local sep = Instance.new("Frame")
sep.Name = "Sep"
sep.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
sep.BorderSizePixel = 0
sep.Size = UDim2.new(0, 250, 0, 2)
sep.Position = UDim2.new(0, 25, 0, 65)
sep.BackgroundTransparency = 1
sep.Parent = ball

local msg = Instance.new("TextLabel")
msg.Name = "Msg"
msg.BackgroundTransparency = 1
msg.Size = UDim2.new(0, 250, 0, 70)
msg.Position = UDim2.new(0, 25, 0, 80)
msg.Text = "Greetings "
	.. localplr.DisplayName
	.. ", it seems like it's your first time using our script. Please read the instructions below."
msg.TextColor3 = Color3.fromRGB(200, 200, 200)
msg.TextSize = 14
msg.Font = Enum.Font.Gotham
msg.TextXAlignment = Enum.TextXAlignment.Left
msg.TextYAlignment = Enum.TextYAlignment.Top
msg.TextWrapped = true
msg.TextTransparency = 1
msg.Parent = ball

local codebox = Instance.new("Frame")
codebox.Name = "Codebox"
codebox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
codebox.Size = UDim2.new(0, 280, 0, 110)
codebox.Position = UDim2.new(0, 295, 0, 25)
codebox.BackgroundTransparency = 1
codebox.Parent = ball

local codeboxcorner = Instance.new("UICorner")
codeboxcorner.CornerRadius = UDim.new(0, 15)
codeboxcorner.Parent = codebox

local codetitle = Instance.new("TextLabel")
codetitle.Name = "Codetitle"
codetitle.BackgroundTransparency = 1
codetitle.Size = UDim2.new(1, -20, 0, 20)
codetitle.Position = UDim2.new(0, 10, 0, 10)
codetitle.Text = "YOUR CODE"
codetitle.TextColor3 = Color3.fromRGB(180, 180, 180)
codetitle.TextSize = 12
codetitle.Font = Enum.Font.GothamMedium
codetitle.TextXAlignment = Enum.TextXAlignment.Left
codetitle.TextTransparency = 1
codetitle.Parent = codebox

local codewarning = Instance.new("TextLabel")
codewarning.Name = "Codewarning"
codewarning.BackgroundTransparency = 1
codewarning.Size = UDim2.new(1, -20, 0, 15)
codewarning.Position = UDim2.new(0, 10, 0, 28)
codewarning.Text = "dont share this with anyone."
codewarning.TextColor3 = Color3.fromRGB(140, 140, 140)
codewarning.TextSize = 10
codewarning.Font = Enum.Font.Gotham
codewarning.TextXAlignment = Enum.TextXAlignment.Left
codewarning.TextTransparency = 1
codewarning.Parent = codebox

local codefields = Instance.new("Frame")
codefields.Name = "Fields"
codefields.BackgroundTransparency = 1
codefields.Size = UDim2.new(1, -20, 0, 50)
codefields.Position = UDim2.new(0, 10, 0, 50)
codefields.Parent = codebox

local fieldlayout = Instance.new("UIListLayout")
fieldlayout.FillDirection = Enum.FillDirection.Horizontal
fieldlayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
fieldlayout.VerticalAlignment = Enum.VerticalAlignment.Center
fieldlayout.Padding = UDim.new(0, 8)
fieldlayout.Parent = codefields

local fields = {}
for i = 1, 5 do
	local field = Instance.new("TextLabel")
	field.Name = "Field" .. i
	field.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	field.Size = UDim2.new(0, 42, 0, 50)
	field.Text = ""
	field.TextColor3 = Color3.fromRGB(150, 150, 150)
	field.TextSize = 20
	field.Font = Enum.Font.GothamBold
	field.BackgroundTransparency = 1
	field.TextTransparency = 1
	field.Parent = codefields

	local fieldcorner = Instance.new("UICorner")
	fieldcorner.CornerRadius = UDim.new(0, 12)
	fieldcorner.Parent = field

	table.insert(fields, field)
end

local guide = Instance.new("Frame")
guide.Name = "Guide"
guide.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
guide.Size = UDim2.new(0, 550, 0, 220)
guide.Position = UDim2.new(0, 25, 0, 160)
guide.BackgroundTransparency = 1
guide.Parent = ball

local guidecorner = Instance.new("UICorner")
guidecorner.CornerRadius = UDim.new(0, 15)
guidecorner.Parent = guide

local htitle = Instance.new("TextLabel")
htitle.Name = "Htitle"
htitle.BackgroundTransparency = 1
htitle.Size = UDim2.new(1, -20, 0, 25)
htitle.Position = UDim2.new(0, 15, 0, 15)
htitle.Text = "How to verify"
htitle.TextColor3 = Color3.fromRGB(255, 255, 255)
htitle.TextSize = 19
htitle.Font = Enum.Font.GothamBold
htitle.TextXAlignment = Enum.TextXAlignment.Left
htitle.TextTransparency = 1
htitle.Parent = guide

local steps = Instance.new("TextLabel")
steps.Name = "Steps"
steps.BackgroundTransparency = 1
steps.Size = UDim2.new(1, -30, 0, 120)
steps.Position = UDim2.new(0, 15, 0, 45)
steps.TextColor3 = Color3.fromRGB(200, 200, 200)
steps.TextSize = 14
steps.Font = Enum.Font.Gotham
steps.TextXAlignment = Enum.TextXAlignment.Left
steps.TextYAlignment = Enum.TextYAlignment.Top
steps.TextWrapped = true
steps.RichText = true
steps.TextTransparency = 1
steps.Parent = guide

local btntext = Instance.new("TextLabel")
btntext.Name = "Btntext"
btntext.BackgroundTransparency = 1
btntext.Size = UDim2.new(0, 1000, 0, 50)
btntext.Text = "Copied to clipboard"
btntext.TextColor3 = Color3.fromRGB(255, 255, 255)
btntext.TextSize = 14
btntext.Font = Enum.Font.GothamBold
btntext.Visible = false
btntext.Parent = screen

local btntxtwidth = btntext.TextBounds.X + 40
btntext:Destroy()

local btn = Instance.new("TextButton")
btn.Name = "Btn"
btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
btn.Size = UDim2.new(0, btntxtwidth, 0, 40)
btn.Position = UDim2.new(0.5, -btntxtwidth / 2, 1, -55)
btn.Text = ""
btn.AutoButtonColor = false
btn.BackgroundTransparency = 1
btn.Parent = guide

local btncorner = Instance.new("UICorner")
btncorner.CornerRadius = UDim.new(1, 0)
btncorner.Parent = btn

local btnclip = Instance.new("Frame")
btnclip.Name = "Clip"
btnclip.BackgroundTransparency = 1
btnclip.Size = UDim2.new(1, 0, 1, 0)
btnclip.ClipsDescendants = true
btnclip.Parent = btn

local btnclipcorner = Instance.new("UICorner")
btnclipcorner.CornerRadius = UDim.new(1, 0)
btnclipcorner.Parent = btnclip

local btnfill = Instance.new("Frame")
btnfill.Name = "Fill"
btnfill.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
btnfill.Size = UDim2.new(1, 0, 1, 0)
btnfill.Position = UDim2.new(-1, 0, 0, 0)
btnfill.BorderSizePixel = 0
btnfill.Parent = btnclip

local btnfillcorner = Instance.new("UICorner")
btnfillcorner.CornerRadius = UDim.new(1, 0)
btnfillcorner.Parent = btnfill

local btnlabel = Instance.new("TextLabel")
btnlabel.Name = "Label"
btnlabel.BackgroundTransparency = 1
btnlabel.Size = UDim2.new(1, 0, 1, 0)
btnlabel.Text = "Join discord"
btnlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
btnlabel.TextSize = 14
btnlabel.Font = Enum.Font.GothamBold
btnlabel.TextTransparency = 1
btnlabel.Parent = btn

local clicking = false

btn.MouseButton1Click:Connect(function()
	if clicking then
		return
	end
	clicking = true

	setclipboard("discord.gg/yourlink")

	local origtext = btnlabel.Text
	btnlabel.Text = "Copied to clipboard"

	anim(btnfill, 0.6, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Exponential):Play()

	task.wait(2)

	btnlabel.Text = origtext
	anim(btnfill, 0.6, { Position = UDim2.new(-1, 0, 0, 0) }, Enum.EasingStyle.Exponential):Play()

	task.wait(0.6)
	clicking = false
end)

local function updateinstructions(code)
	local codetext = code and code ~= "" and code or ""
	local instruction = '<font color="rgb(200,200,200)">Join our Discord server and navigate to the </font><font color="rgb(88,101,242)" face="GothamMedium">#verify</font><font color="rgb(200,200,200)"> channel.\n\nType </font><font face="RobotoMono" color="rgb(180,180,180)">.link '
		.. codetext
		.. '</font><font color="rgb(200,200,200)"> in the channel.\n\nOur bot will DM you. Press confirm to verify your account.\n\nThat\'s it. Enjoy!</font>'
	steps.Text = instruction
end

local function animcode(code)
	currentcode = code
	updateinstructions(code)

	for i, field in ipairs(fields) do
		task.wait(0.05)
		local char = code:sub(i, i) or ""
		field.Text = char

		local origsize = field.Size
		field.Size = UDim2.new(0, 0, 0, 0)

		anim(field, 0.4, { Size = origsize }, Enum.EasingStyle.Back):Play()

		local pulse = anim(field, 0.2, { BackgroundColor3 = Color3.fromRGB(150, 100, 255) })
		pulse:Play()
		pulse.Completed:Connect(function()
			anim(field, 0.3, { BackgroundColor3 = Color3.fromRGB(25, 25, 25) }):Play()
		end)
	end
end

local function fetchcode()
	local un = localplr.Name
	local s_hw, hw = pcall(function()
		return game:GetService("RbxAnalyticsService"):GetClientId()
	end)
	if not s_hw then
		hw = "unknown"
	end
	local ts = tostring(os.time())

	local pl = "register:" .. un .. "+" .. hw .. "+" .. ts

	local s1, en = pcall(function()
		return enc(pl)
	end)

	if not s1 then
		return nil
	end

	local url = serverurl .. "/api?d=" .. UrlEncode(en)

	local s2, res = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not s2 then
		return nil
	end

	local s3, data = pcall(function()
		return http:JSONDecode(res)
	end)

	if not s3 then
		return nil
	end

	if data.ok ~= true then
		return nil
	end

	if not data.e then
		return nil
	end

	local s4, code = pcall(function()
		return dec(data.e)
	end)

	if not s4 then
		return nil
	end

	return code
end

task.wait(0.2)
anim(title, 0.4, { TextTransparency = 0 }):Play()
task.wait(0.08)
anim(sep, 0.4, { BackgroundTransparency = 0 }):Play()
task.wait(0.08)
anim(msg, 0.4, { TextTransparency = 0 }):Play()
task.wait(0.08)
anim(codebox, 0.4, { BackgroundTransparency = 0 }):Play()
anim(codetitle, 0.4, { TextTransparency = 0 }):Play()
anim(codewarning, 0.4, { TextTransparency = 0 }):Play()
for _, field in ipairs(codefields:GetChildren()) do
	if field:IsA("TextLabel") then
		anim(field, 0.4, { BackgroundTransparency = 0, TextTransparency = 0 }):Play()
	end
end
task.wait(0.08)
anim(guide, 0.4, { BackgroundTransparency = 0 }):Play()
anim(htitle, 0.4, { TextTransparency = 0 }):Play()
updateinstructions()
anim(steps, 0.4, { TextTransparency = 0 }):Play()
anim(btn, 0.4, { BackgroundTransparency = 0 }):Play()
anim(btnlabel, 0.4, { TextTransparency = 0 }):Play()

spawn(function()
	task.wait(0.5)
	local success, code = pcall(fetchcode)
	if success and code then
		animcode(code)
	end
end)
