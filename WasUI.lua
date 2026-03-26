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

local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = Control.New(self, name, parent)
    
    local windowWidth = 400
    local windowHeight = 320
    
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
    
    local dotContainer = CreateInstance("Frame", {
        Name = "Dots",
        Size = UDim2.new(0, 45, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    local closeDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 0, 0.5, -4.5),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local minimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 15, 0.5, -4.5),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local maximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 9, 0, 9),
        Position = UDim2.new(0, 30, 0.5, -4.5),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    for _, dot in ipairs({closeDot, minimizeDot, maximizeDot}) do
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
    
    local isMinimized = false
    local originalSize = self.Instance.Size
    local originalPosition = self.Instance.Position
    
    local function MinimizeWindow()
        if isMinimized then return end
        
        Tween(self.Instance, {
            Size = UDim2.new(0, 60, 0, 26),
            Position = UDim2.new(
                originalPosition.X.Scale,
                originalPosition.X.Offset + originalSize.X.Offset - 60,
                originalPosition.Y.Scale,
                originalPosition.Y.Offset + originalSize.Y.Offset - 26
            )
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        isMinimized = true
    end
    
    local function RestoreWindow()
        if not isMinimized then return end
        
        Tween(self.Instance, {
            Size = originalSize,
            Position = originalPosition
        }, 0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        
        isMinimized = false
    end
    
    self.MinimizeButton.MouseButton1Click:Connect(MinimizeWindow)
    
    self.CloseButton.MouseButton1Click:Connect(function() 
        self:SetVisible(false) 
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
    
    self.ContentArea = CreateInstance("ScrollingFrame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -10, 1, -announcementHeight - 36),
        Position = UDim2.new(0, 5, 0, announcementHeight + 31),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Parent = self.Instance
    })
    
    local contentLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = self.ContentArea
    })
    
    contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        self.ContentArea.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y)
    end)
    
    local dragging = false
    local dragStart
    local startPos
    
    self.DraggableArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Instance.Position
        end
    end)
    
    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Instance.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            self.Instance.Position = UDim2.new(
                startPos.X.Scale, 
                startPos.X.Offset + delta.X, 
                startPos.Y.Scale, 
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    self.MinimizeWindow = MinimizeWindow
    self.RestoreWindow = RestoreWindow
    
    return self
end

function Panel:SetWelcomeText(text)
    self.WelcomeText.Text = tostring(text)
end

function Panel:SetExecutorText(text)
    self.ExecutorLabel.Text = "您的执行器为: " .. tostring(text)
end

function Panel:SetUsername(text)
    self.Username.Text = "玩家: " .. tostring(text)
end

function Panel:AddButton(text, onClick)
    local button = Button:New("Button_" .. text, self.ContentArea, text, onClick)
    button.Instance.Size = UDim2.new(0.9, 0, 0, 28)
    button.Instance.Position = UDim2.new(0.05, 0, 0, #self.ContentArea:GetChildren() * 34)
    return button
end

function Panel:AddLabel(text)
    local label = Label:New("Label_" .. text, self.ContentArea, text)
    label.Instance.Position = UDim2.new(0.05, 0, 0, #self.ContentArea:GetChildren() * 24)
    return label
end

function Panel:AddToggle(text, initialState, onToggle)
    local toggleContainer = CreateInstance("Frame", {
        Name = "ToggleContainer_" .. text,
        Size = UDim2.new(0.9, 0, 0, 28),
        Position = UDim2.new(0.05, 0, 0, #self.ContentArea:GetChildren() * 34),
        BackgroundTransparency = 1,
        Parent = self.ContentArea
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

function WasUI:CreateWindow(title, size, position, displayOrder)
    displayOrder = displayOrder or WasUI.DefaultDisplayOrder
    
    local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then
        playerGui = Instance.new("PlayerGui")
        playerGui.Parent = Players.LocalPlayer
    end
    
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
    SetDisplayOrder = WasUI.SetDisplayOrder
}
