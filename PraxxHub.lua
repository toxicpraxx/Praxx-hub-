-- ═══════════════════════════════════════════════
--  PRAXX HUB (autonome, Delta)
--  Fermeture au clic + écran de choix ML patché
-- ═══════════════════════════════════════════════

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer

local GREEN = Color3.fromRGB(0, 220, 80)
local DARK  = Color3.fromRGB(12, 28, 18)
local KEY_FILE = "PraxxHub/Key.txt"

--------------------------------------------------
-- PATCH : nom + couleurs (rouge/violet -> vert, hex inclus)
--------------------------------------------------
local function patch(src)
    src = src:gsub('"Silence"', '"Praxx Hub"')
    src = src:gsub("'Silence'", "'Praxx Hub'")
    src = src:gsub('%[Silence%]', '[Praxx Hub]')

    -- Couleurs fromRGB rouges/violettes -> vert
    src = src:gsub("Color3%.fromRGB%((%d+),%s*(%d+),%s*(%d+)%)", function(r, g, b)
        r, g, b = tonumber(r), tonumber(g), tonumber(b)
        local isRed    = r > g + 30 and r > b + 30
        local isPurple = b > g + 30 and r > g + 30
        if not (isRed or isPurple) then
            return ("Color3.fromRGB(%d, %d, %d)"):format(r, g, b)
        end
        if (r + g + b) < 150 then
            return "Color3.fromRGB(12, 28, 18)"
        end
        return "Color3.fromRGB(0, 220, 80)"
    end)

    -- Couleurs hex rouges -> vert (ex : #880000 dans Tap Simulator)
    src = src:gsub('Color3%.fromHex%("#?(%x%x)(%x%x)(%x%x)"?%)', function(r, g, b)
        r, g, b = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)
        local isRed    = r > g + 30 and r > b + 30
        local isPurple = b > g + 30 and r > g + 30
        if not (isRed or isPurple) then
            return ('Color3.fromHex("#%02x%02x%02x")'):format(r, g, b)
        end
        if (r + g + b) < 150 then
            return 'Color3.fromHex("#0c1c12")'
        end
        return 'Color3.fromHex("#00dc50")'
    end)

    -- Hook : tout script chargé via le loader ML est aussi patché
    src = src:gsub("loadstring%(game:HttpGet%((%w+URL)%)%)%(",
                   "loadstring(getgenv().PRAXX_PATCH(game:HttpGet(%1)))(")

    return src
end

getgenv().PRAXX_PATCH = patch

--------------------------------------------------
-- SCRIPTS DISPONIBLES
--------------------------------------------------
local SCRIPTS = {
    -- Muscle Legends : on charge SON écran de choix (Main Script / Rep Pets only)
    {name = "Muscle Legends (choix Main/Rep Pets)", url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/main/Scripts/MuscleLegends/Loader.luau"},
    {name = "Tap Simulator",            url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/tapsim.luau"},
    {name = "Hyper Speed Runner",       url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/HyperSpeedRunner.luau"},
    {name = "+1 Speed Keyboard Escape", url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/%2B1SpeedKeyBoardEscape.luau"},
    {name = "MM2",                      url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/mm2.luau"},
    {name = "Survive Zombie Arena",     url = "https://raw.githubusercontent.com/silencedevs/SilenceScripts/refs/heads/main/Scripts/SurviveZombieArena.luau"},
}

local VALID_KEYS = {"sot", "silenceontop", "praxxontop"}

--------------------------------------------------
-- SAUVEGARDE / LECTURE DE LA CLÉ
--------------------------------------------------
local function loadSavedKey()
    if type(isfile) == "function" and type(readfile) == "function"
       and isfile(KEY_FILE) then
        local ok, k = pcall(readfile, KEY_FILE)
        if ok and k then
            k = tostring(k):lower()
            for _, v in ipairs(VALID_KEYS) do
                if k == v then return v end
            end
        end
    end
    return nil
end

local function saveKey(k)
    if type(writefile) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" and not isfolder("PraxxHub") then
            makefolder("PraxxHub")
        end
        writefile(KEY_FILE, k)
    end)
end

--------------------------------------------------
-- ÉCRAN DE SÉLECTION
--------------------------------------------------
local function showSelector()
    local pg = Player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("PraxxHubSelector")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PraxxHubSelector"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 360, 0, 420)
    main.Position = UDim2.new(0.5, -180, 0.5, -210)
    main.BackgroundColor3 = DARK
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = GREEN
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 45)
    title.BackgroundTransparency = 1
    title.Text = "Praxx Hub"
    title.TextColor3 = GREEN
    title.Font = Enum.Font.GothamBold
    title.TextSize = 24

    local scroll = Instance.new("ScrollingFrame", main)
    scroll.Position = UDim2.new(0, 12, 0, 50)
    scroll.Size = UDim2.new(1, -24, 1, -120)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, #SCRIPTS * 42)
    Instance.new("UIListLayout", scroll).Padding = UDim.new(0, 6)

    local selected = {}
    for i, s in ipairs(SCRIPTS) do
        selected[i] = false

        local row = Instance.new("TextButton", scroll)
        row.Size = UDim2.new(1, -4, 0, 36)
        row.BackgroundColor3 = Color3.fromRGB(20, 40, 28)
        row.Text = ""
        row.AutoButtonColor = false
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

        local box = Instance.new("Frame", row)
        box.Size = UDim2.new(0, 22, 0, 22)
        box.Position = UDim2.new(0, 8, 0.5, -11)
        box.BackgroundColor3 = Color3.fromRGB(10, 20, 14)
        box.BorderSizePixel = 0
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

        local check = Instance.new("TextLabel", box)
        check.Size = UDim2.new(1, 0, 1, 0)
        check.BackgroundTransparency = 1
        check.Text = ""
        check.TextColor3 = GREEN
        check.TextSize = 16
        check.Font = Enum.Font.GothamBold

        local label = Instance.new("TextLabel", row)
        label.Position = UDim2.new(0, 40, 0, 0)
        label.Size = UDim2.new(1, -48, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = s.name
        label.TextColor3 = Color3.fromRGB(230, 230, 230)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Font = Enum.Font.Gotham
        label.TextSize = 15

        row.MouseButton1Click:Connect(function()
            selected[i] = not selected[i]
            check.Text = selected[i] and "✔" or ""
            row.BackgroundColor3 = selected[i] and Color3.fromRGB(0, 60, 30) or Color3.fromRGB(20, 40, 28)
        end)
    end

    local loadBtn = Instance.new("TextButton", main)
    loadBtn.Position = UDim2.new(0, 12, 1, -58)
    loadBtn.Size = UDim2.new(1, -24, 0, 42)
    loadBtn.BackgroundColor3 = GREEN
    loadBtn.Text = "Charger les scripts cochés"
    loadBtn.TextColor3 = Color3.fromRGB(5, 15, 10)
    loadBtn.Font = Enum.Font.GothamBold
    loadBtn.TextSize = 16
    Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 8)

    loadBtn.MouseButton1Click:Connect(function()
        local any = false
        for i in ipairs(SCRIPTS) do
            if selected[i] then any = true break end
        end
        if not any then
            loadBtn.Text = "Coche au moins un script !"
            task.wait(1.2)
            loadBtn.Text = "Charger les scripts cochés"
            return
        end

        -- La page se ferme IMMÉDIATEMENT, le chargement continue en fond
        gui:Destroy()

        task.spawn(function()
            for i, s in ipairs(SCRIPTS) do
                if selected[i] then
                    local ok, src = pcall(function() return game:HttpGet(s.url) end)
                    if ok then
                        local ok2, err = pcall(function() loadstring(patch(src))() end)
                        if not ok2 then warn("[Praxx Hub] Erreur : " .. tostring(err)) end
                    else
                        warn("[Praxx Hub] Impossible de charger : " .. s.name)
                    end
                end
            end
        end)
    end)
end

--------------------------------------------------
-- ÉCRAN DE CLÉ
--------------------------------------------------
local function showKeyScreen()
    if loadSavedKey() then showSelector() return end

    local gui = Instance.new("ScreenGui")
    gui.Name = "PraxxHubKey"
    gui.ResetOnSpawn = false
    gui.Parent = Player:WaitForChild("PlayerGui")

    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 320, 0, 200)
    main.Position = UDim2.new(0.5, -160, 0.5, -100)
    main.BackgroundColor3 = DARK
    main.BorderSizePixel = 0
    main.Parent = gui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", main)
    stroke.Color = GREEN
    stroke.Thickness = 2

    local title = Instance.new("TextLabel", main)
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "Praxx Hub"
    title.TextColor3 = GREEN
    title.Font = Enum.Font.GothamBold
    title.TextSize = 26

    local input = Instance.new("TextBox", main)
    input.Position = UDim2.new(0, 25, 0, 62)
    input.Size = UDim2.new(1, -50, 0, 36)
    input.BackgroundColor3 = Color3.fromRGB(10, 20, 14)
    input.Text = ""
    input.PlaceholderText = "Entrer la clé..."
    input.TextColor3 = Color3.fromRGB(230, 230, 230)
    input.Font = Enum.Font.Gotham
    input.TextSize = 15
    Instance.new("UICorner", input).CornerRadius = UDim.new(0, 6)
    local inStroke = Instance.new("UIStroke", input)
    inStroke.Color = Color3.fromRGB(40, 90, 60)

    local status = Instance.new("TextLabel", main)
    status.Position = UDim2.new(0, 20, 0, 105)
    status.Size = UDim2.new(1, -40, 0, 18)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = GREEN
    status.Font = Enum.Font.Gotham
    status.TextSize = 13

    local btn = Instance.new("TextButton", main)
    btn.Position = UDim2.new(0, 25, 1, -46)
    btn.Size = UDim2.new(1, -50, 0, 36)
    btn.BackgroundColor3 = GREEN
    btn.Text = "Valider"
    btn.TextColor3 = Color3.fromRGB(5, 15, 10)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local function try()
        local k = input.Text:lower():gsub("%s+", "")
        local valid = false
        for _, v in ipairs(VALID_KEYS) do
            if k == v then valid = true break end
        end
        if valid then
            saveKey(input.Text)
            status.Text = "✅ Clé valide !"
            task.wait(0.8)
            gui:Destroy()
            showSelector()
        else
            status.Text = "❌ Clé invalide"
            input.Text = ""
        end
    end

    btn.MouseButton1Click:Connect(try)
    input.FocusLost:Connect(function(enter) if enter then try() end end)
end

--------------------------------------------------
-- LANCEMENT
--------------------------------------------------
pcall(showKeyScreen)
