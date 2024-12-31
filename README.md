# Rounded Rects

## Description

This is a library to draw anti-aliased rounded rectangles in Garry's Mod.

## Usage

```lua
local RoundedRect = include("rounded_rect.lua")

hook.Add("HUDPaint", "DrawRoundedRect", function()
    local x, y = 300, 300
    local w, h = 500, 500
    UI.RoundedRect.Draw(10, x, y, w, h, color_white)
    UI.RoundedRect.DrawEx(10, x + w + 20, y, w, h, color_white, true, false, true, false)
    UI.RoundedRect.DrawEx2(x + (w * 2) + 40, y, w, h, color_white, 5, 10, 20, 40)
end)
```
![image](https://github.com/user-attachments/assets/de3abf33-68f3-42cc-b5ee-d64bf8e93743)

## Functions

### RoundedRect.Draw(radius, x, y, w, h, color)

Draws a rounded rectangle with the given radius, position, size and color.

### RoundedRect.DrawEx(radius, x, y, w, h, color, tl, tr, bl, br)

Draws a rounded rectangle with the given radius, position, size, color and corner flags. The corner flags are booleans that determine if the corner should be rounded.

### RoundedRect.DrawEx2(x, y, w, h, color, tl, tr, bl, br)

Draws a rounded rectangle with the given position, size, color and corner radii. The corner radii are the radius of each corner.

## FAQ

### What the hell is this?

Incase you didn't know, Garry's Mod default rectangles look terrible.

### This is Stupid.

Yes.

Jokes aside, This is actually a nice way to get anti-aliased rounded rect and really fast (unless Rubat approves shaders), unlike `surface.DrawPoly` which is really slow and doesn't support anti-aliasing. `draw.RoundedBox` looks terrible at some scales even with anti-aliasing enabled. (+ one is faster by 100% in main branch and by around 500% in x86-64 branch)
![image](https://github.com/user-attachments/assets/2f59e3e3-b471-4dd9-a3eb-886f1b7346c1)


You could use [Spoly MelonsMasks](https://github.com/Srlion/spoly_melonsmasks) but anti-aliasing in gmod make it look terrible. Corners look so blurry and ugly. So why not just use Awesomium/Chromium's anti-aliasing? :D
