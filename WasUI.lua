local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if _G.WasUILoaded then
    warn("WasUI 已加载，跳过重复加载")
    return _G.WasUIModule
end
_G.WasUILoaded = true

WasUI.DefaultDisplayOrder = 10

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

WasUI.Themes = {
    Default = {
        Primary = Color3.fromRGB(106, 17, 203),
        Secondary = Color3.fromRGB(135, 45, 225),
        Background = Color3.fromRGB(240, 245, 250),
        Text = Color3.fromRGB(44, 62, 80),
        Accent = Color3.fromRGB(231, 76, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        Section = Color3.fromRGB(230, 235, 240),
        Input = Color3.fromRGB(250, 250, 252),
        TabBorder = Color3.fromRGB(220, 220, 220)
    },
    Dark = {
        Primary = Color3.fromRGB(106, 17, 203),
        Secondary = Color3.fromRGB(135, 45, 225),
        Background = Color3.fromRGB(28, 28, 34),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123),
        Section = Color3.fromRGB(35, 35, 40),
        Input = Color3.fromRGB(45, 45, 50),
        TabBorder = Color3.fromRGB(40, 40, 40),
        TabButton = Color3.fromRGB(0, 0, 0)
    },
    Light = {
        Primary = Color3.fromRGB(76, 175, 80),
        Secondary = Color3.fromRGB(102, 187, 106),
        Background = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(60, 64, 67),
        Accent = Color3.fromRGB(219, 68, 55),
        Success = Color3.fromRGB(15, 157, 88),
        Warning = Color3.fromRGB(249, 171, 0),
        Error = Color3.fromRGB(219, 68, 55),
        Section = Color3.fromRGB(248, 249, 250),
        Input = Color3.fromRGB(241, 243, 244),
        TabBorder = Color3.fromRGB(220, 220, 220),
        TabButton = Color3.fromRGB(255, 255, 255)
    }
}
WasUI.CurrentTheme = WasUI.Themes.Dark

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        instance[prop] = value
    end
    return instance
end

-- 修复核心语法错误：TweenService用冒号调用Create
local function Tween(instance, properties, duration, easingStyle, easingDirection)
    easingStyle = easingStyle or Enum.EasingStyle.Quad
    easingDirection = easingDirection or Enum.EasingDirection.Out
    local tweenInfo = TweenInfo.new(duration or 0.3, easingStyle, easingDirection)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
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
function Button:New(name, parent, text, onClick)
    local self = Control.New(self, name, parent)
    self.Instance = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "按钮",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent
    })
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Instance})
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
    return self
end

local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch
function ToggleSwitch:New(name, parent, initialState, onToggle)
    local self = Control.New(self, name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
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
    self.Background.MouseButton1Click:Connect(function()
        self.Toggled = not self.Toggled
        if self.Toggled then
            Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.2)
        else
            Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(200, 200, 200)}, 0.2)
            Tween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
        end
        if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
    end)
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
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    return self
end

local Category = setmetatable({}, {__index = Control})
Category.__index = Category
function Category:New(name, parent, title)
    local self = Control.New(self, name, parent)
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 32),
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
        Font = Enum.Font.GothamBold,
        TextSize = 18,
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
    return self
end

local Dropdown = setmetatable({}, {__index = Control})
Dropdown.__index = Dropdown
function Dropdown:New(name, parent, title, options, defaultValue, callback)
    local self = Control.New(self, name, parent)
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
        BorderColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 1,
        Text = defaultValue or "选择...",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextTruncate = Enum.TextTruncate.AtEnd,
        AutoButtonColor = false,
        ZIndex = 11,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.DropdownButton})
    self.Options = options or {}
    self.SelectedValue = defaultValue
    self.Callback = callback
    self.IsOpen = false
    self.OptionsContainer = CreateInstance("Frame", {
        Name = "OptionsContainer",
        Size = UDim2.new(0.3, 0, 0, 0),
        Position = UDim2.new(0.7, 0, 0, 24),
        BackgroundColor3 = WasUI.CurrentTheme.Input,
        BorderColor3 = Color3.fromRGB(200, 200, 200),
        BorderSizePixel = 1,
        ClipsDescendants = true,
        Visible = false,
        ZIndex = 999,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.OptionsContainer})
    self.OptionsListLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 1),
        Parent = self.OptionsContainer
    })
    for i, option in ipairs(self.Options) do
        local optionButton = CreateInstance("TextButton", {
            Name = "Option_" .. option,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundColor3 = WasUI.CurrentTheme.Input,
            BorderSizePixel = 0,
            Text = option,
            TextColor3 = WasUI.CurrentTheme.Text,
            Font = Enum.Font.Gotham,
            TextSize = 12,
            AutoButtonColor = false,
            LayoutOrder = i,
            ZIndex = 1000,
            Parent = self.OptionsContainer
        })
        optionButton.MouseEnter:Connect(function()
            Tween(optionButton, {BackgroundColor3 = Color3.fromRGB(240, 240, 245)}, 0.2)
        end)
        optionButton.MouseLeave:Connect(function()
            Tween(optionButton, {BackgroundColor3 = WasUI.CurrentTheme.Input}, 0.2)
        end)
        optionButton.MouseButton1Click:Connect(function()
            self.SelectedValue = option
            self.DropdownButton.Text = option
            self:CloseDropdown()
            if self.Callback then
                self.Callback(option)
            end
        end)
    end
    self.DropdownButton.MouseButton1Click:Connect(function()
        if self.IsOpen then
            self:CloseDropdown()
        else
            self:OpenDropdown()
        end
    end)
    self.Instance = self.Container
    return self
end

function Dropdown:OpenDropdown()
    if self.IsOpen or #self.Options == 0 then return end
    self.OptionsContainer.Visible = true
    local maxHeight = math.min(#self.Options * 25, 150)
    Tween(self.OptionsContainer, {Size = UDim2.new(0.3, 0, 0, maxHeight)}, 0.3)
    self.IsOpen = true
    local function closeIfClickedOutside(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = input.Position
            local absolutePos = self.OptionsContainer.AbsolutePosition
            local absoluteSize = self.OptionsContainer.AbsoluteSize
            local buttonPos = self.DropdownButton.AbsolutePosition
            local buttonSize = self.DropdownButton.AbsoluteSize
            local inButton = mousePos.X >= buttonPos.X and mousePos.X <= buttonPos.X + buttonSize.X and
                             mousePos.Y >= buttonPos.Y and mousePos.Y <= buttonPos.Y + buttonSize.Y
            local inOptions = mousePos.X >= absolutePos.X and mousePos.X <= absolutePos.X + absoluteSize.X and
                              mousePos.Y >= absolutePos.Y and mousePos.Y <= absolutePos.Y + absoluteSize.Y
            if not inButton and not inOptions then
                self:CloseDropdown()
            end
        end
    end
    self.CloseConnection = UserInputService.InputBegan:Connect(closeIfClickedOutside)
end

function Dropdown:CloseDropdown()
    if not self.IsOpen then return end
    Tween(self.OptionsContainer, {Size = UDim2.new(0.3, 0, 0, 0)}, 0.2)
    task.wait(0.2)
    self.OptionsContainer.Visible = false
    self.IsOpen = false
    if self.CloseConnection then
        self.CloseConnection:Disconnect()
        self.CloseConnection = nil
    end
end

function Dropdown:GetValue()
    return self.SelectedValue
end

function Dropdown:SetValue(value)
    if table.find(self.Options, value) then
        self.SelectedValue = value
        self.DropdownButton.Text = value
    end
end

local Slider = setmetatable({}, {__index = Control})
Slider.__index = Slider
function Slider:New(name, parent, title, min, max, defaultValue, callback)
    local self = Control.New(self, name, parent)
    self.Container = CreateInstance("Frame", {
        Name = name,
        Size = UDim2.new(1, 0, 0, 50),
        BackgroundTransparency = 1,
        Parent = parent
    })
    self.TitleLabel = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(0.7, 0, 0, 20),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = title or "滑块",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.Container
    })
    self.ValueLabel = CreateInstance("TextLabel", {
        Name = "ValueLabel",
        Size = UDim2.new(0.3, 0, 0, 20),
        Position = UDim2.new(0.7, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(defaultValue or min),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = self.Container
    })
    -- 加宽滑动条上下宽度（从6→8），保持圆角
    self.SliderTrack = CreateInstance("TextButton", {
        Name = "SliderTrack",
        Size = UDim2.new(1, 0, 0, 8),
        Position = UDim2.new(0, 0, 0, 30),
        BackgroundColor3 = Color3.fromRGB(220, 220, 220),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = self.Container
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderTrack})
    self.SliderFill = CreateInstance("Frame", {
        Name = "SliderFill",
        Size = UDim2.new(0, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.SliderTrack
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.SliderFill})
    self.MinValue = min or 0
    self.MaxValue = max or 100
    self.CurrentValue = defaultValue or min or 0
    self.Callback = callback
    self.IsDragging = false
    local function calculateValueFromX(x)
        local trackWidth = self.SliderTrack.AbsoluteSize.X
        local relativeX = math.clamp(x, 0, trackWidth)
        local percentage = relativeX / trackWidth
        local value = self.MinValue + (self.MaxValue - self.MinValue) * percentage
        return math.floor(value)
    end
    local function updateSlider(value)
        self.CurrentValue = math.clamp(value, self.MinValue, self.MaxValue)
        local percentage = (self.CurrentValue - self.MinValue) / (self.MaxValue - self.MinValue)
        self.SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
        self.ValueLabel.Text = tostring(self.CurrentValue)
        if self.Callback then
            self.Callback(self.CurrentValue)
        end
    end
    self.SliderTrack.MouseButton1Down:Connect(function()
        self.IsDragging = true
        local mousePos = UserInputService:GetMouseLocation()
        local trackPos = self.SliderTrack.AbsolutePosition
        local relativeX = mousePos.X - trackPos.X
        local newValue = calculateValueFromX(relativeX)
        updateSlider(newValue)
    end)
    UserInputService.InputChanged:Connect(function(input)
        if self.IsDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local mousePos = input.Position
            local trackPos = self.SliderTrack.AbsolutePosition
            local relativeX = mousePos.X - trackPos.X
            local newValue = calculateValueFromX(relativeX)
            updateSlider(newValue)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.IsDragging = false
        end
    end)
    self.Instance = self.Container
    updateSlider(self.CurrentValue)
    return self
end

function Slider:GetValue()
    return self.CurrentValue
end

function Slider:SetValue(value)
    value = math.clamp(value, self.MinValue, self.MaxValue)
    self.CurrentValue = value
    local percentage = (value - self.MinValue) / (self.MaxValue - self.MinValue)
    self.SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
    self.ValueLabel.Text = tostring(value)
end

WasUI.RainbowTexts = {}
local rainbowConnections = {}

local function CreateRainbowText(text, position)
    local screenGui = CreateInstance("ScreenGui", {
        Name = "RainbowText_" .. text,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        Parent = game:GetService("CoreGui")
    })
    local textLabel = CreateInstance("TextLabel", {
        Name = "RainbowText",
        Size = UDim2.new(0, 0, 0, 0),
        Position = position or UDim2.new(1, -10, 0, 10),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Color3.fromRGB(255, 0, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextStrokeTransparency = 0.5,
        TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
        Parent = screenGui
    })
    Tween(textLabel, {Size = UDim2.new(0, 200, 0, 30)}, 0.3)
    local rainbowSpeed = 4
    local time = 0
    local connection = RunService.Heartbeat:Connect(function(deltaTime)
        time = time + deltaTime * rainbowSpeed
        local r = (math.sin(time) + 1) / 2
        local g = (math.sin(time + math.pi/3) + 1) / 2
        local b = (math.sin(time + 2*math.pi/3) + 1) / 2
        textLabel.TextColor3 = Color3.new(r, g, b)
    end)
    WasUI.RainbowTexts[text] = screenGui
    rainbowConnections[text] = connection
    return screenGui
end

local function RemoveRainbowText(text)
    if WasUI.RainbowTexts[text] then
        WasUI.RainbowTexts[text]:Destroy()
        WasUI.RainbowTexts[text] = nil
    end
    if rainbowConnections[text] then
        rainbowConnections[text]:Disconnect()
        rainbowConnections[text] = nil
    end
end

WasUI.Notifications = {}
WasUI.ActiveNotifications = {}
WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 8
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250

function WasUI:Notify(options)
    local config = {
        Content = options.Content or "通知",
        Duration = options.Duration or 3,
        Type = options.Type or "Info"
    }
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Notification_" .. tick(),
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = playerGui
    })
    local notificationFrame = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, 10, 0, 20),
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
    WasUI.ActiveNotifications[notificationId] = notificationData
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
    updateAllNotificationPositions()
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

local function getExecutor()
    if syn then
        return "Synapse X"
    elseif krnl then
        return "Krnl"
    elseif identifyexecutor then
        return identifyexecutor()
    else
        return "未知执行器"
    end
end

local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = setmetatable({}, Panel)
    local windowWidth = 380
    local windowHeight = 350
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = size or UDim2.new(0, windowWidth, 0, windowHeight),
        Position = position or UDim2.new(0.5, -windowWidth/2, 0.5, -windowHeight/2),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})

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
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    -- 加强标题栏外围圆角（顶部12px），内部（底部）改为直角
    CreateInstance("UICorner", {
        TopLeftRadius = UDim.new(0, 12),
        TopRightRadius = UDim.new(0, 12),
        BottomLeftRadius = UDim.new(0, 0),
        BottomRightRadius = UDim.new(0, 0),
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
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 70, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })

    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 36, 1, 0),
        Position = UDim2.new(0, 10.5, 0, 1.3),
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
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.DotContainer
    })

    self.MinimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 14, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        ZIndex = 3,
        Parent = self.DotContainer
    })

    self.MaximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 28, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
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
            self.RestoreFromDots()
        else
            self.MinimizeToDots()
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
                self.RestoreFromDots()
            else
                self.MinimizeToDots()
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
        self:SetVisible(false) 
    end)

    local dragging = false
    local dragStart
    local startPos
    local function startDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Instance.Position
        end
    end
    local function stopDragging(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
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
    UserInputService.InputEnded:Connect(stopDragging)

    local announcementHeight = 80
    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, announcementHeight),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BackgroundTransparency = 0.1,
        BorderSizePixel = 0,
        Parent = self.Instance
    })

    local player = Players.LocalPlayer
    local headshot = Players:GetUserThumbnailAsync(
        player.UserId, 
        Enum.ThumbnailType.HeadShot, 
        Enum.ThumbnailSize.Size60x60
    )
    self.Avatar = CreateInstance("ImageButton", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.15, 0),
        BackgroundColor3 = Color3.fromRGB(240, 240, 245),
        Image = headshot,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Parent = self.AnnouncementBar
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    local avatarStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(220, 220, 225),
        Thickness = 1,
        Parent = self.Avatar
    })

    self.Avatar.MouseButton1Down:Connect(function()
        Tween(self.Avatar, {Size = UDim2.new(0, 44, 0, 44)}, 0.1)
    end)
    self.Avatar.MouseButton1Up:Connect(function()
        Tween(self.Avatar, {Size = UDim2.new(0, 48, 0, 48)}, 0.1)
    end)

    -- 三行文字向左对齐，贴紧头像右侧（留8px，XOffset从68→66）
    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 66, 0.12, 0),
        BackgroundTransparency = 1,
        Text = "玩家: " .. player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })

    self.ExecutorLabel = CreateInstance("TextLabel", {
        Name = "ExecutorLabel",

        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 66, 0.35, 0),
        BackgroundTransparency = 1,
        Text = "执行器: "..getExecutor(),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })

    self.WelcomeLabel = CreateInstance("TextLabel", {
        Name = "WelcomeLabel",
        Size = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 66, 0.55, 0),
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

    self.TabBar = CreateInstance("ScrollingFrame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 26 + announcementHeight),
        BackgroundColor3 = WasUI.CurrentTheme.Section,
        BorderSizePixel = 0,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
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
        Position = UDim2.new(0, -3, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TabBar
    })

    self.TabLayout = CreateInstance("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = self.TabContainer
    })
    self.TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.TabBar.CanvasSize = UDim2.new(0, self.TabLayout.AbsoluteContentSize.X, 0, 0)
    end)

    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -10, 1, -announcementHeight - 28 - 31),
        Position = UDim2.new(0, 5, 0, 26 + announcementHeight + 28),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
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

    return self
end

function Panel:SetWelcomeText(text)
    if self.WelcomeLabel then
        self.WelcomeLabel.Text = text
    end
end

function Panel:AddTab(tabName)
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
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})
    local underline = CreateInstance("Frame", {
        Name = "Underline",
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0.5, 0, 1, 0),
        AnchorPoint = Vector2.new(0.5, 0),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BackgroundTransparency = 1,
        Parent = tabButton
    })
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 1), Parent = underline})
    local tabContent = CreateInstance("ScrollingFrame", {
        Name = tabName .. "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.ContentArea
    })
    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = tabContent
    })
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabContent.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
    end)
    tabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(self.Tabs) do
            tab.Button.BackgroundTransparency = 0.7
            tab.Button.TextColor3 = Color3.fromRGB(100, 100, 105)
            Tween(tab.Button, {BackgroundColor3 = WasUI.CurrentTheme.TabButton}, 0.2)
            if tab.Underline then
                Tween(tab.Underline, {BackgroundTransparency = 1}, 0.2)
            end
            tab.Content.Visible = false
        end
        tabButton.BackgroundTransparency = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        Tween(tabButton, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
        Tween(underline, {Size = UDim2.new(0.8, 0, 0, 2), BackgroundTransparency = 0}, 0.2)
        tabContent.Visible = true
        self.ActiveTab = tabName
    end)
    local tab = {
        Name = tabName,
        Button = tabButton,
        Content = tabContent,
        Underline = underline
    }
    table.insert(self.Tabs, tab)
    self.TabContents[tabName] = tabContent
    if #self.Tabs == 1 then
        tabButton.BackgroundTransparency = 0
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabButton.BackgroundColor3 = WasUI.CurrentTheme.Primary
        underline.Size = UDim2.new(0.8, 0, 0, 2)
        underline.BackgroundTransparency = 0
        tabContent.Visible = true
    end
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
    local toggleSwitch = ToggleSwitch:New("Toggle", toggleContainer, initialState, onToggle)
    return toggleSwitch
end

function Panel:AddDropdown(title, options, defaultValue, callback, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local dropdown = Dropdown:New("Dropdown_" .. title, targetContent, title, options, defaultValue, callback)
    return dropdown
end

function Panel:AddSlider(title, min, max, defaultValue, callback, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local slider = Slider:New("Slider_" .. title, targetContent, title, min, max, defaultValue, callback)
    return slider
end

function Panel:MinimizeWindow()
    self.MinimizeToDots()
end

function Panel:RestoreWindow()
    self.RestoreFromDots()
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
    local window = Panel:New(title, screenGui, size, position)
    self.CurrentWindow = window
    return window
end

function WasUI:SetTheme(themeName)
    if self.Themes[themeName] then
        self.CurrentTheme = self.Themes[themeName]
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

_G.WasUIModule = WasUI
return WasUI
