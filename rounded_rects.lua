local ADDON_NAME = "YOUR_ADDON_NAME"

local util = util
local file = file
local math = math

local Material = Material
local SetDrawColor = surface.SetDrawColor
local SetMaterial = surface.SetMaterial
local DrawTexturedRect = surface.DrawTexturedRect

local DIR = ADDON_NAME:lower() .. "/rounded_rects/"
file.CreateDir(DIR)

local QUEUED = {}
local MATERIALS = {}

-- Because vgui.Create is not ready yet when loading early
local html = vgui.CreateX("Awesomium")
html:SetMouseInputEnabled(false)
html:SetKeyboardInputEnabled(false)
html:SetVisible(false)
html:NewObjectCallback("lua", "callback")

local COL_WHITE = Color(255, 255, 255)
local COL_GREEN = Color(51, 184, 100)
local COL_BLUE = Color(92, 192, 254)
function html:OnCallback(_, _, args)
    local id, data = args[1], args[2]
    local path = DIR .. util.SHA256(id) .. ".png"
    file.Write(path, util.Base64Decode(data))
    MATERIALS[id] = Material("data/" .. path)
    QUEUED[id] = nil
    MsgC(COL_BLUE, "[Rounded Rects]", COL_WHITE, " Generated rounded rect with ID ", COL_GREEN, id, "\n")
end

html:SetHTML([=[
<script>
  function generateRoundedRect(width, height, roundTL, roundTR, roundBL, roundBR) {
    const canvas = document.createElement('canvas');
    canvas.width = width;
    canvas.height = height;

    const ctx = canvas.getContext('2d');
    ctx.beginPath();

    ctx.moveTo(roundTL, 0);

    ctx.lineTo(width - roundTR, 0);
    if (roundTR > 0) {
      ctx.arcTo(width, 0, width, roundTR, roundTR);
    }

    ctx.lineTo(width, height - roundBR);
    if (roundBR > 0) {
      ctx.arcTo(width, height, width - roundBR, height, roundBR);
    }

    ctx.lineTo(roundBL, height);
    if (roundBL > 0) {
      ctx.arcTo(0, height, 0, height - roundBL, roundBL);
    }

    ctx.lineTo(0, roundTL);
    if (roundTL > 0) {
      ctx.arcTo(0, 0, roundTL, 0, roundTL);
    }

    ctx.closePath();
    ctx.fillStyle = "white";
    ctx.fill();

    const base64Data = canvas.toDataURL("image/png").split(",")[1];
    return base64Data;
  }
</script>
]=])

local function get_id(w, h, tl, tr, bl, br)
    return w .. ";" .. h .. ";" .. tl .. ";" .. tr .. ";" .. bl .. ";" .. br
end

local function get_right_roundness(w, h, tl, tr, bl, br)
    local max_roundness = math.min(w, h) / 2
    tl, tr, bl, br =
        math.min(tl, max_roundness),
        math.min(tr, max_roundness),
        math.min(bl, max_roundness),
        math.min(br, max_roundness)
    return tl, tr, bl, br
end

-- we can't run JS code until the page is loaded
local function RunJS(code)
    if html:IsLoading() then
        timer.Simple(0.5, function()
            RunJS(code)
        end)
    else
        html:RunJavascript(code)
    end
end

local function generate_rounded_rect(w, h, tl, tr, bl, br)
    tl, tr, bl, br = get_right_roundness(w, h, tl, tr, bl, br)
    local ID = get_id(w, h, tl, tr, bl, br)

    if QUEUED[ID] or MATERIALS[ID] then
        return ID
    end

    do
        local path = DIR .. util.SHA256(ID) .. ".png"
        if file.Exists(path, "DATA") then
            MATERIALS[ID] = Material("data/" .. path)
            if not MATERIALS[ID]:IsError() then
                return ID
            end
        end
    end

    QUEUED[ID] = true

    w, h, tl, tr, bl, br =
        math.floor(w),
        math.floor(h),
        math.floor(tl),
        math.floor(tr),
        math.floor(bl),
        math.floor(br)

    local code = [[
        var pngBytes = generateRoundedRect(%u, %u, %u, %u, %u, %u);
        lua.callback('%s', pngBytes);
    ]]
    RunJS(code:format(w, h, tl, tr, bl, br, ID))

    return ID
end

local function internal_draw(id, x, y, w, h, col)
    local mat = MATERIALS[id]
    if not mat then return end
    if col then
        SetDrawColor(col)
    else
        SetDrawColor(255, 255, 255, 255)
    end
    SetMaterial(mat)
    DrawTexturedRect(x, y, w, h)
end

local function DrawEx2(x, y, w, h, col, tl, tr, bl, br)
    local ID = generate_rounded_rect(w, h, tl, tr, bl, br)
    internal_draw(ID, x, y, w, h, col)
end

local function Draw(r, x, y, w, h, col)
    DrawEx2(x, y, w, h, col, r, r, r, r)
end

local function DrawEx(r, x, y, w, h, col, rtl, rtr, rbl, rbr)
    rtl, rtr = rtl and r or 0, rtr and r or 0
    rbl, rbr = rbl and r or 0, rbr and r or 0
    DrawEx2(x, y, w, h, col, rtl, rtr, rbl, rbr)
end

return {
    Draw = Draw,
    DrawEx = DrawEx,
    DrawEx2 = DrawEx2
}