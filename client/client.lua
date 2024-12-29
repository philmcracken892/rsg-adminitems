-- Constants
local MENU_CONFIG = {
    MAX_ITEMS = 100,
    MIN_ITEMS = 1,
    DEFAULT_AMOUNT = 1,
    DIALOG_ICONS = {
        PLAYER_SELECT = '👤',
        AMOUNT_SELECT = '🔢'
    }
}

-- Utility functions
local function formatPlayerLabel(player)
    return string.format('%s (ID: %s)', player.name, player.id)
end

local function createPlayerOptions(players)
    local options = {
        { 
            label = 'Self',
            value = 'self',
            description = 'Spawn items for yourself'
        }
    }
    
    for _, player in ipairs(players) do
        table.insert(options, {
            label = formatPlayerLabel(player),
            value = tostring(player.id),
            description = 'Spawn items for this player'
        })
    end
    
    return options
end

local function filterItems(items, searchQuery)
    if not searchQuery or searchQuery == "" then
        return {}
    end
    
    local filtered = {}
    searchQuery = string.lower(searchQuery)
    
    for _, item in ipairs(items) do
        if string.find(string.lower(item.label), searchQuery) or 
           string.find(string.lower(item.item), searchQuery) or 
           (item.description and string.find(string.lower(item.description), searchQuery)) then
            table.insert(filtered, item)
        end
    end
    
    return filtered
end

local function createItemOptions(items, targetPlayer, searchQuery)
    local filteredItems = filterItems(items, searchQuery)
    local options = {}
    
    if #filteredItems == 0 then
        table.insert(options, {
            title = "No items found",
            description = "Try a different search term",
            disabled = true
        })
        return options
    end
    
    for _, item in ipairs(filteredItems) do
        table.insert(options, {
            title = item.label,
            description = item.description or ('Click to spawn ' .. item.label),
            image = item.image,
            onSelect = function()
                local input = lib.inputDialog(('Spawn %s'):format(item.label), {
                    {
                        type = 'number',
                        label = 'Amount',
                        description = 'How many would you like to spawn?',
                        required = true,
                        min = 1,
                        max = 100,
                        default = 1
                    }
                })
                
                if input then
                    lib.notify({
                        title = 'Spawning Item',
                        description = string.format('Attempting to spawn %dx %s', input[1], item.label),
                        type = 'info',
                        duration = 2000
                    })

                    TriggerServerEvent('rsg_itemspawner:server:spawnItem', {
                        targetPlayer = targetPlayer,
                        item = item.item,
                        label = item.label,
                        amount = input[1],
                        type = item.type
                    })
                end
            end,
            metadata = {
                {label = 'Item Name', value = item.item},
                {label = 'Type', value = item.type},
                {label = 'Weight', value = tostring(item.weight)},
                {label = 'Useable', value = item.useable and 'Yes' or 'No'}
            }
        })
    end
    
    return options
end
-- Main menu function
local function openItemSpawnerMenu(menuData)
    if not menuData or not menuData.items or not menuData.players then
        lib.notify({
            title = 'Error',
            description = 'Failed to load menu data',
            type = 'error'
        })
        return
    end
    
    -- Player selection dialog
    local targetPlayer = lib.inputDialog('Select Target Player', {
        {
            type = 'select',
            label = 'Player',
            description = 'Select a player to receive the items',
            options = createPlayerOptions(menuData.players),
            default = 'self',
            icon = MENU_CONFIG.DIALOG_ICONS.PLAYER_SELECT,
            required = true
        }
    })
    
    if not targetPlayer or not targetPlayer[1] then return end
    
    -- Search dialog
    local searchInput = lib.inputDialog('Search Items', {
        {
            type = 'input',
            label = 'Search',
            description = 'Enter item name, label, or description to search',
            icon = MENU_CONFIG.DIALOG_ICONS.SEARCH,
            required = true
        }
    })
    
    if not searchInput or not searchInput[1] then return end
    
    -- Register and show item selection menu
    lib.registerContext({
        id = 'item_spawner',
        title = 'Item Spawner',
        menu = 'item_spawner_main',
        onBack = function()
            openItemSpawnerMenu(menuData)  -- Reopen menu to start new search
            return false
        end,
        options = createItemOptions(menuData.items, targetPlayer[1], searchInput[1])
    })
    
    lib.showContext('item_spawner')
end

-- Event handler
RegisterNetEvent('rsg_itemspawner:openMenu', function()
    -- Show loading indicator
    lib.notify({
        title = 'Loading',
        description = 'Fetching menu data...',
        type = 'info',
        duration = 2000
    })
    
    -- Fetch menu data with timeout handling
    local success, menuData = pcall(function()
        return lib.callback.await('rsg_itemspawner:getMenuData', 5000)
    end)
    
    if not success or not menuData then
        lib.notify({
            title = 'Error',
            description = 'Failed to load menu data',
            type = 'error'
        })
        return
    end
    
    openItemSpawnerMenu(menuData)
end)