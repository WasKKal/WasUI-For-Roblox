local WasUI = {}
WasUI.__index = WasUI
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

if _G.WasUILoaded then
    warn("WasUI 已加载，跳过重复加载")
    return _G.WasUIModule
end
_G.WasUILoaded = true

WasUI.DefaultDisplayOrder = 10
WasUI.DialogTitle = "你要关闭WasUI吗?"
WasUI.DefaultNotificationTitle = "通知"

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
    if type(featureName) ~= "string" then
        warn("featureName must be a string")
        return
    end
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
    if type(featureName) ~= "string" then return end
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
local rainbowSpeed = 4
RunService.Heartbeat:Connect(function(deltaTime)
    rainbowTime += deltaTime * rainbowSpeed
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
function ToggleSwitch:New(name, parent, initialState, onToggle, featureName)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = type(featureName) == "string" and featureName or name

    self.Background = CreateInstance("ImageButton", {
        Name = name .. "_BG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(1, -40, 0.5, -9),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(200, 200, 200),
        Image = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = parent
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
        CreateRainbowTextForFeature(self.FeatureName)
    end
    self.Background.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.2)
            CreateRainbowTextForFeature(self.FeatureName)
        else
            Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
            DestroyRainbowTextForFeature(self.FeatureName)
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
    end)
    table.insert(WasUI.Objects, {Object = self.Background, Type = "Toggle"})
    table.insert(WasUI.Objects, {Object = self.Knob, Type = "ToggleKnob"})
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label
function Label:New(name, parent, text)
    local self = Control:New(name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        Text = text or "标签",
        TextColor3 = WasUI.CurrentTheme.Text,
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
        Position = UDim2.new(0.05, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.new(1,1,1),
        TextTransparency = 0,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = self.Instance
    })
    local line = CreateInstance("Frame", {
        Name = "Line",
        Size = UDim2.new(0.9, 0, 0, 1),
        Position = UDim2.new(0.05, 0, 1, -2),
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
        Position = UDim2.new(0.7, 0, 0, 0),
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
        Parent = self.DropdownButton
    })

    self.OptionsContainer = CreateInstance("ScrollingFrame", {
        Name = "OptionsContainer",
        Size = UDim2.new(0.3, 0, 0, 0),
        Position = UDim2.new(0.7, 0, 0, 24),
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
        local viewportSize = game:GetService("CoreGui").AbsoluteSize
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
        Position = UDim2.new(0.7, 0, 0, 0),
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
        Size = UDim2.new(1, -16, 0, 12),
        Position = UDim2.new(0, 8, 0, 22),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderTrack})
    self.SliderFill = CreateInstance("Frame", {
        Name = "Fill",
        Size = UDim2.new((self.Value - self.Min) / (self.Max - self.Min), 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderFill})

    local dragging = false
    local function updateFromInput()
        local mousePos = UserInputService:GetMouseLocation()
        local trackPos = self.SliderTrack.AbsolutePosition
        local trackSize = self.SliderTrack.AbsoluteSize.X
        if trackSize <= 0 then return end
        local mouseX = mousePos.X - trackPos.X
        local t = math.clamp(mouseX / trackSize, 0, 1)
        local newValue = self.Min + t * (self.Max - self.Min)
        newValue = math.round(newValue)
        if newValue ~= self.Value then
            self.Value = newValue
            self.ValueLabel.Text = tostring(self.Value)
            self.SliderFill.Size = UDim2.new(t, 0, 1, 0)
            if self.Callback then self.Callback(self.Value) end
        end
    end

    self.SliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromInput()
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromInput()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    table.insert(WasUI.Objects, {Object = self.Container, Type = "Slider"})
    return self
end

local Panel = {}
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = setmetatable({}, Panel)
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = size or UDim2.new(0, 420, 0, 350),
        Position = position or UDim2.new(0.5, -210, 0.5, -175),
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
        borderTime += deltaTime * 4
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
        Position = UDim2.new(0, 53, 0, 0),
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
        TextSize = 18,
        Parent = self.TitleBar
    })

    local dragging = false
    local dragStartPos, dragStartFramePos

    self.DraggableArea.MouseButton1Down:Connect(function(x, y)
        dragging = true
        dragStartPos = Vector2.new(x, y)
        dragStartFramePos = self.Instance.Position
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStartPos
            self.Instance.Position = UDim2.new(
                dragStartFramePos.X.Scale,
                dragStartFramePos.X.Offset + delta.X,
                dragStartFramePos.Y.Scale,
                dragStartFramePos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    self.CloseButton.MouseButton1Click:Connect(function()
        local dialog = {}
        dialog.Container = CreateInstance("Frame", {
            Size = UDim2.new(0, 260, 0, 120),
            Position = UDim2.new(0.5, -130, 0.5, -60),
            BackgroundColor3 = WasUI.CurrentTheme.Background,
            BackgroundTransparency = 0.3,
            ClipsDescendants = true,
            Parent = game:GetService("CoreGui")
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = dialog.Container})
        local stroke = CreateInstance("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1, Parent = dialog.Container})
        dialog.Title = CreateInstance("TextLabel", {
            Size = UDim2.new(1, 0, 0, 30),
            Position = UDim2.new(0, 0, 0, 0),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = WasUI.DialogTitle,
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamSemibold,
            TextSize = 13,
            Parent = dialog.Container
        })
        dialog.Message = CreateInstance("TextLabel", {
            Size = UDim2.new(1, -20, 0, 40),
            Position = UDim2.new(0, 10, 0, 35),
            BackgroundTransparency = 1,
            Text = "确定要关闭界面吗？",
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            Parent = dialog.Container
        })
        dialog.Yes = CreateInstance("TextButton", {
            Size = UDim2.new(0, 100, 0, 26),
            Position = UDim2.new(0.5, -105, 1, -35),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = "确定",
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            Parent = dialog.Container
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dialog.Yes})
        dialog.No = CreateInstance("TextButton", {
            Size = UDim2.new(0, 100, 0, 26),
            Position = UDim2.new(0.5, 5, 1, -35),
            BackgroundColor3 = WasUI.CurrentTheme.Primary,
            BackgroundTransparency = 0.3,
            Text = "取消",
            TextColor3 = Color3.new(1,1,1),
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            Parent = dialog.Container
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = dialog.No})
        dialog.Yes.MouseButton1Click:Connect(function()
            for _, data in pairs(WasUI.ActiveRainbowTexts) do
                if data.ScreenGui then data.ScreenGui:Destroy() end
            end
            if WasUI.NotificationGui then WasUI.NotificationGui:Destroy() end
            if WasUI.DropdownGui then WasUI.DropdownGui:Destroy() end
            dialog.Container:Destroy()
            self.Instance:Destroy()
            _G.WasUILoaded = nil
        end)
        dialog.No.MouseButton1Click:Connect(function()
            dialog.Container:Destroy()
        end)
    end)

    self.IsMinimized = false
    self.OriginalSize = self.Instance.Size

    self.MinimizeButton.MouseButton1Click:Connect(function()
        self.IsMinimized = not self.IsMinimized
        if self.IsMinimized then
            Tween(self.Instance, {Size = UDim2.new(0, 380, 0, 26)}, 0.2)
        else
            Tween(self.Instance, {Size = self.OriginalSize}, 0.2)
        end
    end)

    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, 80),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Secondary,
        BackgroundTransparency = 0.4,
        Parent = self.Instance
    })

    self.Avatar = CreateInstance("ImageButton", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(240,240,245),
        Image = "",
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = self.AnnouncementBar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    CreateInstance("UIStroke", {Color = Color3.fromRGB(220,220,225), Thickness = 1, Parent = self.Avatar})

    local player = Players.LocalPlayer
    pcall(function()
        self.Avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
    end)

    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 62, 0.12, 0),
        BackgroundTransparency = 1,
        Text = "用户: " .. player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })

    local executorName = "Unknown"
    pcall(function()
        if typeof(getexecutorname) == "function" then
            executorName = getexecutorname()
        elseif typeof(getExecutor) == "function" then
            executorName = getExecutor()
        end
    end)

    self.ExecutorLabel = CreateInstance("TextLabel", {
        Name = "Executor",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 62, 0.35, 0),
        BackgroundTransparency = 1,
        Text = "注入器: " .. executorName,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })

    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.new(0, 0, 0, 106),
        BackgroundColor3 = WasUI.CurrentTheme.Secondary,
        BackgroundTransparency = 0.3,
        Parent = self.Instance
    })

    self.TabListLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Parent = self.TabContainer
    })

    self.TabContentContainer = CreateInstance("Frame", {
        Name = "TabContentContainer",
        Size = UDim2.new(1, 0, 1, -136),
        Position = UDim2.new(0, 0, 0, 136),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })

    self.Tabs = {}
    self.ActiveTab = nil

    function self:AddTab(tabName)
        local tabButton = CreateInstance("TextButton", {
            Name = tabName .. "_Tab",
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundTransparency = 1,
            Text = tabName,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            Parent = self.TabContainer
        })

        local tabUnderline = CreateInstance("Frame", {
            Name = "Underline",
            Size = UDim2.new(0, 0, 0, 2),
            Position = UDim2.new(0.5, 0, 1, -2),
            AnchorPoint = Vector2.new(0.5, 0),
            BackgroundColor3 = Color3.fromRGB(25, 60, 140),
            Visible = false,
            Parent = tabButton
        })

        local tabPage = CreateInstance("Frame", {
            Name = tabName .. "_Page",
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = self.TabContentContainer
        })

        local pageList = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = tabPage
        })

        local pagePadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            PaddingTop = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            Parent = tabPage
        })

        table.insert(self.Tabs, {
            Button = tabButton,
            Underline = tabUnderline,
            Page = tabPage
        })

        tabButton.MouseButton1Click:Connect(function()
            for _, tab in ipairs(self.Tabs) do
                tab.Underline.Visible = false
                Tween(tab.Underline, {Size = UDim2.new(0, 0, 0, 2)}, 0.1)
                tab.Page.Visible = false
            end
            tabUnderline.Visible = true
            Tween(tabUnderline, {Size = UDim2.new(1, 0, 0, 2)}, 0.2)
            tabPage.Visible = true
            self.ActiveTab = tabPage
        end)

        if not self.ActiveTab then
            tabUnderline.Visible = true
            tabUnderline.Size = UDim2.new(1, 0, 0, 2)
            tabPage.Visible = true
            self.ActiveTab = tabPage
        end

        return tabPage
    end

    return self
end

function WasUI:CreateWindow(windowName, size)
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Main",
        ResetOnSpawn = false,
        DisplayOrder = WasUI.DefaultDisplayOrder,
        Parent = game:GetService("CoreGui")
    })
    local window = Panel:New(windowName, screenGui, size or UDim2.new(0, 420, 0, 520))
    return window
end

function WasUI:CreateButton(parent, text, onClick)
    return Button:New(text .. "_Btn", parent, text, onClick)
end

function WasUI:CreateToggle(parent, text, defaultState, onToggle, featureName)
    local frame = CreateInstance("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = parent
    })
    local label = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local toggle = ToggleSwitch:New(text .. "_Toggle", frame, defaultState, onToggle, featureName or text)
    return toggle
end

function WasUI:CreateLabel(parent, text)
    return Label:New(text .. "_Label", parent, text)
end

function WasUI:CreateCategory(parent, title)
    return Category:New(title .. "_Category", parent, title)
end

function WasUI:CreateDropdown(parent, title, options, default, callback, multi)
    return Dropdown:New(title .. "_Dropdown", parent, title, options, default, callback, multi)
end

function WasUI:CreateSlider(parent, title, min, max, default, callback)
    return Slider:New(title .. "_Slider", parent, title, min, max, default, callback)
end

function WasUI:Notify(options)
    local title = options.Title or WasUI.DefaultNotificationTitle
    local content = options.Content or ""
    local duration = options.Duration or 3

    local noticeId = HttpService:GenerateGUID()
    local notice = CreateInstance("Frame", {
        Name = "Notice_" .. noticeId,
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, WasUI.NotificationTop),
        BackgroundColor3 = Color3.fromRGB(30, 30, 34),
        BackgroundTransparency = 0.3,
        Parent = WasUI.NotificationGui
    })

    local stroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(10, 10, 12),
        Thickness = 1,
        Parent = notice
    })

    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 4),
        Parent = notice
    })

    local titleLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        Parent = notice
    })

    local contentLabel = CreateInstance("TextLabel", {
        Size = UDim2.new(1, -72, 1, 0),
        Position = UDim2.new(0, 68, 0, 0),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = Color3.fromRGB(210,210,210),
        Font = Enum.Font.Gotham,
        TextSize = 12,
        Parent = notice
    })

    WasUI.ActiveNotifications[noticeId] = notice
    local totalOffset = 0
    for id, frame in pairs(WasUI.ActiveNotifications) do
        if frame ~= notice then
            totalOffset = totalOffset + frame.Size.Y.Offset + WasUI.NotificationSpacing
        end
    end

    Tween(notice, {
        Position = UDim2.new(1, -WasUI.NotificationWidth - 12, 0, WasUI.NotificationTop + totalOffset)
    }, 0.3)

    task.delay(duration, function()
        if not WasUI.ActiveNotifications[noticeId] then return end
        Tween(notice, {
            Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, notice.Position.Y.Offset)
        }, 0.3)
        task.wait(0.3)
        notice:Destroy()
        WasUI.ActiveNotifications[noticeId] = nil
    end)
end

_G.WasUIModule = WasUI
return WasUI