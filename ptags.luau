--- START OF MODIFIED FILE (NO JSON, DIRECT OWNER LIST) ---

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- 1. Prüfe welche Executor-Funktionen verfügbar sind
local crequest = syn and syn.request or request or fluxus and fluxus.request or http and http.request or http_request or sentinel and sentinel.request  or http_request or http.request or http and http.request or http_request or (crypt and crypt.request) or request or (SENTINEL_LOADED and request) or (syn and syn.request)  or (typeof(request) == "function" and request) or (typeof(http) == "table" and http.request)
local write_func = writefile or write_file or saveinstance
local read_func = readfile or read_file
local exists_func = isfile or does_file_exist or file_exists or is_file
local asset_func = getsynasset or getcustomasset or get_asset or getexecutorasset or syn_get_asset

-- #####################################################################
-- ## HIER DIE ROBLOX USERNAMEN DER OWNER EINTRAGEN ##
-- #####################################################################
local OWNER_USERNAMES = {
    "goetemp_3", -- Beispiel: Ersetze dies durch einen echten Usernamen
    "str4wberrymymommy",   -- Füge weitere Owner-Usernamen hier hinzu
    -- "NochEinOwner",
}
-- #####################################################################

local playerToTag = {}
-- Befülle playerToTag basierend auf der OWNER_USERNAMES Liste
for _, username in ipairs(OWNER_USERNAMES) do
    if type(username) == "string" then
        local userLower = username:lower()
        if not playerToTag[userLower] then -- Verhindert doppelte Einträge, falls ein Name mehrfach in der Liste ist
            playerToTag[userLower] = "SENTINEL OWNER"
            print("Konfiguriert: " .. username .. " als SENTINEL OWNER")
        end
    else
        warn("Ungültiger Username in OWNER_USERNAMES gefunden (kein String): ", username)
    end
end
if #OWNER_USERNAMES == 0 then
    print("Keine Owner in der OWNER_USERNAMES Liste konfiguriert.")
end

local function containsIgnoreCase(tbl, name)
    if not name then return false end
    name = name:lower()
    for _, v in ipairs(tbl) do
        if v:lower() == name then
            return true
        end
    end
    return false
end

local CONFIG = {
    TAG_SIZE = UDim2.new(0, 0, 0, 32),
    TAG_OFFSET = Vector3.new(0, 2.0, 0),
    MAX_DISTANCE = 200000,
    DISTANCE_THRESHOLD = 50,
    HYSTERESIS = 5,
    CORNER_RADIUS = UDim.new(0, 10),
    GLOW_INTENSITY = 0.3,
    TELEPORT_DISTANCE = 5,
    TELEPORT_HEIGHT = 0.5,
}

local RankData = {
    ["SENTINEL OWNER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseImage = true,
        accent = Color3.fromRGB(255, 215, 0),
        emoji = "👑",
        imageUrl = "https://raw.githubusercontent.com/Entity303GB/Scripts/3f2bd1cdeb67e1f6d9150c101d54c247afd022e1/owner.png",
        localFileName = "sentinel_owner_icon.png",
        localImageAssetId = ""
    },
    ["SENTINEL USER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseImage = true,
        accent = Color3.fromRGB(255, 215, 0),
        emoji = "👤",
        imageUrl = "https://raw.githubusercontent.com/Entity303GB/Scripts/3f2bd1cdeb67e1f6d9150c101d54c247afd022e1/user.png",
        localFileName = "sentinel_user_icon.png",
        localImageAssetId = ""
    }
}

local ChatWhitelist = {} -- Für "SENTINEL USER" über Chat-Nachricht

local function loadImageAsset(rankConfigEntry)
    if not rankConfigEntry.UseImage or not rankConfigEntry.imageUrl or not rankConfigEntry.localFileName then
        return false
    end

    if rankConfigEntry.localImageAssetId and rankConfigEntry.localImageAssetId ~= "" then
        return true
    end

    if not write_func or not exists_func or not asset_func or not crequest then
        warn("FEHLER: Executor-Funktionen zum Laden von Bildern nicht verfügbar. Deaktiviere Bild für: " .. (rankConfigEntry.rankName or "Unbekannter Rang"))
        rankConfigEntry.UseImage = false
        return false
    end

    local IMAGE_URL = rankConfigEntry.imageUrl
    local LOCAL_FILE_NAME = rankConfigEntry.localFileName

    if exists_func(LOCAL_FILE_NAME) then
        local success, assetId = pcall(asset_func, LOCAL_FILE_NAME)
        if success and assetId then
            rankConfigEntry.localImageAssetId = assetId
            print("Bild aus Workspace geladen: " .. LOCAL_FILE_NAME)
            return true
        else
            warn("Konnte existierendes Bild nicht aus Workspace laden: " .. LOCAL_FILE_NAME .. (assetId and (" - Error: " .. tostring(assetId)) or ""))
        end
    end

    local imageData
    local successOnRequest, response = pcall(crequest, { Url = IMAGE_URL, Method = "GET" })

    if successOnRequest and response and response.Body then
        imageData = response.Body
    else
        print("crequest fehlgeschlagen oder keine Body-Daten für " .. IMAGE_URL .. ", versuche HttpService...")
        local httpSuccess, httpResult = pcall(function()
            return HttpService:GetAsync(IMAGE_URL)
        end)
        if httpSuccess and httpResult then
            imageData = httpResult
            print("Bild erfolgreich mit HttpService heruntergeladen: " .. IMAGE_URL)
        else
            warn("FEHLER: Konnte Bild nicht herunterladen von: " .. IMAGE_URL .. (response and (" - crequest Status: " .. tostring(response.StatusMessage)) or (httpResult and (" - HttpService Error: " .. tostring(httpResult)) or "")))
            rankConfigEntry.UseImage = false
            return false
        end
    end

    if imageData then
        local writeSuccess, writeError = pcall(write_func, LOCAL_FILE_NAME, imageData)
        if writeSuccess then
            task.wait(0.1)
            local assetSuccess, assetId = pcall(asset_func, LOCAL_FILE_NAME)
            if assetSuccess and assetId then
                rankConfigEntry.localImageAssetId = assetId
                print("Bild heruntergeladen und geladen: " .. LOCAL_FILE_NAME)
                return true
            else
                warn("FEHLER: Konnte kein Asset aus heruntergeladenem Bild erstellen: " .. LOCAL_FILE_NAME .. (assetId and (" - Error: " .. tostring(assetId)) or ""))
                rankConfigEntry.UseImage = false
                return false
            end
        else
            warn("FEHLER: Konnte Bilddaten nicht speichern unter: " .. LOCAL_FILE_NAME .. " - Error: " .. tostring(writeError))
            rankConfigEntry.UseImage = false
            return false
        end
    end
    return false
end

local function preloadRankImages()
    if not asset_func then
         warn("Executor-Funktion 'asset_func' nicht gefunden. Bild-Tags werden nicht funktionieren. Fallback auf Emojis/Text.")
         for rankName, data in pairs(RankData) do
             data.UseImage = false
         end
         return
    end

    print("Beginne mit dem Vorabladen von Rangbildern...")
    for rankName, data in pairs(RankData) do
        if data.UseImage and data.imageUrl and data.localFileName then
            data.rankName = rankName
            task.spawn(function()
                local success = loadImageAsset(data)
                if success then
                    print("Bild für Rang '" .. rankName .. "' erfolgreich vorgeladen.")
                else
                    warn("Vorabladen des Bildes für Rang '" .. rankName .. "' fehlgeschlagen. Fallback auf Emoji/Text.")
                end
            end)
        end
    end
end

preloadRankImages()

local function modifyString(randomText)
    local modified = ""
    for char in randomText:gmatch(".") do
        if char ~= " " then
            modified = modified .. char
        end
    end
    return modified
end

local message = "im  using  -  SENTINEL ADMIN!  "
local modifiedMessage = modifyString(message)

spawn(function()
    while true do
        for i = 1, 5 do
            Players:Chat(modifiedMessage)
            wait(8)
        end
    end
end)

local function teleportToPlayer(targetPlayer)
    local localPlayer = Players.LocalPlayer
    local character = localPlayer.Character
    local targetCharacter = targetPlayer.Character
    if not (character and targetCharacter) then return end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    local targetHRP = targetCharacter:FindFirstChild("UpperTorso") or targetCharacter:FindFirstChild("HumanoidRootPart")
    if not (hrp and targetHRP) then return end

    local targetCFrame = targetHRP.CFrame
    local teleportPosition = targetCFrame.Position + (targetCFrame.LookVector * CONFIG.TELEPORT_DISTANCE)
    teleportPosition = teleportPosition + Vector3.new(0, CONFIG.TELEPORT_HEIGHT, 0)

    hrp.CFrame = CFrame.new(teleportPosition, targetHRP.Position)
end

local function getTextWidth(text, font, textSize)
    local size = TextService:GetTextSize(text, textSize, font, Vector2.new(2000, CONFIG.TAG_SIZE.Y.Offset))
    return math.ceil(size.X)
end

local function attachTagToHead(character, player, rankText)
    local head = character:FindFirstChild("Head")
    if not head then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end
    for _, child in ipairs(head:GetChildren()) do
        if child.Name == "RankTag" then
            child:Destroy()
        end
    end
    local rankData = RankData[rankText] or {
        primary = Color3.fromRGB(20, 20, 20),
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseImage = false,
        accent = Color3.fromRGB(255, 215, 0),
        emoji = "⭐",
        imageUrl = "", localFileName = "", localImageAssetId = ""
    }
    local tag = Instance.new("BillboardGui")
    tag.Name = "RankTag"
    tag.Adornee = head
    tag.Size = CONFIG.TAG_SIZE
    tag.StudsOffset = CONFIG.TAG_OFFSET
    tag.AlwaysOnTop = true
    tag.MaxDistance = CONFIG.MAX_DISTANCE
    tag.LightInfluence = 0
    tag.ResetOnSpawn = false
    tag.Active = true
    local container = Instance.new("Frame")
    container.Name = "TagContainer"
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundColor3 = rankData.primary
    container.BackgroundTransparency = 0.15
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Parent = tag
    local containerCorner = Instance.new("UICorner")
    containerCorner.CornerRadius = CONFIG.CORNER_RADIUS
    containerCorner.Parent = container
    local border = Instance.new("UIStroke")
    border.Color = rankData.accent
    border.Thickness = 2
    border.Transparency = 0.2
    border.Parent = container
    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 10
    clickButton.AutoButtonColor = false
    clickButton.Active = true
    clickButton.Parent = container
    if player ~= Players.LocalPlayer then
        clickButton.MouseButton1Click:Connect(function()
            teleportToPlayer(player)
        end)
        clickButton.MouseEnter:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0}):Play()
        end)
        clickButton.MouseLeave:Connect(function()
            TweenService:Create(container, TweenInfo.new(0.3), {BackgroundTransparency = 0.15}):Play()
        end)
    end
    local particlesContainer = Instance.new("Frame")
    particlesContainer.Name = "ParticlesContainer"
    particlesContainer.Size = UDim2.new(1, 0, 1, 0)
    particlesContainer.BackgroundTransparency = 1
    particlesContainer.ZIndex = 2
    particlesContainer.ClipsDescendants = true
    particlesContainer.Parent = container
    local pContainerCorner = Instance.new("UICorner")
    pContainerCorner.CornerRadius = UDim.new(1, 0)
    pContainerCorner.Parent = particlesContainer

    local iconDisplay
    if rankData.UseImage and rankData.localImageAssetId and rankData.localImageAssetId ~= "" then
        iconDisplay = Instance.new("ImageLabel")
        iconDisplay.Name = "RankIcon"
        iconDisplay.Image = rankData.localImageAssetId
        iconDisplay.ScaleType = Enum.ScaleType.Fit
    else
        iconDisplay = Instance.new("TextLabel")
        iconDisplay.Name = "RankIcon"
        iconDisplay.Text = rankData.emoji or ""
        iconDisplay.Font = Enum.Font.GothamBold
        iconDisplay.TextSize = 22
        iconDisplay.TextColor3 = Color3.new(1, 1, 1)
    end

    iconDisplay.Size = UDim2.new(0, 30, 0, 30)
    iconDisplay.Position = UDim2.new(0, 8, 0.5, -15)
    iconDisplay.BackgroundTransparency = 1
    iconDisplay.ZIndex = 5
    iconDisplay.Parent = container

    local displayNameLabel = Instance.new("TextLabel")
    displayNameLabel.Name = "DisplayNameLabel"
    displayNameLabel.BackgroundTransparency = 1
    local fullDisplayName = player.DisplayName or player.Name
    displayNameLabel.Text = "<font color='rgb(" .. math.floor(rankData.accent.R * 255) .. "," .. math.floor(rankData.accent.G * 255) .. "," .. math.floor(rankData.accent.B * 255) .. ")'>@" .. fullDisplayName .. "</font>"
    displayNameLabel.RichText = true
    displayNameLabel.TextSize = 10
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.ZIndex = 5
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rankText
    rankLabel.TextSize = 14
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextColor3 = rankData.accent
    rankLabel.TextXAlignment = Enum.TextXAlignment.Left
    rankLabel.ZIndex = 5

    local sidePadding = 16
    local iconWidth = 30
    local iconLeftPadding = 8
    local rankWidthActual = getTextWidth(rankLabel.Text, rankLabel.Font, rankLabel.TextSize)
    local displayNameWidthActual = getTextWidth("@" .. fullDisplayName, displayNameLabel.Font, displayNameLabel.TextSize)
    local maxTextWidth = math.max(rankWidthActual, displayNameWidthActual)
    local totalWidth = iconLeftPadding + iconWidth + sidePadding + maxTextWidth + sidePadding
    tag.Size = UDim2.new(0, totalWidth, 0, CONFIG.TAG_SIZE.Y.Offset)
    container.Size = UDim2.new(1, 0, 1, 0)
    iconDisplay.Position = UDim2.new(0, iconLeftPadding, 0.5, -15)
    iconDisplay.Size = UDim2.new(0, iconWidth, 0, 30)

    local textBlockXOffset = iconLeftPadding + iconWidth + sidePadding
    rankLabel.Position = UDim2.new(0, textBlockXOffset, 0, 3)
    rankLabel.Size = UDim2.new(0, rankWidthActual, 0, 16)
    rankLabel.Parent = container
    displayNameLabel.Position = UDim2.new(0, textBlockXOffset, 0, 17)
    displayNameLabel.Size = UDim2.new(0, displayNameWidthActual, 0, 16)
    displayNameLabel.Parent = container
    local isMinimized = false
    local FULL_SIZE = UDim2.new(0, totalWidth, 0, CONFIG.TAG_SIZE.Y.Offset)
    local MINI_SIZE = UDim2.new(0, 40, 0, 40)
    local MINI_OFFSET = Vector3.new(0, 1.0, 0)
    local activeTween = true
    spawn(function()
        while activeTween and tag and tag.Parent do
            if character and head and head.Parent and Players.LocalPlayer and Players.LocalPlayer.Character then
                local localHead = Players.LocalPlayer.Character:FindFirstChild("Head")
                if localHead then
                    local distance = (head.Position - localHead.Position).Magnitude
                    if distance > (CONFIG.DISTANCE_THRESHOLD + CONFIG.HYSTERESIS) and not isMinimized then
                        isMinimized = true
                        TweenService:Create(tag, TweenInfo.new(0.5), { Size = MINI_SIZE, StudsOffset = MINI_OFFSET }):Play()
                        TweenService:Create(rankLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
                        TweenService:Create(displayNameLabel, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
                        TweenService:Create(iconDisplay, TweenInfo.new(0.5), { Position = UDim2.new(0.5, -(iconWidth/2), 0.5, -(iconWidth/2)), Size = UDim2.new(0, iconWidth, 0, iconWidth)}):Play()
                        TweenService:Create(containerCorner, TweenInfo.new(0.5), { CornerRadius = UDim.new(1, 0) }):Play()
                    elseif distance < (CONFIG.DISTANCE_THRESHOLD - CONFIG.HYSTERESIS) and isMinimized then
                        isMinimized = false
                        TweenService:Create(tag, TweenInfo.new(0.5), { Size = FULL_SIZE, StudsOffset = CONFIG.TAG_OFFSET }):Play()
                        TweenService:Create(rankLabel, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
                        TweenService:Create(displayNameLabel, TweenInfo.new(0.5), { TextTransparency = 0 }):Play()
                        TweenService:Create(iconDisplay, TweenInfo.new(0.5), { Position = UDim2.new(0, iconLeftPadding, 0.5, -15), Size = UDim2.new(0, iconWidth, 0, 30)}):Play()
                        TweenService:Create(containerCorner, TweenInfo.new(0.5), { CornerRadius = CONFIG.CORNER_RADIUS }):Play()
                    end
                end
            else
                activeTween = false
            end
            task.wait(0.2)
        end
    end)
    tag.AncestryChanged:Connect(function(_, parent)
        if not parent then
            activeTween = false
        end
    end)
    Players.PlayerRemoving:Connect(function(removedPlayer)
        if removedPlayer == player then
            if tag and tag.Parent then
                tag:Destroy()
            end
            activeTween = false
        end
    end)
    tag.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    return tag
end

local localTagChoice = nil

local function showSENTINELAdminNotification(player)
    local playerName = player.Name
    local notifMessage = "@" .. playerName .. " Has executed SENTINEL ADMIN"
    local success, thumb = pcall(function()
        return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    end)
    if not success then thumb = "" end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SENTINELAdminNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, 250, 0, 60)
    frame.Position = UDim2.new(1, 10, 1, 10)
    frame.BackgroundColor3 = Color3.fromRGB(180, 160, 220)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 20)
    uiCorner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 0.5
    stroke.Parent = frame
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ProfilePic"
    imageLabel.Size = UDim2.new(0, 50, 0, 50)
    imageLabel.Position = UDim2.new(0, 10, 0, 5)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = thumb
    imageLabel.Parent = frame
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "NotificationText"
    textLabel.Size = UDim2.new(1, -70, 1, 0)
    textLabel.Position = UDim2.new(0, 60, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = notifMessage
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 16
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.Parent = frame
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -260, 1, -70)})
    tweenIn:Play()
    tweenIn.Completed:Wait()
    task.wait(3)
    local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 10, 1, 10)})
    tweenOut:Play()
    tweenOut.Completed:Wait()
    screenGui:Destroy()
end

local function createNotificationUI()
    if game:GetService("CoreGui"):FindFirstChild("TagNotification") or localTagChoice ~= nil then
        return nil, nil, nil
    end
    local gui = Instance.new("ScreenGui")
    gui.Name = "TagNotification"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(0, 280, 0, 140)
    frame.Position = UDim2.new(0.5, -140, 0.5, -70)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 0
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = frame
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.8
    stroke.Thickness = 1
    stroke.Parent = frame
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 16
    title.Text = "Tag Visibility Settings"
    title.Parent = frame
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(0.9, 0, 0, 40)
    messageLabel.Position = UDim2.new(0.05, 0, 0.35, 0)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    messageLabel.TextSize = 14
    messageLabel.TextWrapped = true
    messageLabel.Text = "Would you like to display your rank tag above your character?"
    messageLabel.Parent = frame
    local function createButton(text, position, color)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0.35, 0, 0, 30)
        button.Position = position
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 14
        button.Text = text
        button.AutoButtonColor = false
        button.BackgroundTransparency = 0
        button.Parent = frame
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0.2}):Play()
        end)
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.15), {BackgroundTransparency = 0}):Play()
        end)
        return button
    end
    local yesButton = createButton("Yes", UDim2.new(0.1, 0, 0.7, 0), Color3.fromRGB(46, 204, 113))
    local noButton = createButton("No", UDim2.new(0.55, 0, 0.7, 0), Color3.fromRGB(231, 76, 60))
    return gui, yesButton, noButton
end

local charAddedConn
local notificationGuiVisible = false

local function attachTagAndConnect(player, rankText)
    if player.Character then
        attachTagToHead(player.Character, player, rankText)
    end
    if charAddedConn and charAddedConn.Connected then charAddedConn:Disconnect() end
    charAddedConn = player.CharacterAdded:Connect(function(character)
        task.wait()
        attachTagToHead(character, player, rankText)
    end)
    local playerRemovingConn
    playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            if charAddedConn and charAddedConn.Connected then charAddedConn:Disconnect() end
            if playerRemovingConn and playerRemovingConn.Connected then playerRemovingConn:Disconnect() end
        end
    end)
end

local function cleanupNotificationUI(gui, yesConn, noConn)
    if yesConn and yesConn.Connected then yesConn:Disconnect() end
    if noConn and noConn.Connected then noConn:Disconnect() end
    if gui and gui.Parent then gui:Destroy() end
    notificationGuiVisible = false
end

local function handleUserChoice(player, rankText, choice)
    if choice then
        attachTagAndConnect(player, rankText)
    end
    localTagChoice = choice
end

local function createTag(player, rankText, showPrompt)
    if showPrompt and player == Players.LocalPlayer then
        if localTagChoice ~= nil then
            if localTagChoice then
                attachTagAndConnect(player, rankText)
            end
            return
        end
        if notificationGuiVisible then
            return
        end
        local gui, yesButton, noButton = createNotificationUI()
        if not gui then return end
        local playerGui = player:WaitForChild("PlayerGui", 5)
        if not playerGui then
            if gui and gui.Parent then gui:Destroy() end
            return
        end
        gui.Parent = playerGui
        notificationGuiVisible = true
        local yesConn, noConn
        yesConn = yesButton.MouseButton1Click:Connect(function()
            handleUserChoice(player, rankText, true)
            cleanupNotificationUI(gui, yesConn, noConn)
        end)
        noConn = noButton.MouseButton1Click:Connect(function()
            handleUserChoice(player, rankText, false)
            cleanupNotificationUI(gui, yesConn, noConn)
        end)
    else
        attachTagAndConnect(player, rankText)
    end
end

local function applyPlayerTag(player)
    if not player or not player:IsDescendantOf(Players) then
        return
    end
    local showPrompt = (player == Players.LocalPlayer)
    local assignedTag = nil
    local playerNameLower = player.Name:lower()

    -- Zuerst prüfen, ob der Spieler ein definierter Owner ist
    if playerToTag[playerNameLower] then
        assignedTag = playerToTag[playerNameLower] -- Dies wird "SENTINEL OWNER" sein
    elseif ChatWhitelist[playerNameLower] then -- Dann prüfen, ob der Spieler in der Chat-Whitelist für User ist
        assignedTag = "SENTINEL USER"
    else
        -- Kein expliziter Tag für diesen Spieler
    end

    local localPlayerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not localPlayerGui then return end


    if player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("BillboardGui") and child.Name == "RankTag" then
                child:Destroy()
            end
        end
        for _, gui in ipairs(localPlayerGui:GetChildren()) do
            if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == head then
                gui:Destroy()
            end
        end
    end

    if assignedTag then
        local rankConfig = RankData[assignedTag]
        if rankConfig and rankConfig.UseImage and (not rankConfig.localImageAssetId or rankConfig.localImageAssetId == "") then
            -- print("Warte auf Bild-Asset für Rang: " .. assignedTag .. " für Spieler " .. player.Name)
            local successLoading = loadImageAsset(rankConfig)
            if not successLoading then
                 warn("Konnte Bild für " .. assignedTag .. " nicht laden, bevor Tag erstellt wurde für " .. player.Name .. ". Fallback.")
            end
        end
        createTag(player, assignedTag, showPrompt)
    end
end

local chatConnections = {}

local function setupChatListener(player)
    if chatConnections[player] then
        return
    end

    local conn = player.Chatted:Connect(function(msg)
        if not player or not player:IsDescendantOf(Players) then
            if chatConnections[player] and chatConnections[player].Connected then
                chatConnections[player]:Disconnect()
            end
            chatConnections[player] = nil
            return
        end
        if modifyString(msg:lower()) == modifiedMessage:lower() then
            local playerNameLower = player.Name:lower()
            -- Nur Whitelisten, wenn der Spieler nicht bereits ein Owner ist
            if not playerToTag[playerNameLower] and not ChatWhitelist[playerNameLower] then
                ChatWhitelist[playerNameLower] = true
                print(player.Name .. " zur ChatWhitelist für SENTINEL USER hinzugefügt.")
                applyPlayerTag(player) -- Tag neu anwenden, jetzt als User
                showSENTINELAdminNotification(player)
            elseif playerToTag[playerNameLower] then
                -- print(player.Name .. " ist bereits Owner, wird nicht zur User-Whitelist hinzugefügt.")
            elseif ChatWhitelist[playerNameLower] then
                -- print(player.Name .. " ist bereits in der User-Whitelist.")
            end
        end
    end)
    chatConnections[player] = conn
end

local localPlayerGui = Players.LocalPlayer and Players.LocalPlayer:WaitForChild("PlayerGui")

if localPlayerGui then
    spawn(function()
        while task.wait(2) do
            if not Players.LocalPlayer or not Players.LocalPlayer:FindFirstChild("PlayerGui") then break end
            localPlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
            
            local validAdornees = {}
            local currentPlayers = Players:GetPlayers()
            for _, player in ipairs(currentPlayers) do
                if player.Character and player.Character:FindFirstChild("Head") then
                    table.insert(validAdornees, player.Character.Head)
                    local hasTag = false
                    for _, gui in ipairs(localPlayerGui:GetChildren()) do
                        if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == player.Character.Head then
                            hasTag = true
                            break
                        end
                    end
                    local playerNameLower = player.Name:lower()
                    local shouldHaveTag = playerToTag[playerNameLower] or ChatWhitelist[playerNameLower]
                    if shouldHaveTag and not hasTag then
                        applyPlayerTag(player)
                    end
                end
            end
            for _, gui in ipairs(localPlayerGui:GetChildren()) do
                if gui:IsA("BillboardGui") and gui.Name == "RankTag" then
                    local adornee = gui.Adornee
                    if not adornee or not adornee:IsDescendantOf(workspace) or not table.find(validAdornees, adornee) then
                        gui:Destroy()
                    end
                end
            end
        end
    end)
else
    warn("LocalPlayerGui nicht beim Start des Aufräum-Loops gefunden.")
end


for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(applyPlayerTag, player)
    task.spawn(setupChatListener, player)
end

Players.PlayerAdded:Connect(function(player)
    task.wait(0.5)
    task.spawn(setupChatListener, player)
    task.spawn(applyPlayerTag, player)
end)

Players.PlayerRemoving:Connect(function(player)
    if chatConnections[player] and chatConnections[player].Connected then
        chatConnections[player]:Disconnect()
        chatConnections[player] = nil
    end
    
    if localPlayerGui then
        local playerHead = player.Character and player.Character:FindFirstChild("Head")
        if playerHead then
            for _, gui in ipairs(localPlayerGui:GetChildren()) do
                if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == playerHead then
                    gui:Destroy()
                end
            end
        end
    end

    if player == Players.LocalPlayer then
        local playerGuiInstance = player:FindFirstChild("PlayerGui")
        if playerGuiInstance then
            local notification = playerGuiInstance:FindFirstChild("TagNotification")
            if notification then
                notification:Destroy()
            end
        end
        localTagChoice = nil
    end
end)

return {
    refreshTags = function()
        print("Refreshing all player tags...")
        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(applyPlayerTag, player)
        end
    end,
    forceTag = function(player, rankType)
        if not player or not player:IsDescendantOf(Players) then
            warn("forceTag: Invalid player.")
            return false
        end
        if RankData[rankType] then
            print("Forcing tag '" .. rankType .. "' for player: " .. player.Name)
            if player.Character and player.Character:FindFirstChild("Head") then
                local head = player.Character.Head
                for _, child in ipairs(head:GetChildren()) do
                    if child.Name == "RankTag" and child:IsA("BillboardGui") then
                        child:Destroy()
                    end
                end
            end
            if localPlayerGui then
                 for _, gui in ipairs(localPlayerGui:GetChildren()) do
                    if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee and gui.Adornee.Parent == player.Character then
                        gui:Destroy()
                    end
                end
            end

            local rankConfig = RankData[rankType]
            if rankConfig.UseImage and (not rankConfig.localImageAssetId or rankConfig.localImageAssetId == "") then
                warn("forceTag: Image for rank '" .. rankType .. "' not yet loaded. Attempting to load now.")
                loadImageAsset(rankConfig)
            end

            createTag(player, rankType, player == Players.LocalPlayer)
            return true
        else
            warn("forceTag: Invalid rankType: " .. tostring(rankType))
            return false
        end
    end
}

--- END OF MODIFIED FILE (NO JSON, DIRECT OWNER LIST) ---
