--[[
MIT License

Copyright (c) 2024 Srlion (https://github.com/Srlion)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
local ADDON_NAME = "YOUR_ADDON_NAME"

local util = util
local file = file
local math = math

local Material = Material
local SetDrawColor = surface.SetDrawColor
local SetMaterial = surface.SetMaterial
local DrawTexturedRectUV = surface.DrawTexturedRectUV

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
local COL_RED = Color(255, 0, 0)
function html:OnCallback(_, _, args)
    local success, id, data = args[1], args[2], args[3]
    QUEUED[id] = nil
    if not success then
        MsgC(COL_BLUE, "[Rounded Rects]", COL_RED, " Failed to generate rounded rect with ID ", COL_GREEN, id, COL_WHITE, ": ", data, "\n")
        return
    end
    local path = DIR .. util.SHA256(id) .. ".png"
    file.Write(path, util.Base64Decode(data))
    MATERIALS[id] = Material("data/" .. path)
    MsgC(COL_BLUE, "[Rounded Rects]", COL_WHITE, " Generated rounded rect with ID ", COL_GREEN, id, "\n")
end

html:SetHTML([=[
<script>
  function generateRoundedRect(id, width, height, roundTL, roundTR, roundBL, roundBR, imageData) {
    var canvas = document.createElement('canvas');
    var context = canvas.getContext('2d');

    var hasImage = !!imageData;
    var scaleFactor = hasImage ? 2 : 1;
    canvas.width = width * scaleFactor;
    canvas.height = height * scaleFactor;

    function drawRoundedRectangle() {
      context.beginPath();
      context.moveTo(roundTL * scaleFactor, 0);

      context.lineTo(canvas.width - (roundTR * scaleFactor), 0);
      if (roundTR > 0) {
        context.arcTo(canvas.width, 0, canvas.width, roundTR * scaleFactor, roundTR * scaleFactor);
      }

      context.lineTo(canvas.width, canvas.height - (roundBR * scaleFactor));
      if (roundBR > 0) {
        context.arcTo(canvas.width, canvas.height, canvas.width - (roundBR * scaleFactor), canvas.height, roundBR * scaleFactor);
      }

      context.lineTo(roundBL * scaleFactor, canvas.height);
      if (roundBL > 0) {
        context.arcTo(0, canvas.height, 0, canvas.height - (roundBL * scaleFactor), roundBL * scaleFactor);
      }

      context.lineTo(0, roundTL * scaleFactor);
      if (roundTL > 0) {
        context.arcTo(0, 0, roundTL * scaleFactor, 0, roundTL * scaleFactor);
      }

      context.closePath();
      context.fillStyle = "white";
      context.fill();
    }

    function drawImage(img) {
      context.save();
      context.clip();

      context.imageSmoothingEnabled = true;
      context.imageSmoothingQuality = "high";

      context.drawImage(img, 0, 0, canvas.width, canvas.height);
      context.restore();
    }

    drawRoundedRectangle();
    if (!hasImage) {
      const base64Data = canvas.toDataURL("image/png").split(",")[1];
      lua.callback(true, id, base64Data);
      return
    }

    var img = new Image();
    img.onload = function () {
      drawImage(img);

      var outputCanvas = document.createElement('canvas');
      var outputContext = outputCanvas.getContext('2d');
      outputCanvas.width = width;
      outputCanvas.height = height;

      outputContext.drawImage(canvas, 0, 0, outputCanvas.width, outputCanvas.height);

      var result = outputCanvas.toDataURL('image/png').split(',')[1];
      lua.callback(true, id, result);
    };

    img.onerror = function () {
      lua.callback(false, id, "Failed to load image.");
    };

    var mimeType;
    if (imageData.charAt(0) === '/') {
      mimeType = 'image/jpeg';
    } else if (imageData.charAt(0) === 'i') {
      mimeType = 'image/png';
    } else {
      lua.callback(false, id, "Invalid image data.");
      return;
    }

    img.src = 'data:' + mimeType + ';base64,' + imageData;
  }
</script>
]=])

local function get_id(w, h, tl, tr, bl, br, image_id)
    if image_id then
        return w .. "_" .. h .. "_" .. tl .. "_" .. tr .. "_" .. bl .. "_" .. br .. "_" .. image_id
    end
    return w .. ";" .. h .. ";" .. tl .. ";" .. tr .. ";" .. bl .. ";" .. br
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

local function math_floor_min(a, b)
    return (math.floor(math.min(a, b)))
end

local function generate_rounded_rect(w, h, tl, tr, bl, br, image_id, image_data)
    w, h = math.floor(w), math.floor(h)

    local max_roundness = math.min(w, h) / 2
    tl, tr, bl, br =
        math_floor_min(tl, max_roundness),
        math_floor_min(tr, max_roundness),
        math_floor_min(bl, max_roundness),
        math_floor_min(br, max_roundness)

    local ID = get_id(w, h, tl, tr, bl, br, image_id)

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

    image_data = (image_id and image_data) and "\"" .. util.Base64Encode(image_data, true) .. "\"" or "null"

    local code = [[
        generateRoundedRect('%s', %u, %u, %u, %u, %u, %u, %s);
    ]]
    RunJS(code:format(ID, w, h, tl, tr, bl, br, image_data))

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
    -- https://gmodwiki.com/surface.DrawTexturedRectUV
    local u0, v0, u1, v1 = 0, 0, 1, 1
    local du = 0.5 / w -- half pixel anticorrection
    local dv = 0.5 / h -- half pixel anticorrection
    u0, v0 = (u0 - du) / (1 - 2 * du), (v0 - dv) / (1 - 2 * dv)
    u1, v1 = (u1 - du) / (1 - 2 * du), (v1 - dv) / (1 - 2 * dv)
    DrawTexturedRectUV(x, y, w, h, u0, v0, u1, v1)
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

local function DrawImage(r, x, y, w, h, col, image_id, image_data)
    local ID = generate_rounded_rect(w, h, r, r, r, r, image_id, image_data)
    internal_draw(ID, x, y, w, h, col)
end

return {
    Draw = Draw,
    DrawEx = DrawEx,
    DrawEx2 = DrawEx2,
    DrawImage = DrawImage
}
