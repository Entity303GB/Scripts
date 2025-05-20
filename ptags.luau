-- Sentinel Admin Tag System
--- START OF MODIFIED FILE ---

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
-- ## RANK DATA - Definitionen der Tag-Styles ##
-- #####################################################################
local RankData = {
    ["SENTINEL OWNER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(255, 215, 0), -- Gold
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseVideo = true,
        videoUrl = "https://github.com/Entity303GB/Scripts/raw/refs/heads/main/input_video.mp4",
        localVideoFileName = "sentinel_owner_video.mp4",
        localVideoAssetId = "",
        UseImage = true,
        imageUrl = "https://raw.githubusercontent.com/Entity303GB/Scripts/3f2bd1cdeb67e1f6d9150c101d54c247afd022e1/owner.png",
        localFileName = "sentinel_owner_icon.png",
        localImageAssetId = "",
        emoji = nil,
    },
    ["Sentinel User"] = {
		primary = Color3.fromRGB(20, 20, 20),
		accent = Color3.fromRGB(192, 192, 192),
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseVideo = true,
        videoUrl = "https://github.com/Entity303GB/Scripts/raw/refs/heads/main/sentinel_user_video.mp4",
        localVideoFileName = "sentinel_user_video.mp4",
        localVideoAssetId = "",
        UseImage = true,
        imageUrl = "https://raw.githubusercontent.com/Entity303GB/Scripts/refs/heads/main/user.png",
        localFileName = "sentinel_user_icon.png",
        localImageAssetId = "",
        emoji = nil,
    },
    ["SENTINEL SUPPORTER"] = {
        primary = Color3.fromRGB(20, 20, 20),
        accent = Color3.fromRGB(0, 0, 200),
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseVideo = true,
        videoUrl = "https://github.com/Entity303GB/Scripts/raw/refs/heads/main/sentinel_supporter_video%20(1).mp4",
        localVideoFileName = "sentinel_supporter_video.mp4",
        localVideoAssetId = "",
        UseImage = false,
        imageUrl = "URL_ZUM_SUPPORTER_ICON.png",
        localFileName = "sentinel_supporter_icon.png",
        localImageAssetId = "",
        emoji = "🛡️",
    },
    -- NEUE ROLLE FÜR TAMI_MOGLI
    ["SENTINEL MOMMY"] = {
        primary = Color3.fromRGB(255, 255, 255), -- Weiß (für den Übergang)
        accent = Color3.fromRGB(255, 105, 180), -- Hot Pink (ein kräftiges "Mommy Pink")
        AnimateName = false, JumpLetters = false, GlitchName = false,
        UseVideo = true,
        videoUrl = "https://github.com/Entity303GB/Scripts/raw/refs/heads/main/input_video_Rosa_smooth%20(1).mp4",
        localVideoFileName = "tami_mogli_video.mp4", -- Eindeutiger lokaler Dateiname
        localVideoAssetId = "",
        UseImage = true,
        imageUrl = "https://raw.githubusercontent.com/Entity303GB/Scripts/refs/heads/main/bow.png",
        localFileName = "tami_mogli_icon.png", -- Eindeutiger lokaler Dateiname
        localImageAssetId = "",
        emoji = nil, -- Kein Emoji wie gewünscht
    }
}
-- #####################################################################


-- #####################################################################
-- ## ROLE CONFIGURATION - HIER SPIELER ZU SPEZIFISCHEN TAGS ZUWEISEN ##
-- #####################################################################
local ROLE_DEFINITIONS = {
    {
        roleNameForLogging = "Owner",
        allowedPlayers = {
            "goetemp_4",
            "str4wberrymymommy",
			"goetemp_2",
			"goetemp_3",
			""
        },
        rankDataKey = "SENTINEL OWNER"
    },
    {
        roleNameForLogging = "Supporter",
        allowedPlayers = {
             "0jxl0",
             "FSK_WayzZ",
			 "IBimsDerBimbo44",
			 ""
        },
        rankDataKey = "SENTINEL SUPPORTER"
    },
    -- ZUWEISUNG FÜR TAMI_MOGLI
    {
        roleNameForLogging = "Mommy", -- Ein Name für die Logs, kann beliebig sein
        allowedPlayers = {
            "Tami_Mogli" -- Der genaue Benutzername
        },
        rankDataKey = "SENTINEL MOMMY" -- Muss mit dem Schlüssel in RankData übereinstimmen
    }
}

local forcedTags = {}
local activatedSentinelUsers = {}

local function initializeAndLogRoleConfiguration()
    if #ROLE_DEFINITIONS == 0 then
        print("INFO: Keine spezifischen Rollen in ROLE_DEFINITIONS definiert. Spieler erhalten den 'Sentinel User' Tag nur, wenn sie die Aktivierungsnachricht senden oder das Script ausführen.")
    end

    for i = #ROLE_DEFINITIONS, 1, -1 do -- Iterate backwards when removing
        local roleDef = ROLE_DEFINITIONS[i]
        if not (roleDef.roleNameForLogging and roleDef.allowedPlayers and roleDef.rankDataKey) then
            warn("WARNUNG: Ungültige Rollendefinition bei Index " .. i .. " gefunden - überspringe.")
            table.remove(ROLE_DEFINITIONS, i)
            continue
        end

        if not (RankData and RankData[roleDef.rankDataKey]) then
            warn("WARNUNG: RankData für '" .. roleDef.rankDataKey .. "' (definiert in ROLE_DEFINITIONS) nicht in RankData gefunden.")
        end
    end

    if not (RankData and RankData["Sentinel User"]) then
        warn("WARNUNG: Der Tag-Style 'Sentinel User' ist nicht in RankData definiert! Spieler, die die Nachricht senden oder das Skript ausführen, erhalten möglicherweise keinen Tag.")
    end

    return true
end
initializeAndLogRoleConfiguration()


local function getPlayerRankDataKey(player)
    if not player or not player:IsA("Player") then return nil end
    local userId = player.UserId
    local playerNameLower = string.lower(player.Name)

    if forcedTags[userId] then
        if RankData and RankData[forcedTags[userId]] then
            return forcedTags[userId]
        else
            warn("Invalid forced rank '" .. forcedTags[userId] .. "' for player " .. player.Name .. ". Ignoring and removing.")
            forcedTags[userId] = nil
        end
    end

    for _, roleDef in ipairs(ROLE_DEFINITIONS) do
        if roleDef.allowedPlayers and roleDef.rankDataKey then
            for _, allowedPlayerName in ipairs(roleDef.allowedPlayers) do
                if type(allowedPlayerName) == "string" and string.lower(allowedPlayerName) == playerNameLower then
                    if RankData and RankData[roleDef.rankDataKey] then
                        return roleDef.rankDataKey
                    else
                        warn("Player " .. player.Name .. " is assigned to role '" .. roleDef.roleNameForLogging ..
                             "', but its RankDataKey '" .. roleDef.rankDataKey .. "' is not found or invalid in RankData. " ..
                             "This player will NOT receive this specific tag. They will receive no tag.")
                        return nil
                    end
                end
            end
        end
    end

    if player == Players.LocalPlayer then
        if RankData and RankData["Sentinel User"] then
            return "Sentinel User"
        else
            warn("Local player " .. player.Name .. " would get 'Sentinel User' tag by script execution, but 'Sentinel User' tag style is not configured in RankData.")
        end
    end

    if activatedSentinelUsers[userId] then
        if RankData and RankData["Sentinel User"] then
            return "Sentinel User"
        else
            warn("Player " .. player.Name .. " activated 'Sentinel User' tag (or local player fallback), but the 'Sentinel User' tag style is not configured in RankData.")
            return nil
        end
    end

    return nil
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

local VIDEO_CONFIG = {
    HEIGHT_SCALE = 5,
    Y_OFFSET = -20,
    BORDER_THICKNESS = 3,
    CLIP_CONTENT = true
}

local globalLocalPlayerGuiRef = nil
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
    VIDEO_Y_OFFSET = VIDEO_CONFIG.Y_OFFSET,
    VIDEO_HEIGHT_SCALE = VIDEO_CONFIG.HEIGHT_SCALE,
    ICON_SIZE = 30,
    ICON_LEFT_PADDING = 8,
    BACKGROUND_TRANSPARENCY = 0.7,
    ICON_BACKGROUND_ENABLED = true,
    ICON_BACKGROUND_COLOR = Color3.fromRGB(50, 50, 50),
    ICON_BACKGROUND_TRANSPARENCY = 0.2,
    ICON_BACKGROUND_SIZE_OFFSET = 6,
    BORDER_GRADIENT_ENABLED = true,
    BORDER_GRADIENT_DARKEN_FACTOR = 0.6,
}

local function downloadAsset(url, localFileName, assetType)
    if not write_func or not exists_func or not asset_func or not crequest then
        warn("FEHLER: Executor-Funktionen zum Laden von " .. assetType .. " nicht verfügbar.")
        return nil
    end
    if exists_func(localFileName) then
        local success, assetId = pcall(asset_func, localFileName)
        if success and assetId then
            return assetId
        else
            warn("Konnte existierendes " .. assetType .. " nicht aus Workspace laden: " .. localFileName .. (assetId and (" - Error: " .. tostring(assetId)) or ""))
        end
    end
    local assetData
    local successOnRequest, response = pcall(crequest, { Url = url, Method = "GET" })
    if successOnRequest and response and response.Body then
        assetData = response.Body
    else
        local httpSuccess, httpResult = pcall(function()
            return HttpService:GetAsync(url, true)
        end)
        if httpSuccess and httpResult then
            assetData = httpResult
        else
            warn("FEHLER: Konnte " .. assetType .. " nicht herunterladen von: " .. url .. (response and (" - crequest Status: " .. tostring(response.StatusMessage)) or (httpResult and (" - HttpService Error: " .. tostring(httpResult)) or "")))
            return nil
        end
    end
    if assetData then
        local writeSuccess, writeError = pcall(write_func, localFileName, assetData)
        if writeSuccess then
            task.wait(0.2)
            local assetSuccess, assetId = pcall(asset_func, localFileName)
            if assetSuccess and assetId then
                print(assetType .. " heruntergeladen und geladen: " .. localFileName)
                return assetId
            else
                warn("FEHLER: Konnte kein Asset aus heruntergeladenem " .. assetType .. " erstellen: " .. localFileName .. (assetId and (" - Error: " .. tostring(assetId)) or ""))
                return nil
            end
        else
            warn("FEHLER: Konnte " .. assetType .. "-Daten nicht speichern unter: " .. localFileName .. " - Error: " .. tostring(writeError))
            return nil
        end
    end
    return nil
end

local function loadIconImageAsset(rankConfigEntry)
    if not rankConfigEntry.UseImage or not rankConfigEntry.imageUrl or rankConfigEntry.imageUrl == "" or not rankConfigEntry.localFileName or rankConfigEntry.localFileName == "" then
        return false
    end
    if rankConfigEntry.localImageAssetId and rankConfigEntry.localImageAssetId ~= "" then
        return true
    end
    local assetId = downloadAsset(rankConfigEntry.imageUrl, rankConfigEntry.localFileName, "Icon-Bild")
    if assetId then
        rankConfigEntry.localImageAssetId = assetId
        return true
    else
        return false
    end
end

local function loadVideoAsset(rankConfigEntry)
    if not rankConfigEntry.UseVideo or not rankConfigEntry.videoUrl or rankConfigEntry.videoUrl == "" or not rankConfigEntry.localVideoFileName or rankConfigEntry.localVideoFileName == "" then
        return false
    end
     if rankConfigEntry.localVideoAssetId and rankConfigEntry.localVideoAssetId ~= "" then
        return true
    end
    if exists_func(rankConfigEntry.localVideoFileName) then
        local success, assetId = pcall(asset_func, rankConfigEntry.localVideoFileName)
        if success and assetId then
            rankConfigEntry.localVideoAssetId = assetId
            return true
        else
            warn("Konnte Video nicht aus existierender Datei laden: " .. rankConfigEntry.localVideoFileName .. (assetId and (" - Error: " .. tostring(assetId)) or ""))
        end
    end
    local assetId = downloadAsset(rankConfigEntry.videoUrl, rankConfigEntry.localVideoFileName, "Video")
    if assetId then
        rankConfigEntry.localVideoAssetId = assetId
        return true
    else
        return false
    end
end

local function checkAndLoadAssets(rankConfig)
    if not rankConfig then return false end
    local rankNameForLog = rankConfig.rankName or "Unbekannt"

    local assetsCompletelyReady = true

    if rankConfig.UseVideo then
        if not (rankConfig.localVideoAssetId and rankConfig.localVideoAssetId ~= "") then
            if not loadVideoAsset(rankConfig) then
                -- assetsCompletelyReady = false -- Video is optional for tag creation
            end
        end
    end

    local iconAssetAvailable = false
    if rankConfig.UseImage then
        if not (rankConfig.localImageAssetId and rankConfig.localImageAssetId ~= "") then
            if loadIconImageAsset(rankConfig) then
                iconAssetAvailable = true
            else
                 if rankConfig.emoji and rankConfig.emoji ~= "" then
                    iconAssetAvailable = true
                 end
            end
        else
            iconAssetAvailable = true
        end
    elseif rankConfig.emoji and rankConfig.emoji ~= "" then
        iconAssetAvailable = true
    end

    if not iconAssetAvailable then
        warn("Kein Icon (weder Bild noch Emoji) verfügbar für Rang '" .. rankNameForLog .. "'. Tag-Erstellung könnte fehlschlagen oder unvollständig sein.")
        assetsCompletelyReady = false
    end

    return assetsCompletelyReady
end

local function preloadRankAssets()
    if not asset_func then
         warn("Executor-Funktion 'asset_func' nicht gefunden. Bild- und Video-Tags werden nicht funktionieren. Fallback auf Emojis/Text, falls konfiguriert.")
         for rankKey, data in pairs(RankData) do
             data.UseImage = false
             data.UseVideo = false
         end
         return
    end

    local ranksToPreload = {}
    for _, roleDef in ipairs(ROLE_DEFINITIONS) do
        if roleDef.rankDataKey and RankData[roleDef.rankDataKey] and not ranksToPreload[roleDef.rankDataKey] then -- Fixed typo rankDataKrankKeyand
            local rankCfg = RankData[roleDef.rankDataKey]
            if rankCfg.UseImage or rankCfg.UseVideo then
                 ranksToPreload[roleDef.rankDataKey] = true
            end
        end
    end

    local defaultRankKey = "Sentinel User"
    if RankData[defaultRankKey] and not ranksToPreload[defaultRankKey] then
        local defaultRankConfig = RankData[defaultRankKey]
        if defaultRankConfig.UseVideo or defaultRankConfig.UseImage then
            ranksToPreload[defaultRankKey] = true
        end
    end

    if next(ranksToPreload) == nil then
        return
    end

    for rankKey, _ in pairs(ranksToPreload) do
        local data = RankData[rankKey]
        if data then
            data.rankName = rankKey
            task.spawn(function()
                checkAndLoadAssets(data)
            end)
        end
    end
end

preloadRankAssets()


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
    local success, size = pcall(TextService.GetTextSize, TextService, text, textSize, font, Vector2.new(2000, CONFIG.TAG_SIZE.Y.Offset))
    if success and size then
        return math.ceil(size.X)
    else
        return #text * (textSize / 1.8)
    end
end

local function attachTagToHead(character, player, rankTextKey)
    local head = character:FindFirstChild("Head")
    if not head then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    end

    -- NEU: Alten Tag vom PlayerGui entfernen, falls vorhanden
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for i = #playerGui:GetChildren(), 1, -1 do
            local child = playerGui:GetChildren()[i]
            if child.Name == "RankTag" and child:IsA("BillboardGui") and child.Adornee == head then
                child:Destroy()
            end
        end
    end
    -- NEU: Alten Tag direkt vom Kopf entfernen, falls vorhanden
     for _, child in ipairs(head:GetChildren()) do
        if child.Name == "RankTag" and child:IsA("BillboardGui") then
            child:Destroy()
        end
    end


    local rankData = RankData[rankTextKey]
    if not rankData then
        return nil
    end

    if not rankData.rankName then rankData.rankName = rankTextKey end
    if not checkAndLoadAssets(rankData) then
        if not ( (rankData.UseImage and rankData.localImageAssetId and rankData.localImageAssetId ~= "") or (rankData.emoji and rankData.emoji ~= "") ) then
            return nil
        end
    end

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
    tag.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local videoContainer = Instance.new("Frame")
    videoContainer.Name = "VideoContainer"
    videoContainer.Size = UDim2.new(1, 0, 1, 0)
    videoContainer.BackgroundTransparency = 1
    videoContainer.ZIndex = 1
    videoContainer.ClipsDescendants = VIDEO_CONFIG.CLIP_CONTENT
    videoContainer.Parent = tag
    local vcCorner = Instance.new("UICorner") -- vcCorner für videoContainer
    vcCorner.CornerRadius = CONFIG.CORNER_RADIUS
    vcCorner.Parent = videoContainer

    if rankData.UseVideo and rankData.localVideoAssetId and rankData.localVideoAssetId ~= "" then
        local videoDisplay = Instance.new("VideoFrame")
        videoDisplay.Name = "RankVideoBackground"
        videoDisplay.Video = rankData.localVideoAssetId
        videoDisplay.Looped = true
        videoDisplay.Playing = true
        videoDisplay.Volume = 0
        videoDisplay.Size = UDim2.new(1, 0, CONFIG.VIDEO_HEIGHT_SCALE, 0)
        videoDisplay.Position = UDim2.new(0, 0, (1 - CONFIG.VIDEO_HEIGHT_SCALE) / 2, CONFIG.VIDEO_Y_OFFSET)
        videoDisplay.BackgroundTransparency = 1
        videoDisplay.ZIndex = 1
        videoDisplay.Parent = videoContainer
    end

    local backgroundContainer = Instance.new("Frame")
    backgroundContainer.Name = "BackgroundContainer"
    backgroundContainer.Size = UDim2.new(1, 0, 1, 0)
    backgroundContainer.BackgroundColor3 = rankData.primary
    backgroundContainer.BackgroundTransparency = CONFIG.BACKGROUND_TRANSPARENCY
    backgroundContainer.BorderSizePixel = 0
    backgroundContainer.ZIndex = 2
    backgroundContainer.Parent = tag
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = CONFIG.CORNER_RADIUS
    bgCorner.Parent = backgroundContainer

    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, 0, 1, 0)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ZIndex = 3
    contentContainer.Parent = tag

    local borderContainer = Instance.new("Frame")
    borderContainer.Name = "BorderContainer"
    borderContainer.Size = UDim2.new(1, 0, 1, 0)
    borderContainer.BackgroundTransparency = 1
    borderContainer.ZIndex = 4
    borderContainer.Parent = tag
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = CONFIG.CORNER_RADIUS
    borderCorner.Parent = borderContainer

    local outerStroke = Instance.new("UIStroke")
    outerStroke.Thickness = VIDEO_CONFIG.BORDER_THICKNESS
    outerStroke.LineJoinMode = Enum.LineJoinMode.Round
    outerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    outerStroke.Parent = borderContainer
    if CONFIG.BORDER_GRADIENT_ENABLED and rankData.accent then
        local accentColor = rankData.accent
        local shadowColor = Color3.new(
            math.max(0, accentColor.R - CONFIG.BORDER_GRADIENT_DARKEN_FACTOR),
            math.max(0, accentColor.G - CONFIG.BORDER_GRADIENT_DARKEN_FACTOR),
            math.max(0, accentColor.B - CONFIG.BORDER_GRADIENT_DARKEN_FACTOR)
        )
        outerStroke.Color = accentColor
        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, accentColor),
            ColorSequenceKeypoint.new(0.5, shadowColor),
            ColorSequenceKeypoint.new(1, accentColor)
        })
        gradient.Rotation = 90
        gradient.Parent = outerStroke
    elseif rankData.accent then
        outerStroke.Color = rankData.accent
        outerStroke.Transparency = 0
    else
        outerStroke.Color = Color3.new(1,1,1)
        outerStroke.Transparency = 0.5
    end


    local clickButton = Instance.new("TextButton")
    clickButton.Name = "ClickButton"
    clickButton.Size = UDim2.new(1, 0, 1, 0)
    clickButton.BackgroundTransparency = 1
    clickButton.Text = ""
    clickButton.ZIndex = 5
    clickButton.AutoButtonColor = false
    clickButton.Active = true
    clickButton.Parent = tag
    if player ~= Players.LocalPlayer then
        clickButton.MouseButton1Click:Connect(function() teleportToPlayer(player) end)
        clickButton.MouseEnter:Connect(function() TweenService:Create(backgroundContainer, TweenInfo.new(0.2), {BackgroundTransparency = CONFIG.BACKGROUND_TRANSPARENCY * 0.5}):Play() end)
        clickButton.MouseLeave:Connect(function() TweenService:Create(backgroundContainer, TweenInfo.new(0.2), {BackgroundTransparency = CONFIG.BACKGROUND_TRANSPARENCY}):Play() end)
    end

    local iconDisplay = nil
    local actualIconWidth = CONFIG.ICON_SIZE
    local actualIconLeftPadding = CONFIG.ICON_LEFT_PADDING
    local iconBackground = nil
    local iconDisplayCorner = nil -- Wichtig für Tweening

    if CONFIG.ICON_BACKGROUND_ENABLED and ((rankData.UseImage and rankData.localImageAssetId and rankData.localImageAssetId ~= "") or (rankData.emoji and rankData.emoji ~= "")) then
        iconBackground = Instance.new("Frame")
        iconBackground.Name = "IconBackground"
        local bgSize = actualIconWidth + CONFIG.ICON_BACKGROUND_SIZE_OFFSET
        iconBackground.Size = UDim2.new(0, bgSize, 0, bgSize)
        iconBackground.Position = UDim2.new(0, actualIconLeftPadding - (CONFIG.ICON_BACKGROUND_SIZE_OFFSET / 2), 0.5, -(bgSize / 2))
        iconBackground.BackgroundColor3 = CONFIG.ICON_BACKGROUND_COLOR
        iconBackground.BackgroundTransparency = CONFIG.ICON_BACKGROUND_TRANSPARENCY
        iconBackground.BorderSizePixel = 0
        iconBackground.Parent = contentContainer
        local iconBgCorner = Instance.new("UICorner")
        iconBgCorner.CornerRadius = UDim.new(0, bgSize / 2) -- Macht es zirkulär
        iconBgCorner.Parent = iconBackground
    end

    if rankData.UseImage and rankData.localImageAssetId and rankData.localImageAssetId ~= "" then
        iconDisplay = Instance.new("ImageLabel")
        iconDisplay.Name = "RankIconImage"
        iconDisplay.Image = rankData.localImageAssetId
        iconDisplay.ScaleType = Enum.ScaleType.Fit

        -- UICorner für das iconDisplay ImageLabel hinzufügen
        iconDisplayCorner = Instance.new("UICorner")
        iconDisplayCorner.CornerRadius = UDim.new(0, actualIconWidth / 2) -- Macht das Icon standardmäßig rund
        iconDisplayCorner.Parent = iconDisplay

    elseif rankData.emoji and rankData.emoji ~= "" then
        iconDisplay = Instance.new("TextLabel")
        iconDisplay.Name = "RankIconEmoji"
        iconDisplay.Text = rankData.emoji
        iconDisplay.Font = Enum.Font.GothamBold
        iconDisplay.TextSize = math.floor(actualIconWidth * 0.9)
        iconDisplay.TextColor3 = rankData.accent or Color3.new(1,1,1)
        iconDisplay.TextScaled = true
    end

    if iconDisplay then
        iconDisplay.Size = UDim2.new(0, actualIconWidth, 0, actualIconWidth)
        iconDisplay.Position = UDim2.new(0, actualIconLeftPadding, 0.5, -actualIconWidth / 2)
        iconDisplay.BackgroundTransparency = 1
        iconDisplay.ZIndex = (iconBackground and iconBackground.ZIndex + 1 or 1)
        iconDisplay.Parent = contentContainer
    else
        if iconBackground then iconBackground:Destroy(); iconBackground = nil; end
        actualIconWidth = 0
        actualIconLeftPadding = 8
    end

    local displayNameLabel = Instance.new("TextLabel")
    displayNameLabel.Name = "DisplayNameLabel"
    displayNameLabel.BackgroundTransparency = 1
    local fullDisplayName = player.DisplayName or player.Name
    local accentR = rankData.accent and math.floor(rankData.accent.R * 255) or 255
    local accentG = rankData.accent and math.floor(rankData.accent.G * 255) or 255
    local accentB = rankData.accent and math.floor(rankData.accent.B * 255) or 255
    displayNameLabel.Text = "<font color='rgb(" .. accentR .. "," .. accentG .. "," .. accentB .. ")'>@" .. fullDisplayName .. "</font>"
    displayNameLabel.RichText = true
    displayNameLabel.TextSize = 10
    displayNameLabel.Font = Enum.Font.GothamBold
    displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
    displayNameLabel.TextColor3 = Color3.new(1,1,1)
    displayNameLabel.Parent = contentContainer
    local displayNameTextStroke = Instance.new("UIStroke")
    displayNameTextStroke.Color = Color3.fromRGB(0, 0, 0)
    displayNameTextStroke.Thickness = 1.5
    displayNameTextStroke.Parent = displayNameLabel

    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.BackgroundTransparency = 1
    rankLabel.Text = rankTextKey
    rankLabel.TextSize = 14
    rankLabel.Font = Enum.Font.GothamBold
    rankLabel.TextColor3 = rankData.accent or Color3.new(1,1,1)
    rankLabel.TextXAlignment = Enum.TextXAlignment.Left
    rankLabel.Parent = contentContainer
    local rankTextStroke = Instance.new("UIStroke")
    rankTextStroke.Color = Color3.fromRGB(0, 0, 0)
    rankTextStroke.Thickness = 2
    rankTextStroke.Parent = rankLabel

    local sidePadding = 8
    local textBlockPadding = (iconDisplay or iconBackground) and 8 or 0
    local rankWidthActual = getTextWidth(rankLabel.Text, rankLabel.Font, rankLabel.TextSize)
    local displayNameWidthActual = getTextWidth("@" .. fullDisplayName, displayNameLabel.Font, displayNameLabel.TextSize)
    local maxTextWidth = math.max(rankWidthActual, displayNameWidthActual)
    local totalWidth
    local textBlockXOffset

    if iconDisplay or iconBackground then
        textBlockXOffset = actualIconLeftPadding + actualIconWidth + textBlockPadding
        totalWidth = textBlockXOffset + maxTextWidth + sidePadding
    else
        textBlockXOffset = actualIconLeftPadding
        totalWidth = textBlockXOffset + maxTextWidth + sidePadding
    end
    tag.Size = UDim2.new(0, totalWidth, 0, CONFIG.TAG_SIZE.Y.Offset)

    rankLabel.Position = UDim2.new(0, textBlockXOffset, 0, 2)
    rankLabel.Size = UDim2.new(0, rankWidthActual, 0, 16)
    displayNameLabel.Position = UDim2.new(0, textBlockXOffset, 0, 16)
    displayNameLabel.Size = UDim2.new(0, displayNameWidthActual, 0, 14)

    local isMinimized = false
    local FULL_SIZE = tag.Size
    local MINI_ICON_SIZE_FACTOR = 0.8
    local MINI_ICON_SIZE = CONFIG.ICON_SIZE * MINI_ICON_SIZE_FACTOR
    local MINI_BACKGROUND_OFFSET_FACTOR = CONFIG.ICON_BACKGROUND_SIZE_OFFSET * MINI_ICON_SIZE_FACTOR
    local MINI_SIZE_WIDTH = (iconDisplay and (MINI_ICON_SIZE + (iconBackground and MINI_BACKGROUND_OFFSET_FACTOR or 4) + 4)) or (CONFIG.TAG_SIZE.Y.Offset * MINI_ICON_SIZE_FACTOR)
    MINI_SIZE_WIDTH = math.max(MINI_SIZE_WIDTH, CONFIG.TAG_SIZE.Y.Offset * 0.8)
    local MINI_SIZE = UDim2.new(0, MINI_SIZE_WIDTH, 0, MINI_SIZE_WIDTH)
    local MINI_OFFSET = Vector3.new(0, 1.2, 0)
    local activeTween = true
    local minimizedCornerRadius = UDim.new(0, MINI_SIZE.X.Offset / 2)

    spawn(function()
        while activeTween and tag and tag.Parent and character and character.Parent and head and head.Parent do
            local localPlayerChar = Players.LocalPlayer and Players.LocalPlayer.Character
            if localPlayerChar and localPlayerChar:FindFirstChild("Head") then
                local localHead = localPlayerChar.Head
                if localHead then
                    local distance = (head.Position - localHead.Position).Magnitude
                    if distance > (CONFIG.DISTANCE_THRESHOLD + CONFIG.HYSTERESIS) and not isMinimized then
                        isMinimized = true
                        TweenService:Create(tag, TweenInfo.new(0.3), { Size = MINI_SIZE, StudsOffset = MINI_OFFSET }):Play()
                        TweenService:Create(rankLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                        TweenService:Create(displayNameLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
                        if iconDisplay then
                            local targetIconPos = UDim2.new(0.5, -MINI_ICON_SIZE/2, 0.5, -MINI_ICON_SIZE/2)
                            local targetIconSizeUDim = UDim2.new(0, MINI_ICON_SIZE, 0, MINI_ICON_SIZE)
                            TweenService:Create(iconDisplay, TweenInfo.new(0.3), { Position = targetIconPos, Size = targetIconSizeUDim }):Play()
                            if iconDisplayCorner then -- UICorner des Icons anpassen
                                TweenService:Create(iconDisplayCorner, TweenInfo.new(0.3), { CornerRadius = UDim.new(0, MINI_ICON_SIZE / 2) }):Play()
                            end
                            if iconBackground then
                                local miniBgSize = MINI_ICON_SIZE + MINI_BACKGROUND_OFFSET_FACTOR
                                TweenService:Create(iconBackground, TweenInfo.new(0.3), {
                                    Position = UDim2.new(0.5, -miniBgSize/2, 0.5, -miniBgSize/2),
                                    Size = UDim2.new(0, miniBgSize, 0, miniBgSize)
                                }):Play()
                                -- Der CornerRadius des iconBackground muss nicht angepasst werden, da er bereits zirkulär ist und bleibt
                            end
                        end
                        TweenService:Create(bgCorner, TweenInfo.new(0.3), { CornerRadius = minimizedCornerRadius }):Play()
                        TweenService:Create(borderCorner, TweenInfo.new(0.3), { CornerRadius = minimizedCornerRadius }):Play()
                        if vcCorner then -- UICorner des VideoContainers anpassen
                           TweenService:Create(vcCorner, TweenInfo.new(0.3), { CornerRadius = minimizedCornerRadius }):Play()
                        end
                    elseif distance < (CONFIG.DISTANCE_THRESHOLD - CONFIG.HYSTERESIS) and isMinimized then
                        isMinimized = false
                        TweenService:Create(tag, TweenInfo.new(0.3), { Size = FULL_SIZE, StudsOffset = CONFIG.TAG_OFFSET }):Play()
                        TweenService:Create(rankLabel, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
                        TweenService:Create(displayNameLabel, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
                        if iconDisplay then
                             TweenService:Create(iconDisplay, TweenInfo.new(0.3), {
                                Position = UDim2.new(0, actualIconLeftPadding, 0.5, -actualIconWidth/2),
                                Size = UDim2.new(0, actualIconWidth, 0, actualIconWidth)
                            }):Play()
                            if iconDisplayCorner then -- UICorner des Icons zurücksetzen
                                TweenService:Create(iconDisplayCorner, TweenInfo.new(0.3), { CornerRadius = UDim.new(0, actualIconWidth / 2) }):Play()
                            end
                            if iconBackground then
                                local fullBgSize = actualIconWidth + CONFIG.ICON_BACKGROUND_SIZE_OFFSET
                                TweenService:Create(iconBackground, TweenInfo.new(0.3), {
                                    Position = UDim2.new(0, actualIconLeftPadding - (CONFIG.ICON_BACKGROUND_SIZE_OFFSET / 2), 0.5, -(fullBgSize / 2)),
                                    Size = UDim2.new(0, fullBgSize, 0, fullBgSize)
                                }):Play()
                            end
                        end
                        TweenService:Create(bgCorner, TweenInfo.new(0.3), { CornerRadius = CONFIG.CORNER_RADIUS }):Play()
                        TweenService:Create(borderCorner, TweenInfo.new(0.3), { CornerRadius = CONFIG.CORNER_RADIUS }):Play()
                        if vcCorner then -- UICorner des VideoContainers zurücksetzen
                            TweenService:Create(vcCorner, TweenInfo.new(0.3), { CornerRadius = CONFIG.CORNER_RADIUS }):Play()
                        end
                    end
                end
            else
                activeTween = false
            end
            task.wait(0.15)
        end
    end)

    tag.AncestryChanged:Connect(function(_, parent) if not parent then activeTween = false end end)
    local playerRemovingConn
    playerRemovingConn = Players.PlayerRemoving:Connect(function(removedPlayer)
        if removedPlayer == player then
            if tag and tag.Parent then tag:Destroy() end
            activeTween = false
            if playerRemovingConn and playerRemovingConn.Connected then playerRemovingConn:Disconnect() end
        end
    end)

    if playerGui then
        tag.Parent = playerGui
    else
        playerGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5) -- Attempt to get PlayerGui again
        if playerGui then
            tag.Parent = playerGui
        else
            warn("Konnte Tag nicht an PlayerGui anhängen für Spieler: " .. player.Name)
            tag:Destroy()
            return nil
        end
    end
    return tag
end

local function showSENTINELAdminNotification(player)
    local playerName = player.Name
    local notifMessage = "@" .. playerName .. " uses SENTINEL"
    local success, thumb = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    if not success then thumb = "" end

    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    local oldNotif = playerGui:FindFirstChild("SENTINELAdminNotificationGui")
    if oldNotif then oldNotif:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SENTINELAdminNotificationGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = UDim2.new(0, 280, 0, 70)
    frame.Position = UDim2.new(1, 10, 0.9, -80)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 12)
    uiCorner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 100, 180)
    stroke.Transparency = 0.5
    stroke.Thickness = 1.5
    stroke.Parent = frame

    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Name = "ProfilePic"
    imageLabel.Size = UDim2.new(0, 50, 0, 50)
    imageLabel.Position = UDim2.new(0, 10, 0.5, -25)
    imageLabel.BackgroundTransparency = 1
    imageLabel.Image = thumb
    imageLabel.Parent = frame
    local imgCorner = Instance.new("UICorner")
    imgCorner.CornerRadius = UDim.new(0,8)
    imgCorner.Parent = imageLabel

    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "NotificationText"
    textLabel.Size = UDim2.new(1, -75, 1, -10)
    textLabel.Position = UDim2.new(0, 65, 0.5, -textLabel.TextBounds.Y/2 -5)
    textLabel.BackgroundTransparency = 1
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.new(0.95, 0.95, 0.95)
    textLabel.TextSize = 15
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Text = notifMessage
    textLabel.Parent = frame

    local endPosition = UDim2.new(1, -290, 0.9, -80)
    local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = endPosition})
    tweenIn:Play()

    task.delay(4, function()
        if frame and frame.Parent then
            local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 0.9, -80)})
            tweenOut:Play()
            tweenOut.Completed:Connect(function()
                if screenGui and screenGui.Parent then
                    screenGui:Destroy()
                end
            end)
        end
    end)
end

local localTagChoice = nil
local notificationGuiVisible = false

local function createNotificationUI()
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil, nil, nil end

    if notificationGuiVisible then
        local existingGui = playerGui:FindFirstChild("TagNotification")
        if existingGui then return existingGui, existingGui.Frame:FindFirstChild("YesButton"), existingGui.Frame:FindFirstChild("NoButton") end
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "TagNotification"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 1000

    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, -0.2, 0)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 10)
    notifCorner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 90)
    stroke.Transparency = 0.6
    stroke.Thickness = 1
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "TitleLabel"
    title.Size = UDim2.new(1, -20, 0, 35)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = Color3.new(0.9, 0.9, 0.9)
    title.TextSize = 18
    title.Text = "Rank Tag Visibility"
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = frame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "MessageLabel"
    local titleBottomY = title.Position.Y.Offset + title.Size.Y.Offset
    local buttonsTopY = frame.Size.Y.Offset - 45
    local messageHeight = buttonsTopY - titleBottomY - 10 -- 10 for padding between title and message

    messageLabel.Size = UDim2.new(1, -30, 0, messageHeight)
    messageLabel.Position = UDim2.new(0.5, 0, 0, titleBottomY + 5) -- Position below title
    messageLabel.AnchorPoint = Vector2.new(0.5, 0) -- Anchor at top-center

    messageLabel.BackgroundTransparency = 1
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextColor3 = Color3.new(0.8, 0.8, 0.8)
    messageLabel.TextSize = 14
    messageLabel.TextWrapped = true
    messageLabel.Text = "Do you want to display your rank tag above your character's head?"
    messageLabel.TextXAlignment = Enum.TextXAlignment.Center
    messageLabel.TextYAlignment = Enum.TextYAlignment.Center -- Explicitly center vertically
    messageLabel.Parent = frame


    local function createButton(text, btnName, positionOffset, widthScale, color)
        local button = Instance.new("TextButton")
        button.Name = btnName
        button.Size = UDim2.new(widthScale, -10, 0, 35)
        button.Position = UDim2.new(positionOffset, 5, 1, -45)
        button.BackgroundColor3 = color
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextColor3 = Color3.new(1, 1, 1)
        button.TextSize = 15
        button.Text = text
        button.AutoButtonColor = false
        button.BackgroundTransparency = 0.1
        button.Parent = frame
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 8)
        buttonCorner.Parent = button
        button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.2)}):Play() end)
        button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play() end)
        return button
    end

    local yesButton = createButton("Yes, show it", "YesButton", 0.05, 0.45, Color3.fromRGB(46, 180, 113))
    local noButton = createButton("No, hide it", "NoButton", 0.5, 0.45, Color3.fromRGB(200, 76, 60))

    notificationGuiVisible = true
    gui.Parent = playerGui

    TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, -150, 0.05, 0)}):Play()

    return gui, yesButton, noButton
end


local charAddedConn = {}
local charRemovedConn = {}


local function cleanupPlayerConnections(userId)
    if charAddedConn[userId] then
        if charAddedConn[userId].Connected then
            charAddedConn[userId]:Disconnect()
        end
        charAddedConn[userId] = nil
    end

    if charRemovedConn[userId] then
        if charRemovedConn[userId].Connected then
            charRemovedConn[userId]:Disconnect()
        end
        charRemovedConn[userId] = nil
    end
end

local function manageTagVisibility(player, rankTextKey)
    if not player or not player:IsA("Player") then return end

    cleanupPlayerConnections(player.UserId)

    charAddedConn[player.UserId] = player.CharacterAdded:Connect(function(character)
        task.spawn(function()
            if not character:IsDescendantOf(workspace) then
                character.AncestryChanged:Wait()
            end

            local head = character:WaitForChild("Head", 3)
            if not head then return end

            local currentRankKey = getPlayerRankDataKey(player)
            if currentRankKey then
                 if player == Players.LocalPlayer and localTagChoice == false then
                else
                    local success, err = pcall(attachTagToHead, character, player, currentRankKey)
                    if not success then
                        warn("Tag Creation Error on CharacterAdded:", err, "for player", player.Name, "rank", currentRankKey)
                    end
                end
            end
        end)
    end)

    charRemovedConn[player.UserId] = player.CharacterRemoving:Connect(function(character)
        local head = character and character:FindFirstChild("Head")
        if not head then return end

        if globalLocalPlayerGuiRef then
             for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
                local gui = globalLocalPlayerGuiRef:GetChildren()[i]
                if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == head then
                    gui:Destroy()
                    break
                end
            end
        end
    end)
end

local function attachTagAndConnect(player, rankTextKey)
    if not player or not player:IsA("Player") then return end

    local rankConfig = RankData[rankTextKey]
    if not rankConfig then
        return
    end

    manageTagVisibility(player, rankTextKey)

    if player.Character then
        task.spawn(function()
            if player == Players.LocalPlayer and localTagChoice == false then
            else
                local success, err = pcall(attachTagToHead, player.Character, player, rankTextKey)
                if not success then
                    warn("Tag Creation Error (initial attach):", err, "for player", player.Name, "rank", rankTextKey)
                end
            end
        end)
    end
end

local function cleanupNotificationUI(gui, yesConn, noConn)
    if yesConn and yesConn.Connected then yesConn:Disconnect() end
    if noConn and noConn.Connected then noConn:Disconnect() end
    if gui and gui.Parent then
        local frame = gui:FindFirstChild("Frame")
        if frame then
            local targetPos = UDim2.new(0.5, -frame.AbsoluteSize.X/2, -0.2 - (frame.AbsoluteSize.Y/((Players.LocalPlayer:GetMouse() and Players.LocalPlayer:GetMouse().ViewSizeY) or 1000)), 0)
            if Players.LocalPlayer:GetMouse() and Players.LocalPlayer:GetMouse().ViewSizeY == 0 then targetPos = UDim2.new(0.5, -frame.AbsoluteSize.X/2, -1,0) end
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = targetPos}):Play()
            task.wait(0.3)
        end
        gui:Destroy()
    end
    notificationGuiVisible = false
end

local function handlePlayerChoice(player, rankTextKeyToShowIfNeeded, choice)
    localTagChoice = choice
    if choice then
        local actualRankKey = getPlayerRankDataKey(player)
        if actualRankKey then
            attachTagAndConnect(player, actualRankKey)
        end
    else
        task.spawn(function()
            if player.Character then
                local head = player.Character:FindFirstChild("Head")
                if head and globalLocalPlayerGuiRef then
                    for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
                        local gui = globalLocalPlayerGuiRef:GetChildren()[i]
                        if gui.Name == "RankTag" and gui:IsA("BillboardGui") and gui.Adornee == head then
                            gui:Destroy()
                        end
                    end
                end
            end
        end)

        if charAddedConn[player.UserId] and charAddedConn[player.UserId].Connected then
            charAddedConn[player.UserId]:Disconnect()
            charAddedConn[player.UserId] = nil
        end
    end
end

local function createTag(player, rankTextKey, doPromptLocalPlayerNow)
    if doPromptLocalPlayerNow then
        if notificationGuiVisible then return end

        local gui, yesButton, noButton = createNotificationUI()
        if not gui or not yesButton or not noButton then
            warn("Tag Notification UI creation failed for " .. player.Name)
            return
        end

        local yesConn, noConn
        yesConn = yesButton.MouseButton1Click:Connect(function()
            handlePlayerChoice(player, rankTextKey, true)
            cleanupNotificationUI(gui, yesConn, noConn)
        end)
        noConn = noButton.MouseButton1Click:Connect(function()
            handlePlayerChoice(player, rankTextKey, false)
            cleanupNotificationUI(gui, yesConn, noConn)
        end)
    else
        attachTagAndConnect(player, rankTextKey)
    end
end

local function applyPlayerTag(player)
    if not player or not player:IsDescendantOf(Players) then
        return
    end

    globalLocalPlayerGuiRef = globalLocalPlayerGuiRef or (Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui"))

    -- NEU: Alten Tag vom PlayerGui entfernen, falls vorhanden (bezogen auf diesen Spieler)
    if globalLocalPlayerGuiRef and player.Character and player.Character:FindFirstChild("Head") then
        local head = player.Character.Head
        for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
            local guiInPg = globalLocalPlayerGuiRef:GetChildren()[i]
            if guiInPg:IsA("BillboardGui") and guiInPg.Name == "RankTag" and guiInPg.Adornee == head then
                guiInPg:Destroy()
            end
        end
    end
    -- NEU: Alten Tag direkt vom Kopf entfernen, falls vorhanden
    if player.Character and player.Character:FindFirstChild("Head") then
         local head = player.Character.Head
         for _, child in ipairs(head:GetChildren()) do
            if child.Name == "RankTag" and child:IsA("BillboardGui") then
                child:Destroy()
            end
        end
    end

    -- Bestehende Verbindungen für diesen Spieler aufräumen, bevor neue erstellt werden
    if charAddedConn[player.UserId] and charAddedConn[player.UserId].Connected then
        charAddedConn[player.UserId]:Disconnect()
        charAddedConn[player.UserId] = nil
    end
     if charRemovedConn[player.UserId] and charRemovedConn[player.UserId].Connected then
        charRemovedConn[player.UserId]:Disconnect()
        charRemovedConn[player.UserId] = nil
    end

    local rankDataKeyToApply = getPlayerRankDataKey(player)

    if rankDataKeyToApply then
        if player == Players.LocalPlayer and localTagChoice == false then
            return
        end

        local rankConfig = RankData[rankDataKeyToApply]
        if rankConfig then
            if player == Players.LocalPlayer and rankDataKeyToApply == "Sentinel User" and not activatedSentinelUsers[player.UserId] then
                if RankData["Sentinel User"] then
                    activatedSentinelUsers[player.UserId] = true
                    print("Local player " .. player.Name .. " automatically received and activated 'Sentinel User' tag via script execution.")
                end
            end

            local shouldPrompt = false
            if player == Players.LocalPlayer and localTagChoice == nil then
                shouldPrompt = true -- UNIVERSAL PROMPT for local player if no choice made
            end

            createTag(player, rankDataKeyToApply, shouldPrompt)
        end
    end
end


local chatConnections = {}

local function setupChatListener(player)
    if not player or not player:IsA("Player") then return end
    local userId = player.UserId

    if chatConnections[userId] and chatConnections[userId].Connected then
        return
    end

    local conn = player.Chatted:Connect(function(msg)
        if not player or not player:IsDescendantOf(Players) then
            if chatConnections[userId] and chatConnections[userId].Connected then
                chatConnections[userId]:Disconnect()
            end
            chatConnections[userId] = nil
            return
        end

        if modifyString(msg:lower()) == modifiedMessage:lower() then
            local isSpecificRole = false
            local isOwner = false
            local playerNameLower = string.lower(player.Name)

            if forcedTags[userId] then
                isSpecificRole = true
                if forcedTags[userId] == "SENTINEL OWNER" then isOwner = true end
            else
                for _, roleDef in ipairs(ROLE_DEFINITIONS) do
                    if roleDef.allowedPlayers then
                        for _, allowedPlayerName in ipairs(roleDef.allowedPlayers) do
                            if type(allowedPlayerName) == "string" and string.lower(allowedPlayerName) == playerNameLower then
                                isSpecificRole = true
                                if roleDef.rankDataKey == "SENTINEL OWNER" then
                                    isOwner = true
                                end
                                break
                            end
                        end
                    end
                    if isSpecificRole then break end
                end
            end

            if isOwner then
                showSENTINELAdminNotification(player)
            end

            if player ~= Players.LocalPlayer and not isSpecificRole then
                if not activatedSentinelUsers[userId] then
                    if RankData["Sentinel User"] then
                        print("Player " .. player.Name .. " sent Sentinel Admin message. Activating 'Sentinel User' tag.")
                        activatedSentinelUsers[userId] = true
                        applyPlayerTag(player)
                    else
                        warn("Player " .. player.Name .. " tried to activate 'Sentinel User' tag, but it's not configured in RankData.")
                    end
                end
            elseif player == Players.LocalPlayer and not isSpecificRole then
                 -- Local player already handled by script execution
            end
        end
    end)
    chatConnections[userId] = conn
end


globalLocalPlayerGuiRef = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")

if globalLocalPlayerGuiRef then
    spawn(function()
        while task.wait(2) and globalLocalPlayerGuiRef and globalLocalPlayerGuiRef.Parent do
            local currentPlayers = Players:GetPlayers()
            local validAdorneesInWorkspace = {}
            for _, p_instance in ipairs(currentPlayers) do
                if p_instance.Character and p_instance.Character:FindFirstChild("Head") and p_instance.Character.Parent == workspace then
                    table.insert(validAdorneesInWorkspace, p_instance.Character.Head)
                end
            end

            if globalLocalPlayerGuiRef then
                 for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
                    local gui = globalLocalPlayerGuiRef:GetChildren()[i]
                    if gui:IsA("BillboardGui") and gui.Name == "RankTag" then
                        local adornee = gui.Adornee
                        if not adornee or not adornee:IsDescendantOf(workspace) or not table.find(validAdorneesInWorkspace, adornee) then
                            gui:Destroy()
                        end
                    end
                end
            end

            for _, p_instance in ipairs(currentPlayers) do
                local player = p_instance
                local expectedRankKey = getPlayerRankDataKey(player)
                local currentTagGui = nil
                local currentRankOnTag = nil

                if player.Character and player.Character:FindFirstChild("Head") and player.Character.Parent == workspace then
                    local head = player.Character.Head
                    if globalLocalPlayerGuiRef then
                        for _, guiInPg in ipairs(globalLocalPlayerGuiRef:GetChildren()) do
                            if guiInPg:IsA("BillboardGui") and guiInPg.Name == "RankTag" and guiInPg.Adornee == head then
                                currentTagGui = guiInPg
                                local rankLabel = currentTagGui:FindFirstChild("ContentContainer") and currentTagGui.ContentContainer:FindFirstChild("RankLabel")
                                if rankLabel then currentRankOnTag = rankLabel.Text end
                                break
                            end
                        end
                    end
                end

                if expectedRankKey then
                    local shouldShowTag = true
                    if player == Players.LocalPlayer then
                        shouldShowTag = (localTagChoice ~= false)
                    end

                    if shouldShowTag then
                        local needsCreationOrUpdate = not currentTagGui or
                                          not currentTagGui.Parent or
                                          currentRankOnTag ~= expectedRankKey

                        if needsCreationOrUpdate then
                            task.spawn(applyPlayerTag, player)
                        end
                    else
                        if currentTagGui then
                            currentTagGui:Destroy()
                        end
                    end
                else
                    if currentTagGui then
                        currentTagGui:Destroy()
                    end
                end
            end
        end

        if not (globalLocalPlayerGuiRef and globalLocalPlayerGuiRef.Parent) then
            globalLocalPlayerGuiRef = nil
        end
    end)
else
    warn("LocalPlayerGui nicht verfügbar beim Start - Tag-System könnte eingeschränkt sein.")
    local lp = Players.LocalPlayer
    if not lp then
        local playerAddedConnForLP
        playerAddedConnForLP = Players.PlayerAdded:Connect(function(addedPlayer)
            if addedPlayer == Players.LocalPlayer and not globalLocalPlayerGuiRef then
                 globalLocalPlayerGuiRef = addedPlayer:WaitForChild("PlayerGui")
                 print("LocalPlayerGui nachträglich initialisiert für Tag-System.")
                 if playerAddedConnForLP and playerAddedConnForLP.Connected then playerAddedConnForLP:Disconnect() end
            end
        end)
    end
end

local function initializeTagSystem()
    globalLocalPlayerGuiRef = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not globalLocalPlayerGuiRef then
        if Players.LocalPlayer then
            globalLocalPlayerGuiRef = Players.LocalPlayer:WaitForChild("PlayerGui", 10)
        end
        if not globalLocalPlayerGuiRef then
             warn("InitializeTagSystem: LocalPlayerGui auch nach Wartezeit nicht gefunden. Tags werden nicht initialisiert.")
             return
        end
    end

    -- NEU: Alle alten "RankTag" BillboardGuis aus PlayerGui entfernen (von alter Skriptausführung)
    if globalLocalPlayerGuiRef then
        for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
            local existing = globalLocalPlayerGuiRef:GetChildren()[i]
            if existing:IsA("BillboardGui") and existing.Name == "RankTag" then
                existing:Destroy()
            end
        end
    end
    -- NEU: Auch von Köpfen entfernen
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChild("Head") then
            local head = p.Character.Head
            for i = #head:GetChildren(), 1, -1 do
                local child = head:GetChildren()[i]
                if child.Name == "RankTag" and child:IsA("BillboardGui") then
                    child:Destroy()
                end
            end
        end
    end


    for _, player in ipairs(Players:GetPlayers()) do
        task.spawn(applyPlayerTag, player)
        task.spawn(setupChatListener, player)
    end
end

initializeTagSystem()

local function onPlayerAdded(player)
    if not player or not player:IsDescendantOf(Players) then return end

    task.spawn(function()
        if not player.Character then
            player.CharacterAdded:Wait()
        end
        task.wait(0.5)

        applyPlayerTag(player)
        setupChatListener(player)
    end)
end

Players.PlayerAdded:Connect(onPlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    local userId = player.UserId
    cleanupPlayerConnections(userId)

    if chatConnections[userId] and chatConnections[userId].Connected then
        chatConnections[userId]:Disconnect()
        chatConnections[userId] = nil
    end
    if forcedTags[userId] then
        forcedTags[userId] = nil
    end
    if activatedSentinelUsers[userId] then
        activatedSentinelUsers[userId] = nil
    end


    if globalLocalPlayerGuiRef then
        local playerHead = player.Character and player.Character:FindFirstChild("Head")
        if playerHead then
            for i = #globalLocalPlayerGuiRef:GetChildren(), 1, -1 do
                local gui = globalLocalPlayerGuiRef:GetChildren()[i]
                if gui:IsA("BillboardGui") and gui.Name == "RankTag" and gui.Adornee == playerHead then
                    gui:Destroy()
                    break
                end
            end
        end
    end

    if player == Players.LocalPlayer then
        globalLocalPlayerGuiRef = nil

        local playerGuiInstance = player:FindFirstChild("PlayerGui")
        if playerGuiInstance then
            for _, guiObject in ipairs(playerGuiInstance:GetChildren()) do
                if guiObject.Name == "TagNotification" or
                   guiObject.Name == "SENTINELAdminNotificationGui" then
                    guiObject:Destroy()
                end
            end
        end

        localTagChoice = nil
        notificationGuiVisible = false

        for uid, conn in pairs(charAddedConn) do if conn and conn.Connected then conn:Disconnect() end end
        table.clear(charAddedConn)
        for uid, conn in pairs(charRemovedConn) do if conn and conn.Connected then conn:Disconnect() end end
        table.clear(charRemovedConn)
        for uid, conn in pairs(chatConnections) do if conn and conn.Connected then conn:Disconnect() end end
        table.clear(chatConnections)
    end
end)

return {
    refreshTags = function()
        if not globalLocalPlayerGuiRef then
            globalLocalPlayerGuiRef = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
        end

        if not globalLocalPlayerGuiRef then
            warn("Kann Tags nicht aktualisieren - LocalPlayerGui nicht verfügbar")
            return
        end

        for _, player in ipairs(Players:GetPlayers()) do
            task.spawn(applyPlayerTag, player)
        end
    end,

    forceTag = function(targetPlayerOrName, rankType)
        local playerToForce = nil
        if typeof(targetPlayerOrName) == "Instance" and targetPlayerOrName:IsA("Player") then
            playerToForce = targetPlayerOrName
        elseif type(targetPlayerOrName) == "string" then
            playerToForce = Players:FindFirstChild(targetPlayerOrName)
        end

        if not playerToForce then
            warn("forceTag: Ungültiger Spieler angegeben: " .. tostring(targetPlayerOrName))
            return false
        end

        if rankType == nil then
            forcedTags[playerToForce.UserId] = nil
            applyPlayerTag(playerToForce)
            return true
        end

        if RankData[rankType] then
            local rankConfig = RankData[rankType]
            if not rankConfig.rankName then rankConfig.rankName = rankType end

            if checkAndLoadAssets(rankConfig) then
                forcedTags[playerToForce.UserId] = rankType
                applyPlayerTag(playerToForce)
                return true
            else
                warn("forceTag: Assets für Rang '" .. rankType .. "' konnten nicht geladen werden. Tag wird nicht forciert.")
                return false
            end
        else
            warn("forceTag: Ungültiger rankType: " .. tostring(rankType) .. ". Nicht in RankData gefunden.")
            return false
        end
    end,
    setLocalPlayerTagVisibility = function(visibleBoolean)
        if Players.LocalPlayer then
            localTagChoice = visibleBoolean
            applyPlayerTag(Players.LocalPlayer)

            local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                local gui = playerGui:FindFirstChild("TagNotification")
                if gui then cleanupNotificationUI(gui, nil, nil) end
            end
        else
            warn("setLocalPlayerTagVisibility: LocalPlayer nicht gefunden.")
        end
    end,
    getRole = function(targetPlayerOrName)
        local player = nil
        if typeof(targetPlayerOrName) == "Instance" and targetPlayerOrName:IsA("Player") then
            player = targetPlayerOrName
        elseif type(targetPlayerOrName) == "string" then
            player = Players:FindFirstChild(targetPlayerOrName)
        end
        if player then
            return getPlayerRankDataKey(player)
        end
        return nil
    end
}

--- END OF MODIFIED FILE ---
