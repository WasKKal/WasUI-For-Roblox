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

WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.ActiveNotifications = {}

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
function ToggleSwitch:New(name, parent, initialState, onToggle, featureName)
    local self = Control:New(name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    self.FeatureName = featureName or name
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
        TextColor3 = WasUI.CurrentTheme.Primary,
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
    self.MultiSelect = multiSelect or false
    self.Options = options or {}
    self.SelectedValues = {}
    self.SelectedValue = nil

    if self.MultiSelect then
        if type(defaultValue) == "table" then
            for _, v in ipairs(defaultValue) do
                table.insert(self.SelectedValues, v)
            end
        elseif defaultValue ~= nil then
            table.insert(self.SelectedValues, defaultValue)
        end
    else
        if type(defaultValue) == "table" then
            self.SelectedValue = defaultValue[1] or nil
        else
            self.SelectedValue = defaultValue
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
        updateContainerSize()
        updatePosition()
        self.OptionsContainer.Visible = true
        Tween(self.OptionsContainer, {BackgroundTransparency = 0.3}, 0.2)
        Tween(shadow, {Transparency = 0.8}, 0.2)
    end

    function self:Close()
        if not self.IsOpen then return end
        self.IsOpen = false
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

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.IsOpen then
                local mousePos = input.Position
                local menuPos = self.OptionsContainer.AbsolutePosition
                local menuSize = self.OptionsContainer.AbsoluteSize
                local inMenu = mousePos.X >= menuPos.X and mousePos.X <= menuPos.X + menuSize.X and
                                mousePos.Y >= menuPos.Y and mousePos.Y <= menuPos.Y + menuSize.Y
                if not inMenu then
                    self:Close()
                end
            end
        end
    end)

    self:UpdateDisplayText()
    table.insert(WasUI.Objects, {Object = self.Container, Type = "Dropdown"})
    table.insert(WasUI.Objects, {Object = self.DropdownButton, Type = "DropdownButton"})
    return self
end

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
        TextSize = 16,
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
        self.SnowContainer.Visible = false
        self.DotContainer.Visible = true
        self.IsMinimized = true
        if self.SnowConnection then
            self.SnowConnection:Disconnect()
            self.SnowConnection = nil
        end
        for _, flake in ipairs(self.SnowFlakes) do
            if flake.Instance then
                flake.Instance:Destroy()
            end
        end
        self.SnowFlakes = {}
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
        self.SnowContainer.Visible = self.SnowEnabled
        if self.SnowEnabled and not self.SnowConnection then
            self.SnowConnection = RunService.Heartbeat:Connect(function()
                if self.SnowContainer.Visible and self.Instance.Visible then
                    self:UpdateSnowflakes()
                    self:SpawnSnowflakes()
                end
            end)
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
                if self.SnowConnection then
                    self.SnowConnection:Disconnect()
                    self.SnowConnection = nil
                end
                for _, flake in ipairs(self.SnowFlakes) do
                    if flake.Instance then
                        flake.Instance:Destroy()
                    end
                end
                self.SnowFlakes = {}
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
            dragging = true
            dragStart = input.Position
            startPos = self.Instance.Position
            input:SetConsumed(true)
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
    
    local executorName = pcall(function() return getexecutorname() end) and getexecutorname() or (type(getExecutor) == "function" and getExecutor() or "未知")
    self.ExecutorLabel = CreateInstance("TextLabel", {
        Name = "ExecutorLabel",
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 62, 0.35, 0),
        BackgroundTransparency = 1,
        Text = "您使用的执行器为: " .. executorName,
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

    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 26 + 80),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 0.4,
        Parent = self.Instance
    })
    local tabLine = CreateInstance("Frame", {
        Name = "TabLine",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = WasUI.CurrentTheme.TabBorder,
        Parent = self.TabBar
    })
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TabBar
    })
    local tabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 6),
        Parent = self.TabContainer
    })

    self.ContentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -(26 + 80 + 32)),
        Position = UDim2.new(0, 0, 0, 26 + 80 + 32),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        Parent = self.Instance
    })
    local contentPadding = CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        Parent = self.ContentArea
    })

    self.Tabs = {}
    self.ActiveTab = nil

    function self:AddTab(tabName, icon)
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
            Parent = self.TabContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})
        local tabUnderline = CreateInstance("Frame", {
            Name = "Underline",
            Size = UDim2.new(0.8, 0, 0, 2),
            Position = UDim2.new(0.1, 0, 1, -2),
            BackgroundColor3 = WasUI.CurrentTheme.Accent,
            Visible = false,
            Parent = tabButton
        })

        local tabFrame = CreateInstance("ScrollingFrame", {
            Name = "TabFrame_" .. tabName,
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Visible = false,
            ScrollBarThickness = 4,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            Parent = self.ContentArea
        })
        local tabListLayout = CreateInstance("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
            Parent = tabFrame
        })
        local tabPadding = CreateInstance("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
            Parent = tabFrame
        })
        tabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabFrame.CanvasSize = UDim2.new(0, 0, 0, tabListLayout.AbsoluteContentSize.Y + 12)
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
            old.Frame.Visible = false
        end
        local new = self.Tabs[tabName]
        new.Underline.Visible = true
        new.Frame.Visible = true
        self.ActiveTab = tabName
    end

    self.SnowEnabled = false
    self.SnowFlakes = {}
    self.SnowContainer = CreateInstance("Frame", {
        Name = "SnowContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ZIndex = 1000,
        Visible = false,
        Parent = self.Instance
    })

    function self:SpawnSnowflake()
        local flake = CreateInstance("Frame", {
            Name = "Snowflake",
            Size = UDim2.new(0, 2, 0, 2),
            Position = UDim2.new(math.random(), 0, 0, -4),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Parent = self.SnowContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = flake})
        table.insert(self.SnowFlakes, {
            Instance = flake,
            Speed = math.random(30, 70) / 100,
            Offset = math.random() * math.pi * 2
        })
    end

    function self:UpdateSnowflakes()
        for i = #self.SnowFlakes, 1, -1 do
            local data = self.SnowFlakes[i]
            local inst = data.Instance
            if not inst or not inst.Parent then
                table.remove(self.SnowFlakes, i)
                continue
            end
            local pos = inst.Position
            local newY = pos.Y.Offset + data.Speed * 2
            local newX = pos.X.Scale + math.sin(data.Offset + tick() * 2) * 0.005
            inst.Position = UDim2.new(newX, 0, 0, newY)
            if newY > self.Instance.AbsoluteSize.Y then
                inst:Destroy()
                table.remove(self.SnowFlakes, i)
            end
        end
    end

    function self:SpawnSnowflakes()
        if #self.SnowFlakes < 50 and math.random() < 0.1 then
            self:SpawnSnowflake()
        end
    end

    function self:EnableSnow(enabled)
        self.SnowEnabled = enabled
        self.SnowContainer.Visible = enabled
        if enabled then
            if not self.SnowConnection then
                self.SnowConnection = RunService.Heartbeat:Connect(function()
                    if self.SnowContainer.Visible and self.Instance.Visible then
                        self:UpdateSnowflakes()
                        self:SpawnSnowflakes()
                    end
                end)
            end
        else
            if self.SnowConnection then
                self.SnowConnection:Disconnect()
                self.SnowConnection = nil
            end
            for _, flake in ipairs(self.SnowFlakes) do
                if flake.Instance then
                    flake.Instance:Destroy()
                end
            end
            self.SnowFlakes = {}
        end
    end

    function self:SetVisible(visible)
        self.Instance.Visible = visible
        if self.BorderEffect then
            self.BorderEffect.Visible = visible
        end
    end

    function self:SetTitle(text)
        self.Title.Text = text
    end

    function self:SetWelcome(text)
        self.WelcomeLabel.Text = text
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
    local color = options.Color or WasUI.CurrentTheme.Accent
    local notificationId = HttpService:GenerateGUID(false)
    local frame = CreateInstance("Frame", {
        Name = "Notification_" .. notificationId,
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, WasUI.NotificationTop),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.2,
        ClipsDescendants = true,
        Visible = true,
        ZIndex = 9999,
        Parent = WasUI.NotificationGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = frame})
    local stroke = CreateInstance("UIStroke", {
        Color = color,
        Thickness = 1,
        Parent = frame
    })
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -10, 0, 14),
        Position = UDim2.new(0, 5, 0, 2),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = Color3.new(1,1,1),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame
    })
    local contentLabel = CreateInstance("TextLabel", {
        Name = "Content",
        Size = UDim2.new(1, -10, 0, 12),
        Position = UDim2.new(0, 5, 0, 16),
        BackgroundTransparency = 1,
        Text = content,
        TextColor3 = Color3.new(0.9,0.9,0.9),
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Left,
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
        local fadeOut = Tween(frame, {BackgroundTransparency = 1, Position = UDim2.new(1, WasUI.NotificationWidth + 20, 0, frame.Position.Y.Offset)}, 0.3)
        fadeOut.Completed:Connect(function()
            WasUI.ActiveNotifications[notificationId] = nil
            frame:Destroy()
            updateAllNotificationPositions()
        end)
    end)
end

function WasUI:CreateWindow(title, size, position)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "WasUI_Main"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = WasUI.DefaultDisplayOrder
    screenGui.Parent = game:GetService("CoreGui")
    local window = Panel:New(title, screenGui, size, position)
    RecordOriginalTransparency(window.Instance)
    return window
end

function WasUI:CreateButton(parent, text, onClick, size)
    return Button:New("Button", parent, text, onClick, size)
end

function WasUI:CreateToggle(parent, initialState, onToggle, featureName)
    return ToggleSwitch:New("Toggle", parent, initialState, onToggle, featureName)
end

function WasUI:CreateLabel(parent, text)
    return Label:New("Label", parent, text)
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