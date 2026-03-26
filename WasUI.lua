local WasUI = {}
WasUI.__index = WasUI

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

WasUI.DefaultDisplayOrder = 10

local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

WasUI.Themes = {
    Default = {
        Primary = Color3.fromRGB(41, 128, 185),
        Secondary = Color3.fromRGB(52, 152, 219),
        Background = Color3.fromRGB(240, 245, 250),
        Text = Color3.fromRGB(44, 62, 80),
        Accent = Color3.fromRGB(231, 76, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60)
    },
    Dark = {
        Primary = Color3.fromRGB(30, 30, 36),
        Secondary = Color3.fromRGB(40, 40, 46),
        Background = Color3.fromRGB(28, 28, 34),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123)
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
        Size = UDim2.new(0, 120, 0, 28),
        Position = UDim2.new(0.5, -60, 0.5, -14),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "按钮",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = self.Instance})
    
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
    
    self.Background = CreateInstance("Frame", {
        Name = name .. "_BG",
        Size = UDim2.new(0, 36, 0, 18),
        Position = UDim2.new(0.5, -18, 0.5, -9),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(100, 100, 100),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    local bgCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Background})
    
    self.Knob = CreateInstance("Frame", {
        Name = name .. "_Knob",
        Size = UDim2.new(0, 16, 0, 16),
        Position = self.Toggled and UDim2.new(1, -18, 0, 1) or UDim2.new(0, 1, 0, 1),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = self.Background
    })
    
    local knobCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Knob})
    
    self.Background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Toggled = not self.Toggled
            
            if self.Toggled then
                Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                Tween(self.Knob, {Position = UDim2.new(1, -18, 0, 1)}, 0.2)
            else
                Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}, 0.2)
                Tween(self.Knob, {Position = UDim2.new(0, 1, 0, 1)}, 0.2)
            end
            
            if self.ToggleCallback then self.ToggleCallback(self.Toggled) end
        end
    end)
    
    return self
end

local Label = setmetatable({}, {__index = Control})
Label.__index = Label

function Label:New(name, parent, text)
    local self = Control.New(self, name, parent)
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(0.9, 0, 0, 20),
        Position = UDim2.new(0.05, 0, 0, 0),
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

-- 彩虹文字系统
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
    
    local rainbowSpeed = 2
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

-- 通知系统
WasUI.Notifications = {}
WasUI.NotificationQueue = {}

function WasUI:Notify(options)
    local config = {
        Content = options.Content or "通知",
        Duration = options.Duration or 3,
        Type = options.Type or "Info"
    }
    
    table.insert(WasUI.NotificationQueue, config)
    
    if not WasUI.NotificationProcessing then
        WasUI.NotificationProcessing = true
        WasUI:ProcessNotificationQueue()
    end
end

function WasUI:ProcessNotificationQueue()
    if #WasUI.NotificationQueue == 0 then
        WasUI.NotificationProcessing = false
        return
    end
    
    local config = table.remove(WasUI.NotificationQueue, 1)
    
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Notification",
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = playerGui
    })
    
    local notificationFrame = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, 300, 0, 40),
        Position = UDim2.new(0.5, -150, 0, -50),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.3,
        Parent = screenGui
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = notificationFrame})
    
    local stroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(60, 60, 65),
        Thickness = 2,
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
        TextSize = 14,
        TextWrapped = true,
        Parent = notificationFrame
    })
    
    local slideDown = Tween(notificationFrame, {Position = UDim2.new(0.5, -150, 0, 20)}, 0.3)
    slideDown.Completed:Wait()
    
    wait(config.Duration)
    
    local fadeOut = Tween(notificationFrame, {BackgroundTransparency = 1}, 0.5)
    Tween(textLabel, {TextTransparency = 1}, 0.5)
    Tween(stroke, {Transparency = 1}, 0.5)
    
    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
        wait(0.5)
        WasUI:ProcessNotificationQueue()
    end)
end

local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = setmetatable({}, Panel)
    
    local windowWidth = 400
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
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Instance})
    
    local stroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(60, 60, 65),
        Thickness = 1,
        Parent = self.Instance
    })
    
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    local titleCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8, 0, 0),
        Parent = self.TitleBar
    })
    
    self.DraggableArea = CreateInstance("TextButton", {
        Name = "DraggableArea",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Parent = self.TitleBar
    })
    
    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -100, 1, 0),
        Position = UDim2.new(0, 50, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    self.DotContainer = CreateInstance("Frame", {
        Name = "DotContainer",
        Size = UDim2.new(0, 50, 1, 0),  -- 增加宽度使左右对称
        Position = UDim2.new(0.5, -25, 0, 0),  -- 居中
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    self.CloseDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 0, 0.5, -4.5),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        Parent = self.DotContainer
    })
    
    self.MinimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 20, 0.5, -4.5),  -- 调整间距
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        Parent = self.DotContainer
    })
    
    self.MaximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 40, 0.5, -4.5),  -- 调整间距
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BorderSizePixel = 0,
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
    self.OriginalPosition = self.Instance.Position
    self.MinimizedSize = UDim2.new(0, 60, 0, 26)
    self.MinimizedPosition = self.Instance.Position
    
    self.MinimizeToDots = function()
        if self.IsMinimized then return end
        
        self.MinimizedPosition = self.Instance.Position
        self.OriginalSize = self.Instance.Size
        
        Tween(self.Instance, {
            Size = self.MinimizedSize,
            Position = self.MinimizedPosition
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        self.Title.Visible = false
        self.AnnouncementBar.Visible = false
        self.TabBar.Visible = false
        self.ContentArea.Visible = false
        self.CloseButton.Visible = false
        self.MinimizeButton.Visible = false
        self.DraggableArea.Visible = false
        
        self.DotContainer.Visible = true
        self.IsMinimized = true
    end
    
    self.RestoreFromDots = function()
        if not self.IsMinimized then return end
        
        Tween(self.Instance, {
            Size = self.OriginalSize,
            Position = self.MinimizedPosition
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        self.Title.Visible = true
        self.AnnouncementBar.Visible = true
        self.TabBar.Visible = true
        self.ContentArea.Visible = true
        self.CloseButton.Visible = true
        self.MinimizeButton.Visible = true
        self.DraggableArea.Visible = true
        
        self.DotContainer.Visible = true
        self.IsMinimized = false
    end
    
    self.MinimizeButton.MouseButton1Click:Connect(self.MinimizeToDots)
    self.MinimizeDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.IsMinimized then
                self.RestoreFromDots()
            else
                self.MinimizeToDots()
            end
        end
    end)
    
    self.CloseButton.MouseButton1Click:Connect(function() 
        self:SetVisible(false) 
    end)
    
    self.CloseDot.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:SetVisible(false)
        end
    end)
    
    local announcementHeight = 80
    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, announcementHeight),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
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
    
    self.Avatar = CreateInstance("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 10, 0.2, 0),
        BackgroundColor3 = Color3.fromRGB(60, 60, 65),
        Image = headshot,
        BorderSizePixel = 0,
        Parent = self.AnnouncementBar
    })
    
    local avatarCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.Avatar})
    
    local avatarStroke = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(100, 100, 110),
        Thickness = 1,
        Parent = self.Avatar
    })
    
    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(0.6, 0, 0, 20),
        Position = UDim2.new(0, 68, 0.15, 0),
        BackgroundTransparency = 1,
        Text = "玩家: " .. player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.AnnouncementBar
    })
    
    self.ExecutorLabel = CreateInstance("TextLabel", {
        Name = "ExecutorLabel",
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 68, 0.45, 0),
        BackgroundTransparency = 1,
        Text = "您的执行器为: Synapse X",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.AnnouncementBar
    })
    
    self.WelcomeText = CreateInstance("TextLabel", {
        Name = "WelcomeText",
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 68, 0.75, 0),
        BackgroundTransparency = 1,
        Text = "欢迎使用 WasUI 库",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.AnnouncementBar
    })
    
    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 26 + announcementHeight),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(60, 60, 65),
        Parent = self.Instance
    })
    
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -10, 1, 0),
        Position = UDim2.new(0, 5, 0, 0),
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
    
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -10, 1, -announcementHeight - 32 - 31),
        Position = UDim2.new(0, 5, 0, 26 + announcementHeight + 32),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.Instance
    })
    
    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = self.ContentArea
    })
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
    end)
    
    self.Tabs = {}
    self.ActiveTab = nil
    self.TabContents = {}
    
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
    self.TitleBar.InputBegan:Connect(startDragging)
    self.DotContainer.InputBegan:Connect(startDragging)
    
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
            
            if self.IsMinimized then
                self.MinimizedPosition = newPosition
            else
                self.OriginalPosition = newPosition
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(stopDragging)
    
    return self
end

function Panel:SetWelcomeText(text)
    if self.WelcomeText then
        self.WelcomeText.Text = tostring(text)
    end
end

function Panel:SetExecutorText(text)
    if self.ExecutorLabel then
        self.ExecutorLabel.Text = "您的执行器为: " .. tostring(text)
    end
end

function Panel:SetUsername(text)
    if self.Username then
        self.Username.Text = "玩家: " .. tostring(text)
    end
end

function Panel:AddTab(tabName)
    local tabButton = CreateInstance("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(0, 70, 1, -4),
        Position = UDim2.new(0, 0, 0, 2),
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        BackgroundTransparency = 0.7,
        Text = tabName,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        Font = Enum.Font.Gotham,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = self.TabContainer
    })
    
    local tabCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 4), Parent = tabButton})
    
    local tabBorder = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(60, 60, 65),
        Thickness = 1,
        Parent = tabButton
    })
    
    local tabContent = CreateInstance("Frame", {
        Name = tabName .. "Content",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = self.ContentArea
    })
    
    tabButton.Size = UDim2.new(0, 0, 1, -4)
    tabButton.Visible = false
    
    task.spawn(function()
        tabButton.Visible = true
        Tween(tabButton, {Size = UDim2.new(0, 70, 1, -4)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    
    tabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(self.Tabs) do
            if tab.Button == tabButton then
                tabButton.BackgroundTransparency = 0
                tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                Tween(tabButton, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
                Tween(tabButton, {Size = UDim2.new(0, 75, 1, -4)}, 0.15)
                task.wait(0.05)
                Tween(tabButton, {Size = UDim2.new(0, 70, 1, -4)}, 0.1)
                tab.Content.Visible = true
            else
                tab.Button.BackgroundTransparency = 0.7
                tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
                Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.2)
                tab.Content.Visible = false
            end
        end
        self.ActiveTab = tabName
    end)
    
    local tab = {
        Name = tabName,
        Button = tabButton,
        Content = tabContent
    }
    
    table.insert(self.Tabs, tab)
    self.TabContents[tabName] = tabContent
    
    if #self.Tabs == 1 then
        task.spawn(function()
            tabButton.BackgroundTransparency = 0
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabButton.BackgroundColor3 = WasUI.CurrentTheme.Primary
            tabContent.Visible = true
            self.ActiveTab = tabName
        end)
    end
    
    return tabContent
end

function Panel:AddButton(text, onClick, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local button = Button:New("Button_" .. text, targetContent, text, onClick)
    button.Instance.Size = UDim2.new(0.9, 0, 0, 28)
    button.Instance.Position = UDim2.new(0.05, 0, 0, #targetContent:GetChildren() * 34)
    return button
end

function Panel:AddLabel(text, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local label = Label:New("Label_" .. text, targetContent, text)
    label.Instance.Position = UDim2.new(0.05, 0, 0, #targetContent:GetChildren() * 24)
    return label
end

function Panel:AddToggle(text, initialState, onToggle, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    
    local toggleContainer = CreateInstance("Frame", {
        Name = "ToggleContainer_" .. text,
        Size = UDim2.new(0.9, 0, 0, 28),
        Position = UDim2.new(0.05, 0, 0, #targetContent:GetChildren() * 34),
        BackgroundTransparency = 1,
        Parent = targetContent
    })
    
    local toggleLabel = CreateInstance("TextLabel", {
        Name = "ToggleLabel",
        Size = UDim2.new(0.7, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        Parent = toggleContainer
    })
    
    local toggleSwitch = ToggleSwitch:New("Toggle", toggleContainer, initialState, onToggle)
    toggleSwitch.Background.Position = UDim2.new(1, -40, 0.5, -9)
    
    return toggleSwitch
end

function Panel:MinimizeWindow()
    if self.MinimizeToDots then
        self.MinimizeToDots()
    end
end

function Panel:RestoreWindow()
    if self.RestoreFromDots then
        self.RestoreFromDots()
    end
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
    
    local window = Panel:New(tostring(title), screenGui, size, position)
    
    return window
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

return {
    CreateWindow = function(title, size, position, displayOrder)
        return WasUI:CreateWindow(title, size, position, displayOrder)
    end,
    SetTheme = function(themeName)
        if WasUI.Themes[themeName] then
            WasUI.CurrentTheme = WasUI.Themes[themeName]
        end
    end,
    SaveConfig = function(key, data)
        WasUI:SaveConfig(key, data)
    end,
    LoadConfig = function(key, default)
        return WasUI:LoadConfig(key, default)
    end,
    SetDisplayOrder = WasUI.SetDisplayOrder,
    Notify = function(options)
        WasUI:Notify(options)
    end,
    CreateRainbowText = WasUI.CreateRainbowText,
    RemoveRainbowText = WasUI.RemoveRainbowText
}
