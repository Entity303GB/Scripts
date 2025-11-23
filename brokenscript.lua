if not game:IsLoaded() then
    game.Loaded:Wait()
end

--[[
Sync v2.7
]]

local Codeless = true -- Set to true to bypass key system
local KeyCode = "SYNC_DEV" -- The code to enter

if getgenv().SyncExecuted then
    local localplr = game.Players.LocalPlayer
    local gui = localplr:WaitForChild("PlayerGui")
    
    local notifscreen = gui:FindFirstChild("SyncNotifications")
    if not notifscreen then
        notifscreen = Instance.new("ScreenGui")
        notifscreen.Name = "SyncNotifications"
        notifscreen.ResetOnSpawn = false
        notifscreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        notifscreen.DisplayOrder = 2147483647
        notifscreen.Parent = gui
    end
    
    local container = Instance.new("Frame")
    container.Name = "Notification"
    container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    container.BorderSizePixel = 0
    container.Size = UDim2.new(0, 320, 0, 85)
    container.Position = UDim2.new(1, 340, 0, 10)
    container.Parent = notifscreen
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = container
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 35))
    }
    gradient.Rotation = 45
    gradient.Parent = container
    
    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -20, 0, 24)
    title.Position = UDim2.new(0, 15, 0, 12)
    title.Text = "Sync"
    title.TextColor3 = Color3.fromRGB(150, 120, 255)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = container
    
    local msglabel = Instance.new("TextLabel")
    msglabel.BackgroundTransparency = 1
    msglabel.Size = UDim2.new(1, -30, 0, 40)
    msglabel.Position = UDim2.new(0, 15, 0, 38)
    msglabel.Text = "Already executed!"
    msglabel.TextColor3 = Color3.fromRGB(220, 220, 230)
    msglabel.TextSize = 13
    msglabel.Font = Enum.Font.Gotham
    msglabel.TextXAlignment = Enum.TextXAlignment.Left
    msglabel.TextYAlignment = Enum.TextYAlignment.Top
    msglabel.TextWrapped = true
    msglabel.Parent = container
    
    game:GetService("TweenService"):Create(container, TweenInfo.new(0.6, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(1, -330, 0, 10)}):Play()
    
    task.wait(3)
    
    game:GetService("TweenService"):Create(container, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.new(1, 340, 0, 10)}):Play()
    task.wait(0.4)
    container:Destroy()
    
    return
end

getgenv().SyncExecuted = true

local DevMode = false
local ForcePCMode = false
local UserTier = "Free"

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local CoreGui = game:GetService("CoreGui")

local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and not ForcePCMode

local Config = {
    ServerURL = "https://baskets-comments-favorite-news.trycloudflare.com",
    CommandPrefix = ";",
    CommandBarKey = Enum.KeyCode.F6,
    MinimizeDelay = 30
}

local TierHierarchy = {
    Free = 1,
    Premium = 2,
    Ultimate = 3,
    Admin = 4
}

local TierColors = {
    Free = Color3.fromRGB(120, 120, 140),
    Premium = Color3.fromRGB(255, 215, 0),
    Ultimate = Color3.fromRGB(200, 100, 255),
    Admin = Color3.fromRGB(255, 70, 70)
}

local function CanUseTier(userTier, requiredTier)
    local userLevel = TierHierarchy[userTier] or 1
    local requiredLevel = TierHierarchy[requiredTier] or 1
    return userLevel >= requiredLevel
end

---------- DATA STORAGE ----------

local function SaveData(filename, data)
    pcall(function()
        writefile("Sync_" .. filename, HttpService:JSONEncode(data))
    end)
end

local function LoadData(filename, default)
    local success, result = pcall(function()
        if isfile("Sync_" .. filename) then
            return HttpService:JSONDecode(readfile("Sync_" .. filename))
        end
        return default or {}
    end)
    return success and result or (default or {})
end

local keybinds = LoadData("keybinds.json", {})
local favorites = LoadData("favorites.json", {})

---------- NOTIFICATION MODULE ----------

local notify = {}
notify.notifications = {}
notify.yoffset = 10

function notify.anim(obj, time, props, style)
    style = style or Enum.EasingStyle.Exponential
    return TweenService:Create(obj, TweenInfo.new(time, style, Enum.EasingDirection.Out), props)
end

function notify.new(message, duration, notifType)
    pcall(function()
        duration = duration or 3
        notifType = notifType or "info"
        
        local typeColors = {
            info = Color3.fromRGB(150, 120, 255),
            success = Color3.fromRGB(140, 100, 255),
            error = Color3.fromRGB(255, 100, 120),
            warning = Color3.fromRGB(255, 180, 80)
        }
        
        local screen = PlayerGui:FindFirstChild("SyncNotifications")
        if not screen then
            screen = Instance.new("ScreenGui")
            screen.Name = "SyncNotifications"
            screen.ResetOnSpawn = false
            screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screen.DisplayOrder = 2147483647
            screen.Parent = PlayerGui
        end
        
        local container = Instance.new("Frame")
        container.Name = "Notification"
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        container.BorderSizePixel = 0
        container.Size = UDim2.new(0, 340, 0, 70)
        container.Position = UDim2.new(1, 360, 0, notify.yoffset)
        container.Parent = screen
        
        local container = Instance.new("Frame")
        container.Name = "Notification"
        container.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
        container.BorderSizePixel = 0
        container.Size = UDim2.new(0, 340, 0, 70)
        container.Position = UDim2.new(1, 360, 0, notify.yoffset)
        container.Parent = screen
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 18)
        corner.Parent = container
        
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 50)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 35))
        }
        gradient.Rotation = 45
        gradient.Parent = container
        
        local glow = Instance.new("ImageLabel")
        glow.BackgroundTransparency = 1
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0, -10, 0, -10)
        glow.Image = "rbxassetid://5028857084"
        glow.ImageColor3 = typeColors[notifType]
        glow.ImageTransparency = 0.7
        glow.ZIndex = 0
        glow.Parent = container
        
        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -30, 0, 24)
        title.Position = UDim2.new(0, 15, 0, 10)
        title.Text = "Sync"
        title.TextColor3 = typeColors[notifType]
        title.TextSize = 16
        title.Font = Enum.Font.GothamBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = container
        
        local msglabel = Instance.new("TextLabel")
        msglabel.Name = "Message"
        msglabel.BackgroundTransparency = 1
        msglabel.Size = UDim2.new(1, -30, 0, 1000)
        msglabel.Position = UDim2.new(0, 15, 0, 36)
        msglabel.Text = message
        msglabel.TextColor3 = Color3.fromRGB(230, 230, 240)
        msglabel.TextSize = 13
        msglabel.Font = Enum.Font.Gotham
        msglabel.TextXAlignment = Enum.TextXAlignment.Left
        msglabel.TextYAlignment = Enum.TextYAlignment.Top
        msglabel.TextWrapped = true
        msglabel.Parent = container
        
        local textbounds = msglabel.TextBounds.Y
        local finalheight = math.max(75, 46 + textbounds)
        container.Size = UDim2.new(0, 340, 0, finalheight)
        
        table.insert(notify.notifications, {frame = container, height = finalheight})
        
        container.Size = UDim2.new(0, 0, 0, finalheight)
        container.Position = UDim2.new(1, 0, 0, notify.yoffset)
        
        notify.anim(container, 0.6, {
            Size = UDim2.new(0, 340, 0, finalheight),
            Position = UDim2.new(1, -350, 0, notify.yoffset)
        }):Play()
        
        notify.yoffset = notify.yoffset + finalheight + 10
        
        task.delay(duration, function()
            notify.anim(title, 0.3, {TextTransparency = 1}):Play()
            notify.anim(msglabel, 0.3, {TextTransparency = 1}):Play()
            
            task.wait(0.3)
            
            notify.anim(container, 0.5, {
                Size = UDim2.new(0, 0, 0, finalheight),
                Position = UDim2.new(1, 0, 0, container.Position.Y.Offset)
            }):Play()
            
            task.wait(0.5)
            
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
                notify.anim(notif.frame, 0.4, {Position = UDim2.new(1, -350, 0, targetypos)}):Play()
            end
            
            container:Destroy()
        end)
    end)
end

---------- SYNC CMD MODULE ----------

local synccmd = {}
synccmd.__index = synccmd

function synccmd.new(config)
    local self = setmetatable({}, synccmd)
    
    self.prefix = config.prefix or ";"
    self.commands = {}
    self.functions = {}
    
    return self
end

function synccmd:cmd(data)
    table.insert(self.commands, {
        name = data.name,
        desc = data.desc or "No description",
        aliases = data.aliases or {},
        minimumTier = data.minimumTier or "Free",
        func = data.func,
        args = data.args or 0,
        needsTarget = data.needsTarget or false,
        popup = data.popup or nil
    })
end

function synccmd:func(name, func)
    self.functions[name] = func
end

function synccmd:parse(msg)
    if not msg:sub(1, #self.prefix) == self.prefix then return nil end
    
    local args = {}
    for word in msg:sub(#self.prefix + 1):gmatch("%S+") do
        table.insert(args, word)
    end
    
    if #args == 0 then return nil end
    
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

function synccmd:exec(msg, providedargs, skipPopup)
    local success, result = pcall(function()
        local cmdname, args
        
        if providedargs then
            cmdname = msg
            args = providedargs
        else
            cmdname, args = self:parse(msg)
        end
        
        if not cmdname then return false end
        
        local cmd = self:findcmd(cmdname)
        
        if cmd then
            if not CanUseTier(UserTier, cmd.minimumTier) then
                notify.new("This command requires " .. cmd.minimumTier .. " tier or higher!", 3, "error")
                return false
            end
            
            if not skipPopup and (cmd.args > 0 or cmd.needsTarget) and (#args == 0) then
                return cmd
            end
            
            local success, err = pcall(function()
                cmd.func(args, self)
            end)
            
            if not success then
                notify.new("Command error: " .. tostring(err), 3, "error")
            end
            
            return true
        end
        
        return false
    end)
    
    return success and result or false
end

local config = {
    prefix = ";"
}

local cmdcore = synccmd.new(config)

local currentSpeed = 16
local currentJumpPower = 50

cmdcore:cmd({
    name = "speed",
    desc = "Change walkspeed",
    aliases = {"ws", "walkspeed"},
    minimumTier = "Free",
    args = 1,
    func = function(args, core)
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local speed = tonumber(args[1]) or 16
            currentSpeed = speed
            hum.WalkSpeed = speed
            notify.new("WalkSpeed set to " .. speed, 3, "success")
        end
    end
})

cmdcore:cmd({
    name = "jumppower",
    desc = "Change jump power",
    aliases = {"jp", "jump"},
    minimumTier = "Free",
    args = 1,
    func = function(args, core)
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            local jp = tonumber(args[1]) or 50
            currentJumpPower = jp
            hum.JumpPower = jp
            notify.new("JumpPower set to " .. jp, 3, "success")
        end
    end
})

cmdcore:cmd({
    name = "goto",
    desc = "Teleport to player",
    aliases = {"tp", "teleport"},
    minimumTier = "Free",
    args = 1,
    needsTarget = true,
    func = function(args, core)
        if #args > 0 then
            local targetName = args[1]:lower()
            for _, player in pairs(Players:GetPlayers()) do
                if player.Name:lower():find(targetName) or player.DisplayName:lower():find(targetName) then
                    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                        local char = Player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
                            notify.new("Teleported to " .. player.DisplayName, 3, "success")
                            return
                        end
                    end
                end
            end
            notify.new("Player not found", 3, "error")
        end
    end
})

local spectating = false
local currentSpectateTarget = nil

cmdcore:cmd({
    name = "spectate",
    desc = "Spectate a player",
    aliases = {"spec", "view"},
    minimumTier = "Free",
    args = 1,
    needsTarget = true,
    func = function(args, core)
        if #args > 0 then
            local targetName = args[1]:lower()
            for _, player in pairs(Players:GetPlayers()) do
                if player.Name:lower():find(targetName) or player.DisplayName:lower():find(targetName) then
                    if player.Character and player.Character:FindFirstChild("Humanoid") then
                        workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
                        spectating = true
                        currentSpectateTarget = player
                        notify.new("Now spectating " .. player.DisplayName, 3, "success")
                        return
                    end
                end
            end
            notify.new("Player not found", 3, "error")
        end
    end
})

cmdcore:cmd({
    name = "unspectate",
    desc = "Stop spectating",
    aliases = {"unspec"},
    minimumTier = "Free",
    args = 0,
    func = function(args, core)
        if spectating then
            local char = Player.Character
            if char and char:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = char.Humanoid
                spectating = false
                currentSpectateTarget = nil
                notify.new("Stopped spectating", 3, "success")
            end
        end
    end
})

cmdcore:cmd({
    name = "noclip",
    desc = "Toggle noclip through walls",
    aliases = {"nc"},
    minimumTier = "Premium",
    args = 0,
    func = function(args, core)
        notify.new("Noclip toggled", 3, "success")
    end
})

local function togglefavorite(cmdname)
    local found = false
    for i, name in ipairs(favorites) do
        if name == cmdname then
            table.remove(favorites, i)
            found = true
            break
        end
    end
    
    if not found then
        table.insert(favorites, cmdname)
    end
    
    SaveData("favorites.json", favorites)
end

local function isfavorite(cmdname)
    for _, name in ipairs(favorites) do
        if name == cmdname then return true end
    end
    return false
end

---------- ENCRYPTION/DECRYPTION ----------

local function b64e(d)
    local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    return ((d:gsub('.', function(x)
        local r, b = '', x:byte()
        for i = 8, 1, -1 do
            r = r .. (b % 2^i - b % 2^(i-1) > 0 and '1' or '0')
        end
        return r
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do
            c = c + (x:sub(i,i) == '1' and 2^(6-i) or 0)
        end
        return b64c:sub(c+1,c+1)
    end) .. ({ '', '==', '=' })[#d % 3 + 1])
end

local function b64d(d)
    local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    d = string.gsub(d, '[^'..b64c..'=]', '')
    return (d:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (b64c:find(x)-1)
        for i = 5, 0, -1 do
            r = r .. (f % 2^(i+1) >= 2^i and '1' or '0')
        end
        return r
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i,i) == '1' and 2^(8-i) or 0)
        end
        return string.char(c)
    end))
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
    local success, result = pcall(function()
        local url = Config.ServerURL .. "/check/" .. HttpService:UrlEncode(Player.Name)
        
        local res = game:HttpGet(url, true)
        local data = HttpService:JSONDecode(res)
        
        if not data.d then return nil end
        
        local decrypted = dec(data.d)
        local status = HttpService:JSONDecode(decrypted)
        
        return status
    end)
    
    return success and result or nil
end

local function anim(obj, time, props, style)
    style = style or Enum.EasingStyle.Exponential
    return TweenService:Create(obj, TweenInfo.new(time, style, Enum.EasingDirection.Out), props)
end

local status = nil
if not Codeless then
    status = checkstatus()
end

if DevMode or Codeless then
    UserTier = "Premium"
elseif status then
    if status.t == 1 or status.s ~= 1 then
        UserTier = "Free"
    elseif status.t == 2 or status.t == 4 then
        UserTier = "Premium"
    elseif status.t == 3 then
        UserTier = "Ultimate"
    elseif status.t == 5 then
        UserTier = "Admin"
    else
        UserTier = "Free"
    end
else
    UserTier = "Free"
end

local Verified = false

if Codeless then
    Verified = true
else
    local keyscreen = Instance.new("ScreenGui")
    keyscreen.Name = "SyncKeySystem"
    keyscreen.ResetOnSpawn = false
    keyscreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyscreen.DisplayOrder = 2147483647
    keyscreen.Parent = PlayerGui
    
    local keycontainer = Instance.new("Frame")
    keycontainer.Name = "KeyContainer"
    keycontainer.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    keycontainer.BorderSizePixel = 0
    keycontainer.Size = UDim2.new(0, 320, 0, 180)
    keycontainer.Position = UDim2.new(0.5, -160, 0.5, -90)
    keycontainer.Parent = keyscreen
    
    local keycorner = Instance.new("UICorner")
    keycorner.CornerRadius = UDim.new(0, 16)
    keycorner.Parent = keycontainer
    
    local keygradient = Instance.new("UIGradient")
    keygradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 35))
    }
    keygradient.Rotation = 45
    keygradient.Parent = keycontainer
    
    local keytitle = Instance.new("TextLabel")
    keytitle.BackgroundTransparency = 1
    keytitle.Size = UDim2.new(1, 0, 0, 40)
    keytitle.Position = UDim2.new(0, 0, 0, 10)
    keytitle.Text = "Authentication"
    keytitle.TextColor3 = Color3.fromRGB(150, 120, 255)
    keytitle.TextSize = 20
    keytitle.Font = Enum.Font.GothamBold
    keytitle.Parent = keycontainer
    
    local keyinput = Instance.new("TextBox")
    keyinput.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
    keyinput.Size = UDim2.new(0, 260, 0, 45)
    keyinput.Position = UDim2.new(0.5, -130, 0, 60)
    keyinput.PlaceholderText = "Enter Key..."
    keyinput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    keyinput.Text = ""
    keyinput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyinput.TextSize = 15
    keyinput.Font = Enum.Font.Gotham
    keyinput.ClearTextOnFocus = false
    keyinput.Parent = keycontainer
    
    Instance.new("UICorner", keyinput).CornerRadius = UDim.new(0, 12)
    
    local submitbtn = Instance.new("TextButton")
    submitbtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    submitbtn.Size = UDim2.new(0, 260, 0, 40)
    submitbtn.Position = UDim2.new(0.5, -130, 0, 120)
    submitbtn.Text = "Submit"
    submitbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitbtn.TextSize = 15
    submitbtn.Font = Enum.Font.GothamBold
    submitbtn.AutoButtonColor = false
    submitbtn.Parent = keycontainer
    
    Instance.new("UICorner", submitbtn).CornerRadius = UDim.new(0, 12)
    
    local function checkKey()
        if keyinput.Text == KeyCode then
            notify.new("Key accepted!", 3, "success")
            anim(keycontainer, 0.5, {Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0.5, 0, 0.5, 0)}):Play()
            task.wait(0.5)
            keyscreen:Destroy()
            Verified = true
        else
            notify.new("Incorrect key!", 3, "error")
            anim(keyinput, 0.1, {BackgroundColor3 = Color3.fromRGB(255, 100, 120)}):Play()
            task.wait(0.1)
            anim(keyinput, 0.1, {BackgroundColor3 = Color3.fromRGB(40, 35, 50)}):Play()
        end
    end
    
    submitbtn.MouseButton1Click:Connect(checkKey)
    keyinput.FocusLost:Connect(function(enter)
        if enter then checkKey() end
    end)
    
    -- Mobile Support
    if IsMobile then
        keycontainer.Position = UDim2.new(0.5, -160, 0.3, 0) -- Move up for keyboard
    end
    
    repeat task.wait() until Verified
end

local screen = Instance.new("ScreenGui")
screen.Name = "SyncGui"
screen.ResetOnSpawn = false
screen.DisplayOrder = 2147483646
screen.IgnoreGuiInset = true
screen.Parent = CoreGui

local viewportsize = workspace.CurrentCamera.ViewportSize
local centerx = viewportsize.X / 2
local centery = viewportsize.Y / 2

local blur = Instance.new("BlurEffect")
blur.Size = 0
blur.Parent = game:GetService("Lighting")

local container = Instance.new("Frame")
container.Name = "Container"
container.BackgroundTransparency = 1
container.Size = UDim2.new(0, 280, 0, 55)
container.Parent = screen

local savedPos = LoadData("position.json", nil)
if savedPos and savedPos.x and savedPos.y then
    container.Position = UDim2.new(0, savedPos.x, 0, savedPos.y)
else
    container.Position = UDim2.new(0, centerx - 140, 0, -70)
end

local ball = Instance.new("Frame")
ball.Name = "Ball"
ball.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
ball.Size = UDim2.new(0, 55, 0, 55)
ball.Position = UDim2.new(0, 0, 0, 0)
ball.BackgroundTransparency = 1
ball.Parent = container

local ballcorner = Instance.new("UICorner")
ballcorner.CornerRadius = UDim.new(0, 18)
ballcorner.Parent = ball

local ballgradient = Instance.new("UIGradient")
ballgradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 25, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 30))
}
ballgradient.Rotation = 45
ballgradient.Parent = ball

local pfp = Instance.new("ImageLabel")
pfp.Name = "Pfp"
pfp.BackgroundTransparency = 1
pfp.Size = UDim2.new(0.75, 0, 0.75, 0)
pfp.Position = UDim2.new(0.125, 0, 0.125, 0)
pfp.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150"
pfp.ImageTransparency = 1
pfp.Parent = ball

local pfpcorner = Instance.new("UICorner")
pfpcorner.CornerRadius = UDim.new(0, 15)
pfpcorner.Parent = pfp

local island = Instance.new("Frame")
island.Name = "Island"
island.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
island.Size = UDim2.new(0, 220, 0, 55)
island.Position = UDim2.new(0, 65, 0, 0)
island.BackgroundTransparency = 1
island.Parent = container

local islandcorner = Instance.new("UICorner")
islandcorner.CornerRadius = UDim.new(0, 18)
islandcorner.Parent = island

local islandgradient = Instance.new("UIGradient")
islandgradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 25, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 30))
}
islandgradient.Rotation = 45
islandgradient.Parent = island

local welcome = Instance.new("TextLabel")
welcome.Name = "Welcome"
welcome.BackgroundTransparency = 1
welcome.Size = UDim2.new(1, -25, 1, 0)
welcome.Position = UDim2.new(0, 15, 0, 0)
welcome.Text = "Welcome, " .. Player.DisplayName .. " 👋"
welcome.TextColor3 = Color3.fromRGB(255, 255, 255)
welcome.TextSize = 16
welcome.Font = Enum.Font.GothamBold
welcome.TextXAlignment = Enum.TextXAlignment.Left
welcome.TextTransparency = 1
welcome.Parent = island

local txtwidth = welcome.TextBounds.X + 35
island.Size = UDim2.new(0, txtwidth, 0, 55)
container.Size = UDim2.new(0, txtwidth + 65, 0, 55)
container.Position = UDim2.new(0, centerx - (txtwidth + 65)/2, 0, -70)

Player.Chatted:Connect(function(msg)
    if msg:sub(1, #cmdcore.prefix) == cmdcore.prefix then
        cmdcore:exec(msg, nil, true)
    end
end)

---------- VERIFIED USER PATH ----------

if status and status.s == 1 then
    anim(container, 0.8, {Position = UDim2.new(0, centerx - (txtwidth + 65)/2, 0, 25)}):Play()
    task.wait(0.15)
    anim(ball, 0.4, {BackgroundTransparency = 0}):Play()
    anim(island, 0.4, {BackgroundTransparency = 0}):Play()
    anim(welcome, 0.4, {TextTransparency = 0}):Play()
    anim(pfp, 0.4, {ImageTransparency = 0}):Play()

    task.wait(2)

    anim(welcome, 0.3, {TextTransparency = 1}, Enum.EasingStyle.Sine):Play()
    anim(pfp, 0.3, {ImageTransparency = 1}, Enum.EasingStyle.Sine):Play()

    task.wait(0.3)

    local shrink = anim(island, 0.6, {Size = UDim2.new(0, 55, 0, 55), Position = UDim2.new(0, 0, 0, 0)})
    local fade = anim(island, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
    shrink:Play()
    task.wait(0.3)
    fade:Play()
    shrink.Completed:Wait()

    island:Destroy()
    welcome:Destroy()

    local move = anim(container, 0.7, {Position = UDim2.new(0, centerx - 27.5, 0, 25)})
    move:Play()
    move.Completed:Wait()

    pfp:Destroy()
    
    local navw = 280
    local navh = 55
    
    local expand = anim(ball, 0.9, {Size = UDim2.new(0, navw, 0, navh), Position = UDim2.new(0, -navw/2 + 27.5, 0, 0)})
    local roundcorner = anim(ballcorner, 0.9, {CornerRadius = UDim.new(0, 18)})
    expand:Play()
    roundcorner:Play()
    expand.Completed:Wait()
    
    container.Size = UDim2.new(0, navw, 0, navh)
    container.Position = UDim2.new(0, centerx - navw/2, 0, 25)
    ball.Size = UDim2.new(1, 0, 1, 0)
    ball.Position = UDim2.new(0, 0, 0, 0)
    
    local icondata = {
        {id = "77152639636456", name = "Home"},
        {id = "116802249038446", name = "User"},
        {id = "139500470994801", name = "Commands"},
        {id = "122415709139083", name = "Script Search"},
        {id = "86095856062452", name = "Settings"}
    }
    
    local iconsize = 35
    local iconspacing = 10
    local totalwidth = (#icondata * iconsize) + ((#icondata - 1) * iconspacing)
    local startx = (navw - totalwidth) / 2
    
    local lavalamp = Instance.new("Frame")
    lavalamp.Name = "Lavalamp"
    lavalamp.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    lavalamp.Size = UDim2.new(0, iconsize + 6, 0, iconsize + 6)
    lavalamp.Position = UDim2.new(0, startx - 3, 0, (navh - iconsize) / 2 - 3)
    lavalamp.BorderSizePixel = 0
    lavalamp.ZIndex = 1
    lavalamp.BackgroundTransparency = 1
    lavalamp.Parent = ball
    
    local lavalampcorner = Instance.new("UICorner")
    lavalampcorner.CornerRadius = UDim.new(0, 14)
    lavalampcorner.Parent = lavalamp
    
    local icons = {}
    local currenthover = nil
    local lastinteract = tick()
    local minimized = false
    local tabopen = false
    local currentOpenTab = nil
    local isDragging = false
    local dragStart = nil
    local dragStartPos = nil
    local hasDragged = false
    local isClicking = false
    local clickTime = 0
    
    local tabcontainer = Instance.new("Frame")
    tabcontainer.Name = "TabContainer"
    tabcontainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    tabcontainer.Size = UDim2.new(0, 720, 0, 470)
    tabcontainer.Position = UDim2.new(0, centerx - 360, 0, 90)
    tabcontainer.BorderSizePixel = 0
    tabcontainer.Visible = false
    tabcontainer.ZIndex = 10
    tabcontainer.Parent = screen
    
    local tabcorner = Instance.new("UICorner")
    tabcorner.CornerRadius = UDim.new(0, 20)
    tabcorner.Parent = tabcontainer
    
    local tabgradient = Instance.new("UIGradient")
    tabgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 20, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 15, 25))
    }
    tabgradient.Rotation = 45
    tabgradient.Parent = tabcontainer
    
    ---------- POPUP SYSTEM ----------
    
    local popupcontainer = Instance.new("Frame")
    popupcontainer.Name = "PopupContainer"
    popupcontainer.BackgroundColor3 = Color3.fromRGB(28, 23, 38)
    popupcontainer.Size = UDim2.new(0, 420, 0, 180)
    popupcontainer.Position = UDim2.new(0.5, -210, 0.5, -90)
    if IsMobile then
        popupcontainer.Position = UDim2.new(0.5, -210, 0.3, 0) -- Move up for keyboard on mobile
    end
    popupcontainer.BorderSizePixel = 0
    popupcontainer.Visible = false
    popupcontainer.ZIndex = 2147483640
    popupcontainer.Parent = screen
    
    Instance.new("UICorner", popupcontainer).CornerRadius = UDim.new(0, 22)
    
    local popupgradient = Instance.new("UIGradient")
    popupgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 30, 55)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 20, 35))
    }
    popupgradient.Rotation = 135
    popupgradient.Parent = popupcontainer
    
    local popuptitle = Instance.new("TextLabel")
    popuptitle.BackgroundTransparency = 1
    popuptitle.Size = UDim2.new(1, -40, 0, 30)
    popuptitle.Position = UDim2.new(0, 20, 0, 20)
    popuptitle.Text = "Enter Value"
    popuptitle.TextColor3 = Color3.fromRGB(200, 180, 255)
    popuptitle.TextSize = 18
    popuptitle.Font = Enum.Font.GothamBold
    popuptitle.TextXAlignment = Enum.TextXAlignment.Left
    popuptitle.ZIndex = 2147483641
    popuptitle.Parent = popupcontainer
    
    local popupinput = Instance.new("TextBox")
    popupinput.BackgroundColor3 = Color3.fromRGB(40, 35, 50)
    popupinput.Size = UDim2.new(1, -40, 0, 45)
    popupinput.Position = UDim2.new(0, 20, 0, 60)
    popupinput.PlaceholderText = "Enter value..."
    popupinput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    popupinput.Text = ""
    popupinput.TextColor3 = Color3.fromRGB(255, 255, 255)
    popupinput.TextSize = 15
    popupinput.Font = Enum.Font.Gotham
    popupinput.ClearTextOnFocus = false
    popupinput.ZIndex = 2147483641
    popupinput.Parent = popupcontainer
    
    Instance.new("UICorner", popupinput).CornerRadius = UDim.new(0, 12)
    
    local popupexec = Instance.new("TextButton")
    popupexec.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    popupexec.Size = UDim2.new(0, 180, 0, 42)
    popupexec.Position = UDim2.new(0, 20, 0, 118)
    popupexec.Text = "Execute"
    popupexec.TextColor3 = Color3.fromRGB(255, 255, 255)
    popupexec.TextSize = 15
    popupexec.Font = Enum.Font.GothamBold
    popupexec.AutoButtonColor = false
    popupexec.ZIndex = 2147483641
    popupexec.Parent = popupcontainer
    
    Instance.new("UICorner", popupexec).CornerRadius = UDim.new(0, 12)
    
    local popupcancel = Instance.new("TextButton")
    popupcancel.BackgroundColor3 = Color3.fromRGB(60, 50, 70)
    popupcancel.Size = UDim2.new(0, 180, 0, 42)
    popupcancel.Position = UDim2.new(1, -200, 0, 118)
    popupcancel.Text = "Cancel"
    popupcancel.TextColor3 = Color3.fromRGB(220, 220, 230)
    popupcancel.TextSize = 15
    popupcancel.Font = Enum.Font.GothamBold
    popupcancel.AutoButtonColor = false
    popupcancel.ZIndex = 2147483641
    popupcancel.Parent = popupcontainer
    
    Instance.new("UICorner", popupcancel).CornerRadius = UDim.new(0, 12)
    
    local currentPopupCmd = nil
    
    local function showPopup(cmd)
        currentPopupCmd = cmd
        popupinput.Text = ""
        popupcontainer.Visible = true
        popupcontainer.Size = UDim2.new(0, 0, 0, 0)
        popupcontainer.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        anim(blur, 0.4, {Size = 25}):Play()
        anim(popupcontainer, 0.5, {
            Size = UDim2.new(0, 420, 0, 180),
            Position = UDim2.new(0.5, -210, 0.5, -90)
        }):Play()
        
        task.wait(0.5)
        popupinput:CaptureFocus()
    end
    
    local function hidePopup()
        popupinput:ReleaseFocus()
        
        anim(popupcontainer, 0.4, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0)
        }):Play()
        
        if not tabopen then
            anim(blur, 0.4, {Size = 0}):Play()
        end
        
        task.wait(0.4)
        popupcontainer.Visible = false
        currentPopupCmd = nil
    end
    
    popupexec.MouseButton1Click:Connect(function()
        if currentPopupCmd and popupinput.Text ~= "" then
            local args = {}
            for word in popupinput.Text:gmatch("%S+") do
                table.insert(args, word)
            end
            currentPopupCmd.func(args, cmdcore)
            hidePopup()
        end
    end)
    
    popupexec.MouseEnter:Connect(function()
        anim(popupexec, 0.3, {BackgroundColor3 = Color3.fromRGB(170, 120, 255)}):Play()
    end)
    
    popupexec.MouseLeave:Connect(function()
        anim(popupexec, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
    end)
    
    popupcancel.MouseButton1Click:Connect(function()
        hidePopup()
    end)
    
    popupcancel.MouseEnter:Connect(function()
        anim(popupcancel, 0.3, {BackgroundColor3 = Color3.fromRGB(70, 60, 85)}):Play()
    end)
    
    popupcancel.MouseLeave:Connect(function()
        anim(popupcancel, 0.3, {BackgroundColor3 = Color3.fromRGB(60, 50, 70)}):Play()
    end)
    
    popupinput.FocusLost:Connect(function(enterPressed)
        if enterPressed and currentPopupCmd and popupinput.Text ~= "" then
            local args = {}
            for word in popupinput.Text:gmatch("%S+") do
                table.insert(args, word)
            end
            currentPopupCmd.func(args, cmdcore)
            hidePopup()
        end
    end)
    
    ---------- HOME TAB ----------
    
    local hometab = Instance.new("Frame")
    hometab.Name = "HomeTab"
    hometab.BackgroundTransparency = 1
    hometab.Size = UDim2.new(1, 0, 1, 0)
    hometab.BorderSizePixel = 0
    hometab.Visible = false
    hometab.ClipsDescendants = true
    hometab.ZIndex = 11
    hometab.Parent = tabcontainer
    
    local function createWidget(name, size, position, bgColor, gradientColors)
        local widget = Instance.new("Frame")
        widget.Name = name
        widget.BackgroundColor3 = bgColor or Color3.fromRGB(30, 30, 40)
        widget.Size = size
        widget.Position = position
        widget.BorderSizePixel = 0
        widget.BackgroundTransparency = 1
        widget.ZIndex = 12
        widget.Parent = hometab
        
        Instance.new("UICorner", widget).CornerRadius = UDim.new(0, 20)
        
        if gradientColors then
            local gradient = Instance.new("UIGradient")
            gradient.Color = gradientColors
            gradient.Rotation = 45
            gradient.Parent = widget
        end
        
        return widget
    end
    
    local userwidget = createWidget("UserWidget", UDim2.new(0, 440, 0, 110), UDim2.new(0, 20, 0, 20), Color3.fromRGB(30, 30, 40))
    
    local usergradient = Instance.new("UIGradient")
    usergradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 40, 75)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 25, 50))
    }
    usergradient.Rotation = 45
    usergradient.Parent = userwidget
    
    local useravatar = Instance.new("ImageLabel")
    useravatar.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
    useravatar.Size = UDim2.new(0, 75, 0, 75)
    useravatar.Position = UDim2.new(0, 18, 0, 18)
    useravatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. Player.UserId .. "&w=150&h=150"
    useravatar.BorderSizePixel = 0
    useravatar.BackgroundTransparency = 1
    useravatar.ZIndex = 13
    useravatar.Parent = userwidget
    
    Instance.new("UICorner", useravatar).CornerRadius = UDim.new(0, 16)
    
    local userinfo = Instance.new("Frame")
    userinfo.BackgroundTransparency = 1
    userinfo.Size = UDim2.new(0, 320, 0, 75)
    userinfo.Position = UDim2.new(0, 105, 0, 18)
    userinfo.ZIndex = 13
    userinfo.Parent = userwidget
    
    local userdisplay = Instance.new("TextLabel")
    userdisplay.BackgroundTransparency = 1
    userdisplay.Size = UDim2.new(1, 0, 0, 24)
    userdisplay.Position = UDim2.new(0, 0, 0, 0)
    userdisplay.Text = "Hello, " .. Player.DisplayName .. " 👋"
    userdisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
    userdisplay.TextSize = 17
    userdisplay.Font = Enum.Font.GothamBold
    userdisplay.TextXAlignment = Enum.TextXAlignment.Left
    userdisplay.TextTransparency = 1
    userdisplay.ZIndex = 13
    userdisplay.Parent = userinfo
    
    local usersep = Instance.new("Frame")
    usersep.BackgroundColor3 = Color3.fromRGB(180, 140, 255)
    usersep.Size = UDim2.new(0, 3, 0, 16)
    usersep.Position = UDim2.new(0, 0, 0, 28)
    usersep.BorderSizePixel = 0
    usersep.BackgroundTransparency = 1
    usersep.ZIndex = 13
    usersep.Parent = userinfo
    
    Instance.new("UICorner", usersep).CornerRadius = UDim.new(1, 0)
    
    local username = Instance.new("TextLabel")
    username.BackgroundTransparency = 1
    username.Size = UDim2.new(1, 0, 0, 17)
    username.Position = UDim2.new(0, 10, 0, 26)
    username.Text = "@" .. Player.Name
    username.TextColor3 = Color3.fromRGB(180, 180, 200)
    username.TextSize = 14
    username.Font = Enum.Font.Gotham
    username.TextXAlignment = Enum.TextXAlignment.Left
    username.TextTransparency = 1
    username.ZIndex = 13
    username.Parent = userinfo
    
    local typecontainer = Instance.new("Frame")
    typecontainer.BackgroundTransparency = 1
    typecontainer.Size = UDim2.new(1, 0, 0, 22)
    typecontainer.Position = UDim2.new(0, 0, 0, 48)
    typecontainer.ZIndex = 13
    typecontainer.Parent = userinfo
    
    local typelabel = Instance.new("TextLabel")
    typelabel.BackgroundTransparency = 1
    typelabel.Size = UDim2.new(0, 45, 0, 22)
    typelabel.Position = UDim2.new(0, 0, 0, 0)
    typelabel.Text = "Tier:"
    typelabel.TextColor3 = Color3.fromRGB(190, 190, 210)
    typelabel.TextSize = 13
    typelabel.Font = Enum.Font.Gotham
    typelabel.TextXAlignment = Enum.TextXAlignment.Left
    typelabel.TextTransparency = 1
    typelabel.ZIndex = 13
    typelabel.Parent = typecontainer
    
    local typebadge = Instance.new("Frame")
    typebadge.BackgroundColor3 = TierColors[UserTier]
    typebadge.Size = UDim2.new(0, 75, 0, 22)
    typebadge.Position = UDim2.new(0, 45, 0, 0)
    typebadge.BorderSizePixel = 0
    typebadge.BackgroundTransparency = 1
    typebadge.ZIndex = 13
    typebadge.Parent = typecontainer
    
    Instance.new("UICorner", typebadge).CornerRadius = UDim.new(1, 0)
    
    local typebadgetext = Instance.new("TextLabel")
    typebadgetext.BackgroundTransparency = 1
    typebadgetext.Size = UDim2.new(1, 0, 1, 0)
    typebadgetext.Text = UserTier
    typebadgetext.TextColor3 = Color3.fromRGB(255, 255, 255)
    typebadgetext.TextSize = 12
    typebadgetext.Font = Enum.Font.GothamBold
    typebadgetext.TextTransparency = 1
    typebadgetext.ZIndex = 13
    typebadgetext.Parent = typebadge
    
    local datewidget = createWidget("DateWidget", UDim2.new(0, 240, 0, 110), UDim2.new(0, 480, 0, 20))
    
    local dategradient = Instance.new("UIGradient")
    dategradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(65, 45, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 30, 60))
    }
    dategradient.Rotation = 135
    dategradient.Parent = datewidget
    
    local datelabel = Instance.new("TextLabel")
    datelabel.BackgroundTransparency = 1
    datelabel.Size = UDim2.new(1, -35, 0, 26)
    datelabel.Position = UDim2.new(0, 18, 0, 18)
    datelabel.Text = os.date("%A, %d. %b %Y")
    datelabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    datelabel.TextSize = 16
    datelabel.Font = Enum.Font.GothamBold
    datelabel.TextXAlignment = Enum.TextXAlignment.Left
    datelabel.TextTransparency = 1
    datelabel.ZIndex = 13
    datelabel.Parent = datewidget
    
    local timebox = Instance.new("Frame")
    timebox.BackgroundColor3 = Color3.fromRGB(50, 40, 70)
    timebox.Size = UDim2.new(0, 110, 0, 38)
    timebox.Position = UDim2.new(0, 18, 0, 56)
    timebox.BorderSizePixel = 0
    timebox.BackgroundTransparency = 1
    timebox.ZIndex = 13
    timebox.Parent = datewidget
    
    Instance.new("UICorner", timebox).CornerRadius = UDim.new(0, 14)
    
    local timelabel = Instance.new("TextLabel")
    timelabel.BackgroundTransparency = 1
    timelabel.Size = UDim2.new(1, 0, 1, 0)
    timelabel.Text = os.date("%I:%M %p")
    timelabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    timelabel.TextSize = 15
    timelabel.Font = Enum.Font.GothamBold
    timelabel.TextTransparency = 1
    timelabel.ZIndex = 13
    timelabel.Parent = timebox
    
    task.spawn(function()
        while true do
            timelabel.Text = os.date("%I:%M %p")
            task.wait(1)
        end
    end)
    
    local execwidget = createWidget("ExecWidget", UDim2.new(0, 220, 0, 100), UDim2.new(0, 20, 0, 150))
    
    local execgradient = Instance.new("UIGradient")
    execgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 50, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(240, 80, 80))
    }
    execgradient.Rotation = 45
    execgradient.Parent = execwidget
    
    local execlabel = Instance.new("TextLabel")
    execlabel.BackgroundTransparency = 1
    execlabel.Size = UDim2.new(1, -35, 0, 22)
    execlabel.Position = UDim2.new(0, 18, 0, 18)
    execlabel.Text = "Executor"
    execlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    execlabel.TextSize = 15
    execlabel.Font = Enum.Font.GothamBold
    execlabel.TextXAlignment = Enum.TextXAlignment.Left
    execlabel.TextTransparency = 1
    execlabel.ZIndex = 13
    execlabel.Parent = execwidget
    
    local execname = Instance.new("TextLabel")
    execname.BackgroundTransparency = 1
    execname.Size = UDim2.new(1, -35, 0, 45)
    execname.Position = UDim2.new(0, 18, 0, 45)
    execname.Text = identifyexecutor and identifyexecutor() or "Unknown"
    execname.TextColor3 = Color3.fromRGB(250, 250, 255)
    execname.TextSize = 18
    execname.Font = Enum.Font.GothamBold
    execname.TextXAlignment = Enum.TextXAlignment.Left
    execname.TextTransparency = 1
    execname.TextWrapped = true
    execname.ZIndex = 13
    execname.Parent = execwidget
    
    local fpswidget = createWidget("FPSWidget", UDim2.new(0, 220, 0, 100), UDim2.new(0, 260, 0, 150))
    
    local fpsgradient = Instance.new("UIGradient")
    fpsgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 90, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 240))
    }
    fpsgradient.Rotation = 45
    fpsgradient.Parent = fpswidget
    
    local fpslabel = Instance.new("TextLabel")
    fpslabel.BackgroundTransparency = 1
    fpslabel.Size = UDim2.new(1, -35, 0, 22)
    fpslabel.Position = UDim2.new(0, 18, 0, 18)
    fpslabel.Text = "Performance"
    fpslabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    fpslabel.TextSize = 15
    fpslabel.Font = Enum.Font.GothamBold
    fpslabel.TextXAlignment = Enum.TextXAlignment.Left
    fpslabel.TextTransparency = 1
    fpslabel.ZIndex = 13
    fpslabel.Parent = fpswidget
    
    local fpsvalue = Instance.new("TextLabel")
    fpsvalue.BackgroundTransparency = 1
    fpsvalue.Size = UDim2.new(1, -35, 0, 45)
    fpsvalue.Position = UDim2.new(0, 18, 0, 45)
    fpsvalue.Text = "60 FPS"
    fpsvalue.TextColor3 = Color3.fromRGB(250, 250, 255)
    fpsvalue.TextSize = 18
    fpsvalue.Font = Enum.Font.GothamBold
    fpsvalue.TextXAlignment = Enum.TextXAlignment.Left
    fpsvalue.TextTransparency = 1
    fpsvalue.ZIndex = 13
    fpsvalue.Parent = fpswidget
    
    task.spawn(function()
        local lastTime = tick()
        while true do
            local currentTime = tick()
            local fps = math.floor(1 / (currentTime - lastTime))
            fpsvalue.Text = fps .. " FPS"
            lastTime = currentTime
            RunService.RenderStepped:Wait()
        end
    end)
    
    local friendswidget = createWidget("FriendsWidget", UDim2.new(0, 220, 0, 100), UDim2.new(0, 500, 0, 150))
    
    local friendsgradient = Instance.new("UIGradient")
    friendsgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 100, 70)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 220, 130))
    }
    friendsgradient.Rotation = 45
    friendsgradient.Parent = friendswidget
    
    local friendslabel = Instance.new("TextLabel")
    friendslabel.BackgroundTransparency = 1
    friendslabel.Size = UDim2.new(1, -35, 0, 22)
    friendslabel.Position = UDim2.new(0, 18, 0, 18)
    friendslabel.Text = "Online Friends"
    friendslabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    friendslabel.TextSize = 15
    friendslabel.Font = Enum.Font.GothamBold
    friendslabel.TextXAlignment = Enum.TextXAlignment.Left
    friendslabel.TextTransparency = 1
    friendslabel.ZIndex = 13
    friendslabel.Parent = friendswidget
    
    local friendscount = Instance.new("TextLabel")
    friendscount.BackgroundTransparency = 1
    friendscount.Size = UDim2.new(1, -35, 0, 45)
    friendscount.Position = UDim2.new(0, 18, 0, 45)
    friendscount.Text = "0 Online"
    friendscount.TextColor3 = Color3.fromRGB(250, 250, 255)
    friendscount.TextSize = 18
    friendscount.Font = Enum.Font.GothamBold
    friendscount.TextXAlignment = Enum.TextXAlignment.Left
    friendscount.TextTransparency = 1
    friendscount.ZIndex = 13
    friendscount.Parent = friendswidget
    
    task.spawn(function()
        pcall(function()
            local count = 0
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Player and player:IsFriendsWith(Player.UserId) then
                    count = count + 1
                end
            end
            friendscount.Text = count .. " Online"
        end)
    end)
    
    local joinscriptwidget = createWidget("JoinScriptWidget", UDim2.new(0, 440, 0, 100), UDim2.new(0, 20, 0, 270))
    
    local joinscriptgradient = Instance.new("UIGradient")
    joinscriptgradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 50, 120)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 90, 220))
    }
    joinscriptgradient.Rotation = 45
    joinscriptgradient.Parent = joinscriptwidget
    
    local joinscriptlabel = Instance.new("TextLabel")
    joinscriptlabel.BackgroundTransparency = 1
    joinscriptlabel.Size = UDim2.new(1, -35, 0, 22)
    joinscriptlabel.Position = UDim2.new(0, 18, 0, 18)
    joinscriptlabel.Text = "Join Script"
    joinscriptlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    joinscriptlabel.TextSize = 15
    joinscriptlabel.Font = Enum.Font.GothamBold
    joinscriptlabel.TextXAlignment = Enum.TextXAlignment.Left
    joinscriptlabel.TextTransparency = 1
    joinscriptlabel.ZIndex = 13
    joinscriptlabel.Parent = joinscriptwidget
    
    local joinscriptdesc = Instance.new("TextLabel")
    joinscriptdesc.BackgroundTransparency = 1
    joinscriptdesc.Size = UDim2.new(1, -35, 0, 45)
    joinscriptdesc.Position = UDim2.new(0, 18, 0, 45)
    joinscriptdesc.Text = "Click to copy rejoin script"
    joinscriptdesc.TextColor3 = Color3.fromRGB(220, 220, 240)
    joinscriptdesc.TextSize = 14
    joinscriptdesc.Font = Enum.Font.Gotham
    joinscriptdesc.TextXAlignment = Enum.TextXAlignment.Left
    joinscriptdesc.TextYAlignment = Enum.TextYAlignment.Top
    joinscriptdesc.TextWrapped = true
    joinscriptdesc.TextTransparency = 1
    joinscriptdesc.ZIndex = 13
    joinscriptdesc.Parent = joinscriptwidget
    
    local joinscriptbtn = Instance.new("TextButton")
    joinscriptbtn.BackgroundTransparency = 1
    joinscriptbtn.Size = UDim2.new(1, 0, 1, 0)
    joinscriptbtn.Position = UDim2.new(0, 0, 0, 0)
    joinscriptbtn.Text = ""
    joinscriptbtn.ZIndex = 14
    joinscriptbtn.Parent = joinscriptwidget
    
    joinscriptbtn.MouseButton1Click:Connect(function()
        pcall(function()
            local joinScript = string.format('game:GetService("TeleportService"):TeleportToPlaceInstance(%d, "%s", game.Players.LocalPlayer)', game.PlaceId, game.JobId)
            setclipboard(joinScript)
            notify.new("Join script copied to clipboard!", 3, "success")
            
            anim(joinscriptwidget, 0.2, {BackgroundColor3 = Color3.fromRGB(180, 130, 255)}):Play()
            task.wait(0.15)
            anim(joinscriptwidget, 0.3, {BackgroundColor3 = Color3.fromRGB(90, 50, 120)}):Play()
        end)
    end)
    
    joinscriptbtn.MouseEnter:Connect(function()
        anim(joinscriptwidget, 0.3, {Size = UDim2.new(0, 450, 0, 105)}):Play()
    end)
    
    joinscriptbtn.MouseLeave:Connect(function()
        anim(joinscriptwidget, 0.3, {Size = UDim2.new(0, 440, 0, 100)}):Play()
    end)
    
    task.spawn(function()
        task.wait(0.5)
        anim(userwidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(useravatar, 0.7, {BackgroundTransparency = 0}):Play()
        anim(userdisplay, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(usersep, 0.6, {BackgroundTransparency = 0}):Play()
        anim(username, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(typelabel, 0.7, {TextTransparency = 0}):Play()
        anim(typebadge, 0.7, {BackgroundTransparency = 0}):Play()
        anim(typebadgetext, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(datewidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(datelabel, 0.7, {TextTransparency = 0}):Play()
        anim(timebox, 0.7, {BackgroundTransparency = 0}):Play()
        anim(timelabel, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(execwidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(execlabel, 0.7, {TextTransparency = 0}):Play()
        anim(execname, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(fpswidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(fpslabel, 0.7, {TextTransparency = 0}):Play()
        anim(fpsvalue, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(friendswidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(friendslabel, 0.7, {TextTransparency = 0}):Play()
        anim(friendscount, 0.7, {TextTransparency = 0}):Play()
        task.wait(0.12)
        anim(joinscriptwidget, 0.7, {BackgroundTransparency = 0}):Play()
        anim(joinscriptlabel, 0.7, {TextTransparency = 0}):Play()
        anim(joinscriptdesc, 0.7, {TextTransparency = 0}):Play()
    end)
    
    ---------- USER TAB ----------
    
    local usertab = Instance.new("Frame")
    usertab.Name = "UserTab"
    usertab.BackgroundTransparency = 1
    usertab.Size = UDim2.new(1, 0, 1, 0)
    usertab.BorderSizePixel = 0
    usertab.Visible = false
    usertab.ClipsDescendants = true
    usertab.ZIndex = 11
    usertab.Parent = tabcontainer
    
    local playerlistframe = Instance.new("Frame")
    playerlistframe.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    playerlistframe.Size = UDim2.new(0, 320, 0, 400)
    playerlistframe.Position = UDim2.new(0, 20, 0, 20)
    playerlistframe.BorderSizePixel = 0
    playerlistframe.ZIndex = 12
    playerlistframe.Parent = usertab
    
    Instance.new("UICorner", playerlistframe).CornerRadius = UDim.new(0, 20)
    
    local playerlistscroll = Instance.new("ScrollingFrame")
    playerlistscroll.BackgroundTransparency = 1
    playerlistscroll.Size = UDim2.new(1, -20, 1, -20)
    playerlistscroll.Position = UDim2.new(0, 10, 0, 10)
    playerlistscroll.ScrollBarThickness = 6
    playerlistscroll.ScrollBarImageColor3 = Color3.fromRGB(150, 120, 255)
    playerlistscroll.BorderSizePixel = 0
    playerlistscroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    playerlistscroll.ZIndex = 13
    playerlistscroll.Parent = playerlistframe
    
    local playerlistlayout = Instance.new("UIListLayout")
    playerlistlayout.Padding = UDim.new(0, 8)
    playerlistlayout.SortOrder = Enum.SortOrder.LayoutOrder
    playerlistlayout.Parent = playerlistscroll
    
    local selectedPlayer = nil
    local playerMenu = nil
    
    local function updatePlayerList()
        for _, child in pairs(playerlistscroll:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player then
                local playerentry = Instance.new("Frame")
                playerentry.BackgroundColor3 = Color3.fromRGB(45, 40, 60)
                playerentry.Size = UDim2.new(1, -10, 0, 50)
                playerentry.BorderSizePixel = 0
                playerentry.ZIndex = 14
                playerentry.Parent = playerlistscroll
                
                Instance.new("UICorner", playerentry).CornerRadius = UDim.new(0, 14)
                
                local playeravatar = Instance.new("ImageLabel")
                playeravatar.BackgroundColor3 = Color3.fromRGB(55, 50, 70)
                playeravatar.Size = UDim2.new(0, 38, 0, 38)
                playeravatar.Position = UDim2.new(0, 6, 0, 6)
                playeravatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
                playeravatar.BorderSizePixel = 0
                playeravatar.ZIndex = 15
                playeravatar.Parent = playerentry
                
                Instance.new("UICorner", playeravatar).CornerRadius = UDim.new(0, 12)
                
                local playername = Instance.new("TextLabel")
                playername.BackgroundTransparency = 1
                playername.Size = UDim2.new(1, -55, 1, 0)
                playername.Position = UDim2.new(0, 50, 0, 0)
                playername.Text = player.DisplayName
                playername.TextColor3 = Color3.fromRGB(255, 255, 255)
                playername.TextSize = 14
                playername.Font = Enum.Font.GothamBold
                playername.TextXAlignment = Enum.TextXAlignment.Left
                playername.TextScaled = false
                playername.ZIndex = 15
                playername.Parent = playerentry
                
                if playername.TextBounds.X > playername.AbsoluteSize.X then
                    playername.TextScaled = true
                end
                
                local playerbtn = Instance.new("TextButton")
                playerbtn.BackgroundTransparency = 1
                playerbtn.Size = UDim2.new(1, 0, 1, 0)
                playerbtn.Text = ""
                playerbtn.ZIndex = 16
                playerbtn.Parent = playerentry
                
                playerbtn.MouseEnter:Connect(function()
                    anim(playerentry, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
                end)
                
                playerbtn.MouseLeave:Connect(function()
                    anim(playerentry, 0.3, {BackgroundColor3 = Color3.fromRGB(45, 40, 60)}):Play()
                end)
                
                playerbtn.MouseButton1Click:Connect(function()
                    if selectedPlayer == player and playerMenu and playerMenu.Visible then
                        playerMenu.Visible = false
                        selectedPlayer = nil
                        return
                    end
                    
                    selectedPlayer = player
                    
                    if not playerMenu then
                        playerMenu = Instance.new("Frame")
                        playerMenu.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
                        playerMenu.Size = UDim2.new(0, 140, 0, 90)
                        playerMenu.Position = UDim2.new(0, 360, 0, 60)
                        playerMenu.BorderSizePixel = 0
                        playerMenu.ZIndex = 20
                        playerMenu.Parent = usertab
                        
                        Instance.new("UICorner", playerMenu).CornerRadius = UDim.new(0, 14)
                        
                        local menulayout = Instance.new("UIListLayout")
                        menulayout.Padding = UDim.new(0, 4)
                        menulayout.SortOrder = Enum.SortOrder.LayoutOrder
                        menulayout.Parent = playerMenu
                        
                        local menupadding = Instance.new("UIPadding")
                        menupadding.PaddingTop = UDim.new(0, 8)
                        menupadding.PaddingBottom = UDim.new(0, 8)
                        menupadding.PaddingLeft = UDim.new(0, 8)
                        menupadding.PaddingRight = UDim.new(0, 8)
                        menupadding.Parent = playerMenu
                        
                        local gotobtn = Instance.new("TextButton")
                        gotobtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
                        gotobtn.Size = UDim2.new(1, 0, 0, 32)
                        gotobtn.Text = "Goto"
                        gotobtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        gotobtn.TextSize = 13
                        gotobtn.Font = Enum.Font.GothamBold
                        gotobtn.AutoButtonColor = false
                        gotobtn.ZIndex = 21
                        gotobtn.Parent = playerMenu
                        
                        Instance.new("UICorner", gotobtn).CornerRadius = UDim.new(0, 10)
                        
                        local specbtn = Instance.new("TextButton")
                        specbtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
                        specbtn.Size = UDim2.new(1, 0, 0, 32)
                        specbtn.Text = "Spectate"
                        specbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        specbtn.TextSize = 13
                        specbtn.Font = Enum.Font.GothamBold
                        specbtn.AutoButtonColor = false
                        specbtn.ZIndex = 21
                        specbtn.Parent = playerMenu
                        
                        Instance.new("UICorner", specbtn).CornerRadius = UDim.new(0, 10)
                        
                        gotobtn.MouseEnter:Connect(function()
                            anim(gotobtn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
                        end)
                        
                        gotobtn.MouseLeave:Connect(function()
                            anim(gotobtn, 0.3, {BackgroundColor3 = Color3.fromRGB(50, 45, 65)}):Play()
                        end)
                        
                        specbtn.MouseEnter:Connect(function()
                            anim(specbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
                        end)
                        
                        specbtn.MouseLeave:Connect(function()
                            anim(specbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(50, 45, 65)}):Play()
                        end)
                        
                        gotobtn.MouseButton1Click:Connect(function()
                            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                                local char = Player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    char.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
                                    notify.new("Teleported to " .. selectedPlayer.DisplayName, 3, "success")
                                    playerMenu.Visible = false
                                end
                            end
                        end)
                        
                        specbtn.MouseButton1Click:Connect(function()
                            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Humanoid") then
                                local cam = workspace.CurrentCamera
                                local char = Player.Character
                                
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    local startPos = cam.CFrame.Position
                                    local skyPos = Vector3.new(startPos.X, startPos.Y + 500, startPos.Z)
                                    
                                    anim(cam, 1.5, {CFrame = CFrame.new(skyPos, startPos)}):Play()
                                    
                                    task.wait(1.5)
                                    
                                    if selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("Head") then
                                        local targetPos = selectedPlayer.Character.Head.Position + Vector3.new(0, 50, 0)
                                        anim(cam, 1.5, {CFrame = CFrame.new(targetPos, selectedPlayer.Character.Head.Position)}):Play()
                                        
                                        task.wait(1.5)
                                        
                                        cam.CameraSubject = selectedPlayer.Character.Humanoid
                                        spectating = true
                                        currentSpectateTarget = selectedPlayer
                                        notify.new("Now spectating " .. selectedPlayer.DisplayName, 3, "success")
                                    end
                                end
                                
                                playerMenu.Visible = false
                            end
                        end)
                    else
                        playerMenu.Visible = true
                    end
                end)
            end
        end
        
        playerlistscroll.CanvasSize = UDim2.new(0, 0, 0, playerlistlayout.AbsoluteContentSize.Y + 10)
    end
    
    Players.PlayerAdded:Connect(updatePlayerList)
    Players.PlayerRemoving:Connect(updatePlayerList)
    updatePlayerList()
    
    local controlsframe = Instance.new("Frame")
    controlsframe.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    controlsframe.Size = UDim2.new(0, 360, 0, 240)
    controlsframe.Position = UDim2.new(0, 360, 0, 20)
    controlsframe.BorderSizePixel = 0
    controlsframe.ZIndex = 12
    controlsframe.Parent = usertab
    
    Instance.new("UICorner", controlsframe).CornerRadius = UDim.new(0, 20)
    
    local controlstitle = Instance.new("TextLabel")
    controlstitle.BackgroundTransparency = 1
    controlstitle.Size = UDim2.new(1, -30, 0, 30)
    controlstitle.Position = UDim2.new(0, 15, 0, 15)
    controlstitle.Text = "Player Controls"
    controlstitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    controlstitle.TextSize = 18
    controlstitle.Font = Enum.Font.GothamBold
    controlstitle.TextXAlignment = Enum.TextXAlignment.Left
    controlstitle.ZIndex = 13
    controlstitle.Parent = controlsframe
    
    local speedlabel = Instance.new("TextLabel")
    speedlabel.BackgroundTransparency = 1
    speedlabel.Size = UDim2.new(1, -30, 0, 20)
    speedlabel.Position = UDim2.new(0, 15, 0, 55)
    speedlabel.Text = "WalkSpeed: " .. currentSpeed
    speedlabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    speedlabel.TextSize = 14
    speedlabel.Font = Enum.Font.Gotham
    speedlabel.TextXAlignment = Enum.TextXAlignment.Left
    speedlabel.ZIndex = 13
    speedlabel.Parent = controlsframe
    
    local speedslider = Instance.new("Frame")
    speedslider.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    speedslider.Size = UDim2.new(1, -30, 0, 8)
    speedslider.Position = UDim2.new(0, 15, 0, 80)
    speedslider.BorderSizePixel = 0
    speedslider.ZIndex = 13
    speedslider.Parent = controlsframe
    
    Instance.new("UICorner", speedslider).CornerRadius = UDim.new(1, 0)
    
    local speedfill = Instance.new("Frame")
    speedfill.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    speedfill.Size = UDim2.new((currentSpeed - 16) / 484, 0, 1, 0)
    speedfill.BorderSizePixel = 0
    speedfill.ZIndex = 14
    speedfill.Parent = speedslider
    
    Instance.new("UICorner", speedfill).CornerRadius = UDim.new(1, 0)
    
    local speedbtn = Instance.new("TextButton")
    speedbtn.BackgroundTransparency = 1
    speedbtn.Size = UDim2.new(1, 0, 1, 10)
    speedbtn.Position = UDim2.new(0, 0, 0, -5)
    speedbtn.Text = ""
    speedbtn.ZIndex = 15
    speedbtn.Parent = speedslider
    
    speedbtn.MouseButton1Down:Connect(function()
        local mouse = Player:GetMouse()
        local connection
        connection = mouse.Move:Connect(function()
            local relativeX = math.clamp(mouse.X - speedslider.AbsolutePosition.X, 0, speedslider.AbsoluteSize.X)
            local percentage = relativeX / speedslider.AbsoluteSize.X
            local newSpeed = math.floor(16 + (percentage * 484))
            currentSpeed = newSpeed
            speedlabel.Text = "WalkSpeed: " .. newSpeed
            anim(speedfill, 0.1, {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
            
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.WalkSpeed = newSpeed
            end
        end)
        
        local releaseConnection
        releaseConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
                releaseConnection:Disconnect()
            end
        end)
    end)
    
    local jplabel = Instance.new("TextLabel")
    jplabel.BackgroundTransparency = 1
    jplabel.Size = UDim2.new(1, -30, 0, 20)
    jplabel.Position = UDim2.new(0, 15, 0, 105)
    jplabel.Text = "JumpPower: " .. currentJumpPower
    jplabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    jplabel.TextSize = 14
    jplabel.Font = Enum.Font.Gotham
    jplabel.TextXAlignment = Enum.TextXAlignment.Left
    jplabel.ZIndex = 13
    jplabel.Parent = controlsframe
    
    local jpslider = Instance.new("Frame")
    jpslider.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    jpslider.Size = UDim2.new(1, -30, 0, 8)
    jpslider.Position = UDim2.new(0, 15, 0, 130)
    jpslider.BorderSizePixel = 0
    jpslider.ZIndex = 13
    jpslider.Parent = controlsframe
    
    Instance.new("UICorner", jpslider).CornerRadius = UDim.new(1, 0)
    
    local jpfill = Instance.new("Frame")
    jpfill.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    jpfill.Size = UDim2.new(currentJumpPower / 200, 0, 1, 0)
    jpfill.BorderSizePixel = 0
    jpfill.ZIndex = 14
    jpfill.Parent = jpslider
    
    Instance.new("UICorner", jpfill).CornerRadius = UDim.new(1, 0)
    
    local jpbtn = Instance.new("TextButton")
    jpbtn.BackgroundTransparency = 1
    jpbtn.Size = UDim2.new(1, 0, 1, 10)
    jpbtn.Position = UDim2.new(0, 0, 0, -5)
    jpbtn.Text = ""
    jpbtn.ZIndex = 15
    jpbtn.Parent = jpslider
    
    jpbtn.MouseButton1Down:Connect(function()
        local mouse = Player:GetMouse()
        local connection
        connection = mouse.Move:Connect(function()
            local relativeX = math.clamp(mouse.X - jpslider.AbsolutePosition.X, 0, jpslider.AbsoluteSize.X)
            local percentage = relativeX / jpslider.AbsoluteSize.X
            local newJP = math.floor(percentage * 200)
            currentJumpPower = newJP
            jplabel.Text = "JumpPower: " .. newJP
            anim(jpfill, 0.1, {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
            
            local char = Player.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.JumpPower = newJP
            end
        end)
        
        local releaseConnection
        releaseConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                connection:Disconnect()
                releaseConnection:Disconnect()
            end
        end)
    end)
    
    local resetbtn = Instance.new("TextButton")
    resetbtn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    resetbtn.Size = UDim2.new(1, -30, 0, 42)
    resetbtn.Position = UDim2.new(0, 15, 0, 160)
    resetbtn.Text = ""
    resetbtn.AutoButtonColor = false
    resetbtn.ZIndex = 13
    resetbtn.Parent = controlsframe
    
    Instance.new("UICorner", resetbtn).CornerRadius = UDim.new(0, 14)
    
    local reseticon = Instance.new("ImageLabel")
    reseticon.BackgroundTransparency = 1
    reseticon.Size = UDim2.new(0, 24, 0, 24)
    reseticon.Position = UDim2.new(0, 10, 0.5, -12)
    reseticon.Image = "rbxassetid://138754648998203"
    reseticon.ImageColor3 = Color3.fromRGB(255, 255, 255)
    reseticon.ZIndex = 14
    reseticon.Parent = resetbtn
    
    local resetlabel = Instance.new("TextLabel")
    resetlabel.BackgroundTransparency = 1
    resetlabel.Size = UDim2.new(1, -50, 1, 0)
    resetlabel.Position = UDim2.new(0, 40, 0, 0)
    resetlabel.Text = "Reset to Default"
    resetlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetlabel.TextSize = 15
    resetlabel.Font = Enum.Font.GothamBold
    resetlabel.TextXAlignment = Enum.TextXAlignment.Left
    resetlabel.ZIndex = 14
    resetlabel.Parent = resetbtn
    
    resetbtn.MouseEnter:Connect(function()
        anim(resetbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(170, 120, 255)}):Play()
    end)
    
    resetbtn.MouseLeave:Connect(function()
        anim(resetbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
    end)
    
    resetbtn.MouseButton1Click:Connect(function()
        currentSpeed = 16
        currentJumpPower = 50
        speedlabel.Text = "WalkSpeed: 16"
        jplabel.Text = "JumpPower: 50"
        anim(speedfill, 0.3, {Size = UDim2.new(0, 0, 1, 0)}):Play()
        anim(jpfill, 0.3, {Size = UDim2.new(0.25, 0, 1, 0)}):Play()
        
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
        
        notify.new("Player settings reset", 3, "success")
    end)
    
    local serverframe = Instance.new("Frame")
    serverframe.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    serverframe.Size = UDim2.new(0, 360, 0, 140)
    serverframe.Position = UDim2.new(0, 360, 0, 280)
    serverframe.BorderSizePixel = 0
    serverframe.ZIndex = 12
    serverframe.Parent = usertab
    
    Instance.new("UICorner", serverframe).CornerRadius = UDim.new(0, 20)
    
    local servertitle = Instance.new("TextLabel")
    servertitle.BackgroundTransparency = 1
    servertitle.Size = UDim2.new(1, -30, 0, 30)
    servertitle.Position = UDim2.new(0, 15, 0, 15)
    servertitle.Text = "Server"
    servertitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    servertitle.TextSize = 18
    servertitle.Font = Enum.Font.GothamBold
    servertitle.TextXAlignment = Enum.TextXAlignment.Left
    servertitle.ZIndex = 13
    servertitle.Parent = serverframe
    
    local serverhopbtn = Instance.new("TextButton")
    serverhopbtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    serverhopbtn.Size = UDim2.new(0, 160, 0, 42)
    serverhopbtn.Position = UDim2.new(0, 15, 0, 60)
    serverhopbtn.Text = "Server Hop"
    serverhopbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    serverhopbtn.TextSize = 15
    serverhopbtn.Font = Enum.Font.GothamBold
    serverhopbtn.AutoButtonColor = false
    serverhopbtn.ZIndex = 13
    serverhopbtn.Parent = serverframe
    
    Instance.new("UICorner", serverhopbtn).CornerRadius = UDim.new(0, 14)
    
    local rejoinbtn = Instance.new("TextButton")
    rejoinbtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
    rejoinbtn.Size = UDim2.new(0, 160, 0, 42)
    rejoinbtn.Position = UDim2.new(1, -175, 0, 60)
    rejoinbtn.Text = "Rejoin"
    rejoinbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rejoinbtn.TextSize = 15
    rejoinbtn.Font = Enum.Font.GothamBold
    rejoinbtn.AutoButtonColor = false
    rejoinbtn.ZIndex = 13
    rejoinbtn.Parent = serverframe
    
    Instance.new("UICorner", rejoinbtn).CornerRadius = UDim.new(0, 14)
    
    serverhopbtn.MouseEnter:Connect(function()
        anim(serverhopbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
    end)
    
    serverhopbtn.MouseLeave:Connect(function()
        anim(serverhopbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(50, 45, 65)}):Play()
    end)
    
    rejoinbtn.MouseEnter:Connect(function()
        anim(rejoinbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
    end)
    
    rejoinbtn.MouseLeave:Connect(function()
        anim(rejoinbtn, 0.3, {BackgroundColor3 = Color3.fromRGB(50, 45, 65)}):Play()
    end)
    
    serverhopbtn.MouseButton1Click:Connect(function()
        local TeleportService = game:GetService("TeleportService")
        local HttpService = game:GetService("HttpService")
        
        local cam = workspace.CurrentCamera
        local startCFrame = cam.CFrame
        
        local targetCFrame = CFrame.new(Vector3.new(0, 500, 0)) * CFrame.Angles(math.rad(-90), 0, 0)
        
        anim(cam, 2, {CFrame = targetCFrame}):Play()
        
        task.wait(2.5)
        
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
            
            for _, server in pairs(servers.data) do
                if server.playing < server.maxPlayers and server.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
                    return
                end
            end
            
            notify.new("No available servers found", 3, "error")
        end)
    end)
    
   rejoinbtn.MouseButton1Click:Connect(function()
    local TeleportService = game:GetService("TeleportService")
    
    pcall(function()
        local posData = {
            x = container.Position.X.Offset,
            y = container.Position.Y.Offset,
            minimized = minimized
        }
        SaveData("position.json", posData)
    end)
    
    notify.new("Rejoining server...", 2, "info")
    task.wait(1)
    
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
end)
    
    ---------- COMMANDS TAB ----------
    
    local commandstab = Instance.new("ScrollingFrame")
    commandstab.Name = "CommandsTab"
    commandstab.BackgroundTransparency = 1
    commandstab.Size = UDim2.new(1, 0, 1, 0)
    commandstab.ScrollBarThickness = 8
    commandstab.ScrollBarImageColor3 = Color3.fromRGB(150, 120, 255)
    commandstab.BorderSizePixel = 0
    commandstab.Visible = false
    commandstab.CanvasSize = UDim2.new(0, 0, 0, 0)
    commandstab.ZIndex = 11
    commandstab.Parent = tabcontainer
    
    local cmdtitle = Instance.new("TextLabel")
    cmdtitle.BackgroundTransparency = 1
    cmdtitle.Size = UDim2.new(1, -40, 0, 35)
    cmdtitle.Position = UDim2.new(0, 20, 0, 20)
    cmdtitle.Text = "Commands"
    cmdtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    cmdtitle.TextSize = 26
    cmdtitle.Font = Enum.Font.GothamBold
    cmdtitle.TextXAlignment = Enum.TextXAlignment.Left
    cmdtitle.ZIndex = 12
    cmdtitle.Parent = commandstab
    
    local cmdsearch = Instance.new("TextBox")
    cmdsearch.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
    cmdsearch.Size = UDim2.new(0, 210, 0, 36)
    cmdsearch.Position = UDim2.new(1, -230, 0, 20)
    cmdsearch.PlaceholderText = "Search..."
    cmdsearch.PlaceholderColor3 = Color3.fromRGB(130, 130, 150)
    cmdsearch.Text = ""
    cmdsearch.TextColor3 = Color3.fromRGB(255, 255, 255)
    cmdsearch.TextSize = 14
    cmdsearch.Font = Enum.Font.Gotham
    cmdsearch.ZIndex = 12
    cmdsearch.Parent = commandstab
    
    Instance.new("UICorner", cmdsearch).CornerRadius = UDim.new(0, 12)
    
    local cmdgrid = Instance.new("Frame")
    cmdgrid.BackgroundTransparency = 1
    cmdgrid.Size = UDim2.new(1, -40, 1, -85)
    cmdgrid.Position = UDim2.new(0, 20, 0, 65)
    cmdgrid.ZIndex = 12
    cmdgrid.Parent = commandstab
    
    local function refreshcmds(filter)
        pcall(function()
            for _, child in ipairs(cmdgrid:GetChildren()) do
                child:Destroy()
            end
            
            local ypos = 0
            local xpos = 0
            local count = 0
            
            local sortedCommands = {}
            for _, cmd in ipairs(cmdcore.commands) do
                table.insert(sortedCommands, cmd)
            end
            
            table.sort(sortedCommands, function(a, b)
                local aFav = isfavorite(a.name)
                local bFav = isfavorite(b.name)
                if aFav ~= bFav then
                    return aFav
                end
                return a.name < b.name
            end)
            
            for _, cmd in ipairs(sortedCommands) do
                if not filter or filter == "" or cmd.name:lower():find(filter:lower()) then
                    local cmdbox = Instance.new("TextButton")
                    cmdbox.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
                    cmdbox.Size = UDim2.new(0, 160, 0, 95)
                    cmdbox.Position = UDim2.new(0, xpos, 0, ypos)
                    cmdbox.Text = ""
                    cmdbox.AutoButtonColor = false
                    cmdbox.ZIndex = 13
                    cmdbox.Parent = cmdgrid
                    
                    Instance.new("UICorner", cmdbox).CornerRadius = UDim.new(0, 16)
                    
                    local cmdname = Instance.new("TextLabel")
                    cmdname.BackgroundTransparency = 1
                    cmdname.Size = UDim2.new(1, -55, 0, 20)
                    cmdname.Position = UDim2.new(0, 12, 0, 10)
                    cmdname.Text = cmd.name
                    cmdname.TextColor3 = Color3.fromRGB(255, 255, 255)
                    cmdname.TextSize = 15
                    cmdname.Font = Enum.Font.GothamBold
                    cmdname.TextXAlignment = Enum.TextXAlignment.Left
                    cmdname.ZIndex = 14
                    cmdname.Parent = cmdbox
                    
                    if cmd.minimumTier ~= "Free" then
                        local tierbadge = Instance.new("Frame")
                        tierbadge.BackgroundColor3 = TierColors[cmd.minimumTier]
                        tierbadge.Size = UDim2.new(0, 65, 0, 18)
                        tierbadge.Position = UDim2.new(0, 12, 1, -26)
                        tierbadge.BorderSizePixel = 0
                        tierbadge.ZIndex = 14
                        tierbadge.Parent = cmdbox
                        
                        Instance.new("UICorner", tierbadge).CornerRadius = UDim.new(0, 9)
                        
                        local tierbadgetext = Instance.new("TextLabel")
                        tierbadgetext.BackgroundTransparency = 1
                        tierbadgetext.Size = UDim2.new(1, 0, 1, 0)
                        tierbadgetext.Text = cmd.minimumTier:upper()
                        tierbadgetext.TextColor3 = Color3.fromRGB(255, 255, 255)
                        tierbadgetext.TextSize = 9
                        tierbadgetext.Font = Enum.Font.GothamBold
                        tierbadgetext.ZIndex = 14
                        tierbadgetext.Parent = tierbadge
                    end
                    
                    local cmddesc = Instance.new("TextLabel")
                    cmddesc.BackgroundTransparency = 1
                    cmddesc.Size = UDim2.new(1, -24, 0, 42)
                    cmddesc.Position = UDim2.new(0, 12, 0, 32)
                    cmddesc.Text = cmd.desc
                    cmddesc.TextColor3 = Color3.fromRGB(190, 190, 210)
                    cmddesc.TextSize = 12
                    cmddesc.Font = Enum.Font.Gotham
                    cmddesc.TextXAlignment = Enum.TextXAlignment.Left
                    cmddesc.TextYAlignment = Enum.TextYAlignment.Top
                    cmddesc.TextWrapped = true
                    cmddesc.ZIndex = 14
                    cmddesc.Parent = cmdbox
                    
                    local star = Instance.new("TextButton")
                    star.BackgroundTransparency = 1
                    star.Size = UDim2.new(0, 22, 0, 22)
                    star.Position = UDim2.new(1, -28, 0, 6)
                    star.Text = isfavorite(cmd.name) and "★" or "☆"
                    star.TextColor3 = isfavorite(cmd.name) and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(160, 160, 180)
                    star.TextSize = 19
                    star.Font = Enum.Font.Gotham
                    star.ZIndex = 15
                    star.Parent = cmdbox
                    
                    star.MouseButton1Click:Connect(function()
                        togglefavorite(cmd.name)
                        star.Text = isfavorite(cmd.name) and "★" or "☆"
                        star.TextColor3 = isfavorite(cmd.name) and Color3.fromRGB(255, 220, 0) or Color3.fromRGB(160, 160, 180)
                        refreshcmds(filter)
                    end)
                    
                    if cmd.args == 0 and not IsMobile then
                        local keybindbtn = Instance.new("TextButton")
                        keybindbtn.BackgroundColor3 = Color3.fromRGB(50, 45, 65)
                        keybindbtn.Size = UDim2.new(0, 55, 0, 22)
                        keybindbtn.Position = UDim2.new(1, -67, 1, -30)
                        keybindbtn.Text = keybinds[cmd.name] or "KEY"
                        keybindbtn.TextColor3 = Color3.fromRGB(210, 210, 230)
                        keybindbtn.TextSize = 10
                        keybindbtn.Font = Enum.Font.GothamBold
                        keybindbtn.AutoButtonColor = false
                        keybindbtn.ZIndex = 15
                        keybindbtn.Parent = cmdbox
                        
                        Instance.new("UICorner", keybindbtn).CornerRadius = UDim.new(0, 9)
                        
                        keybindbtn.MouseButton1Click:Connect(function()
                            notify.new("Press any key to bind to " .. cmd.name, 5, "info")
                            
                            local conn
                            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                                if gpe then return end
                                if input.UserInputType == Enum.UserInputType.Keyboard then
                                    keybinds[cmd.name] = input.KeyCode.Name
                                    SaveData("keybinds.json", keybinds)
                                    keybindbtn.Text = input.KeyCode.Name
                                    notify.new("Keybind set to " .. input.KeyCode.Name, 3, "success")
                                    conn:Disconnect()
                                end
                            end)
                        end)
                    end
                    
                    cmdbox.MouseEnter:Connect(function()
                        anim(cmdbox, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
                    end)
                    
                    cmdbox.MouseLeave:Connect(function()
                        anim(cmdbox, 0.3, {BackgroundColor3 = Color3.fromRGB(35, 30, 50)}):Play()
                    end)
                    
                    cmdbox.MouseButton1Click:Connect(function()
                        if not CanUseTier(UserTier, cmd.minimumTier) then
                            notify.new("This command requires " .. cmd.minimumTier .. " tier!", 3, "error")
                            return
                        end
                        
                        if cmd.args > 0 or cmd.needsTarget then
                            showPopup(cmd)
                        else
                            cmd.func({}, cmdcore)
                        end
                    end)
                    
                    count = count + 1
                    xpos = xpos + 170
                    if count % 4 == 0 then
                        xpos = 0
                        ypos = ypos + 105
                    end
                end
            end
            
            commandstab.CanvasSize = UDim2.new(0, 0, 0, ypos + 115)
        end)
    end
    
    cmdsearch:GetPropertyChangedSignal("Text"):Connect(function()
        refreshcmds(cmdsearch.Text)
    end)
    
    refreshcmds("")
    
    ---------- SCRIPT SEARCH TAB ----------
    
    local scriptstab = Instance.new("Frame")
    scriptstab.Name = "ScriptSearchTab"
    scriptstab.BackgroundTransparency = 1
    scriptstab.Size = UDim2.new(1, 0, 1, 0)
    scriptstab.Visible = false
    scriptstab.ZIndex = 11
    scriptstab.Parent = tabcontainer
    
    local scriptstitle = Instance.new("TextLabel")
    scriptstitle.BackgroundTransparency = 1
    scriptstitle.Size = UDim2.new(1, -40, 0, 35)
    scriptstitle.Position = UDim2.new(0, 20, 0, 20)
    scriptstitle.Text = "Script Search"
    scriptstitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    scriptstitle.TextSize = 26
    scriptstitle.Font = Enum.Font.GothamBold
    scriptstitle.TextXAlignment = Enum.TextXAlignment.Left
    scriptstitle.ZIndex = 12
    scriptstitle.Parent = scriptstab
    
    ---------- SETTINGS TAB ----------
    
    local settingstab = Instance.new("ScrollingFrame")
    settingstab.Name = "SettingsTab"
    settingstab.BackgroundTransparency = 1
    settingstab.Size = UDim2.new(1, 0, 1, 0)
    settingstab.ScrollBarThickness = 8
    settingstab.ScrollBarImageColor3 = Color3.fromRGB(150, 120, 255)
    settingstab.BorderSizePixel = 0
    settingstab.Visible = false
    settingstab.CanvasSize = UDim2.new(0, 0, 0, 450)
    settingstab.ZIndex = 11
    settingstab.Parent = tabcontainer
    
    local settingstitle = Instance.new("TextLabel")
    settingstitle.BackgroundTransparency = 1
    settingstitle.Size = UDim2.new(1, -40, 0, 35)
    settingstitle.Position = UDim2.new(0, 20, 0, 20)
    settingstitle.Text = "Settings"
    settingstitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    settingstitle.TextSize = 26
    settingstitle.Font = Enum.Font.GothamBold
    settingstitle.TextXAlignment = Enum.TextXAlignment.Left
    settingstitle.ZIndex = 12
    settingstitle.Parent = settingstab
    
    if not IsMobile then
        local settingbox = Instance.new("Frame")
        settingbox.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
        settingbox.Size = UDim2.new(1, -40, 0, 75)
        settingbox.Position = UDim2.new(0, 20, 0, 75)
        settingbox.ZIndex = 12
        settingbox.Parent = settingstab
        
        Instance.new("UICorner", settingbox).CornerRadius = UDim.new(0, 16)
        
        local settinglabel = Instance.new("TextLabel")
        settinglabel.BackgroundTransparency = 1
        settinglabel.Size = UDim2.new(1, -25, 0, 24)
        settinglabel.Position = UDim2.new(0, 12, 0, 12)
        settinglabel.Text = "Command Bar Toggle Key"
        settinglabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        settinglabel.TextSize = 16
        settinglabel.Font = Enum.Font.GothamBold
        settinglabel.TextXAlignment = Enum.TextXAlignment.Left
        settinglabel.ZIndex = 13
        settinglabel.Parent = settingbox
        
        local settingdesc = Instance.new("TextLabel")
        settingdesc.BackgroundTransparency = 1
        settingdesc.Size = UDim2.new(1, -25, 0, 17)
        settingdesc.Position = UDim2.new(0, 12, 0, 36)
        settingdesc.Text = "Press the button below and then any key"
        settingdesc.TextColor3 = Color3.fromRGB(170, 170, 190)
        settingdesc.TextSize = 13
        settingdesc.Font = Enum.Font.Gotham
        settingdesc.TextXAlignment = Enum.TextXAlignment.Left
        settingdesc.ZIndex = 13
        settingdesc.Parent = settingbox
        
        local keybindbutton = Instance.new("TextButton")
        keybindbutton.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
        keybindbutton.Size = UDim2.new(0, 110, 0, 35)
        keybindbutton.Position = UDim2.new(1, -122, 0, 28)
        keybindbutton.Text = Config.CommandBarKey.Name
        keybindbutton.TextColor3 = Color3.fromRGB(255, 255, 255)
        keybindbutton.TextSize = 14
        keybindbutton.Font = Enum.Font.GothamBold
        keybindbutton.AutoButtonColor = false
        keybindbutton.ZIndex = 13
        keybindbutton.Parent = settingbox
        
        Instance.new("UICorner", keybindbutton).CornerRadius = UDim.new(0, 12)
        
        keybindbutton.MouseButton1Click:Connect(function()
            keybindbutton.Text = "Press key..."
            
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, gpe)
                if gpe then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    Config.CommandBarKey = input.KeyCode
                    keybindbutton.Text = input.KeyCode.Name
                    notify.new("Command bar key set to " .. input.KeyCode.Name, 3, "success")
                    conn:Disconnect()
                end
            end)
        end)
    end
    
    local yposition = IsMobile and 75 or 170
    
    local clearfavbox = Instance.new("Frame")
    clearfavbox.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    clearfavbox.Size = UDim2.new(1, -40, 0, 75)
    clearfavbox.Position = UDim2.new(0, 20, 0, yposition)
    clearfavbox.ZIndex = 12
    clearfavbox.Parent = settingstab
    
    Instance.new("UICorner", clearfavbox).CornerRadius = UDim.new(0, 16)
    
    local clearfavlabel = Instance.new("TextLabel")
    clearfavlabel.BackgroundTransparency = 1
    clearfavlabel.Size = UDim2.new(1, -25, 0, 24)
    clearfavlabel.Position = UDim2.new(0, 12, 0, 12)
    clearfavlabel.Text = "Clear Favorites"
    clearfavlabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearfavlabel.TextSize = 16
    clearfavlabel.Font = Enum.Font.GothamBold
    clearfavlabel.TextXAlignment = Enum.TextXAlignment.Left
    clearfavlabel.ZIndex = 13
    clearfavlabel.Parent = clearfavbox
    
    local clearfavdesc = Instance.new("TextLabel")
    clearfavdesc.BackgroundTransparency = 1
    clearfavdesc.Size = UDim2.new(1, -25, 0, 17)
    clearfavdesc.Position = UDim2.new(0, 12, 0, 36)
    clearfavdesc.Text = "Remove all favorited commands"
    clearfavdesc.TextColor3 = Color3.fromRGB(170, 170, 190)
    clearfavdesc.TextSize = 13
    clearfavdesc.Font = Enum.Font.Gotham
    clearfavdesc.TextXAlignment = Enum.TextXAlignment.Left
    clearfavdesc.ZIndex = 13
    clearfavdesc.Parent = clearfavbox
    
    local clearfavbtn = Instance.new("TextButton")
    clearfavbtn.BackgroundColor3 = Color3.fromRGB(255, 100, 120)
    clearfavbtn.Size = UDim2.new(0, 110, 0, 35)
    clearfavbtn.Position = UDim2.new(1, -122, 0, 28)
    clearfavbtn.Text = "Clear"
    clearfavbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearfavbtn.TextSize = 14
    clearfavbtn.Font = Enum.Font.GothamBold
    clearfavbtn.AutoButtonColor = false
    clearfavbtn.ZIndex = 13
    clearfavbtn.Parent = clearfavbox
    
    Instance.new("UICorner", clearfavbtn).CornerRadius = UDim.new(0, 12)
    
    clearfavbtn.MouseButton1Click:Connect(function()
        favorites = {}
        SaveData("favorites.json", favorites)
        notify.new("All favorites cleared", 3, "success")
        refreshcmds("")
    end)
    
    local clearbindsbox = Instance.new("Frame")
    clearbindsbox.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
    clearbindsbox.Size = UDim2.new(1, -40, 0, 75)
    clearbindsbox.Position = UDim2.new(0, 20, 0, yposition + 95)
    clearbindsbox.ZIndex = 12
    clearbindsbox.Parent = settingstab
    
    Instance.new("UICorner", clearbindsbox).CornerRadius = UDim.new(0, 16)
    
    local clearbindslabel = Instance.new("TextLabel")
    clearbindslabel.BackgroundTransparency = 1
    clearbindslabel.Size = UDim2.new(1, -25, 0, 24)
    clearbindslabel.Position = UDim2.new(0, 12, 0, 12)
    clearbindslabel.Text = "Clear Keybinds"
    clearbindslabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearbindslabel.TextSize = 16
    clearbindslabel.Font = Enum.Font.GothamBold
    clearbindslabel.TextXAlignment = Enum.TextXAlignment.Left
    clearbindslabel.ZIndex = 13
    clearbindslabel.Parent = clearbindsbox
    
    local clearbindsdesc = Instance.new("TextLabel")
    clearbindsdesc.BackgroundTransparency = 1
    clearbindsdesc.Size = UDim2.new(1, -25, 0, 17)
    clearbindsdesc.Position = UDim2.new(0, 12, 0, 36)
    clearbindsdesc.Text = "Remove all command keybinds"
    clearbindsdesc.TextColor3 = Color3.fromRGB(170, 170, 190)
    clearbindsdesc.TextSize = 13
    clearbindsdesc.Font = Enum.Font.Gotham
    clearbindsdesc.TextXAlignment = Enum.TextXAlignment.Left
    clearbindsdesc.ZIndex = 13
    clearbindsdesc.Parent = clearbindsbox
    
    local clearbindsbtn = Instance.new("TextButton")
    clearbindsbtn.BackgroundColor3 = Color3.fromRGB(255, 100, 120)
    clearbindsbtn.Size = UDim2.new(0, 110, 0, 35)
    clearbindsbtn.Position = UDim2.new(1, -122, 0, 28)
    clearbindsbtn.Text = "Clear"
    clearbindsbtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearbindsbtn.TextSize = 14
    clearbindsbtn.Font = Enum.Font.GothamBold
    clearbindsbtn.AutoButtonColor = false
    clearbindsbtn.ZIndex = 13
    clearbindsbtn.Parent = clearbindsbox
    
    Instance.new("UICorner", clearbindsbtn).CornerRadius = UDim.new(0, 12)
    
    clearbindsbtn.MouseButton1Click:Connect(function()
        keybinds = {}
        SaveData("keybinds.json", keybinds)
        notify.new("All keybinds cleared", 3, "success")
        refreshcmds("")
    end)
    
    ---------- ICON SETUP ----------
    
    local dragHitbox = Instance.new("Frame")
    dragHitbox.BackgroundTransparency = 1
    dragHitbox.Size = UDim2.new(1, 30, 1, 30)
    dragHitbox.Position = UDim2.new(0, -15, 0, -15)
    dragHitbox.ZIndex = 5
    dragHitbox.Parent = ball
    
    for i, data in ipairs(icondata) do
        local xpos = startx + (i - 1) * (iconsize + iconspacing)
        
        local iconbtn = Instance.new("TextButton")
        iconbtn.BackgroundColor3 = Color3.fromRGB(35, 30, 50)
        iconbtn.Size = UDim2.new(0, iconsize, 0, iconsize)
        iconbtn.Position = UDim2.new(0, xpos, 0, (navh - iconsize) / 2)
        iconbtn.Text = ""
        iconbtn.AutoButtonColor = false
        iconbtn.BackgroundTransparency = 1
        iconbtn.ZIndex = 3
        iconbtn.Parent = ball
        
        Instance.new("UICorner", iconbtn).CornerRadius = UDim.new(0, 12)
        
        local iconimg = Instance.new("ImageLabel")
        iconimg.BackgroundTransparency = 1
        iconimg.Size = UDim2.new(0, 20, 0, 20)
        iconimg.Position = UDim2.new(0.5, -10, 0.5, -10)
        iconimg.Image = "rbxassetid://" .. data.id
        iconimg.ImageColor3 = Color3.fromRGB(255, 255, 255)
        iconimg.ImageTransparency = 1
        iconimg.ZIndex = 4
        iconimg.Parent = iconbtn
        
        local label = Instance.new("TextLabel")
        label.BackgroundColor3 = Color3.fromRGB(40, 35, 55)
        label.Size = UDim2.new(0, 0, 0, 26)
        label.Position = UDim2.new(0.5, 0, 1, 8)
        label.AnchorPoint = Vector2.new(0.5, 0)
        label.Text = data.name
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 12
        label.Font = Enum.Font.GothamMedium
        label.TextTransparency = 1
        label.BackgroundTransparency = 1
        label.ZIndex = 6
        label.Parent = iconbtn
        
        Instance.new("UICorner", label).CornerRadius = UDim.new(0, 8)
        
        iconbtn.MouseEnter:Connect(function()
    if minimized then return end
    
    lastinteract = tick()
    currenthover = i
    
    local currentPos = container.Position
    local screenWidth = viewportsize.X
    local isVertical = currentPos.X.Offset < screenWidth * 0.25 or currentPos.X.Offset > screenWidth * 0.75
    
    if isVertical then
        local targety = ((i - 1) * (iconsize + iconspacing)) + 2
        anim(lavalamp, 0.5, {
            Position = UDim2.new(0, 2, 0, targety),
            Size = UDim2.new(0, iconsize + 6, 0, iconsize + 6),
            BackgroundTransparency = 0
        }):Play()
    else
        local targetx = xpos - 3
        anim(lavalamp, 0.5, {
            Position = UDim2.new(0, targetx, 0, (navh - iconsize) / 2 - 3),
            Size = UDim2.new(0, iconsize + 6, 0, iconsize + 6),
            BackgroundTransparency = 0
        }):Play()
    end
    
    local txtbounds = label.TextBounds.X
    anim(label, 0.3, {
        Size = UDim2.new(0, txtbounds + 14, 0, 26),
        BackgroundTransparency = 0,
        TextTransparency = 0
    }):Play()
end)
        
        iconbtn.MouseLeave:Connect(function()
            if minimized then return end
            lastinteract = tick()
            currenthover = nil
            anim(lavalamp, 0.4, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine):Play()
            anim(label, 0.2, {
                Size = UDim2.new(0, 0, 0, 26),
                BackgroundTransparency = 1,
                TextTransparency = 1
            }):Play()
        end)
        
        iconbtn.MouseButton1Click:Connect(function()
    if minimized then
    if not hasDragged then
        minimized = false
        lastinteract = tick()
        
        local currentPos = container.Position
        local currentSize = container.AbsoluteSize
        local screenWidth = viewportsize.X
        local screenHeight = viewportsize.Y
        
        local isLeft = currentPos.X.Offset < screenWidth * 0.25
        local isRight = currentPos.X.Offset > screenWidth * 0.75
        local isTop = currentPos.Y.Offset < screenHeight * 0.25
        local isBottom = currentPos.Y.Offset > screenHeight * 0.75
        
        local newPosX, newPosY
        local expandVertical = isLeft or isRight
        
        if expandVertical then
            local verticalHeight = (#icondata * iconsize) + ((#icondata - 1) * iconspacing)
            newPosX = currentPos.X.Offset - (iconsize - currentSize.X)/2
            newPosY = currentPos.Y.Offset - (verticalHeight - currentSize.Y)/2
            
            anim(ball, 0.8, {Size = UDim2.new(1, 0, 1, 0)}):Play()
            anim(container, 0.8, {
                Size = UDim2.new(0, iconsize + 10, 0, verticalHeight + 10),
                Position = UDim2.new(currentPos.X.Scale, newPosX, currentPos.Y.Scale, newPosY)
            }):Play()
            
            task.wait(0.8)
            
            for j, ic in ipairs(icons) do
                local ypos = ((j - 1) * (iconsize + iconspacing)) + 5
                anim(ic.btn, 0.4, {
                    Position = UDim2.new(0, 5, 0, ypos),
                    BackgroundTransparency = 0
                }):Play()
                anim(ic.img, 0.4, {ImageTransparency = 0}):Play()
                task.wait(0.05)
            end
        else
            newPosX = currentPos.X.Offset - (navw - currentSize.X)/2
            newPosY = currentPos.Y.Offset - (navh - currentSize.Y)/2
            
            anim(ball, 0.8, {Size = UDim2.new(1, 0, 1, 0)}):Play()
            anim(container, 0.8, {
                Size = UDim2.new(0, navw, 0, navh),
                Position = UDim2.new(currentPos.X.Scale, newPosX, currentPos.Y.Scale, newPosY)
            }):Play()
            
            task.wait(0.8)
            
            for j, ic in ipairs(icons) do
                anim(ic.btn, 0.4, {
                    Position = UDim2.new(0, ic.xpos, 0, (navh - iconsize) / 2),
                    BackgroundTransparency = 0
                }):Play()
                anim(ic.img, 0.4, {ImageTransparency = 0}):Play()
                task.wait(0.05)
            end
        end
    end
    hasDragged = false
    return
end
    
    lastinteract = tick()
    local tabname = data.name:lower()
    if tabname == "script search" then
        tabname = "scriptsearch"
    end
    
    if tabopen and currentOpenTab == tabname then
        tabopen = false
        currentOpenTab = nil
        
        anim(blur, 0.4, {Size = 0}):Play()
        anim(tabcontainer, 0.6, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, centerx, 0, 90)
        }):Play()
        
        task.wait(0.6)
        
        tabcontainer.Visible = false
        hometab.Visible = false
        usertab.Visible = false
        commandstab.Visible = false
        scriptstab.Visible = false
        settingstab.Visible = false
        tabcontainer.BackgroundTransparency = 0
        return
    end
    
    if tabopen then
        hometab.Visible = false
        usertab.Visible = false
        commandstab.Visible = false
        scriptstab.Visible = false
        settingstab.Visible = false
    end
    
    hometab.Visible = (tabname == "home")
    usertab.Visible = (tabname == "user")
    commandstab.Visible = (tabname == "commands")
    scriptstab.Visible = (tabname == "scriptsearch")
    settingstab.Visible = (tabname == "settings")
    
    if tabname == "home" or tabname == "user" then
        tabcontainer.BackgroundTransparency = 1
    else
        tabcontainer.BackgroundTransparency = 0
    end
    
    if not tabopen then
        tabopen = true
        currentOpenTab = tabname
        tabcontainer.Visible = true
        tabcontainer.Size = UDim2.new(0, 0, 0, 0)
        tabcontainer.Position = UDim2.new(0, centerx, 0, 90)
        
        anim(blur, 0.5, {Size = 22}):Play()
        anim(tabcontainer, 0.7, {
            Size = UDim2.new(0, 730, 0, 480),
            Position = UDim2.new(0, centerx - 365, 0, 90)
        }):Play()
    else
        currentOpenTab = tabname
    end
end)
        
        table.insert(icons, {btn = iconbtn, img = iconimg, xpos = xpos, label = label})
    end
    
    task.wait(0.5)
    
    for i, icon in ipairs(icons) do
        anim(icon.btn, 0.4, {BackgroundTransparency = 0}):Play()
        anim(icon.img, 0.4, {ImageTransparency = 0}):Play()
        task.wait(0.05)
    end
    
    ---------- DRAGGING SYSTEM ----------
    
    dragHitbox.InputBegan:Connect(function(input)
        if minimized and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isClicking = true
            clickTime = tick()
            isDragging = false
            hasDragged = false
            dragStart = input.Position
            dragStartPos = container.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isClicking and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            
            if (math.abs(delta.X) > 5 or math.abs(delta.Y) > 5) and (tick() - clickTime) > 0.1 then
                isDragging = true
                hasDragged = true
            end
            
            if isDragging then
                local newPos = UDim2.new(
                    dragStartPos.X.Scale,
                    dragStartPos.X.Offset + delta.X,
                    dragStartPos.Y.Scale,
                    dragStartPos.Y.Offset + delta.Y
                )
                container.Position = newPos
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if isClicking and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            isClicking = false
            isDragging = false
        end
    end)
    
    ---------- AUTO MINIMIZE ----------
    
    task.spawn(function()
    while true do
        task.wait(1)
        if not minimized and (tick() - lastinteract) >= Config.MinimizeDelay and not tabopen then
            minimized = true
            
            local currentPos = container.Position
            
            anim(lavalamp, 0.4, {BackgroundTransparency = 1}):Play()
            
            for i = 2, #icons do
                anim(icons[i].btn, 0.5, {BackgroundTransparency = 1}):Play()
                anim(icons[i].img, 0.5, {ImageTransparency = 1}):Play()
                anim(icons[i].label, 0.3, {
                    Size = UDim2.new(0, 0, 0, 26),
                    BackgroundTransparency = 1,
                    TextTransparency = 1
                }):Play()
            end
            
            task.wait(0.5)
            
            local homeiconsize = 45
            anim(ball, 0.8, {Size = UDim2.new(0, homeiconsize, 0, homeiconsize)}):Play()
            anim(container, 0.8, {
                Size = UDim2.new(0, homeiconsize, 0, homeiconsize),
                Position = UDim2.new(currentPos.X.Scale, currentPos.X.Offset + (navw - homeiconsize)/2, currentPos.Y.Scale, currentPos.Y.Offset)
            }):Play()
            
            anim(icons[1].btn, 0.8, {
                Position = UDim2.new(0.5, -iconsize/2, 0.5, -iconsize/2)
            }):Play()
        end
    end
end)
    
    ---------- COMMAND BAR ----------
    
    if not IsMobile then
        local cmdbarcontainer = Instance.new("Frame")
        cmdbarcontainer.Name = "CmdBar"
        cmdbarcontainer.BackgroundColor3 = Color3.fromRGB(28, 23, 38)
        cmdbarcontainer.Size = UDim2.new(0, 40, 0, 40)
        cmdbarcontainer.Position = UDim2.new(0.5, -20, 0.5, -20)
        cmdbarcontainer.BorderSizePixel = 0
        cmdbarcontainer.BackgroundTransparency = 1
        cmdbarcontainer.ZIndex = 2147483630
        cmdbarcontainer.Parent = screen
        
        local cmdbarcorner = Instance.new("UICorner")
        cmdbarcorner.CornerRadius = UDim.new(1, 0)
        cmdbarcorner.Parent = cmdbarcontainer
        
        local cmdgradient = Instance.new("UIGradient")
        cmdgradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 90, 220)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 110, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 130, 255))
        }
        cmdgradient.Rotation = 45
        cmdgradient.Parent = cmdbarcontainer
        
        local cmdbarinput = Instance.new("TextBox")
        cmdbarinput.BackgroundTransparency = 1
        cmdbarinput.Size = UDim2.new(1, -45, 1, 0)
        cmdbarinput.Position = UDim2.new(0, 25, 0, 0)
        cmdbarinput.PlaceholderText = "Enter command..."
        cmdbarinput.PlaceholderColor3 = Color3.fromRGB(160, 160, 180)
        cmdbarinput.Text = ""
        cmdbarinput.TextColor3 = Color3.fromRGB(255, 255, 255)
        cmdbarinput.TextSize = 17
        cmdbarinput.Font = Enum.Font.GothamMedium
        cmdbarinput.TextXAlignment = Enum.TextXAlignment.Left
        cmdbarinput.ClearTextOnFocus = false
        cmdbarinput.TextTransparency = 1
        cmdbarinput.ZIndex = 2147483631
        cmdbarinput.Parent = cmdbarcontainer
        
        local suggestionlabel = Instance.new("TextLabel")
        suggestionlabel.BackgroundTransparency = 1
        suggestionlabel.Size = UDim2.new(1, -45, 1, 0)
        suggestionlabel.Position = UDim2.new(0, 25, 0, 0)
        suggestionlabel.Text = ""
        suggestionlabel.TextColor3 = Color3.fromRGB(130, 130, 150)
        suggestionlabel.TextSize = 17
        suggestionlabel.Font = Enum.Font.Gotham
        suggestionlabel.TextXAlignment = Enum.TextXAlignment.Left
        suggestionlabel.TextTransparency = 1
        suggestionlabel.ZIndex = 2147483630
        suggestionlabel.Parent = cmdbarcontainer
        
        local function updatesuggestion()
            pcall(function()
                local text = cmdbarinput.Text
                if text == "" then
                    suggestionlabel.Text = ""
                    anim(suggestionlabel, 0.2, {TextTransparency = 1}):Play()
                    return
                end
                
                local cmd = cmdcore:findcmd(text)
                if cmd and cmd.name:lower():sub(1, #text) == text:lower() then
                    suggestionlabel.Text = cmd.name
                    anim(suggestionlabel, 0.2, {TextTransparency = 0.6}):Play()
                else
                    suggestionlabel.Text = ""
                    anim(suggestionlabel, 0.2, {TextTransparency = 1}):Play()
                end
            end)
        end
        
        cmdbarinput:GetPropertyChangedSignal("Text"):Connect(updatesuggestion)
        
        UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            
            if input.KeyCode == Config.CommandBarKey then
                cmdbaropen = not cmdbaropen
                
                if cmdbaropen then
                    anim(cmdbarcontainer, 0.6, {
                        Size = UDim2.new(0, 680, 0, 70),
                        Position = UDim2.new(0.5, -340, 0.5, -35),
                        BackgroundTransparency = 0.05
                    }):Play()
                    
                    anim(cmdbarcorner, 0.6, {CornerRadius = UDim.new(0, 22)}):Play()
                    
                    task.wait(0.6)
                    anim(cmdbarinput, 0.3, {TextTransparency = 0}):Play()
                    cmdbarinput:CaptureFocus()
                else
                    cmdbarinput:ReleaseFocus()
                    anim(cmdbarinput, 0.2, {TextTransparency = 1}):Play()
                    anim(suggestionlabel, 0.2, {TextTransparency = 1}):Play()
                    
                    task.wait(0.2)
                    
                    anim(cmdbarcontainer, 0.6, {
                        Size = UDim2.new(0, 40, 0, 40),
                        Position = UDim2.new(0.5, -20, 0.5, -20),
                        BackgroundTransparency = 1
                    }):Play()
                    
                    anim(cmdbarcorner, 0.6, {CornerRadius = UDim.new(1, 0)}):Play()
                end
            elseif input.KeyCode == Enum.KeyCode.Tab and cmdbaropen and suggestionlabel.Text ~= "" then
                local suggestion = suggestionlabel.Text
                cmdbarinput.Text = suggestion
            end
        end)
        
        cmdbarinput.FocusLost:Connect(function(enter)
            if enter and cmdbarinput.Text ~= "" then
                local result = cmdcore:exec(cmdcore.prefix .. cmdbarinput.Text, nil, false)
                if type(result) == "table" then
                    showPopup(result)
                end
                cmdbarinput.Text = ""
            end
            
            task.wait(0.1)
            if cmdbaropen then
                cmdbaropen = false
                anim(cmdbarinput, 0.2, {TextTransparency = 1}):Play()
                anim(suggestionlabel, 0.2, {TextTransparency = 1}):Play()
                
                task.wait(0.2)
                
                anim(cmdbarcontainer, 0.6, {
                    Size = UDim2.new(0, 40, 0, 40),
                    Position = UDim2.new(0.5, -20, 0.5, -20),
                    BackgroundTransparency = 1
                }):Play()
                
                anim(cmdbarcorner, 0.6, {CornerRadius = UDim.new(1, 0)}):Play()
            end
        end)
    end
    
    ---------- KEYBIND LISTENER ----------
    
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        
        if input.UserInputType == Enum.UserInputType.Keyboard then
            local keyname = input.KeyCode.Name
            for cmdname, boundkey in pairs(keybinds) do
                if boundkey == keyname then
                    cmdcore:exec(cmdcore.prefix .. cmdname, nil, true)
                end
            end
        end
    end)
    
    ---------- HIDE OTHER GUIs ----------
    
    for _, gui in pairs(PlayerGui:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Name ~= "SyncGui" and gui.Name ~= "SyncNotifications" then
            gui.DisplayOrder = math.min(gui.DisplayOrder, 2147483645)
        end
    end
    
    notify.new("Welcome to Sync, " .. Player.DisplayName .. "!", 4, "success")
    
    return
end

---------- NEW USER PATH (VERIFICATION) ----------

if not Codeless then
    -- Only show verification if NOT codeless
    anim(container, 0.8, {Position = UDim2.new(0, centerx - (txtwidth + 65)/2, 0, 30)}):Play()
    task.wait(0.15)
    anim(ball, 0.4, {BackgroundTransparency = 0}):Play()
    anim(island, 0.4, {BackgroundTransparency = 0}):Play()
    anim(welcome, 0.4, {TextTransparency = 0}):Play()
    anim(pfp, 0.4, {ImageTransparency = 0}):Play()

    task.wait(2)

    anim(welcome, 0.3, {TextTransparency = 1}, Enum.EasingStyle.Sine):Play()
    anim(pfp, 0.3, {ImageTransparency = 1}, Enum.EasingStyle.Sine):Play()

    task.wait(0.3)

    local shrink = anim(island, 0.6, {Size = UDim2.new(0, 55, 0, 55), Position = UDim2.new(0, 0, 0, 0)})
    local fade = anim(island, 0.3, {BackgroundTransparency = 1}, Enum.EasingStyle.Sine)
    shrink:Play()
    task.wait(0.3)
    fade:Play()
    shrink.Completed:Wait()

    island:Destroy()
    welcome:Destroy()

    local move = anim(container, 0.7, {Position = UDim2.new(0, centerx - 27.5, 0, centery - 27.5)})
    move:Play()
    move.Completed:Wait()

    local mainw = 600
    local mainh = 400

    local expand = anim(ball, 0.9, {Size = UDim2.new(0, mainw, 0, mainh), Position = UDim2.new(0, -mainw/2 + 27.5, 0, -mainh/2 + 27.5)})
    local roundcorner = anim(ballcorner, 0.9, {CornerRadius = UDim.new(0, 22)})
    expand:Play()
    roundcorner:Play()
    expand.Completed:Wait()

    pfp:Destroy()
    container.Size = UDim2.new(0, mainw, 0, mainh)
    container.Position = UDim2.new(0, centerx - mainw/2, 0, centery - mainh/2)
    ball.Size = UDim2.new(1, 0, 1, 0)
    ball.Position = UDim2.new(0, 0, 0, 0)

    local title = Instance.new("TextLabel")
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
    sep.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    sep.BorderSizePixel = 0
    sep.Size = UDim2.new(0, 250, 0, 2)
    sep.Position = UDim2.new(0, 25, 0, 65)
    sep.BackgroundTransparency = 1
    sep.Parent = ball

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency = 1
    msg.Size = UDim2.new(0, 250, 0, 70)
    msg.Position = UDim2.new(0, 25, 0, 80)
    msg.Text = "Greetings " .. Player.DisplayName .. ", it seems like it's your first time using our script. Please read the instructions below."
    msg.TextColor3 = Color3.fromRGB(200, 200, 200)
    msg.TextSize = 14
    msg.Font = Enum.Font.Gotham
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.TextWrapped = true
    msg.TextTransparency = 1
    msg.Parent = ball

    local codebox = Instance.new("Frame")
    codebox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    codebox.Size = UDim2.new(0, 280, 0, 110)
    codebox.Position = UDim2.new(0, 295, 0, 25)
    codebox.BackgroundTransparency = 1
    codebox.Parent = ball

    Instance.new("UICorner", codebox).CornerRadius = UDim.new(0, 15)

    local codetitle = Instance.new("TextLabel")
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
        field.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        field.Size = UDim2.new(0, 42, 0, 50)
        field.Text = ""
        field.TextColor3 = Color3.fromRGB(150, 150, 150)
        field.TextSize = 20
        field.Font = Enum.Font.GothamBold
        field.BackgroundTransparency = 1
        field.TextTransparency = 1
        field.Parent = codefields
        
        Instance.new("UICorner", field).CornerRadius = UDim.new(0, 12)
        
        table.insert(fields, field)
    end

    local guide = Instance.new("Frame")
    guide.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    guide.Size = UDim2.new(0, 550, 0, 220)
    guide.Position = UDim2.new(0, 25, 0, 160)
    guide.BackgroundTransparency = 1
    guide.Parent = ball

    Instance.new("UICorner", guide).CornerRadius = UDim.new(0, 15)

    local htitle = Instance.new("TextLabel")
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

    local btn = Instance.new("TextButton")
    btn.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
    btn.Size = UDim2.new(0, 160, 0, 45)
    btn.Position = UDim2.new(0.5, -80, 1, -60)
    btn.Text = "Join Discord"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 15
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = false
    btn.BackgroundTransparency = 1
    btn.Parent = guide

    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 14)

    local clicking = false

    btn.MouseButton1Click:Connect(function()
        if clicking then return end
        clicking = true
        
        pcall(function()
            setclipboard("discord.gg/yourlink")
        end)
        
        btn.Text = "Copied!"
        anim(btn, 0.2, {BackgroundColor3 = Color3.fromRGB(140, 100, 255)}):Play()
        
        task.wait(2)
        
        btn.Text = "Join Discord"
        anim(btn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
        
        clicking = false
    end)

    btn.MouseEnter:Connect(function()
        anim(btn, 0.3, {BackgroundColor3 = Color3.fromRGB(170, 120, 255)}):Play()
    end)

    btn.MouseLeave:Connect(function()
        if not clicking then
            anim(btn, 0.3, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)}):Play()
        end
    end)

    local function updateinstructions(code)
        local codetext = code and code ~= "" and code or ""
        local instruction = '<font color="rgb(200,200,200)">Join our Discord server and navigate to the </font><font color="rgb(88,101,242)" face="GothamMedium">#verify</font><font color="rgb(200,200,200)"> channel.\n\nType </font><font face="RobotoMono" color="rgb(180,180,180)">.link ' .. codetext .. '</font><font color="rgb(200,200,200)"> in the channel.\n\nOur bot will DM you. Press confirm to verify your account.\n\nThat\'s it. Enjoy!</font>'
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
            
            anim(field, 0.4, {Size = origsize}, Enum.EasingStyle.Back):Play()
            
            local pulse = anim(field, 0.2, {BackgroundColor3 = Color3.fromRGB(150, 100, 255)})
            pulse:Play()
            pulse.Completed:Connect(function()
                anim(field, 0.3, {BackgroundColor3 = Color3.fromRGB(25, 25, 25)}):Play()
            end)
        end
    end

    local function fetchcode()
        local success, result = pcall(function()
            local un = Player.Name
            local hw = game:GetService("RbxAnalyticsService"):GetClientId()
            local ts = tostring(os.time())
            
            local pl = "register:" .. un .. "+" .. hw .. "+" .. ts
            local en = enc(pl)
            local url = Config.ServerURL .. "/api?d=" .. HttpService:UrlEncode(en)
            
            local res = game:HttpGet(url, true)
            local data = HttpService:JSONDecode(res)
            
            if data.ok and data.e then
                return dec(data.e)
            end
            return nil
        end)
        
        return success and result or nil
    end

    task.wait(0.2)
    anim(title, 0.5, {TextTransparency = 0}):Play()
    task.wait(0.1)
    anim(sep, 0.5, {BackgroundTransparency = 0}):Play()
    task.wait(0.1)
    anim(msg, 0.5, {TextTransparency = 0}):Play()
    task.wait(0.1)
    anim(codebox, 0.5, {BackgroundTransparency = 0}):Play()
    anim(codetitle, 0.5, {TextTransparency = 0}):Play()
    anim(codewarning, 0.5, {TextTransparency = 0}):Play()
    for _, field in ipairs(codefields:GetChildren()) do
        if field:IsA("TextLabel") then
            anim(field, 0.5, {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        end
    end
    task.wait(0.1)
    anim(guide, 0.5, {BackgroundTransparency = 0}):Play()
    anim(htitle, 0.5, {TextTransparency = 0}):Play()
    updateinstructions()
    anim(steps, 0.5, {TextTransparency = 0}):Play()
    anim(btn, 0.5, {BackgroundTransparency = 0}):Play()

    task.spawn(function()
        task.wait(0.5)
        local code = fetchcode()
        if code then
            animcode(code)
        end
    end)
end
