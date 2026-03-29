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

if _G.WasUILoaded then
    warn("WasUI 已加载，跳过重复加载")
    return _G.WasUIModule
end
_G.WasUILoaded = true

WasUI.DefaultDisplayOrder = 10
WasUI.DialogTitle = "你要关闭WasUI吗?"

WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}
WasUI.OpenDropdowns = {}

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

WasUI.Themes = {
    Dark = {
        Primary = Color3.fromRGB(15, 15, 20),
        Secondary = Color3.fromRGB(25, 25, 30),
        Background = Color3.fromRGB(28, 28, 34),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123),
        Section = Color3.fromRGB(45, 45, 50),
        Input = Color3.fromRGB(45, 45, 50),
        TabBorder = Color3.fromRGB(60, 60, 65),
        TabButton = Color3.fromRGB(0, 0, 0)
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
local rainbowSpeed = 4
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
function Button:New(name, parent, text, onClick, size)
    local self = Control:New(name, parent)
    local buttonSize = size or UDim2.new(1, 0, 0, 28)
    self.Instance = CreateInstance("TextButton", {
        Name = name,
        Size = buttonSize,
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        Text = text or "按钮",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent,
        AutomaticSize = Enum.AutomaticSize.None
    })
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 14), Parent = self.Instance})
    local padding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = self.Instance
    })
    self.Instance.MouseEnter:Connect(function() 
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
    end)
    self.Instance.MouseLeave:Connect(function() 
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
    end)
    self.Instance.MouseButton1Down:Connect(function() 
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
    end)
    self.Instance.MouseButton1Up:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
        if onClick then onClick() end
    end)
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Button"})
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, title, initialState, onToggle, featureName, rainbowName)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = featureName or name
    self.RainbowName = rainbowName or self.FeatureName
    
    self.Container = CreateInstance("Frame", {
        Name = name .. "_Container",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = parent
    })
    
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
            Parent = self.Container
        })
    end
    
    self.Background = CreateInstance("ImageButton", {
        Name = name .. "_BG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = title and UDim2.new(1, -40, 0.5, -9) or UDim2.new(1, -40, 0.5, -9),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(200, 200, 200),
        Image = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = self.Container
    })
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
    if self.Toggled then
        CreateRainbowTextForFeature(self.RainbowName)
    end
    self.Background.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.2)
            CreateRainbowTextForFeature(self.RainbowName)
        else
            Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
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
        Parent = parent
    })
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
        Parent = parent
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.9, 0, 1, 0),
        Position = UDim2.new(0, 2, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.new(1, 1, 1),
        TextTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = self.Instance
    })
    local line = CreateInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(1, -4, 0, 1),
        Position = UDim2.new(0, 2, 1, -2),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
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
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.DropdownButton})
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
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.OptionsContainer})
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
                self:Close()
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
        self.OptionsContainer.CanvasSize = UDim2.new(0, 0, 0, optionsList.AbsoluteContentSize.Y)
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
    end

    function self:Close()
        if not self.IsOpen then return end
        self.IsOpen = false
        for i, dropdown in ipairs(WasUI.OpenDropdowns) do
            if dropdown == self then
                table.remove(WasUI.OpenDropdowns, i)
                break
            end
        end
        Tween(self.OptionsContainer, {BackgroundTransparency = 1}, 0.2)
        Tween(shadow, {Transparency = 1}, 0.2)
        task.wait(0.2)
        self.OptionsContainer.Visible = false
    end

    self.DropdownButton.MouseButton1Click:Connect(function()
        if self.IsOpen then
            self:Close()
        else
            self:Open()
        end
    end)

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
    self.Container = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundTransparency = 1,
        Parent = parent
    })
    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "滑动条",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "Value",
        Size = UDim2.new(0.3, 0, 0, 20),
        Position = UDim2.new(0.7, -3, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(self.Value),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Container
    })
    self.SliderTrack = CreateInstance("Frame", {
        Name = "Track",
        Size = UDim2.new(1, -13, 0, 12),
        Position = UDim2.new(0, 5, 0, 22),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderTrack})
    
    self.SliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(128, 0, 128),
        BorderSizePixel = 0,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderFill})
    
    -- 完全透明的 Knob（仅用于接收输入）
    self.Knob = CreateInstance("Frame", {
        Name = "Knob",
        Size = UDim2.new(0, 20, 0, 20),          -- 比轨道稍大，便于触摸
        Position = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), -10, 0.5, -10),
        BackgroundTransparency = 1,              -- 完全透明
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.SliderTrack
    })

    local dragging = false
    local function updateFromMousePosition(inputX)
        local trackPos = self.SliderTrack.AbsolutePosition
        local trackSize = self.SliderTrack.AbsoluteSize.X
        if trackSize <= 0 then return end
        local t = math.clamp((inputX - trackPos.X) / trackSize, 0, 1)
        local newValue = self.Min + t * (self.Max - self.Min)
        newValue = math.round(newValue)
        if newValue ~= self.Value then
            self.Value = newValue
            self.ValueLabel.Text = tostring(self.Value)
            self.SliderFill.Size = UDim2.new(t, 0, 1, 0)
            self.Knob.Position = UDim2.new(t, -10, 0.5, -10)
            if self.Callback then self.Callback(self.Value) end
        end
    end

    self.SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            updateFromMousePosition(pos.X)
            dragging = true
            input:SetConsumed(true)
        end
    end)

    self.Knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            input:SetConsumed(true)
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
        end
    end)

    table.insert(WasUI.Objects, {Object = self.Container, Type = "Slider"})
    return self
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
        Parent = parent
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    
    self.BorderEffect = CreateInstance("Frame", {
        Name = "BorderEffect",
        Size = UDim2.new(0, self.Instance.AbsoluteSize.X + 4, 0, self.Instance.AbsoluteSize.Y + 4),
        Position = UDim2.new(0, self.Instance.AbsolutePosition.X - 2, 0, self.Instance.AbsolutePosition.Y - 2),
        AnchorPoint = Vector2.new(0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = -1,
        Parent = self.Instance.Parent
    })
    local borderCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 12), Parent = self.BorderEffect})
    local borderStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(255, 0, 0),
        Thickness = 2,
        Parent = self.BorderEffect
    })
    local function updateBorder()
        if not self.Instance or not self.BorderEffect then return end
        self.BorderEffect.Position = UDim2.new(
            0, self.Instance.AbsolutePosition.X - 2,
            0, self.Instance.AbsolutePosition.Y - 2
        )
        self.BorderEffect.Size = UDim2.new(
            0, self.Instance.AbsoluteSize.X + 4,
            0, self.Instance.AbsoluteSize.Y + 4
        )
    end
    self.Instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateBorder)
    self.Instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateBorder)
    updateBorder()

    local borderTime = 0
    self.BorderConnection = RunService.Heartbeat:Connect(function(deltaTime)
        borderTime = borderTime + deltaTime * 4
        local r = (math.sin(borderTime) + 1) / 2
        local g = (math.sin(borderTime + math.pi/3) + 1) / 2
        local b = (math.sin(borderTime + 2*math.pi/3) + 1) / 2
        borderStroke.Color = Color3.new(r, g, b)
    end)
    
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
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
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0,
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 28, 1, 0),
        Position = UDim2.new(0, 10.5, 0, 0.8),
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
    
    self.MinimizeButton = CreateInstance("TextButton", {
        Name = "MinimizeButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -54, 0, 2),
        BackgroundTransparency = 1,
        Text = "-",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    
    self.CloseButton = CreateInstance("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -28, 0, 2),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        ZIndex = 2,
        Parent = self.TitleBar
    })
    
    self.IsMinimized = false
    self.OriginalSize = self.Instance.Size
    self.MinimizedSize = UDim2.new(0, 60, 0, 26)
    
    self.MinimizeToDots = function()
        if self.IsMinimized then return end
        Tween(self.Instance, {
            Size = self.MinimizedSize,
            Position = self.Instance.Position
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        self.Title.Visible = false
        self.AnnouncementBar.Visible = false
        self.TabBar.Visible = false
        self.ContentArea.Visible = false
        self.CloseButton.Visible = false
        self.MinimizeButton.Visible = false
        self.DraggableArea.Visible = true
        self.DotContainer.Visible = true
        if self.SnowContainer then
            self.SnowContainer.Visible = false
        end
        self.IsMinimized = true
    end
    
    self.RestoreFromDots = function()
        if not self.IsMinimized then return end
        Tween(self.Instance, {
            Size = self.OriginalSize,
            Position = self.Instance.Position
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        self.Title.Visible = true
        self.AnnouncementBar.Visible = true
        self.TabBar.Visible = true
        self.ContentArea.Visible = true
        self.CloseButton.Visible = true
        self.MinimizeButton.Visible = true
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
            input:SetConsumed(true)
            self:SetVisible(false)
        end
    end)
    
    self.MinimizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            input:SetConsumed(true)
            if self.IsMinimized then
                self:RestoreFromDots()
            else
                self:MinimizeToDots()
            end
        end
    end)
    
    self.MaximizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            input:SetConsumed(true)
        end
    end)
    
    self.MinimizeButton.MouseButton1Click:Connect(self.MinimizeToDots)
    self.CloseButton.MouseButton1Click:Connect(function() 
        local function showCloseDialog()
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
                TextColor3 = Color3.fromRGB(255, 100, 100),
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
                TextColor3 = Color3.fromRGB(255, 255, 255),
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
                if self.BorderEffect then
                    self.BorderEffect:Destroy()
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
            overlay.MouseButton1Click:Connect(function(input)
                local mousePos = input.Position
                local framePos = dialogFrame.AbsolutePosition
                local frameSize = dialogFrame.AbsoluteSize
                if not (mousePos.X >= framePos.X and mousePos.X <= framePos.X + frameSize.X and
                        mousePos.Y >= framePos.Y and mousePos.Y <= framePos.Y + frameSize.Y) then
                    Tween(dialogFrame, {BackgroundTransparency = 1}, 0.2)
                    Tween(overlay, {BackgroundTransparency = 1}, 0.2)
                    task.wait(0.2)
                    overlay:Destroy()
                end
            end)
        end
        showCloseDialog()
    end)
    
    local dragging = false
    local dragStart = Vector2.new()
    local startPos = UDim2.new()
    local function startDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local dotContainerPos = self.DotContainer.AbsolutePosition
            local dotContainerSize = self.DotContainer.AbsoluteSize
            local closeDotPos = self.CloseDot.AbsolutePosition
            local closeDotSize = self.CloseDot.AbsoluteSize
            local minDotPos = self.MinimizeDot.AbsolutePosition
            local minDotSize = self.MinimizeDot.AbsoluteSize
            local maxDotPos = self.MaximizeDot.AbsolutePosition
            local maxDotSize = self.MaximizeDot.AbsoluteSize
            
            local hitDot = (mousePos.X >= closeDotPos.X and mousePos.X <= closeDotPos.X + closeDotSize.X and
                            mousePos.Y >= closeDotPos.Y and mousePos.Y <= closeDotPos.Y + closeDotSize.Y) or
                           (mousePos.X >= minDotPos.X and mousePos.X <= minDotPos.X + minDotSize.X and
                            mousePos.Y >= minDotPos.Y and mousePos.Y <= minDotPos.Y + minDotSize.Y) or
                           (mousePos.X >= maxDotPos.X and mousePos.X <= maxDotPos.X + maxDotSize.X and
                            mousePos.Y >= maxDotPos.Y and mousePos.Y <= maxDotPos.Y + maxDotSize.Y)
            
            if not hitDot then
                dragging = true
                dragStart = input.Position
                startPos = self.Instance.Position
                input:SetConsumed(true)
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
        Parent = self.AnnouncementBar
    })
    local avatarScale = CreateInstance("UIScale", {
        Scale = 1,
        Parent = self.Avatar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    local avatarStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(220, 220, 225),
        Thickness = 1,
        Parent = self.Avatar
    })
    loadAvatar()
    
    self.Avatar.MouseButton1Down:Connect(function()
        Tween(avatarScale, {Scale = 0.9}, 0.1)
    end)
    self.Avatar.MouseButton1Up:Connect(function()
        Tween(avatarScale, {Scale = 1}, 0.1)
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
        Parent = self.AnnouncementBar
    })

    -- 选项卡栏：贴合左侧，高度自适应
    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 0),          -- 高度暂时为0，后面动态调整
        Position = UDim2.new(0, 0, 0, 26 + 80),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.4,
        AutomaticSize = Enum.AutomaticSize.Y,   -- 自动高度
        Parent = self.Instance
    })
    local tabLine = CreateInstance("Frame", {
        Name = "TabLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = WasUI.CurrentTheme.TabBorder,
        Parent = self.TabBar
    })
    
    -- 横向滚动的 TabContainer，贴合左侧，无额外间距
    self.TabContainer = CreateInstance("ScrollingFrame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = WasUI.CurrentTheme.Text,
        ScrollingDirection = Enum.ScrollingDirection.X,
        VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
        CanvasSize = UDim2.new(0, 0, 0, 0),
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
    tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabContainer.CanvasSize = UDim2.new(0, tabListLayout.AbsoluteContentSize.X + 8, 0, 0)
    end)

    -- 内容区域（仅垂直滚动，禁用横向）
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -(26 + 80 + self.TabBar.AbsoluteSize.Y)),
        Position = UDim2.new(0, 0, 0, 26 + 80 + self.TabBar.AbsoluteSize.Y),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ScrollBarThickness = 4,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.Instance
    })
    -- 监听 TabBar 高度变化，调整 ContentArea 位置和大小
    self.TabBar:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        local tabHeight = self.TabBar.AbsoluteSize.Y
        self.ContentArea.Position = UDim2.new(0, 0, 0, 26 + 80 + tabHeight)
        self.ContentArea.Size = UDim2.new(1, 0, 1, -(26 + 80 + tabHeight))
    end)
    
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
    contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentListLayout.AbsoluteContentSize.Y + 8)
    end)

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
            Parent = self.TabContainer
        })
        local tabUnderline = CreateInstance("Frame", {
            Name = "Underline",
            Size = UDim2.new(0, 0, 0, 2),
            Position = UDim2.new(0.5, 0, 1, -2),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(128, 0, 128),
            Visible = false,
            Parent = tabButton
        })

        -- 每个选项卡对应的内容框架
        local tabFrame = CreateInstance("Frame", {
            Name = "TabFrame_" .. tabName,
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1,
            Visible = false,
            AutomaticSize = Enum.AutomaticSize.Y,
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
        -- 当内部内容变化时，触发外层布局更新
        tabInnerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            -- 重新触发 ContentArea 的 CanvasSize 更新
            contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire()
        end)

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
        if self.ActiveTab then
            local old = self.Tabs[self.ActiveTab]
            old.Underline.Visible = false
            Tween(old.Underline, {Size = UDim2.new(0, 0, 0, 2)}, 0.15)
            old.Frame.Visible = false
        end

        local new = self.Tabs[tabName]
        new.Underline.Visible = true
        Tween(new.Underline, {Size = UDim2.new(1, 0, 0, 2)}, 0.25)
        new.Frame.Visible = true
        self.ActiveTab = tabName
    end

    function self:SetVisible(visible)
        self.Instance.Visible = visible
        if self.BorderEffect then
            self.BorderEffect.Visible = visible
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
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
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
    for i, data in ipairs(sorted) do
        local targetY = WasUI.NotificationTop + (i-1)*(WasUI.NotificationHeight + WasUI.NotificationSpacing)
        Tween(data.Frame, {Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)}, 0.2)
    end
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
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 9999,
        Parent = WasUI.NotificationGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    local stroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(0, 0, 0),
        Thickness = 1,
        Parent = frame
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 0, 14),
        Position = UDim2.new(0, 5, 0, 2),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.fromRGB(255, 255, 255),
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
        TextColor3 = Color3.fromRGB(220, 220, 220),
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
    updateAllNotificationPositions()
    Tween(frame, {Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, frame.Position.Y.Offset)}, 0.3)
    task.delay(duration, function()
        WasUI.ActiveNotifications[notificationId] = nil
        updateAllNotificationPositions()
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

function WasUI:CreateButton(parent, text, onClick, size)
    return Button:New("Button", parent, text, onClick, size)
end

function WasUI:CreateToggle(parent, initialState, onToggle, featureName, rainbowName)
    return ToggleSwitch:New("Toggle", parent, nil, initialState, onToggle, featureName, rainbowName)
end

function WasUI:CreateToggleWithTitle(parent, title, initialState, onToggle, featureName, rainbowName)
    return ToggleSwitch:New("Toggle", parent, title, initialState, onToggle, featureName, rainbowName)
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

_G.WasUIModule = WasUI
return WasUI
