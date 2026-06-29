-- Toggle: Right Control


local Players = game:GetService("Players")

local VK_RCONTROL = 0xA3
local PULSE_SECONDS = 0.02
local MOVE_KEYS = {
    0x57, -- W
    0x41, -- A
    0x53, -- S
    0x44, -- D
}



local enabled = false
local overlay = nil
local fading = false

local function safeNotify(message, title, duration)
    if notify then
        pcall(notify, message, title or "Movement Toggle", duration or 3)
    end
end

local function getViewportSize()
    local ok, size = pcall(function()
        return workspace.CurrentCamera.ViewportSize
    end)

    if ok and size then
        return size
    end

    return Vector2.new(1920, 1080)
end

local function createDrawingOverlay()
    local text = Drawing.new("Text")
    text.Visible = false
    text.Text = "Anti-AFK is ON"
    text.Color = Color3.fromHSV(255,0,0)
    text.Center = true
    text.Outline = true
    text.Size = 36
    text.ZIndex = 1000
    local group={Text=text,Visible=false}
    function group:SetVisible(v) self.Visible=v==true; self.Text.Visible=self.Visible end
    function group:SetTransparency(v) self.Text.Transparency=1-v end
    function group:Layout() local vp=getViewportSize(); self.Text.Position=Vector2.new(vp.X/2,vp.Y/2) end
    function group:Remove() pcall(function() self.Text:Remove() end) end
    return group
end

local function showOverlay()
    fading = false

    if not overlay then
        overlay = createDrawingOverlay()
    end

    overlay:Layout()
    overlay:SetTransparency(0)
    overlay:SetVisible(true)

    task.spawn(function()
        local duration = 0.45
        local started = os.clock()

        while enabled and os.clock() - started < duration do
            local alpha = (os.clock() - started) / duration
            if overlay then
                overlay:SetTransparency(alpha)
            end
            task.wait(0.016)
        end

        if enabled and overlay then
            overlay:SetTransparency(1)
        end
    end)
end

local function fadeOutOverlay()
    if not overlay or fading then return end

    fading = true
    task.spawn(function()
        local duration = 0.45
        local started = os.clock()

        while os.clock() - started < duration do
            local alpha = 1 - ((os.clock() - started) / duration)
            if overlay then
                overlay:SetTransparency(alpha)
            end
            task.wait(0.016)
        end

        if overlay then
            overlay:SetTransparency(0)
            overlay:SetVisible(false)
        end

        fading = false
    end)
end

local function tapKey(vk, seconds)
    pcall(keypress, vk)
    task.wait(seconds or PULSE_SECONDS)
    pcall(keyrelease, vk)
end

local function setEnabled(value)
    enabled = value == true

    if enabled then
        showOverlay()
        safeNotify("Enabled", "Movement Toggle", 2)
    else
        fadeOutOverlay()
        safeNotify("Disabled", "Movement Toggle", 2)
    end
end

task.spawn(function()
    local wasDown = false

    while true do
        local down = false
        pcall(function()
            down = iskeypressed(VK_RCONTROL) == true
        end)

        if down and not wasDown then
            setEnabled(not enabled)
        end

        wasDown = down
        task.wait(0.03)
    end
end)

task.spawn(function()
    math.randomseed(math.floor(os.clock() * 100000))

    while true do
        if enabled then
            if overlay then
                overlay:Layout()
            end

            local vk = MOVE_KEYS[math.random(1, #MOVE_KEYS)]
            tapKey(vk, PULSE_SECONDS)
            task.wait(math.random(650, 1200) / 100)
        else
            task.wait(0.1)
        end
    end
end)

safeNotify("Loaded. Press Right Control to toggle.", "Movement Toggle", 4)

local RunService=game:GetService("RunService")
RunService.RenderStepped:Connect(function()
 if overlay and overlay.Text then
  overlay.Text.Color=Color3.fromHSV((tick()*0.25)%1,1,1)
 end
end)
