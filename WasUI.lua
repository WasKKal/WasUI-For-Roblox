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

-- 全局容器
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
    local self = Control.New(self, name, parent)
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
    local self = Control.New(self, name, parent)
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
    local self = Control.New(self, name, parent)
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
    local self = Control.New(self, name, parent)
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

-- 下拉菜单（支持多选、滚动、防超出屏幕）
local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback, multiSelect)
    local self = Control.New(self, name, parent)
    self.MultiSelect = multiSelect or false
    self.Options = options or {}
    -- 类型安全初始化，复制传入的表以避免只读错误
    if self.MultiSelect then
        if type(defaultValue) == "table" then
            self.SelectedValues = {}
            for _, v in ipairs(defaultValue) do
                table.insert(self.SelectedValues, v)
            end
        elseif defaultValue ~= nil then
            self.SelectedValues = {defaultValue}
        else
            self.SelectedValues = {}
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

    -- 创建容器
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
        Text = self:GetDisplayText(),
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

    -- 下拉菜单容器（带滚动）
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

    -- 选项列表布局
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

    -- 创建选项按钮
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
                local index = table.find(self.SelectedValues, option)
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

    -- 更新容器尺寸并防止超出屏幕
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

    -- 点击外部关闭
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

    table.insert(WasUI.Objects, {Object = self.Container, Type = "Dropdown"})
    table.insert(WasUI.Objects, {Object = self.DropdownButton, Type = "DropdownButton"})
    return self
end

-- 辅助函数：查找表元素
function table.find(t, value)
    for i, v in ipairs(t) do
        if v == value then return i end
    end
    return nil
end

local Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider
function Slider:New(name, parent, title, min, max, defaultValue, callback)
    local self = Control.New(self, name, parent)
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
        Text = "欢迎使用WasUI",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })
    
    self.SnowContainer = CreateInstance("Frame", {
        Name = "SnowContainer",
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 100,
        Parent = self.Instance
    })
    
    -- 选项卡栏（左侧无空白）
    self.TabBar = CreateInstance("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 26 + announcementHeight),
        BackgroundColor3 = Color3.fromRGB(50, 50, 55),
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.Instance
    })
    
    CreateInstance("Frame", {
        Name = "TabTopBorder",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = WasUI.CurrentTheme.TabBorder,
        BorderSizePixel = 0,
        Parent = self.TabBar
    })
    CreateInstance("Frame", {
        Name = "TabBottomBorder",
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = WasUI.CurrentTheme.TabBorder,
        BorderSizePixel = 0,
        Parent = self.TabBar
    })
    
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TabBar
    })
    
    self.TabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 0),
        Parent = self.TabContainer
    })
    
    self.TabHighlight = CreateInstance("Frame", {
        Name = "TabHighlight",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.7,
        BorderSizePixel = 0,
        ZIndex = 5,
        Parent = self.TabContainer
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.TabHighlight})
    
    local function updateHighlightPosition()
        if not self.ActiveTab then return end
        for _, tab in pairs(self.Tabs) do
            if tab.Name == self.ActiveTab and tab.Button then
                local targetPos = tab.Button.AbsolutePosition.X - self.TabContainer.AbsolutePosition.X
                local targetWidth = tab.Button.AbsoluteSize.X
                Tween(self.TabHighlight, {Position = UDim2.new(0, targetPos, 0, 0), Size = UDim2.new(0, targetWidth, 1, 0)}, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
                break
            end
        end
    end
    
    self.TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabBar.CanvasSize = UDim2.new(0, self.TabLayout.AbsoluteContentSize.X, 0, 0)
        updateHighlightPosition()
    end)
    self.TabContainer:GetPropertyChangedSignal("AbsolutePosition"):Connect(updateHighlightPosition)
    
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -20, 1, -announcementHeight - 28 - 31),
        Position = UDim2.new(0, 5, 0, 26 + announcementHeight + 28),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.Instance
    })
    
    self.Tabs = {}
    self.ActiveTab = nil
    self.TabContents = {}
    self.SnowFlakes = {}
    self.SnowEnabled = true
    
    function self:CreateSnowflake()
        local size = math.random(3, 8)
        local snowflake = CreateInstance("Frame", {
            Name = "Snowflake",
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(math.random(), 0, -size, 0),
            BackgroundColor3 = Color3.new(1,1,1),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = self.SnowContainer
        })
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowflake})
        return {
            Instance = snowflake,
            Speed = math.random(1,3),
            Offset = math.random()*math.pi*2
        }
    end
    
    function self:SpawnSnowflakes()
        if #self.SnowFlakes < 30 and self.Instance.Visible then
            table.insert(self.SnowFlakes, self:CreateSnowflake())
        end
    end
    
    function self:UpdateSnowflakes()
        for i = #self.SnowFlakes, 1, -1 do
            local flake = self.SnowFlakes[i]
            if not flake.Instance or not flake.Instance.Parent then
                table.remove(self.SnowFlakes, i)
                continue
            end
            local pos = flake.Instance.Position
            flake.Instance.Position = UDim2.new(pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset + flake.Speed)
            if flake.Instance.Position.Y.Offset > self.SnowContainer.AbsoluteSize.Y then
                flake.Instance:Destroy()
                table.remove(self.SnowFlakes, i)
            end
        end
    end
    
    self.SnowConnection = RunService.Heartbeat:Connect(function()
        if self.SnowContainer.Visible then
            self:SpawnSnowflakes()
            self:UpdateSnowflakes()
        end
    end)
    
    table.insert(WasUI.Objects, {Object = self.Instance, Type = "Window"})
    table.insert(WasUI.Objects, {Object = self.TitleBar, Type = "TitleBar"})
    table.insert(WasUI.Objects, {Object = self.AnnouncementBar, Type = "AnnouncementBar"})
    table.insert(WasUI.Objects, {Object = self.TabBar, Type = "TabBar"})
    table.insert(WasUI.Objects, {Object = self.ContentArea, Type = "ContentArea"})
    return self
end

function Panel:SetWelcomeText(text)
    if self.WelcomeLabel then
        self.WelcomeLabel.Text = text
    end
end

function Panel:AddTab(tabName)
    assert(self and self.TabContainer and self.Tabs and self.TabContents, "AddTab 必须使用 : 调用，格式为 window:AddTab(\"标签名\")")
    local tabButtonBg = WasUI.CurrentTheme.TabButton
    local tabButton = CreateInstance("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundColor3 = tabButtonBg,
        BackgroundTransparency = 0.7,
        Text = tabName,
        TextColor3 = Color3.fromRGB(100, 100, 105),
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.TabContainer
    })
    local tabContent = CreateInstance("ScrollingFrame", {
        Name = tabName .. "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = self.ContentArea
    })
    CreateInstance("UIPadding", {
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 4),
        Parent = tabContent
    })
    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 2),
        Parent = tabContent
    })
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
    end)
    
    local function switchTab()
        for _, tab in pairs(self.Tabs) do
            if tab.Button ~= tabButton and tab.Content.Visible then
                tab.Content.Transparency = 1
                tab.Content.Visible = false
                tab.Button.BackgroundTransparency = 0.7
                tab.Button.TextColor3 = Color3.fromRGB(100, 100, 105)
                tab.Button.BackgroundColor3 = WasUI.CurrentTheme.TabButton
            end
        end
        tabContent.Visible = true
        tabContent.Transparency = 1
        tabButton.BackgroundTransparency = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundColor3 = WasUI.CurrentTheme.Primary
        Tween(tabContent, {Transparency = 0}, 0.2, Enum.EasingStyle.Cubic)
        self.ActiveTab = tabName
        local targetPos = tabButton.AbsolutePosition.X - self.TabContainer.AbsolutePosition.X
        local targetWidth = tabButton.AbsoluteSize.X
        Tween(self.TabHighlight, {Position = UDim2.new(0, targetPos, 0, 0), Size = UDim2.new(0, targetWidth, 1, 0)}, 0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
    end
    
    tabButton.MouseButton1Click:Connect(switchTab)
    local tab = {
        Name = tabName,
        Button = tabButton,
        Content = tabContent
    }
    table.insert(self.Tabs, tab)
    self.TabContents[tabName] = tabContent
    if #self.Tabs == 1 then
        tabButton.BackgroundTransparency = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundColor3 = WasUI.CurrentTheme.Primary
        tabContent.Visible = true
        local targetPos = tabButton.AbsolutePosition.X - self.TabContainer.AbsolutePosition.X
        local targetWidth = tabButton.AbsoluteSize.X
        self.TabHighlight.Position = UDim2.new(0, targetPos, 0, 0)
        self.TabHighlight.Size = UDim2.new(0, targetWidth, 1, 0)
        self.ActiveTab = tabName
    end
    table.insert(WasUI.Objects, {Object = tabButton, Type = "TabButton"})
    return tabContent
end

function Panel:AddTitle(text, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title_" .. text,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = targetContent
    })
    table.insert(WasUI.Objects, {Object = titleLabel, Type = "Label"})
    return titleLabel
end

function Panel:AddLabel(text, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local label = Label:New("Label_" .. text, targetContent, text)
    return label
end

function Panel:AddButton(text, onClick, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local button = Button:New("Button_" .. text, targetContent, text, onClick)
    return button
end

function Panel:AddToggle(text, initialState, onToggle, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local toggleContainer = CreateInstance("Frame", {
        Name = "ToggleContainer_" .. text,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = targetContent
    })
    local toggleLabel = CreateInstance("TextLabel", {
        Name = "ToggleLabel",
        Size = UDim2.new(0.7, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = toggleContainer
    })
    local toggleSwitch = ToggleSwitch:New("Toggle", toggleContainer, initialState, onToggle, text)
    table.insert(WasUI.Objects, {Object = toggleContainer, Type = "ToggleContainer"})
    table.insert(WasUI.Objects, {Object = toggleLabel, Type = "Label"})
    return toggleSwitch
end

function Panel:AddDropdown(title, options, defaultValue, callback, tabName, multiSelect)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local dropdown = Dropdown:New("Dropdown_" .. title, targetContent, title, options, defaultValue, callback, multiSelect)
    return dropdown
end

function Panel:AddSlider(title, min, max, defaultValue, callback, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local slider = Slider:New("Slider_" .. title, targetContent, title, min, max, defaultValue, callback)
    return slider
end

function Panel:MinimizeWindow()
    self:MinimizeToDots()
end

function Panel:RestoreWindow()
    self:RestoreFromDots()
end

function WasUI:CreateWindow(title, size, position, displayOrder)
    displayOrder = displayOrder or WasUI.DefaultDisplayOrder
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Window",
        ResetOnSpawn = false,
        DisplayOrder = displayOrder,
        Parent = playerGui
    })
    local window = Panel:New(title, screenGui, size or UDim2.new(0, 420, 0, 350), position)
    self.CurrentWindow = window
    return window
end

function WasUI:SetDialogTitle(title)
    WasUI.DialogTitle = title or "你要关闭WasUI吗?"
end

function WasUI:SetTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = self.Themes[themeName]
        for _, objData in ipairs(WasUI.Objects) do
            local obj = objData.Object
            local objType = objData.Type
            if obj and obj.Parent then
                if objType == "Button" then
                    Tween(obj, {BackgroundColor3 = self.CurrentTheme.Primary}, 0.2)
                elseif objType == "TabButton" then
                    Tween(obj, {BackgroundColor3 = self.CurrentTheme.TabButton}, 0.2)
                elseif objType == "Label" then
                    obj.TextColor3 = self.CurrentTheme.Text
                elseif objType == "Toggle" then
                    local toggleObj = obj.Parent.Parent
                    if toggleObj.Toggled ~= nil then
                        obj.BackgroundColor3 = toggleObj.Toggled and self.CurrentTheme.Success or Color3.fromRGB(200, 200, 200)
                    end
                elseif objType == "SliderFill" then
                    obj.BackgroundColor3 = self.CurrentTheme.Primary
                elseif objType == "DropdownButton" then
                    obj.BackgroundColor3 = self.CurrentTheme.Input
                    obj.TextColor3 = self.CurrentTheme.Text
                end
            end
        end
    end
end

function WasUI:SaveConfig(key, data)
    local keyStr = tostring(key)
    local configValue = WasUI_Folder:FindFirstChild(keyStr)
    if not configValue then
        configValue = CreateInstance("StringValue", {
            Name = keyStr,
            Parent = WasUI_Folder
        })
    end
    configValue.Value = tostring(data)
end

function WasUI:LoadConfig(key, default)
    local keyStr = tostring(key)
    local configValue = WasUI_Folder:FindFirstChild(keyStr)
    if configValue and configValue.Value ~= "" then
        return configValue.Value
    end
    return default
end

function WasUI.SetDisplayOrder(order)
    WasUI.DefaultDisplayOrder = order
end

function WasUI.CreateRainbowText(text, position)
    return CreateRainbowText(text, position)
end

function WasUI.RemoveRainbowText(text)
    RemoveRainbowText(text)
end

function WasUI:ToggleSnowfall(enabled)
    if self.CurrentWindow and self.CurrentWindow.SnowContainer then
        self.CurrentWindow.SnowEnabled = enabled
        self.CurrentWindow.SnowContainer.Visible = enabled
    end
end

function WasUI:IsSnowfallEnabled()
    if self.CurrentWindow then
        return self.CurrentWindow.SnowEnabled
    end
    return false
end

function WasUI:RefreshTheme()
    self:SetTheme("Dark")
end

function WasUI:Notify(options)
    local config = {
        Content = options.Content or "通知",
        Duration = options.Duration or 3,
        Type = options.Type or "Info"
    }

    local screenGui = WasUI.NotificationGui
    if not screenGui or not screenGui.Parent then
        screenGui = Instance.new("ScreenGui")
        screenGui.Name = "WasUI_Notifications"
        screenGui.ResetOnSpawn = false
        screenGui.DisplayOrder = 999
        screenGui.Parent = game:GetService("CoreGui")
        WasUI.NotificationGui = screenGui
    end

    local notificationFrame = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.3,
        Parent = screenGui
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = notificationFrame})
    local stroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(60, 60, 65),
        Thickness = 1,
        Parent = notificationFrame
    })

    local textLabel = CreateInstance("TextLabel", {
        Name = "Content",
        Size = UDim2.new(0.9, 0, 0.8, 0),
        Position = UDim2.new(0.05, 0, 0.1, 0),
        BackgroundTransparency = 1,
        Text = config.Content,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextWrapped = true,
        Parent = notificationFrame
    })

    local notificationId = tostring(tick())
    local notificationData = {
        Instance = notificationFrame,
        ScreenGui = screenGui,
        Height = WasUI.NotificationHeight
    }

    local function calculatePosition(index)
        return (index - 1) * (WasUI.NotificationHeight + WasUI.NotificationSpacing) + WasUI.NotificationTop
    end

    local function updateAllNotificationPositions()
        local sortedIds = {}
        for id, _ in pairs(WasUI.ActiveNotifications) do
            table.insert(sortedIds, id)
        end
        table.sort(sortedIds, function(a, b)
            return tonumber(a) < tonumber(b)
        end)

        for i, id in ipairs(sortedIds) do
            local notification = WasUI.ActiveNotifications[id]
            if notification and notification.Instance and notification.Instance.Parent then
                local targetY = calculatePosition(i)
                Tween(notification.Instance, {
                    Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)
                }, 0.3)
            end
        end
    end

    local index = #WasUI.ActiveNotifications + 1
    local targetY = calculatePosition(index)
    notificationFrame.Position = UDim2.new(1, 10, 0, targetY)
    WasUI.ActiveNotifications[notificationId] = notificationData
    updateAllNotificationPositions()

    Tween(notificationFrame, {Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, targetY)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.wait(config.Duration)

    local fadeOut = Tween(notificationFrame, {BackgroundTransparency = 1}, 0.5)
    Tween(textLabel, {TextTransparency = 1}, 0.5)
    Tween(stroke, {Transparency = 1}, 0.5)

    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
        WasUI.ActiveNotifications[notificationId] = nil
        task.wait(0.1)
        updateAllNotificationPositions()
    end)
end

_G.WasUIModule = WasUI
return WasUI