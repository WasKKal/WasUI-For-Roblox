local WasUI = {}
WasUI.__index = WasUI

-- 服务引用
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- 创建主配置文件夹
local WasUI_Folder = Instance.new("Folder")
WasUI_Folder.Name = "WasUI_Config"
WasUI_Folder.Parent = ReplicatedStorage

-- 主题系统
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

-- 当前主题
WasUI.CurrentTheme = WasUI.Themes.Dark

-- 工具函数
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
    
    local tweenInfo = TweenInfo.new(
        duration or 0.3,
        easingStyle,
        easingDirection
    )
    
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- 控件基类
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

-- 按钮控件 (缩小比例)
local Button = setmetatable({}, {__index = Control})
Button.__index = Button

function Button:New(name, parent, text, onClick)
    local self = Control.New(self, name, parent)
    
    -- 创建按钮实例 (缩小尺寸)
    self.Instance = CreateInstance("TextButton", {
        Name = name,
        Size = UDim2.new(0, 160, 0, 36),
        Position = UDim2.new(0.5, -80, 0.5, -18),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        Text = text or "Button",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        AutoButtonColor = false,
        ClipsDescendants = true,
        Parent = parent
    })
    
    -- 圆角
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = self.Instance
    })
    
    -- 悬停效果
    self.Instance.MouseEnter:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.2)
    end)
    
    self.Instance.MouseLeave:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Primary}, 0.2)
    end)
    
    -- 点击效果
    self.Instance.MouseButton1Down:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Accent}, 0.1)
    end)
    
    self.Instance.MouseButton1Up:Connect(function()
        Tween(self.Instance, {BackgroundColor3 = WasUI.CurrentTheme.Secondary}, 0.1)
        if onClick then onClick() end
    end)
    
    return self
end

-- iOS风格开关
local ToggleSwitch = setmetatable({}, {__index = Control})
ToggleSwitch.__index = ToggleSwitch

function ToggleSwitch:New(name, parent, initialState, onToggle)
    local self = Control.New(self, name, parent)
    self.Toggled = initialState or false
    self.ToggleCallback = onToggle
    
    -- 开关背景
    self.Background = CreateInstance("Frame", {
        Name = name.."_BG",
        Size = UDim2.new(0, 44, 0, 24),
        Position = UDim2.new(0.5, -22, 0.5, -12),
        BackgroundColor3 = self.Toggled and WasUI.CurrentTheme.Success or Color3.fromRGB(120, 120, 120),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    local bgCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Background
    })
    
    -- 开关滑块
    self.Knob = CreateInstance("Frame", {
        Name = name.."_Knob",
        Size = UDim2.new(0, 20, 0, 20),
        Position = self.Toggled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = self.Background
    })
    
    local knobCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(1, 0),
        Parent = self.Knob
    })
    
    -- 点击事件
    self.Background.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Toggled = not self.Toggled
            
            if self.Toggled then
                Tween(self.Background, {BackgroundColor3 = WasUI.CurrentTheme.Success}, 0.2)
                Tween(self.Knob, {Position = UDim2.new(1, -22, 0, 2)}, 0.2)
            else
                Tween(self.Background, {BackgroundColor3 = Color3.fromRGB(120, 120, 120)}, 0.2)
                Tween(self.Knob, {Position = UDim2.new(0, 2, 0, 2)}, 0.2)
            end
            
            if self.ToggleCallback then
                self.ToggleCallback(self.Toggled)
            end
        end
    end)
    
    return self
end

-- 标签控件 (缩小比例)
local Label = setmetatable({}, {__index = Control})
Label.__index = Label

function Label:New(name, parent, text)
    local self = Control.New(self, name, parent)
    
    self.Instance = CreateInstance("TextLabel", {
        Name = name,
        Size = UDim2.new(0, 160, 0, 24),
        Position = UDim2.new(0.5, -80, 0.5, -12),
        BackgroundTransparency = 1,
        Text = text or "Label",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent
    })
    
    return self
end

-- 增强版面板容器 (MacOS风格)
local Panel = setmetatable({}, {__index = Control})
Panel.__index = Panel

function Panel:New(name, parent, size, position)
    local self = Control.New(self, name, parent)
    
    -- 主窗口
    self.Instance = CreateInstance("Frame", {
        Name = name,
        Size = size or UDim2.new(0, 500, 0, 400),
        Position = position or UDim2.new(0.5, -250, 0.5, -200),
        BackgroundColor3 = WasUI.CurrentTheme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = parent
    })
    
    -- 增强圆角
    local corner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 12),
        Parent = self.Instance
    })
    
    -- 标题栏 (MacOS风格)
    self.TitleBar = CreateInstance("Frame", {
        Name = "TitleBar",
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = WasUI.CurrentTheme.Primary,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    -- 标题文本
    self.Title = CreateInstance("TextLabel", {
        Name = "Title",
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 70, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamSemibold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar
    })
    
    -- MacOS操作点 (装饰用)
    local dotContainer = CreateInstance("Frame", {
        Name = "Dots",
        Size = UDim2.new(0, 60, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.TitleBar
    })
    
    local closeDot = CreateInstance("Frame", {
        Name = "Close",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 0, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 95, 87),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local minimizeDot = CreateInstance("Frame", {
        Name = "Minimize",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 20, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(255, 189, 46),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    local maximizeDot = CreateInstance("Frame", {
        Name = "Maximize",
        Size = UDim2.new(0, 12, 0, 12),
        Position = UDim2.new(0, 40, 0.5, -6),
        BackgroundColor3 = Color3.fromRGB(39, 201, 63),
        BorderSizePixel = 0,
        Parent = dotContainer
    })
    
    for _, dot in ipairs({closeDot, minimizeDot, maximizeDot}) do
        CreateInstance("UICorner", {
            CornerRadius = UDim.new(1, 0),
            Parent = dot
        })
    end
    
    -- 关闭按钮
    self.CloseButton = CreateInstance("TextButton", {
        Name = "CloseButton",
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -30, 0, 4),
        BackgroundTransparency = 1,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        Parent = self.TitleBar
    })
    
    self.CloseButton.MouseButton1Click:Connect(function()
        self:SetVisible(false)
    end)
    
    -- 公告栏
    self.AnnouncementBar = CreateInstance("Frame", {
        Name = "AnnouncementBar",
        Size = UDim2.new(1, 0, 0, 70),
        Position = UDim2.new(0, 0, 0, 32),
        BackgroundColor3 = WasUI.CurrentTheme.Announcement,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    -- 玩家头像
    local player = Players.LocalPlayer
    local headshot = player:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
    
    self.Avatar = CreateInstance("ImageLabel", {
        Name = "Avatar",
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(0, 12, 0.5, -24),
        BackgroundColor3 = Color3.fromRGB(200, 200, 200),
        Image = headshot,
        BorderSizePixel = 0,
        Parent = self.AnnouncementBar
    })
    
    local avatarCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = self.Avatar
    })
    
    -- 玩家名
    self.Username = CreateInstance("TextLabel", {
        Name = "Username",
        Size = UDim2.new(0, 200, 0, 24),
        Position = UDim2.new(0, 68, 0.3, 0),
        BackgroundTransparency = 1,
        Text = player.Name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.GothamSemibold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })
    
    -- 欢迎语
    self.WelcomeText = CreateInstance("TextLabel", {
        Name = "WelcomeText",
        Size = UDim2.new(0, 200, 0, 20),
        Position = UDim2.new(0, 68, 0.7, 0),
        BackgroundTransparency = 1,
        Text = "欢迎使用 WasUI 库",
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.AnnouncementBar
    })
    
    -- 选项卡区域
    self.TabBar = CreateInstance("Frame", {
        Name = "TabBar",
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 102),
        BackgroundColor3 = WasUI.CurrentTheme.TabInactive,
        BorderSizePixel = 0,
        Parent = self.Instance
    })
    
    self.TabContainer = CreateInstance("Frame", {
        Name = "TabContainer",
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
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
    
    -- 内容区域
    self.ContentArea = CreateInstance("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, 0, 1, -138),
        Position = UDim2.new(0, 0, 0, 138),
        BackgroundTransparency = 1,
        Parent = self.Instance
    })
    
    -- 页面容器
    self.PageContainer = CreateInstance("Frame", {
        Name = "PageContainer",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent = self.ContentArea
    })
    
    -- 调整大小手柄 (右下角弧形)
    self.ResizeHandle = CreateInstance("TextButton", {
        Name = "ResizeHandle",
        Size = UDim2.new(0, 20, 0, 20),
        Position = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = Color3.fromRGB(100, 100, 100),
        Text = "",
        AutoButtonColor = false,
        Parent = self.Instance
    })
    
    local resizeCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 10),
        Parent = self.ResizeHandle
    })
    
    -- 拖动功能
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
    
    -- 调整大小功能
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
            local newWidth = math.max(300, startSize.X.Offset + delta.X)
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

-- 添加选项卡
function Panel:AddTab(name, iconId)
    local tab = {}
    
    -- 创建选项卡按钮
    tab.Button = CreateInstance("TextButton", {
        Name = name.."Tab",
        Size = UDim2.new(0, 80, 1, 0),
        BackgroundColor3 = WasUI.CurrentTheme.TabInactive,
        Text = name,
        TextColor3 = WasUI.CurrentTheme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = self.TabContainer
    })
    
    local tabCorner = CreateInstance("UICorner", {
        CornerRadius = UDim.new(0, 6),
        Parent = tab.Button
    })
    
    -- 创建页面
    tab.Page = CreateInstance("ScrollingFrame", {
        Name = name.."Page",
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        Visible = false,
        Parent = self.PageContainer
    })
    
    local pageLayout = CreateInstance("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = tab.Page
    })
    
    -- 初始激活第一个选项卡
    if #self.TabContainer:GetChildren() == 2 then -- 第一个选项卡
        tab.Button.BackgroundColor3 = WasUI.CurrentTheme.TabActive
        tab.Page.Visible = true
    end
    
    -- 选项卡点击事件
    tab.Button.MouseButton1Click:Connect(function()
        -- 隐藏所有页面
        for _, child in ipairs(self.PageContainer:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
        
        -- 重置所有选项卡颜色
        for _, child in ipairs(self.TabContainer:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = WasUI.CurrentTheme.TabInactive
            end
        end
        
        -- 激活当前选项卡
        tab.Button.BackgroundColor3 = WasUI.CurrentTheme.TabActive
        tab.Page.Visible = true
    end)
    
    return tab
end

-- 向页面添加控件
function Panel:AddToPage(page, control)
    control.Parent = page
    control.Instance.LayoutOrder = #page:GetChildren()
    return control
end

-- 设置欢迎文本
function Panel:SetWelcomeText(text)
    self.WelcomeText.Text = text
end

-- 库主函数
function WasUI:CreateWindow(title, size, position)
    local screenGui = CreateInstance("ScreenGui", {
        Name = "WasUI_Window",
        ResetOnSpawn = false,
        Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    })
    
    local window = Panel:New(title, screenGui, size, position)
    return window
end

-- 配置管理
function WasUI:SaveConfig(key, data)
    local configValue = WasUI_Folder:FindFirstChild(key)
    if not configValue then
        configValue = CreateInstance("StringValue", {
            Name = key,
            Parent = WasUI_Folder
        })
    end
    configValue.Value = tostring(data)
end

function WasUI:LoadConfig(key, default)
    local configValue = WasUI_Folder:FindFirstChild(key)
    if configValue and configValue.Value ~= "" then
        return configValue.Value
    end
    return default
end

-- 返回公共接口
return {
    CreateWindow = function(title, size, position)
        return WasUI:CreateWindow(title, size, position)
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
    end
}
