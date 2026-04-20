--Version 1.1.0-Debug
local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local TextService = game:GetService("TextService")

if _G.WasUIDebugModule then
    warn("WasUI Debug 已加载")
    return _G.WasUIDebugModule
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
WasUI.Version = "1.1.0-Debug"

WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}

WasUI.SettingsPanel = nil

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

function WasUI:SetDefaultTheme(themeName)
    if self.Themes[themeName] then
        self.DefaultTheme = themeName
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
        Primary = Color3.fromRGB(70, 130, 180),
        Secondary = Color3.fromRGB(100, 165, 200),
        Background = Color3.fromRGB(30, 100, 140),
        Text = Color3.fromRGB(240, 245, 250),
        Accent = Color3.fromRGB(220, 140, 60),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 91),
        Error = Color3.fromRGB(255, 123, 123),
        Section = Color3.fromRGB(50, 130, 170),
        Input = Color3.fromRGB(40, 120, 160),
        TabBorder = Color3.fromRGB(0, 145, 210),
        TabButton = Color3.fromRGB(40, 120, 180),
        SnowColor = Color3.fromRGB(255, 180, 100)
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

WasUI.ActiveDialogs = {}

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

function WasUI:Notify(options)
    if not WasUI.NotificationGui then
        WasUI.NotificationGui = Instance.new("ScreenGui")
        WasUI.NotificationGui.Name = "WasUI_Notifications"
        WasUI.NotificationGui.ResetOnSpawn = false
        WasUI.NotificationGui.DisplayOrder = 999
        WasUI.NotificationGui.Parent = game:GetService("CoreGui")
    end
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
    local sorted = {}
    for _, v in pairs(WasUI.ActiveNotifications) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b) return a.CreationTime < b.CreationTime end)
    for i, v in ipairs(sorted) do
        local targetY = WasUI.NotificationTop + (i-1)*(WasUI.NotificationHeight + WasUI.NotificationSpacing)
        Tween(v.Frame, {Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)}, 0.35)
    end
    task.delay(duration, function()
        WasUI.ActiveNotifications[notificationId] = nil
        local newSorted = {}
        for _, v in pairs(WasUI.ActiveNotifications) do table.insert(newSorted, v) end
        table.sort(newSorted, function(a, b) return a.CreationTime < b.CreationTime end)
        for i, v in ipairs(newSorted) do
            local targetY = WasUI.NotificationTop + (i-1)*(WasUI.NotificationHeight + WasUI.NotificationSpacing)
            Tween(v.Frame, {Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)}, 0.3)
        end
        Tween(frame, {BackgroundTransparency = 1, Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, frame.Position.Y.Offset)}, 0.3):Wait()
        frame:Destroy()
    end)
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
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent,
        ZIndex = 2
    })
    WasUI:SetLocalizedText(self.Instance, text or "按钮")
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Instance})
    if iconName then
        local icon = WasUI:CreateIcon(iconName, UDim2.new(0, 14, 0, 14))
        if icon then
            icon.Parent = self.Instance
            icon.Position = UDim2.new(0, 8, 0.5, -7)
            icon.ZIndex = 3
            self.Instance.TextXAlignment = Enum.TextXAlignment.Left
            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 28)
            padding.Parent = self.Instance
        end
    end
    local scale = Instance.new("UIScale", self.Instance)
    self.Instance.MouseButton1Down:Connect(function()
        SpringTween(scale, {Scale = 0.97}, 0.2)
    end)
    self.Instance.MouseButton1Up:Connect(function()
        SpringTween(scale, {Scale = 1}, 0.25)
        if onClick then onClick() end
    end)
    AddRipple(self.Instance)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Button"})
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, title, initialState, onToggle)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.Container = CreateInstance("Frame", {
        Name = "ToggleContainer",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
        ZIndex = 2
    })
    if title then
        local titleLabel = CreateInstance("TextLabel", {
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
        WasUI:SetLocalizedText(titleLabel, title)
    end
    local offColor = Color3.fromRGB(80, 80, 80)
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
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Background})
    self.Knob = CreateInstance("Frame", {
        Name = "ToggleKnob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Toggled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Background
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Knob})
    AddRipple(self.Background, 2.5)
    local function performToggle(newState)
        self.Toggled = newState
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
        else
            Tween(self.Background, {BackgroundColor3 = offColor}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
        end
        if onToggle then onToggle(self.Toggled) end
    end
    self.Background.MouseButton1Click:Connect(function()
        performToggle(not self.Toggled)
    end)
    function self:SetToggle(newState)
        performToggle(newState)
    end
    table.insert(WasUI.Objects, {Object = self.Background, Type = "Toggle"})
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label
function Label:New(name, parent, text)
    local self = Control:New(name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = "Label",
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = parent
    })
    WasUI:SetLocalizedText(self.Instance, text or "标签")
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Label"})
    return self
end

local Category = setmetatable({}, {__index = Control})
Category.__index = Category
function Category:New(name, parent, title, iconName)
    local actualIcon = iconName or "chevron-down"
    local self = Control:New(name, parent)
    self.Collapsed = false
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
    local icon = WasUI:CreateIcon(actualIcon, UDim2.new(0, 18, 0, 18))
    if icon then
        icon.Name = "CategoryIcon"
        icon.Parent = titleContainer
        icon.LayoutOrder = 1
        icon.ZIndex = 3
        icon.Rotation = 0
        self.Icon = icon
    end
    CreateInstance("Frame", {
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
    CreateInstance("UIPadding", {
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
            Tween(self.Content, {Size = UDim2.new(1, 0, 0, targetHeight)}, 0.25)
            if self.Icon then
                Tween(self.Icon, {Rotation = self.Collapsed and -90 or 0}, 0.25)
            end
        else
            self.Content.Size = UDim2.new(1, 0, 0, targetHeight)
            if self.Icon then
                self.Icon.Rotation = self.Collapsed and -90 or 0
            end
        end
        updateParentScroller()
    end
    local toggleButton = CreateInstance("TextButton", {
        Name = "ToggleButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        Parent = self.Header,
        ZIndex = 1,
        AutoButtonColor = false
    })
    toggleButton.MouseButton1Click:Connect(function()
        self.Collapsed = not self.Collapsed
        updateLayout(true)
    end)
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
        panel = panel.Parent
    end
    if panel and panel.SetCurrentCategory then
        panel:SetCurrentCategory(title)
    end
    self.Instance = self.Content
    table.insert(WasUI.Objects, {Object = self.Header, Type = "Category"})
    return self
end

local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback, multiSelect)
    if not WasUI.DropdownGui then
        WasUI.DropdownGui = Instance.new("ScreenGui")
        WasUI.DropdownGui.Name = "WasUI_Dropdowns"
        WasUI.DropdownGui.ResetOnSpawn = false
        WasUI.DropdownGui.DisplayOrder = 1000
        WasUI.DropdownGui.Parent = game:GetService("CoreGui")
    end
    local self = Control:New(name, parent)
    self.MultiSelect = multiSelect or false
    self.Options = {}
    for _, v in ipairs(options or {}) do table.insert(self.Options, tostring(v)) end
    self.SelectedValues = {}
    self.SelectedValue = nil
    if self.MultiSelect then
        if type(defaultValue) == "table" then
            for _, v in ipairs(defaultValue) do table.insert(self.SelectedValues, tostring(v)) end
        elseif defaultValue then
            table.insert(self.SelectedValues, tostring(defaultValue))
        end
    else
        self.SelectedValue = defaultValue and tostring(defaultValue) or nil
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
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.Container
    })
    WasUI:SetLocalizedText(titleLabel, title or "下拉菜单")
    self.DropdownButton = CreateInstance("TextButton", {
        Name = "DropdownButton",
        Size = UDim2.new(0.3, 0, 0, 24),
        Position = UDim2.new(0.7, -3, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        AutoButtonColor = false,
        ZIndex = 11,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.DropdownButton})
    self.OptionsContainer = CreateInstance("ScrollingFrame", {
        Name = "OptionsContainer",
        Size = UDim2.new(0.3, 0, 0, 0),
        Position = UDim2.new(0.7, -3, 0, 24),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 0.3,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 9999,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = WasUI.DropdownGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = self.OptionsContainer})
    local optionsList = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.OptionsContainer
    })
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        Parent = self.OptionsContainer
    })
    self.OptionButtons = {}
    local function rebuildOptions()
        for _, btn in pairs(self.OptionButtons) do btn:Destroy() end
        self.OptionButtons = {}
        for _, option in ipairs(self.Options) do
            local optionButton = CreateInstance("TextButton", {
                Name = "Option_" .. option,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = WasUI.CurrentTheme.Input,
                BackgroundTransparency = 0.3,
                Text = option,
                TextColor3 = WasUI.CurrentTheme.Text,
                Font = Enum.Font.Gotham,
                TextSize = 12,
                AutoButtonColor = false,
                ZIndex = 10000,
                Parent = self.OptionsContainer
            })
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = optionButton})
            optionButton.MouseButton1Click:Connect(function()
                if self.MultiSelect then
                    local index = nil
                    for i, v in ipairs(self.SelectedValues) do if v == option then index = i break end end
                    if index then table.remove(self.SelectedValues, index) else table.insert(self.SelectedValues, option) end
                    self:UpdateDisplayText()
                    if self.Callback then self.Callback(self.SelectedValues) end
                else
                    self.SelectedValue = option
                    self:UpdateDisplayText()
                    if self.Callback then self.Callback(option) end
                    self:Close(true)
                end
            end)
            AddRipple(optionButton)
            self.OptionButtons[option] = optionButton
        end
        local totalHeight = #self.Options * 28 + (#self.Options - 1) * 4 + 16
        local maxHeight = math.floor(Workspace.CurrentCamera.ViewportSize.Y * 0.5)
        self.OptionsContainer.Size = UDim2.new(0.3, 0, 0, math.min(totalHeight, maxHeight))
        self.OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsList.AbsoluteContentSize.Y + 8)
    end
    function self:UpdateOptions(newOptions, newDefaultValue)
        self.Options = {}
        for _, v in ipairs(newOptions or {}) do table.insert(self.Options, tostring(v)) end
        if self.MultiSelect then
            self.SelectedValues = {}
            if type(newDefaultValue) == "table" then
                for _, v in ipairs(newDefaultValue) do table.insert(self.SelectedValues, tostring(v)) end
            elseif newDefaultValue then
                table.insert(self.SelectedValues, tostring(newDefaultValue))
            end
        else
            self.SelectedValue = newDefaultValue and tostring(newDefaultValue) or nil
        end
        rebuildOptions()
        self:UpdateDisplayText()
    end
    function self:GetDisplayText()
        if self.MultiSelect then
            if #self.SelectedValues == 0 then return WasUI:Translate("选择...") end
            return table.concat(self.SelectedValues, ", ")
        else
            return self.SelectedValue or WasUI:Translate("选择...")
        end
    end
    function self:UpdateDisplayText()
        self.DropdownButton.Text = self:GetDisplayText()
    end
    local function updatePosition()
        if not self.IsOpen then return end
        local btnPos = self.DropdownButton.AbsolutePosition
        local btnSize = self.DropdownButton.AbsoluteSize
        local menuHeight = self.OptionsContainer.AbsoluteSize.Y
        local menuWidth = self.OptionsContainer.AbsoluteSize.X
        local viewport = Workspace.CurrentCamera.ViewportSize
        local x = btnPos.X
        local y = btnPos.Y + btnSize.Y
        if y + menuHeight > viewport.Y then y = btnPos.Y - menuHeight end
        if x + menuWidth > viewport.X then x = viewport.X - menuWidth - 5 end
        self.OptionsContainer.Position = UDim2.new(0, math.max(5, x), 0, math.max(5, y))
    end
    self.DropdownButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition)
    self.DropdownButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
    function self:Open()
        if self.IsOpen then return end
        self.IsOpen = true
        table.insert(WasUI.OpenDropdowns, self)
        updatePosition()
        self.OptionsContainer.Visible = true
        Tween(self.OptionsContainer, {BackgroundTransparency = 0.3}, 0.2)
    end
    function self:Close(instant)
        if not self.IsOpen then return end
        self.IsOpen = false
        for i, dd in ipairs(WasUI.OpenDropdowns) do if dd == self then table.remove(WasUI.OpenDropdowns, i) break end end
        if instant then
            self.OptionsContainer.Visible = false
        else
            Tween(self.OptionsContainer, {BackgroundTransparency = 1}, 0.2):Wait()
            self.OptionsContainer.Visible = false
        end
    end
    self.DropdownButton.MouseButton1Click:Connect(function()
        if self.IsOpen then self:Close() else self:Open() end
    end)
    AddRipple(self.DropdownButton)
    rebuildOptions()
    self:UpdateDisplayText()
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Dropdown"})
    return self
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        for i = #WasUI.OpenDropdowns, 1, -1 do
            local dd = WasUI.OpenDropdowns[i]
            if dd and dd.IsOpen then
                local mousePos = input.Position
                local menuPos = dd.OptionsContainer.AbsolutePosition
                local menuSize = dd.OptionsContainer.AbsoluteSize
                local btnPos = dd.DropdownButton.AbsolutePosition
                local btnSize = dd.DropdownButton.AbsoluteSize
                local inMenu = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X and mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
                local inButton = mousePos.X >= btnPos.X and mousePos.X <= btnPos.X + btnSize.X and mousePos.Y >= btnPos.Y and mousePos.Y <= btnPos.Y + btnSize.Y
                if not inMenu and not inButton then dd:Close() end
            end
        end
    end
end)

local Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider
function Slider:New(name, parent, title, min, max, defaultValue, callback)
    local self = Control:New(name, parent)
    self.Min = min or 0
    self.Max = max or 100
    self.Value = math.clamp(defaultValue or self.Min, self.Min, self.Max)
    self.Callback = callback
    self.Container = CreateInstance("Frame", {
        Name = "Slider",
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = parent
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.4, 0, 0, 18),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = self.Container
    })
    WasUI:SetLocalizedText(titleLabel, title or "滑动条")
    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.2, 0, 0, 18),
        Position = UDim2.new(0.8, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 3,
        Parent = self.Container
    })
    self.SliderTrack = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -2, 0, 8),
        Position = UDim2.new(0, 2, 0, 20),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.SliderTrack})
    self.SliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.SliderFill})
    self.Knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -8, 0.5, -8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.SliderTrack
    })
    self.Knob.Visible = false
    local knobCircle = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        Parent = self.Knob
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knobCircle})
    local knobScale = Instance.new("UIScale", knobCircle)
    local dragging = false
    local inputChangedConn = nil
    local function setValue(newValue)
        newValue = math.clamp(newValue, self.Min, self.Max)
        if newValue == self.Value then return end
        self.Value = newValue
        self.ValueLabel.Text = tostring(self.Value)
        local t = (self.Value - self.Min) / (self.Max - self.Min)
        self.SliderFill.Size = UDim2.new(t, 0, 1, 0)
        self.Knob.Position = UDim2.new(t, -8, 0.5, -8)
        if self.Callback then self.Callback(self.Value) end
    end
    local function updateFromMouse(inputX)
        local trackPos = self.SliderTrack.AbsolutePosition
        local trackSize = self.SliderTrack.AbsoluteSize.X
        if trackSize <= 0 then return end
        local t = math.clamp((inputX - trackPos.X) / trackSize, 0, 1)
        setValue(math.round(self.Min + t * (self.Max - self.Min)))
    end
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            SpringTween(knobScale, {Scale = 1.2}, 0.15)
            updateFromMouse(input.Position.X)
            if inputChangedConn then inputChangedConn:Disconnect() end
            inputChangedConn = UserInputService.InputChanged:Connect(function(inp)
                if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                    updateFromMouse(inp.Position.X)
                end
            end)
        end
    end
    local function endDrag()
        dragging = false
        SpringTween(knobScale, {Scale = 1}, 0.25)
        if inputChangedConn then inputChangedConn:Disconnect(); inputChangedConn = nil end
    end
    self.SliderTrack.InputBegan:Connect(startDrag)
    self.SliderTrack.InputEnded:Connect(endDrag)
    self.Knob.InputBegan:Connect(startDrag)
    self.Knob.InputEnded:Connect(endDrag)
    AddRipple(self.SliderTrack)
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Slider"})
    return self
end

local TextInput = setmetatable({}, {__index = Control})
TextInput.__index = TextInput
function TextInput:New(name, parent, placeholder, defaultValue, callback)
    local self = Control:New(name, parent)
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
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = self.TextBox})
    self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        if callback then callback(self.TextBox.Text) end
    end)
    AddRipple(self.TextBox)
    table.insert(WasUI.Objects, {Object = self.Container, Type = "TextInput"})
    return self
end

function WasUI:ShowPopup(options)
    local title = options.title or "提示"
    local titleIcon = options.titleIcon
    local content = options.content or ""
    local confirmText = options.confirmText or "确认"
    local cancelText = options.cancelText or "取消"
    local onConfirm = options.onConfirm
    local onCancel = options.onCancel
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "WasUI_Popup"
    dialogGui.ResetOnSpawn = false
    dialogGui.DisplayOrder = 2000
    dialogGui.IgnoreGuiInset = true
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
    if titleIcon then
        local icon = WasUI:CreateIcon(titleIcon, UDim2.new(0, 20, 0, 20))
        if icon then
            icon.Parent = titleContainer
            icon.Position = UDim2.new(0, 0, 0.5, -10)
            icon.ZIndex = 1002
        end
    end
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, titleIcon and -24 or 0, 0, 24),
        Position = UDim2.new(titleIcon and 0.06 or 0, 0, 0.5, -12),
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
    local totalHeight = 56 + contentLabel.TextBounds.Y + 40 + 65
    dialogFrame.Size = UDim2.new(0, 480, 0, totalHeight)
    buttonContainer.Position = UDim2.new(0, 10, 0, 56 + contentLabel.TextBounds.Y + 18)
    dialogFrame.Position = UDim2.new(0.5, -240, 0.5, -totalHeight/2)
    local function animateClose()
        Tween(overlay, {BackgroundTransparency = 1}, 0.2):Wait()
        dialogGui:Destroy()
        for i, d in ipairs(WasUI.ActiveDialogs) do if d == dialogGui then table.remove(WasUI.ActiveDialogs, i) break end end
    end
    cancelButton.MouseButton1Click:Connect(function()
        if onCancel then onCancel() end
        animateClose()
    end)
    confirmButton.MouseButton1Click:Connect(function()
        if onConfirm then onConfirm() end
        animateClose()
    end)
    Tween(overlay, {BackgroundTransparency = 0.5}, 0.2)
    table.insert(WasUI.ActiveDialogs, dialogGui)
    return dialogGui
end

function WasUI:ShowConfirmDialog(options)
    local title = options.title or "确认"
    local description = options.description
    local showInput = options.showInput
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
    dialogGui.IgnoreGuiInset = true
    dialogGui.Parent = game:GetService("CoreGui")
    local overlay = CreateInstance("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
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
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 1001,
        Parent = dialogFrame
    })
    local currentY = 60
    if description and description ~= "" then
        local descLabel = CreateInstance("TextLabel", {
            Name = "Description",
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 10, 0, currentY),
            BackgroundTransparency = 1,
            Text = description,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextWrapped = true,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 1001,
            Parent = dialogFrame
        })
        currentY = currentY + descLabel.AbsoluteSize.Y + 10
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
            ClearTextOnFocus = false,
            ZIndex = 1001,
            Parent = dialogFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = inputBox})
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = inputBox})
        currentY = currentY + 42
    end
    local buttonContainer = CreateInstance("Frame", {
        Name = "ButtonContainer",
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 10, 0, currentY + 10),
        BackgroundTransparency = 1,
        ZIndex = 1001,
        Parent = dialogFrame
    })
    local cancelButton = CreateInstance("TextButton", {
        Name = "CancelButton",
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.3,
        Text = cancelText,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        ZIndex = 1002,
        Parent = buttonContainer
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
        ZIndex = 1002,
        Parent = buttonContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = confirmButton})
    local totalHeight = currentY + 60
    dialogFrame.Size = UDim2.new(0, 400, 0, totalHeight)
    dialogFrame.Position = UDim2.new(0.5, -200, 0.5, -totalHeight/2)
    local function animateClose()
        Tween(overlay, {BackgroundTransparency = 1}, 0.2):Wait()
        dialogGui:Destroy()
        for i, d in ipairs(WasUI.ActiveDialogs) do if d == dialogGui then table.remove(WasUI.ActiveDialogs, i) break end end
    end
    cancelButton.MouseButton1Click:Connect(function()
        if onCancel then onCancel() end
        animateClose()
    end)
    confirmButton.MouseButton1Click:Connect(function()
        if onConfirm then onConfirm(inputBox and inputBox.Text) end
        animateClose()
    end)
    Tween(overlay, {BackgroundTransparency = 0.5}, 0.2)
    table.insert(WasUI.ActiveDialogs, dialogGui)
    return dialogGui
end

local Panel = {}
Panel.__index = Panel

function Panel:New(name, parent, size, position, titleTag)
    local self = setmetatable({}, Panel)
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
    AddRipple(self.Instance)
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Instance
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.TitleBar})
    self.DraggableArea = CreateInstance("TextButton", {
        Name = "DraggableArea",
        Size = UDim2.new(1, 0, 1, 0),
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
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.X,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    WasUI:SetLocalizedText(self.Title, name)
    if titleTag then
        local titleTags = type(titleTag) == "table" and titleTag or {titleTag}
        local titleContainer = CreateInstance("Frame", {
            Name = "TitleContainer",
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, 60, 0, 0),
            BackgroundTransparency = 1,
            ZIndex = 2,
            Parent = self.TitleBar
        })
        CreateInstance("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = titleContainer
        })
        self.Title.Parent = titleContainer
        self.Title.Size = UDim2.new(0, self.Title.TextBounds.X, 1, 0)
        for _, tag in ipairs(titleTags) do
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
                ZIndex = 11,
                Parent = tagContainer
            })
            tagContainer.Size = UDim2.new(0, tagLabel.TextBounds.X + 8, 0, 18)
        end
    end
    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 10, 0, 0.8),
        BackgroundTransparency = 1,
        ZIndex = 3,
        Parent = self.TitleBar
    })
    self.CloseDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 1.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.CloseDot})
    self.CloseDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetVisible(false)
        end
    end)
    local closeButton = CreateInstance("ImageButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0, 2),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        ZIndex = 40,
        Parent = self.TitleBar
    })
    local closeIcon = WasUI:CreateIcon("circle-x", UDim2.new(0, 18, 0, 18))
    if closeIcon then
        closeIcon.Parent = closeButton
        closeIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    end
    closeButton.MouseButton1Click:Connect(function()
        WasUI:ShowConfirmDialog({
            title = WasUI.DialogTitle,
            confirmText = "确认关闭",
            cancelText = "取消",
            onConfirm = function()
                self:SetVisible(false)
            end
        })
    end)
    local dragging = false
    local dragStart, startPos
    self.DraggableArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = self.Instance.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            self.Instance.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
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
    self.Avatar = CreateInstance("ImageButton", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(240, 240, 245),
        Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60),
        AutoButtonColor = false,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    self.Avatar.MouseButton1Click:Connect(function()
        if WasUI.SettingsGui then
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
            Visible = true,
            ZIndex = 999,
            Parent = settingsGui
        })
        local settingsFrame = CreateInstance("Frame", {
            Name = "SettingsPanel",
            Size = UDim2.new(0, 300, 0, 380),
            Position = UDim2.new(0.5, -150, 0.5, -190),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 1,
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
            BackgroundColor3 = WasUI.CurrentTheme.Background:lerp(Color3.fromRGB(0,0,0), 0.2),
            BackgroundTransparency = 0.3,
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
        WasUI:SetLocalizedText(titleLabel, "默认配置")
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
            Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2):Wait()
            settingsGui:Destroy()
            WasUI.SettingsGui = nil
            WasUI.SettingsPanel = nil
        end)
        local contentFrame = CreateInstance("ScrollingFrame", {
            Name = "Content",
            Size = UDim2.new(1, -20, 1, -40),
            Position = UDim2.new(0, 10, 0, 40),
            BackgroundTransparency = 1,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ZIndex = 1001,
            Parent = settingsFrame
        })
        local contentLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 8),
            Parent = contentFrame
        })
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = contentFrame})
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
        WasUI:SetLocalizedText(themeLabel, "设置默认主题")
        local themeDropdown = CreateInstance("TextButton", {
            Name = "ThemeDropdown",
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            Text = WasUI.DefaultTheme,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = themeDropdown})
        local themeNames = {"Dark", "Light", "Blue"}
        themeDropdown.MouseButton1Click:Connect(function()
            local current = themeDropdown.Text
            local idx = 1
            for i, n in ipairs(themeNames) do if n == current then idx = i break end end
            idx = idx % #themeNames + 1
            themeDropdown.Text = themeNames[idx]
            WasUI:SetDefaultTheme(themeNames[idx])
        end)
        
        local rainbowLabel = CreateInstance("TextLabel", {
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
        WasUI:SetLocalizedText(rainbowLabel, "设置默认彩虹风格")
        local rainbowBtn = CreateInstance("TextButton", {
            Name = "RainbowModeButton",
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            Text = WasUI.DefaultRainbowMode,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = rainbowBtn})
        rainbowBtn.MouseButton1Click:Connect(function()
            local newMode = rainbowBtn.Text == "整体" and "流动" or "整体"
            rainbowBtn.Text = newMode
            WasUI:SetDefaultRainbowMode(newMode)
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
        WasUI:SetLocalizedText(snowTitle, "雪花飘落开关")
        local snowBg = CreateInstance("ImageButton", {
            Name = "SnowBG",
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -40, 0.5, -9),
            BackgroundColor3 = WasUI.CurrentTheme.Error,
            Image = "",
            AutoButtonColor = false,
            ZIndex = 1003,
            Parent = snowContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowBg})
        local snowKnob = CreateInstance("Frame", {
            Name = "SnowKnob",
            Size = UDim2.new(0, 16, 0, 16),
            Position = UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            ZIndex = 1004,
            Parent = snowBg
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowKnob})
        local snowEnabled = false
        local function updateSnowToggle(state)
            snowEnabled = state
            if state then
                Tween(snowBg, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                SpringTween(snowKnob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
            else
                Tween(snowBg, {BackgroundColor3 = WasUI.CurrentTheme.Error}, 0.2)
                SpringTween(snowKnob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            end
        end
        snowBg.MouseButton1Click:Connect(function() updateSnowToggle(not snowEnabled) end)
        
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
        WasUI:SetLocalizedText(langTitle, "切换当前语言")
        local langBg = CreateInstance("ImageButton", {
            Name = "LangBG",
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -40, 0.5, -9),
            BackgroundColor3 = WasUI.CurrentLanguage == "English" and WasUI.CurrentTheme.Success or WasUI.CurrentTheme.Error,
            Image = "",
            AutoButtonColor = false,
            ZIndex = 1003,
            Parent = langContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = langBg})
        local langKnob = CreateInstance("Frame", {
            Name = "LangKnob",
            Size = UDim2.new(0, 16, 0, 16),
            Position = WasUI.CurrentLanguage == "English" and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
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
                Tween(langBg, {BackgroundColor3 = WasUI.CurrentTheme.Error}, 0.2)
                SpringTween(langKnob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
                WasUI:SetLanguage("中文")
            end
        end
        langBg.MouseButton1Click:Connect(function() updateLangToggle(WasUI.CurrentLanguage ~= "English") end)
        
        local copyButton = CreateInstance("TextButton", {
            Name = "CopyButton",
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
        WasUI:SetLocalizedText(copyButton, "复制你的自定义项目")
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 16), Parent = copyButton})
        copyButton.MouseButton1Click:Connect(function()
            copyToClipboard("loadstring(game:HttpGet('https://raw.githubusercontent.com/WasKKal/WasUI-For-Roblox/main/WasUI.lua'))()")
            WasUI:Notify({Title = "调试", Content = "链接已复制", Duration = 2})
        end)
        
        refreshCanvas()
        Tween(settingsFrame, {BackgroundTransparency = 0.2}, 0.25)
        clickCatcher.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                local framePos = settingsFrame.AbsolutePosition
                local frameSize = settingsFrame.AbsoluteSize
                if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                    Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2):Wait()
                    settingsGui:Destroy()
                    WasUI.SettingsGui = nil
                    WasUI.SettingsPanel = nil
                end
            end
        end)
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
    WasUI:SetLocalizedText(self.WelcomeLabel, "调试版本")
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
    CreateInstance("Frame", {
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
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = self.TabBar
    })
    local tabListLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabContainer
    })
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = self.TabContainer})
    local function updateTabBarHeight()
        local h = self.TabContainer.AbsoluteSize.Y
        if h > 0 then
            self.TabBar.Size = UDim2.new(1, 0, 0, h)
            self.ContentArea.Position = UDim2.new(0, 0, 0, 26 + 80 + h)
            self.ContentArea.Size = UDim2.new(1, 0, 1, -(26 + 80 + h))
        end
    end
    self.TabContainer:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateTabBarHeight)
    tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabContainer.CanvasSize = UDim2.new(0, tabListLayout.AbsoluteContentSize.X + 8, 0, 0)
        updateTabBarHeight()
    end)
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -(26 + 80 + self.TabBar.AbsoluteSize.Y)),
        Position = UDim2.new(0, 0, 0, 26 + 80 + self.TabBar.AbsoluteSize.Y),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 2,
        Parent = self.Instance
    })
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = self.ContentArea})
    local contentListLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = self.ContentArea
    })
    contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentListLayout.AbsoluteContentSize.Y + 8)
    end)
    self.Tabs = {}
    self.ActiveTab = nil
    self.TabOrderCounter = 0
    function self:AddTab(tabName)
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
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), Parent = tabFrame})
        tabInnerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentListLayout.AbsoluteContentSize.Y + 8)
        end)
        tabButton.MouseButton1Click:Connect(function() self:SetActiveTab(tabName) end)
        self.Tabs[tabName] = {Button = tabButton, Underline = tabUnderline, Frame = tabFrame}
        if not self.ActiveTab then self:SetActiveTab(tabName) end
        return tabFrame
    end
    function self:SetActiveTab(tabName)
        if self.ActiveTab and self.Tabs[self.ActiveTab] then
            local old = self.Tabs[self.ActiveTab]
            old.Underline.Visible = false
            old.Frame.Visible = false
        end
        local new = self.Tabs[tabName]
        if not new then return end
        new.Underline.Size = UDim2.new(0, 0, 0, 2)
        new.Underline.Visible = true
        Tween(new.Underline, {Size = UDim2.new(1, 0, 0, 2)}, 0.25)
        new.Frame.Visible = true
        self.ActiveTab = tabName
    end
    function self:SetVisible(visible)
        self.Instance.Visible = visible
    end
    function self:SetTitle(text)
        WasUI:SetLocalizedText(self.Title, text)
    end
    function self:SetWelcome(text)
        WasUI:SetLocalizedText(self.WelcomeLabel, text)
    end
    self.CurrentCategory = nil
    function self:SetCurrentCategory(cat) self.CurrentCategory = cat end
    function self:GetCurrentCategory() return self.CurrentCategory end
    self.Instance.BackgroundTransparency = 1
    self.Instance.Size = UDim2.new(0, 0, 0, 0)
    self.Instance.Position = UDim2.new(0.5, 0, 0.5, 0)
    Tween(self.Instance, {BackgroundTransparency = 0.3, Size = size or UDim2.new(0, 380, 0, 350), Position = position or UDim2.new(0.5, -190, 0.5, -175)}, 0.25)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Panel"})
    return self
end

function WasUI:CreateWindow(title, size, position, titleTag)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WasUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = WasUI.DefaultDisplayOrder
    screenGui.Parent = game:GetService("CoreGui")
    local window = Panel:New(title, screenGui, size, position, titleTag)
    window:SetTitle(title)
    return window
end

function WasUI:CreateButton(parent, text, onClick, size, iconName)
    return Button:New("Button", parent, text, onClick, size, iconName)
end

function WasUI:CreateToggle(parent, title, initialState, onToggle)
    return ToggleSwitch:New("Toggle", parent, title, initialState, onToggle)
end

function WasUI:CreateLabel(parent, text)
    return Label:New("Label", parent, text)
end

function WasUI:CreateCategory(parent, title, iconName)
    return Category:New("Category", parent, title, iconName)
end

function WasUI:CreateDropdown(parent, title, options, defaultValue, callback, multiSelect)
    return Dropdown:New("Dropdown", parent, title, options, defaultValue, callback, multiSelect)
end

function WasUI:CreateSlider(parent, title, min, max, defaultValue, callback)
    return Slider:New("Slider", parent, title, min, max, defaultValue, callback)
end

function WasUI:CreateTextInput(parent, placeholder, defaultValue, callback)
    return TextInput:New("TextInput", parent, placeholder, defaultValue, callback)
end

function WasUI:AddSpacing(parent, height)
    local spacing = Instance.new("Frame")
    spacing.Name = "Spacing"
    spacing.Size = UDim2.new(1, 0, 0, height or 4)
    spacing.BackgroundTransparency = 1
    spacing.Parent = parent
end

task.spawn(function()
    local success, langTable = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/WasKKal/WasUI-For-Roblox/main/CnToEng.lua"))()
    end)
    if success and type(langTable) == "table" then
        WasUI:LoadLanguageTable(langTable)
    end
end)

_G.WasUIDebugModule = WasUI
return WasUI