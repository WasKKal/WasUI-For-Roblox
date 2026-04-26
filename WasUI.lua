
local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")

if _G.WasUIModule then
    warn("WasUI已加载 请勿重复加载")
    return _G.WasUIModule
end

local function copyToClipboard(text)
    if type(setclipboard) == "function" then
        setclipboard(text)
        return true
    elseif pcall(function() game:GetService("Selection"):SetTextAsync(text) end) then
        return true
    end
    return false
end

WasUI.DefaultDisplayOrder = 10
WasUI.DialogTitle = "你要关闭WasUI吗?"
WasUI.Version = "1.1.0"
WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}
WasUI.SettingsPanel = nil
WasUI.GroupButtonText = "加入WasUI主群"
WasUI.GroupCopyContent = "786284990"

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

WasUI.DefaultTheme = "Dark"
WasUI.DefaultRainbowMode = "流动"
WasUI.CurrentThemeName = WasUI.DefaultTheme
WasUI.CurrentLanguage = "中文"
WasUI.LanguageTable = nil

function WasUI:LoadLanguageTable(tbl)
    self.LanguageTable = tbl
end

function WasUI:Translate(text)
    if self.CurrentLanguage == "中文" or not self.LanguageTable then
        return text
    end
    return self.LanguageTable[text] or text
end

function WasUI:SetLocalizedText(guiObject, chineseText, propertyName)
    propertyName = propertyName or "Text"
    local translated = self:Translate(chineseText)
    guiObject[propertyName] = translated
    guiObject:SetAttribute("OriginalText", chineseText)
    guiObject:SetAttribute("LocalizedProperty", propertyName)
end

function WasUI:SetLanguage(lang)
    if lang ~= "中文" and lang ~= "English" then return false end
    self.CurrentLanguage = lang
    self:RefreshAllTexts()
    return true
end

function WasUI:SetDefaultLanguage(lang)
    if lang ~= "中文" and lang ~= "English" then return false end
    self.CurrentLanguage = lang
    return true
end

function WasUI:RefreshAllTexts()
    for _, obj in ipairs(WasUI.Objects) do
        local instance = obj.Object
        if instance and instance:IsA("GuiObject") then
            local original = instance:GetAttribute("OriginalText")
            if original then
                local prop = instance:GetAttribute("LocalizedProperty") or "Text"
                local translated = self:Translate(original)
                if instance[prop] ~= nil then
                    instance[prop] = translated
                end
            end
        end
    end
    for _, shortcut in pairs(WasUI.ShortcutButtons) do
        local btn = shortcut.button
        if btn then
            local textLabel = btn:FindFirstChild("Text")
            if textLabel then
                local original = textLabel:GetAttribute("OriginalText")
                if original then
                    textLabel.Text = self:Translate(original)
                end
            end
        end
    end
    if WasUI.SettingsPanel then
        local content = WasUI.SettingsPanel:FindFirstChild("Content")
        if content then
            for _, child in ipairs(content:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local original = child:GetAttribute("OriginalText")
                    if original then
                        child.Text = self:Translate(original)
                    end
                elseif child.Name == "SnowToggleContainer" or child.Name == "LanguageToggleContainer" then
                    local title = child:FindFirstChild("Title")
                    if title then
                        local original = title:GetAttribute("OriginalText")
                        if original then
                            title.Text = self:Translate(original)
                        end
                    end
                end
            end
        end
        local titleBar = WasUI.SettingsPanel:FindFirstChild("TitleBar")
        if titleBar then
            local title = titleBar:FindFirstChild("Title")
            if title then
                local original = title:GetAttribute("OriginalText")
                if original then
                    title.Text = self:Translate(original)
                end
            end
        end
        for _, child in ipairs(WasUI.SettingsPanel:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local original = child:GetAttribute("OriginalText")
                if original then
                    child.Text = self:Translate(original)
                end
            end
        end
    end
    for _, notif in pairs(WasUI.ActiveNotifications) do
        local frame = notif.Frame
        if frame then
            local title = frame:FindFirstChild("Title")
            local content = frame:FindFirstChild("Content")
            if title then
                local original = title:GetAttribute("OriginalText")
                if original then
                    title.Text = self:Translate(original)
                end
            end
            if content then
                local original = content:GetAttribute("OriginalText")
                if original then
                    content.Text = self:Translate(original)
                end
            end
        end
    end
    for _, panelObj in ipairs(WasUI.Objects) do
        if panelObj.Type == "Panel" and panelObj.Object then
            local panelInstance = panelObj.Object
            local titleBar = panelInstance:FindFirstChild("TitleBar")
            if titleBar then
                local titleLabel = titleBar:FindFirstChild("Title")
                if not titleLabel then
                    local titleContainer = titleBar:FindFirstChild("TitleContainer")
                    if titleContainer then
                        titleLabel = titleContainer:FindFirstChild("Title")
                    end
                end
                if titleLabel then
                    local original = titleLabel:GetAttribute("OriginalText")
                    if original then
                        titleLabel.Text = self:Translate(original)
                    end
                end
            end
            local announcementBar = panelInstance:FindFirstChild("AnnouncementBar")
            if announcementBar then
                local welcomeLabel = announcementBar:FindFirstChild("WelcomeLabel")
                if welcomeLabel then
                    local original = welcomeLabel:GetAttribute("OriginalText")
                    if original then
                        welcomeLabel.Text = self:Translate(original)
                    end
                end
                local settingsHint = announcementBar:FindFirstChild("SettingsHint")
                if settingsHint then
                    local original = settingsHint:GetAttribute("OriginalText")
                    if original then
                        settingsHint.Text = self:Translate(original)
                    end
                end
            end
            local tabBar = panelInstance:FindFirstChild("TabBar")
            if tabBar then
                local tabContainer = tabBar:FindFirstChild("TabContainer")
                if tabContainer then
                    for _, tabBtn in ipairs(tabContainer:GetChildren()) do
                        if tabBtn:IsA("TextButton") then
                            local original = tabBtn:GetAttribute("OriginalText")
                            if original then
                                tabBtn.Text = self:Translate(original)
                            end
                        end
                    end
                end
            end
        end
    end
end

function WasUI:RefreshSettingsPanelTexts()
end

function WasUI:SetDefaultTheme(themeName)
    if self.Themes[themeName] then
        self.DefaultTheme = themeName
        self.CurrentThemeName = themeName
        self.CurrentTheme = self.Themes[themeName]
        return true
    end
    return false
end

function WasUI:SetDefaultRainbowMode(mode)
    if mode == "整体" or mode == "流动" then
        self.DefaultRainbowMode = mode
        return true
    end
    return false
end

WasUI.Themes = {
    Dark = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(25, 25, 30),
        Background = Color3.fromRGB(28, 28, 34),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(153, 51, 255),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123),
        Section = Color3.fromRGB(45, 45, 50),
        Input = Color3.fromRGB(45, 45, 50),
        TabBorder = Color3.fromRGB(60, 60, 65),
        TabButton = Color3.fromRGB(0, 0, 0),
        SnowColor = Color3.fromRGB(255, 255, 255)
    },
    Light = {
        Primary = Color3.fromRGB(240, 240, 245),
        Secondary = Color3.fromRGB(245, 245, 250),
        Background = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(0, 0, 0),
        Accent = Color3.fromRGB(52, 86, 139),
        Success = Color3.fromRGB(52, 168, 83),
        Warning = Color3.fromRGB(251, 188, 5),
        Error = Color3.fromRGB(234, 67, 53),
        Section = Color3.fromRGB(240, 240, 245),
        Input = Color3.fromRGB(240, 240, 245),
        TabBorder = Color3.fromRGB(200, 200, 205),
        TabButton = Color3.fromRGB(248, 248, 250),
        SnowColor = Color3.fromRGB(0, 0, 0)
    },
    Blue = {
        Primary = Color3.fromRGB(30, 42, 56),
        Secondary = Color3.fromRGB(44, 62, 80),
        Background = Color3.fromRGB(52, 73, 94),
        Text = Color3.fromRGB(236, 240, 241),
        Accent = Color3.fromRGB(230, 126, 34),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Section = Color3.fromRGB(61, 86, 110),
        Input = Color3.fromRGB(44, 62, 80),
        TabBorder = Color3.fromRGB(93, 109, 126),
        TabButton = Color3.fromRGB(40, 55, 71),
        SnowColor = Color3.fromRGB(255, 255, 255)
    }
}
WasUI.CurrentTheme = WasUI.Themes[WasUI.DefaultTheme]
WasUI.Objects = {}
WasUI.ActiveRainbowTexts = {}
WasUI.RainbowOrder = {}
WasUI.ShortcutGui = nil
WasUI.ShortcutButtons = {}
WasUI.KeyBindings = {}
WasUI.AwaitingKeyBind = nil
WasUI.ConfigManager = nil
WasUI.ConfigFolderCreated = false
WasUI.ConfigFolderName = nil
WasUI.ActiveDialogs = {}
WasUI.ExternalPopupCalled = false

local function RecordOriginalTransparency(instance)
    if instance and instance:IsA("GuiObject") then
        instance:SetAttribute("OriginalTransparency", instance.BackgroundTransparency)
    end
end

local function ensureConfigFolderExists()
    if not WasUI.ConfigFolderCreated then
        WasUI:Notify({
            Title = "配置错误",
            Content = "当前脚本作者未正确配置 Folder 状态，请先调用 WasUI:CreateFolder('文件夹名')",
            Duration = 4,
            BackgroundColor = WasUI.CurrentTheme.Error,
            BorderColor = WasUI.CurrentTheme.Error
        })
        return false
    end
    return true
end

function WasUI:CreateFolder(folderName)
    if not folderName or folderName == "" then
        error("CreateFolder: folderName cannot be empty")
    end
    local path = "WasUI_Configs/" .. folderName
    if not isfolder(path) then
        makefolder(path)
    end
    WasUI.ConfigFolderCreated = true
    WasUI.ConfigFolderName = folderName
    WasUI.ConfigManager = {}
    
    local function getFilePath(configName)
        return path .. "/" .. configName .. ".json"
    end
    
    function WasUI.ConfigManager:GetConfig(configName)
        if not ensureConfigFolderExists() then return nil end
        local filePath = getFilePath(configName)
        local config = {
            Name = configName,
            Path = filePath,
            Data = {},
            Bindings = {},
        }
        
        function config:Save()
            if not ensureConfigFolderExists() then return false end
            local dataToSave = {}
            for key, value in pairs(self.Data) do
                dataToSave[key] = value
            end
            local json = HttpService:JSONEncode(dataToSave)
            writefile(self.Path, json)
            return true
        end
        
        function config:Load()
            if not ensureConfigFolderExists() then return false end
            if not isfile(self.Path) then return false end
            local success, data = pcall(function()
                return HttpService:JSONDecode(readfile(self.Path))
            end)
            if success and type(data) == "table" then
                self.Data = data
                for key, value in pairs(self.Data) do
                    local binding = self.Bindings[key]
                    if binding and binding.control and binding.update then
                        binding.update(value)
                    end
                end
                return true
            end
            return false
        end
        
        function config:Delete()
            if not ensureConfigFolderExists() then return false end
            if isfile(self.Path) then
                delfile(self.Path)
            end
            self.Data = {}
            self.Bindings = {}
            return true
        end
        
        function config:Set(key, value)
            self.Data[key] = value
        end
        
        function config:Get(key, defaultValue)
            local val = self.Data[key]
            if val == nil then return defaultValue end
            return val
        end
        
        function config:Bind(key, control, updateFunc)
            self.Bindings[key] = { control = control, update = updateFunc }
            local savedValue = self.Data[key]
            if savedValue ~= nil then
                updateFunc(savedValue)
            end
        end
        
        if isfile(filePath) then
            config:Load()
        end
        
        return config
    end
    
    function WasUI.ConfigManager:AllConfigs()
        if not ensureConfigFolderExists() then return {} end
        local files = {}
        if listfiles then
            for _, file in ipairs(listfiles(path)) do
                local name = file:match("([^/]+)%.json$")
                if name then
                    table.insert(files, name)
                end
            end
        end
        return files
    end
    
    function WasUI.ConfigManager:DeleteConfig(configName)
        if not ensureConfigFolderExists() then return false end
        local filePath = getFilePath(configName)
        if isfile(filePath) then
            delfile(filePath)
        end
        return true
    end
    
    function WasUI.ConfigManager:GetConfigNames()
        if not ensureConfigFolderExists() then return {} end
        return self:AllConfigs()
    end
    
    function WasUI.ConfigManager:LoadConfigByName(configName)
        local config = self:GetConfig(configName)
        if config then
            config:Load()
            return true
        end
        return false
    end
    
    function WasUI.ConfigManager:SaveConfigByName(configName, data)
        local config = self:GetConfig(configName)
        for k, v in pairs(data) do
            config:Set(k, v)
        end
        config:Save()
    end
    
    function WasUI.ConfigManager:DeleteConfigByName(configName)
        self:DeleteConfig(configName)
    end
    
    WasUI:Notify({Title = "配置系统", Content = "已创建配置文件夹: " .. folderName, Duration = 2})
    return WasUI.ConfigManager
end

local function EnsureShortcutGui()
    if not WasUI.ShortcutGui or not WasUI.ShortcutGui.Parent then
        WasUI.ShortcutGui = Instance.new("ScreenGui")
        WasUI.ShortcutGui.Name = "WasUI_Shortcuts"
        WasUI.ShortcutGui.ResetOnSpawn = false
        WasUI.ShortcutGui.DisplayOrder = 500
        WasUI.ShortcutGui.Parent = game:GetService("CoreGui")
    end
end
EnsureShortcutGui()

local function EnsureNotificationGui()
    if not WasUI.NotificationGui or not WasUI.NotificationGui.Parent then
        WasUI.NotificationGui = Instance.new("ScreenGui")
        WasUI.NotificationGui.Name = "WasUI_Notifications"
        WasUI.NotificationGui.ResetOnSpawn = false
        WasUI.NotificationGui.DisplayOrder = 999
        WasUI.NotificationGui.Parent = game:GetService("CoreGui")
    end
end

local function EnsureDropdownGui()
    if not WasUI.DropdownGui or not WasUI.DropdownGui.Parent then
        WasUI.DropdownGui = Instance.new("ScreenGui")
        WasUI.DropdownGui.Name = "WasUI_Dropdowns"
        WasUI.DropdownGui.ResetOnSpawn = false
        WasUI.DropdownGui.DisplayOrder = 1000
        WasUI.DropdownGui.Parent = game:GetService("CoreGui")
    end
end

EnsureNotificationGui()
EnsureDropdownGui()

WasUI.LucideManager = {
    Module = nil,
    Loaded = false,
}

function WasUI:LoadLucide()
    if self.LucideManager.Loaded then
        return self.LucideManager.Module
    end
    local success, module = pcall(function()
        local url = "https://raw.githubusercontent.com/deividcomsono/lucide-roblox-direct/refs/heads/main/source.lua"
        return loadstring(game:HttpGet(url))()
    end)
    if success and module then
        self.LucideManager.Module = module
        self.LucideManager.Loaded = true
        return module
    end
    return nil
end

function WasUI:GetIcon(iconName)
    local lucide = self:LoadLucide()
    if lucide then
        local success, icon = pcall(lucide.GetAsset, iconName)
        if success and icon then
            return icon
        end
    end
    return nil
end

function WasUI:CreateIcon(iconName, size, color, ignoreTheme)
    local icon = self:GetIcon(iconName)
    if not icon then
        return nil
    end
    local imageLabel = Instance.new("ImageLabel")
    imageLabel.Image = icon.Url
    imageLabel.Size = size or UDim2.new(0, 20, 0, 20)
    imageLabel.BackgroundTransparency = 1
    imageLabel.ImageColor3 = color or WasUI.CurrentTheme.Text
    imageLabel.ScaleType = Enum.ScaleType.Fit
    if icon.ImageRectOffset then
        imageLabel.ImageRectOffset = icon.ImageRectOffset
        imageLabel.ImageRectSize = icon.ImageRectSize
    end
    if ignoreTheme then
        imageLabel:SetAttribute("IgnoreThemeChange", true)
    end
    return imageLabel
end

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

local function Tween(instance, properties, duration, easingStyle, easingDirection)
    if not instance or not instance:IsDescendantOf(game) then
        return nil
    end
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function SpringTween(instance, properties, duration)
    if not instance or not instance:IsDescendantOf(game) then
        return nil
    end
    local tweenInfo = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function RefreshRainbowLayout()
    local startY = 10
    local spacing = 5
    for i, featureName in ipairs(WasUI.RainbowOrder) do
        local data = WasUI.ActiveRainbowTexts[featureName]
        if data and data.Label then
            local label = data.Label
            local height = label.Size.Y.Offset
            label.Position = UDim2.new(1, -190, 0, startY)
            startY = startY + height + spacing
        end
    end
end

local function CreateRainbowTextForFeature(featureName)
    featureName = type(featureName) == "string" and featureName or tostring(featureName)
    if WasUI.ActiveRainbowTexts[featureName] then return end
    local screenGui = CreateInstance("ScreenGui", {
        Name = "RainbowText_" .. featureName,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = game:GetService("CoreGui")
    })
    local textLabel = CreateInstance("TextLabel", {
        Name = "Text",
        Size = UDim2.new(0, 180, 0, 0),
        Position = UDim2.new(1, -190, 0, 0),
        BackgroundTransparency = 1,
        Text = featureName,
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextWrapped = true,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        Parent = screenGui
    })
    local bounds = textLabel.TextBounds
    local height = bounds.Y + 4
    textLabel.Size = UDim2.new(0, 180, 0, height)
    WasUI.ActiveRainbowTexts[featureName] = {
        ScreenGui = screenGui,
        Connection = nil,
        Label = textLabel
    }
    table.insert(WasUI.RainbowOrder, featureName)
    RefreshRainbowLayout()
end

local function DestroyRainbowTextForFeature(featureName)
    featureName = type(featureName) == "string" and featureName or tostring(featureName)
    local data = WasUI.ActiveRainbowTexts[featureName]
    if data then
        if data.ScreenGui then data.ScreenGui:Destroy() end
        WasUI.ActiveRainbowTexts[featureName] = nil
        for i, name in ipairs(WasUI.RainbowOrder) do
            if name == featureName then
                table.remove(WasUI.RainbowOrder, i)
                break
            end
        end
        RefreshRainbowLayout()
    end
end

local rainbowTime = 0
local rainbowSpeed = 2
local rainbowConnection = RunService.Heartbeat:Connect(function(deltaTime)
    rainbowTime = rainbowTime + deltaTime * rainbowSpeed
    local r = (math.sin(rainbowTime) + 1) / 2
    local g = (math.sin(rainbowTime + math.pi/3) + 1) / 2
    local b = (math.sin(rainbowTime + 2*math.pi/3) + 1) / 2
    local color = Color3.new(r, g, b)
    for _, data in pairs(WasUI.ActiveRainbowTexts) do
        if data.Label then
            data.Label.TextColor3 = color
        end
    end
end)

local function GetShortcutKey(controlType, controlId, rainbowName)
    local base = ""
    local safeRainbowName = (type(rainbowName) == "string" and rainbowName ~= "") and rainbowName or nil
    if safeRainbowName then
        base = "shortcut_" .. safeRainbowName
    else
        base = "shortcut_" .. controlType .. "_" .. tostring(controlId)
    end
    base = base:gsub("[^%w_]", "_")
    return base
end

local function SaveShortcutPosition(key, position)
    local folder = ReplicatedStorage:FindFirstChild(WasUI_Folder.Name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = WasUI_Folder.Name
        folder.Parent = ReplicatedStorage
    end
    local posStr = string.format("%.3f,%.3f,%.3f,%.3f", position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset)
    folder:SetAttribute(key .. "_Pos", posStr)
end

local function LoadShortcutPosition(key)
    local folder = ReplicatedStorage:FindFirstChild(WasUI_Folder.Name)
    if folder then
        local posStr = folder:GetAttribute(key .. "_Pos")
        if posStr and type(posStr) == "string" then
            local parts = {}
            for part in string.gmatch(posStr, "[^,]+") do
                table.insert(parts, tonumber(part))
            end
            if #parts == 4 then
                return UDim2.new(parts[1], parts[2], parts[3], parts[4])
            end
        end
    end
    return nil
end

function WasUI:ClearAllShortcuts()
    for key, shortcut in pairs(WasUI.ShortcutButtons) do
        if shortcut and shortcut.destroy then
            shortcut:destroy()
        elseif shortcut and shortcut.button then
            shortcut.button:Destroy()
        end
    end
    WasUI.ShortcutButtons = {}
end

local function SaveKeyBinding(key, keyCode)
    local folder = ReplicatedStorage:FindFirstChild(WasUI_Folder.Name)
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = WasUI_Folder.Name
        folder.Parent = ReplicatedStorage
    end
    folder:SetAttribute(key .. "_Key", tostring(keyCode))
end

local function LoadKeyBinding(key)
    local folder = ReplicatedStorage:FindFirstChild(WasUI_Folder.Name)
    if folder then
        local keyStr = folder:GetAttribute(key .. "_Key")
        if keyStr then
            for _, kc in pairs(Enum.KeyCode:GetEnumItems()) do
                if tostring(kc) == keyStr then return kc end
            end
        end
    end
    return nil
end

local function GetKeyName(keyCode)
    return string.gsub(tostring(keyCode), "Enum.KeyCode.", "")
end

local function AddKeyBindLongPress(controlInstance, controlKey, controlType, callback, displayName)
    local longPressTime = 0.5
    local timer = nil
    local pressed = false
    local startPos = nil

    local function startPress(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = true
            startPos = input.Position
            timer = task.delay(longPressTime, function()
                if pressed then
                    if WasUI.AwaitingKeyBind then
                        WasUI:Notify({Title = "快捷键", Content = "已有正在绑定的快捷键，请稍后", Duration = 1.5})
                        return
                    end
                    WasUI.AwaitingKeyBind = {
                        controlKey = controlKey,
                        controlType = controlType,
                        callback = callback,
                        displayName = displayName
                    }
                    WasUI:Notify({Title = "设置快捷键", Content = "请按下任意键...", Duration = 3, BackgroundColor = WasUI.CurrentTheme.Section, BorderColor = WasUI.CurrentTheme.Accent})
                end
            end)
        end
    end

    local function endPress()
        if timer then task.cancel(timer); timer = nil end
        pressed = false
        startPos = nil
    end

    local function checkMove(input)
        if pressed and input.UserInputType == Enum.UserInputType.MouseMovement then
            if startPos and (input.Position - startPos).Magnitude > 10 then
                endPress()
            end
        end
    end

    controlInstance.InputBegan:Connect(startPress)
    controlInstance.InputEnded:Connect(endPress)
    UserInputService.InputChanged:Connect(checkMove)
end

local function AddLongPressToControl(controlInstance, onLongPress, longPressTime)
    longPressTime = longPressTime or 0.5
    local timer = nil
    local pressed = false
    local startPos = nil

    local function cleanup()
        if timer then
            task.cancel(timer)
            timer = nil
        end
        pressed = false
        startPos = nil
    end

    local function startPress(input)
        cleanup()
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            pressed = true
            startPos = input.Position
            timer = task.delay(longPressTime, function()
                if pressed then
                    cleanup()
                    onLongPress()
                end
            end)
        end
    end

    local function endPress(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            cleanup()
        end
    end

    local function checkMove(input)
        if pressed and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            if startPos and (input.Position - startPos).Magnitude > 10 then
                cleanup()
            end
        end
    end

    controlInstance.InputBegan:Connect(startPress)
    controlInstance.InputEnded:Connect(endPress)
    UserInputService.InputChanged:Connect(checkMove)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard then
        if WasUI.AwaitingKeyBind then
            local bind = WasUI.AwaitingKeyBind
            WasUI.AwaitingKeyBind = nil
            local keyCode = input.KeyCode
            if keyCode then
                SaveKeyBinding(bind.controlKey, keyCode)
                WasUI.KeyBindings[bind.controlKey] = { keyCode = keyCode, callback = bind.callback, controlType = bind.controlType }
                WasUI:Notify({Title = "设置完成", Content = string.format("当前功能 [%s] 绑定的快捷键为: %s", bind.displayName, GetKeyName(keyCode)), Duration = 2.5, BackgroundColor = WasUI.CurrentTheme.Success, BorderColor = WasUI.CurrentTheme.Success})
            else
                WasUI:Notify({Title = "设置失败", Content = "无效的按键", Duration = 1.5})
            end
            return
        end
        for key, bind in pairs(WasUI.KeyBindings) do
            if input.KeyCode == bind.keyCode then
                if bind.controlType == "toggle" and bind.callback then
                    bind.callback()
                elseif bind.controlType == "button" and bind.callback then
                    bind.callback()
                end
                break
            end
        end
    end
end)

local function AddRipple(instance, scaleFactor)
    scaleFactor = scaleFactor or 1.5
    local function createRipple(input)
        local ripple = Instance.new("Frame")
        ripple.Name = "Ripple"
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.BackgroundColor3 = WasUI.CurrentTheme.Accent
        ripple.BackgroundTransparency = 0.6
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 10
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(1, 0)
        corner.Parent = ripple
        ripple.Parent = instance
        local mousePos = input.Position
        local btnPos = instance.AbsolutePosition
        local x = mousePos.X - btnPos.X
        local y = mousePos.Y - btnPos.Y
        ripple.Position = UDim2.new(0, x, 0, y)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        local maxSize = math.max(instance.AbsoluteSize.X, instance.AbsoluteSize.Y) * scaleFactor
        Tween(ripple, {Size = UDim2.new(0, maxSize, 0, maxSize), BackgroundTransparency = 1}, 0.5)
        task.delay(0.5, function() ripple:Destroy() end)
    end
    instance.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            createRipple(input)
        end
    end)
end

local function CreateShortcutButton(displayName, isToggle, initialState, onToggleCallback, onClickCallback, rainbowKey)
    EnsureShortcutGui()
    local key = GetShortcutKey(isToggle and "toggle" or "button", nil, rainbowKey)

    if WasUI.ShortcutButtons[key] then
        local existing = WasUI.ShortcutButtons[key]
        if existing.destroy then
            existing:destroy()
        elseif existing.button then
            existing.button:Destroy()
        end
        WasUI.ShortcutButtons[key] = nil
        return nil
    end

    local btnFrame = CreateInstance("Frame", {
        Name = "Shortcut_" .. (rainbowKey or displayName),
        Size = UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 10000,
        Parent = WasUI.ShortcutGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = btnFrame})
    local stroke = CreateInstance("UIStroke", {
        Color = WasUI.CurrentTheme.Accent,
        Thickness = 1,
        Transparency = 0.5,
        Parent = btnFrame
    })

    local textLabel = CreateInstance("TextLabel", {
        Name = "Text",
        BackgroundTransparency = 1,
        Text = displayName,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 10001,
        Parent = btnFrame
    })
    WasUI:SetLocalizedText(textLabel, displayName)

    local stateIndicator = nil
    if isToggle then
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.Size = UDim2.new(1, -24, 1, 0)
        textLabel.Position = UDim2.new(0, 8, 0, 0)
        stateIndicator = CreateInstance("Frame", {
            Name = "Indicator",
            Size = UDim2.new(0, 8, 0, 8),
            Position = UDim2.new(1, -16, 0.5, -4),
            BackgroundColor3 = initialState and WasUI.CurrentTheme.Success or WasUI.CurrentTheme.Error,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            ZIndex = 10002,
            Parent = btnFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = stateIndicator})
    else
        textLabel.TextXAlignment = Enum.TextXAlignment.Center
        textLabel.Size = UDim2.new(1, -16, 1, 0)
        textLabel.Position = UDim2.new(0, 8, 0, 0)
    end

    local function updateSize()
        local textBounds = textLabel.TextBounds
        local width = math.max(80, textBounds.X + (isToggle and 32 or 24))
        btnFrame.Size = UDim2.new(0, width, 0, 32)
    end
    textLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateSize)
    updateSize()

    local savedPos = LoadShortcutPosition(key)
    if savedPos then
        btnFrame.Position = savedPos
    else
        local index = 0
        for _,_ in pairs(WasUI.ShortcutButtons) do index = index + 1 end
        btnFrame.Position = UDim2.new(1, -100, 1, -50 - index * 40)
    end

    local dragData = {
        dragging = false,
        startPos = nil,
        startMouse = nil,
        moved = false,
        threshold = 5,
        connectionChanged = nil,
        connectionEnded = nil,
        currentTouch = nil
    }

    local currentState = initialState

    local function updateVisuals()
        if isToggle then
            if currentState then
                Tween(stroke, {Color = WasUI.CurrentTheme.Success, Transparency = 0.2}, 0.2)
                Tween(stateIndicator, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            else
                Tween(stroke, {Color = WasUI.CurrentTheme.Accent, Transparency = 0.5}, 0.2)
                Tween(stateIndicator, {BackgroundColor3 = WasUI.CurrentTheme.Error}, 0.2)
            end
        end
    end

    local function onInputBegan(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragData.dragging = true
            dragData.moved = false
            dragData.startPos = btnFrame.Position
            dragData.startMouse = input.Position
            dragData.currentTouch = nil
            SpringTween(btnFrame, {BackgroundTransparency = 0.1}, 0.1)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            dragData.dragging = true
            dragData.moved = false
            dragData.startPos = btnFrame.Position
            dragData.startMouse = input.Position
            dragData.currentTouch = input
            SpringTween(btnFrame, {BackgroundTransparency = 0.1}, 0.1)
        end
    end

    local function onInputChanged(input, processed)
        if processed then return end
        local isValid = false
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragData.dragging and dragData.currentTouch == nil then
            isValid = true
        elseif input.UserInputType == Enum.UserInputType.Touch and dragData.dragging and input == dragData.currentTouch then
            isValid = true
        end
        if isValid then
            local delta = input.Position - dragData.startMouse
            if delta.Magnitude > dragData.threshold then
                dragData.moved = true
            end
            if dragData.moved then
                local newPos = UDim2.new(
                    dragData.startPos.X.Scale,
                    dragData.startPos.X.Offset + delta.X,
                    dragData.startPos.Y.Scale,
                    dragData.startPos.Y.Offset + delta.Y
                )
                btnFrame.Position = newPos
            end
        end
    end

    local function onInputEnded(input, processed)
        if processed then return end
        local isValid = false
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragData.dragging and dragData.currentTouch == nil then
            isValid = true
        elseif input.UserInputType == Enum.UserInputType.Touch and dragData.dragging and input == dragData.currentTouch then
            isValid = true
        end
        if isValid then
            if dragData.moved then
                SaveShortcutPosition(key, btnFrame.Position)
            else
                if isToggle then
                    currentState = not currentState
                    updateVisuals()
                    if onToggleCallback then onToggleCallback(currentState) end
                    SpringTween(btnFrame, {BackgroundTransparency = 0.3}, 0.1)
                    task.wait(0.05)
                    SpringTween(btnFrame, {BackgroundTransparency = 0.2}, 0.1)
                else
                    if onClickCallback then onClickCallback() end
                    SpringTween(btnFrame, {BackgroundTransparency = 0.3}, 0.1)
                    task.wait(0.05)
                    SpringTween(btnFrame, {BackgroundTransparency = 0.2}, 0.1)
                end
            end
            dragData.dragging = false
            dragData.currentTouch = nil
            SpringTween(btnFrame, {BackgroundTransparency = 0.2}, 0.1)
        end
    end

    btnFrame.InputBegan:Connect(onInputBegan)
    dragData.connectionChanged = UserInputService.InputChanged:Connect(onInputChanged)
    dragData.connectionEnded = UserInputService.InputEnded:Connect(onInputEnded)

    local function updateState(newState)
        if isToggle then
            currentState = newState
            updateVisuals()
        end
    end

    updateVisuals()

    local shortcutObj = {
        button = btnFrame,
        key = key,
        updateState = updateState,
        destroy = function()
            if dragData.connectionChanged then dragData.connectionChanged:Disconnect() end
            if dragData.connectionEnded then dragData.connectionEnded:Disconnect() end
            if btnFrame then btnFrame:Destroy() end
            WasUI.ShortcutButtons[key] = nil
        end
    }
    WasUI.ShortcutButtons[key] = shortcutObj
    return shortcutObj
end

local Control = {}
Control.__index = Control
function Control:New(name, parent)
    local self = setmetatable({}, Control)
    self.Name = name
    self.Parent = parent
    self.Instance = nil
    self.Visible = true
    return self
end

function Control:SetPosition(position)
    if self.Instance then
        self.Instance.Position = position
    end
end

function Control:SetSize(size)
    if self.Instance then
        self.Instance.Size = size
    end
end

function Control:SetVisible(visible)
    self.Visible = visible
    if self.Instance then
        self.Instance.Visible = visible
    end
end

local Button = setmetatable({}, {__index = Control})
Button.__index = Button
function Button:New(name, parent, text, onClick, size, iconName)
    local self = Control:New(name, parent)
    local buttonSize = size or UDim2.new(1, 0, 0, 28)
    self.Instance = CreateInstance("TextButton", {
        Name = "Button",
        Size = buttonSize,
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.None,
        ZIndex = 2
    })
    WasUI:SetLocalizedText(self.Instance, text or "按钮")
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Instance})
    local padding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = self.Instance
    })
    if iconName then
        local icon = WasUI:CreateIcon(iconName, UDim2.new(0, 14, 0, 14), WasUI.CurrentTheme.Text)
        if icon then
            icon.Parent = self.Instance
            icon.Position = UDim2.new(0, -34, 0.5, -7)
            icon.ZIndex = 3
            padding.PaddingLeft = UDim.new(0, 64)
            self.Instance.TextXAlignment = Enum.TextXAlignment.Left
        end
    end
    local scale = Instance.new("UIScale", self.Instance)
    
    local isPressed = false
    local isDragging = false
    local dragStartPos = nil
    local dragThreshold = 10
    local dragConnection = nil
    
    local function resetPress()
        if isPressed then
            isPressed = false
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
            SpringTween(scale, {Scale = 1}, 0.25)
        end
        if dragConnection then dragConnection:Disconnect() end
        isDragging = false
        dragStartPos = nil
    end
    
    self.Instance.MouseEnter:Connect(function()
        if not isPressed then
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.15, Enum.EasingStyle.Sine)
        end
    end)
    self.Instance.MouseLeave:Connect(function()
        if not isPressed then
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.15, Enum.EasingStyle.Sine)
        else
            resetPress()
        end
    end)
    self.Instance.MouseButton1Down:Connect(function()
        isPressed = true
        dragStartPos = UserInputService:GetMouseLocation()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
        SpringTween(scale, {Scale = 0.97}, 0.2)
        dragConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement and dragStartPos then
                local delta = (UserInputService:GetMouseLocation() - dragStartPos).Magnitude
                if delta > dragThreshold then
                    isDragging = true
                end
            end
        end)
    end)
    self.Instance.MouseButton1Up:Connect(function()
        if isPressed then
            isPressed = false
            Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
            SpringTween(scale, {Scale = 1}, 0.25)
            if not isDragging and onClick then
                onClick()
            end
        end
        if dragConnection then dragConnection:Disconnect() end
        isDragging = false
        dragStartPos = nil
    end)
    
    if UserInputService.TouchEnabled then
        local touchStartPos = nil
        local touchDragging = false
        local touchConnection = nil
        self.Instance.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                isPressed = true
                touchStartPos = input.Position
                Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
                SpringTween(scale, {Scale = 0.97}, 0.2)
                touchConnection = UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.Touch and touchStartPos then
                        local delta = (inp.Position - touchStartPos).Magnitude
                        if delta > dragThreshold then
                            touchDragging = true
                        end
                    end
                end)
            end
        end)
        self.Instance.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                if isPressed then
                    isPressed = false
                    Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
                    SpringTween(scale, {Scale = 1}, 0.25)
                    if not touchDragging and onClick then
                        onClick()
                    end
                end
                if touchConnection then touchConnection:Disconnect() end
                touchDragging = false
                touchStartPos = nil
            end
        end)
    end

    AddRipple(self.Instance)

    local controlKey = "button_" .. (text or name)
    AddKeyBindLongPress(self.Instance, controlKey, "button", onClick, text or name)
    local savedKey = LoadKeyBinding(controlKey)
    if savedKey then
        WasUI.KeyBindings[controlKey] = { keyCode = savedKey, callback = onClick, controlType = "button" }
    end

    AddLongPressToControl(self.Instance, function()
        CreateShortcutButton(text or name, false, nil, nil, onClick, text or name)
    end, 3)

    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Instance:SetAttribute("Category", cat)
        end
    end

    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Button"})
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, title, initialState, onToggle, featureName, rainbowName, iconName, configKey)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = featureName or name
    self.RainbowName = (type(rainbowName) == "string" and rainbowName) 
                       or (type(self.FeatureName) == "string" and self.FeatureName) 
                       or name
    self.Container = CreateInstance("Frame", {
        Name = "ToggleContainer",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
        ZIndex = 2
    })
    self.Container:SetAttribute("SearchText", title or "")
    
    if title ~= nil then
        self.TitleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
            Parent = self.Container
        })
        WasUI:SetLocalizedText(self.TitleLabel, title)
    end
    
    local offColor = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
    local bgPos = title and UDim2.new(1, -40, 0.5, -9) or UDim2.new(0, 0, 0.5, -9)
    self.Background = CreateInstance("ImageButton", {
        Name = "ToggleBG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = bgPos,
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or offColor,
        Image = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = self.Container
    })
    self.Background:SetAttribute("Toggled", self.Toggled)
    local bgCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Background})
    self.Knob = CreateInstance("Frame", {
        Name = "ToggleKnob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Toggled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Background
    })
    local knobCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Knob})
    if iconName then
        local knobIcon = WasUI:CreateIcon(iconName, UDim2.new(0, 10, 0, 10), self.Toggled and WasUI.CurrentTheme.Success or WasUI.CurrentTheme.Accent)
        if knobIcon then
            knobIcon.Parent = self.Knob
            knobIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
            knobIcon.ZIndex = 6
            knobIcon.ImageTransparency = 0
        end
    end
    if self.Toggled and self.RainbowName ~= nil and self.RainbowName ~= "" then
        CreateRainbowTextForFeature(self.RainbowName)
    end

    AddRipple(self.Background, 2.5)

    local function performToggle(newState)
        self.Toggled = newState
        self.Background:SetAttribute("Toggled", self.Toggled)
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
            if self.RainbowName and self.RainbowName ~= "" then
                CreateRainbowTextForFeature(self.RainbowName)
            end
            if iconName then
                local iconImg = self.Knob:FindFirstChildOfClass("ImageLabel")
                if iconImg then iconImg.ImageColor3 = WasUI.CurrentTheme.Success end
            end
        else
            local offCol = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
            Tween(self.Background, {BackgroundColor3 = offCol}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            if self.RainbowName and self.RainbowName ~= "" then
                DestroyRainbowTextForFeature(self.RainbowName)
            end
            if iconName then
                local iconImg = self.Knob:FindFirstChildOfClass("ImageLabel")
                if iconImg then iconImg.ImageColor3 = WasUI.CurrentTheme.Accent end
            end
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
        local shortcutKey = GetShortcutKey("toggle", name, self.RainbowName)
        local shortcut = WasUI.ShortcutButtons[shortcutKey]
        if shortcut and shortcut.updateState then
            shortcut.updateState(self.Toggled)
        end
        if configKey and WasUI.ConfigManager then
            local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
            if config then
                config:Set(configKey, self.Toggled)
                config:Save()
            end
        end
    end

    local function setStateSilently(newState)
        self.Toggled = newState
        self.Background:SetAttribute("Toggled", self.Toggled)
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
            if self.RainbowName and self.RainbowName ~= "" then
                CreateRainbowTextForFeature(self.RainbowName)
            end
            if iconName then
                local iconImg = self.Knob:FindFirstChildOfClass("ImageLabel")
                if iconImg then iconImg.ImageColor3 = WasUI.CurrentTheme.Success end
            end
        else
            local offCol = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
            Tween(self.Background, {BackgroundColor3 = offCol}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            if self.RainbowName and self.RainbowName ~= "" then
                DestroyRainbowTextForFeature(self.RainbowName)
            end
            if iconName then
                local iconImg = self.Knob:FindFirstChildOfClass("ImageLabel")
                if iconImg then iconImg.ImageColor3 = WasUI.CurrentTheme.Accent end
            end
        end
        local shortcutKey = GetShortcutKey("toggle", name, self.RainbowName)
        local shortcut = WasUI.ShortcutButtons[shortcutKey]
        if shortcut and shortcut.updateState then
            shortcut.updateState(self.Toggled)
        end
        if configKey and WasUI.ConfigManager then
            local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
            if config then
                config:Set(configKey, self.Toggled)
                config:Save()
            end
        end
    end

    function self:SetToggle(newState)
        performToggle(newState)
    end

    self._setStateSilently = setStateSilently

    self.Background.MouseButton1Click:Connect(function()
        performToggle(not self.Toggled)
    end)

    local controlKey = GetShortcutKey("toggle", name, self.RainbowName)
    AddKeyBindLongPress(self.Background, controlKey, "toggle", function()
        performToggle(not self.Toggled)
    end, self.RainbowName)
    local savedKey = LoadKeyBinding(controlKey)
    if savedKey then
        WasUI.KeyBindings[controlKey] = { keyCode = savedKey, callback = function() performToggle(not self.Toggled) end, controlType = "toggle" }
    end

    AddLongPressToControl(self.Background, function()
        local shortcut = CreateShortcutButton(self.RainbowName, true, self.Toggled, 
            function(newState)
                performToggle(newState)
            end, nil, self.RainbowName)
    end, 3)

    if configKey and WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
        if config then
            config:Bind(configKey, self, function(state) performToggle(state) end)
        end
    end

    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Container:SetAttribute("Category", cat)
        end
    end

    table.insert(WasUI.Objects, {Object = self.Background, Type = "Toggle"})
    table.insert(WasUI.Objects, {Object = self.Knob, Type = "ToggleKnob"})
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label
function Label:New(name, parent, text, textColor)
    local self = Control:New(name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = textColor or WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = parent
    })
    WasUI:SetLocalizedText(self.Instance, text or "标签")
    self.Instance:SetAttribute("SearchText", text or "")
    self.Instance:SetAttribute("IsLabel", true)
    
    function self:SetText(newText)
        if self.Instance then
            WasUI:SetLocalizedText(self.Instance, newText or "")
            self.Instance:SetAttribute("SearchText", newText or "")
        end
    end
    
    function self:SetTextColor(newColor)
        if self.Instance then
            self.Instance.TextColor3 = newColor or WasUI.CurrentTheme.Text
        end
    end
    
    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Instance:SetAttribute("Category", cat)
        end
    end

    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Label"})
    return self
end

local Category = setmetatable({}, {__index = Control})
Category.__index = Category
function Category:New(name, parent, title, iconName)
    local actualIcon = iconName or "chevron-down"
    local self = Control:New(name, parent)
    self.Collapsed = false
    self.ContentHeight = 0

    self.Header = CreateInstance("Frame", {
        Name = "CategoryHeader",
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundTransparency = 1,
        Parent = parent,
        ZIndex = 2
    })

    local titleContainer = CreateInstance("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.Header
    })
    local titleLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = titleContainer
    })

    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
        ZIndex = 2,
        Parent = titleContainer
    })
    WasUI:SetLocalizedText(titleLabel, title)
    table.insert(WasUI.Objects, {Object = titleLabel, Type = "CategoryTitle"})

    local icon = WasUI:CreateIcon(actualIcon, UDim2.new(0, 18, 0, 18), WasUI.CurrentTheme.Text)
    if icon then
        icon.Name = "CategoryIcon"
        icon.Parent = titleContainer
        icon.LayoutOrder = 1
        icon.ZIndex = 3
        icon.Rotation = 0
        self.Icon = icon
    end

    local line = CreateInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Header
    })

    self.Content = CreateInstance("Frame", {
        Name = "CategoryContent",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = parent,
        ZIndex = 2
    })

    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.Content
    })

    local contentPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = self.Content
    })

    local function getContentHeight()
        local h = contentLayout.AbsoluteContentSize.Y
        return h > 0 and h or 0
    end

    local function updateParentScroller()
        local parentScroller = self.Content.Parent
        while parentScroller and not parentScroller:IsA("ScrollingFrame") do
            parentScroller = parentScroller.Parent
        end
        if parentScroller and parentScroller:IsA("ScrollingFrame") then
            local layout = parentScroller:FindFirstChildOfClass("UIListLayout")
            if layout then
                parentScroller.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
            end
        end
    end

    local function updateLayout(animate)
        local targetHeight = self.Collapsed and 0 or getContentHeight()
        if animate then
            local tween = Tween(self.Content, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.25)
            if self.Icon then
                Tween(self.Icon, {Rotation = self.Collapsed and -90 or 0}, 0.25)
            end
            tween.Completed:Connect(function()
                updateParentScroller()
            end)
        else
            self.Content.Size = UDim2.new(1, 0, 0, targetHeight)
            if self.Icon then
                self.Icon.Rotation = self.Collapsed and -90 or 0
            end
            updateParentScroller()
        end
    end

    local function toggleCollapsed()
        self.Collapsed = not self.Collapsed
        updateLayout(true)
    end

    local toggleButton = CreateInstance("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Header,
        ZIndex = 3,
        AutoButtonColor = false
    })
    toggleButton.MouseButton1Click:Connect(toggleCollapsed)

    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if not self.Collapsed then
            local newHeight = getContentHeight()
            if self.Content.Size.Y.Offset ~= newHeight then
                Tween(self.Content, {Size = UDim2.new(1, 0, 0, newHeight)}, 0.2)
                updateParentScroller()
            end
        end
    end)

    updateLayout(false)

    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.SetCurrentCategory then
        panel:SetCurrentCategory(title)
    end

    self.Instance = self.Content
    table.insert(WasUI.Objects, {Object = self.Header, Type = "Category"})
    table.insert(WasUI.Objects, {Object = self.Content, Type = "CategoryContent"})
    return self
end

local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback, multiSelect, configKey)
    EnsureDropdownGui()
    local self = Control:New(name, parent)
    self.MultiSelect = not not multiSelect
    self.Options = {}
    for _, v in ipairs(options or {}) do
        table.insert(self.Options, tostring(v))
    end
    self.SelectedValues = {}
    self.SelectedValue = nil
    if self.MultiSelect then
        if type(defaultValue) == "table" then
            for _, v in ipairs(defaultValue) do
                table.insert(self.SelectedValues, tostring(v))
            end
        elseif defaultValue ~= nil then
            table.insert(self.SelectedValues, tostring(defaultValue))
        end
    else
        if type(defaultValue) == "table" then
            self.SelectedValue = tostring(defaultValue[1] or "")
        elseif defaultValue ~= nil then
            self.SelectedValue = tostring(defaultValue)
        end
    end
    self.Callback = callback
    self.IsOpen = false
    self.Container = CreateInstance("Frame", {
        Name = "Dropdown",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = parent
    })
    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.Container
    })
    WasUI:SetLocalizedText(self.TitleLabel, title or "下拉菜单")
    self.DropdownButton = CreateInstance("TextButton", {
        Name = "DropdownButton",
        Size = UDim2.new(0.3, 0, 0, 24),
        Position = UDim2.new(0.7, -3, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        ZIndex = 11,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.DropdownButton})
    local arrowIcon = CreateInstance("ImageLabel", {
        Name = "ArrowIcon",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(1, -10, 0.5, -6),
        BackgroundTransparency = 1,
        Image = "rbxassetid://12187365364",
        ImageRectOffset = Vector2.new(0, 0),
        ImageRectSize = Vector2.new(24, 24),
        ImageColor3 = WasUI.CurrentTheme.Text,
        ImageTransparency = 0,
        ZIndex = 12,
        Parent = self.DropdownButton
    })
    self.OptionsContainer = CreateInstance("ScrollingFrame", {
        Name = "OptionsContainer",
        Size = UDim2.new(0.3, 0, 0, 0),
        Position = UDim2.new(0.7, -3, 0, 24),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 0.3,
        BorderColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 9999,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = WasUI.DropdownGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.OptionsContainer})
    local shadow = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Transparency = 1,
        Parent = self.OptionsContainer
    })
    local optionsList = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.OptionsContainer
    })
    local optionsPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        Parent = self.OptionsContainer
    })
    self.OptionButtons = {}
    local function rebuildOptions()
        for _, btn in pairs(self.OptionButtons) do
            btn:Destroy()
        end
        self.OptionButtons = {}
        for i, option in ipairs(self.Options) do
            local optionButton = CreateInstance("TextButton", {
                Name = "Option_" .. option,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = WasUI.CurrentTheme.Input,
                BackgroundTransparency = 0.3,
                BorderSizePixel = 0,
                Text = option,
                TextColor3 = WasUI.CurrentTheme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                AutoButtonColor = false,
                ZIndex = 10000,
                Parent = self.OptionsContainer
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = optionButton})
            optionButton.MouseEnter:Connect(function()
                Tween(optionButton, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
            end)
            optionButton.MouseLeave:Connect(function()
                Tween(optionButton, {BackgroundColor3 = WasUI.CurrentTheme.Input}, 0.1)
            end)
            optionButton.MouseButton1Click:Connect(function()
                if self.MultiSelect then
                    local index = nil
                    for i, v in ipairs(self.SelectedValues) do
                        if v == option then
                            index = i
                            break
                        end
                    end
                    if index then
                        table.remove(self.SelectedValues, index)
                    else
                        table.insert(self.SelectedValues, option)
                    end
                    self:UpdateDisplayText()
                    if self.Callback then self.Callback(self.SelectedValues) end
                    if configKey and WasUI.ConfigManager then
                        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
                        if config then
                            config:Set(configKey, self.SelectedValues)
                            config:Save()
                        end
                    end
                else
                    self.SelectedValue = option
                    self:UpdateDisplayText()
                    if self.Callback then self.Callback(option) end
                    self:Close(true)
                    if configKey and WasUI.ConfigManager then
                        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
                        if config then
                            config:Set(configKey, option)
                            config:Save()
                        end
                    end
                end
            end)
            AddRipple(optionButton)
            self.OptionButtons[option] = optionButton
            table.insert(WasUI.Objects, {Object = optionButton, Type = "DropdownOption"})
        end
        local function updateContainerSize()
            local totalHeight = #self.Options * 28 + (#self.Options - 1) * 4 + 16
            local maxHeight = math.floor(Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize.Y or GuiService:GetScreenSize().Y) * 0.5
            local finalHeight = math.min(totalHeight, maxHeight)
            self.OptionsContainer.Size = UDim2.new(0.3, 0, 0, finalHeight)
            task.wait()
            self.OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsList.AbsoluteContentSize.Y + 8)
        end
        updateContainerSize()
        if self.IsOpen then
            updatePosition()
        end
    end
    function self:UpdateOptions(newOptions, newDefaultValue)
        self.Options = {}
        for _, v in ipairs(newOptions or {}) do
            table.insert(self.Options, tostring(v))
        end
        if self.MultiSelect then
            self.SelectedValues = {}
            if type(newDefaultValue) == "table" then
                for _, v in ipairs(newDefaultValue) do
                    table.insert(self.SelectedValues, tostring(v))
                end
            elseif newDefaultValue ~= nil then
                table.insert(self.SelectedValues, tostring(newDefaultValue))
            end
        else
            if type(newDefaultValue) == "table" then
                self.SelectedValue = tostring(newDefaultValue[1] or "")
            elseif newDefaultValue ~= nil then
                self.SelectedValue = tostring(newDefaultValue)
            end
        end
        rebuildOptions()
        self:UpdateDisplayText()
    end
    local function updatePosition()
        if not self.IsOpen then return end
        local btnPos = self.DropdownButton.AbsolutePosition
        local btnSize = self.DropdownButton.AbsoluteSize
        local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or GuiService:GetScreenSize()
        local menuHeight = self.OptionsContainer.AbsoluteSize.Y
        local menuWidth = self.OptionsContainer.AbsoluteSize.X
        local x = btnPos.X
        local y = btnPos.Y + btnSize.Y
        if y + menuHeight > viewportSize.Y then
            y = btnPos.Y - menuHeight
            if y < 0 then
                y = 5
            end
        end
        if x + menuWidth > viewportSize.X then
            x = viewportSize.X - menuWidth - 5
        end
        if x < 0 then
            x = 5
        end
        self.OptionsContainer.Position = UDim2.new(0, x, 0, y)
    end
    self.DropdownButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition)
    self.DropdownButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
    function self:GetDisplayText()
        if self.MultiSelect then
            if #self.SelectedValues == 0 then return WasUI:Translate("选择...") end
            return table.concat(self.SelectedValues, ", ")
        else
            return self.SelectedValue and tostring(self.SelectedValue) or WasUI:Translate("选择...")
        end
    end
    function self:UpdateDisplayText()
        self.DropdownButton.Text = self:GetDisplayText()
    end
    function self:Open()
        if self.IsOpen then return end
        self.IsOpen = true
        table.insert(WasUI.OpenDropdowns, self)
        updatePosition()
        self.OptionsContainer.Visible = true
        Tween(self.OptionsContainer, {BackgroundTransparency = 0.3}, 0.2)
        Tween(shadow, {Transparency = 0.8}, 0.2)
        for _, btn in pairs(self.OptionButtons) do
            Tween(btn, {BackgroundTransparency = 0.3, TextTransparency = 0}, 0.2)
        end
    end
    function self:Close(instant)
        if not self.IsOpen then return end
        self.IsOpen = false
        for i, dropdown in ipairs(WasUI.OpenDropdowns) do
            if dropdown == self then
                table.remove(WasUI.OpenDropdowns, i)
                break
            end
        end
        if instant then
            self.OptionsContainer.Visible = false
            self.OptionsContainer.BackgroundTransparency = 1
            shadow.Transparency = 1
            for _, btn in pairs(self.OptionButtons) do
                btn.BackgroundTransparency = 1
                btn.TextTransparency = 1
            end
        else
            Tween(self.OptionsContainer, {BackgroundTransparency = 1}, 0.2)
            Tween(shadow, {Transparency = 1}, 0.2)
            for _, btn in pairs(self.OptionButtons) do
                Tween(btn, {BackgroundTransparency = 1, TextTransparency = 1}, 0.2)
            end
            task.wait(0.2)
            self.OptionsContainer.Visible = false
        end
    end
    self.DropdownButton.MouseButton1Click:Connect(function()
        if self.IsOpen then
            self:Close()
        else
            self:Open()
        end
    end)
    AddRipple(self.DropdownButton)
    rebuildOptions()
    self:UpdateDisplayText()
    if configKey and WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
        if config then
            local savedValue = config:Get(configKey)
            if savedValue ~= nil then
                if self.MultiSelect then
                    if type(savedValue) == "table" then
                        self.SelectedValues = savedValue
                    elseif type(savedValue) == "string" then
                        self.SelectedValues = { savedValue }
                    end
                else
                    if type(savedValue) == "string" then
                        self.SelectedValue = savedValue
                    elseif type(savedValue) == "table" and #savedValue > 0 then
                        self.SelectedValue = savedValue[1]
                    end
                end
                self:UpdateDisplayText()
            end
            config:Bind(configKey, self, function(value)
                if self.MultiSelect then
                    if type(value) == "table" then
                        self.SelectedValues = value
                    elseif type(value) == "string" then
                        self.SelectedValues = { value }
                    end
                else
                    if type(value) == "string" then
                        self.SelectedValue = value
                    elseif type(value) == "table" and #value > 0 then
                        self.SelectedValue = value[1]
                    end
                end
                self:UpdateDisplayText()
            end)
        end
    end
    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Container:SetAttribute("Category", cat)
        end
    end
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Dropdown"})
    table.insert(WasUI.Objects, {Object = self.DropdownButton, Type = "DropdownButton"})
    return self
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        for i = #WasUI.OpenDropdowns, 1, -1 do
            local dropdown = WasUI.OpenDropdowns[i]
            if not dropdown or not dropdown.IsOpen then continue end
            local mousePos = input.Position
            local menuPos = dropdown.OptionsContainer.AbsolutePosition
            local menuSize = dropdown.OptionsContainer.AbsoluteSize
            local btnPos = dropdown.DropdownButton.AbsolutePosition
            local btnSize = dropdown.DropdownButton.AbsoluteSize
            local inMenu = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X and
                            mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
            local inButton = mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X and
                            mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y
            if not inMenu and not inButton then
                dropdown:Close()
            end
        end
    end
end)

local Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider
function Slider:New(name, parent, title, min, max, defaultValue, callback, configKey)
    local self = Control:New(name, parent)
    self.Min = min or 0
    self.Max = max or 100
    self.Value = math.clamp(defaultValue or self.Min, self.Min, self.Max)
    self.Callback = callback
    self.AnimationTween = nil
    self.Container = CreateInstance("Frame", {
        Name = "Slider",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = parent
    })
    self.Container:SetAttribute("SearchText", title or "")
    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.4, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = self.Container
    })
    WasUI:SetLocalizedText(self.TitleLabel, title or "滑动条")
    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.2, 0, 0, 18),
        Position = UDim2.new(0.8, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = string.format("%.1f", self.Value),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
        Parent = self.Container
    })
    self.SliderTrack = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -2, 0, 12),
        Position = UDim2.new(0, 2, 0, 16),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.SliderTrack})
    self.SliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.SliderFill})
    self.Knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -10, 0.5, -10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.SliderTrack
    })
    self.Knob.Visible = false
    self.Knob:GetPropertyChangedSignal("Visible"):Connect(function()
        if self.Knob.Visible then
            self.Knob.Visible = false
        end
    end)
    local knobCircle = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        Parent = self.Knob
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knobCircle})
    local knobScale = Instance.new("UIScale", knobCircle)

    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.Size = UDim2.new(0, 40, 0, 20)
    tooltip.BackgroundColor3 = WasUI.CurrentTheme.Section
    tooltip.BackgroundTransparency = 0.1
    tooltip.TextColor3 = WasUI.CurrentTheme.Text
    tooltip.TextSize = 12
    tooltip.Font = Enum.Font.GothamBold
    tooltip.TextXAlignment = Enum.TextXAlignment.Center
    tooltip.TextYAlignment = Enum.TextYAlignment.Center
    tooltip.Visible = false
    tooltip.ZIndex = 10
    tooltip.Parent = self.SliderTrack
    local tooltipCorner = Instance.new("UICorner")
    tooltipCorner.CornerRadius = UDim.new(1, 0)
    tooltipCorner.Parent = tooltip

    local function showTooltip(val)
        tooltip.Text = string.format("%.1f", val)
        tooltip.Visible = true
        local knobPos = self.Knob.AbsolutePosition
        tooltip.Position = UDim2.new(0, knobPos.X + self.Knob.AbsoluteSize.X/2 - tooltip.AbsoluteSize.X/2 - self.SliderTrack.AbsolutePosition.X, 0, -25)
    end
    local function hideTooltip()
        tooltip.Visible = false
    end

    local function stopAnimation()
        if self.AnimationTween then
            self.AnimationTween:Cancel()
            self.AnimationTween = nil
        end
    end
    local function setValueImmediately(newValue)
        newValue = math.clamp(newValue, self.Min, self.Max)
        if newValue == self.Value then return end
        self.Value = newValue
        self.ValueLabel.Text = string.format("%.1f", self.Value)
        local t = (self.Value - self.Min) / (self.Max - self.Min)
        self.SliderFill.Size = UDim2.new(t, 0, 1, 0)
        self.Knob.Position = UDim2.new(t, -10, 0.5, -10)
        if self.Callback then self.Callback(self.Value) end
        if configKey and WasUI.ConfigManager then
            local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
            if config then
                config:Set(configKey, self.Value)
                config:Save()
            end
        end
    end
    local function animateToValue(targetValue)
        targetValue = math.clamp(targetValue, self.Min, self.Max)
        if targetValue == self.Value then return end
        local targetT = (targetValue - self.Min) / (self.Max - self.Min)
        stopAnimation()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fillTween = TweenService:Create(self.SliderFill, tweenInfo, {Size = UDim2.new(targetT, 0, 1, 0)})
        local knobTween = TweenService:Create(self.Knob, tweenInfo, {Position = UDim2.new(targetT, -10, 0.5, -10)})
        local completed = false
        local function onFinish()
            if completed then return end
            completed = true
            self.AnimationTween = nil
            setValueImmediately(targetValue)
        end
        fillTween.Completed:Connect(onFinish)
        knobTween.Completed:Connect(onFinish)
        fillTween:Play()
        knobTween:Play()
        self.AnimationTween = fillTween
    end
    local dragging = false
    local function updateFromMousePosition(inputX)
        local trackPos = self.SliderTrack.AbsolutePosition
        local trackSize = self.SliderTrack.AbsoluteSize.X
        if trackSize <= 0 then return end
        local t = math.clamp((inputX - trackPos.X) / trackSize, 0, 1)
        local newValue = self.Min + t * (self.Max - self.Min)
        newValue = math.round(newValue * 10) / 10
        if newValue ~= self.Value then
            stopAnimation()
            setValueImmediately(newValue)
        end
    end
    
    local parentScrollingFrame = self.Container.Parent
    while parentScrollingFrame and not parentScrollingFrame:IsA("ScrollingFrame") do
        parentScrollingFrame = parentScrollingFrame.Parent
    end
    local originalScrollingEnabled = parentScrollingFrame and parentScrollingFrame.ScrollingEnabled
    local inputChangedConn = nil
    
    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateFromMousePosition(input.Position.X)
            if parentScrollingFrame then
                parentScrollingFrame.ScrollingEnabled = false
            end
            dragging = true
            stopAnimation()
            SpringTween(knobScale, {Scale = 1.2}, 0.15)
            showTooltip(self.Value)
            if inputChangedConn then inputChangedConn:Disconnect() end
            inputChangedConn = UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    local pos = inp.Position
                    updateFromMousePosition(pos.X)
                    showTooltip(self.Value)
                end
            end)
        end
    end
    
    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if parentScrollingFrame then
                parentScrollingFrame.ScrollingEnabled = originalScrollingEnabled
            end
            dragging = false
            SpringTween(knobScale, {Scale = 1}, 0.25)
            hideTooltip()
            if inputChangedConn then
                inputChangedConn:Disconnect()
                inputChangedConn = nil
            end
        end
    end
    
    self.SliderTrack.InputBegan:Connect(onInputBegan)
    self.SliderTrack.InputEnded:Connect(onInputEnded)
    self.Knob.InputBegan:Connect(onInputBegan)
    self.Knob.InputEnded:Connect(onInputEnded)
    
    self.Container.AncestryChanged:Connect(function()
        if not self.Container:IsDescendantOf(game) then
            if inputChangedConn then inputChangedConn:Disconnect() end
            dragging = false
        end
    end)
    
    function self:StopDragging()
        if dragging then
            dragging = false
            if parentScrollingFrame then
                parentScrollingFrame.ScrollingEnabled = originalScrollingEnabled
            end
            SpringTween(knobScale, {Scale = 1}, 0.25)
            hideTooltip()
            if inputChangedConn then
                inputChangedConn:Disconnect()
                inputChangedConn = nil
            end
        end
    end
    
    AddRipple(self.SliderTrack)
    if configKey and WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
        if config then
            local savedValue = config:Get(configKey)
            if savedValue ~= nil then
                setValueImmediately(savedValue)
            end
            config:Bind(configKey, self, function(value) setValueImmediately(value) end)
        end
    end
    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Container:SetAttribute("Category", cat)
        end
    end
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Slider"})
    return self
end

local TextInput = setmetatable({}, {__index = Control})
TextInput.__index = TextInput
function TextInput:New(name, parent, placeholder, defaultValue, callback, configKey)
    local self = Control:New(name, parent)
    self.Callback = callback
    self.Container = CreateInstance("Frame", {
        Name = "TextInput",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = parent
    })
    self.TextBox = CreateInstance("TextBox", {
        Name = "TextBox",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = defaultValue or "",
        PlaceholderText = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 2,
        Parent = self.Container
    })
    WasUI:SetLocalizedText(self.TextBox, placeholder or "输入...", "PlaceholderText")
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.TextBox})
    local padding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = self.TextBox
    })
    self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if self.Callback then
            self.Callback(self.TextBox.Text)
        end
        if configKey and WasUI.ConfigManager then
            local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
            if config then
                config:Set(configKey, self.TextBox.Text)
                config:Save()
            end
        end
    end)
    AddRipple(self.TextBox)
    if configKey and WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
        if config then
            local savedValue = config:Get(configKey)
            if savedValue ~= nil then
                self.TextBox.Text = savedValue
            end
            config:Bind(configKey, self, function(value) self.TextBox.Text = value end)
        end
    end
    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Container:SetAttribute("Category", cat)
        end
    end
    table.insert(WasUI.Objects, {Object = self.Container, Type = "TextInput"})
    return self
end

function WasUI:CreateTextInput(parent, placeholder, defaultValue, callback, configKey)
    return TextInput:New("TextInput", parent, placeholder, defaultValue, callback, configKey)
end

local ProgressBar = setmetatable({}, {__index = Control})
ProgressBar.__index = ProgressBar

function ProgressBar:New(name, parent, title, min, max, defaultValue, callback)
    local self = Control:New(name, parent)
    self.Min = min or 0
    self.Max = max or 100
    self.Value = math.clamp(defaultValue or self.Min, self.Min, self.Max)
    self.Callback = callback
    self.AnimationTween = nil
    
    self.Container = CreateInstance("Frame", {
        Name = "ProgressBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = parent
    })
    self.Container:SetAttribute("SearchText", title or "")
    
    if title then
        self.TitleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(0.4, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 3,
            Parent = self.Container
        })
        WasUI:SetLocalizedText(self.TitleLabel, title)
    end
    
    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.2, 0, 0, 18),
        Position = UDim2.new(0.8, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value) .. "%",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
        Parent = self.Container
    })
    
    self.Track = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -2, 0, 12),
        Position = UDim2.new(0, 2, 0, 18),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.Track})
    
    self.Fill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.Track
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.Fill})
    
    local stripe = CreateInstance("ImageLabel", {
        Name = "Stripe",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://1288891801",
        ImageTransparency = 0.7,
        ScaleType = Enum.ScaleType.Tile,
        TileSize = UDim2.new(0, 20, 0, 12),
        Visible = true,
        ZIndex = 4,
        Parent = self.Fill
    })
    
    local function updateFill()
        local t = (self.Value - self.Min) / (self.Max - self.Min)
        self.Fill:TweenSize(UDim2.new(t, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        self.ValueLabel.Text = tostring(math.floor(self.Value)) .. "%"
        if self.Callback then self.Callback(self.Value) end
    end
    
    function self:SetValue(newValue)
        self.Value = math.clamp(newValue, self.Min, self.Max)
        updateFill()
    end
    
    function self:GetValue()
        return self.Value
    end
    
    local panel = parent
    while panel do
        if type(panel) == "table" and panel.GetActiveTab then
            break
        end
        if panel.Parent then
            panel = panel.Parent
        else
            panel = nil
            break
        end
    end
    if panel and panel.GetCurrentCategory then
        local cat = panel:GetCurrentCategory()
        if cat then
            self.Container:SetAttribute("Category", cat)
        end
    end
    
    table.insert(WasUI.Objects, {Object = self.Container, Type = "ProgressBar"})
    return self
end

function WasUI:CreateProgressBar(parent, title, min, max, defaultValue, callback)
    return ProgressBar:New("ProgressBar", parent, title, min, max, defaultValue, callback)
end

function WasUI:CreateTooltip(target, text, options)
    options = options or {}
    local offset = options.offset or Vector2.new(0, 20)
    local backgroundColor = options.backgroundColor or WasUI.CurrentTheme.Section
    local textColor = options.textColor or WasUI.CurrentTheme.Text
    local delay = options.delay or 0.5
    local followMouse = options.followMouse or false
    
    local actualTarget = target
    if target and target.Instance and target.Instance:IsA("GuiObject") then
        actualTarget = target.Instance
    elseif not target:IsA("GuiObject") then
        warn("CreateTooltip: target must be a GuiObject or Control with Instance")
        return
    end
    
    local tooltipGui = nil
    local tooltipFrame = nil
    local timer = nil
    local longPressTimer = nil
    local isLongPress = false
    local touchStartPos = nil
    local currentTouchPoint = nil
    
    local function hideTooltip()
        if timer then task.cancel(timer); timer = nil end
        if longPressTimer then task.cancel(longPressTimer); longPressTimer = nil end
        if tooltipGui then
            tooltipGui:Destroy()
            tooltipGui = nil
            tooltipFrame = nil
        end
        isLongPress = false
        touchStartPos = nil
        currentTouchPoint = nil
    end
    
    local function showTooltipAtPoint(point)
        if tooltipGui then return end
        tooltipGui = Instance.new("ScreenGui")
        tooltipGui.Name = "WasUI_Tooltip"
        tooltipGui.ResetOnSpawn = false
        tooltipGui.DisplayOrder = 2000
        tooltipGui.Parent = game:GetService("CoreGui")
        
        tooltipFrame = CreateInstance("Frame", {
            Name = "Tooltip",
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = backgroundColor,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 10000,
            Parent = tooltipGui
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tooltipFrame})
        local stroke = CreateInstance("UIStroke", {
            Color = WasUI.CurrentTheme.Text,
            Thickness = 1,
            Transparency = 0.5,
            Parent = tooltipFrame
        })
        
        local label = CreateInstance("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -8, 1, -4),
            Position = UDim2.new(0, 4, 0, 2),
            BackgroundTransparency = 1,
            Text = text,
            TextColor3 = textColor,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            TextWrapped = true,
            ZIndex = 10001,
            Parent = tooltipFrame
        })
        
        local textBounds = TextService:GetTextSize(text, 12, Enum.Font.Gotham, Vector2.new(1000, 1000))
        local width = math.max(60, textBounds.X + 16)
        local height = textBounds.Y + 8
        tooltipFrame.Size = UDim2.new(0, width, 0, height)
        
        local viewportSize = Workspace.CurrentCamera.ViewportSize
        local x = point.X - width/2
        local y = point.Y + offset.Y
        if y + height > viewportSize.Y then
            y = point.Y - height - offset.Y
        end
        if x + width > viewportSize.X then
            x = viewportSize.X - width - 5
        end
        if x < 5 then x = 5 end
        tooltipFrame.Position = UDim2.new(0, x, 0, y)
    end
    
    local function showTooltip()
        if tooltipGui then return end
        if actualTarget and actualTarget.Parent then
            local targetPos = actualTarget.AbsolutePosition
            local targetSize = actualTarget.AbsoluteSize
            local point = Vector2.new(targetPos.X + targetSize.X/2, targetPos.Y + targetSize.Y)
            showTooltipAtPoint(point)
        end
    end
    
    if actualTarget.MouseEnter then
        actualTarget.MouseEnter:Connect(function()
            timer = task.delay(delay, showTooltip)
        end)
        actualTarget.MouseLeave:Connect(function()
            hideTooltip()
        end)
    end
    
    if actualTarget.InputBegan then
        actualTarget.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                currentTouchPoint = input.Position
                touchStartPos = input.Position
                longPressTimer = task.delay(delay, function()
                    isLongPress = true
                    showTooltipAtPoint(currentTouchPoint)
                end)
            end
        end)
        actualTarget.InputEnded:Connect(function(input)
            if longPressTimer then
                task.cancel(longPressTimer)
                longPressTimer = nil
            end
            if isLongPress then
                isLongPress = false
                hideTooltip()
            end
            touchStartPos = nil
            currentTouchPoint = nil
        end)
        actualTarget.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch and touchStartPos then
                if (input.Position - touchStartPos).Magnitude > 10 then
                    if longPressTimer then task.cancel(longPressTimer); longPressTimer = nil end
                    if isLongPress then hideTooltip() end
                    touchStartPos = nil
                    currentTouchPoint = nil
                end
            end
        end)
    end
    
    actualTarget.Destroying:Connect(hideTooltip)
    
    return {
        Destroy = hideTooltip
    }
end

function WasUI:ShowConfirmDialog(options, callback)
    local title = options.title or "确认"
    local titleColor = options.titleColor or WasUI.CurrentTheme.Text
    local description = options.description
    local descriptionColor = options.descriptionColor or WasUI.CurrentTheme.Text
    local showInput = options.showInput or false
    local inputPlaceholder = options.inputPlaceholder or "请输入..."
    local inputDefault = options.inputDefault or ""
    local confirmText = options.confirmText or "确认"
    local cancelText = options.cancelText or "取消"
    local onConfirm = options.onConfirm
    local onCancel = options.onCancel
    
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "WasUI_ConfirmDialog"
    dialogGui.ResetOnSpawn = false
    dialogGui.DisplayOrder = 2000
    dialogGui.Parent = game:GetService("CoreGui")
    
    local overlay = CreateInstance("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        Selectable = true,
        Parent = dialogGui,
        ZIndex = 999
    })
    
    local dialogFrame = CreateInstance("Frame", {
        Name = "Dialog",
        Size = UDim2.new(0, 400, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = overlay,
        ZIndex = 1000
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialogFrame})
    
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = titleColor,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    
    local currentY = 60
    local descriptionLabel = nil
    if description and description ~= "" then
        descriptionLabel = CreateInstance("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 10, 0, currentY),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = descriptionColor,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            Parent = dialogFrame,
            ZIndex = 1001
        })
        currentY = currentY + descriptionLabel.AbsoluteSize.Y + 10
    end
    
    local inputBox = nil
    if showInput then
        inputBox = CreateInstance("TextBox", {
            Name = "InputBox",
            Size = UDim2.new(1, -20, 0, 32),
            Position = UDim2.new(0, 10, 0, currentY),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Text = inputDefault,
            PlaceholderText = inputPlaceholder,
            TextColor3 = WasUI.CurrentTheme.Text,
            PlaceholderColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = false,
            Parent = dialogFrame,
            ZIndex = 1001
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = inputBox})
        local padding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = inputBox
        })
        currentY = currentY + 42
    end
    
    local buttonContainer = CreateInstance("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, currentY + 10),
        BackgroundTransparency = 1,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    
    local cancelButton = CreateInstance("TextButton", {
        Name = "CancelButton",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.3,
        Text = cancelText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = cancelButton})
    
    local confirmButton = CreateInstance("TextButton", {
        Name = "ConfirmButton",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0.5, 5, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BackgroundTransparency = 0.3,
        Text = confirmText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = confirmButton})
    
    local totalHeight = currentY + 60
    dialogFrame.Size = UDim2.new(0, 400, 0, totalHeight)
    
    local function updatePosition()
        if dialogFrame and dialogFrame.Parent then
            local parentSize = overlay.AbsoluteSize
            local frameSize = dialogFrame.AbsoluteSize
            dialogFrame.Position = UDim2.new(0.5, -frameSize.X/2, 0.5, -frameSize.Y/2)
        end
    end
    
    dialogFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
    updatePosition()
    
    Tween(dialogFrame, {BackgroundTransparency = 0.3}, 0.2)
    Tween(overlay, {BackgroundTransparency = 0.5}, 0.2)
    
    local function animateClose()
        Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
        Tween(overlay, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        dialogGui:Destroy()
        for i, d in ipairs(WasUI.ActiveDialogs) do
            if d == dialogGui then
                table.remove(WasUI.ActiveDialogs, i)
                break
            end
        end
    end
    
    cancelButton.MouseButton1Click:Connect(function()
        if onCancel then onCancel() end
        animateClose()
    end)
    
    confirmButton.MouseButton1Click:Connect(function()
        local inputValue = nil
        if showInput and inputBox then
            inputValue = inputBox.Text
        end
        if onConfirm then onConfirm(inputValue) end
        animateClose()
    end)
    
    local function onOverlayClick(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local framePos = dialogFrame.AbsolutePosition
            local frameSize = dialogFrame.AbsoluteSize
            local inPanel = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                            mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
            if not inPanel then
                if onCancel then onCancel() end
                animateClose()
            end
        end
    end
    overlay.InputBegan:Connect(onOverlayClick)
    
    table.insert(WasUI.ActiveDialogs, dialogGui)
    return dialogGui
end

function WasUI:CreateConfirmButton(parent, text, confirmOptions, onClick, size, iconName)
    local button = self:CreateButton(parent, text, function()
        self:ShowConfirmDialog(confirmOptions, function(confirmed, inputValue)
            if confirmed and onClick then
                onClick(inputValue)
            end
        end)
    end, size, iconName)
    return button
end

function WasUI:CreateConfirmToggle(parent, title, initialState, confirmOptions, onToggle, featureName, rainbowName, iconName, configKey)
    local toggle = self:CreateToggleWithTitle(parent, title, initialState, function(state)
        if state then
            self:ShowConfirmDialog(confirmOptions, function(confirmed, inputValue)
                if confirmed then
                    if onToggle then onToggle(state) end
                else
                    toggle._setStateSilently(false)
                end
            end)
        else
            if onToggle then onToggle(state) end
        end
    end, featureName, rainbowName, iconName, configKey)
    
    return toggle
end

function WasUI:ShowPopup(options, callback)
    local title = options.title or "提示"
    local titleIcon = options.titleIcon
    local content = options.content or ""
    local confirmText = options.confirmText or "确认"
    local cancelText = options.cancelText or "取消"
    local onConfirm = options.onConfirm
    local onCancel = options.onCancel
    local titleTag = options.titleTag

    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "WasUI_Popup"
    dialogGui.ResetOnSpawn = false
    dialogGui.DisplayOrder = 2000
    dialogGui.Parent = game:GetService("CoreGui")

    local overlay = CreateInstance("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        Selectable = true,
        Parent = dialogGui,
        ZIndex = 999
    })

    local dialogFrame = CreateInstance("Frame", {
        Name = "Dialog",
        Size = UDim2.new(0, 480, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = overlay,
        ZIndex = 1000
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialogFrame})

    local titleContainer = CreateInstance("Frame", {
        Name = "TitleContainer",
        Size = UDim2.new(1, -20, 0, 36),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        Parent = dialogFrame,
        ZIndex = 1001
    })

    local titleIconImage = nil
    if titleIcon then
        titleIconImage = WasUI:CreateIcon(titleIcon, UDim2.new(0, 20, 0, 20), WasUI.CurrentTheme.Text)
        if titleIconImage then
            titleIconImage.Parent = titleContainer
            titleIconImage.Position = UDim2.new(0, 0, 0.5, -10)
            titleIconImage.ZIndex = 1002
        end
    end

    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, (titleIconImage and -24 or 0), 0, 24),
        Position = UDim2.new(titleIconImage and 0.06 or 0, 0, 0.5, -12),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = titleContainer,
        ZIndex = 1002
    })

    if titleTag then
        local tagContainer = CreateInstance("Frame", {
            Name = "TagContainer",
            Size = UDim2.new(0, 0, 0, 20),
            Position = UDim2.new(1, 4, 0.5, -10),
            BackgroundColor3 = titleTag.backgroundColor or WasUI.CurrentTheme.Accent,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            Parent = titleContainer,
            ZIndex = 1003
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tagContainer})
        local tagLabel = CreateInstance("TextLabel", {
            Name = "TagLabel",
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            BackgroundTransparency = 1,
            Text = titleTag.text,
            TextColor3 = titleTag.textColor or WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = tagContainer,
            ZIndex = 1004
        })
        tagContainer.Size = UDim2.new(0, tagLabel.TextBounds.X + 8, 0, 20)
        tagLabel.Size = UDim2.new(0, tagLabel.TextBounds.X, 1, 0)
    end

    local contentLabel = CreateInstance("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -20, 0, 0),
        Position = UDim2.new(0, 10, 0, 56),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = dialogFrame,
        ZIndex = 1001
    })

    local buttonContainer = CreateInstance("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, 70),
        BackgroundTransparency = 1,
        Parent = dialogFrame,
        ZIndex = 1001
    })

    local cancelButton = CreateInstance("TextButton", {
        Name = "CancelButton",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.3,
        Text = cancelText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = cancelButton})

    local confirmButton = CreateInstance("TextButton", {
        Name = "ConfirmButton",
        Size = UDim2.new(0.5, -5, 1, 0),
        Position = UDim2.new(0.5, 5, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BackgroundTransparency = 0.3,
        Text = confirmText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = confirmButton})

    local arrowIcon = WasUI:CreateIcon("arrow-right", UDim2.new(0, 16, 0, 16), WasUI.CurrentTheme.Text, true)
    if arrowIcon then
        arrowIcon.Parent = confirmButton
        arrowIcon.Position = UDim2.new(1, -24, 0.5, -8)
        arrowIcon.ZIndex = 1003
        confirmButton.Text = confirmText .. "  "
        confirmButton.TextXAlignment = Enum.TextXAlignment.Left
        local padding = Instance.new("UIPadding")
        padding.PaddingLeft = UDim.new(0, 12)
        padding.Parent = confirmButton
    end

    local totalHeight = 56 + contentLabel.TextBounds.Y + 40 + 65
    dialogFrame.Size = UDim2.new(0, 480, 0, totalHeight)
    buttonContainer.Position = UDim2.new(0, 10, 0, 56 + contentLabel.TextBounds.Y + 18)

    local function updatePosition()
        if dialogFrame and dialogFrame.Parent then
            local parentSize = dialogGui.AbsoluteSize
            local frameSize = dialogFrame.AbsoluteSize
            dialogFrame.Position = UDim2.new(0.5, -frameSize.X/2, 0.5, -frameSize.Y/2)
        end
    end

    dialogFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
    updatePosition()

    local function animateClose()
        Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
        Tween(overlay, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        dialogGui:Destroy()
        for i, d in ipairs(WasUI.ActiveDialogs) do
            if d == dialogGui then
                table.remove(WasUI.ActiveDialogs, i)
                break
            end
        end
    end

    cancelButton.MouseButton1Click:Connect(function()
        if onCancel then onCancel() end
        animateClose()
    end)

    confirmButton.MouseButton1Click:Connect(function()
        if onConfirm then onConfirm() end
        animateClose()
    end)

    Tween(dialogFrame, {BackgroundTransparency = 0}, 0.2)
    table.insert(WasUI.ActiveDialogs, dialogGui)

    return dialogGui
end

function WasUI:ShowColorPicker(options, callback)
    local title = options.title or "选择颜色"
    local defaultColor = options.defaultColor or Color3.fromRGB(255, 255, 255)
    local showAlpha = options.showAlpha or false
    local defaultAlpha = options.defaultAlpha or 1
    local confirmText = options.confirmText or "确认"
    local cancelText = options.cancelText or "取消"

    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "WasUI_ColorPicker"
    dialogGui.ResetOnSpawn = false
    dialogGui.DisplayOrder = 2000
    dialogGui.Parent = game:GetService("CoreGui")

    local transparentOverlay = CreateInstance("Frame", {
        Name = "TransparentOverlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        Selectable = true,
        Parent = dialogGui,
        ZIndex = 999
    })

    local dialogHeight = showAlpha and 380 or 340
    local dialogFrame = CreateInstance("Frame", {
        Name = "Dialog",
        Size = UDim2.new(0, 280, 0, dialogHeight),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = transparentOverlay,
        ZIndex = 1000
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = dialogFrame})

    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = dialogFrame,
        ZIndex = 1001
    })

    local previewFrame = CreateInstance("Frame", {
        Name = "Preview",
        Size = UDim2.new(1, -16, 0, 32),
        Position = UDim2.new(0, 8, 0, 38),
        BackgroundColor3 = defaultColor,
        BackgroundTransparency = 1 - defaultAlpha,
        BorderSizePixel = 0,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = previewFrame})

    local svMap = CreateInstance("ImageLabel", {
        Name = "SVMap",
        Size = UDim2.new(1, -16, 0, 140),
        Position = UDim2.new(0, 8, 0, 78),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        Image = "rbxassetid://4155801252",
        BorderSizePixel = 0,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = svMap})

    local svCursor = CreateInstance("Frame", {
        Name = "SVCursor",
        Size = UDim2.new(0, 10, 0, 10),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = svMap,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = svCursor})
    CreateInstance("UIStroke", {Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.3, Parent = svCursor})

    local hueBar = CreateInstance("Frame", {
        Name = "HueBar",
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 8, 0, 226),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = hueBar})
    local hueGradient = CreateInstance("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
        },
        Parent = hueBar
    })
    local hueCursor = CreateInstance("Frame", {
        Name = "HueCursor",
        Size = UDim2.new(0, 6, 1, 4),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = hueBar,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = hueCursor})
    CreateInstance("UIStroke", {Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.3, Parent = hueCursor})

    local alphaBar, alphaCursor, alphaGradient
    if showAlpha then
        alphaBar = CreateInstance("Frame", {
            Name = "AlphaBar",
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 250),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = dialogFrame,
            ZIndex = 1001
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = alphaBar})
        alphaGradient = CreateInstance("UIGradient", {
            Transparency = NumberSequence.new{
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1)
            },
            Parent = alphaBar
        })
        alphaCursor = CreateInstance("Frame", {
            Name = "AlphaCursor",
            Size = UDim2.new(0, 6, 1, 4),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = alphaBar,
            ZIndex = 1002
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = alphaCursor})
        CreateInstance("UIStroke", {Thickness = 2, Color = Color3.new(0, 0, 0), Transparency = 0.3, Parent = alphaCursor})
    end

    local hexInput = CreateInstance("TextBox", {
        Name = "HexInput",
        Size = UDim2.new(1, -16, 0, 28),
        Position = UDim2.new(0, 8, 0, showAlpha and 274 or 250),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Text = "#" .. defaultColor:ToHex(),
        PlaceholderText = "#FFFFFF",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        ClearTextOnFocus = false,
        Parent = dialogFrame,
        ZIndex = 1001
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = hexInput})
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = hexInput})

    local buttonY = showAlpha and 310 or 286
    local buttonContainer = CreateInstance("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -16, 0, 34),
        Position = UDim2.new(0, 8, 0, buttonY),
        BackgroundTransparency = 1,
        Parent = dialogFrame,
        ZIndex = 1001
    })

    local cancelButton = CreateInstance("TextButton", {
        Name = "CancelButton",
        Size = UDim2.new(0.5, -4, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.3,
        Text = cancelText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = cancelButton})

    local confirmButton = CreateInstance("TextButton", {
        Name = "ConfirmButton",
        Size = UDim2.new(0.5, -4, 1, 0),
        Position = UDim2.new(0.5, 4, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BackgroundTransparency = 0.3,
        Text = confirmText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = buttonContainer,
        ZIndex = 1002
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = confirmButton})

    local currentH, currentS, currentV = Color3.toHSV(defaultColor)
    local currentA = defaultAlpha

    local function updatePreview()
        local color = Color3.fromHSV(currentH, currentS, currentV)
        previewFrame.BackgroundColor3 = color
        previewFrame.BackgroundTransparency = 1 - currentA
        svMap.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
        if alphaBar then
            alphaBar.BackgroundColor3 = color
        end
        hexInput.Text = "#" .. color:ToHex()
    end

    local function setHSV(h, s, v)
        currentH = math.clamp(h, 0, 1)
        currentS = math.clamp(s, 0, 1)
        currentV = math.clamp(v, 0, 1)
        svCursor.Position = UDim2.new(currentS, 0, 1 - currentV, 0)
        hueCursor.Position = UDim2.new(currentH, 0, 0, 0)
        updatePreview()
    end

    local function setAlpha(a)
        currentA = math.clamp(a, 0, 1)
        if alphaCursor then
            alphaCursor.Position = UDim2.new(1 - currentA, 0, 0, 0)
        end
        updatePreview()
    end

    setHSV(currentH, currentS, currentV)
    setAlpha(currentA)

    local draggingSV = false
    local draggingHue = false
    local draggingAlpha = false

    svMap.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
        end
    end)
    hueBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
        end
    end)
    if alphaBar then
        alphaBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                draggingAlpha = true
            end
        end)
    end

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            if draggingSV then
                local relX = (pos.X - svMap.AbsolutePosition.X) / svMap.AbsoluteSize.X
                local relY = (pos.Y - svMap.AbsolutePosition.Y) / svMap.AbsoluteSize.Y
                setHSV(currentH, math.clamp(relX, 0, 1), 1 - math.clamp(relY, 0, 1))
            elseif draggingHue then
                local relX = (pos.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X
                setHSV(math.clamp(relX, 0, 1), currentS, currentV)
            elseif draggingAlpha and alphaBar then
                local relX = (pos.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X
                setAlpha(1 - math.clamp(relX, 0, 1))
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = false
            draggingHue = false
            draggingAlpha = false
        end
    end)

    hexInput.FocusLost:Connect(function(enterPressed)
        local hex = hexInput.Text:gsub("#", "")
        local success, color = pcall(Color3.fromHex, hex)
        if success then
            local h, s, v = Color3.toHSV(color)
            setHSV(h, s, v)
        else
            hexInput.Text = "#" .. Color3.fromHSV(currentH, currentS, currentV):ToHex()
        end
    end)

    local function animateOpen()
        dialogFrame.Position = UDim2.new(0.5, -140, 0.5, -dialogHeight/2)
        Tween(dialogFrame, {BackgroundTransparency = 0.3}, 0.2)
        Tween(transparentOverlay, {BackgroundTransparency = 0.5}, 0.2)
    end

    local function animateClose()
        Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
        Tween(transparentOverlay, {BackgroundTransparency = 1}, 0.2)
        task.wait(0.2)
        dialogGui:Destroy()
        for i, d in ipairs(WasUI.ActiveDialogs) do
            if d == dialogGui then
                table.remove(WasUI.ActiveDialogs, i)
                break
            end
        end
    end

    cancelButton.MouseButton1Click:Connect(animateClose)
    confirmButton.MouseButton1Click:Connect(function()
        local finalColor = Color3.fromHSV(currentH, currentS, currentV)
        if callback then
            callback(finalColor, currentA)
        end
        animateClose()
    end)

    transparentOverlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local framePos = dialogFrame.AbsolutePosition
            local frameSize = dialogFrame.AbsoluteSize
            local inPanel = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                            mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
            if not inPanel then
                animateClose()
            end
        end
    end)

    animateOpen()
    table.insert(WasUI.ActiveDialogs, dialogGui)

    return dialogGui
end

function WasUI:CreateColorPickerButton(parent, title, defaultColor, callback, configKey)
    defaultColor = defaultColor or Color3.fromRGB(255, 255, 255)
    local buttonSize = UDim2.new(1, 0, 0, 28)

    local container = CreateInstance("Frame", {
        Name = "ColorPickerButton",
        Size = buttonSize,
        BackgroundTransparency = 1,
        Parent = parent
    })

    local colorPreview = CreateInstance("Frame", {
        Name = "ColorPreview",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -24, 0.5, -12),
        BackgroundColor3 = defaultColor,
        BorderSizePixel = 0,
        Parent = container,
        ZIndex = 2
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = colorPreview})

    local titleLabel
    if title then
        titleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -32, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
            Parent = container
        })
    end

    local button = CreateInstance("TextButton", {
        Name = "Button",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = container,
        ZIndex = 1,
        AutoButtonColor = false
    })

    local currentColor = defaultColor
    local currentAlpha = 1

    local function updatePreview(color, alpha)
        currentColor = color
        currentAlpha = alpha or 1
        colorPreview.BackgroundColor3 = color
        colorPreview.BackgroundTransparency = 1 - currentAlpha
    end

    button.Activated:Connect(function()
        WasUI:ShowColorPicker({
            title = title or "选择颜色",
            defaultColor = currentColor,
            defaultAlpha = currentAlpha,
            showAlpha = true
        }, function(color, alpha)
            updatePreview(color, alpha)
            if callback then
                callback(color, alpha)
            end
            if configKey and WasUI.ConfigManager then
                local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
                if config then
                    config:Set(configKey, {color = color, alpha = alpha})
                    config:Save()
                end
            end
        end)
    end)

    if configKey and WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig(WasUI.ConfigFolderName .. "_settings")
        if config then
            local saved = config:Get(configKey)
            if saved and saved.color then
                updatePreview(saved.color, saved.alpha)
            end
            config:Bind(configKey, container, function(value)
                if value and value.color then
                    updatePreview(value.color, value.alpha)
                end
            end)
        end
    end

    table.insert(WasUI.Objects, {Object = container, Type = "ColorPickerButton"})
    return container
end

local function AnimateThemeChange(oldTheme, newTheme)
    local duration = 0.35
    for i = #WasUI.Objects, 1, -1 do
        local obj = WasUI.Objects[i]
        if not obj.Object or not obj.Object:IsDescendantOf(game) then
            table.remove(WasUI.Objects, i)
        end
    end
    for _, obj in ipairs(WasUI.Objects) do
        local instance = obj.Object
        if not instance then continue end
        if obj.Type == "Button" then
            Tween(instance, {BackgroundColor3 = newTheme.Primary, TextColor3 = newTheme.Text}, duration)
            local icon = instance:FindFirstChildOfClass("ImageLabel")
            if icon and not icon:GetAttribute("IgnoreThemeChange") then
                Tween(icon, {ImageColor3 = newTheme.Text}, duration)
            end
        elseif obj.Type == "Toggle" then
            local toggled = instance:GetAttribute("Toggled")
            if toggled then
                Tween(instance, {BackgroundColor3 = newTheme.Success}, duration)
            else
                local offCol = (newTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
                Tween(instance, {BackgroundColor3 = offCol}, duration)
            end
            local container = instance.Parent
            if container and container:IsA("Frame") then
                local titleLabel = container:FindFirstChild("Title")
                if titleLabel and titleLabel:IsA("TextLabel") then
                    Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
                end
            end
        elseif obj.Type == "ToggleKnob" then
            local knobIcon = instance:FindFirstChildOfClass("ImageLabel")
            if knobIcon and not knobIcon:GetAttribute("IgnoreThemeChange") then
                Tween(knobIcon, {ImageColor3 = newTheme.Text}, duration)
            end
        elseif obj.Type == "Label" then
            Tween(instance, {TextColor3 = newTheme.Text}, duration)
        elseif obj.Type == "Line" then
            Tween(instance, {BackgroundColor3 = newTheme.Primary}, duration)
        elseif obj.Type == "Slider" then
            local titleLabel = instance:FindFirstChild("Title")
            local valueLabel = instance:FindFirstChild("Value")
            local track = instance:FindFirstChild("Track")
            if titleLabel and titleLabel:IsA("TextLabel") then
                Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
            end
            if valueLabel and valueLabel:IsA("TextLabel") then
                Tween(valueLabel, {TextColor3 = newTheme.Text}, duration)
            end
            if track and track:IsA("Frame") then
                Tween(track, {BackgroundColor3 = newTheme.Input}, duration)
                local fill = track:FindFirstChild("Fill")
                if fill and fill:IsA("Frame") then
                    Tween(fill, {BackgroundColor3 = newTheme.Accent}, duration)
                end
                local knob = track:FindFirstChild("Knob")
                if knob and knob:IsA("Frame") then
                    local knobCircle = knob:FindFirstChildOfClass("Frame")
                    if knobCircle then
                        Tween(knobCircle, {BackgroundColor3 = newTheme.Accent}, duration)
                    end
                end
            end
        elseif obj.Type == "ProgressBar" then
            local titleLabel = instance:FindFirstChild("Title")
            local valueLabel = instance:FindFirstChild("Value")
            local track = instance:FindFirstChild("Track")
            if titleLabel then Tween(titleLabel, {TextColor3 = newTheme.Text}, duration) end
            if valueLabel then Tween(valueLabel, {TextColor3 = newTheme.Text}, duration) end
            if track then
                Tween(track, {BackgroundColor3 = newTheme.Input}, duration)
                local fill = track:FindFirstChild("Fill")
                if fill then Tween(fill, {BackgroundColor3 = newTheme.Accent}, duration) end
            end
        elseif obj.Type == "Dropdown" then
            local titleLabel = instance:FindFirstChild("Title")
            local dropdownButton = instance:FindFirstChild("DropdownButton")
            if titleLabel and titleLabel:IsA("TextLabel") then
                Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
            end
            if dropdownButton and dropdownButton:IsA("TextButton") then
                Tween(dropdownButton, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
                local arrow = dropdownButton:FindFirstChild("ArrowIcon")
                if arrow and arrow:IsA("ImageLabel") and not arrow:GetAttribute("IgnoreThemeChange") then
                    Tween(arrow, {ImageColor3 = newTheme.Text}, duration)
                end
            end
        elseif obj.Type == "DropdownOption" then
            Tween(instance, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
        elseif obj.Type == "Category" then
            local titleLabel = instance:FindFirstChild("TitleContainer"):FindFirstChild("Title")
            local line = instance:FindFirstChild("Line")
            local icon = instance:FindFirstChild("TitleContainer"):FindFirstChild("CategoryIcon")
            if titleLabel and titleLabel:IsA("TextLabel") then
                Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
            end
            if line and line:IsA("Frame") then
                Tween(line, {BackgroundColor3 = newTheme.Primary}, duration)
            end
            if icon and icon:IsA("ImageLabel") and not icon:GetAttribute("IgnoreThemeChange") then
                Tween(icon, {ImageColor3 = newTheme.Text}, duration)
            end
        elseif obj.Type == "TextInput" then
            local textBox = instance:FindFirstChild("TextBox")
            if textBox and textBox:IsA("TextBox") then
                Tween(textBox, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
                textBox.PlaceholderColor3 = newTheme.Text
            end
        elseif obj.Type == "Panel" then
            Tween(instance, {BackgroundColor3 = newTheme.Background}, duration)
            local titleBar = instance:FindFirstChild("TitleBar")
            if titleBar then
                Tween(titleBar, {BackgroundColor3 = newTheme.Primary}, duration)
                local title = titleBar:FindFirstChild("Title")
                if not title then
                    local titleContainer = titleBar:FindFirstChild("TitleContainer")
                    if titleContainer then
                        title = titleContainer:FindFirstChild("Title")
                    end
                end
                if title and title:IsA("TextLabel") then
                    Tween(title, {TextColor3 = newTheme.Text}, duration)
                end
                local closeBtn = titleBar:FindFirstChild("CloseButton")
                if closeBtn and closeBtn:IsA("ImageButton") then
                    local icon = closeBtn:FindFirstChildOfClass("ImageLabel")
                    if icon and not icon:GetAttribute("IgnoreThemeChange") then
                        Tween(icon, {ImageColor3 = newTheme.Text}, duration)
                    end
                end
                local searchBtn = titleBar:FindFirstChild("SearchButton")
                if searchBtn and searchBtn:IsA("ImageButton") then
                    local icon = searchBtn:FindFirstChildOfClass("ImageLabel")
                    if icon and not icon:GetAttribute("IgnoreThemeChange") then
                        Tween(icon, {ImageColor3 = newTheme.Text}, duration)
                    end
                end
                local searchContainer = titleBar:FindFirstChild("SearchContainer")
                if searchContainer then
                    local searchBox = searchContainer:FindFirstChild("SearchBox")
                    if searchBox and searchBox:IsA("TextBox") then
                        Tween(searchBox, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
                        searchBox.PlaceholderColor3 = newTheme.Text
                    end
                end
            end
            local announcementBar = instance:FindFirstChild("AnnouncementBar")
            if announcementBar then
                Tween(announcementBar, {BackgroundColor3 = newTheme.Section}, duration)
                local username = announcementBar:FindFirstChild("Username")
                local executorLabel = announcementBar:FindFirstChild("ExecutorLabel")
                local welcomeLabel = announcementBar:FindFirstChild("WelcomeLabel")
                local settingsHint = announcementBar:FindFirstChild("SettingsHint")
                if username and username:IsA("TextLabel") then
                    Tween(username, {TextColor3 = newTheme.Text}, duration)
                end
                if executorLabel and executorLabel:IsA("TextLabel") then
                    Tween(executorLabel, {TextColor3 = newTheme.Text}, duration)
                end
                if welcomeLabel and welcomeLabel:IsA("TextLabel") then
                    Tween(welcomeLabel, {TextColor3 = newTheme.Text}, duration)
                end
                if settingsHint and settingsHint:IsA("TextLabel") then
                    Tween(settingsHint, {TextColor3 = newTheme.Text}, duration)
                end
                local avatar = announcementBar:FindFirstChild("Avatar")
                if avatar and avatar:IsA("ImageButton") then
                    local stroke = avatar:FindFirstChildOfClass("UIStroke")
                    if stroke then
                        Tween(stroke, {Color = newTheme.Text}, duration)
                    end
                end
            end
            local tabBar = instance:FindFirstChild("TabBar")
            if tabBar then
                Tween(tabBar, {BackgroundColor3 = newTheme.Primary}, duration)
                local tabContainer = tabBar:FindFirstChild("TabContainer")
                if tabContainer then
                    for _, btn in ipairs(tabContainer:GetChildren()) do
                        if btn:IsA("TextButton") then
                            Tween(btn, {BackgroundColor3 = newTheme.TabButton, TextColor3 = newTheme.Text}, duration)
                            local underline = btn:FindFirstChild("Underline")
                            if underline and underline:IsA("Frame") then
                                Tween(underline, {BackgroundColor3 = newTheme.Accent}, duration)
                            end
                        end
                    end
                end
            end
            local panelData = obj.PanelData
            if panelData then
                local dotContainer = panelData.DotContainer
                if dotContainer then
                    local minimizedTextLabel = dotContainer:FindFirstChild("MinimizedText")
                    if minimizedTextLabel and minimizedTextLabel:IsA("TextLabel") then
                        if newTheme == WasUI.Themes.Light then
                            Tween(minimizedTextLabel, {TextColor3 = Color3.fromRGB(0, 0, 0)}, duration)
                        else
                            Tween(minimizedTextLabel, {TextColor3 = newTheme.Text}, duration)
                        end
                    end
                end
                
                local titleTagContainers = panelData.TitleTagContainers
                if titleTagContainers then
                    for _, tagContainer in ipairs(titleTagContainers) do
                        if tagContainer and tagContainer:IsDescendantOf(game) then
                            local tagLabel = tagContainer:FindFirstChild("TagLabel")
                            if tagLabel and tagLabel:IsA("TextLabel") then
                                Tween(tagLabel, {TextColor3 = newTheme.Text}, duration)
                            end
                        end
                    end
                end
            end
        elseif obj.Type == "ColorPickerButton" then
            local titleLabel = instance:FindFirstChild("Title")
            if titleLabel and titleLabel:IsA("TextLabel") then
                Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
            end
        elseif obj.Type == "TabArrow" then
            Tween(instance, {ImageColor3 = newTheme.Text}, duration)
        end
    end
    if WasUI.DropdownGui then
        for _, container in ipairs(WasUI.DropdownGui:GetChildren()) do
            if container:IsA("ScrollingFrame") then
                Tween(container, {BackgroundColor3 = newTheme.Background}, duration)
                for _, btn in ipairs(container:GetChildren()) do
                    if btn:IsA("TextButton") then
                        Tween(btn, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
                    end
                end
            end
        end
    end
    for _, data in pairs(WasUI.ActiveNotifications) do
        local frame = data.Frame
        if frame then
            local titleLabel = frame:FindFirstChild("Title")
            local contentLabel = frame:FindFirstChild("Content")
            if titleLabel then Tween(titleLabel, {TextColor3 = newTheme.Text}, duration) end
            if contentLabel then Tween(contentLabel, {TextColor3 = newTheme.Text}, duration) end
            Tween(frame, {BackgroundColor3 = newTheme.Section}, duration)
            local stroke = frame:FindFirstChildOfClass("UIStroke")
            if stroke then Tween(stroke, {Color = newTheme.Text}, duration) end
        end
    end
    if WasUI.SnowContainer then
        for _, flake in ipairs(WasUI.Snowflakes or {}) do
            if flake.Instance then
                Tween(flake.Instance, {BackgroundColor3 = newTheme.SnowColor}, duration)
            end
        end
    end
    for _, shortcut in pairs(WasUI.ShortcutButtons) do
        if shortcut.button then
            Tween(shortcut.button, {BackgroundColor3 = newTheme.Primary}, duration)
            local text = shortcut.button:FindFirstChild("Text")
            if text then Tween(text, {TextColor3 = newTheme.Text}, duration) end
            local indicator = shortcut.button:FindFirstChild("Indicator")
            if indicator then
                local toggled = indicator:GetAttribute("State")
                if toggled then
                    Tween(indicator, {BackgroundColor3 = newTheme.Success}, duration)
                else
                    Tween(indicator, {BackgroundColor3 = newTheme.Error}, duration)
                end
            end
            local stroke = shortcut.button:FindFirstChildOfClass("UIStroke")
            if stroke then Tween(stroke, {Color = newTheme.Accent}, duration) end
        end
    end
    for _, dialogGui in ipairs(WasUI.ActiveDialogs) do
        if dialogGui and dialogGui.Parent then
            local overlay = dialogGui:FindFirstChild("Overlay")
            local dialogFrame = overlay and overlay:FindFirstChild("Dialog")
            if dialogFrame then
                Tween(dialogFrame, {BackgroundColor3 = newTheme.Background}, duration)
                local titleLabel = dialogFrame:FindFirstChild("Title")
                if titleLabel then Tween(titleLabel, {TextColor3 = newTheme.Text}, duration) end
                local descriptionLabel = dialogFrame:FindFirstChild("Description")
                if descriptionLabel then Tween(descriptionLabel, {TextColor3 = newTheme.Text}, duration) end
                local inputBox = dialogFrame:FindFirstChild("InputBox")
                if inputBox then
                    Tween(inputBox, {BackgroundColor3 = newTheme.Input, TextColor3 = newTheme.Text}, duration)
                    inputBox.PlaceholderColor3 = newTheme.Text
                end
                local cancelBtn = dialogFrame:FindFirstChild("ButtonContainer") and dialogFrame.ButtonContainer:FindFirstChild("CancelButton")
                local confirmBtn = dialogFrame:FindFirstChild("ButtonContainer") and dialogFrame.ButtonContainer:FindFirstChild("ConfirmButton")
                if cancelBtn then Tween(cancelBtn, {BackgroundColor3 = newTheme.Section, TextColor3 = newTheme.Text}, duration) end
                if confirmBtn then Tween(confirmBtn, {BackgroundColor3 = newTheme.Accent, TextColor3 = newTheme.Text}, duration) end
                local stroke = dialogFrame:FindFirstChildOfClass("UIStroke")
                if stroke then Tween(stroke, {Color = newTheme.Text}, duration) end
            end
        end
    end
end

function WasUI:SetTheme(themeName)
    if self.Themes[themeName] then
        local oldTheme = self.CurrentTheme
        local newTheme = self.Themes[themeName]
        self.CurrentTheme = newTheme
        self.CurrentThemeName = themeName
        AnimateThemeChange(oldTheme, newTheme)
        
        for _, obj in ipairs(WasUI.Objects) do
            if obj.Type == "Panel" and obj.Object then
                local announcementBar = obj.Object:FindFirstChild("AnnouncementBar")
                if announcementBar then
                    announcementBar.BackgroundColor3 = newTheme.Section
                    local username = announcementBar:FindFirstChild("Username")
                    local executorLabel = announcementBar:FindFirstChild("ExecutorLabel")
                    local welcomeLabel = announcementBar:FindFirstChild("WelcomeLabel")
                    local settingsHint = announcementBar:FindFirstChild("SettingsHint")
                    if username then username.TextColor3 = newTheme.Text end
                    if executorLabel then executorLabel.TextColor3 = newTheme.Text end
                    if welcomeLabel then welcomeLabel.TextColor3 = newTheme.Text end
                    if settingsHint then settingsHint.TextColor3 = newTheme.Text end
                    local avatar = announcementBar:FindFirstChild("Avatar")
                    if avatar then
                        local stroke = avatar:FindFirstChildOfClass("UIStroke")
                        if stroke then stroke.Color = newTheme.Text end
                    end
                end
            end
        end
        
        if self.SettingsPanel then
            local themeDropdown = self.SettingsPanel:FindFirstChild("Content") and self.SettingsPanel.Content:FindFirstChild("ThemeDropdown")
            if themeDropdown and themeDropdown:IsA("TextButton") then
                themeDropdown.Text = themeName
            end
        end
        return true
    end
    return false
end

local Panel = {}
Panel.__index = Panel

function Panel.__index(self, key)
    if key == "orderFlow" then
        return rawget(self, "BorderFlow")
    end
    return Panel[key]
end

local function isPointOverButton(btn, point)
    if not btn or not btn.Parent then return false end
    local absPos = btn.AbsolutePosition
    local absSize = btn.AbsoluteSize
    return point.X >= absPos.X and point.X <= absPos.X + absSize.X and
           point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y
end

function Panel:New(name, parent, size, position, backgroundUrl, snowEnabled, titleTag)
    local self = setmetatable({}, Panel)
    self.SnowEnabled = snowEnabled or false
    self.BackgroundImage = nil
    function self:SetBackground(url)
        if self.BackgroundImage then
            self.BackgroundImage:Destroy()
        end
        if url and url ~= "" then
            self.BackgroundImage = CreateInstance("ImageLabel", {
                Name = "Background",
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0),
                BackgroundTransparency = 1,
                Image = "",
                ImageTransparency = 0.2,
                ScaleType = Enum.ScaleType.Crop,
                ZIndex = 0,
                Parent = self.Instance
            })
            ContentProvider:PreloadAsync({url})
            self.BackgroundImage.Image = url
        else
            self.BackgroundImage = nil
        end
    end
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = size or UDim2.new(0, 380, 0, 350),
        Position = position or UDim2.new(0.5, -190, 0.5, -175),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 0.3,
        ClipsDescendants = true,
        ZIndex = 1,
        Parent = parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Instance})
    
    if backgroundUrl and backgroundUrl ~= "" then
        self:SetBackground(backgroundUrl)
    end

    AddRipple(self.Instance)

    self.BorderFlow = CreateInstance("Frame", {
        Name = "BorderFlow",
        Size = UDim2.new(0, self.Instance.AbsoluteSize.X + 4, 0, self.Instance.AbsoluteSize.Y + 4),
        Position = UDim2.new(0, self.Instance.AbsolutePosition.X - 2, 0, self.Instance.AbsolutePosition.Y - 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = -1,
        Parent = self.Instance.Parent
    })
    local borderFlowCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.BorderFlow})
    local flowGradient = Instance.new("UIGradient")
    flowGradient.Rotation = 0
    flowGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
        ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 165, 0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 0)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0, 255, 255)),
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(0, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 255))
    }
    flowGradient.Parent = self.BorderFlow
    local highlightStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(255, 255, 255),
        Thickness = 1,
        Transparency = 0.7,
        Parent = self.BorderFlow
    })
    local highlightGradient = Instance.new("UIGradient")
    highlightGradient.Rotation = 45
    highlightGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    }
    highlightGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 0.9)
    }
    highlightGradient.Parent = highlightStroke

    self.BorderStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        Transparency = 0,
        Parent = self.BorderFlow
    })
    self.BorderFlow.Visible = false

    local function updateBorder()
        if not self.Instance or not self.BorderFlow then return end
        self.BorderFlow.Position = UDim2.new(0, self.Instance.AbsolutePosition.X - 2, 0, self.Instance.AbsolutePosition.Y - 2)
        self.BorderFlow.Size = UDim2.new(0, self.Instance.AbsoluteSize.X + 4, 0, self.Instance.AbsoluteSize.Y + 4)
    end
    self.Instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBorder)
    self.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBorder)
    updateBorder()

    local borderTime = 0
    self.RainbowMode = WasUI.DefaultRainbowMode
    self.FlowRotation = 0
    self.BorderConnection = nil

    local function startFlowAnimation()
        if self.BorderConnection then self.BorderConnection:Disconnect() end
        self.BorderConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if self.RainbowMode == "整体" then
                borderTime = borderTime + deltaTime * 4
                local r = (math.sin(borderTime) + 1) / 2
                local g = (math.sin(borderTime + math.pi/3) + 1) / 2
                local b = (math.sin(borderTime + 2*math.pi/3) + 1) / 2
                self.BorderStroke.Color = Color3.new(r, g, b)
                self.BorderStroke.Transparency = 0
                flowGradient.Enabled = false
            else
                self.FlowRotation = (self.FlowRotation + deltaTime * 45) % 360
                flowGradient.Rotation = self.FlowRotation
                flowGradient.Enabled = true
                self.BorderStroke.Transparency = 1
            end
        end)
    end

    function self:SetRainbowMode(mode)
        if mode == "整体" or mode == "流动" then
            self.RainbowMode = mode
            if mode == "整体" then
                self.BorderFlow.BackgroundTransparency = 1
                self.BorderStroke.Enabled = true
                flowGradient.Enabled = false
                highlightStroke.Enabled = true
            else
                self.BorderFlow.BackgroundTransparency = 0
                self.BorderStroke.Enabled = false
                flowGradient.Enabled = true
                highlightStroke.Enabled = true
            end
            self.BorderFlow.Visible = true
            startFlowAnimation()
        end
    end

    function self:SetRainbowEnabled(enabled)
        self.BorderFlow.Visible = enabled
        if enabled then
            startFlowAnimation()
        elseif self.BorderConnection then
            self.BorderConnection:Disconnect()
            self.BorderConnection = nil
        end
    end

    startFlowAnimation()
    self:SetRainbowMode(self.RainbowMode)

    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Instance
    })
    CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 14),
        Parent = self.TitleBar
    })

    self.DraggableArea = CreateInstance("TextButton", {
        Name = "DraggableArea",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 1,
        Parent = self.TitleBar
    })
self.Title = CreateInstance("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -140, 1, 0),
    Position = UDim2.new(0, 54, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = WasUI.CurrentTheme.Text,
    TextTransparency = 0,
    Font = Enum.Font.GothamSemibold,
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.None,
    AutomaticSize = Enum.AutomaticSize.X,
    Active = false,
    ZIndex = 2,
    Parent = self.TitleBar
})
WasUI:SetLocalizedText(self.Title, name)
    
    local titleTagsList = {}
    if type(titleTag) == "table" then
        if titleTag[1] then
            titleTagsList = titleTag
        else
            titleTagsList = {titleTag}
        end
    elseif titleTag then
        titleTagsList = {titleTag}
    end

    if #titleTagsList > 0 then
        local titleContainer = CreateInstance("Frame", {
            Name = "TitleContainer",
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, 60, 0, 0),
            BackgroundTransparency = 1,
            Parent = self.TitleBar,
            ZIndex = 2
        })
        self.TitleContainer = titleContainer
        local titleLayout = CreateInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = titleContainer
        })
        self.Title.Parent = titleContainer
        self.Title.Size = UDim2.new(0, self.Title.TextBounds.X, 1, 0)
        self.Title.TextXAlignment = Enum.TextXAlignment.Left
        self.Title.Position = UDim2.new(0, 0, 0, 0)
        local function updateTitleWidth()
            self.Title.Size = UDim2.new(0, self.Title.TextBounds.X, 1, 0)
        end
        self.Title:GetPropertyChangedSignal("TextBounds"):Connect(updateTitleWidth)
        updateTitleWidth()

        local tagContainers = {}
        for _, tag in ipairs(titleTagsList) do
            local tagContainer = CreateInstance("Frame", {
                Name = "TitleTagContainer",
                Size = UDim2.new(0, 0, 0, 18),
                BackgroundColor3 = tag.backgroundColor or WasUI.CurrentTheme.Accent,
                BackgroundTransparency = 0.2,
                BorderSizePixel = 0,
                Parent = titleContainer,
                ZIndex = 10
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = tagContainer})
            local tagLabel = CreateInstance("TextLabel", {
                Name = "TagLabel",
                Size = UDim2.new(1, -6, 1, 0),
                Position = UDim2.new(0, 3, 0, 0),
                BackgroundTransparency = 1,
                Text = tag.text,
                TextColor3 = tag.textColor or WasUI.CurrentTheme.Text,
                Font = Enum.Font.GothamSemibold,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = tagContainer,
                ZIndex = 11
            })
            task.wait()
            local textWidth = tagLabel.TextBounds.X
            tagContainer.Size = UDim2.new(0, textWidth + 8, 0, 18)
            tagLabel.Size = UDim2.new(0, textWidth, 1, 0)
            table.insert(tagContainers, tagContainer)
        end
        self.TitleTagContainers = tagContainers
    else
        self.Title.Size = UDim2.new(1, -140, 1, 0)
        self.Title.Position = UDim2.new(0, 54, 0, 0)
    end

    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 10, 0, 0.8),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = self.TitleBar
    })
    self.DotAreaButton = CreateInstance("ImageButton", {
        Name = "DotAreaButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = self.DotContainer
    })
    self.CloseDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 1.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    self.MinimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 16.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    self.MaximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 31.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    for _, dot in ipairs({self.CloseDot, self.MinimizeDot, self.MaximizeDot}) do
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dot})
    end
    self.MinimizedTextLabel = CreateInstance("TextLabel", {
        Name = "MinimizedText",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 5, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = (WasUI.CurrentTheme == WasUI.Themes.Light) and Color3.fromRGB(0, 0, 0) or WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Visible = false,
        ZIndex = 10,
        Parent = self.DotContainer
    })
    self.MinimizedCustomText = ""
    function self:SetMinimizedText(text)
        self.MinimizedCustomText = text or ""
        self.MinimizedTextLabel.Text = text or ""
    end
    function self:SetMinimizedTextColor(color)
        self.MinimizedTextLabel.TextColor3 = color or WasUI.CurrentTheme.Text
    end
    local searchContainer = CreateInstance("Frame", {
        Name = "SearchContainer",
        Size = UDim2.new(0, 0, 0, 20),
        Position = UDim2.new(1, -156, 0, 3),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 30,
        Parent = self.TitleBar
    })
    local searchBox = CreateInstance("TextBox", {
        Name = "SearchBox",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        PlaceholderText = "",
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 31,
        Parent = searchContainer
    })
    WasUI:SetLocalizedText(searchBox, "搜索...", "PlaceholderText")
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = searchBox})
    local searchPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = searchBox
    })
    local closeButton = CreateInstance("ImageButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0, 2),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 40,
        Parent = self.TitleBar
    })
    local iconColor = (WasUI.CurrentTheme == WasUI.Themes.Light) and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(255, 255, 255)
    local closeIcon = WasUI:CreateIcon("circle-x", UDim2.new(0, 18, 0, 18), iconColor, true)
    if closeIcon then
        closeIcon.Parent = closeButton
        closeIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    end
    local searchButton = CreateInstance("ImageButton", {
        Name = "SearchButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -56, 0, 2),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 40,
        Parent = self.TitleBar
    })
    local searchIcon = WasUI:CreateIcon("search", UDim2.new(0, 18, 0, 18), iconColor, true)
    if searchIcon then
        searchIcon.Parent = searchButton
        searchIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    end
    local isSearchActive = false
    local autoCloseTimer = nil
    local searchResultTab = nil
    local originalTabButtons = {}
    local originalTabFrames = {}
    local originalActiveTab = nil
    local movedControls = {}
    local function storeOriginalTabs()
        originalTabButtons = {}
        originalTabFrames = {}
        for tabName, tabData in pairs(self.Tabs) do
            originalTabButtons[tabName] = tabData.Button
            originalTabFrames[tabName] = tabData.Frame
        end
        originalActiveTab = self.ActiveTab
    end
    local function restoreOriginalTabs()
        if searchResultTab then
            if searchResultTab.Button then
                searchResultTab.Button:Destroy()
            end
            if searchResultTab.Frame then
                searchResultTab.Frame:Destroy()
            end
            searchResultTab = nil
        end
        for tabName, btn in pairs(originalTabButtons) do
            local frame = originalTabFrames[tabName]
            if frame then
                frame.Parent = self.ContentArea
                frame.Visible = true
            end
            if btn then
                btn.Parent = self.TabContainer
            end
        end
        for _, moved in ipairs(movedControls) do
            if moved.control and moved.control.Parent ~= moved.originalParent then
                moved.control.Parent = moved.originalParent
                moved.control.Visible = true
            end
        end
        movedControls = {}
        self.Tabs = {}
        for tabName, btn in pairs(originalTabButtons) do
            local frame = originalTabFrames[tabName]
            self.Tabs[tabName] = {
                Button = btn,
                Underline = btn:FindFirstChild("Underline"),
                Frame = frame
            }
        end
        originalTabButtons = {}
        originalTabFrames = {}
        if originalActiveTab and self.Tabs[originalActiveTab] then
            self:SetActiveTab(originalActiveTab)
        elseif next(self.Tabs) then
            local firstTab = next(self.Tabs)
            self:SetActiveTab(firstTab)
        end
        if self.ContentArea and self.ContentArea.UIListLayout then
            task.wait()
            self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, self.ContentArea.UIListLayout.AbsoluteContentSize.Y + 8)
        end
        isSearchActive = false
    end
    local function collectSearchableControls()
        local controls = {}
        for tabName, frame in pairs(originalTabFrames) do
            local function collectFromFrame(frameObj)
                for _, child in ipairs(frameObj:GetChildren()) do
                    if child:IsA("TextButton") or child:IsA("Frame") or child:IsA("TextBox") then
                        local isLabel = child:IsA("TextLabel") and child:GetAttribute("IsLabel")
                        if not isLabel then
                            local searchText = child:GetAttribute("SearchText")
                            if not searchText and child:IsA("TextButton") then
                                searchText = child.Text
                            elseif not searchText and child:IsA("TextBox") then
                                searchText = child.Text
                            end
                            if searchText and searchText ~= "" then
                                table.insert(controls, {
                                    Instance = child,
                                    SearchText = searchText,
                                    TabName = tabName,
                                    OriginalParent = child.Parent
                                })
                            end
                        end
                        if child:IsA("Frame") and child.Name ~= "Spacing" and not child:IsA("ScrollingFrame") then
                            collectFromFrame(child)
                        end
                    end
                end
            end
            collectFromFrame(frame)
        end
        return controls
    end
    local function performSearch(keyword)
        if keyword == "" then
            if isSearchActive then
                restoreOriginalTabs()
                isSearchActive = false
            end
            return
        end
        if isSearchActive then
            restoreOriginalTabs()
            isSearchActive = false
        end
        storeOriginalTabs()
        for tabName, tabData in pairs(self.Tabs) do
            tabData.Button.Parent = nil
            tabData.Frame.Parent = nil
        end
        self.Tabs = {}
        local resultButton = CreateInstance("TextButton", {
            Name = "Tab_搜索结果",
            Size = UDim2.new(0, 90, 0, 24),
            BackgroundColor3 = WasUI.CurrentTheme.TabButton,
            BackgroundTransparency = 0.5,
            Text = WasUI:Translate("搜索结果"),
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = 999,
            ZIndex = 2,
            Parent = self.TabContainer
        })
        table.insert(WasUI.Objects, {Object = resultButton, Type = "TabButton"})
        local resultUnderline = CreateInstance("Frame", {
            Name = "Underline",
            Size = UDim2.new(0, 0, 0, 2),
            Position = UDim2.new(0.5, 0, 1, -2),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = WasUI.CurrentTheme.Accent,
            Visible = true,
            ZIndex = 2,
            Parent = resultButton
        })
        local resultFrame = CreateInstance("Frame", {
            Name = "TabFrame_搜索结果",
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
            Parent = self.ContentArea
        })
        local resultLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = resultFrame
        })
        local resultPadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = resultFrame
        })
        searchResultTab = {
            Button = resultButton,
            Underline = resultUnderline,
            Frame = resultFrame
        }
        self.Tabs["搜索结果"] = searchResultTab
        self:SetActiveTab("搜索结果")
        for _, moved in ipairs(movedControls) do
            if moved.control and moved.control.Parent then
                moved.control.Parent = moved.originalParent
            end
        end
        movedControls = {}
        for _, child in ipairs(searchResultTab.Frame:GetChildren()) do
            if child.Name ~= "Spacing" then
                child:Destroy()
            end
        end
        local allControls = collectSearchableControls()
        local matchedControls = {}
        for _, control in ipairs(allControls) do
            if control.SearchText and control.SearchText:lower():find(keyword:lower()) then
                table.insert(matchedControls, control)
            end
        end
        for _, control in ipairs(matchedControls) do
            local originalParent = control.Instance.Parent
            control.Instance.Parent = searchResultTab.Frame
            table.insert(movedControls, {
                control = control.Instance,
                originalParent = originalParent
            })
        end
        local spacing = Instance.new("Frame")
        spacing.Name = "Spacing"
        spacing.Size = UDim2.new(1, 0, 0, 4)
        spacing.BackgroundTransparency = 1
        spacing.Parent = searchResultTab.Frame
        isSearchActive = true
    end
    local function resetAutoCloseTimer()
        if autoCloseTimer then
            task.cancel(autoCloseTimer)
            autoCloseTimer = nil
        end
        if isSearchActive and searchBox.Text == "" then
            autoCloseTimer = task.delay(2.5, function()
                if searchBox.Text == "" then
                    expandSearchBox(false)
                end
                autoCloseTimer = nil
            end)
        end
    end
    local function expandSearchBox(expand)
        if expand then
            if autoCloseTimer then
                task.cancel(autoCloseTimer)
                autoCloseTimer = nil
            end
            searchContainer.Visible = true
            local targetWidth = 120
            Tween(searchContainer, {Size = UDim2.new(0, targetWidth, 0, 20)}, 0.25)
            task.wait(0.25)
            searchBox:CaptureFocus()
        else
            if autoCloseTimer then
                task.cancel(autoCloseTimer)
                autoCloseTimer = nil
            end
            Tween(searchContainer, {Size = UDim2.new(0, 0, 0, 20)}, 0.25)
            task.wait(0.25)
            searchContainer.Visible = false
            searchBox.Text = ""
            performSearch("")
        end
    end
    searchButton.MouseButton1Click:Connect(function()
        if isSearchActive then
            expandSearchBox(false)
        else
            expandSearchBox(true)
            resetAutoCloseTimer()
        end
    end)
    searchBox.FocusLost:Connect(function()
        if searchBox.Text == "" then
            resetAutoCloseTimer()
        end
    end)
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        performSearch(searchBox.Text)
        if searchBox.Text == "" then
            resetAutoCloseTimer()
        else
            if autoCloseTimer then
                task.cancel(autoCloseTimer)
                autoCloseTimer = nil
            end
        end
    end)
    self.IsMinimized = false
    self.OriginalSize = self.Instance.Size
    self.MinimizedSize = UDim2.new(0, 60, 0, 26)
    self.MinimizeToDots = function()
        if self.IsMinimized then return end
        
        for i = #WasUI.OpenDropdowns, 1, -1 do
            local dropdown = WasUI.OpenDropdowns[i]
            if dropdown and dropdown.Close then
                dropdown:Close(true)
            end
        end
        
        if isSearchActive then
            expandSearchBox(false)
        end
        
        for _, dialogGui in ipairs(WasUI.ActiveDialogs) do
            if dialogGui and dialogGui.Parent then
                local overlay = dialogGui:FindFirstChild("Overlay")
                if overlay then
                    Tween(overlay, {BackgroundTransparency = 1}, 0.2)
                    local dialogFrame = overlay:FindFirstChild("Dialog")
                    if dialogFrame then
                        Tween(dialogFrame, {BackgroundTransparency = 1, Position = UDim2.new(0.5, -200, 0.5, -150 + 20)}, 0.2)
                    end
                end
                task.delay(0.2, function()
                    dialogGui:Destroy()
                end)
            end
        end
        WasUI.ActiveDialogs = {}
        
        if WasUI.SettingsGui then
            Tween(WasUI.SettingsPanel, {BackgroundTransparency = 1}, 0.2)
            Tween(WasUI.SettingsPanel:FindFirstChildWhichIsA("UIScale"), {Scale = 0.8}, 0.2)
            task.delay(0.2, function()
                if WasUI.SettingsGui then
                    WasUI.SettingsGui:Destroy()
                    WasUI.SettingsGui = nil
                end
                WasUI.SettingsPanel = nil
            end)
        end
        
        local tweenDuration = 0.3
        local dots = {self.CloseDot, self.MinimizeDot, self.MaximizeDot}
        for _, dot in ipairs(dots) do
            Tween(dot, {BackgroundTransparency = 1}, tweenDuration)
        end
        if self.MinimizedCustomText ~= "" then
            self.MinimizedTextLabel.Visible = true
            self.MinimizedTextLabel.TextTransparency = 1
            Tween(self.MinimizedTextLabel, {TextTransparency = 0}, tweenDuration)
        end
        Tween(self.Instance, {
            Size = self.MinimizedSize,
            Position = self.Instance.Position
        }, tweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        if self.TitleContainer then
            self.TitleContainer.Visible = false
        elseif self.Title then
            self.Title.Visible = false
        end
        if self.AnnouncementBar then self.AnnouncementBar.Visible = false end
        if self.TabBar then self.TabBar.Visible = false end
        if self.ContentArea then self.ContentArea.Visible = false end
        if closeButton then closeButton.Visible = false end
        if searchButton then searchButton.Visible = false end
        if searchContainer then searchContainer.Visible = false end
        if self.DraggableArea then self.DraggableArea.Visible = false end
        if self.DotContainer then self.DotContainer.Visible = true end
        if self.SnowContainer then self.SnowContainer.Visible = false end
        
        self.IsMinimized = true
    end
    self.RestoreFromDots = function()
        if not self.IsMinimized then return end
        local tweenDuration = 0.3
        local dots = {self.CloseDot, self.MinimizeDot, self.MaximizeDot}
        for _, dot in ipairs(dots) do
            Tween(dot, {BackgroundTransparency = 0}, tweenDuration)
        end
        if self.MinimizedCustomText ~= "" then
            Tween(self.MinimizedTextLabel, {TextTransparency = 1}, tweenDuration)
            task.delay(tweenDuration, function()
                self.MinimizedTextLabel.Visible = false
            end)
        end
        Tween(self.Instance, {
            Size = self.OriginalSize,
            Position = self.Instance.Position
        }, tweenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        if self.TitleContainer then
            self.TitleContainer.Visible = true
        elseif self.Title then
            self.Title.Visible = true
        end
        if self.AnnouncementBar then self.AnnouncementBar.Visible = true end
        if self.TabBar then self.TabBar.Visible = true end
        if self.ContentArea then self.ContentArea.Visible = true end
        if closeButton then closeButton.Visible = true end
        if searchButton then searchButton.Visible = true end
        if self.DraggableArea then self.DraggableArea.Visible = true end
        if self.DotContainer then self.DotContainer.Visible = true end
        if self.SnowContainer then self.SnowContainer.Visible = true end
        
        self.IsMinimized = false
    end
    self.DotAreaButton.MouseButton1Click:Connect(function()
        if self.IsMinimized then
            self:RestoreFromDots()
        else
            self:MinimizeToDots()
        end
    end)
    self.CloseDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetVisible(false)
        end
    end)
    self.MinimizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.IsMinimized then
                self:RestoreFromDots()
            else
                self:MinimizeToDots()
            end
        end
    end)
    self.MaximizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
        end
    end)
    closeButton.MouseButton1Click:Connect(function()
        local overlay = CreateInstance("Frame", {
            Name = "Overlay",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = true,
            Active = true,
            ZIndex = 10000,
            Parent = self.Instance
        })
        local dialogFrame = CreateInstance("Frame", {
            Name = "Dialog",
            Size = UDim2.new(0, 400, 0, 260),
            Position = UDim2.new(0.5, -200, 0.5, -130),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = overlay,
            ZIndex = 10001
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = dialogFrame})
        local titleText = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -20, 0, 50),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            TextTransparency = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = dialogFrame,
            ZIndex = 10002
        })
        WasUI:SetLocalizedText(titleText, WasUI.DialogTitle)
        local versionLabel = CreateInstance("TextLabel", {
            Name = "VersionLabel",
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 0, 60),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            TextTransparency = 0,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = dialogFrame,
            ZIndex = 10002
        })
        versionLabel.Text = WasUI:Translate("当前WasUI版本: ") .. WasUI.Version
        local buttonContainer = CreateInstance("Frame", {
            Name = "ButtonContainer",
            Size = UDim2.new(1, -20, 0, 50),
            Position = UDim2.new(0, 10, 1, -60),
            BackgroundTransparency = 1,
            Parent = dialogFrame,
            ZIndex = 10002
        })
        local buttonLayout = CreateInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 15),
            Parent = buttonContainer
        })
        local confirmButton = CreateInstance("TextButton", {
            Name = "Confirm",
            Size = UDim2.new(0, 110, 0, 36),
            BackgroundColor3 = WasUI.CurrentTheme.Section,
            BackgroundTransparency = 0.3,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Error,
            TextTransparency = 0,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            AutoButtonColor = true,
            Parent = buttonContainer,
            ZIndex = 10003
        })
        WasUI:SetLocalizedText(confirmButton, "确认关闭")
        local cancelButton = CreateInstance("TextButton", {
            Name = "Cancel",
            Size = UDim2.new(0, 110, 0, 36),
            BackgroundColor3 = WasUI.CurrentTheme.Section,
            BackgroundTransparency = 0.3,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            TextTransparency = 0,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            AutoButtonColor = true,
            Parent = buttonContainer,
            ZIndex = 10003
        })
        WasUI:SetLocalizedText(cancelButton, "取消")
        for _, btn in ipairs({confirmButton, cancelButton}) do
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 18), Parent = btn})
            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Section}, 0.2)
            end)
        end
        Tween(dialogFrame, {BackgroundTransparency = 0.3}, 0.2)
        Tween(overlay, {BackgroundTransparency = 0.5}, 0.3)
        confirmButton.MouseButton1Click:Connect(function()
            if self.BorderConnection then
                self.BorderConnection:Disconnect()
                self.BorderConnection = nil
            end
            if self.BorderFlow then
                self.BorderFlow:Destroy()
            end
            for _, data in pairs(WasUI.ActiveRainbowTexts) do
                if data.ScreenGui then data.ScreenGui:Destroy() end
            end
            WasUI.ActiveRainbowTexts = {}
            WasUI.RainbowOrder = {}
            WasUI:ClearAllShortcuts()
            for _, dialogGui in ipairs(WasUI.ActiveDialogs) do
                if dialogGui then dialogGui:Destroy() end
            end
            WasUI.ActiveDialogs = {}
            if WasUI.SettingsGui then
                WasUI.SettingsGui:Destroy()
                WasUI.SettingsGui = nil
            end
            WasUI.SettingsPanel = nil
            self:SetVisible(false)
            overlay:Destroy()
            if WasUI.DropdownGui then
                WasUI.DropdownGui:Destroy()
                WasUI.DropdownGui = nil
            end
            if WasUI.NotificationGui then
                WasUI.NotificationGui:Destroy()
                WasUI.NotificationGui = nil
            end
        end)
        cancelButton.MouseButton1Click:Connect(function()
            Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
            Tween(overlay, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.2)
            overlay:Destroy()
        end)
        local function onOverlayClick(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                local framePos = dialogFrame.AbsolutePosition
                local frameSize = dialogFrame.AbsoluteSize
                local inPanel = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                                mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
                if not inPanel then
                    Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
                    Tween(overlay, {BackgroundTransparency = 1}, 0.2)
                    task.wait(0.2)
                    overlay:Destroy()
                end
            end
        end
        overlay.InputBegan:Connect(onOverlayClick)
    end)
    
    local dragging = false
    local dragRenderConn = nil
    local dragEndConn = nil
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    local currentDragTouch = nil
    
    local function isPointOverDraggableArea(point)
        local targetArea = self.IsMinimized and self.DotContainer or self.DraggableArea
        if not targetArea or not targetArea.Parent then return false end
        local absPos = targetArea.AbsolutePosition
        local absSize = targetArea.AbsoluteSize
        if self.IsMinimized then
            return point.X >= absPos.X and point.X <= absPos.X + absSize.X and
                   point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y
        else
            local hitCloseDot = isPointOverButton(self.CloseDot, point)
            local hitMinimizeDot = isPointOverButton(self.MinimizeDot, point)
            local hitMaximizeDot = isPointOverButton(self.MaximizeDot, point)
            local hitCloseBtn = isPointOverButton(closeButton, point)
            local hitSearchBtn = isPointOverButton(searchButton, point)
            return point.X >= absPos.X and point.X <= absPos.X + absSize.X and
                   point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y and
                   not (hitCloseDot or hitMinimizeDot or hitMaximizeDot or hitCloseBtn or hitSearchBtn)
        end
    end
    
    local function startDrag(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            if isPointOverDraggableArea(mousePos) then
                dragging = true
                dragStart = input.Position
                startPos = self.Instance.Position
                currentDragTouch = nil
                if dragRenderConn then dragRenderConn:Disconnect() end
                dragRenderConn = RunService.RenderStepped:Connect(function()
                    if dragging then
                        local delta = UserInputService:GetMouseLocation() - dragStart
                        local newX = startPos.X.Offset + delta.X
                        local newY = startPos.Y.Offset + delta.Y
                        self.Instance.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                    end
                end)
                if not self.IsMinimized and self.SnowEnabled then
                    self.SnowEnabled = false
                    if self.SnowContainer then
                        self.SnowContainer.Visible = false
                    end
                end
            end
        elseif input.UserInputType == Enum.UserInputType.Touch then
            local touchPos = input.Position
            if isPointOverDraggableArea(touchPos) then
                dragging = true
                dragStart = input.Position
                startPos = self.Instance.Position
                currentDragTouch = input
                if dragRenderConn then dragRenderConn:Disconnect() end
                dragRenderConn = RunService.RenderStepped:Connect(function()
                    if dragging and currentDragTouch then
                        local delta = currentDragTouch.Position - dragStart
                        local newX = startPos.X.Offset + delta.X
                        local newY = startPos.Y.Offset + delta.Y
                        self.Instance.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
                    end
                end)
                if not self.IsMinimized and self.SnowEnabled then
                    self.SnowEnabled = false
                    if self.SnowContainer then
                        self.SnowContainer.Visible = false
                    end
                end
            end
        end
    end
    
    local function endDrag(input, processed)
        if processed then return end
        local isValid = false
        if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging and currentDragTouch == nil then
            isValid = true
        elseif input.UserInputType == Enum.UserInputType.Touch and dragging and input == currentDragTouch then
            isValid = true
        end
        if isValid then
            dragging = false
            if dragRenderConn then
                dragRenderConn:Disconnect()
                dragRenderConn = nil
            end
            currentDragTouch = nil
        end
    end
    
    self.DraggableArea.InputBegan:Connect(startDrag)
    self.DotAreaButton.InputBegan:Connect(startDrag)
    dragEndConn = UserInputService.InputEnded:Connect(endDrag)
    
    local announcementHeight = 80
    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, announcementHeight),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Instance
    })
    local player = Players.LocalPlayer
    local function loadAvatar()
        local headshot = Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size60x60
        )
        if self.Avatar then
            self.Avatar.Image = headshot
        end
    end
    self.Avatar = CreateInstance("ImageButton", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(240, 240, 245),
        Image = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
    local avatarScale = Instance.new("UIScale", self.Avatar)
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    local avatarStroke = CreateInstance("UIStroke", {
        Color = WasUI.CurrentTheme.Text,
        Thickness = 1,
        Parent = self.Avatar
    })
    loadAvatar()
    self.Avatar.MouseButton1Down:Connect(function()
        SpringTween(avatarScale, {Scale = 0.9}, 0.15)
    end)
    self.Avatar.MouseButton1Up:Connect(function()
        SpringTween(avatarScale, {Scale = 1}, 0.25)
    end)
    self.Avatar.MouseButton1Click:Connect(function()
        if WasUI.SettingsGui and WasUI.SettingsGui.Parent then
            WasUI.SettingsGui:Destroy()
            WasUI.SettingsGui = nil
            WasUI.SettingsPanel = nil
            return
        end
        local settingsGui = Instance.new("ScreenGui")
        settingsGui.Name = "WasUI_Settings"
        settingsGui.ResetOnSpawn = false
        settingsGui.DisplayOrder = 1001
        settingsGui.Parent = game:GetService("CoreGui")
        local clickCatcher = CreateInstance("Frame", {
            Name = "ClickCatcher",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = true,
            ZIndex = 999,
            Parent = settingsGui
        })
        local settingsFrame = CreateInstance("Frame", {
            Name = "SettingsPanel",
            Size = UDim2.new(0, 300, 0, 350),
            Position = UDim2.new(0.5, -150, 0.5, -200),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1000,
            Parent = settingsGui
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = settingsFrame})
        WasUI.SettingsGui = settingsGui
        WasUI.SettingsPanel = settingsFrame
        local titleBar = CreateInstance("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = WasUI.CurrentTheme.Background:lerp(Color3.fromRGB(0, 0, 0), 0.2),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 1001,
            Parent = settingsFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = titleBar})
        local titleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = titleBar
        })
        WasUI:SetLocalizedText(titleLabel, "UI设置")
        local closeBtn = CreateInstance("TextButton", {
            Name = "Close",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -28, 0, 3),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            ZIndex = 1002,
            Parent = titleBar
        })
        closeBtn.MouseButton1Click:Connect(function()
            Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.2)
            if WasUI.SettingsGui then
                WasUI.SettingsGui:Destroy()
                WasUI.SettingsGui = nil
            end
            WasUI.SettingsPanel = nil
        end)
        local contentFrame = CreateInstance("ScrollingFrame", {
            Name = "Content",
            Size = UDim2.new(1, -20, 1, -40),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 1001,
            Parent = settingsFrame
        })
        local contentLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = contentFrame
        })
        local contentPadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = contentFrame
        })
        local function refreshCanvas()
            contentFrame.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 8)
        end
        contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)
        local themeLabel = CreateInstance("TextLabel", {
            Name = "ThemeLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(themeLabel, "窗口风格")
        local themeDropdown = CreateInstance("TextButton", {
            Name = "ThemeDropdown",
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = themeDropdown})
        local themeDisplayNames = {"Dark", "Light", "Blue"}
        local currentThemeDisplay = WasUI.CurrentThemeName
        themeDropdown.Text = currentThemeDisplay
        themeDropdown.MouseButton1Click:Connect(function()
            local currentIndex = 1
            for i, name in ipairs(themeDisplayNames) do
                if name == themeDropdown.Text then
                    currentIndex = i
                    break
                end
            end
            local nextIndex = (currentIndex % #themeDisplayNames) + 1
            local newThemeName = themeDisplayNames[nextIndex]
            themeDropdown.Text = newThemeName
            Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
            task.wait(0.2)
            if WasUI.SettingsGui then
                WasUI.SettingsGui:Destroy()
                WasUI.SettingsGui = nil
            end
            WasUI.SettingsPanel = nil
            WasUI:SetTheme(newThemeName)
        end)

        local rainbowModeLabel = CreateInstance("TextLabel", {
            Name = "RainbowModeLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(rainbowModeLabel, "彩虹边框模式")
        local rainbowModeButton = CreateInstance("TextButton", {
            Name = "RainbowModeButton",
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            Text = self.RainbowMode,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = rainbowModeButton})
        rainbowModeButton.MouseButton1Click:Connect(function()
            local newMode = (self.RainbowMode == "整体") and "流动" or "整体"
            self:SetRainbowMode(newMode)
            rainbowModeButton.Text = newMode
            WasUI:Notify({Title = "彩虹边框模式", Content = "已切换至 " .. newMode .. " 模式", Duration = 1.5})
        end)

        local snowContainer = CreateInstance("Frame", {
            Name = "SnowToggleContainer",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = contentFrame
        })
        local snowTitle = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1003,
            Parent = snowContainer
        })
        WasUI:SetLocalizedText(snowTitle, "雪花飘落")
        local snowBg = CreateInstance("ImageButton", {
            Name = "SnowBG",
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -40, 0.5, -9),
            BackgroundColor3 = self.SnowEnabled and WasUI.CurrentTheme.Success or ((WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)),
            Image = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 1003,
            Parent = snowContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowBg})
        local snowKnob = CreateInstance("Frame", {
            Name = "SnowKnob",
            Size = UDim2.new(0, 16, 0, 16),
            Position = self.SnowEnabled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 1004,
            Parent = snowBg
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowKnob})
        local function updateSnowToggle(newState)
            self.SnowEnabled = newState
            if self.SnowContainer then
                self.SnowContainer.Visible = newState
            end
            if newState then
                Tween(snowBg, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                SpringTween(snowKnob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
            else
                local offCol = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
                Tween(snowBg, {BackgroundColor3 = offCol}, 0.2)
                SpringTween(snowKnob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            end
        end
        snowBg.MouseButton1Click:Connect(function()
            updateSnowToggle(not self.SnowEnabled)
        end)

        local langContainer = CreateInstance("Frame", {
            Name = "LanguageToggleContainer",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = contentFrame
        })
        local langTitle = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1003,
            Parent = langContainer
        })
        WasUI:SetLocalizedText(langTitle, "English")
        local langBg = CreateInstance("ImageButton", {
            Name = "LangBG",
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -40, 0.5, -9),
            BackgroundColor3 = (WasUI.CurrentLanguage == "English") and WasUI.CurrentTheme.Success or ((WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)),
            Image = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 1003,
            Parent = langContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = langBg})
        local langKnob = CreateInstance("Frame", {
            Name = "LangKnob",
            Size = UDim2.new(0, 16, 0, 16),
            Position = (WasUI.CurrentLanguage == "English") and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 1004,
            Parent = langBg
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = langKnob})
        local function updateLangToggle(state)
            if state then
                Tween(langBg, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                SpringTween(langKnob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
                WasUI:SetLanguage("English")
            else
                local offCol = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
                Tween(langBg, {BackgroundColor3 = offCol}, 0.2)
                SpringTween(langKnob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
                WasUI:SetLanguage("中文")
            end
        end
        langBg.MouseButton1Click:Connect(function()
            updateLangToggle(WasUI.CurrentLanguage ~= "English")
        end)

        local refreshThemeButton = CreateInstance("TextButton", {
            Name = "RefreshThemeButton",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(refreshThemeButton, "刷新主题")
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = refreshThemeButton})
        refreshThemeButton.MouseEnter:Connect(function()
            Tween(refreshThemeButton, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
        end)
        refreshThemeButton.MouseLeave:Connect(function()
            Tween(refreshThemeButton, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
        end)
        refreshThemeButton.MouseButton1Click:Connect(function()
            WasUI:SetTheme(WasUI.CurrentThemeName)
            WasUI:Notify({Title = "主题", Content = "已刷新主题样式", Duration = 1.5})
        end)

        local groupButton = CreateInstance("TextButton", {
            Name = "GroupButton",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = WasUI.GroupButtonText,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = groupButton})
        groupButton.MouseEnter:Connect(function()
            Tween(groupButton, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
        end)
        groupButton.MouseLeave:Connect(function()
            Tween(groupButton, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
        end)
        groupButton.MouseButton1Click:Connect(function()
            local copied = copyToClipboard(WasUI.GroupCopyContent)
            if copied then
                WasUI:Notify({Title = "复制成功", Content = "已复制：" .. WasUI.GroupCopyContent, Duration = 2})
            else
                WasUI:Notify({Title = "复制失败", Content = "当前环境不支持复制到剪贴板", Duration = 2})
            end
        end)
        
        local shortcutHint = CreateInstance("TextLabel", {
            Name = "ShortcutHint",
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 10, 1, -20.4),
            BackgroundTransparency = 1,
            Text = "",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 1002,
            Parent = settingsFrame
        })
        WasUI:SetLocalizedText(shortcutHint, "长按控件可创建快捷键")
        
        refreshCanvas()
        Tween(settingsFrame, {BackgroundTransparency = 0.2}, 0.25)
        local function onScreenClick(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local mousePos = input.Position
            local framePos = settingsFrame.AbsolutePosition
            local frameSize = settingsFrame.AbsoluteSize
            local inPanel = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                            mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
            if not inPanel then
                Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
                task.wait(0.2)
                if WasUI.SettingsGui then
                    WasUI.SettingsGui:Destroy()
                    WasUI.SettingsGui = nil
                end
                WasUI.SettingsPanel = nil
            end
        end
        clickCatcher.InputBegan:Connect(onScreenClick)
    end)
    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 62, 0.12, 0),
        BackgroundTransparency = 1,
        Text = "当前用户: " .. player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
    local executorName = "Unknown Executor"
    if typeof(getexecutorname) == "function" then
        executorName = getexecutorname()
    elseif typeof(getExecutor) == "function" then
        executorName = getExecutor()
    end
    self.ExecutorLabel = CreateInstance("TextLabel", {
        Name = "ExecutorLabel",
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 62, 0.35, 0),
        BackgroundTransparency = 1,
        Text = "执行器: " .. executorName,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
self.WelcomeLabel = CreateInstance("TextLabel", {
    Name = "WelcomeLabel",
    Size = UDim2.new(0.6, 0, 0, 14),
    Position = UDim2.new(0, 62, 0.55, 0),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = WasUI.CurrentTheme.Text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 2,
    Parent = self.AnnouncementBar
})
WasUI:SetLocalizedText(self.WelcomeLabel, "欢迎使用 WasUI")
table.insert(WasUI.Objects, {Object = self.WelcomeLabel, Type = "Label"})

    self.SettingsHint = CreateInstance("TextLabel", {
        Name = "SettingsHint",
        Size = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 10, 0.75, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0.3,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
    WasUI:SetLocalizedText(self.SettingsHint, "点我打开设置页面")
    table.insert(WasUI.Objects, {Object = self.SettingsHint, Type = "Label"})

    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 26 + 80),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.8,
        ClipsDescendants = false,
        ZIndex = 2,
        Parent = self.Instance
    })
    local tabLine = CreateInstance("Frame", {
        Name = "TabLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = WasUI.CurrentTheme.TabBorder,
        BackgroundTransparency = 0.7,
        ZIndex = 2,
        Parent = self.TabBar
    })
    self.TabContainer = CreateInstance("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        ScrollBarImageTransparency = 1,
        ScrollingDirection = Enum.ScrollingDirection.X,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = self.TabBar
    })
    
    local leftArrow, rightArrow
    local function updateArrowVisibility()
        if not self.TabContainer then return end
        local canvasPos = self.TabContainer.CanvasPosition.X
        local canvasSize = self.TabContainer.CanvasSize.X.Offset
        local containerSize = self.TabContainer.AbsoluteSize.X

        if canvasSize <= containerSize then
            if leftArrow then leftArrow.Visible = false end
            if rightArrow then rightArrow.Visible = false end
            return
        end

        if leftArrow then leftArrow.Visible = canvasPos > 5 end
        if rightArrow then rightArrow.Visible = canvasPos < canvasSize - containerSize - 5 end
    end

    leftArrow = WasUI:CreateIcon("chevron-left", UDim2.new(0, 16, 0, 16), WasUI.CurrentTheme.Text)
    if leftArrow then
        leftArrow.Name = "LeftArrow"
        leftArrow.Position = UDim2.new(0, -6, 0.5, -8)
        leftArrow.BackgroundTransparency = 1
        leftArrow.ZIndex = 20
        leftArrow.Visible = false
        leftArrow.Parent = self.TabBar
        table.insert(WasUI.Objects, {Object = leftArrow, Type = "TabArrow"})
    end

    rightArrow = WasUI:CreateIcon("chevron-right", UDim2.new(0, 16, 0, 16), WasUI.CurrentTheme.Text)
    if rightArrow then
        rightArrow.Name = "RightArrow"
        rightArrow.Position = UDim2.new(1, -10, 0.5, -8)
        rightArrow.BackgroundTransparency = 1
        rightArrow.ZIndex = 20
        rightArrow.Visible = false
        rightArrow.Parent = self.TabBar
        table.insert(WasUI.Objects, {Object = rightArrow, Type = "TabArrow"})
    end

    self.TabContainer:GetPropertyChangedSignal("CanvasPosition"):Connect(updateArrowVisibility)
    self.TabContainer:GetPropertyChangedSignal("CanvasSize"):Connect(updateArrowVisibility)
    self.TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateArrowVisibility)
    
    local function delayedUpdate()
        task.wait()
        updateArrowVisibility()
    end
    self.TabContainer.ChildAdded:Connect(delayedUpdate)
    self.TabContainer.ChildRemoved:Connect(delayedUpdate)
    task.defer(updateArrowVisibility)
    
    local tabListLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabContainer
    })
    local tabPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = self.TabContainer
    })
    local function updateTabBarHeight()
        local containerHeight = self.TabContainer.AbsoluteSize.Y
        if containerHeight > 0 then
            self.TabBar.Size = UDim2.new(1, 0, 0, containerHeight)
            local tabHeight = self.TabBar.AbsoluteSize.Y
            self.ContentArea.Position = UDim2.new(0, 0, 0, 26 + 80 + tabHeight)
            self.ContentArea.Size = UDim2.new(1, 0, 1, -(26 + 80 + tabHeight))
        end
    end
    self.TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTabBarHeight)
    tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabContainer.CanvasSize = UDim2.new(0, tabListLayout.AbsoluteContentSize.X + 8, 0, 0)
        task.wait()
        updateTabBarHeight()
    end)
    task.wait()
    updateTabBarHeight()
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -(26 + 80 + self.TabBar.AbsoluteSize.Y)),
        Position = UDim2.new(0, 0, 0, 26 + 80 + self.TabBar.AbsoluteSize.Y),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = self.Instance
    })
    local contentPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = self.ContentArea
    })
    local contentListLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.ContentArea
    })
    local function refreshContentCanvas()
        self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentListLayout.AbsoluteContentSize.Y + 8)
    end
    contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshContentCanvas)
    refreshContentCanvas()
    local function refreshOuterCanvas()
        refreshContentCanvas()
    end
    self.Tabs = {}
    self.ActiveTab = nil
    self.TabOrderCounter = 0
    function self:AddTab(tabName, icon)
        self.TabOrderCounter = self.TabOrderCounter + 1
local tabButton = CreateInstance("TextButton", {
    Name = "Tab_" .. tabName,
    Size = UDim2.new(0, 90, 0, 24),
    BackgroundColor3 = WasUI.CurrentTheme.TabButton,
    BackgroundTransparency = 0.5,
    Text = "",
    TextColor3 = WasUI.CurrentTheme.Text,
    Font = Enum.Font.GothamSemibold,
    TextSize = 12,
    AutoButtonColor = false,
    LayoutOrder = self.TabOrderCounter,
    ZIndex = 2,
    Parent = self.TabContainer
})
WasUI:SetLocalizedText(tabButton, tabName)
        table.insert(WasUI.Objects, {Object = tabButton, Type = "TabButton"})
        local tabUnderline = CreateInstance("Frame", {
            Name = "Underline",
            Size = UDim2.new(0, 0, 0, 2),
            Position = UDim2.new(0.5, 0, 1, -2),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = WasUI.CurrentTheme.Accent,
            Visible = false,
            ZIndex = 2,
            Parent = tabButton
        })
        local tabFrame = CreateInstance("Frame", {
            Name = "TabFrame_" .. tabName,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 2,
            Parent = self.ContentArea
        })
        local tabInnerLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 4),
            Parent = tabFrame
        })
        local tabInnerPadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = tabFrame
        })
        tabInnerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshOuterCanvas)
        tabButton.MouseButton1Click:Connect(function()
            self:SetActiveTab(tabName)
        end)
        self.Tabs[tabName] = {
            Button = tabButton,
            Underline = tabUnderline,
            Frame = tabFrame
        }
        if not self.ActiveTab then
            self:SetActiveTab(tabName)
        end
        return tabFrame
    end
    function self:SetActiveTab(tabName)
        if self.ActiveTab and self.Tabs[self.ActiveTab] then
            local old = self.Tabs[self.ActiveTab]
            if old.Underline then
                old.Underline.Visible = false
                old.Underline.Size = UDim2.new(0, 0, 0, 2)
            end
            if old.Frame then
                old.Frame.Visible = false
            end
        end
        if not self.Tabs[tabName] then return end
        local new = self.Tabs[tabName]
        if new.Underline then
            new.Underline.Size = UDim2.new(0, 0, 0, 2)
            new.Underline.Visible = true
            Tween(new.Underline, {Size = UDim2.new(1, 0, 0, 2)}, 0.25)
        end
        if new.Frame then
            new.Frame.Visible = true
        end
        self.ActiveTab = tabName
    end
    function self:SetVisible(visible)
        self.Instance.Visible = visible
        if self.BorderFlow then
            self.BorderFlow.Visible = visible
        end
        if self.SnowContainer then
            self.SnowContainer.Visible = visible
        end
    end
    function self:SetTitle(text)
        WasUI:SetLocalizedText(self.Title, text)
    end
    function self:SetWelcome(text)
        WasUI:SetLocalizedText(self.WelcomeLabel, text)
    end

    self.HotkeyConnection = nil
    function self:EnableHotkeyToggle(keyCode)
        if self.HotkeyConnection then
            self.HotkeyConnection:Disconnect()
        end
        keyCode = keyCode or Enum.KeyCode.u
        self.HotkeyConnection = UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == keyCode then
                if self.IsMinimized then
                    self:RestoreFromDots()
                else
                    self:MinimizeToDots()
                end
            end
        end)
    end
    function self:DisableHotkeyToggle()
        if self.HotkeyConnection then
            self.HotkeyConnection:Disconnect()
            self.HotkeyConnection = nil
        end
    end

    self.CurrentCategory = nil
    function self:SetCurrentCategory(categoryName)
        self.CurrentCategory = categoryName
    end
    function self:GetCurrentCategory()
        return self.CurrentCategory
    end

    if self.SnowEnabled then
        self.SnowContainer = CreateInstance("Frame", {
            Name = "SnowContainer",
            Size = self.Instance.Size,
            Position = self.Instance.Position,
            BackgroundTransparency = 1,
            ZIndex = 100000,
            Parent = parent
        })
        local function updateSnowContainer()
            if self.SnowContainer and self.Instance then
                self.SnowContainer.Position = self.Instance.Position
                self.SnowContainer.Size = self.Instance.Size
            end
        end
        self.Instance:GetPropertyChangedSignal("Position"):Connect(updateSnowContainer)
        self.Instance:GetPropertyChangedSignal("Size"):Connect(updateSnowContainer)
        self.Snowflakes = {}
        self.SnowTimer = 0
        self.SnowChangeTimer = 0
        self.SnowConnection = RunService.Heartbeat:Connect(function(deltaTime)
            if not self.Instance.Visible then return end
            if not self.SnowContainer.Visible then return end
            self.SnowTimer = self.SnowTimer + deltaTime
            self.SnowChangeTimer = self.SnowChangeTimer + deltaTime
            if self.SnowTimer >= 0.08 and #self.Snowflakes < 30 then
                self.SnowTimer = 0
                local size = math.random(4, 10)
                local flake = CreateInstance("Frame", {
                    Size = UDim2.new(0, size, 0, size),
                    Position = UDim2.new(math.random() * 0.9 + 0.05, 0, -0.1, 0),
                    BackgroundColor3 = WasUI.CurrentTheme.SnowColor,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    ZIndex = 100001,
                    Parent = self.SnowContainer
                })
                CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flake})
                local speedY = math.random(150, 200) / 100
                local speedX = (math.random() - 0.5) * 0.7
                table.insert(self.Snowflakes, {
                    Instance = flake,
                    SpeedY = speedY,
                    SpeedX = speedX,
                    Age = 0,
                    Size = size
                })
            end
            if self.SnowChangeTimer >= 1.25 then
                self.SnowChangeTimer = 0
                for _, data in ipairs(self.Snowflakes) do
                    data.SpeedX = (math.random() - 0.5) * 0.8
                    data.SpeedY = math.random(150, 200) / 100
                end
            end
            for i = #self.Snowflakes, 1, -1 do
                local data = self.Snowflakes[i]
                local flake = data.Instance
                if not flake or not flake.Parent then
                    table.remove(self.Snowflakes, i)
                    continue
                end
                data.Age = data.Age + deltaTime
                local newX = flake.Position.X.Scale + data.SpeedX * deltaTime * 0.6
                local newY = flake.Position.Y.Offset + data.SpeedY * deltaTime * 60
                local alpha = math.clamp(1 - data.Age / 2.8, 0, 1)
                local newSize = data.Size * (1 - data.Age / 3.2)
                flake.Position = UDim2.new(newX, 0, 0, newY)
                flake.Size = UDim2.new(0, math.max(2, newSize), 0, math.max(2, newSize))
                flake.BackgroundTransparency = 1 - alpha
                if newY > self.Instance.AbsoluteSize.Y * 1.5 or newX < -0.1 or newX > 1.1 or data.Age > 3.5 then
                    flake:Destroy()
                    table.remove(self.Snowflakes, i)
                end
            end
        end)
    else
        self.SnowContainer = nil
        self.SnowConnection = nil
    end
    local originalSize = self.Instance.Size
    local originalPos = self.Instance.Position
    local originalTransparency = self.Instance.BackgroundTransparency
    self.Instance.BackgroundTransparency = 1
    self.Instance.Size = UDim2.new(0, 0, 0, 0)
    self.Instance.Position = UDim2.new(0.5, 0, 0.5, 0)
    if self.BorderFlow then
        self.BorderFlow.Visible = false
    end
    if self.SnowContainer then
        self.SnowContainer.Visible = false
    end
    local windowTween = Tween(self.Instance, {
        BackgroundTransparency = originalTransparency,
        Size = originalSize,
        Position = originalPos
    }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    windowTween.Completed:Connect(function()
        if self.BorderFlow then
            self.BorderFlow.Visible = true
        end
        if self.SnowContainer then
            self.SnowContainer.Visible = true
        end
    end)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Panel", PanelData = self})
    return self
end

local function updateAllNotificationPositions()
    local sorted = {}
    for id, data in pairs(WasUI.ActiveNotifications) do
        table.insert(sorted, data)
    end
    table.sort(sorted, function(a, b)
        return a.CreationTime < b.CreationTime
    end)
    local targetPositions = {}
    for i, data in ipairs(sorted) do
        local targetY = WasUI.NotificationTop + (i-1)*(WasUI.NotificationHeight + WasUI.NotificationSpacing)
        targetPositions[data] = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)
    end
    return targetPositions
end

function WasUI:Notify(options)
    EnsureNotificationGui()
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 3
    local bgColor = options.BackgroundColor or WasUI.CurrentTheme.Section
    local borderColor = options.BorderColor or WasUI.CurrentTheme.Text
    local notificationId = HttpService:GenerateGUID(false)
    local frame = CreateInstance("Frame", {
        Name = "Notification_" .. notificationId,
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, WasUI.NotificationTop),
        BackgroundColor3 = bgColor,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 9999,
        Parent = WasUI.NotificationGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    local stroke = CreateInstance("UIStroke", {
        Color = borderColor,
        Thickness = 1,
        Transparency = 0.5,
        Parent = frame
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 0, 14),
        Position = UDim2.new(0, 5, 0, 2),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10000,
        Parent = frame
    })
    local contentLabel = CreateInstance("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -10, 0, 12),
        Position = UDim2.new(0, 5, 0, 16),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 10000,
        Parent = frame
    })
    local data = {
        Frame = frame,
        Id = notificationId,
        CreationTime = tick()
    }
    WasUI.ActiveNotifications[notificationId] = data
    local targetPositions = updateAllNotificationPositions()
    for notif, targetPos in pairs(targetPositions) do
        Tween(notif.Frame, {Position = targetPos}, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    end
    task.delay(duration, function()
        WasUI.ActiveNotifications[notificationId] = nil
        local newTargets = updateAllNotificationPositions()
        for notif, targetPos in pairs(newTargets) do
            Tween(notif.Frame, {Position = targetPos}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
        local fadeOut = Tween(frame, {BackgroundTransparency = 1, Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, frame.Position.Y.Offset)}, 0.3)
        fadeOut.Completed:Connect(function()
            frame:Destroy()
        end)
    end)
end

function WasUI:CreateWindow(title, size, position, backgroundUrl, snowEnabled, titleTag)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WasUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = WasUI.DefaultDisplayOrder
    screenGui.Parent = game:GetService("CoreGui")
    local internalName = title
    local window = Panel:New(internalName, screenGui, size or UDim2.new(0, 380, 0, 350), position, backgroundUrl, snowEnabled, titleTag)
    window:SetTitle(title)
    RecordOriginalTransparency(window.Instance)

    local showBuiltinPopup = true
    if WasUI.ExternalPopupCalled or WasUI.PendingPopup then
        showBuiltinPopup = false
    end

    local hasConfig = false
    if WasUI.ConfigManager then
        local config = WasUI.ConfigManager:GetConfig("user_settings")
        if config and next(config.Data) then
            hasConfig = true
        end
    end

    if hasConfig and showBuiltinPopup then
        WasUI:ShowPopup({
            title = "找到配置文件",
            titleIcon = "file-cog",
            content = "是否加载上次保存的配置？",
            confirmText = "加载",
            cancelText = "跳过",
            onConfirm = function()
                local config = WasUI.ConfigManager:GetConfig("user_settings")
                if config then config:Load() end
            end,
            onCancel = function()
            end
        })
    end

    return window
end

function WasUI:Popup(options, callback)
    WasUI.ExternalPopupCalled = true
    if WasUI.ConfigFolderCreated then
        WasUI:ShowPopup(options, callback)
    else
        WasUI.PendingPopup = {options = options, callback = callback}
    end
end

function WasUI:CreateButton(parent, text, onClick, size, iconName)
    return Button:New("Button", parent, text, onClick, size, iconName)
end

function WasUI:CreateToggle(parent, initialState, onToggle, featureName, rainbowName, configKey)
    return self:CreateToggleWithTitle(parent, featureName or "", initialState, onToggle, featureName, rainbowName, nil, configKey)
end

function WasUI:CreateToggleWithTitle(parent, title, initialState, onToggle, featureName, rainbowName, iconName, configKey)
    return ToggleSwitch:New("Toggle", parent, title, initialState, onToggle, featureName, rainbowName, iconName, configKey)
end

function WasUI:CreateLabel(parent, text, textColor)
    return Label:New("Label", parent, text, textColor)
end

function WasUI:CreateCategory(parent, title, iconName)
    return Category:New("Category", parent, title, iconName)
end

function WasUI:CreateDropdown(parent, title, options, defaultValue, callback, multiSelect, configKey)
    return Dropdown:New("Dropdown", parent, title, options, defaultValue, callback, multiSelect, configKey)
end

function WasUI:CreateSlider(parent, title, min, max, defaultValue, callback, configKey)
    return Slider:New("Slider", parent, title, min, max, defaultValue, callback, configKey)
end

function WasUI:CreateTextInput(parent, placeholder, defaultValue, callback, configKey)
    return TextInput:New("TextInput", parent, placeholder, defaultValue, callback, configKey)
end

function WasUI:AddSpacing(parent, height)
    local spacing = Instance.new("Frame")
    spacing.Name = "Spacing"
    spacing.Size = UDim2.new(1, 0, 0, height or 4)
    spacing.BackgroundTransparency = 1
    spacing.Parent = parent
end

function WasUI:SetGroupButtonText(text)
    WasUI.GroupButtonText = text
    if WasUI.SettingsPanel then
        local btn = WasUI.SettingsPanel:FindFirstChild("Content") and WasUI.SettingsPanel.Content:FindFirstChild("GroupButton")
        if btn then btn.Text = text end
    end
end

function WasUI:SetGroupCopyContent(content)
    WasUI.GroupCopyContent = content
end

function WasUI:CreateCollapsibleSection(...)
    error("CreateCollapsibleSection 已弃用，请使用 CreateCategory")
end

task.spawn(function()
    local success, langTable = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/WasKKal/WasUI-For-Roblox/main/CnToEng.lua"))()
    end)
    if success and type(langTable) == "table" then
        WasUI:LoadLanguageTable(langTable)
        print("[WasUI] 远程翻译表加载成功")
    else
        warn("[WasUI] 远程翻译表加载失败,无法切换English")
    end
end)

_G.WasUIModule = WasUI
return WasUI