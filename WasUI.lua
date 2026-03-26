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
        Background = Color3.fromRGB(236, 240, 241),
        Text = Color3.fromRGB(44, 62, 80),
        Accent = Color3.fromRGB(231, 76, 60),
        Success = Color3.fromRGB(46, 204, 113),
        Warning = Color3.fromRGB(241, 196, 15),
        Error = Color3.fromRGB(231, 76, 60),
        TabActive = Color3.fromRGB(189, 195, 199),
        TabInactive = Color3.fromRGB(236, 240, 241),
        Announcement = Color3.fromRGB(245, 245, 245)
    },
    Dark = {
        Primary = Color3.fromRGB(30, 30, 36),
        Secondary = Color3.fromRGB(40, 40, 46),
        Background = Color3.fromRGB(25, 25, 30),
        Text = Color3.fromRGB(220, 220, 220),
        Accent = Color3.fromRGB(97, 175, 239),
        Success = Color3.fromRGB(83, 227, 136),
        Warning = Color3.fromRGB(255, 213, 92),
        Error = Color3.fromRGB(255, 123, 123),
        TabActive = Color3.fromRGB(55, 55, 65),
        TabInactive = Color3.fromRGB(35, 35, 45),
        Announcement = Color3.fromRGB(40, 40, 50)
    }
}

WasUI.CurrentTheme = WasUI.Themes.Dark

local function CreateInstance(className, properties)
    local instance = Instance.new(className)
    for prop, value in pairs(properties) do
        if prop == "Name" and type(value) == "table" then
            instance.Name = tostring(value)
        else
            instance[prop] = value
        end
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
        Name = tostring(name),
        Size = UDim2.new(0, 140, 0, 30),
        Position = UDim2.new(0.5, -70, 0.5, -15),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "Button",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 12,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = parent
    })
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = self.Instance})
    self.Instance.MouseEnter:Connect(function() Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2) end)
    self.Instance.MouseLeave:Connect(function() Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2) end)
    self.Instance.MouseButton1Down:Connect(function() Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1) end)
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
        Name = tostring(name) .. "_BG",
        Size = UDim2.new(0, 40, 0, 20),
        Position = UDim2.new(0.5, -20, 0.5, -10),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    local bgCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = self.Background})
    self.Knob = CreateInstance("Frame", {
        Name = tostring(name) .. "_Knob",
        Size = UDim2.new(0, 18, 0, 18),
        Position = self.Toggled and UDim2.new(1, -20, 0, 1) or UDim2.new(0, 1, 0, 1),
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
                Tween(self.Knob, {Position = UDim2.new(1, -20, 0, 1)}, 0.2)
            else
                Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
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
        Name = tostring(name),
        Size = UDim2.new(0, 140, 0, 20),
        Position = UDim2.new(0.5, -70, 0.5, -10),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    return self
end

local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = Control.New(self, name, parent)
    
    local windowWidth = 450
    local windowHeight = 380
    local scaleFactor = 0.9
    
    self.Instance = CreateInstance("Frame", {
        Name = tostring(name),
        Size = size or UDim2.new(0, windowWidth, 0, windowHeight),
        Position = position or UDim2.new(0.5, -windowWidth/2, 0.5, -windowHeight/2),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    local corner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Instance})
    
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -70, 1, 0),
        Position = UDim2.new(0, 60, 0, 0),
        BackgroundTransparency = 1,
        Text = tostring(name),
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    local dotContainer = CreateInstance("Frame", {
        Name = "Dots",
        Size = UDim2.new(0, 50, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    local closeDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 0, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local minimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 18, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local maximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0, 36, 0.5, -5),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    for _, dot in ipairs({closeDot, minimizeDot, maximizeDot}) do
        CreateInstance("UICorner", {CornerRadius = UDim.new(1, 0), Parent = dot})
    end
    
    self.CloseButton = CreateInstance("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -26, 0, 3),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = self.TitleBar
    })
    
    self.CloseButton.MouseButton1Click:Connect(function() 
        self:SetVisible(false) 
    end)
    
    local announcementHeight = 80
    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, announcementHeight),
        Position = UDim2.new(0, 0, 0, 28),
        BackgroundColor3 = WasUI.CurrentTheme.Announcement,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    local player = Players.LocalPlayer
    local headshot = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    
    self.Avatar = CreateInstance("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.new(0, 56, 0, 56),
        Position = UDim2.new(0, 12, 0.5, -28),
        BackgroundColor3 = Color3.fromRGB(180, 180, 180),
        Image = headshot,
        BorderSizePixel = 0,
        Parent = self.AnnouncementBar
    })
    
    local avatarCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 10), Parent = self.Avatar})
    
    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(1, -80, 0, 28),
        Position = UDim2.new(0, 76, 0.2, 0),
        BackgroundTransparency = 1,
        Text = player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })
    
    self.WelcomeText = CreateInstance("TextLabel", {
        Name = "WelcomeText",
        Size = UDim2.new(1, -80, 0, 24),
        Position = UDim2.new(0, 76, 0.6, 0),
        BackgroundTransparency = 1,
        Text = "欢迎使用 WasUI 库",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })
    
    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 28 + announcementHeight),
        BackgroundColor3 = WasUI.CurrentTheme.TabInactive,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
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
    
    local contentStart = 28 + announcementHeight + 32
    self.ContentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -contentStart),
        Position = UDim2.new(0, 0, 0, contentStart),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })
    
    self.PageContainer = CreateInstance("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.ContentArea
    })
    
    self.ResizeHandle = CreateInstance("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(1, -16, 1, -16),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Instance
    })
    
    local resizeCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 8), Parent = self.ResizeHandle})
    
    local dragging = false
    local dragStart
    local startPos
    
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
    
    local resizing = false
    local resizeStart
    local startSize
    
    self.ResizeHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = true
            resizeStart = input.Position
            startSize = self.Instance.Size
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newWidth = math.max(280, startSize.X.Offset + delta.X)
            local newHeight = math.max(200, startSize.Y.Offset + delta.Y)
            
            self.Instance.Size = UDim2.new(0, newWidth, 0, newHeight)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    
    return self
end

function Panel:AddTab(name, iconId)
    local tab = {}
    tab.Button = CreateInstance("TextButton", {
        Name = tostring(name) .. "Tab",
        Size = UDim2.new(0, 70, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.TabInactive,
        Text = tostring(name),
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        AutoButtonColor = false,
        Parent = self.TabContainer
    })
    
    local tabCorner = CreateInstance("UICorner", {CornerRadius = UDim.new(0, 5), Parent = tab.Button})
    
    tab.Page = CreateInstance("ScrollingFrame", {
        Name = tostring(name) .. "Page",
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.PageContainer
    })
    
    local pageLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = tab.Page
    })
    
    if #self.TabContainer:GetChildren() == 2 then
        tab.Button.BackgroundColor3 = WasUI.CurrentTheme.TabActive
        tab.Page.Visible = true
    end
    
    tab.Button.MouseButton1Click:Connect(function()
        for _, child in ipairs(self.PageContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
        
        for _, child in ipairs(self.TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = WasUI.CurrentTheme.TabInactive
            end
        end
        
        tab.Button.BackgroundColor3 = WasUI.CurrentTheme.TabActive
        tab.Page.Visible = true
    end)
    
    return tab
end

function Panel:AddToPage(page, control)
    control.Parent = page
    control.Instance.LayoutOrder = #page:GetChildren()
    return control
end

function Panel:SetWelcomeText(text)
    self.WelcomeText.Text = tostring(text)
end

function WasUI:CreateWindow(title, size, position, displayOrder)
    displayOrder = displayOrder or WasUI.DefaultDisplayOrder
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Window",
        ResetOnSpawn = false,
        DisplayOrder = displayOrder,
        Parent = game:GetService("CoreGui")
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
    CreateButton = function(parent, text, onClick)
        return Button:New("Button", parent, text, onClick)
    end,
    CreateLabel = function(parent, text)
        return Label:New("Label", parent, text)
    end,
    CreateToggle = function(parent, initialState, onToggle)
        return ToggleSwitch:New("Toggle", parent, initialState, onToggle)
    end,
    SaveConfig = function(key, data)
        WasUI:SaveConfig(key, data)
    end,
    LoadConfig = function(key, default)
        return WasUI:LoadConfig(key, default)
    end,
    SetTheme = function(themeName)
        if WasUI.Themes[themeName] then
            WasUI.CurrentTheme = WasUI.Themes[themeName]
        end
    end,
    SetDisplayOrder = WasUI.SetDisplayOrder
}
