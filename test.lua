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

if _G.WasUILoaded and _G.WasUIModule then
    warn("WasUI已加载 请勿重复加载")
    return _G.WasUIModule
end
_G.WasUILoaded = true

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
WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}
WasUI.SettingsPanel = nil
WasUI.GroupButtonText = "加入WasUI主群"
WasUI.GroupCopyContent = "1085475284"

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

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
        Text = Color3.fromRGB(30, 30, 35),
        Accent = Color3.fromRGB(52, 86, 139),
        Success = Color3.fromRGB(52, 168, 83),
        Warning = Color3.fromRGB(251, 188, 5),
        Error = Color3.fromRGB(234, 67, 53),
        Section = Color3.fromRGB(240, 240, 245),
        Input = Color3.fromRGB(240, 240, 245),
        TabBorder = Color3.fromRGB(200, 200, 205),
        TabButton = Color3.fromRGB(248, 248, 250),
        SnowColor = Color3.fromRGB(0, 0, 0)
    }
}
WasUI.CurrentTheme = WasUI.Themes.Dark
WasUI.Objects = {}
WasUI.ActiveRainbowTexts = {}
WasUI.RainbowOrder = {}

WasUI.DropdownGui = Instance.new("ScreenGui")
WasUI.DropdownGui.Name = "WasUI_Dropdowns"
WasUI.DropdownGui.ResetOnSpawn = false
WasUI.DropdownGui.DisplayOrder = 1000
WasUI.DropdownGui.Parent = game:GetService("CoreGui")

WasUI.NotificationGui = Instance.new("ScreenGui")
WasUI.NotificationGui.Name = "WasUI_Notifications"
WasUI.NotificationGui.ResetOnSpawn = false
WasUI.NotificationGui.DisplayOrder = 999
WasUI.NotificationGui.Parent = game:GetService("CoreGui")

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

function WasUI:CreateIcon(iconName, size, color)
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
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- 修复后的 SpringTween 函数：第五个参数改为布尔值 false，移除无用的 overshoot 参数
local function SpringTween(instance, properties, duration)
    local tweenInfo = TweenInfo.new(duration or 0.35, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function FadeOut(container, duration)
    duration = duration or 0.3
    local tweens = {}
    for _, child in ipairs(container:GetChildren()) do
        local props = {}
        if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
            props.TextTransparency = 1
            if child:IsA("TextButton") then
                props.BackgroundTransparency = 1
            end
        elseif child:IsA("Frame") or child:IsA("ImageLabel") or child:IsA("ImageButton") then
            props.BackgroundTransparency = 1
            if child:IsA("ImageLabel") or child:IsA("ImageButton") then
                props.ImageTransparency = 1
            end
        elseif child:IsA("UIStroke") then
            props.Transparency = 1
        end
        if next(props) then
            table.insert(tweens, Tween(child, props, duration))
        end
        local childTweens = FadeOut(child, duration)
        for _, tween in ipairs(childTweens) do
            table.insert(tweens, tween)
        end
    end
    return tweens
end

local function FadeIn(container, duration)
    duration = duration or 0.3
    local tweens = {}
    for _, child in ipairs(container:GetChildren()) do
        local props = {}
        if child:IsA("TextLabel") then
            props.TextTransparency = 0
        elseif child:IsA("TextButton") then
            props.TextTransparency = 0
            props.BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 0.3
        elseif child:IsA("TextBox") then
            props.TextTransparency = 0
            props.BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 0.3
        elseif child:IsA("Frame") then
            props.BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 0.3
        elseif child:IsA("ImageLabel") then
            props.ImageTransparency = 0
            props.BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 1
        elseif child:IsA("ImageButton") then
            props.ImageTransparency = 0
            props.BackgroundTransparency = child:GetAttribute("OriginalBackgroundTransparency") or 1
        elseif child:IsA("UIStroke") then
            props.Transparency = child:GetAttribute("OriginalTransparency") or 0
        end
        if next(props) then
            table.insert(tweens, Tween(child, props, duration))
        end
        local childTweens = FadeIn(child, duration)
        for _, tween in ipairs(childTweens) do
            table.insert(tweens, tween)
        end
    end
    return tweens
end

local function RecordOriginalTransparency(container)
    for _, child in ipairs(container:GetChildren()) do
        if child:IsA("TextButton") then
            child:SetAttribute("OriginalBackgroundTransparency", child.BackgroundTransparency)
        elseif child:IsA("TextBox") then
            child:SetAttribute("OriginalBackgroundTransparency", child.BackgroundTransparency)
        elseif child:IsA("Frame") then
            child:SetAttribute("OriginalBackgroundTransparency", child.BackgroundTransparency)
        elseif child:IsA("ImageLabel") then
            child:SetAttribute("OriginalBackgroundTransparency", child.BackgroundTransparency)
            child:SetAttribute("OriginalImageTransparency", child.ImageTransparency)
        elseif child:IsA("ImageButton") then
            child:SetAttribute("OriginalBackgroundTransparency", child.BackgroundTransparency)
            child:SetAttribute("OriginalImageTransparency", child.ImageTransparency)
        elseif child:IsA("UIStroke") then
            child:SetAttribute("OriginalTransparency", child.Transparency)
        end
        RecordOriginalTransparency(child)
    end
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
        Name = "FeatureRainbowText_" .. featureName,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = game:GetService("CoreGui")
    })
    local textLabel = CreateInstance("TextLabel", {
        Name = "RainbowText",
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

local function CreateRainbowText(text, position)
    if WasUI.ActiveRainbowTexts[text] then return end
    local screenGui = CreateInstance("ScreenGui", {
        Name = "RainbowText_" .. text,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = game:GetService("CoreGui")
    })
    local textLabel = CreateInstance("TextLabel", {
        Name = "RainbowText",
        Size = UDim2.new(0, 180, 0, 0),
        Position = position or UDim2.new(0.5, -90, 0.5, -10),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextWrapped = true,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        Parent = screenGui
    })
    local bounds = textLabel.TextBounds
    local height = bounds.Y + 4
    textLabel.Size = UDim2.new(0, 180, 0, height)
    WasUI.ActiveRainbowTexts[text] = {
        ScreenGui = screenGui,
        Connection = nil,
        Label = textLabel
    }
end

local function RemoveRainbowText(text)
    local data = WasUI.ActiveRainbowTexts[text]
    if data then
        if data.ScreenGui then data.ScreenGui:Destroy() end
        WasUI.ActiveRainbowTexts[text] = nil
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
        Name = name,
        Size = buttonSize,
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        Text = text or "按钮",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.None,
        ZIndex = 2
    })
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
    self.Instance.MouseEnter:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.15, Enum.EasingStyle.Sine)
    end)
    self.Instance.MouseLeave:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.15, Enum.EasingStyle.Sine)
    end)
    self.Instance.MouseButton1Down:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
        SpringTween(scale, {Scale = 0.97}, 0.2)
    end)
    self.Instance.MouseButton1Up:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
        SpringTween(scale, {Scale = 1}, 0.25)
        if onClick then onClick() end
    end)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Button"})
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, title, initialState, onToggle, featureName, rainbowName, iconName)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = featureName or name
    self.RainbowName = rainbowName or self.FeatureName
    self.Container = CreateInstance("Frame", {
        Name = name .. "_Container",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
        ZIndex = 2
    })
    self.Container:SetAttribute("SearchText", title or "")
    if title then
        self.TitleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(0.7, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 2,
            Parent = self.Container
        })
    end
    local offColor = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
    self.Background = CreateInstance("ImageButton", {
        Name = name .. "_BG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = title and UDim2.new(1, -40, 0.5, -9) or UDim2.new(1, -40, 0.5, -9),
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
        Name = name .. "_Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Toggled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.Background
    })
    local knobCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Knob})
    if iconName then
        local knobIcon = WasUI:CreateIcon(iconName, UDim2.new(0, 10, 0, 10), WasUI.CurrentTheme.Text)
        if knobIcon then
            knobIcon.Parent = self.Knob
            knobIcon.Position = UDim2.new(0.5, -5, 0.5, -5)
            knobIcon.ZIndex = 5
        end
    end
    if self.Toggled then
        CreateRainbowTextForFeature(self.RainbowName)
    end
    self.Background.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        self.Background:SetAttribute("Toggled", self.Toggled)
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.3)
            CreateRainbowTextForFeature(self.RainbowName)
        else
            local offCol = (WasUI.CurrentTheme == WasUI.Themes.Dark) and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(180, 180, 180)
            Tween(self.Background, {BackgroundColor3 = offCol}, 0.2)
            SpringTween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.3)
            DestroyRainbowTextForFeature(self.RainbowName)
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
    end)
    table.insert(WasUI.Objects, {Object = self.Background, Type = "Toggle"})
    table.insert(WasUI.Objects, {Object = self.Knob, Type = "ToggleKnob"})
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label
function Label:New(name, parent, text, textColor)
    local self = Control:New(name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "标签",
        TextColor3 = textColor or WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = parent
    })
    self.Instance:SetAttribute("SearchText", text or "")
    self.Instance:SetAttribute("IsLabel", true)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Label"})
    return self
end

local Category = setmetatable({}, {__index = Control})
Category.__index = Category
function Category:New(name, parent, title)
    local self = Control:New(name, parent)
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent,
        ZIndex = 2
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.9, 0, 1, 0),
        Position = UDim2.new(0, 2, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 2,
        Parent = self.Instance
    })
    local line = CreateInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 1, -2),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Instance
    })
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Category"})
    table.insert(WasUI.Objects, {Object = titleLabel, Type = "Label"})
    table.insert(WasUI.Objects, {Object = line, Type = "Line"})
    return self
end

local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback, multiSelect)
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
        Name = name,
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
        Text = title or "下拉菜单",
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.Container
    })
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
                else
                    self.SelectedValue = option
                    self:UpdateDisplayText()
                    if self.Callback then self.Callback(option) end
                    self:Close(true)
                end
            end)
            self.OptionButtons[option] = optionButton
        end
        local function updateContainerSize()
            local totalHeight = #self.Options * 28 + (#self.Options - 1) * 4 + 16
            local maxHeight = 300
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
    local function updateContainerSize()
        local totalHeight = #self.Options * 28 + (#self.Options - 1) * 4 + 16
        local maxHeight = 300
        local finalHeight = math.min(totalHeight, maxHeight)
        self.OptionsContainer.Size = UDim2.new(0.3, 0, 0, finalHeight)
        task.wait()
        self.OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsList.AbsoluteContentSize.Y + 8)
    end
    local function updatePosition()
        if not self.IsOpen then return end
        local btnPos = self.DropdownButton.AbsolutePosition
        local btnSize = self.DropdownButton.AbsoluteSize
        local viewportSize = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or GuiService:GetScreenSize()
        local menuHeight = self.OptionsContainer.AbsoluteSize.Y
        local x = btnPos.X
        local y = btnPos.Y + btnSize.Y
        if y + menuHeight > viewportSize.Y then
            y = btnPos.Y - menuHeight
        end
        local menuWidth = self.OptionsContainer.AbsoluteSize.X
        if x + menuWidth > viewportSize.X then
            x = viewportSize.X - menuWidth - 5
        end
        self.OptionsContainer.Position = UDim2.new(0, x, 0, y)
    end
    self.DropdownButton:GetPropertyChangedSignal("AbsolutePosition"):Connect(updatePosition)
    self.DropdownButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePosition)
    function self:GetDisplayText()
        if self.MultiSelect then
            if #self.SelectedValues == 0 then return "选择..." end
            return table.concat(self.SelectedValues, ", ")
        else
            return self.SelectedValue and tostring(self.SelectedValue) or "选择..."
        end
    end
    function self:UpdateDisplayText()
        self.DropdownButton.Text = self:GetDisplayText()
    end
    function self:Open()
        if self.IsOpen then return end
        self.IsOpen = true
        table.insert(WasUI.OpenDropdowns, self)
        updateContainerSize()
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
    rebuildOptions()
    self:UpdateDisplayText()
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
function Slider:New(name, parent, title, min, max, defaultValue, callback)
    local self = Control:New(name, parent)
    self.Min = min or 0
    self.Max = max or 100
    self.Value = math.clamp(defaultValue or self.Min, self.Min, self.Max)
    self.Callback = callback
    self.AnimationTween = nil
    self.Container = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 34),
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
        Text = title or "滑动条",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 3,
        Parent = self.Container
    })
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
        Size = UDim2.new(1, -13, 0, 8),
        Position = UDim2.new(0, 5, 0, 20),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderTrack})
    self.SliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Accent,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderFill})
    self.Knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -8, 0.5, -8),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
        Parent = self.SliderTrack
    })
    local knobScale = Instance.new("UIScale", self.Knob)
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
        self.ValueLabel.Text = tostring(self.Value)
        local t = (self.Value - self.Min) / (self.Max - self.Min)
        self.SliderFill.Size = UDim2.new(t, 0, 1, 0)
        self.Knob.Position = UDim2.new(t, -8, 0.5, -8)
        if self.Callback then self.Callback(self.Value) end
    end
    local function animateToValue(targetValue)
        targetValue = math.clamp(targetValue, self.Min, self.Max)
        if targetValue == self.Value then return end
        local targetT = (targetValue - self.Min) / (self.Max - self.Min)
        stopAnimation()
        local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local fillTween = TweenService:Create(self.SliderFill, tweenInfo, {Size = UDim2.new(targetT, 0, 1, 0)})
        local knobTween = TweenService:Create(self.Knob, tweenInfo, {Position = UDim2.new(targetT, -8, 0.5, -8)})
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
        newValue = math.round(newValue)
        if newValue ~= self.Value then
            stopAnimation()
            setValueImmediately(newValue)
        end
    end
    self.SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            local trackPos = self.SliderTrack.AbsolutePosition
            local trackSize = self.SliderTrack.AbsoluteSize.X
            if trackSize <= 0 then return end
            local t = math.clamp((pos.X - trackPos.X) / trackSize, 0, 1)
            local targetValue = self.Min + t * (self.Max - self.Min)
            targetValue = math.round(targetValue)
            animateToValue(targetValue)
            dragging = true
            SpringTween(knobScale, {Scale = 1.2}, 0.15)
        end
    end)
    self.Knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            stopAnimation()
            SpringTween(knobScale, {Scale = 1.2}, 0.15)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = input.Position
            updateFromMousePosition(pos.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            SpringTween(knobScale, {Scale = 1}, 0.25)
        end
    end)
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Slider"})
    return self
end

local TextInput = setmetatable({}, {__index = Control})
TextInput.__index = TextInput
function TextInput:New(name, parent, placeholder, defaultValue, callback)
    local self = Control:New(name, parent)
    self.Callback = callback
    self.Container = CreateInstance("Frame", {
        Name = name,
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
        PlaceholderText = placeholder or "输入...",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 2,
        Parent = self.Container
    })
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
    end)
    table.insert(WasUI.Objects, {Object = self.Container, Type = "TextInput"})
    return self
end

function WasUI:CreateTextInput(parent, placeholder, defaultValue, callback)
    return TextInput:New("TextInput", parent, placeholder, defaultValue, callback)
end

local function AnimateThemeChange(oldTheme, newTheme)
    local duration = 0.35
    for _, obj in ipairs(WasUI.Objects) do
        local instance = obj.Object
        if instance and instance.Parent then
            if obj.Type == "Button" then
                Tween(instance, {BackgroundColor3 = newTheme.Primary, TextColor3 = newTheme.Text}, duration)
                local icon = instance:FindFirstChildOfClass("ImageLabel")
                if icon then
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
                if knobIcon then
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
                        local knobScale = knob:FindFirstChildOfClass("UIScale")
                        if knobScale then
                        end
                    end
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
                    if arrow and arrow:IsA("ImageLabel") then
                        Tween(arrow, {ImageColor3 = newTheme.Text}, duration)
                    end
                end
            elseif obj.Type == "Category" then
                local titleLabel = instance:FindFirstChild("Title")
                local line = instance:FindFirstChild("Line")
                if titleLabel and titleLabel:IsA("TextLabel") then
                    Tween(titleLabel, {TextColor3 = newTheme.Text}, duration)
                end
                if line and line:IsA("Frame") then
                    Tween(line, {BackgroundColor3 = newTheme.Primary}, duration)
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
                    if title and title:IsA("TextLabel") then
                        Tween(title, {TextColor3 = newTheme.Text}, duration)
                    end
                    local closeBtn = titleBar:FindFirstChild("CloseButton")
                    if closeBtn and closeBtn:IsA("ImageButton") then
                        local icon = closeBtn:FindFirstChildOfClass("ImageLabel")
                        if icon then
                            Tween(icon, {ImageColor3 = newTheme.Text}, duration)
                        else
                            Tween(closeBtn, {TextColor3 = newTheme.Text}, duration)
                        end
                    end
                    local searchBtn = titleBar:FindFirstChild("SearchButton")
                    if searchBtn and searchBtn:IsA("ImageButton") then
                        local icon = searchBtn:FindFirstChildOfClass("ImageLabel")
                        if icon then
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
                    if username and username:IsA("TextLabel") then
                        Tween(username, {TextColor3 = newTheme.Text}, duration)
                    end
                    if executorLabel and executorLabel:IsA("TextLabel") then
                        Tween(executorLabel, {TextColor3 = newTheme.Text}, duration)
                    end
                    if welcomeLabel and welcomeLabel:IsA("TextLabel") then
                        Tween(welcomeLabel, {TextColor3 = newTheme.Text}, duration)
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
                local dotContainer = instance:FindFirstChild("TitleBar"):FindFirstChild("DotContainer")
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
            end
        end
    end
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
end

function WasUI:SetTheme(themeName)
    if self.Themes[themeName] then
        local oldTheme = self.CurrentTheme
        local newTheme = self.Themes[themeName]
        self.CurrentTheme = newTheme
        AnimateThemeChange(oldTheme, newTheme)
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

function Panel:New(name, parent, size, position, backgroundUrl, snowEnabled)
    local self = setmetatable({}, Panel)
    if backgroundUrl and backgroundUrl ~= "" then
        self.BackgroundImage = CreateInstance("ImageLabel", {
            Name = "Background",
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1,
            Image = backgroundUrl,
            ImageTransparency = 0.4,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 0,
            Parent = parent
        })
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
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})

    self.BorderFlow = CreateInstance("Frame", {
        Name = "BorderFlow",
        Size = UDim2.new(0, self.Instance.AbsoluteSize.X + 4, 0, self.Instance.AbsoluteSize.Y + 4),
        Position = UDim2.new(0, self.Instance.AbsolutePosition.X - 2, 0, self.Instance.AbsolutePosition.Y - 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = -1,
        Parent = self.Instance.Parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.BorderFlow})

    self.BorderStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        Transparency = 0,
        Parent = self.BorderFlow
    })

    local function updateBorder()
        if not self.Instance or not self.BorderFlow then return end
        self.BorderFlow.Position = UDim2.new(0, self.Instance.AbsolutePosition.X - 2, 0, self.Instance.AbsolutePosition.Y - 2)
        self.BorderFlow.Size = UDim2.new(0, self.Instance.AbsoluteSize.X + 4, 0, self.Instance.AbsoluteSize.Y + 4)
    end
    self.Instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBorder)
    self.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBorder)
    updateBorder()

    local borderTime = 0
    local borderSpeed = 4
    self.BorderConnection = nil

    local function startFlowAnimation()
        if self.BorderConnection then self.BorderConnection:Disconnect() end
        self.BorderConnection = RunService.Heartbeat:Connect(function(deltaTime)
            borderTime = borderTime + deltaTime * borderSpeed
            local hue = (borderTime % 1) * 360
            local color = Color3.fromHSV(hue / 360, 1, 1)
            self.BorderStroke.Color = color
            self.BorderStroke.Transparency = 0
        end)
    end

    function self:SetRainbowMode(mode)
        if mode == "整体" or mode == "流动" then
            self.RainbowMode = mode
            self.BorderFlow.Visible = true
            startFlowAnimation()
        end
    end

    self:SetRainbowMode("整体")

    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.Instance
    })
    CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 10),
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
        Size = UDim2.new(1, -120, 1, 0),
        Position = UDim2.new(0, 54, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = WasUI.CurrentTheme.Text,
        TextTransparency = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 10, 0, 0.8),
        BackgroundTransparency = 1,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    self.DotAreaButton = CreateInstance("ImageButton", {
        Name = "DotAreaButton",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 2,
        Parent = self.DotContainer
    })
    self.CloseDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 1.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.DotContainer
    })
    self.MinimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 16.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.DotContainer
    })
    self.MaximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 31.2, 0.5, -5.4),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ZIndex = 3,
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
        ZIndex = 5,
        Parent = self.TitleBar
    })
    local searchBox = CreateInstance("TextBox", {
        Name = "SearchBox",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        PlaceholderText = "搜索...",
        Text = "",
        TextColor3 = WasUI.CurrentTheme.Text,
        PlaceholderColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        ClearTextOnFocus = false,
        ZIndex = 6,
        Parent = searchContainer
    })
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
        ZIndex = 10,
        Parent = self.TitleBar
    })
    local closeIcon = WasUI:CreateIcon("circle-x", UDim2.new(0, 18, 0, 18), WasUI.CurrentTheme.Text)
    if closeIcon then
        closeIcon.Parent = closeButton
        closeIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    else
        closeButton.Text = "×"
        closeButton.TextColor3 = WasUI.CurrentTheme.Text
        closeButton.TextSize = 16
        closeButton.Font = Enum.Font.GothamBold
    end
    local searchButton = CreateInstance("ImageButton", {
        Name = "SearchButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -56, 0, 2),
        BackgroundTransparency = 1,
        Image = "",
        AutoButtonColor = false,
        ZIndex = 10,
        Parent = self.TitleBar
    })
    local searchIcon = WasUI:CreateIcon("search", UDim2.new(0, 18, 0, 18), WasUI.CurrentTheme.Text)
    if searchIcon then
        searchIcon.Parent = searchButton
        searchIcon.Position = UDim2.new(0.5, -9, 0.5, -9)
    else
        searchButton.Text = "🔍"
        searchButton.TextColor3 = WasUI.CurrentTheme.Text
        searchButton.TextSize = 14
        searchButton.Font = Enum.Font.GothamBold
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
        for _, moved in ipairs(movedControls) do
            if moved.control and moved.control.Parent then
                moved.control.Parent = moved.originalParent
            end
        end
        movedControls = {}
        self.Tabs = {}
        for tabName, btn in pairs(originalTabButtons) do
            local frame = originalTabFrames[tabName]
            frame.Parent = self.ContentArea
            btn.Parent = self.TabContainer
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
                        if child:IsA("Frame") and child.Name ~= "Spacing" then
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
            Text = "搜索结果",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = 999,
            ZIndex = 2,
            Parent = self.TabContainer
        })
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
        if isSearchActive then
            expandSearchBox(false)
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
        self.Title.Visible = false
        self.AnnouncementBar.Visible = false
        self.TabBar.Visible = false
        self.ContentArea.Visible = false
        closeButton.Visible = false
        searchButton.Visible = false
        searchContainer.Visible = false
        self.DraggableArea.Visible = false
        self.DotContainer.Visible = true
        if self.SnowContainer then
            self.SnowContainer.Visible = false
        end
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
        self.Title.Visible = true
        self.AnnouncementBar.Visible = true
        self.TabBar.Visible = true
        self.ContentArea.Visible = true
        closeButton.Visible = true
        searchButton.Visible = true
        self.DraggableArea.Visible = true
        self.DotContainer.Visible = true
        if self.SnowContainer then
            self.SnowContainer.Visible = true
        end
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
            Size = UDim2.new(0, 400, 0, 220),
            Position = UDim2.new(0.5, -200, 0.5, -110),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 0.3,
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
            Text = WasUI.DialogTitle,
            TextColor3 = WasUI.CurrentTheme.Text,
            TextTransparency = 0,
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            Parent = dialogFrame,
            ZIndex = 10002
        })
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
            Text = "确认关闭",
            TextColor3 = WasUI.CurrentTheme.Error,
            TextTransparency = 0,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            AutoButtonColor = true,
            Parent = buttonContainer,
            ZIndex = 10003
        })
        local cancelButton = CreateInstance("TextButton", {
            Name = "Cancel",
            Size = UDim2.new(0, 110, 0, 36),
            BackgroundColor3 = WasUI.CurrentTheme.Section,
            BackgroundTransparency = 0.3,
            Text = "取消",
            TextColor3 = WasUI.CurrentTheme.Text,
            TextTransparency = 0,
            Font = Enum.Font.GothamSemibold,
            TextSize = 14,
            AutoButtonColor = true,
            Parent = buttonContainer,
            ZIndex = 10003
        })
        for _, btn in ipairs({confirmButton, cancelButton}) do
            CreateInstance("UICorner", {CornerRadius = UDim.new(0, 18), Parent = btn})
            btn.MouseEnter:Connect(function()
                Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
            end)
            btn.MouseLeave:Connect(function()
                Tween(btn, {BackgroundColor3 = WasUI.CurrentTheme.Section}, 0.2)
            end)
        end
        dialogFrame.BackgroundTransparency = 1
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
            self:SetVisible(false)
            overlay:Destroy()
            pcall(function() WasUI.DropdownGui:Destroy() end)
            pcall(function() WasUI.NotificationGui:Destroy() end)
            pcall(function() WasUI.DropdownGui = nil end)
            pcall(function() WasUI.NotificationGui = nil end)
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
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    local function isPointOverButton(btn, point)
        if not btn or not btn.Parent then return false end
        local absPos = btn.AbsolutePosition
        local absSize = btn.AbsoluteSize
        return point.X >= absPos.X and point.X <= absPos.X + absSize.X and
               point.Y >= absPos.Y and point.Y <= absPos.Y + absSize.Y
    end
    local function startDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local hitCloseDot = isPointOverButton(self.CloseDot, mousePos)
            local hitMinimizeDot = isPointOverButton(self.MinimizeDot, mousePos)
            local hitMaximizeDot = isPointOverButton(self.MaximizeDot, mousePos)
            local hitCloseBtn = isPointOverButton(closeButton, mousePos)
            local hitSearchBtn = isPointOverButton(searchButton, mousePos)
            if not (hitCloseDot or hitMinimizeDot or hitMaximizeDot or hitCloseBtn or hitSearchBtn) then
                dragging = true
                dragStart = input.Position
                startPos = self.Instance.Position
            end
        end
    end
    local function stopDragging()
        dragging = false
    end
    self.DraggableArea.InputBegan:Connect(startDragging)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newPosition = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            self.Instance.Position = newPosition
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            stopDragging()
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
            Size = UDim2.new(0, 300, 0, 320),
            Position = UDim2.new(0.5, -150, 0.5, -160),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 0.2,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 1000,
            Parent = settingsGui
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = settingsFrame})
        local scale = Instance.new("UIScale")
        scale.Scale = 0.8
        scale.Parent = settingsFrame
        settingsFrame.BackgroundTransparency = 1
        WasUI.SettingsGui = settingsGui
        WasUI.SettingsPanel = settingsFrame
        local titleBar = CreateInstance("Frame", {
            Name = "TitleBar",
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            Parent = settingsFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = titleBar})
        local titleLabel = CreateInstance("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, -30, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
            BackgroundTransparency = 1,
            Text = "UI设置",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1001,
            Parent = titleBar
        })
        local closeBtn = CreateInstance("TextButton", {
            Name = "Close",
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -28, 0, 3),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamBold,
            TextSize = 18,
            ZIndex = 1001,
            Parent = titleBar
        })
        closeBtn.MouseButton1Click:Connect(function()
            Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
            Tween(scale, {Scale = 0.8}, 0.2)
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
            Text = "窗口风格",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        local themeDropdown = CreateInstance("TextButton", {
            Name = "ThemeDropdown",
            Size = UDim2.new(0, 120, 0, 28),
            Position = UDim2.new(1, -130, 0, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BackgroundTransparency = 0.3,
            Text = "Dark",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            ZIndex = 1002,
            Parent = contentFrame
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = themeDropdown})
        themeDropdown.MouseButton1Click:Connect(function()
            local currentTheme = nil
            for name, _ in pairs(WasUI.Themes) do
                if WasUI.CurrentTheme == WasUI.Themes[name] then
                    currentTheme = name
                    break
                end
            end
            local newTheme = (currentTheme == "Dark") and "Light" or "Dark"
            Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
            Tween(scale, {Scale = 0.8}, 0.2)
            task.wait(0.2)
            if WasUI.SettingsGui then
                WasUI.SettingsGui:Destroy()
                WasUI.SettingsGui = nil
            end
            WasUI.SettingsPanel = nil
            WasUI:SetTheme(newTheme)
        end)
        local rainbowModeLabel = CreateInstance("TextLabel", {
            Name = "RainbowModeLabel",
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            Text = "彩虹边框模式",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
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
        local posLabel = CreateInstance("TextLabel", {
            Name = "PosLabel",
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text = "窗口位置偏移",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 1002,
            Parent = contentFrame
        })
        local updating = false
        local function updateWindowPosition(x, y)
            if updating then return end
            updating = true
            self.Instance.Position = UDim2.new(self.Instance.Position.X.Scale, x, self.Instance.Position.Y.Scale, y)
            updating = false
        end
        local xSlider = WasUI:CreateSlider(contentFrame, "X轴位置", -400, 0, self.Instance.Position.X.Offset, function(value)
            updateWindowPosition(value, self.Instance.Position.Y.Offset)
        end)
        xSlider.TitleLabel.ZIndex = 1002
        xSlider.ValueLabel.ZIndex = 1002
        xSlider.SliderTrack.ZIndex = 1002
        xSlider.SliderFill.ZIndex = 1002
        xSlider.Knob.ZIndex = 1002
        xSlider.TitleLabel.Text = "X轴"
        xSlider.TitleLabel.Size = UDim2.new(0.4, 0, 1, 0)
        xSlider.TitleLabel.Position = UDim2.new(0, 0, 0, -4)
        xSlider.ValueLabel.Text = tostring(xSlider.Value)
        xSlider.ValueLabel.Size = UDim2.new(0.2, 0, 1, 0)
        xSlider.ValueLabel.Position = UDim2.new(0.8, 0, 0, -4)
        xSlider.SliderTrack.Size = UDim2.new(1, 7, 0, 8)
        xSlider.SliderTrack.Position = UDim2.new(0, -5, 0, 20)
        local ySlider = WasUI:CreateSlider(contentFrame, "Y轴位置", -300, -110, self.Instance.Position.Y.Offset, function(value)
            updateWindowPosition(self.Instance.Position.X.Offset, value)
        end)
        ySlider.TitleLabel.ZIndex = 1002
        ySlider.ValueLabel.ZIndex = 1002
        ySlider.SliderTrack.ZIndex = 1002
        ySlider.SliderFill.ZIndex = 1002
        ySlider.Knob.ZIndex = 1002
        ySlider.TitleLabel.Text = "Y轴"
        ySlider.TitleLabel.Size = UDim2.new(0.4, 0, 1, 0)
        ySlider.TitleLabel.Position = UDim2.new(0, 0, 0, -4)
        ySlider.ValueLabel.Text = tostring(ySlider.Value)
        ySlider.ValueLabel.Size = UDim2.new(0.2, 0, 1, 0)
        ySlider.ValueLabel.Position = UDim2.new(0.8, 0, 0, -4)
        ySlider.SliderTrack.Size = UDim2.new(1, 7, 0, 8)
        ySlider.SliderTrack.Position = UDim2.new(0, -5, 0, 20)
        local function syncSliderValues()
            if updating then return end
            local xVal = self.Instance.Position.X.Offset
            local yVal = self.Instance.Position.Y.Offset
            if xSlider then
                xSlider.Value = xVal
                xSlider.ValueLabel.Text = tostring(xVal)
                xSlider.SliderFill.Size = UDim2.new((xVal - xSlider.Min) / (xSlider.Max - xSlider.Min), 0, 1, 0)
                xSlider.Knob.Position = UDim2.new((xVal - xSlider.Min) / (xSlider.Max - xSlider.Min), -8, 0.5, -8)
            end
            if ySlider then
                ySlider.Value = yVal
                ySlider.ValueLabel.Text = tostring(yVal)
                ySlider.SliderFill.Size = UDim2.new((yVal - ySlider.Min) / (ySlider.Max - ySlider.Min), 0, 1, 0)
                ySlider.Knob.Position = UDim2.new((yVal - ySlider.Min) / (ySlider.Max - ySlider.Min), -8, 0.5, -8)
            end
        end
        self.Instance:GetPropertyChangedSignal("Position"):Connect(syncSliderValues)
        syncSliderValues()
        local groupButton = CreateInstance("TextButton", {
            Name = "GroupButton",
            Size = UDim2.new(1, 0, 0, 32),
            Position = UDim2.new(0, 0, 1, -40),
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
        refreshCanvas()
        Tween(settingsFrame, {BackgroundTransparency = 0.2}, 0.25)
        Tween(scale, {Scale = 1}, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local function onScreenClick(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            local mousePos = input.Position
            local framePos = settingsFrame.AbsolutePosition
            local frameSize = settingsFrame.AbsoluteSize
            local inPanel = mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                            mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y
            if not inPanel then
                Tween(settingsFrame, {BackgroundTransparency = 1}, 0.2)
                Tween(scale, {Scale = 0.8}, 0.2)
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
        Text = "欢迎使用 WasUI",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 2,
        Parent = self.AnnouncementBar
    })
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
            Text = tabName,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = self.TabOrderCounter,
            ZIndex = 2,
            Parent = self.TabContainer
        })
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
        self.Title.Text = text
    end
    function self:SetWelcome(text)
        self.WelcomeLabel.Text = text
    end
    if snowEnabled then
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
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Panel"})
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
    local title = options.Title or "Notification"
    local content = options.Content or ""
    local duration = options.Duration or 3
    local notificationId = HttpService:GenerateGUID(false)
    local frame = CreateInstance("Frame", {
        Name = "Notification_" .. notificationId,
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, WasUI.NotificationTop),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 9999,
        Parent = WasUI.NotificationGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    local stroke = CreateInstance("UIStroke", {
        Color = WasUI.CurrentTheme.Text,
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
        Font = Enum.Font.GothamSemibold,
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

function WasUI:CreateWindow(title, size, position, backgroundUrl, snowEnabled)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WasUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = WasUI.DefaultDisplayOrder
    screenGui.Parent = game:GetService("CoreGui")
    local window = Panel:New(title, screenGui, size or UDim2.new(0, 380, 0, 350), position, backgroundUrl, snowEnabled)
    RecordOriginalTransparency(window.Instance)
    return window
end

function WasUI:CreateButton(parent, text, onClick, size, iconName)
    return Button:New("Button", parent, text, onClick, size, iconName)
end

function WasUI:CreateToggle(parent, initialState, onToggle, featureName, rainbowName)
    return ToggleSwitch:New("Toggle", parent, nil, initialState, onToggle, featureName, rainbowName)
end

function WasUI:CreateToggleWithTitle(parent, title, initialState, onToggle, featureName, rainbowName, iconName)
    return ToggleSwitch:New("Toggle", parent, title, initialState, onToggle, featureName, rainbowName, iconName)
end

function WasUI:CreateLabel(parent, text, textColor)
    return Label:New("Label", parent, text, textColor)
end

function WasUI:CreateCategory(parent, title)
    return Category:New("Category", parent, title)
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

_G.WasUIModule = WasUI
return WasUI