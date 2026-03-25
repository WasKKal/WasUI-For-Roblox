-- 加载 WasUI 库（请确保 URL 正确）
local WasUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/WasKKal/-/main/WasUI.lua"))()

-- 初始化配置管理器（必须在使用配置前调用）
WasUI:InitConfig("WasUI_Demo")

-- 创建主窗口
local win = WasUI:CreateWindow({
    Title = "WasUI 完整示例 + Roblox 服务",
    Size = UDim2.new(0, 640, 0, 560),
    Background = Color3.fromRGB(35, 35, 45),
    Draggable = true,
})

-- ==================== 选项卡 1：基础控件 ====================
local basicTab = win:Tab("基础控件")

basicTab:Paragraph({ Text = "按钮", Desc = "点击触发回调，长按生成快捷键" })
basicTab:Button({ Text = "普通按钮", Callback = function() print("[基础] 按钮点击") end })
basicTab:Button({ Text = "另一个按钮", Callback = function() print("[基础] 另一个按钮点击") end })
basicTab:Divider()

basicTab:Paragraph({ Text = "开关 (iOS风格)", Desc = "开启时屏幕上方显示状态提示" })
basicTab:Toggle({ Text = "功能开关", Value = false, Callback = function(v) print("[基础] 开关状态:", v) end })
basicTab:Toggle({ Text = "默认开启", Value = true, Callback = function(v) print("[基础] 默认开关状态:", v) end })
basicTab:Divider()

basicTab:Paragraph({ Text = "滑块", Desc = "支持整数和浮点数步长" })
basicTab:Slider({ Text = "音量", Min = 0, Max = 100, Default = 50, Callback = function(v) print("[基础] 音量:", v) end })
basicTab:Slider({ Text = "亮度", Min = 0, Max = 1, Default = 0.5, Step = 0.05, Callback = function(v) print("[基础] 亮度:", v) end })
basicTab:Space(10)

-- ==================== 选项卡 2：高级控件 ====================
local advancedTab = win:Tab("高级控件")

advancedTab:Paragraph({ Text = "输入框", Desc = "单行文本，失去焦点触发回调" })
advancedTab:Input({ Text = "用户名", Value = "Guest", Placeholder = "输入用户名", Callback = function(t) print("[高级] 用户名:", t) end })
advancedTab:Input({ Text = "密码", Value = "", Placeholder = "密码", Callback = function(t) print("[高级] 密码已输入") end })
advancedTab:Divider()

advancedTab:Paragraph({ Text = "下拉菜单", Desc = "单击展开选项列表" })
advancedTab:Dropdown({ Text = "颜色选择", Values = {"红色","绿色","蓝色"}, Default = "红色", Callback = function(s) print("[高级] 选择颜色:", s) end })
advancedTab:Dropdown({ Text = "数字选项", Values = {"1","2","3","4","5"}, Default = "3", Callback = function(s) print("[高级] 选择数字:", s) end })
advancedTab:Divider()

advancedTab:Paragraph({ Text = "颜色选择器", Desc = "点击按钮打开颜色选择对话框" })
advancedTab:Colorpicker({ Text = "主题色", Default = Color3.fromRGB(0,120,215), Callback = function(c) print("[高级] 颜色:", c) end })
advancedTab:Colorpicker({ Text = "背景色", Default = Color3.fromRGB(30,30,30), Callback = function(c) print("[高级] 背景色:", c) end })
advancedTab:Space(10)

-- ==================== 选项卡 3：布局演示 ====================
local layoutTab = win:Tab("布局演示")

layoutTab:Paragraph({ Text = "左右分栏布局", Desc = "两列独立滚动，互不干扰" })

local cols = layoutTab:CreateTwoColumn()

-- 左侧栏
cols.left:Button({ Text = "左侧按钮 1", Callback = function() print("[布局] 左侧按钮 1") end })
cols.left:Toggle({ Text = "左侧开关", Value = false, Callback = function(v) print("[布局] 左侧开关:", v) end })
cols.left:Slider({ Text = "左侧滑块", Min = 0, Max = 100, Default = 30, Callback = function(v) print("[布局] 左侧滑块:", v) end })
cols.left:Input({ Text = "左侧输入", Placeholder = "输入内容", Callback = function(t) print("[布局] 左侧输入:", t) end })
cols.left:Dropdown({ Text = "左侧下拉", Values = {"选项1","选项2"}, Default = "选项1", Callback = function(s) print("[布局] 左侧下拉:", s) end })

-- 右侧栏
cols.right:Button({ Text = "右侧按钮 1", Callback = function() print("[布局] 右侧按钮 1") end })
cols.right:Toggle({ Text = "右侧开关", Value = true, Callback = function(v) print("[布局] 右侧开关:", v) end })
cols.right:Slider({ Text = "右侧滑块", Min = 0, Max = 100, Default = 70, Callback = function(v) print("[布局] 右侧滑块:", v) end })
cols.right:Input({ Text = "右侧输入", Placeholder = "右侧输入", Callback = function(t) print("[布局] 右侧输入:", t) end })
cols.right:Dropdown({ Text = "右侧下拉", Values = {"A","B","C"}, Default = "B", Callback = function(s) print("[布局] 右侧下拉:", s) end })

layoutTab:Space(10)

-- ==================== 选项卡 4：杂项控件 ====================
local miscTab = win:Tab("杂项控件")

miscTab:Paragraph({ Text = "段落文本控件", Desc = "可以显示带描述的文本内容。" })
miscTab:Divider()
miscTab:Paragraph({ Text = "空段落演示", Desc = nil })
miscTab:Space(10)

miscTab:Button({ Text = "显示全局通知", Callback = function() WasUI:Notify("演示通知", "这是来自 WasUI 的全局通知", 3) end })

miscTab:Button({ Text = "切换主题", Callback = function()
    local current = WasUI:GetTheme()
    WasUI:SetTheme(current == "Light" and "Dark" or "Light")
    print("[杂项] 主题已切换为:", WasUI:GetTheme())
end })

miscTab:Space(10)

-- ==================== 选项卡 5：Roblox 服务 ====================
local serviceTab = win:Tab("Roblox 服务")

-- 显示玩家信息
local player = game.Players.LocalPlayer
serviceTab:Paragraph({ Text = "玩家信息", Desc = "当前玩家相关数据" })
local playerNameLabel = serviceTab:Button({ Text = "玩家名称: " .. player.Name, Callback = function() end })
playerNameLabel:SetText("玩家名称: " .. player.Name)  -- 实际按钮文本不可修改，这里用Paragraph更合适，但为演示简单

-- 使用 Paragraph 显示动态内容
local playerInfo = serviceTab:Paragraph({ Text = "玩家名称: " .. player.Name, Desc = "玩家ID: " .. player.UserId })

-- 获取玩家鼠标位置（UserInputService）
local userInput = game:GetService("UserInputService")
local mousePosLabel = serviceTab:Paragraph({ Text = "鼠标位置: 等待移动...", Desc = "" })

local mouseMoveConn
mouseMoveConn = userInput.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        mousePosLabel:SetText("鼠标位置: X=" .. math.floor(input.Position.X) .. ", Y=" .. math.floor(input.Position.Y))
    end
end)

-- 获取运行服务相关信息
local runService = game:GetService("RunService")
local fpsLabel = serviceTab:Paragraph({ Text = "FPS: 计算中...", Desc = "通过 RenderStepped 估算" })

local lastTime = tick()
local frameCount = 0
local fps = 0
local fpsConn
fpsConn = runService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local now = tick()
    if now - lastTime >= 1 then
        fps = frameCount
        frameCount = 0
        lastTime = now
        fpsLabel:SetText("FPS: " .. fps)
    end
end)

-- 灯光服务调节示例
local lighting = game:GetService("Lighting")
local brightnessSlider = serviceTab:Slider({
    Text = "游戏亮度",
    Min = 0,
    Max = 2,
    Default = lighting.Brightness,
    Step = 0.05,
    Callback = function(value)
        lighting.Brightness = value
        print("[服务] 亮度设置为:", value)
    end
})

-- 获取当前时间（RunService 或 os.time）
local timeLabel = serviceTab:Paragraph({ Text = "当前时间: " .. os.date("%H:%M:%S"), Desc = "每 1 秒更新" })
local timeConn
timeConn = runService.Heartbeat:Connect(function()
    -- 每秒更新一次
    if tick() % 1 < 0.05 then
        timeLabel:SetText("当前时间: " .. os.date("%H:%M:%S"))
    end
end)

-- 一个按钮用于获取服务列表（示例）
serviceTab:Button({ Text = "打印所有服务", Callback = function()
    local services = {"Players", "RunService", "UserInputService", "Lighting", "TweenService", "HttpService"}
    print("可用的 Roblox 服务:")
    for _, s in ipairs(services) do
        local success, service = pcall(function() return game:GetService(s) end)
        if success then
            print("  " .. s .. ": 可用")
        else
            print("  " .. s .. ": 不可用")
        end
    end
end })

serviceTab:Space(10)
serviceTab:Paragraph({ Text = "注意: 部分服务可能因权限而无法访问，但大多数核心服务可用。" })

-- ==================== 配置管理（保存用户设置）====================
local configTab = win:Tab("配置管理")

-- 创建设置项
local toggle1 = configTab:Toggle({
    Text = "启用特效",
    Value = false,
    Callback = function(v) print("[配置] 特效:", v) end
})
local slider1 = configTab:Slider({
    Text = "音量",
    Min = 0,
    Max = 100,
    Default = 50,
    Callback = function(v) print("[配置] 音量:", v) end
})
local input1 = configTab:Input({
    Text = "用户名",
    Value = "Player",
    Placeholder = "输入名称",
    Callback = function(t) print("[配置] 用户名:", t) end
})
local dropdown1 = configTab:Dropdown({
    Text = "语言",
    Values = {"中文", "English", "日本語"},
    Default = "中文",
    Callback = function(s) print("[配置] 语言:", s) end
})
local color1 = configTab:Colorpicker({
    Text = "主题颜色",
    Default = Color3.fromRGB(0,120,215),
    Callback = function(c) print("[配置] 颜色:", c) end
})

-- 创建配置管理器实例
local myConfig = WasUI.ConfigManager:NewConfig("user_settings", true)  -- autoLoad = true

-- 注册控件
myConfig:Register("toggle_effect", toggle1)
myConfig:Register("volume", slider1)
myConfig:Register("username", input1)
myConfig:Register("language", dropdown1)
myConfig:Register("theme_color", color1)

-- 控制按钮
configTab:Button({
    Text = "保存配置",
    Callback = function()
        myConfig:Save()
        WasUI:Notify("配置", "设置已保存", 2)
    end
})
configTab:Button({
    Text = "加载配置",
    Callback = function()
        myConfig:Load()
        WasUI:Notify("配置", "设置已加载", 2)
    end
})
configTab:Button({
    Text = "重置为默认",
    Callback = function()
        toggle1:Set(false)
        slider1:Set(50)
        input1:Set("Player")
        dropdown1:Select("中文")
        color1:SetColor(Color3.fromRGB(0,120,215))
        WasUI:Notify("配置", "已重置为默认值", 2)
    end
})

-- 可选：列出所有配置
configTab:Button({
    Text = "列出所有配置",
    Callback = function()
        local configs = WasUI.ConfigManager:ListConfigs()
        print("当前配置文件:", table.concat(configs, ", "))
    end
})

-- 窗口关闭时清理连接
win.Close = function()
    if mouseMoveConn then mouseMoveConn:Disconnect() end
    if fpsConn then fpsConn:Disconnect() end
    if timeConn then timeConn:Disconnect() end
    print("[WasUI] 窗口已关闭，所有连接已清理")
end