-- SERVER SIDE LUA
local QBCore = exports['qb-core']:GetCoreObject()

-- Veri tabloları
local marketItems = {}
local favorites = {}
local history = {}

-- SQL Yükleme
CreateThread(function()
    local result = MySQL.query.await("SELECT * FROM secondhand_market")
    for _, row in pairs(result) do
        table.insert(marketItems, row)
    end
end)

-- Eşya ekleme
RegisterNetEvent("secondhand:server:SellItem", function(item, amount, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player.Functions.RemoveItem(item, amount) then return end

    local label = QBCore.Shared.Items[item] and QBCore.Shared.Items[item].label or item

    local insertId = MySQL.insert.await("INSERT INTO secondhand_market (citizenid, item, label, amount, price) VALUES (?, ?, ?, ?, ?)", {
        Player.PlayerData.citizenid, item, label, amount, price
    })

    table.insert(marketItems, {
        id = insertId,
        citizenid = Player.PlayerData.citizenid,
        item = item,
        label = label,
        amount = amount,
        price = price
    })

    table.insert(history, {
        citizenid = Player.PlayerData.citizenid,
        item = item,
        label = label,
        amount = amount,
        price = price,
        type = "sell",
        time = os.date("%Y-%m-%d %H:%M:%S")
    })
end)

-- Satın alma
RegisterNetEvent("secondhand:server:BuyItem", function(id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    local index
    local selectedItem
    for i, v in ipairs(marketItems) do
        if v.id == id then
            index = i
            selectedItem = v
            break
        end
    end

    if not selectedItem then return end

    if not Player.Functions.RemoveMoney("cash", selectedItem.price) then
        TriggerClientEvent("QBCore:Notify", src, "Yeterli paran yok", "error")
        return
    end

    -- Oyuncuya eşyayı ver
    Player.Functions.AddItem(selectedItem.item, selectedItem.amount)
    table.remove(marketItems, index)
    MySQL.query.await("DELETE FROM secondhand_market WHERE id = ?", { id })

    -- 🟢 SATICIYA PARA YATIR
    local taxRate = Config.EnableMarketTax and Config.TaxRate or 0.0
    local finalAmount = selectedItem.price * (1 - taxRate)

    local seller = QBCore.Functions.GetPlayerByCitizenId(selectedItem.citizenid)
    if seller then
        seller.Functions.AddMoney(Config.PayoutTo, finalAmount, "Secondhand Sale")
    else
        MySQL.query.await("UPDATE players SET "..Config.PayoutTo.." = "..Config.PayoutTo.." + ? WHERE citizenid = ?", {
            finalAmount, selectedItem.citizenid
        })
    end

    -- Geçmişe ekle
    table.insert(history, {
        citizenid = Player.PlayerData.citizenid,
        item = selectedItem.item,
        label = selectedItem.label,
        amount = selectedItem.amount,
        price = selectedItem.price,
        type = "buy",
        time = os.date("%Y-%m-%d %H:%M:%S")
    })
end)


-- Favorilere ekle
RegisterNetEvent("secondhand:server:AddFavorite", function(itemId)
    local src = source
    local cid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    favorites[cid] = favorites[cid] or {}
    favorites[cid][itemId] = true
end)

-- Favorilerden kaldır
RegisterNetEvent("secondhand:server:RemoveFavorite", function(itemId)
    local src = source
    local cid = QBCore.Functions.GetPlayer(src).PlayerData.citizenid
    if favorites[cid] then
        favorites[cid][itemId] = nil
    end
end)

-- Market itemları göster
QBCore.Functions.CreateCallback("secondhand:server:GetMarketItems", function(_, cb)
    cb(marketItems)
end)

-- Favori itemları göster
QBCore.Functions.CreateCallback("secondhand:server:GetFavorites", function(source, cb)
    local cid = QBCore.Functions.GetPlayer(source).PlayerData.citizenid
    local result = {}
    if favorites[cid] then
        for _, item in ipairs(marketItems) do
            if favorites[cid][item.id] then
                item.item_id = item.id
                table.insert(result, item)
            end
        end
    end
    cb(result)
end)

-- Satış geçmişi
QBCore.Functions.CreateCallback("secondhand:server:GetHistory", function(source, cb)
    local cid = QBCore.Functions.GetPlayer(source).PlayerData.citizenid
    local result = {}
    for _, h in ipairs(history) do
        if h.citizenid == cid then
            table.insert(result, h)
        end
    end
    cb(result)
end)

RegisterNetEvent("secondhand:server:RemoveOwnItem", function(id)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local index, selectedItem
    for i, item in ipairs(marketItems) do
        if item.id == id and item.citizenid == Player.PlayerData.citizenid then
            index = i
            selectedItem = item
            break
        end
    end

    if not selectedItem then
        TriggerClientEvent("QBCore:Notify", src, "Bu ürün sana ait değil veya bulunamadı!", "error")
        return
    end

    Player.Functions.AddItem(selectedItem.item, selectedItem.amount)
    table.remove(marketItems, index)
    MySQL.query.await("DELETE FROM secondhand_market WHERE id = ?", { id })

    TriggerClientEvent("QBCore:Notify", src, "Ürün kaldırıldı ve envanterine iade edildi.", "success")
end)

