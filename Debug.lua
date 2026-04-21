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
WasUI.Version = "开发者端"

WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}

WasUI.SettingsPanel = nil
WasUI.GroupButtonText = "加入WasUI主群"
WasUI.GroupCopyContent = "786284990"

WasUI.ConfigFolderName = "WasUI_Configs"

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
        local fadeOut = Tween(frame, {BackgroundTransparency = 1, Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, frame.Position.Y.Offset)}, 0.3)
        if fadeOut then
            fadeOut.Completed:Connect(function()
                frame:Destroy()
            end)
        else
            frame:Destroy()
        end
    end)
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

    AddLongPressToControl(self.Instance, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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

    AddLongPressToControl(self.Background, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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

    AddLongPressToControl(self.Instance, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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

    AddLongPressToControl(self.Header, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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
            local fade = Tween(self.OptionsContainer, {BackgroundTransparency = 1}, 0.2)
            if fade then
                fade.Completed:Connect(function()
                    self.OptionsContainer.Visible = false
                end)
            else
                self.OptionsContainer.Visible = false
            end
        end
    end
    self.DropdownButton.MouseButton1Click:Connect(function()
        if self.IsOpen then self:Close() else self:Open() end
    end)
    AddRipple(self.DropdownButton)
    rebuildOptions()
    self:UpdateDisplayText()

    AddLongPressToControl(self.DropdownButton, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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

    AddLongPressToControl(self.SliderTrack, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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

    AddLongPressToControl(self.TextBox, function()
        ShowControlConfigurator(parent, self)
    end, 1.5)

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
        local fade = Tween(overlay, {BackgroundTransparency = 1}, 0.2)
        if fade then
            fade.Completed:Wait()
        end
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
        local fade = Tween(overlay, {BackgroundTransparency = 1}, 0.2)
        if fade then
            fade.Completed:Wait()
        end
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
                highlightStroke.Transparency = 0.7
                local pulse = (math.sin(tick() * 0.5) + 1) / 2
                highlightStroke.Transparency = 0.5 + pulse * 0.3
            else
                self.FlowRotation = (self.FlowRotation + deltaTime * 45) % 360
                flowGradient.Rotation = self.FlowRotation
                flowGradient.Enabled = true
                self.BorderStroke.Transparency = 1
                highlightStroke.Transparency = 0.7
                local pulse = (math.sin(tick() * 0.5) + 1) / 2
                highlightStroke.Transparency = 0.5 + pulse * 0.3
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

    startFlowAnimation()
    self:SetRainbowMode(self.RainbowMode)

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
    
    AddLongPressToControl(self.TitleBar, function()
        WasUI:ShowConfirmDialog({
            title = "编辑窗口标题",
            showInput = true,
            inputPlaceholder = "新标题",
            inputDefault = self.Title.Text,
            confirmText = "保存",
            cancelText = "取消",
            onConfirm = function(newTitle)
                if newTitle and newTitle ~= "" then
                    self:SetTitle(newTitle)
                    WasUI:Notify({Title = "标题", Content = "已更新窗口标题", Duration = 1.5})
                end
            end
        })
    end, 1.5)
    
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
    self.MinimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 16.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.MinimizeDot})
    self.MaximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 31.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.DotContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.MaximizeDot})
    self.DotAreaButton = CreateInstance("ImageButton", {
        Name = "DotAreaButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 4,
        Parent = self.DotContainer
    })
    self.IsMinimized = false
    self.OriginalSize = self.Instance.Size
    self.MinimizedSize = UDim2.new(0, 60, 0, 26)
    self.MinimizedCustomText = ""
    self.MinimizedTextLabel = CreateInstance("TextLabel", {
        Name = "MinimizedText",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0.5, 5, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
        ZIndex = 10,
        Parent = self.DotContainer
    })
    function self:SetMinimizedText(text)
        self.MinimizedCustomText = text or ""
        self.MinimizedTextLabel.Text = text or ""
    end
    local function minimizeToDots()
        if self.IsMinimized then return end
        for i = #WasUI.OpenDropdowns, 1, -1 do
            local dd = WasUI.OpenDropdowns[i]
            if dd and dd.Close then dd:Close(true) end
        end
        for _, dlg in ipairs(WasUI.ActiveDialogs) do
            if dlg and dlg.Parent then dlg:Destroy() end
        end
        WasUI.ActiveDialogs = {}
        if WasUI.SettingsGui then
            WasUI.SettingsGui:Destroy()
            WasUI.SettingsGui = nil
            WasUI.SettingsPanel = nil
        end
        local dots = {self.CloseDot, self.MinimizeDot, self.MaximizeDot}
        for _, dot in ipairs(dots) do Tween(dot, {BackgroundTransparency = 1}, 0.3) end
        if self.MinimizedCustomText ~= "" then
            self.MinimizedTextLabel.Visible = true
            self.MinimizedTextLabel.TextTransparency = 1
            Tween(self.MinimizedTextLabel, {TextTransparency = 0}, 0.3)
        end
        Tween(self.Instance, {Size = self.MinimizedSize, Position = self.Instance.Position}, 0.3, Enum.EasingStyle.Quint)
        if self.TitleContainer then self.TitleContainer.Visible = false elseif self.Title then self.Title.Visible = false end
        if self.AnnouncementBar then self.AnnouncementBar.Visible = false end
        if self.TabBar then self.TabBar.Visible = false end
        if self.ContentArea then self.ContentArea.Visible = false end
        if self.DraggableArea then self.DraggableArea.Visible = false end
        if self.DotContainer then self.DotContainer.Visible = true end
        self.IsMinimized = true
    end
    local function restoreFromDots()
        if not self.IsMinimized then return end
        local dots = {self.CloseDot, self.MinimizeDot, self.MaximizeDot}
        for _, dot in ipairs(dots) do Tween(dot, {BackgroundTransparency = 0}, 0.3) end
        if self.MinimizedCustomText ~= "" then
            Tween(self.MinimizedTextLabel, {TextTransparency = 1}, 0.3)
            task.delay(0.3, function() self.MinimizedTextLabel.Visible = false end)
        end
        Tween(self.Instance, {Size = self.OriginalSize, Position = self.Instance.Position}, 0.3, Enum.EasingStyle.Quint)
        if self.TitleContainer then self.TitleContainer.Visible = true elseif self.Title then self.Title.Visible = true end
        if self.AnnouncementBar then self.AnnouncementBar.Visible = true end
        if self.TabBar then self.TabBar.Visible = true end
        if self.ContentArea then self.ContentArea.Visible = true end
        if self.DraggableArea then self.DraggableArea.Visible = true end
        if self.DotContainer then self.DotContainer.Visible = true end
        self.IsMinimized = false
    end
    self.DotAreaButton.MouseButton1Click:Connect(function()
        if self.IsMinimized then restoreFromDots() else minimizeToDots() end
    end)
    self.CloseDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then self:SetVisible(false) end
    end)
    self.MinimizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.IsMinimized then restoreFromDots() else minimizeToDots() end
        end
    end)
    self.MaximizeDot.InputBegan:Connect(function() end)
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
                if self.BorderConnection then self.BorderConnection:Disconnect() end
                if self.BorderFlow then self.BorderFlow:Destroy() end
                for _, dlg in ipairs(WasUI.ActiveDialogs) do if dlg then dlg:Destroy() end end
                WasUI.ActiveDialogs = {}
                if WasUI.SettingsGui then WasUI.SettingsGui:Destroy(); WasUI.SettingsGui = nil; WasUI.SettingsPanel = nil end
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
            Size = UDim2.new(0, 300, 0, 400),
            Position = UDim2.new(0.5, -150, 0.5, -200),
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
            local fade = Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
            if fade then
                fade.Completed:Wait()
            end
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
        
        local folderLabel = CreateInstance("TextLabel", {
            Name = "FolderLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "配置文件夹名称",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(folderLabel, "配置文件夹名称")
        local folderInput = CreateInstance("TextBox", {
            Name = "FolderInput",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Text = WasUI.ConfigFolderName,
            PlaceholderText = "WasUI_Configs",
            TextColor3 = WasUI.CurrentTheme.Text,
            PlaceholderColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = folderInput})
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = folderInput})
        folderInput:GetPropertyChangedSignal("Text"):Connect(function()
            WasUI.ConfigFolderName = folderInput.Text
        end)
        
        local groupTextLabel = CreateInstance("TextLabel", {
            Name = "GroupTextLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "群按钮文字",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(groupTextLabel, "群按钮文字")
        local groupTextInput = CreateInstance("TextBox", {
            Name = "GroupTextInput",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Text = WasUI.GroupButtonText,
            PlaceholderText = "加入WasUI主群",
            TextColor3 = WasUI.CurrentTheme.Text,
            PlaceholderColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = groupTextInput})
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = groupTextInput})
        groupTextInput:GetPropertyChangedSignal("Text"):Connect(function()
            WasUI.GroupButtonText = groupTextInput.Text
        end)
        
        local groupCopyLabel = CreateInstance("TextLabel", {
            Name = "GroupCopyLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "群复制内容",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        WasUI:SetLocalizedText(groupCopyLabel, "群复制内容")
        local groupCopyInput = CreateInstance("TextBox", {
            Name = "GroupCopyInput",
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Text = WasUI.GroupCopyContent,
            PlaceholderText = "786284990",
            TextColor3 = WasUI.CurrentTheme.Text,
            PlaceholderColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            ClearTextOnFocus = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = groupCopyInput})
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = groupCopyInput})
        groupCopyInput:GetPropertyChangedSignal("Text"):Connect(function()
            WasUI.GroupCopyContent = groupCopyInput.Text
        end)
        
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
            local code = GenerateExportCode(self)
            copyToClipboard(code)
            WasUI:Notify({Title = "调试", Content = "配置源码已复制", Duration = 2})
        end)
        
        refreshCanvas()
        Tween(settingsFrame, {BackgroundTransparency = 0.2}, 0.25)
        clickCatcher.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = input.Position
                local framePos = settingsFrame.AbsolutePosition
                local frameSize = settingsFrame.AbsoluteSize
                if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                    local fade = Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
                    if fade then
                        fade.Completed:Wait()
                    end
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
    
    AddLongPressToControl(self.WelcomeLabel, function()
        WasUI:ShowConfirmDialog({
            title = "编辑欢迎语",
            showInput = true,
            inputPlaceholder = "新欢迎语",
            inputDefault = self.WelcomeLabel.Text,
            confirmText = "保存",
            cancelText = "取消",
            onConfirm = function(newText)
                if newText and newText ~= "" then
                    self:SetWelcome(newText)
                    WasUI:Notify({Title = "欢迎语", Content = "已更新欢迎语", Duration = 1.5})
                end
            end
        })
    end, 1.5)
    
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
    
    self.AddTabButton = CreateInstance("TextButton", {
        Name = "AddTabButton",
        Size = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = WasUI.CurrentTheme.TabButton,
        BackgroundTransparency = 0.5,
        Text = "+",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = self.TabContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.AddTabButton})
    self.AddTabButton.MouseButton1Click:Connect(function()
        WasUI:ShowConfirmDialog({
            title = "添加选项卡",
            showInput = true,
            inputPlaceholder = "输入选项卡名称",
            confirmText = "添加",
            cancelText = "取消",
            onConfirm = function(name)
                if name and name ~= "" then
                    self:AddTab(name)
                    WasUI:Notify({Title = "选项卡", Content = "已添加: " .. name, Duration = 1.5})
                end
            end
        })
    end)

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
        
        AddLongPressToControl(tabButton, function()
            WasUI:ShowConfirmDialog({
                title = "重命名选项卡",
                showInput = true,
                inputPlaceholder = "新名称",
                inputDefault = tabName,
                confirmText = "重命名",
                cancelText = "删除",
                onConfirm = function(newName)
                    if newName and newName ~= "" and newName ~= tabName then
                        tabButton.Text = newName
                        WasUI:SetLocalizedText(tabButton, newName)
                        self.Tabs[newName] = self.Tabs[tabName]
                        self.Tabs[tabName] = nil
                        if self.ActiveTab == tabName then self.ActiveTab = newName end
                        WasUI:Notify({Title = "选项卡", Content = "已重命名为: " .. newName, Duration = 1.5})
                    end
                end,
                onCancel = function()
                    WasUI:ShowConfirmDialog({
                        title = "删除选项卡",
                        description = "确定要删除选项卡 \"" .. tabName .. "\" 吗？",
                        confirmText = "删除",
                        cancelText = "取消",
                        onConfirm = function()
                            tabButton:Destroy()
                            tabFrame:Destroy()
                            self.Tabs[tabName] = nil
                            if self.ActiveTab == tabName then
                                local nextTab = next(self.Tabs)
                                if nextTab then self:SetActiveTab(nextTab) else self.ActiveTab = nil end
                            end
                            WasUI:Notify({Title = "选项卡", Content = "已删除", Duration = 1.5})
                        end
                    })
                end
            })
        end, 1.5)
        
        local addControlBtn = CreateInstance("TextButton", {
            Name = "AddControlButton",
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = "+ 添加控件",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 2,
            Parent = tabFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = addControlBtn})
        addControlBtn.MouseButton1Click:Connect(function()
            ShowControlConfigurator(tabFrame)
        end)
        self.Tabs[tabName] = {Button = tabButton, Underline = tabUnderline, Frame = tabFrame, AddControlBtn = addControlBtn}
        if not self.ActiveTab then self:SetActiveTab(tabName) end
        
        task.defer(updateTabBarHeight)
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
        if self.BorderFlow then self.BorderFlow.Visible = visible end
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
    
    task.defer(updateTabBarHeight)
    return self
end

function ShowControlConfigurator(parentFrame, existingControl)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ControlConfigurator"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 2000
    gui.IgnoreGuiInset = true
    gui.Parent = game:GetService("CoreGui")

    local overlay = CreateInstance("Frame", {
        Name = "Overlay",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        Selectable = true,
        ZIndex = 999,
        Parent = gui
    })

    local mainFrame = CreateInstance("Frame", {
        Name = "ConfigFrame",
        Size = UDim2.new(0, 380, 0, 420),
        Position = UDim2.new(0.5, -190, 0.5, -210),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 0.2,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1000,
        Parent = overlay
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = mainFrame})
    local stroke = CreateInstance("UIStroke", {
        Color = WasUI.CurrentTheme.Accent,
        Thickness = 1,
        Transparency = 0.5,
        Parent = mainFrame
    })

    local saveBtn = CreateInstance("ImageButton", {
        Name = "SaveBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 6),
        BackgroundTransparency = 0.3,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 1003,
        Parent = mainFrame
    })
    local saveBg = Instance.new("Frame")
    saveBg.Size = UDim2.new(1, 0, 1, 0)
    saveBg.BackgroundColor3 = WasUI.CurrentTheme.Section
    saveBg.BackgroundTransparency = 0.5
    saveBg.BorderSizePixel = 0
    saveBg.Parent = saveBtn
    local saveCorner = Instance.new("UICorner")
    saveCorner.CornerRadius = UDim.new(1, 0)
    saveCorner.Parent = saveBg
    local saveIcon = WasUI:CreateIcon("save", UDim2.new(0, 20, 0, 20))
    if saveIcon then
        saveIcon.Parent = saveBtn
        saveIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
        saveIcon.ZIndex = 1004
    end
    local closeBtn = CreateInstance("ImageButton", {
        Name = "CloseBtn",
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -68, 0, 6),
        BackgroundTransparency = 0.3,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 1003,
        Parent = mainFrame
    })
    local closeBg = Instance.new("Frame")
    closeBg.Size = UDim2.new(1, 0, 1, 0)
    closeBg.BackgroundColor3 = WasUI.CurrentTheme.Section
    closeBg.BackgroundTransparency = 0.5
    closeBg.BorderSizePixel = 0
    closeBg.Parent = closeBtn
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBg
    local closeIcon = WasUI:CreateIcon("x", UDim2.new(0, 20, 0, 20))
    if closeIcon then
        closeIcon.Parent = closeBtn
        closeIcon.Position = UDim2.new(0.5, -10, 0.5, -10)
        closeIcon.ZIndex = 1004
    end

    local content = CreateInstance("ScrollingFrame", {
        Name = "Content",
        Size = UDim2.new(1, -20, 1, -45),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ZIndex = 1001,
        Parent = mainFrame
    })
    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = content
    })
    CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = content})

    local function refreshCanvas()
        content.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 12)
    end
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

    local modeContainer = CreateInstance("Frame", {
        Name = "ModeContainer",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 1002,
        Parent = content
    })
    local modeLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = modeContainer
    })

    local controlTypeContainer = CreateInstance("Frame", {
        Name = "ControlTypeContainer",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 1002,
        Parent = content
    })
    local controlTypeLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = controlTypeContainer
    })
    local controlTypeLabel = CreateInstance("TextLabel", {
        Name = "Label",
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundTransparency = 1,
        Text = "控件类型",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 1003,
        Parent = controlTypeContainer
    })
    WasUI:SetLocalizedText(controlTypeLabel, "控件类型")
    local controlTypes = {"按钮", "开关", "滑块", "下拉菜单", "文本输入", "标签", "小标题"}
    local currentControlType = existingControl and (existingControl.Name or "按钮") or "按钮"
    if currentControlType == "Button" then currentControlType = "按钮"
    elseif currentControlType == "Toggle" then currentControlType = "开关"
    elseif currentControlType == "Slider" then currentControlType = "滑块"
    elseif currentControlType == "Dropdown" then currentControlType = "下拉菜单"
    elseif currentControlType == "TextInput" then currentControlType = "文本输入"
    elseif currentControlType == "Label" then currentControlType = "标签"
    elseif currentControlType == "Category" then currentControlType = "小标题"
    end
    local controlTypeBtn = CreateInstance("TextButton", {
        Name = "ControlTypeBtn",
        Size = UDim2.new(0, 90, 0, 24),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        Text = currentControlType,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 1003,
        Parent = controlTypeContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = controlTypeBtn})
    controlTypeBtn.MouseButton1Click:Connect(function()
        local idx = 1
        for i, t in ipairs(controlTypes) do if t == currentControlType then idx = i break end end
        idx = idx % #controlTypes + 1
        currentControlType = controlTypes[idx]
        controlTypeBtn.Text = currentControlType
        updateModeAndContent()
    end)

    local dynamicContent = CreateInstance("Frame", {
        Name = "DynamicContent",
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 1002,
        Parent = content
    })
    local dynamicLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = dynamicContent
    })
    dynamicLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshCanvas)

    local currentElements = {}
    local modeButtons = {}
    local currentMode = "Remote"
    local sliderMode = "属性"
    local dropdownDataMode = "直接子对象"
    local fixedDataUnits = {}
    local manualItems = {}

    local function clearDynamicContent()
        for _, elem in ipairs(currentElements) do
            elem:Destroy()
        end
        currentElements = {}
    end

    local function createInputField(placeholder, height, multiLine, defaultText)
        local box = CreateInstance("TextBox", {
            Size = UDim2.new(1, 0, 0, height or 30),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            PlaceholderText = placeholder or "",
            Text = defaultText or "",
            TextColor3 = WasUI.CurrentTheme.Text,
            PlaceholderColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            ClearTextOnFocus = false,
            TextWrapped = multiLine or false,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
            ZIndex = 1003,
            Parent = dynamicContent
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = box})
        CreateInstance("UIPadding", {PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), Parent = box})
        return box
    end

    local function createToggle(title, callback, initialState)
        local container = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = dynamicContent
        })
        local label = CreateInstance("TextLabel", {
            Size = UDim2.new(0.7, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1004,
            Parent = container
        })
        WasUI:SetLocalizedText(label, title)
        local bg = CreateInstance("ImageButton", {
            Size = UDim2.new(0, 32, 0, 16),
            Position = UDim2.new(1, -36, 0.5, -8),
            BackgroundColor3 = initialState and WasUI.CurrentTheme.Success or WasUI.CurrentTheme.Error,
            Image = "",
            AutoButtonColor = false,
            ZIndex = 1004,
            Parent = container
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = bg})
        local knob = CreateInstance("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = initialState and UDim2.new(1, -16, 0, 1) or UDim2.new(0, 1, 0, 1),
            BackgroundColor3 = Color3.fromRGB(255,255,255),
            ZIndex = 1005,
            Parent = bg
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knob})
        local state = initialState or false
        local function setState(s)
            state = s
            if s then
                Tween(bg, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                SpringTween(knob, {Position = UDim2.new(1, -16, 0, 1)}, 0.3)
            else
                Tween(bg, {BackgroundColor3 = WasUI.CurrentTheme.Error}, 0.2)
                SpringTween(knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            end
            if callback then callback(s) end
        end
        bg.MouseButton1Click:Connect(function() setState(not state) end)
        return container, setState
    end

    local function createCategory(title)
        local cat = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = dynamicContent
        })
        local label = CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 1004,
            Parent = cat
        })
        WasUI:SetLocalizedText(label, title)
        return cat
    end

    local function createSlider(title, minVal, maxVal, defaultVal, callback)
        local container = CreateInstance("Frame", {
            Name = "Slider",
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = dynamicContent
        })
        local titleLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(0.4, 0, 0, 16),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1004,
            Parent = container
        })
        WasUI:SetLocalizedText(titleLabel, title)
        local valueLabel = CreateInstance("TextLabel", {
            Size = UDim2.new(0.2, 0, 0, 16),
            Position = UDim2.new(0.8, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = tostring(defaultVal),
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Right,
            ZIndex = 1004,
            Parent = container
        })
        local track = CreateInstance("Frame", {
            Size = UDim2.new(1, -2, 0, 6),
            Position = UDim2.new(0, 2, 0, 18),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 1004,
            Parent = container
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = track})
        local fill = CreateInstance("Frame", {
            Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0),
            BackgroundColor3 = WasUI.CurrentTheme.Accent,
            BorderSizePixel = 0,
            ZIndex = 1004,
            Parent = track
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 3), Parent = fill})
        local knobFrame = CreateInstance("Frame", {
            Size = UDim2.new(0, 14, 0, 14),
            Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -7, 0.5, -7),
            BackgroundTransparency = 1,
            ZIndex = 1005,
            Parent = track
        })
        local knobCircle = CreateInstance("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = WasUI.CurrentTheme.Accent,
            BorderSizePixel = 0,
            Parent = knobFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = knobCircle})
        local knobScale = Instance.new("UIScale", knobCircle)
        local dragging = false
        local currentVal = defaultVal
        local function setValue(v)
            v = math.clamp(v, minVal, maxVal)
            if v == currentVal then return end
            currentVal = v
            valueLabel.Text = tostring(v)
            local t = (v - minVal) / (maxVal - minVal)
            fill.Size = UDim2.new(t, 0, 1, 0)
            knobFrame.Position = UDim2.new(t, -7, 0.5, -7)
            if callback then callback(v) end
        end
        local function updateFromMouse(x)
            local trackPos = track.AbsolutePosition
            local trackSize = track.AbsoluteSize.X
            if trackSize <= 0 then return end
            local t = math.clamp((x - trackPos.X) / trackSize, 0, 1)
            setValue(math.round(minVal + t * (maxVal - minVal)))
        end
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                SpringTween(knobScale, {Scale = 1.2}, 0.15)
                updateFromMouse(input.Position.X)
            end
        end)
        track.InputEnded:Connect(function()
            dragging = false
            SpringTween(knobScale, {Scale = 1}, 0.25)
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                updateFromMouse(input.Position.X)
            end
        end)
        return container, setValue
    end

    local function addManualItem(parent, index)
        local container = CreateInstance("Frame", {
            Name = "ManualItem_" .. index,
            Size = UDim2.new(1, 0, 0, 60),
            BackgroundTransparency = 1,
            ZIndex = 1003,
            Parent = parent
        })
        local nameInput = createInputField("项目名称", 30, false, "")
        nameInput.Parent = container
        nameInput.Size = UDim2.new(1, 0, 0, 30)
        local deleteBtn = CreateInstance("TextButton", {
            Name = "DeleteItemBtn",
            Size = UDim2.new(0, 100, 0, 24),
            Position = UDim2.new(1, -105, 0, 32),
            BackgroundColor3 = WasUI.CurrentTheme.Error,
            BackgroundTransparency = 0.3,
            Text = "删除项目",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 11,
            AutoButtonColor = false,
            ZIndex = 1004,
            Parent = container
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = deleteBtn})
        deleteBtn.MouseButton1Click:Connect(function()
            WasUI:ShowConfirmDialog({
                title = "删除项目",
                description = "确定要删除该项目吗？",
                confirmText = "删除",
                cancelText = "取消",
                onConfirm = function()
                    container:Destroy()
                    for i, item in ipairs(manualItems) do
                        if item == container then
                            table.remove(manualItems, i)
                            break
                        end
                    end
                    refreshCanvas()
                end
            })
        end)
        return container
    end

    local function updateModeAndContent()
        clearDynamicContent()
        
        if currentControlType == "滑块" then
            for _, btn in ipairs(modeButtons) do btn:Destroy() end
            modeButtons = {}
            local sliderModes = {"属性", "间隔", "大小"}
            for _, modeName in ipairs(sliderModes) do
                local btn = CreateInstance("TextButton", {
                    Name = "SliderMode_" .. modeName,
                    Size = UDim2.new(0, 60, 0, 24),
                    BackgroundColor3 = modeName == sliderMode and WasUI.CurrentTheme.Accent or WasUI.CurrentTheme.Primary,
                    BackgroundTransparency = 0.3,
                    Text = modeName,
                    TextColor3 = WasUI.CurrentTheme.Text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 1003,
                    Parent = modeContainer
                })
                CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = btn})
                btn.MouseButton1Click:Connect(function()
                    sliderMode = modeName
                    for _, b in ipairs(modeButtons) do
                        Tween(b, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
                    end
                    Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.2)
                    updateModeAndContent()
                end)
                table.insert(modeButtons, btn)
            end
            
            local sliderTitle = createInputField("滑块标题", 30)
            sliderTitle.Name = "SliderTitle"
            table.insert(currentElements, sliderTitle)
            local minInput = createInputField("最小值", 30)
            minInput.Name = "Min"
            table.insert(currentElements, minInput)
            local maxInput = createInputField("最大值", 30)
            maxInput.Name = "Max"
            table.insert(currentElements, maxInput)
            local defaultInput = createInputField("默认值", 30)
            defaultInput.Name = "Default"
            table.insert(currentElements, defaultInput)
            
            if sliderMode == "属性" then
                local configKeyInput = createInputField("Config Key (留空则不保存)", 30)
                configKeyInput.Name = "ConfigKey"
                table.insert(currentElements, configKeyInput)
                local notifyContainer, setNotify = createToggle("绑定通知", function(enabled)
                    for i = #currentElements, 1, -1 do
                        local elem = currentElements[i]
                        if elem:IsA("TextBox") and (elem.PlaceholderText == "开启标题" or elem.PlaceholderText == "开启内容" or elem.PlaceholderText == "关闭标题" or elem.PlaceholderText == "关闭内容") then
                            local fade = Tween(elem, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                            if fade then
                                fade.Completed:Connect(function()
                                    if not enabled then elem:Destroy() table.remove(currentElements, i) end
                                end)
                            else
                                if not enabled then elem:Destroy() table.remove(currentElements, i) end
                            end
                        end
                    end
                    if enabled then
                        local onTitle = createInputField("开启标题", 30)
                        onTitle.Size = UDim2.new(1, 0, 0, 0); onTitle.BackgroundTransparency = 1
                        table.insert(currentElements, onTitle)
                        Tween(onTitle, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                        local onContent = createInputField("开启内容", 30)
                        onContent.Size = UDim2.new(1, 0, 0, 0); onContent.BackgroundTransparency = 1
                        table.insert(currentElements, onContent)
                        Tween(onContent, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                        local offTitle = createInputField("关闭标题", 30)
                        offTitle.Size = UDim2.new(1, 0, 0, 0); offTitle.BackgroundTransparency = 1
                        table.insert(currentElements, offTitle)
                        Tween(offTitle, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                        local offContent = createInputField("关闭内容", 30)
                        offContent.Size = UDim2.new(1, 0, 0, 0); offContent.BackgroundTransparency = 1
                        table.insert(currentElements, offContent)
                        Tween(offContent, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    end
                end)
                table.insert(currentElements, notifyContainer)
            end
        elseif currentControlType == "下拉菜单" then
            for _, btn in ipairs(modeButtons) do btn:Destroy() end
            modeButtons = {}
            local ddModes = {"直接子对象", "子对象属性"}
            for _, modeName in ipairs(ddModes) do
                local btn = CreateInstance("TextButton", {
                    Name = "DDMode_" .. modeName,
                    Size = UDim2.new(0, 90, 0, 24),
                    BackgroundColor3 = modeName == dropdownDataMode and WasUI.CurrentTheme.Accent or WasUI.CurrentTheme.Primary,
                    BackgroundTransparency = 0.3,
                    Text = modeName,
                    TextColor3 = WasUI.CurrentTheme.Text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 1003,
                    Parent = modeContainer
                })
                CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = btn})
                btn.MouseButton1Click:Connect(function()
                    dropdownDataMode = modeName
                    for _, b in ipairs(modeButtons) do
                        Tween(b, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
                    end
                    Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.2)
                    updateModeAndContent()
                end)
                table.insert(modeButtons, btn)
            end
            
            local ddTitle = createInputField("标题", 30)
            ddTitle.Name = "DropdownTitle"
            table.insert(currentElements, ddTitle)
            
            if dropdownDataMode == "直接子对象" then
                local pathInput = createInputField("文件夹路径", 30)
                table.insert(currentElements, pathInput)
                local dynamicToggleContainer, setDynamic = createToggle("动态数据 (实时读取文件夹)", true)
                table.insert(currentElements, dynamicToggleContainer)
                
                local manualArea = CreateInstance("Frame", {
                    Name = "ManualArea",
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 1003,
                    Parent = dynamicContent
                })
                table.insert(currentElements, manualArea)
                
                local dynamic = true
                setDynamic(true)
                local function rebuildManualArea()
                    for _, child in ipairs(manualArea:GetChildren()) do child:Destroy() end
                    if not dynamic then
                        for i, item in ipairs(manualItems) do
                            item.Parent = manualArea
                        end
                        local addBtn = CreateInstance("TextButton", {
                            Name = "AddManualItemBtn",
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = WasUI.CurrentTheme.Success,
                            BackgroundTransparency = 0.3,
                            Text = "添加新项目",
                            TextColor3 = WasUI.CurrentTheme.Text,
                            Font = Enum.Font.GothamSemibold,
                            TextSize = 11,
                            AutoButtonColor = false,
                            ZIndex = 1004,
                            Parent = manualArea
                        })
                        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = addBtn})
                        addBtn.MouseButton1Click:Connect(function()
                            local newItem = addManualItem(manualArea, #manualItems + 1)
                            table.insert(manualItems, newItem)
                            rebuildManualArea()
                        end)
                    end
                end
                setDynamic(function(enabled)
                    dynamic = enabled
                    manualArea.Visible = not enabled
                    rebuildManualArea()
                    refreshCanvas()
                end)
                manualArea.Visible = false
            else
                local pathInput = createInputField("对象路径 (如 workspace.Model)", 30)
                table.insert(currentElements, pathInput)
                local propInput = createInputField("属性名称", 30)
                table.insert(currentElements, propInput)
                local dynamicToggleContainer, setDynamic = createToggle("动态数据 (实时读取属性)", true)
                table.insert(currentElements, dynamicToggleContainer)
                
                local manualArea = CreateInstance("Frame", {
                    Name = "ManualArea",
                    Size = UDim2.new(1, 0, 0, 0),
                    BackgroundTransparency = 1,
                    AutomaticSize = Enum.AutomaticSize.Y,
                    ZIndex = 1003,
                    Parent = dynamicContent
                })
                table.insert(currentElements, manualArea)
                
                local dynamic = true
                setDynamic(true)
                local function rebuildManualArea()
                    for _, child in ipairs(manualArea:GetChildren()) do child:Destroy() end
                    if not dynamic then
                        for i, item in ipairs(manualItems) do
                            item.Parent = manualArea
                        end
                        local addBtn = CreateInstance("TextButton", {
                            Name = "AddManualItemBtn",
                            Size = UDim2.new(1, 0, 0, 28),
                            BackgroundColor3 = WasUI.CurrentTheme.Success,
                            BackgroundTransparency = 0.3,
                            Text = "添加新项目",
                            TextColor3 = WasUI.CurrentTheme.Text,
                            Font = Enum.Font.GothamSemibold,
                            TextSize = 11,
                            AutoButtonColor = false,
                            ZIndex = 1004,
                            Parent = manualArea
                        })
                        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = addBtn})
                        addBtn.MouseButton1Click:Connect(function()
                            local newItem = addManualItem(manualArea, #manualItems + 1)
                            table.insert(manualItems, newItem)
                            rebuildManualArea()
                        end)
                    end
                end
                setDynamic(function(enabled)
                    dynamic = enabled
                    manualArea.Visible = not enabled
                    rebuildManualArea()
                    refreshCanvas()
                end)
                manualArea.Visible = false
            end
            
            local configKeyInput = createInputField("Config Key (留空则不保存)", 30)
            configKeyInput.Name = "ConfigKey"
            table.insert(currentElements, configKeyInput)
        else
            for _, btn in ipairs(modeButtons) do btn:Destroy() end
            modeButtons = {}
            local modes = {"Remote", "传送", "模拟按键"}
            for _, modeName in ipairs(modes) do
                local btn = CreateInstance("TextButton", {
                    Name = "Mode_" .. modeName,
                    Size = UDim2.new(0, 75, 0, 24),
                    BackgroundColor3 = modeName == currentMode and WasUI.CurrentTheme.Accent or WasUI.CurrentTheme.Primary,
                    BackgroundTransparency = 0.3,
                    Text = modeName,
                    TextColor3 = WasUI.CurrentTheme.Text,
                    Font = Enum.Font.GothamSemibold,
                    TextSize = 11,
                    AutoButtonColor = false,
                    ZIndex = 1003,
                    Parent = modeContainer
                })
                CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = btn})
                btn.MouseButton1Click:Connect(function()
                    currentMode = modeName
                    for _, b in ipairs(modeButtons) do
                        Tween(b, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
                    end
                    Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.2)
                    updateModeAndContent()
                end)
                table.insert(modeButtons, btn)
            end
            if currentMode == "Remote" then
                local input = createInputField("输入你的Remote", 70, true)
                table.insert(currentElements, input)
                local loopContainer, setLoop = createToggle("循环发送", function(enabled)
                    for i = #currentElements, 1, -1 do
                        local elem = currentElements[i]
                        if elem:IsA("TextBox") and elem.PlaceholderText == "循环间隔(秒)" then
                            local fade = Tween(elem, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                            if fade then
                                fade.Completed:Connect(function()
                                    if not enabled then elem:Destroy() table.remove(currentElements, i) end
                                end)
                            else
                                if not enabled then elem:Destroy() table.remove(currentElements, i) end
                            end
                            break
                        end
                    end
                    if enabled then
                        local intervalBox = createInputField("循环间隔(秒)", 30)
                        intervalBox.Size = UDim2.new(1, 0, 0, 0)
                        intervalBox.BackgroundTransparency = 1
                        table.insert(currentElements, intervalBox)
                        Tween(intervalBox, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    end
                end)
                table.insert(currentElements, loopContainer)
            elseif currentMode == "传送" then
                createCategory("输入坐标点")
                local coordInput = createInputField("x, y, z", 30)
                table.insert(currentElements, coordInput)
                local smoothContainer, setSmooth = createToggle("平滑传送", function(enabled)
                    for i = #currentElements, 1, -1 do
                        local elem = currentElements[i]
                        if (elem:IsA("Frame") and elem.Name == "Slider") or (elem:IsA("Frame") and elem.Name == "ToggleContainer") then
                            local fade = Tween(elem, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                            if fade then
                                fade.Completed:Connect(function()
                                    if not enabled then elem:Destroy() table.remove(currentElements, i) end
                                end)
                            else
                                if not enabled then elem:Destroy() table.remove(currentElements, i) end
                            end
                        end
                    end
                    if enabled then
                        local sliderFrame, sliderSet = createSlider("控制TweenTo速度", 1, 200, 50)
                        sliderFrame.Size = UDim2.new(1, 0, 0, 0)
                        sliderFrame.BackgroundTransparency = 1
                        table.insert(currentElements, sliderFrame)
                        Tween(sliderFrame, {Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 0}, 0.2)
                        local adaptContainer, setAdapt = createToggle("自适应Tween速度", function() end)
                        adaptContainer.Size = UDim2.new(1, 0, 0, 0)
                        adaptContainer.BackgroundTransparency = 1
                        table.insert(currentElements, adaptContainer)
                        Tween(adaptContainer, {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 0}, 0.2)
                    end
                end)
                table.insert(currentElements, smoothContainer)
            elseif currentMode == "模拟按键" then
                createCategory("模拟按键输入")
                local keyInput = createInputField("按键代码 (如: F)", 30)
                table.insert(currentElements, keyInput)
                local pressContainer, setPress = createToggle("按住", function() end)
                table.insert(currentElements, pressContainer)
                local durationInput = createInputField("持续时间(秒)", 30)
                table.insert(currentElements, durationInput)
            end
        end

        if currentControlType == "按钮" and currentControlType ~= "滑块" and currentControlType ~= "下拉菜单" then
            local btnText = createInputField("按钮文本", 30)
            btnText.Name = "BtnText"
            table.insert(currentElements, btnText)
        elseif currentControlType == "开关" then
            local switchTitle = createInputField("开关标题", 30)
            switchTitle.Name = "SwitchTitle"
            table.insert(currentElements, switchTitle)
        elseif currentControlType == "文本输入" then
            local placeholder = createInputField("占位符文本", 30)
            placeholder.Name = "Placeholder"
            table.insert(currentElements, placeholder)
        elseif currentControlType == "标签" then
            local labelText = createInputField("标签文本", 30)
            labelText.Name = "LabelText"
            table.insert(currentElements, labelText)
        elseif currentControlType == "小标题" then
            local catTitle = createInputField("小标题", 30)
            catTitle.Name = "CategoryTitle"
            table.insert(currentElements, catTitle)
        end

        if currentControlType == "按钮" and currentControlType ~= "滑块" and currentControlType ~= "下拉菜单" then
            local notifyContainer, setNotify = createToggle("绑定通知", function(enabled)
                for i = #currentElements, 1, -1 do
                    local elem = currentElements[i]
                    if elem:IsA("TextBox") and (elem.PlaceholderText == "通知标题" or elem.PlaceholderText == "通知内容") then
                        local fade = Tween(elem, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                        if fade then
                            fade.Completed:Connect(function()
                                if not enabled then elem:Destroy() table.remove(currentElements, i) end
                            end)
                        else
                            if not enabled then elem:Destroy() table.remove(currentElements, i) end
                        end
                    end
                end
                if enabled then
                    local titleBox = createInputField("通知标题", 30)
                    titleBox.Size = UDim2.new(1, 0, 0, 0); titleBox.BackgroundTransparency = 1
                    table.insert(currentElements, titleBox)
                    Tween(titleBox, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    local contentBox = createInputField("通知内容", 30)
                    contentBox.Size = UDim2.new(1, 0, 0, 0); contentBox.BackgroundTransparency = 1
                    table.insert(currentElements, contentBox)
                    Tween(contentBox, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                end
            end)
            table.insert(currentElements, notifyContainer)
        elseif currentControlType == "开关" then
            local notifyContainer, setNotify = createToggle("绑定通知", function(enabled)
                for i = #currentElements, 1, -1 do
                    local elem = currentElements[i]
                    if elem:IsA("TextBox") and (elem.PlaceholderText == "开启标题" or elem.PlaceholderText == "开启内容" or elem.PlaceholderText == "关闭标题" or elem.PlaceholderText == "关闭内容") then
                        local fade = Tween(elem, {Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1}, 0.2)
                        if fade then
                            fade.Completed:Connect(function()
                                if not enabled then elem:Destroy() table.remove(currentElements, i) end
                            end)
                        else
                            if not enabled then elem:Destroy() table.remove(currentElements, i) end
                        end
                    end
                end
                if enabled then
                    local onTitle = createInputField("开启标题", 30)
                    onTitle.Size = UDim2.new(1, 0, 0, 0); onTitle.BackgroundTransparency = 1
                    table.insert(currentElements, onTitle)
                    Tween(onTitle, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    local onContent = createInputField("开启内容", 30)
                    onContent.Size = UDim2.new(1, 0, 0, 0); onContent.BackgroundTransparency = 1
                    table.insert(currentElements, onContent)
                    Tween(onContent, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    local offTitle = createInputField("关闭标题", 30)
                    offTitle.Size = UDim2.new(1, 0, 0, 0); offTitle.BackgroundTransparency = 1
                    table.insert(currentElements, offTitle)
                    Tween(offTitle, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                    local offContent = createInputField("关闭内容", 30)
                    offContent.Size = UDim2.new(1, 0, 0, 0); offContent.BackgroundTransparency = 1
                    table.insert(currentElements, offContent)
                    Tween(offContent, {Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 0.3}, 0.2)
                end
            end)
            table.insert(currentElements, notifyContainer)
        end

        refreshCanvas()
    end

    if existingControl then
        if existingControl.Name == "Button" then
            currentControlType = "按钮"
        elseif existingControl.Name == "Toggle" then
            currentControlType = "开关"
        elseif existingControl.Name == "Slider" then
            currentControlType = "滑块"
        elseif existingControl.Name == "Dropdown" then
            currentControlType = "下拉菜单"
        elseif existingControl.Name == "TextInput" then
            currentControlType = "文本输入"
        elseif existingControl.Name == "Label" then
            currentControlType = "标签"
        elseif existingControl.Name == "Category" then
            currentControlType = "小标题"
        end
        controlTypeBtn.Text = currentControlType
    end

    updateModeAndContent()

    if existingControl then
        if currentControlType == "按钮" then
            for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then elem.Text = existingControl.Instance.Text end end
        elseif currentControlType == "开关" then
            local titleLabel = existingControl.Container:FindFirstChild("Title")
            if titleLabel then for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then elem.Text = titleLabel.Text end end end
        elseif currentControlType == "滑块" then
            local titleLabel = existingControl.Container:FindFirstChild("Title")
            if titleLabel then for _, elem in ipairs(currentElements) do if elem.Name == "SliderTitle" then elem.Text = titleLabel.Text end end end
            for _, elem in ipairs(currentElements) do
                if elem.Name == "Min" then elem.Text = tostring(existingControl.Min)
                elseif elem.Name == "Max" then elem.Text = tostring(existingControl.Max)
                elseif elem.Name == "Default" then elem.Text = tostring(existingControl.Value) end
            end
        elseif currentControlType == "下拉菜单" then
            local titleLabel = existingControl.Container:FindFirstChild("Title")
            if titleLabel then for _, elem in ipairs(currentElements) do if elem.Name == "DropdownTitle" then elem.Text = titleLabel.Text end end end
        elseif currentControlType == "文本输入" then
            for _, elem in ipairs(currentElements) do if elem.Name == "Placeholder" then elem.Text = existingControl.TextBox.PlaceholderText end end
        elseif currentControlType == "标签" then
            for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then elem.Text = existingControl.Instance.Text end end
        elseif currentControlType == "小标题" then
            local titleLabel = existingControl.Header:FindFirstChild("TitleContainer"):FindFirstChild("Title")
            if titleLabel then for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then elem.Text = titleLabel.Text end end end
        end
    end

    local function closeConfigurator()
        local fade = Tween(overlay, {BackgroundTransparency = 1}, 0.2)
        if fade then
            fade.Completed:Wait()
        end
        gui:Destroy()
    end

    local function getRequiredText()
        if currentControlType == "按钮" then
            for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then return elem.Text end end
        elseif currentControlType == "开关" then
            for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then return elem.Text end end
        elseif currentControlType == "滑块" then
            for _, elem in ipairs(currentElements) do if elem.Name == "SliderTitle" then return elem.Text end end
        elseif currentControlType == "下拉菜单" then
            for _, elem in ipairs(currentElements) do if elem.Name == "DropdownTitle" then return elem.Text end end
        elseif currentControlType == "文本输入" then
            for _, elem in ipairs(currentElements) do if elem.Name == "Placeholder" then return elem.Text end end
        elseif currentControlType == "标签" then
            for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then return elem.Text end end
        elseif currentControlType == "小标题" then
            for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then return elem.Text end end
        end
        return ""
    end

    closeBtn.MouseButton1Click:Connect(function()
        WasUI:ShowConfirmDialog({
            title = "警告",
            description = "你还有未保存的配置，你要关闭还是储存？",
            confirmText = "储存",
            cancelText = "关闭",
            onConfirm = function()
                local requiredText = getRequiredText()
                if requiredText == "" then
                    WasUI:ShowConfirmDialog({
                        title = "输入文本",
                        showInput = true,
                        inputPlaceholder = "请输入控件文本",
                        confirmText = "保存",
                        cancelText = "取消",
                        onConfirm = function(input)
                            if input and input ~= "" then
                                if currentControlType == "按钮" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then elem.Text = input end end
                                elseif currentControlType == "开关" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then elem.Text = input end end
                                elseif currentControlType == "滑块" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "SliderTitle" then elem.Text = input end end
                                elseif currentControlType == "下拉菜单" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "DropdownTitle" then elem.Text = input end end
                                elseif currentControlType == "文本输入" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "Placeholder" then elem.Text = input end end
                                elseif currentControlType == "标签" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then elem.Text = input end end
                                elseif currentControlType == "小标题" then
                                    for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then elem.Text = input end end
                                end
                                if existingControl then
                                    if currentControlType == "按钮" then
                                        for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                                    elseif currentControlType == "开关" then
                                        for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                                    elseif currentControlType == "滑块" then
                                        local newMin, newMax, newDefault = existingControl.Min, existingControl.Max, existingControl.Value
                                        for _, elem in ipairs(currentElements) do
                                            if elem.Name == "SliderTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end
                                            elseif elem.Name == "Min" then newMin = tonumber(elem.Text) or existingControl.Min
                                            elseif elem.Name == "Max" then newMax = tonumber(elem.Text) or existingControl.Max
                                            elseif elem.Name == "Default" then newDefault = tonumber(elem.Text) or existingControl.Value end
                                        end
                                        existingControl.Min = newMin
                                        existingControl.Max = newMax
                                        existingControl.Value = math.clamp(newDefault, newMin, newMax)
                                        existingControl.ValueLabel.Text = tostring(existingControl.Value)
                                        local t = (existingControl.Value - newMin) / (newMax - newMin)
                                        existingControl.SliderFill.Size = UDim2.new(t, 0, 1, 0)
                                        existingControl.Knob.Position = UDim2.new(t, -8, 0.5, -8)
                                    elseif currentControlType == "标签" then
                                        for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                                    elseif currentControlType == "小标题" then
                                        for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then local titleLabel = existingControl.Header:FindFirstChild("TitleContainer"):FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                                    end
                                else
                                    if currentControlType == "按钮" then
                                        local btnText = ""
                                        for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then btnText = elem.Text end end
                                        WasUI:CreateButton(parentFrame, btnText, function() WasUI:Notify({Title = btnText, Content = "按钮被点击", Duration = 1}) end)
                                    elseif currentControlType == "开关" then
                                        local switchTitle = ""
                                        local cfgKey = nil
                                        for _, elem in ipairs(currentElements) do
                                            if elem.Name == "SwitchTitle" then switchTitle = elem.Text
                                            elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                        end
                                        WasUI:CreateToggle(parentFrame, switchTitle, false, function(state) end, nil, nil, cfgKey)
                                    elseif currentControlType == "滑块" then
                                        local sliderTitle = ""
                                        local minVal, maxVal, defaultVal = 0, 100, 50
                                        local cfgKey = nil
                                        for _, elem in ipairs(currentElements) do
                                            if elem.Name == "SliderTitle" then sliderTitle = elem.Text
                                            elseif elem.Name == "Min" then minVal = tonumber(elem.Text) or 0
                                            elseif elem.Name == "Max" then maxVal = tonumber(elem.Text) or 100
                                            elseif elem.Name == "Default" then defaultVal = tonumber(elem.Text) or 50
                                            elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                        end
                                        WasUI:CreateSlider(parentFrame, sliderTitle, minVal, maxVal, defaultVal, function(val) end, cfgKey)
                                    elseif currentControlType == "文本输入" then
                                        local placeholder = ""
                                        local cfgKey = nil
                                        for _, elem in ipairs(currentElements) do
                                            if elem.Name == "Placeholder" then placeholder = elem.Text
                                            elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                        end
                                        WasUI:CreateTextInput(parentFrame, placeholder, "", function(text) end, cfgKey)
                                    elseif currentControlType == "标签" then
                                        local labelText = ""
                                        for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then labelText = elem.Text end end
                                        WasUI:CreateLabel(parentFrame, labelText)
                                    elseif currentControlType == "小标题" then
                                        local catTitle = ""
                                        for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then catTitle = elem.Text end end
                                        WasUI:CreateCategory(parentFrame, catTitle)
                                    elseif currentControlType == "下拉菜单" then
                                        local ddTitle = ""
                                        local cfgKey = nil
                                        for _, elem in ipairs(currentElements) do
                                            if elem.Name == "DropdownTitle" then ddTitle = elem.Text
                                            elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                        end
                                        WasUI:CreateDropdown(parentFrame, ddTitle, {"选项1", "选项2"}, nil, function(sel) end, false, cfgKey)
                                    end
                                end
                                WasUI:Notify({Title = "调试", Content = "你的更改已被保存", Duration = 2})
                                closeConfigurator()
                            end
                        end
                    })
                else
                    if existingControl then
                        if currentControlType == "按钮" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                        elseif currentControlType == "开关" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                        elseif currentControlType == "滑块" then
                            local newMin, newMax, newDefault = existingControl.Min, existingControl.Max, existingControl.Value
                            for _, elem in ipairs(currentElements) do
                                if elem.Name == "SliderTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end
                                elseif elem.Name == "Min" then newMin = tonumber(elem.Text) or existingControl.Min
                                elseif elem.Name == "Max" then newMax = tonumber(elem.Text) or existingControl.Max
                                elseif elem.Name == "Default" then newDefault = tonumber(elem.Text) or existingControl.Value end
                            end
                            existingControl.Min = newMin
                            existingControl.Max = newMax
                            existingControl.Value = math.clamp(newDefault, newMin, newMax)
                            existingControl.ValueLabel.Text = tostring(existingControl.Value)
                            local t = (existingControl.Value - newMin) / (newMax - newMin)
                            existingControl.SliderFill.Size = UDim2.new(t, 0, 1, 0)
                            existingControl.Knob.Position = UDim2.new(t, -8, 0.5, -8)
                        elseif currentControlType == "标签" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                        elseif currentControlType == "小标题" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then local titleLabel = existingControl.Header:FindFirstChild("TitleContainer"):FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                        end
                    else
                        if currentControlType == "按钮" then
                            local btnText = ""
                            for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then btnText = elem.Text end end
                            WasUI:CreateButton(parentFrame, btnText, function() WasUI:Notify({Title = btnText, Content = "按钮被点击", Duration = 1}) end)
                        elseif currentControlType == "开关" then
                            local switchTitle = ""
                            local cfgKey = nil
                            for _, elem in ipairs(currentElements) do
                                if elem.Name == "SwitchTitle" then switchTitle = elem.Text
                                elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                            end
                            WasUI:CreateToggle(parentFrame, switchTitle, false, function(state) end, nil, nil, cfgKey)
                        elseif currentControlType == "滑块" then
                            local sliderTitle = ""
                            local minVal, maxVal, defaultVal = 0, 100, 50
                            local cfgKey = nil
                            for _, elem in ipairs(currentElements) do
                                if elem.Name == "SliderTitle" then sliderTitle = elem.Text
                                elseif elem.Name == "Min" then minVal = tonumber(elem.Text) or 0
                                elseif elem.Name == "Max" then maxVal = tonumber(elem.Text) or 100
                                elseif elem.Name == "Default" then defaultVal = tonumber(elem.Text) or 50
                                elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                            end
                            WasUI:CreateSlider(parentFrame, sliderTitle, minVal, maxVal, defaultVal, function(val) end, cfgKey)
                        elseif currentControlType == "文本输入" then
                            local placeholder = ""
                            local cfgKey = nil
                            for _, elem in ipairs(currentElements) do
                                if elem.Name == "Placeholder" then placeholder = elem.Text
                                elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                            end
                            WasUI:CreateTextInput(parentFrame, placeholder, "", function(text) end, cfgKey)
                        elseif currentControlType == "标签" then
                            local labelText = ""
                            for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then labelText = elem.Text end end
                            WasUI:CreateLabel(parentFrame, labelText)
                        elseif currentControlType == "小标题" then
                            local catTitle = ""
                            for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then catTitle = elem.Text end end
                            WasUI:CreateCategory(parentFrame, catTitle)
                        elseif currentControlType == "下拉菜单" then
                            local ddTitle = ""
                            local cfgKey = nil
                            for _, elem in ipairs(currentElements) do
                                if elem.Name == "DropdownTitle" then ddTitle = elem.Text
                                elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                            end
                            WasUI:CreateDropdown(parentFrame, ddTitle, {"选项1", "选项2"}, nil, function(sel) end, false, cfgKey)
                        end
                    end
                    WasUI:Notify({Title = "调试", Content = "你的更改已被保存", Duration = 2})
                    closeConfigurator()
                end
            end,
            onCancel = function()
                closeConfigurator()
            end
        })
    end)

    saveBtn.MouseButton1Click:Connect(function()
        local requiredText = getRequiredText()
        if requiredText == "" then
            WasUI:ShowConfirmDialog({
                title = "输入文本",
                showInput = true,
                inputPlaceholder = "请输入控件文本",
                confirmText = "保存",
                cancelText = "取消",
                onConfirm = function(input)
                    if input and input ~= "" then
                        if currentControlType == "按钮" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then elem.Text = input end end
                        elseif currentControlType == "开关" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then elem.Text = input end end
                        elseif currentControlType == "滑块" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "SliderTitle" then elem.Text = input end end
                        elseif currentControlType == "下拉菜单" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "DropdownTitle" then elem.Text = input end end
                        elseif currentControlType == "文本输入" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "Placeholder" then elem.Text = input end end
                        elseif currentControlType == "标签" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then elem.Text = input end end
                        elseif currentControlType == "小标题" then
                            for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then elem.Text = input end end
                        end
                        if existingControl then
                            if currentControlType == "按钮" then
                                for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                            elseif currentControlType == "开关" then
                                for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                            elseif currentControlType == "滑块" then
                                local newMin, newMax, newDefault = existingControl.Min, existingControl.Max, existingControl.Value
                                for _, elem in ipairs(currentElements) do
                                    if elem.Name == "SliderTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end
                                    elseif elem.Name == "Min" then newMin = tonumber(elem.Text) or existingControl.Min
                                    elseif elem.Name == "Max" then newMax = tonumber(elem.Text) or existingControl.Max
                                    elseif elem.Name == "Default" then newDefault = tonumber(elem.Text) or existingControl.Value end
                                end
                                existingControl.Min = newMin
                                existingControl.Max = newMax
                                existingControl.Value = math.clamp(newDefault, newMin, newMax)
                                existingControl.ValueLabel.Text = tostring(existingControl.Value)
                                local t = (existingControl.Value - newMin) / (newMax - newMin)
                                existingControl.SliderFill.Size = UDim2.new(t, 0, 1, 0)
                                existingControl.Knob.Position = UDim2.new(t, -8, 0.5, -8)
                            elseif currentControlType == "标签" then
                                for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                            elseif currentControlType == "小标题" then
                                for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then local titleLabel = existingControl.Header:FindFirstChild("TitleContainer"):FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                            end
                        else
                            if currentControlType == "按钮" then
                                local btnText = ""
                                for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then btnText = elem.Text end end
                                WasUI:CreateButton(parentFrame, btnText, function() WasUI:Notify({Title = btnText, Content = "按钮被点击", Duration = 1}) end)
                            elseif currentControlType == "开关" then
                                local switchTitle = ""
                                local cfgKey = nil
                                for _, elem in ipairs(currentElements) do
                                    if elem.Name == "SwitchTitle" then switchTitle = elem.Text
                                    elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                end
                                WasUI:CreateToggle(parentFrame, switchTitle, false, function(state) end, nil, nil, cfgKey)
                            elseif currentControlType == "滑块" then
                                local sliderTitle = ""
                                local minVal, maxVal, defaultVal = 0, 100, 50
                                local cfgKey = nil
                                for _, elem in ipairs(currentElements) do
                                    if elem.Name == "SliderTitle" then sliderTitle = elem.Text
                                    elseif elem.Name == "Min" then minVal = tonumber(elem.Text) or 0
                                    elseif elem.Name == "Max" then maxVal = tonumber(elem.Text) or 100
                                    elseif elem.Name == "Default" then defaultVal = tonumber(elem.Text) or 50
                                    elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                end
                                WasUI:CreateSlider(parentFrame, sliderTitle, minVal, maxVal, defaultVal, function(val) end, cfgKey)
                            elseif currentControlType == "文本输入" then
                                local placeholder = ""
                                local cfgKey = nil
                                for _, elem in ipairs(currentElements) do
                                    if elem.Name == "Placeholder" then placeholder = elem.Text
                                    elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                end
                                WasUI:CreateTextInput(parentFrame, placeholder, "", function(text) end, cfgKey)
                            elseif currentControlType == "标签" then
                                local labelText = ""
                                for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then labelText = elem.Text end end
                                WasUI:CreateLabel(parentFrame, labelText)
                            elseif currentControlType == "小标题" then
                                local catTitle = ""
                                for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then catTitle = elem.Text end end
                                WasUI:CreateCategory(parentFrame, catTitle)
                            elseif currentControlType == "下拉菜单" then
                                local ddTitle = ""
                                local cfgKey = nil
                                for _, elem in ipairs(currentElements) do
                                    if elem.Name == "DropdownTitle" then ddTitle = elem.Text
                                    elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                                end
                                WasUI:CreateDropdown(parentFrame, ddTitle, {"选项1", "选项2"}, nil, function(sel) end, false, cfgKey)
                            end
                        end
                        WasUI:Notify({Title = "调试", Content = "你的更改已被保存", Duration = 2})
                        closeConfigurator()
                    end
                end
            })
        else
            if existingControl then
                if currentControlType == "按钮" then
                    for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                elseif currentControlType == "开关" then
                    for _, elem in ipairs(currentElements) do if elem.Name == "SwitchTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                elseif currentControlType == "滑块" then
                    local newMin, newMax, newDefault = existingControl.Min, existingControl.Max, existingControl.Value
                    for _, elem in ipairs(currentElements) do
                        if elem.Name == "SliderTitle" then local titleLabel = existingControl.Container:FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end
                        elseif elem.Name == "Min" then newMin = tonumber(elem.Text) or existingControl.Min
                        elseif elem.Name == "Max" then newMax = tonumber(elem.Text) or existingControl.Max
                        elseif elem.Name == "Default" then newDefault = tonumber(elem.Text) or existingControl.Value end
                    end
                    existingControl.Min = newMin
                    existingControl.Max = newMax
                    existingControl.Value = math.clamp(newDefault, newMin, newMax)
                    existingControl.ValueLabel.Text = tostring(existingControl.Value)
                    local t = (existingControl.Value - newMin) / (newMax - newMin)
                    existingControl.SliderFill.Size = UDim2.new(t, 0, 1, 0)
                    existingControl.Knob.Position = UDim2.new(t, -8, 0.5, -8)
                elseif currentControlType == "标签" then
                    for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then existingControl.Instance.Text = elem.Text; WasUI:SetLocalizedText(existingControl.Instance, elem.Text) end end
                elseif currentControlType == "小标题" then
                    for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then local titleLabel = existingControl.Header:FindFirstChild("TitleContainer"):FindFirstChild("Title"); if titleLabel then titleLabel.Text = elem.Text; WasUI:SetLocalizedText(titleLabel, elem.Text) end end end
                end
            else
                if currentControlType == "按钮" then
                    local btnText = ""
                    for _, elem in ipairs(currentElements) do if elem.Name == "BtnText" then btnText = elem.Text end end
                    WasUI:CreateButton(parentFrame, btnText, function() WasUI:Notify({Title = btnText, Content = "按钮被点击", Duration = 1}) end)
                elseif currentControlType == "开关" then
                    local switchTitle = ""
                    local cfgKey = nil
                    for _, elem in ipairs(currentElements) do
                        if elem.Name == "SwitchTitle" then switchTitle = elem.Text
                        elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                    end
                    WasUI:CreateToggle(parentFrame, switchTitle, false, function(state) end, nil, nil, cfgKey)
                elseif currentControlType == "滑块" then
                    local sliderTitle = ""
                    local minVal, maxVal, defaultVal = 0, 100, 50
                    local cfgKey = nil
                    for _, elem in ipairs(currentElements) do
                        if elem.Name == "SliderTitle" then sliderTitle = elem.Text
                        elseif elem.Name == "Min" then minVal = tonumber(elem.Text) or 0
                        elseif elem.Name == "Max" then maxVal = tonumber(elem.Text) or 100
                        elseif elem.Name == "Default" then defaultVal = tonumber(elem.Text) or 50
                        elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                    end
                    WasUI:CreateSlider(parentFrame, sliderTitle, minVal, maxVal, defaultVal, function(val) end, cfgKey)
                elseif currentControlType == "文本输入" then
                    local placeholder = ""
                    local cfgKey = nil
                    for _, elem in ipairs(currentElements) do
                        if elem.Name == "Placeholder" then placeholder = elem.Text
                        elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                    end
                    WasUI:CreateTextInput(parentFrame, placeholder, "", function(text) end, cfgKey)
                elseif currentControlType == "标签" then
                    local labelText = ""
                    for _, elem in ipairs(currentElements) do if elem.Name == "LabelText" then labelText = elem.Text end end
                    WasUI:CreateLabel(parentFrame, labelText)
                elseif currentControlType == "小标题" then
                    local catTitle = ""
                    for _, elem in ipairs(currentElements) do if elem.Name == "CategoryTitle" then catTitle = elem.Text end end
                    WasUI:CreateCategory(parentFrame, catTitle)
                elseif currentControlType == "下拉菜单" then
                    local ddTitle = ""
                    local cfgKey = nil
                    for _, elem in ipairs(currentElements) do
                        if elem.Name == "DropdownTitle" then ddTitle = elem.Text
                        elseif elem.Name == "ConfigKey" and elem.Text ~= "" then cfgKey = elem.Text end
                    end
                    WasUI:CreateDropdown(parentFrame, ddTitle, {"选项1", "选项2"}, nil, function(sel) end, false, cfgKey)
                end
            end
            WasUI:Notify({Title = "调试", Content = "你的更改已被保存", Duration = 2})
            closeConfigurator()
        end
    end)

    overlay.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local framePos = mainFrame.AbsolutePosition
            local frameSize = mainFrame.AbsoluteSize
            if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                closeConfigurator()
            end
        end
    end)

    Tween(overlay, {BackgroundTransparency = 0.5}, 0.2)
end

function GenerateExportCode(panel)
    local code = "local WasUI = loadstring(game:HttpGet('https://raw.githubusercontent.com/WasKKal/WasUI-For-Roblox/main/WasUI.lua'))()\n"
    code = code .. "local win = WasUI:CreateWindow('" .. panel.Title.Text .. "', UDim2.new(0, 380, 0, 350))\n"
    code = code .. "win:SetWelcome('" .. panel.WelcomeLabel.Text .. "')\n"
    for tabName, tabData in pairs(panel.Tabs) do
        local safeTabName = tabName:gsub("%s", "_"):gsub("[^%w_]", "")
        code = code .. "local " .. safeTabName .. " = win:AddTab('" .. tabName .. "')\n"
        local frame = tabData.Frame
        for _, child in ipairs(frame:GetChildren()) do
            if child:IsA("TextButton") and child.Name == "Button" then
                code = code .. "WasUI:CreateButton(" .. safeTabName .. ", '" .. child.Text:gsub("'", "\\'") .. "', function() end)\n"
            elseif child:IsA("Frame") and child.Name == "ToggleContainer" then
                local titleLabel = child:FindFirstChild("Title")
                if titleLabel then
                    code = code .. "WasUI:CreateToggle(" .. safeTabName .. ", '" .. titleLabel.Text:gsub("'", "\\'") .. "', false, function(state) end)\n"
                end
            elseif child:IsA("Frame") and child.Name == "Slider" then
                local titleLabel = child:FindFirstChild("Title")
                local minVal, maxVal, defaultVal = 0, 100, 50
                local sliderObj = nil
                for _, obj in ipairs(WasUI.Objects) do if obj.Object == child then sliderObj = obj end end
                if sliderObj and sliderObj.Slider then
                    minVal = sliderObj.Slider.Min
                    maxVal = sliderObj.Slider.Max
                    defaultVal = sliderObj.Slider.Value
                end
                if titleLabel then
                    code = code .. "WasUI:CreateSlider(" .. safeTabName .. ", '" .. titleLabel.Text:gsub("'", "\\'") .. "', " .. minVal .. ", " .. maxVal .. ", " .. defaultVal .. ", function(val) end)\n"
                end
            elseif child:IsA("Frame") and child.Name == "Dropdown" then
                local titleLabel = child:FindFirstChild("Title")
                if titleLabel then
                    code = code .. "WasUI:CreateDropdown(" .. safeTabName .. ", '" .. titleLabel.Text:gsub("'", "\\'") .. "', {'选项1', '选项2'}, nil, function(sel) end)\n"
                end
            elseif child:IsA("Frame") and child.Name == "TextInput" then
                local textBox = child:FindFirstChild("TextBox")
                if textBox then
                    code = code .. "WasUI:CreateTextInput(" .. safeTabName .. ", '" .. textBox.PlaceholderText:gsub("'", "\\'") .. "', '', function(text) end)\n"
                end
            elseif child:IsA("TextLabel") and child.Name == "Label" then
                code = code .. "WasUI:CreateLabel(" .. safeTabName .. ", '" .. child.Text:gsub("'", "\\'") .. "')\n"
            elseif child:IsA("Frame") and child.Name == "CategoryHeader" then
                local titleContainer = child:FindFirstChild("TitleContainer")
                if titleContainer then
                    local title = titleContainer:FindFirstChild("Title")
                    if title then
                        code = code .. "WasUI:CreateCategory(" .. safeTabName .. ", '" .. title.Text:gsub("'", "\\'") .. "')\n"
                    end
                end
            end
        end
    end
    return code
end

function WasUI:CreateWindow(title, size, position, titleTag)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WasUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = WasUI.DefaultDisplayOrder
    screenGui.Parent = game:GetService("CoreGui")
    local window = Panel:New(title, screenGui, UDim2.new(0, 380, 0, 350), position, titleTag)
    window:SetTitle(title)
    return window
end

function WasUI:CreateButton(parent, text, onClick, size, iconName)
    return Button:New("Button", parent, text, onClick, size, iconName)
end

function WasUI:CreateToggle(parent, title, initialState, onToggle, featureName, rainbowName, iconName, configKey)
    return ToggleSwitch:New("Toggle", parent, title, initialState, onToggle)
end

function WasUI:CreateLabel(parent, text)
    return Label:New("Label", parent, text)
end

function WasUI:CreateCategory(parent, title, iconName)
    return Category:New("Category", parent, title, iconName)
end

function WasUI:CreateDropdown(parent, title, options, defaultValue, callback, multiSelect, configKey)
    return Dropdown:New("Dropdown", parent, title, options, defaultValue, callback, multiSelect)
end

function WasUI:CreateSlider(parent, title, min, max, defaultValue, callback, configKey)
    return Slider:New("Slider", parent, title, min, max, defaultValue, callback)
end

function WasUI:CreateTextInput(parent, placeholder, defaultValue, callback, configKey)
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