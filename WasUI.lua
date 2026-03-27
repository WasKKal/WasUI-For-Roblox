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
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "按钮",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = parent
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = self.Instance})
    
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
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(100, 100, 100),
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
            Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(100, 100, 100)}, 0.2)
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

WasUI.Notifications = {}
WasUI.NotificationQueue = {}
WasUI.ActiveNotifications = {}
WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 5
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250

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
        Name = "WasUI_Notification_" .. tick(),
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = playerGui
    })
    
    local notificationFrame = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.3,
        Parent = screenGui
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = notificationFrame})
    
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
    
    local notificationId = tostring(#WasUI.ActiveNotifications + 1)
    WasUI.ActiveNotifications[notificationId] = {
        Instance = notificationFrame,
        ScreenGui = screenGui,
        Height = WasUI.NotificationHeight
    }
    
    WasUI:UpdateNotificationPositions()
    
    local slideIn = Tween(notificationFrame, {
        Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, 20)
    }, 0.3)
    slideIn.Completed:Wait()
    
    wait(config.Duration)
    
    local fadeOut = Tween(notificationFrame, {BackgroundTransparency = 1}, 0.5)
    Tween(textLabel, {TextTransparency = 1}, 0.5)
    Tween(stroke, {Transparency = 1}, 0.5)
    
    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
        WasUI.ActiveNotifications[notificationId] = nil
        wait(0.2)
        WasUI:UpdateNotificationPositions()
        wait(0.3)
        WasUI:ProcessNotificationQueue()
    end)
end

function WasUI:UpdateNotificationPositions()
    local currentY = WasUI.NotificationTop
    local sortedNotifications = {}
    
    for id, notification in pairs(WasUI.ActiveNotifications) do
        table.insert(sortedNotifications, {id = id, notification = notification})
    end
    
    table.sort(sortedNotifications, function(a, b)
        return tonumber(a.id) < tonumber(b.id)
    end)
    
    for _, entry in ipairs(sortedNotifications) do
        local notification = entry.notification
        if notification.Instance and notification.Instance.Parent then
            Tween(notification.Instance, {
                Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, currentY)
            }, 0.3)
            currentY = currentY + notification.Height + WasUI.NotificationSpacing
        end
    end
end


local function getExecutor()
    if syn then
        return "Synapse X"
    elseif krnl then
        return "Krnl"
    elseif script_context and script_context.getexecutorname then
        return script_context.getexecutorname()
    elseif identifyexecutor then
        return identifyexecutor()
    elseif getexecutorname then
        return getexecutorname()
    elseif is_sirhurt_closure then
        return "Sirhurt"
    elseif pebc_execute then
        return "ProtoSmasher"
    elseif get_hidden_ui then
        return "Hydrogen"
    else
        return "未知执行器"
    end
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
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    
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
        CornerRadius = UDim.new(0, 10, 0, 0),
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
        Position = UDim2.new(0, 10, 0.15, 0),
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
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 68, 0.12, 0),
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
        Size = UDim2.new(0.6, 0, 0, 16),
        Position = UDim2.new(0, 68, 0.35, 0),
        BackgroundTransparency = 1,
        Text = "您的执行器为: " .. getExecutor(),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = self.AnnouncementBar
    })
    
    self.WelcomeLabel = CreateInstance("TextLabel", {
        Name = "WelcomeLabel",
        Size = UDim2.new(0.6, 0, 0, 14),
        Position = UDim2.new(0, 68, 0.55, 0),
        BackgroundTransparency = 1,
        Text = "欢迎使用WasUI",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
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
        Size = UDim2.new(1, 0, 0, 24),  -- 固定高度，与选项卡按钮一致
        Position = UDim2.new(0, 0, 0, 26 + announcementHeight),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(60, 60, 65),
        ScrollBarThickness = 6,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollingEnabled = true,
        ScrollingDirection = Enum.ScrollingDirection.X,
        Parent = self.Instance
    })
    
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, 0, 1, 0),
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
        Size = UDim2.new(1, -10, 1, -announcementHeight - 28 - 31),  -- 调整高度
        Position = UDim2.new(0, 5, 0, 26 + announcementHeight + 28),  -- 调整位置
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
        local xPos = math.random(0, 100) / 100
        local yPos = -size
        local snowflake = CreateInstance("Frame", {
            Name = "Snowflake",
            Size = UDim2.new(0, size, 0, size),
            Position = UDim2.new(xPos, 0, 0, yPos),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0,
            ZIndex = 101,
            Parent = self.SnowContainer
        })
        
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = snowflake})
        
        local speed = math.random(1, 3)
        local sway = math.random(-2, 2) * 0.1
        
        return {
            Instance = snowflake,
            Speed = speed,
            Sway = sway,
            XOffset = math.random(0, 100)
        }
    end
    
    function self:UpdateSnowflakes()
        for i, flake in ipairs(self.SnowFlakes) do
            if flake.Instance.Parent then
                local currentY = flake.Instance.Position.Y.Offset
                local currentX = flake.Instance.Position.X.Offset
                
                local newY = currentY + flake.Speed
                local swayAmount = math.sin(tick() + flake.XOffset) * 20
                local newX = currentX + flake.Sway + swayAmount * 0.1
                
                flake.Instance.Position = UDim2.new(0, newX, 0, newY)
                
                if newY > self.SnowContainer.AbsoluteSize.Y then
                    flake.Instance:Destroy()
                    table.remove(self.SnowFlakes, i)
                end
            end
        end
    end
    
    function self:SpawnSnowflakes()
        if #self.SnowFlakes < 30 and self.Instance.Visible then
            for i = 1, math.random(1, 3) do
                local flake = self:CreateSnowflake()
                table.insert(self.SnowFlakes, flake)
            end
        end
    end
    
    self.SnowConnection = RunService.Heartbeat:Connect(function()
        if self.SnowContainer.Visible and self.Instance.Visible then
            self:UpdateSnowflakes()
            self:SpawnSnowflakes()
        end
    end)
    
    return self
end

function Panel:AddTab(tabName)
    local tabButton = CreateInstance("TextButton", {
        Name = tabName .. "Tab",
        Size = UDim2.new(0, 70, 1, -2),  -- 预留1px上下边距
        BackgroundColor3 = Color3.fromRGB(45, 45, 50),
        BackgroundTransparency = 0.7,
        Text = tabName,
        TextColor3 = Color3.fromRGB(180, 180, 180),
        Font = Enum.Font.Gotham,
        TextSize = 13,
        AutoButtonColor = false,
        Parent = self.TabContainer
    })
    
    local tabCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 6), Parent = tabButton})
    local tabBorder = CreateInstance("UIStroke", {
        Color = Color3.fromRGB(60, 60, 65),
        Thickness = 1,
        Parent = tabButton
    })
    
    local underline = CreateInstance("Frame", {
        Name = "Underline",
        Size = UDim2.new(0, 0, 0, 3),
        Position = UDim2.new(0.5, 0, 1, -1),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(106, 17, 203),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = tabButton
    })
    
    CreateInstance("UICorner", {CornerRadius = UDim.new(0, 2), Parent = underline})
    
    local function animateUnderline(targetWidth, instant)
        if instant then
            underline.Size = UDim2.new(0, targetWidth, 0, 3)
            underline.BackgroundTransparency = 0
        else
            underline.Position = UDim2.new(0.5, 0, 1, -1)
            underline.Size = UDim2.new(0, 2, 0, 3)
            underline.BackgroundTransparency = 0
            
            wait(0.05)
            
            Tween(underline, {
                Size = UDim2.new(0, targetWidth, 0, 3)
            }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        end
    end
    
    local function hideUnderline()
        Tween(underline, {BackgroundTransparency = 1}, 0.2)
    end
    
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
    
    tabButton.Size = UDim2.new(0, 0, 1, -2)  -- 预留1px上下边距
    tabButton.Visible = false
    
    task.spawn(function()
        tabButton.Visible = true
        Tween(tabButton, {Size = UDim2.new(0, 70, 1, -2)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
    
    tabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(self.Tabs) do
            if tab.Button == tabButton then
                tabButton.BackgroundTransparency = 0
                tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                Tween(tabButton, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
                
                animateUnderline(tabButton.AbsoluteSize.X, false)
                
                Tween(tabButton, {Size = UDim2.new(0, 75, 1, -2)}, 0.15)
                task.wait(0.05)
                Tween(tabButton, {Size = UDim2.new(0, 70, 1, -2)}, 0.1)
                tab.Content.Visible = true
            else
                tab.Button.BackgroundTransparency = 0.7
                tab.Button.TextColor3 = Color3.fromRGB(180, 180, 180)
                Tween(tab.Button, {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}, 0.2)
                
                if tab.Button:FindFirstChild("Underline") then
                    local otherUnderline = tab.Button:FindFirstChild("Underline")
                    Tween(otherUnderline, {BackgroundTransparency = 1}, 0.2)
                end
                
                tab.Content.Visible = false
            end
        end
        self.ActiveTab = tabName
    end)
    
    local tab = {
        Name = tabName,
        Button = tabButton,
        Content = tabContent,
        Underline = underline,
        HideUnderline = hideUnderline
    }
    
    table.insert(self.Tabs, tab)
    self.TabContents[tabName] = tabContent
    
    if #self.Tabs == 1 then
        task.spawn(function()
            tabButton.BackgroundTransparency = 0
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabButton.BackgroundColor3 = WasUI.CurrentTheme.Primary
            tabContent.Visible = true
            
            animateUnderline(tabButton.AbsoluteSize.X, true)
            
            self.ActiveTab = tabName
        end)
    end
    
    return tabContent
end

-- 修复通知堆叠问题
WasUI.Notifications = {}
WasUI.NotificationQueue = {}
WasUI.ActiveNotifications = {}
WasUI.NotificationTop = 20
WasUI.NotificationSpacing = 5
WasUI.NotificationHeight = 30
WasUI.NotificationWidth = 250
WasUI.NotificationProcessing = false

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
        Name = "WasUI_Notification_" .. tick(),
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = playerGui
    })
    
    local notificationFrame = CreateInstance("Frame", {
        Name = "Notification",
        Size = UDim2.new(0, WasUI.NotificationWidth, 0, WasUI.NotificationHeight),
        Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, 20),
        BackgroundColor3 = Color3.fromRGB(30, 30, 35),
        BackgroundTransparency = 0.3,
        Parent = screenGui
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0.5, 0), Parent = notificationFrame})
    
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
    
    local function updateNotificationPositions()
        local currentY = WasUI.NotificationTop
        local sortedIds = {}
        
        for id, _ in pairs(WasUI.ActiveNotifications) do
            table.insert(sortedIds, id)
        end
        
        table.sort(sortedIds, function(a, b)
            return tonumber(a) < tonumber(b)
        end)
        
        for _, id in ipairs(sortedIds) do
            local notification = WasUI.ActiveNotifications[id]
            if notification and notification.Instance and notification.Instance.Parent then
                Tween(notification.Instance, {
                    Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, currentY)
                }, 0.3)
                currentY = currentY + notification.Height + WasUI.NotificationSpacing
            end
        end
    end
    
    updateNotificationPositions()
    
    local slideIn = Tween(notificationFrame, {
        Position = UDim2.new(1, -WasUI.NotificationWidth - 10, 0, WasUI.NotificationTop)
    }, 0.3)
    slideIn.Completed:Wait()
    
    wait(config.Duration)
    
    local fadeOut = Tween(notificationFrame, {BackgroundTransparency = 1}, 0.5)
    Tween(textLabel, {TextTransparency = 1}, 0.5)
    Tween(stroke, {Transparency = 1}, 0.5)
    
    fadeOut.Completed:Connect(function()
        screenGui:Destroy()
        WasUI.ActiveNotifications[notificationId] = nil
        
        wait(0.2)
        updateNotificationPositions()
        
        wait(0.3)
        WasUI:ProcessNotificationQueue()
    end)
end

-- 保留其他 Panel 方法不变...
function Panel:SetUsername(text)
    if self.Username then
        self.Username.Text = "玩家: " .. tostring(text)
    end
end

function Panel:SetWelcomeText(text)
    if self.WelcomeLabel then
        self.WelcomeLabel.Text = tostring(text)
    end
end

function Panel:SetVersionInfo(versionText)
    if self.VersionLabel then
        self.VersionLabel.Instance.Text = "版本: " .. tostring(versionText)
    end
end

function Panel:SetAuthorInfo(authorText)
    if self.AuthorLabel then
        self.AuthorLabel.Instance.Text = "作者: " .. tostring(authorText)
    end
end

function Panel:SetGithubInfo(githubText)
    if self.GithubLabel then
        self.GithubLabel.Instance.Text = "GitHub: " .. tostring(githubText)
    end
end

function Panel:AddTitle(text, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    
    if not targetContent then
        return nil
    end
    
    local titleLabel = CreateInstance("TextLabel", {
        Name = "Title_" .. text,
        Size = UDim2.new(1, 0, 0, 28),
        Position = UDim2.new(0, 0, 0, 0),
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

function Panel:AddCategory(title, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local category = Category:New("Category_" .. title, targetContent, title)
    return category
end

function Panel:AddButton(text, onClick, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local button = Button:New("Button_" .. text, targetContent, text, onClick)
    return button
end

function Panel:AddLabel(text, tabName)
    local targetContent = tabName and self.TabContents[tabName] or self.ContentArea
    local label = Label:New("Label_" .. text, targetContent, text)
    return label
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

function WasUI:ToggleSnowfall(enabled)
    if self.CurrentWindow and self.CurrentWindow.SnowContainer then
        self.CurrentWindow.SnowEnabled = enabled
        self.CurrentWindow.SnowContainer.Visible = enabled
        
        if enabled and not self.CurrentWindow.SnowConnection then
            self.CurrentWindow.SnowConnection = RunService.Heartbeat:Connect(function()
                if self.CurrentWindow.SnowContainer.Visible and self.CurrentWindow.Instance.Visible then
                    self.CurrentWindow:UpdateSnowflakes()
                    self.CurrentWindow:SpawnSnowflakes()
                end
            end)
        elseif not enabled and self.CurrentWindow.SnowConnection then
            self.CurrentWindow.SnowConnection:Disconnect()
            self.CurrentWindow.SnowConnection = nil
            
            for _, flake in ipairs(self.CurrentWindow.SnowFlakes) do
                if flake.Instance then
                    flake.Instance:Destroy()
                end
            end
            self.CurrentWindow.SnowFlakes = {}
        end
    end
end

function WasUI:IsSnowfallEnabled()
    if self.CurrentWindow and self.CurrentWindow.SnowContainer then
        return self.CurrentWindow.SnowEnabled
    end
    return false
end

return {
    CreateWindow = function(title, size, position, displayOrder)
        local window = WasUI:CreateWindow(title, size, position, displayOrder)
        WasUI.CurrentWindow = window
        return window
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
    RemoveRainbowText = WasUI.RemoveRainbowText,
    ToggleSnowfall = function(enabled)
        WasUI:ToggleSnowfall(enabled)
    end,
    IsSnowfallEnabled = function()
        return WasUI:IsSnowfallEnabled()
    end
}
