-- @MugTypography
-- @duration 4
-- @title Fast Forward
-- @author Mug
-- @version 1.0
-- @api_level 9
-- @recommend text "x4"
-- @input number 1 "Speed" default=1.0
-- @input number 2 "Wait" default=0.33
-- @input number 3 "Mark Scale" default=1.0
-- @input number 4 "Mark Spacing" default=1.0
-- @input number 5 "Text Gap" default=1.0
-- @input number 6 "Active Scale" default=1.1
-- @input number 7 "Mark Outline" default=1.0
-- @input color 1 "Active Color" default={1.0, 1.00, 1.00, 1.0}
-- @input color 2 "Inactive Color" default={0.30, 0.34, 0.44, 1.0}
--[[ @description
A fast-forward mark whose triangles light up left to right, over and over,
with your text alongside it.
]]

local kFallbackClipLength = 4.0

local kTriangleCount = 3
local kBaseSweepDuration = 0.62
local kMinimumSpeed = 0.05
local kMaximumSpeed = 8.0
local kMaximumWait = 10.0

local kMinimumMarkScale = 0.1
local kMaximumMarkScale = 4.0
local kMinimumSpacing = 0.0
local kMaximumSpacing = 4.0

local kBandWidth = 0.1
local kBandOvertravel = 0.09
local kMinimumActiveScale = 0.2
local kMaximumActiveScale = 4.0
local kOutlineOnThreshold = 0.5

local kIntroDuration = 0.4
local kOutroDuration = 0.4

local kTriangleAdvance = 560
local kGapAfterMarkEm = 0.22
local trianglePath = mt.svg_path([[
M4 2
L20 12
L4 22
Z
]], {
    view_box = { 0, 0, 24, 24 },
    em_scale = 0.7,
})

function OnPreLayout(ctx)
    local markScale = mt.clamp(ctx.inputs.numbers[3], kMinimumMarkScale, kMaximumMarkScale)
    local spacing = mt.clamp(ctx.inputs.numbers[4], kMinimumSpacing, kMaximumSpacing)
    local textGap = mt.clamp(ctx.inputs.numbers[5], kMinimumSpacing, kMaximumSpacing)

    -- The advance follows the scale so the triangles keep their spacing as the
    -- mark grows, and Mark Spacing widens or tightens it from there.
    local advance = kTriangleAdvance * markScale * spacing
    local triangle = ctx.glyphs:declare({
        path = trianglePath,
        advance_x = advance,
        advance_y = -advance,
    })

    local caption = ctx.global.text
    ctx.global.text = string.rep(triangle, kTriangleCount) .. caption

    if caption ~= "" then
        local margins = {}
        for index = 1, kTriangleCount do
            margins[index] = (index == kTriangleCount)
                and (kGapAfterMarkEm * markScale * textGap) or 0.0
        end
        ctx.global.margins = margins
    end
end

function OnLayout(ctx)
    local introAmount, outroAmount =
        mt.timeline.intro_outro_seconds(ctx, kIntroDuration, kOutroDuration, kFallbackClipLength)
    local groupOpacity = mt.ease.out_cubic(introAmount) * (1.0 - mt.ease.in_cubic(outroAmount))

    local markEnd = math.min(kTriangleCount, ctx.char_count)
    local markLeft = math.huge
    local markRight = -math.huge
    for _, triangle in mt.each_char(ctx, { from = 1, to = markEnd }) do
        local centerX = triangle.geometry.bounds_center_x
        local halfWidth = triangle.geometry.bounds_width * 0.5
        markLeft = math.min(markLeft, centerX - halfWidth)
        markRight = math.max(markRight, centerX + halfWidth)
    end

    local speed = mt.clamp(ctx.inputs.numbers[1], kMinimumSpeed, kMaximumSpeed)
    local waitSeconds = mt.clamp(ctx.inputs.numbers[2], 0.0, kMaximumWait)
    local sweepSeconds = kBaseSweepDuration / speed
    local cycleSeconds = sweepSeconds + waitSeconds

    local sweepStart = markLeft - kBandOvertravel
    local sweepEnd = markRight + kBandOvertravel
    local timeInCycle = ctx.time % cycleSeconds
    local sweep = mt.saturate(timeInCycle / sweepSeconds)
    local bandCenterX = sweepStart + sweep * (sweepEnd - sweepStart)
    local resting = timeInCycle > sweepSeconds

    local activeColor = ctx.inputs.colors[1]
    local inactiveColor = ctx.inputs.colors[2]
    local markScale = mt.clamp(ctx.inputs.numbers[3], kMinimumMarkScale, kMaximumMarkScale)
    local activeScale = mt.clamp(ctx.inputs.numbers[6], kMinimumActiveScale, kMaximumActiveScale)
    local outlineEnabled = ctx.inputs.numbers[7] >= kOutlineOnThreshold

    for _, triangle in mt.each_char(ctx, { from = 1, to = markEnd }) do
        local distance = math.abs(triangle.geometry.bounds_center_x - bandCenterX)
        local lit = resting and 0.0 or (1.0 - mt.saturate(distance / kBandWidth))
        lit = lit * lit * (3.0 - 2.0 * lit)

        triangle.opacity = triangle.opacity * groupOpacity
        triangle.scale = triangle.scale * markScale * mt.lerp(1.0, activeScale, lit)
        triangle.fill.use = true
        triangle.fill.color = mt.color.lerp_oklab(inactiveColor, activeColor, lit)

        if not outlineEnabled then
            triangle.stroke.use = true
            triangle.stroke.width = 0.0
        end
    end

    for _, caption in mt.each_char(ctx, { from = markEnd + 1, to = ctx.char_count }) do
        caption.opacity = caption.opacity * groupOpacity
    end
end
