SConfig = {}
local RSGCore = exports['rsg-core']:GetCoreObject()

SConfig.Notify = function(msg, source)
    if source then
        --TriggerClientEvent("chatMessage", source, "ItemSpawner", {255, 0, 0}, msg)
        TriggerClientEvent('rNotify:NotifyLeft', source, msg, "NICE", "generic_textures", "tick", 4000)
    end
end

SConfig.PermissionCheck = function(source)
    return RSGCore.Functions.HasPermission(source, 'admin')
end

local function getPlayerName(Player)
    if Player and Player.PlayerData and Player.PlayerData.charinfo then
        return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    end
    return "Unknown"
end

local function GetNearbyPlayers(source)
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        if tonumber(playerId) ~= tonumber(source) then
            local Player = RSGCore.Functions.GetPlayer(tonumber(playerId))
            local charName = getPlayerName(Player)
            table.insert(players, {
                id = tonumber(playerId),
                name = charName
            })
        end
    end
    return players
end


SConfig.AddItem = function(source, item, amount, type)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        
        return false
    end

    if not item or not amount then
        
        return false
    end

    local success = Player.Functions.AddItem(item, amount)
    if success then
        TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items[item], 'add')
        return true
    end

    return false
end


SConfig.GetItems = function()
    local items = {}
    for itemName, itemData in pairs(RSGCore.Shared.Items) do
        local itemInfo = {
            type = itemData.type or "item",
            item = itemData.name,
            label = itemData.label,
            description = itemData.description or "",
            image = itemData.image,
            weight = itemData.weight or 0,
            useable = itemData.useable or false,
            unique = itemData.unique or false,
            shouldClose = itemData.shouldClose or false
        }
        table.insert(items, itemInfo)
    end
    return items
end

-- server/server.lua
local Items = SConfig.GetItems()



-- Discord webhook function
local function SendToDiscord(name, message)
    local connect = {
        {
            ["color"] = 15158332,
            ["title"] = "**".. name .."**",
            ["description"] = message,
            ["footer"] = {
                ["text"] = "Date : " .. os.date("%Y-%m-%d %X"),
            },
        }
    }
    PerformHttpRequest(
        Config.WebhookURL,
        function(err, text, headers) end,
        'POST',
        json.encode({
            username = "Item Spawner",
            embeds = connect,
            avatar_url = "https://media.discordapp.net/attachments/1163182151391527053/1317888980876005417/image-removebg-preview_4.png"
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

lib.callback.register('rsg_itemspawner:getMenuData', function(source)
    if not SConfig.PermissionCheck(source) then
        return false
    end
    
    return {
        items = SConfig.GetItems(),
        players = GetNearbyPlayers(source)
    }
end)

RegisterNetEvent('rsg_itemspawner:server:spawnItem', function(data)
    local source = source
    
    if not SConfig.PermissionCheck(source) then
        return SConfig.Notify("You don't have permission to use this command!", source)
    end

    local targetSource = data.targetPlayer == "self" and source or tonumber(data.targetPlayer)
    local targetPlayer = RSGCore.Functions.GetPlayer(targetSource)
    local adminPlayer = RSGCore.Functions.GetPlayer(source)
    
    local targetName = getPlayerName(targetPlayer)
    local adminName = getPlayerName(adminPlayer)
    
    if not targetName then
        return SConfig.Notify("Player not found!", source)
    end

    local logs = {
        message = string.format(
            "## For Character: %s (id %s)\n## By Admin: %s (id %s)",
            targetName,
            targetSource,
            adminName,
            source
        ),
        title = "Item Spawner"
    }

    if SConfig.AddItem(targetSource, data.item, data.amount, data.type) then
        SConfig.Notify(string.format("Received %dx %s", data.amount, data.label), targetSource)
        SConfig.Notify("Item spawned!", source)
        
        local itemsMessageBox = string.format(
            "## Spawned Items\n```\n%s x%d\n```\n",
            data.label,
            data.amount
        )
        logs.message = logs.message .. "\n" .. itemsMessageBox
        
        SendToDiscord(logs.title, logs.message)
    else
        SConfig.Notify("Failed to spawn item!", source)
    end
end)

-- Command to open the menu
RegisterCommand('itemspawner', function(source, args, raw)
    if not SConfig.PermissionCheck(source) then
        return SConfig.Notify("You don't have permission to use this command!", source)
    end
    
    TriggerClientEvent('rsg_itemspawner:openMenu', source)
end, false)