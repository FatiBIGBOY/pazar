Config = {}

-- 💵 Pazara konulan eşyalardan komisyon alınsın mı?
Config.EnableMarketTax = true
Config.TaxRate = 0.05 -- %5 vergi (fiyat * 0.05)


Config.EnableWebhook = true
Config.Webhook = "https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN"


-- 🕒 Pazardaki eşyaların süresi var mı?
Config.ExpireItems = true
Config.ExpireHours = 24 -- saat sonra otomatik silinsin

-- 🧾 Kara liste (satılamaz itemler)
Config.BlacklistedItems = {
    "weapon_pistol",
    "weapon_knife",
    "weed_bag",
    "c4_explosive",
    "lockpick"
}

-- 📍 NPC Ayarları
Config.MarketNPC = {
    model = "cs_bankman",
    coords = vector4(159.59, -994.6, 29.36, 165.91),
    scenario = "WORLD_HUMAN_CLIPBOARD"
}

-- 💬 Bildirim tipi (qb-core notify / okokNotify / mythic_notify)
Config.NotifyType = "qb" -- Seçenekler: qb / okok / mythic


-- 🏦 Satıcıya para yatırma şekli
Config.PayoutTo = "bank" -- cash, bank

-- 🏷️ Menü başlığı
Config.MarketTitle = "İkinci El Pazarı"
