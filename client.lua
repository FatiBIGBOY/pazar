local QBCore = exports['qb-core']:GetCoreObject()

-- 🧍 NPC SPAWN
CreateThread(function()
    local model = Config.MarketNPC.model
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end

    local npc = CreatePed(0, model, Config.MarketNPC.coords.x, Config.MarketNPC.coords.y, Config.MarketNPC.coords.z - 1.0, Config.MarketNPC.coords.w, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    if Config.MarketNPC.scenario then
        TaskStartScenarioInPlace(npc, Config.MarketNPC.scenario, 0, true)
    end
end)

-- 🎯 qb-target Etkileşimi
CreateThread(function()
    exports['qb-target']:AddTargetModel(Config.MarketNPC.model, {
        options = {
            {
                type = "client",
                event = "secondhand:client:OpenMarket",
                icon = "fas fa-shopping-basket",
                label = "🛒 İkinci El Pazarı"
            }
        },
        distance = 2.0
    })
end)

-- 📦 Ana Menü
RegisterNetEvent("secondhand:client:OpenMarket", function()
    exports['qb-menu']:openMenu({
        {
            header = Config.MarketTitle or "📦 İkinci El Pazarı",
            isMenuHeader = true,
        },
        {
            header = "📄 Eşya Sat",
            txt = "Elindeki eşyayı pazara koy",
            params = { event = "secondhand:client:SellItem" }
        },
        {
            header = "🛍️ Pazarı Görüntüle",
            txt = "Oyuncuların sattığı eşyaları gör",
            params = { event = "secondhand:client:ViewMarket" }
        },
        {
            header = "❤️ Favorilerim",
            txt = "Favoriye aldığın eşyaları gör",
            params = { event = "secondhand:client:ViewFavorites" }
        },
        {
            header = "📊 Satış Geçmişim",
            txt = "Yaptığın alış/satışları gör",
            params = { event = "secondhand:client:ViewHistory" }
        }
    })
end)

-- 💰 Eşya Satma
RegisterNetEvent("secondhand:client:SellItem", function()
    local Player = QBCore.Functions.GetPlayerData()
    local inventory = Player.items
    local menu = {
        { header = "📄 Satılacak Eşyayı Seç", isMenuHeader = true }
    }

    for _, item in pairs(inventory) do
        if item and item.amount > 0 then
            table.insert(menu, {
                header = item.label .. " x" .. item.amount,
                txt = "Fiyat belirle ve sat",
                params = {
                    event = "secondhand:client:ConfirmSell",
                    args = { item = item.name, label = item.label, amount = item.amount }
                }
            })
        end
    end

    if #menu == 1 then
        table.insert(menu, {
            header = "⚠️ Envanterde eşya yok",
            icon = "fas fa-ban",
            params = {}
        })
    end

    table.insert(menu, {
        header = "⬅️ Geri Dön",
        txt = "Ana menüye dön",
        params = { event = "secondhand:client:OpenMarket" }
    })

    exports['qb-menu']:openMenu(menu)
end)

-- 📝 Satış Onayı
RegisterNetEvent("secondhand:client:ConfirmSell", function(data)
    local input = exports['qb-input']:ShowInput({
        header = "💰 Satış Fiyatı",
        submitText = "Sat",
        inputs = {
            { text = "Fiyat ($)", name = "price", type = "number", isRequired = true },
            { text = "Adet (Max: "..data.amount..")", name = "amount", type = "number", isRequired = true }
        }
    })

    if input then
        local amount = tonumber(input.amount)
        local price = tonumber(input.price)
        if amount > 0 and price > 0 then
            TriggerServerEvent("secondhand:server:SellItem", data.item, amount, price)
            Wait(500)
            TriggerEvent("secondhand:client:OpenMarket")
        else
            TriggerEvent('QBCore:Notify', "Geçersiz değerler!", "error")
        end
    end
end)

-- 🛍️ Pazarı Görüntüle
local currentKeyword = ""

RegisterNetEvent("secondhand:client:ViewMarket", function()
    LoadMarketMenu(currentKeyword)
end)

function LoadMarketMenu(keyword)
    QBCore.Functions.TriggerCallback("secondhand:server:GetMarketItems", function(items)
        local menu = {
            { header = "🛍️ Mevcut Eşyalar", isMenuHeader = true },
            { header = "🔍 Filtrele", txt = "Eşya adına göre ara", params = { event = "secondhand:client:FilterMarket" } }
        }

        local Player = QBCore.Functions.GetPlayerData()
        local found = false

        for _, v in pairs(items) do
            if keyword == "" or v.label:lower():find(keyword:lower()) then
                found = true
                local isOwn = (v.citizenid == Player.citizenid)

                table.insert(menu, {
                    header = (isOwn and "❌ " or "🛒 ") .. v.label .. " x" .. v.amount,
                    txt = "Fiyat: $"..v.price .. (isOwn and " | Tıkla: Kaldır" or " | Başkasına ait"),
                    params = isOwn and {
                        event = "secondhand:client:RemoveOwnItem",
                        args = { id = v.id }
                    } or {}
                })
            end
        end

        if not found then
            table.insert(menu, {
                header = "⚠️ Ürün bulunamadı",
                txt = keyword ~= "" and ("'"..keyword.."' için sonuç yok") or "Hiç ürün yok.",
                icon = "fas fa-ban"
            })
        end

        table.insert(menu, {
            header = "⬅️ Geri Dön",
            txt = "Ana menüye dön",
            params = { event = "secondhand:client:OpenMarket" }
        })

        exports['qb-menu']:openMenu(menu)
    end)
end



RegisterNetEvent("secondhand:client:FilterMarket", function()
    local input = exports['qb-input']:ShowInput({
        header = "🔍 Eşya Filtrele",
        submitText = "Ara",
        inputs = {
            { text = "Eşya adı (bandaj, su...)", name = "keyword", type = "text", isRequired = false }
        }
    })

    if input then
        currentKeyword = input.keyword or ""
        LoadMarketMenu(currentKeyword)
    end
end)

-- 📃 Satın Alma
RegisterNetEvent("secondhand:client:BuyItem", function(data)
    TriggerServerEvent("secondhand:server:BuyItem", data.id)
end)

-- ⭐ Favori Ekle
RegisterNetEvent("secondhand:client:AddFavorite", function(data)
    TriggerServerEvent("secondhand:server:AddFavorite", data.id)
end)

-- ❤️ Favorileri Görüntüle
RegisterNetEvent("secondhand:client:ViewFavorites", function()
    QBCore.Functions.TriggerCallback("secondhand:server:GetFavorites", function(items)
        local menu = {
            { header = "❤️ Favori Ürünlerin", isMenuHeader = true }
        }

        if #items == 0 then
            table.insert(menu, {
                header = "⚠️ Favori yok",
                txt = "Hiç favoriye eşya eklememşsin.",
                icon = "fas fa-heart-broken"
            })
        else
            for _, v in pairs(items) do
                table.insert(menu, {
                    header = v.label .. " x" .. v.amount,
                    txt = "Fiyat: $"..v.price,
                    params = {
                        event = "secondhand:client:BuyItem",
                        args = { id = v.item_id }
                    }
                })
                table.insert(menu, {
                    header = "💔 Favoriden Kaldır",
                    txt = "Bu ürünü favorilerinden çıkar",
                    params = {
                        event = "secondhand:client:RemoveFavorite",
                        args = { id = v.item_id }
                    }
                })
            end
        end

        table.insert(menu, {
            header = "⬅️ Geri Dön",
            txt = "Ana menüye dön",
            params = { event = "secondhand:client:OpenMarket" }
        })

        exports['qb-menu']:openMenu(menu)
    end)
end)

-- 🔎 Favoriden Çıkarma
RegisterNetEvent("secondhand:client:RemoveFavorite", function(data)
    TriggerServerEvent("secondhand:server:RemoveFavorite", data.id)
    Wait(500)
    TriggerEvent("secondhand:client:ViewFavorites")
end)

-- 📜 Satış Geçmişi Göster
RegisterNetEvent("secondhand:client:ViewHistory", function()
    QBCore.Functions.TriggerCallback("secondhand:server:GetHistory", function(data)
        local menu = {
            { header = "📜 Satış & Alış Geçmişi", isMenuHeader = true }
        }

        if #data == 0 then
            table.insert(menu, {
                header = "⚠️ Kayıt yok",
                txt = "Hiçbir işlem yapılmamış.",
                icon = "fas fa-ban"
            })
        else
            for _, h in ipairs(data) do
                local prefix = h.type == "sell" and "💸 Satış" or "🛍️ Alış"
                table.insert(menu, {
                    header = prefix .. ": " .. h.label .. " x" .. h.amount,
                    txt = "Fiyat: $" .. h.price .. " | Tarih: " .. h.time
                })
            end
        end

        table.insert(menu, {
            header = "⬅️ Geri Dön",
            txt = "Ana menüye dön",
            params = { event = "secondhand:client:OpenMarket" }
        })

        exports['qb-menu']:openMenu(menu)
    end)
end)

RegisterNetEvent("secondhand:client:RemoveOwnItem", function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = "❓ Ürünü Kaldır",
        submitText = "Kaldır",
        inputs = {
            {
                text = "Kaldırılsın mı? (evet/hayır)",
                name = "confirm",
                type = "text"
            }
        }
    })

    if dialog and dialog.confirm and dialog.confirm:lower() == "evet" then
        TriggerServerEvent("secondhand:server:RemoveOwnItem", data.id)
        Wait(500)
        TriggerEvent("secondhand:client:ViewMarket")
    else
        TriggerEvent("QBCore:Notify", "İşlem iptal edildi.", "error")
    end
end)

-- 📍 Blip Oluştur
CreateThread(function()
    local blip = AddBlipForCoord(Config.MarketNPC.coords.x, Config.MarketNPC.coords.y, Config.MarketNPC.coords.z)
    SetBlipSprite(blip, 605) -- Alışveriş sepeti simgesi
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.7)
    SetBlipColour(blip, 43)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("İkinci El Pazarı")
    EndTextCommandSetBlipName(blip)
end)


