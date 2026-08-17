-- @MugTypography
-- @api_level 9
-- @recommend text "So you've finally made it this far.\nI have been waiting a very long time to meet you."
-- @duration 5.0
-- @title Dialogue Window
-- @author Mug
-- @version 1.0
-- @input number 1 "Window Width" default=0.84
-- @input number 2 "Window Height" default=0.27
-- @input number 3 "Icon Area Ratio" default=0.155
-- @input number 4 "Text Padding X" default=0.03
-- @input number 5 "Text Padding Y" default=0.06
-- @input number 6 "Corner Roundness" default=0.22
-- @input number 7 "Icon Scale" default=1.0
-- @input number 8 "Typing Delay" default=0.0
-- @input number 9 "Typing Speed" default=20.0
-- @input number 10 "Show Marker (0=off 1=on)" default=1
-- @input color 1 "Window Color" default={0.035, 0.045, 0.075, 0.96}
-- @input color 2 "Icon Color" default={0.95, 0.96, 1.0, 1.0}
-- @input color 3 "Marker Color" default={0.95, 0.96, 1.0, 1.0}
-- @input text 1 "Icon SVG" default="M4.5 9.5C5.88 9.5 7 8.38 7 7S5.88 4.5 4.5 4.5 2 5.62 2 7s1.12 2.5 2.5 2.5zM9 6c1.38 0 2.5-1.12 2.5-2.5S10.38 1 9 1 6.5 2.12 6.5 3.5 7.62 6 9 6zM15 6c1.38 0 2.5-1.12 2.5-2.5S16.38 1 15 1s-2.5 1.12-2.5 2.5S13.62 6 15 6zM19.5 9.5C20.88 9.5 22 8.38 22 7s-1.12-2.5-2.5-2.5S17 5.62 17 7s1.12 2.5 2.5 2.5zM17.34 14.86c-.87-1.02-1.6-1.89-2.48-2.91-.46-.54-1.05-1.08-1.75-1.32-.11-.04-.22-.07-.33-.09-.57-.12-1.17-.12-1.74 0-.11.02-.22.05-.33.09-.7.24-1.28.78-1.75 1.32-.87 1.02-1.6 1.89-2.48 2.91-1.31 1.31-2.92 2.76-2.62 4.79.29 1.02 1.02 2.03 2.33 2.32.73.15 3.06-.44 5.54-.44h.36c2.48 0 4.81.58 5.54.441.31-.29 2.04-1.31 2.33-2.32.3-2.03-1.31-3.48-2.62-4.79z"
--[[ @description
A game-style dialogue window: the text types itself out inside a rounded
panel, with a speaker icon on the left and a bobbing marker that appears
once the line is finished.

Icon SVG:
    Open an SVG file in a text editor, copy the whole contents and paste
    them into the field. Pasting just the contents of a d attribute works
    too. Clearing the field leaves the icon out, and an X is drawn when the
    text cannot be read. Elliptical arcs (A/a commands) are not supported.

Beyond that, several of the standard inspector settings drive this effect:

Window outline:
    The script never touches Stroke, so the window frame is whatever the
    inspector's stroke settings say. Turn Stroke on and give it a width to
    draw a border; leave it off for a borderless panel. The stroke is
    applied to every character, but each fill paints over its own stroke,
    so on the text and the icon it stays hidden behind them and only the
    window reads as outlined.

Alignment:
    The body text is aligned inside the window, not the screen. Left with
    Baseline reads the most like a real dialogue box: lines start at a
    common left margin and sit low in the panel. Center is better suited to
    a single short line.

Fill / Gradient:
    The body text takes the inspector's own fill color, so gradients and
    any other fill settings apply to it as usual. The window, icon and
    marker have their own color inputs and ignore it.

Global Scale:
    Sets the body text size. The window itself does not scale with it: the
    number of lines that fit is recomputed from the resulting size and
    Line Spacing, and the text rewraps to match. Larger text simply means
    fewer lines in the same panel.

Global Position X/Y:
    Moves the whole UI, window and all, rather than the text alone.

Tracking and Line Spacing behave as usual and are folded into the wrap.

------------------------------------------------------------

ゲームの会話ウインドウ風アニメーション。角丸パネルの中で本文が1文字ずつ
表示され、左に話者アイコン、本文を出し切ると右下に会話送りの▼が現れて
上下に揺れます。

Icon SVG:
    SVGファイルをテキストエディタで開き、中身を全部コピーして貼り付けます。
    d属性の中身だけを貼り付けても構いません。空欄にするとアイコンなしに
    なり、読み取れない場合は✗が表示されます。楕円弧（A/aコマンド）には
    対応していません。

上記のほかに、通常のInspector設定も効きます。

ウインドウの枠線:
    スクリプトはStrokeに一切触れないため、枠線はInspectorのStroke設定
    そのままになります。Strokeをオンにして幅を与えると枠が描かれ、オフ
    なら枠なしのパネルになります。Strokeは全文字に適用されますが、各文字
    は自身の塗りが枠線の上に乗るため、本文とアイコンでは背面に隠れ、
    ウインドウだけが枠線付きに見えます。

Alignment:
    本文は画面ではなくウインドウ内で整列します。Left と Baseline の組み
    合わせが最も会話ウインドウらしく、各行が共通の左マージンから始まり、
    パネル内のやや下寄りに配置されます。1行の短い台詞なら Center も適して
    います。

Fill / Gradient:
    本文はInspectorのFill色をそのまま使うため、グラデーションなどの塗り
    設定がそのまま効きます。ウインドウ・アイコン・▼は専用の色パラメータ
    を持ち、Fillの影響を受けません。

Global Scale:
    本文の文字サイズを決めます。ウインドウ自体は追従せず、そのサイズと
    Line Spacingから収まる行数を再計算して折り返し直します。文字を大きく
    すると、同じパネルに入る行数が減るだけです。

Global Position X/Y:
    本文だけでなく、ウインドウを含むUI全体を移動します。

Tracking と Line Spacing は通常どおり動作し、折り返しに反映されます。
]]

------------------------------------------------------------
-- Values taken from the inspector
------------------------------------------------------------

local uiOffsetX = 0.0
local uiOffsetY = 0.0
local textScale = 1.0

------------------------------------------------------------
-- Character layout
--
-- Three glyphs are prepended to the inspector's text, so their indices are
-- fixed and the body text starts after them.
------------------------------------------------------------

local WINDOW_CHARACTER = 1
local ICON_CHARACTER = 2
local MARKER_CHARACTER = 3
local FIRST_TEXT_CHARACTER = 4

-- Floor for the line advance, so a degenerate line height cannot divide by
-- zero when the fitting line count is worked out.
local MINIMUM_LINE_ADVANCE = 0.000001

------------------------------------------------------------
-- Window
------------------------------------------------------------

-- Window center. Resizing does not move it.
local WINDOW_X = 0.5
local WINDOW_Y = 0.295

-- Size floor, so a collapsed window cannot break the drawing.
local WINDOW_MINIMUM_WIDTH = 0.05
local WINDOW_MINIMUM_HEIGHT = 0.05

-- Size taken from the inspector, resolved in OnPreLayout.
local windowWidth = 0.84
local windowHeight = 0.27

-- Edges derived from the size above, updated in OnPreLayout.
local windowLeft = 0.08
local windowRight = 0.92
local windowBottom = 0.16
local windowTop = 0.43

------------------------------------------------------------
-- Icon
--
-- A fixed share of the window's left side is the icon area, and the icon
-- sits at its center. Holding it as a ratio keeps the proportion when the
-- window is resized.
------------------------------------------------------------

-- Ceiling on the icon area's share of the width. Past this the body text
-- has nowhere left to go.
local ICON_AREA_RATIO_LIMIT = 0.8
local ICON_HEIGHT = 0.075

-- Resolved in OnPreLayout.
local iconX = 0.145
local iconY = 0.295

-- Right edge of the icon area. The text area starts from it.
local iconAreaRight = 0.223

------------------------------------------------------------
-- Advance marker
--
-- Bobs at the bottom right of the window to show the dialogue is waiting
-- to be advanced. Positioned by its distance from that corner.
------------------------------------------------------------

-- Distance from the corner, held as a length normalized by canvas height
-- and divided by aspect_ratio for the horizontal axis.
--
-- Writing separate normalized values for X and Y would put the same number
-- at different on-screen distances (about 1.8x wider at 16:9).
local MARKER_INSET = 0.045
local MARKER_HEIGHT = 0.034

-- Resolved in OnPreLayout.
local markerX = 0.885
local markerY = 0.185

-- Seconds per bob cycle, and its amplitude as a fraction of canvas height.
local MARKER_BOB_PERIOD = 0.9
local MARKER_BOB_AMPLITUDE = 0.008

-- Share of the cycle spent descending. Below half, the marker drops
-- quickly and drifts back up slowly.
local MARKER_BOB_FALL_RATIO = 0.42

-- Threshold that counts as Show Marker being on. The input is numeric, so
-- anything at or above this is on rather than rounding to the nearest.
local MARKER_ENABLED_THRESHOLD = 0.5

-- Pause between the text finishing and the marker appearing.
--
-- Fixed rather than measured in characters: a character-based pause scales
-- inversely with Speed, so it reads as simultaneous when fast and as a
-- stall when slow.
local MARKER_PAUSE_SECONDS = 0.3

------------------------------------------------------------
-- Text area
--
-- Lines are packed into this band, as many as Scale and Line Spacing allow.
------------------------------------------------------------

-- The text area runs from the icon area's right edge to the window's right
-- edge, with the inspector's padding inside that.
--
-- Top and bottom are derived from the window edges with the same padding.
-- Writing TOP/BOTTOM as literals lets the two margins disagree, which
-- pushes the text off the window's center.

-- Padding taken from the inspector, resolved in OnPreLayout.
local textPaddingX = 0.03
local textPaddingY = 0.06

-- Resolved in OnPreLayout.
local textLeft = 0.225
local textRight = 0.875
local textTop = 0.355
local textBottom = 0.205
local RIGHT_MARGIN = 0.008

------------------------------------------------------------
-- Word wrapping
------------------------------------------------------------

-- Leading byte of the UTF-8 sequences covering the CJK ideographs, hiragana,
-- katakana and the full-width punctuation that goes with them.
local CJK_CHARACTER_PATTERN = "[\227-\233]"

---Whether a line is allowed to break between two characters.
---
---Scripts that use spaces break at them, so a word only ever moves down whole.
---CJK has no spaces and breaks between any two of its own characters. Where the
---two scripts meet is a break opportunity as well, which keeps a run of Latin
---embedded in CJK together instead of splitting it down the middle.
---@param text string|nil the character
---@param previousText string|nil the character before it
---@return boolean
local function canBreakBefore(text, previousText)
    local result = false

    if text ~= nil and previousText ~= nil then
        local isCjk = text:match(CJK_CHARACTER_PATTERN) ~= nil
        local previousIsCjk = previousText:match(CJK_CHARACTER_PATTERN) ~= nil

        -- A space ends a word, so the character after one starts the next.
        if previousText == " " then
            result = true
        elseif isCjk and previousIsCjk then
            result = true
        elseif isCjk ~= previousIsCjk then
            -- The boundary between a CJK run and a Latin one.
            result = true
        end
    end

    return result
end

------------------------------------------------------------
-- Typing reveal
--
-- Only characters that are actually visible count toward the reveal.
-- Counting newlines and characters the wrap dropped would spend typing
-- time while nothing happens on screen.
------------------------------------------------------------

-- How many characters may be shown at the current time, resolved in
-- OnLayout. A negative value means no limit, so the whole text shows.
local typedCharacterLimit = -1.0

------------------------------------------------------------
-- Empty path, used when there is no icon
--
-- The default icon is carried as the inspector input's default value
-- (Google Material Icons "pets", Apache License 2.0). Clearing that field
-- draws no icon at all.
------------------------------------------------------------

local emptyIcon = mt.drawing_path()

------------------------------------------------------------
-- Cross shown when the icon cannot be read
--
-- Says so on the spot. Drawing nothing would only look like the icon
-- disappeared, leaving the mistake in the input unnoticed.
------------------------------------------------------------

local errorIcon = mt.svg_path(
    "M5 3.6L3.6 5 10.6 12 3.6 19 5 20.4 12 13.4 19 20.4 20.4 19 13.4 12 20.4 5 19 3.6 12 10.6z",
    { view_box = { 0, 0, 24, 24 }, em_scale = 0.9 }
)

------------------------------------------------------------
-- Reading the icon SVG
------------------------------------------------------------

-- Commands mt.svg_path does not support. They raise no error and are
-- silently dropped, so they have to be detected here before drawing.
local UNSUPPORTED_PATH_COMMAND = "[Aa]"

-- The resolved path and the text it came from, so the SVG is only parsed
-- again when the input changes.
--
-- The source starts as a sentinel no input can produce, which forces the
-- first resolve.
local resolvedIconPath = emptyIcon
local resolvedIconSource = "\0"
local iconLoadFailed = false

---Pulls the viewBox and every path's `d` out of raw SVG markup.
---Accepts a whole `<svg>` document or a bare `d` string.
---@param source string|nil raw text from the inspector
---@return table|nil parsed `{ d = string, viewBox = number[]|nil }`
local function parseSvgSource(source)
    local result = nil

    if source ~= nil and source ~= "" then
        -- Starting with a move command means this is path data on its own.
        if source:match("^%s*[Mm]") then
            result = {
                d = source,
                viewBox = nil,
            }
        else
            -- viewBox="minX minY width height"
            local viewBox = nil
            local viewBoxText = source:match('viewBox%s*=%s*"([^"]*)"') or source:match("viewBox%s*=%s*'([^']*)'")

            if viewBoxText then
                local numbers = {}

                for value in viewBoxText:gmatch("[-%d%.eE+]+") do
                    numbers[#numbers + 1] = tonumber(value)
                end

                if #numbers == 4 and numbers[3] > 0.0 and numbers[4] > 0.0 then
                    viewBox = numbers
                end
            end

            -- Concatenate every <path d="..."> in document order, so a
            -- multi-path icon becomes one shape.
            local pathData = {}

            for d in source:gmatch('<path[^>]-%sd%s*=%s*"([^"]*)"') do
                pathData[#pathData + 1] = d
            end

            for d in source:gmatch("<path[^>]-%sd%s*=%s*'([^']*)'") do
                pathData[#pathData + 1] = d
            end

            if #pathData > 0 then
                result = {
                    d = table.concat(pathData, " "),
                    viewBox = viewBox,
                }
            end
        end
    end

    return result
end

---Chooses the icon path for the current inspector text.
---Falls back to no icon when empty, and to the error icon when the text
---cannot be turned into a usable outline.
---@param source string|nil raw text from the inspector
---@return MtDrawingPath path template to declare
local function resolveIconPath(source)
    local sourceText = source or ""

    -- Reuse the previous result for the same text: mt.svg_path re-parses on
    -- every call, so it is not worth rebuilding each frame.
    if sourceText ~= resolvedIconSource then
        resolvedIconSource = sourceText
        iconLoadFailed = false
        local trimmed = sourceText:match("^%s*(.-)%s*$")

        if trimmed == "" then
            resolvedIconPath = emptyIcon
        else
            local parsed = parseSvgSource(trimmed)

            if parsed == nil then
                iconLoadFailed = true
            elseif parsed.d:match(UNSUPPORTED_PATH_COMMAND) then
                -- Arcs are dropped and the shape comes out mangled, so treat
                -- them as a failure rather than draw a distorted icon.
                print("Icon SVG uses arc commands (A/a), which are not supported.")
                iconLoadFailed = true
            else
                resolvedIconPath = mt.svg_path(parsed.d, {
                    view_box = parsed.viewBox or { 0, 0, 24, 24 },
                    em_scale = 0.9,
                })
            end
        end

        if iconLoadFailed then
            print("Icon SVG could not be read.")
            resolvedIconPath = errorIcon
        end
    end

    return resolvedIconPath
end

------------------------------------------------------------
-- Advance marker glyph
--
-- A downward triangle filling a 24x24 viewBox.
------------------------------------------------------------

local advanceMarker = mt.svg_path("M4 7h16L12 20z", {
    view_box = { 0, 0, 24, 24 },
    em_scale = 0.9,
})

------------------------------------------------------------
-- Rounded window
--
-- The path is rebuilt every frame in OnPath at the window's own
-- proportions, which is what keeps the corners circular.
--
-- Stretching a square path with stretch_x / stretch_y would squash the
-- corner radius by the same factors and turn the corners into ellipses.
------------------------------------------------------------

-- Path coordinates are always 1000 units per em.
local PATH_UNITS_PER_EM = 1000.0

-- The declared path. OnPath redraws the real shape, but the declaration
-- still needs geometry for the part to be created at all.
local windowPath = mt.drawing_path()

-- Corner radius ceiling, as a fraction of the window height. At 0.5 the
-- short side is exactly a half circle.
local WINDOW_CORNER_RATIO_LIMIT = 0.5

-- Computed in OnLayout and read by OnPath, in path units.
local windowHalfWidthUnits = 500.0
local windowHalfHeightUnits = 500.0
local windowCornerUnits = 90.0

---Draws a rounded rectangle whose corners stay circular.
---@param path table drawing path to fill
---@param halfWidth number half width in path units
---@param halfHeight number half height in path units
---@param radius number corner radius in path units
local function buildWindowPath(path, halfWidth, halfHeight, radius)
    local cornerRadius = math.min(radius, math.min(halfWidth, halfHeight))
    local left = -halfWidth
    local right = halfWidth
    local top = -halfHeight
    local bottom = halfHeight
    path:move_to(left + cornerRadius, top)
    path:line_to(right - cornerRadius, top)
    path:quad_to(right, top, right, top + cornerRadius)
    path:line_to(right, bottom - cornerRadius)
    path:quad_to(right, bottom, right - cornerRadius, bottom)
    path:line_to(left + cornerRadius, bottom)
    path:quad_to(left, bottom, left, bottom - cornerRadius)
    path:line_to(left, top + cornerRadius)
    path:quad_to(left, top, left + cornerRadius, top)
    path:close()
end

------------------------------------------------------------
-- Placeholder shape for the declaration
--
-- OnPath redraws it at the right size, but a declaration with no geometry
-- produces no part to redraw.
------------------------------------------------------------

buildWindowPath(windowPath, windowHalfWidthUnits, windowHalfHeightUnits, windowCornerUnits)

------------------------------------------------------------
-- PRE LAYOUT
------------------------------------------------------------

function OnPreLayout(ctx)
    -- Apply the inspector's window size. The center stays put, and every
    -- edge and UI element is derived from the requested size.
    windowWidth = math.max(ctx.inputs.numbers[1], WINDOW_MINIMUM_WIDTH)
    windowHeight = math.max(ctx.inputs.numbers[2], WINDOW_MINIMUM_HEIGHT)
    windowLeft = WINDOW_X - windowWidth * 0.5
    windowRight = WINDOW_X + windowWidth * 0.5
    windowBottom = WINDOW_Y - windowHeight * 0.5
    windowTop = WINDOW_Y + windowHeight * 0.5

    -- Split the width between the icon area on the left and the text area
    -- that takes the rest.
    local iconAreaRatio = mt.clamp(ctx.inputs.numbers[3], 0.0, ICON_AREA_RATIO_LIMIT)
    iconAreaRight = windowLeft + windowWidth * iconAreaRatio

    -- Center the icon in that area on both axes. The vertical center comes
    -- from the window's real edges rather than the center constant, so it
    -- is derived the same way as the horizontal one.
    iconX = (windowLeft + iconAreaRight) * 0.5
    iconY = (windowBottom + windowTop) * 0.5

    -- Hold the padding to half the area so it cannot invert on a small
    -- window.
    local textAreaWidth = windowRight - iconAreaRight
    textPaddingX = math.min(math.max(ctx.inputs.numbers[4], 0.0), textAreaWidth * 0.5)
    textPaddingY = math.min(math.max(ctx.inputs.numbers[5], 0.0), windowHeight * 0.5)
    textLeft = iconAreaRight + textPaddingX
    textRight = windowRight - textPaddingX
    textTop = windowTop - textPaddingY
    textBottom = windowBottom + textPaddingY

    -- The rounder the corner, the further the bottom right is cut inward, so
    -- a fixed inset would leave the marker outside the outline. Push it back
    -- until it sits inside the arc.
    --
    -- Canvas X and Y are normalized by different lengths, so the arc test is
    -- done after bringing the horizontal axis onto the same scale with
    -- aspect_ratio.
    local cornerRadiusY = windowHeight * mt.clamp(ctx.inputs.numbers[6], 0.0, WINDOW_CORNER_RATIO_LIMIT)
    local aspectRatio = ctx.canvas.aspect_ratio

    -- How far the marker reaches out from its center. Vertically that is
    -- half its height plus the bob amplitude; horizontally half its width,
    -- which covers 16 of the 24x24 viewBox against 13 vertically.
    local markerReachY = MARKER_HEIGHT * 0.5 + MARKER_BOB_AMPLITUDE
    local markerReachX = MARKER_HEIGHT * (16.0 / 13.0) * 0.5

    -- Distance from the corner, in the aspect-corrected space. Both axes use
    -- the same MARKER_INSET, so the gaps read as equal on screen.
    local insetX = MARKER_INSET - markerReachX
    local insetY = MARKER_INSET - markerReachY
    local radiusPhysical = cornerRadiusY

    -- Whether a point is inside the arc is decided by its distance from the
    -- corner's center. Anything outside is pulled back onto the arc along
    -- the same direction.
    if insetX < radiusPhysical and insetY < radiusPhysical then
        local offsetX = radiusPhysical - insetX
        local offsetY = radiusPhysical - insetY
        local distance = math.sqrt(offsetX * offsetX + offsetY * offsetY)

        if distance > radiusPhysical and distance > 0.0 then
            local pullBack = distance - radiusPhysical
            insetX = insetX + offsetX / distance * pullBack
            insetY = insetY + offsetY / distance * pullBack
        end
    end

    markerX = windowRight - (insetX + markerReachX) / aspectRatio
    markerY = windowBottom + insetY + markerReachY

    uiOffsetX = ctx.global.position_x - 0.5
    uiOffsetY = ctx.global.position_y - 0.5

    textScale = ctx.global.scale

    -- Return Position and Scale to neutral on the host side. The position is
    -- added back to the whole UI later, and the scale applies to the body
    -- text alone.
    ctx.global.position_x = 0.5
    ctx.global.position_y = 0.5
    ctx.global.scale = 1.0

    local windowGlyph = ctx.glyphs:declare({
        path = windowPath,
        bounds = { 0, 0, 0, 0 },
    })

    -- Uses the SVG pasted into the inspector when there is one.
    local iconGlyph = ctx.glyphs:declare({
        path = resolveIconPath(ctx.inputs.texts[1]),
        bounds = { 0, 0, 0, 0 },
    })

    local markerGlyph = ctx.glyphs:declare({
        path = advanceMarker,
        bounds = { 0, 0, 0, 0 },
    })

    local dialogue = ctx.global.text

    -- c1 = background, c2 = icon, c3 = advance marker, c4 onward = body text
    ctx.global.text = windowGlyph .. iconGlyph .. markerGlyph .. dialogue
end

------------------------------------------------------------
-- LAYOUT
------------------------------------------------------------

---Sizes, places and paints the window background.
---@param ctx table OnLayout context
local function layoutWindow(ctx)
    local window = ctx.chars[WINDOW_CHARACTER]
    local windowWidthCanvas = windowRight - windowLeft
    local windowHeightCanvas = windowTop - windowBottom

    -- Draw the path with its height as one em and pass the width as a ratio
    -- at that scale. em_size is normalized by canvas height, so a path unit
    -- maps straight onto canvas Y but is compressed on X by aspect_ratio;
    -- the width cancels that compression out.
    windowHalfHeightUnits = PATH_UNITS_PER_EM * 0.5
    windowHalfWidthUnits = windowHalfHeightUnits * (windowWidthCanvas / windowHeightCanvas) * ctx.canvas.aspect_ratio

    -- At 0.5 the short side is exactly a half circle. buildWindowPath clamps
    -- to half the short side as well; this states the meaningful range.
    windowCornerUnits = windowHalfHeightUnits * 2.0 * mt.clamp(ctx.inputs.numbers[6], 0.0, WINDOW_CORNER_RATIO_LIMIT)

    -- Uniform scale, from how many em_size units the height covers.
    if ctx.font.em_size > 0.0 then
        window.scale = window.scale * (windowHeightCanvas / ctx.font.em_size)
    end

    mt.layout.place_2d(ctx, window, WINDOW_X + uiOffsetX, WINDOW_Y + uiOffsetY)

    -- The outline follows the inspector's stroke settings, so nothing here
    -- touches it.
    window.fill.use = true
    window.fill.color = ctx.inputs.colors[1]
end

---Sizes, centers and paints the speaker icon.
---@param ctx table OnLayout context
local function layoutIcon(ctx)
    local icon = ctx.chars[ICON_CHARACTER]
    local iconBounds = mt.layout.measure_bounds_2d(ctx, { ICON_CHARACTER })

    -- The icon keeps a fixed size independent of the body's Global Scale;
    -- Icon Scale in the inspector is what resizes it.
    if iconBounds and iconBounds.height > 0 then
        icon.scale = icon.scale * ICON_HEIGHT * math.max(ctx.inputs.numbers[7], 0.0) / iconBounds.height
    end

    mt.layout.place_2d(ctx, icon, iconX + uiOffsetX, iconY + uiOffsetY)

    -- Bring the drawn center back onto the area's center. place_2d anchors on
    -- the declared bounds, which are {0,0,0,0}, so an SVG drawn off-center in
    -- its viewBox does not look centered even once the anchor is. Measure what
    -- was actually drawn and cancel the difference.
    local placedIconBounds = mt.layout.measure_bounds_2d(ctx, { ICON_CHARACTER })

    if placedIconBounds then
        mt.layout.place_2d(
            ctx,
            icon,
            iconX + uiOffsetX - (placedIconBounds.center_x - (iconX + uiOffsetX)),
            iconY + uiOffsetY - (placedIconBounds.center_y - (iconY + uiOffsetY))
        )
    end

    icon.fill.use = true
    icon.fill.color = ctx.inputs.colors[2]
end

---Sizes and paints the advance marker, leaving it hidden.
---Its placement waits until the typing progress is known.
---@param ctx table OnLayout context
local function prepareMarker(ctx)
    local marker = ctx.chars[MARKER_CHARACTER]
    local markerBounds = mt.layout.measure_bounds_2d(ctx, { MARKER_CHARACTER })

    -- Fixed size independent of Scale, like the icon.
    if markerBounds and markerBounds.height > 0 then
        marker.scale = marker.scale * MARKER_HEIGHT / markerBounds.height
    end

    marker.fill.use = true
    marker.fill.color = ctx.inputs.colors[3]
    marker.opacity = 0.0
end

---Places the advance marker and bobs it, once `revealTime` has passed.
---@param ctx table OnLayout context
---@param revealTime number seconds at which the marker appears
local function showMarkerAt(ctx, revealTime)
    if ctx.time < revealTime then
        return
    end

    -- The two directions use different easings to stress the descent: a short
    -- in_quad drop that accelerates, then a longer out_sine return, which
    -- reads as a press rather than a drift.
    --
    -- The phase is measured from the moment it appears. Using ctx.time
    -- directly would have it show up partway through the cycle.
    local phase = mt.cycle(ctx.time - revealTime, MARKER_BOB_PERIOD)
    local descent

    if phase < MARKER_BOB_FALL_RATIO then
        descent = mt.ease.in_quad(phase / MARKER_BOB_FALL_RATIO)
    else
        descent = 1.0 - mt.ease.out_sine((phase - MARKER_BOB_FALL_RATIO) / (1.0 - MARKER_BOB_FALL_RATIO))
    end

    -- Y is up, so descending means moving the offset negative.
    local bobOffset = (0.5 - descent) * 2.0 * MARKER_BOB_AMPLITUDE
    local marker = ctx.chars[MARKER_CHARACTER]
    mt.layout.place_2d(ctx, marker, markerX + uiOffsetX, markerY + uiOffsetY + bobOffset)
    marker.opacity = 1.0
end

---Records the body text's natural layout before anything moves it.
---The inspector's Tracking is already folded into these positions.
---@param ctx table OnLayout context
---@return table measurements keyed by character index
---@return table baseline Y of each source line
local function measureBodyText(ctx)
    local data = {}
    local sourceLineBaseY = {}

    for i = FIRST_TEXT_CHARACTER, ctx.char_count do
        local ch = ctx.chars[i]
        local x, y = mt.layout.get_canvas_position_2d(ctx, ch)
        local bounds = mt.layout.measure_bounds_2d(ctx, { i })
        local sourceLine = ch.line_index

        if sourceLineBaseY[sourceLine] == nil then
            sourceLineBaseY[sourceLine] = y
        end

        local leftFromAnchor = 0.0
        local rightFromAnchor = 0.0

        if bounds then
            leftFromAnchor = bounds.left - x
            rightFromAnchor = bounds.right - x
        end

        data[i] = {
            x = x,
            y = y,
            bounds = bounds,
            sourceLine = sourceLine,
            leftFromAnchor = leftFromAnchor,
            rightFromAnchor = rightFromAnchor,
            text = ch.text,
        }
    end

    return data, sourceLineBaseY
end

---Applies the inspector's Scale to every body character.
---The fill is left untouched so the text keeps the inspector's own color.
---@param ctx table OnLayout context
local function styleBodyText(ctx)
    for i = FIRST_TEXT_CHARACTER, ctx.char_count do
        local ch = ctx.chars[i]
        ch.scale = ch.scale * textScale
    end
end

---Line advance from the font's line height, Line Spacing and Scale.
---@param ctx table OnLayout context
---@return number advance in canvas units, floored away from zero
local function resolveLineAdvance(ctx)
    local lineAdvance = ctx.font.line_height * ctx.global.line_spacing * textScale * math.abs(ctx.global.stretch_y)
    return math.max(lineAdvance, MINIMUM_LINE_ADVANCE)
end

---Updates `typedCharacterLimit` for the current time.
---@param ctx table OnLayout context
---@return number typing speed in characters per second
---@return number delay in seconds before the reveal starts
local function resolveTypingProgress(ctx)
    -- Past the delay the count grows by Speed characters per second. A Speed
    -- of zero or less drops the per-character reveal and shows the whole text
    -- after the delay.
    local typingSpeed = ctx.inputs.numbers[9]
    local typingDelay = math.max(ctx.inputs.numbers[8], 0.0)
    local elapsedSinceDelay = ctx.time - typingDelay

    if elapsedSinceDelay < 0.0 then
        typedCharacterLimit = 0.0
    elseif typingSpeed > 0.0 then
        typedCharacterLimit = elapsedSinceDelay * typingSpeed
    else
        -- No reveal: lift the limit so the whole text shows.
        typedCharacterLimit = -1.0
    end

    return typingSpeed, typingDelay
end

---Wraps the body text into the text area and places every character.
---Characters that do not fit, and those the typing has not reached, are
---hidden rather than skipped, so the lines do not re-flow as text arrives.
---@param ctx table OnLayout context
---@param data table measurements from measureBodyText
---@param sourceLineBaseY table baseline Y of each source line
---@param lineAdvance number vertical step between lines
---@param maxLines number how many lines fit in the area
---@return table placed characters, each with its final position and line
---@return number how many lines were used
---@return number how many characters are visible
local function wrapBodyText(ctx, data, sourceLineBaseY, lineAdvance, maxLines)
    local placedCharacters = {}
    local usedLineCount = 0
    local shownCharacterCount = 0

    -- Assign a line to every character first. Deciding the breaks up front is
    -- what lets a break move a whole word down: the alternative, placing as we
    -- go, would need to take characters back off the line once the word turns
    -- out not to fit.
    local lineOfCharacter = {}
    local targetLine = 1
    local lineStartIndex = nil
    local wordStartIndex = nil
    local previousIndex = nil
    local previousSourceLine = nil

    for i = FIRST_TEXT_CHARACTER, ctx.char_count do
        local info = data[i]
        local manualBreak = info.text == "\n"

        if previousSourceLine ~= nil and info.sourceLine ~= previousSourceLine then
            manualBreak = true
        end

        if manualBreak and lineStartIndex ~= nil then
            targetLine = targetLine + 1
            lineStartIndex = nil
            wordStartIndex = nil
            previousIndex = nil
        end

        previousSourceLine = info.sourceLine

        -- Newlines draw nothing, and a space that would open a line is dropped
        -- rather than indenting it.
        if info.text == "\n" or (info.text == " " and lineStartIndex == nil) then
            lineOfCharacter[i] = nil
        else
            local previousText = previousIndex ~= nil and data[previousIndex].text or nil

            -- Track where the current word began, so a break can carry it down.
            if lineStartIndex == nil or canBreakBefore(info.text, previousText) then
                wordStartIndex = i
            end

            -- Where this character's right edge would land if it joined the
            -- current line. The line is laid out from its first character's
            -- left edge, and the offsets come from the host's own advances, so
            -- Tracking and kerning are carried along.
            local overflows = false

            if lineStartIndex ~= nil then
                local originX = textLeft - data[lineStartIndex].leftFromAnchor * textScale
                local characterX = originX + (info.x - data[lineStartIndex].x) * textScale
                overflows = characterX + info.rightFromAnchor * textScale > textRight - RIGHT_MARGIN
            end

            if overflows then
                -- Move the whole word down, unless it started the line: a word
                -- too long for the area on its own still has to break.
                if wordStartIndex ~= nil and wordStartIndex > lineStartIndex then
                    for index = wordStartIndex, i - 1 do
                        lineOfCharacter[index] = nil
                    end

                    targetLine = targetLine + 1
                    lineStartIndex = wordStartIndex

                    for index = wordStartIndex, i do
                        if data[index].text ~= "\n" then
                            lineOfCharacter[index] = targetLine
                        end
                    end
                else
                    targetLine = targetLine + 1
                    lineStartIndex = i
                    lineOfCharacter[i] = targetLine
                end

                wordStartIndex = lineStartIndex
            else
                if lineStartIndex == nil then
                    lineStartIndex = i
                end

                lineOfCharacter[i] = targetLine
            end

            previousIndex = i
        end
    end

    -- Now place each character on the line it was assigned, laying every line
    -- out from its own left edge.
    local currentLine = nil
    local lineOriginIndex = nil
    local lineOriginX = nil

    for i = FIRST_TEXT_CHARACTER, ctx.char_count do
        local ch = ctx.chars[i]
        local info = data[i]
        local line = lineOfCharacter[i]

        if line == nil or line > maxLines then
            ch.opacity = 0.0
        else
            if line ~= currentLine then
                currentLine = line
                lineOriginIndex = i
                lineOriginX = textLeft - info.leftFromAnchor * textScale
            end

            local candidateX = lineOriginX + (info.x - data[lineOriginIndex].x) * textScale
            local candidateRight = candidateX + info.rightFromAnchor * textScale

            if candidateRight > textRight - RIGHT_MARGIN then
                ch.opacity = 0.0
            else
                -- The font's own vertical offset, which keeps punctuation and
                -- small kana from being flattened onto the baseline.
                local relativeY = (info.y - sourceLineBaseY[info.sourceLine]) * textScale

                -- Y is up, so each line after the first steps downward by one
                -- advance.
                local targetY = textTop - (line - 1) * lineAdvance + relativeY + uiOffsetY
                local finalX = candidateX + uiOffsetX

                -- Placed against textTop for now; the vertical alignment runs
                -- once every line is known.
                mt.layout.place_2d(ctx, ch, finalX, targetY)

                -- Characters whose turn has not come are only hidden, while
                -- placement and line breaking carry on. Wrapping on the
                -- visible characters alone would re-flow the lines on every
                -- new character.
                shownCharacterCount = shownCharacterCount + 1

                if typedCharacterLimit >= 0.0 and shownCharacterCount > typedCharacterLimit then
                    ch.opacity = 0.0
                end

                -- A space left at the end of a wrapped line draws nothing, so
                -- it must not count toward the line's right edge or right and
                -- centre alignment would push the visible text off by its
                -- width.
                local extent = info.rightFromAnchor * textScale

                if info.text == " " then
                    extent = -math.huge
                end

                placedCharacters[#placedCharacters + 1] = {
                    char = ch,
                    x = finalX,
                    y = targetY,
                    line = line,
                    rightFromAnchor = extent,
                }

                usedLineCount = math.max(usedLineCount, line)
            end
        end
    end

    return placedCharacters, usedLineCount, shownCharacterCount
end

---Shifts the wrapped text to honour the inspector's alignment on both axes.
---Wrapping can leave fewer and shorter lines than the area holds, so the
---leftover space is distributed to match.
---@param ctx table OnLayout context
---@param placedCharacters table output of wrapBodyText
---@param usedLineCount number how many lines were used
---@param lineAdvance number vertical step between lines
local function alignBodyText(ctx, placedCharacters, usedLineCount, lineAdvance)
    if usedLineCount <= 0 then
        return
    end

    -- The first line currently sits at textTop, so the block's height follows
    -- from the line count.
    local blockBottomY = textTop - (usedLineCount - 1) * lineAdvance
    local verticalSlack = blockBottomY - textBottom
    local verticalOffset = -verticalSlack * 0.5

    if ctx.global.v_align == "top" then
        verticalOffset = 0.0
    elseif ctx.global.v_align == "bottom" then
        verticalOffset = -verticalSlack
    end

    -- Measure each line's own right edge, so the horizontal slack can be
    -- distributed per line.
    local lineRightMost = {}

    for _, placed in ipairs(placedCharacters) do
        local lineRight = placed.x + placed.rightFromAnchor

        if lineRightMost[placed.line] == nil or lineRight > lineRightMost[placed.line] then
            lineRightMost[placed.line] = lineRight
        end
    end

    local textAreaRight = textRight - RIGHT_MARGIN

    for _, placed in ipairs(placedCharacters) do
        local horizontalSlack = textAreaRight - lineRightMost[placed.line]
        local horizontalOffset = 0.0

        if ctx.global.h_align == "right" then
            horizontalOffset = horizontalSlack
        elseif ctx.global.h_align == "center" then
            horizontalOffset = horizontalSlack * 0.5
        end

        mt.layout.place_2d(ctx, placed.char, placed.x + horizontalOffset, placed.y + verticalOffset)
    end
end

function OnLayout(ctx)
    if ctx.char_count < MARKER_CHARACTER then
        return
    end

    layoutWindow(ctx)
    layoutIcon(ctx)
    prepareMarker(ctx)

    local showMarker = ctx.inputs.numbers[10] >= MARKER_ENABLED_THRESHOLD

    -- With no body text there is nothing to wait for after the delay, so the
    -- marker takes the same pause it would have taken otherwise. It rests at
    -- its base position here rather than bobbing, since there is no dialogue
    -- to invite the reader through.
    if ctx.char_count < FIRST_TEXT_CHARACTER then
        local emptyTextDelay = math.max(ctx.inputs.numbers[8], 0.0) + MARKER_PAUSE_SECONDS

        if showMarker and ctx.time >= emptyTextDelay then
            local marker = ctx.chars[MARKER_CHARACTER]
            mt.layout.place_2d(ctx, marker, markerX + uiOffsetX, markerY + uiOffsetY)
            marker.opacity = 1.0
        end

        ctx.output.manual_order_text = "c1"

        return
    end

    local data, sourceLineBaseY = measureBodyText(ctx)
    styleBodyText(ctx)

    local lineAdvance = resolveLineAdvance(ctx)

    -- The first line sits at textTop, so this counts that line plus however
    -- many times the advance fits below it.
    local maxLines = math.max(1 + math.floor((textTop - textBottom) / lineAdvance), 1)

    local typingSpeed, typingDelay = resolveTypingProgress(ctx)

    local placedCharacters, usedLineCount, shownCharacterCount =
        wrapBodyText(ctx, data, sourceLineBaseY, lineAdvance, maxLines)

    alignBodyText(ctx, placedCharacters, usedLineCount, lineAdvance)

    -- The marker appears a fixed pause after the whole text is out. The time
    -- the text finishes follows from Speed, since the number of characters it
    -- can show is settled by this point.
    if showMarker then
        local textFinishedTime = typingDelay

        if typingSpeed > 0.0 then
            textFinishedTime = typingDelay + shownCharacterCount / typingSpeed
        end

        showMarkerAt(ctx, textFinishedTime + MARKER_PAUSE_SECONDS)
    end

    ctx.output.manual_order_text = "c1"
end

------------------------------------------------------------
-- PATH
------------------------------------------------------------

function OnPath(ctx)
    -- ctx.paths is rebuilt every frame, so the window has to be redrawn each
    -- time.
    for _, part in ipairs(ctx.paths:character(WINDOW_CHARACTER)) do
        part.path:clear()
        buildWindowPath(part.path, windowHalfWidthUnits, windowHalfHeightUnits, windowCornerUnits)
    end
end
