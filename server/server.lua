-- Configuration and initialization
local Items = SConfig.GetItems()
local WEBHOOK_URL = WEBHOOK_URL -- Should be defined in config

-- Utility functions
local Utilities = {
    -- Get nearby players excluding the source player
    getNearbyPlayers = function(source)
        local players = {}
        local sourceId = tonumber(source)
        
        for _, player in ipairs(GetPlayers()) do
            local playerId = tonumber(player)
            if playerId ~= sourceId then
                players[#players + 1] = {
                    id = playerId,
                    name = GetPlayerName(player)
                }
            end
        end
        return players
    end,

    -- Enhanced Discord webhook with error handling
    sendToDiscord = function(name, message)
        if not WEBHOOK_URL then
            
            return
        end

        local payload = {
            username = "Item Spawner",
            embeds = {
                {
                    color = 15158332,
                    title = "**" .. name .. "**",
                    description = message,
                    footer = {
                        text = "Date: " .. os.date("%Y-%m-%d %X")
                    }
                }
            },
            avatar_url = "https://media.discordapp.net/attachments/1163182151391527053/1317888980876005417/image-removebg-preview_4.png"
        }

        PerformHttpRequest(
            WEBHOOK_URL,
            function(err, text, headers)
                if err ~= 200 then
                    
                end
            end,
            'POST',
            json.encode(payload),
            { ['Content-Type'] = 'application/json' }
        )
    end,

    -- Format log message
    formatLogMessage = function(targetName, targetSource, adminName, adminSource, itemLabel, amount)
        local baseMessage = string.format(
            "## For Player: %s (id %s)\n## By Admin: %s (id %s)",
            targetName,
            targetSource,
            adminName,
            adminSource
        )

        local itemsMessage = string.format(
            "\n## Spawned Items\n```\n%s x%d\n```",
            itemLabel,
            amount
        )

        return baseMessage .. itemsMessage
    end
}

-- Callbacks and Events
lib.callback.register('rsg_itemspawner:getMenuData', function(source)
    if not SConfig.PermissionCheck(source) then
        return false
    end
    
    return {
        items = Items,
        players = Utilities.getNearbyPlayers(source)
    }
end)



-- Commands
RegisterCommand('itemspawner', function(source, args, raw)
    if not SConfig.PermissionCheck(source) then
        return SConfig.Notify("You don't have permission to use this command!", source)
    end
    
    TriggerClientEvent('rsg_itemspawner:openMenu', source)
end, false)