-- @MugTypography
-- @duration 5
-- @recommend text "Hello there!\nLovely day, isn't it?"
-- @title Speech Balloon
-- @author Mug
-- @version 1.4
-- @api_level 9
-- @input number 1 "Style (1=Speech 2=Thought)" default=1
-- @input number 2 "Tail Side (1=Left 2=Right)" default=1
-- @input number 3 "Tail Position (0-1 around edge)" default=0.25
-- @input number 4 "Padding X" default=1.0
-- @input number 5 "Padding Y" default=1.0
-- @input number 6 "Tail Width (em)" default=0.18
-- @input number 7 "Tail Length (em)" default=0.42
-- @input number 8 "Outline Width (em)" default=0.075
-- @input number 9 "Roundness (0-1)" default=0.5
-- @input number 10 "Pop Duration" default=0.45
-- @input color 1 "Balloon Fill" default={0.24, 0.28, 0.38, 1.0}
-- @input color 2 "Balloon Outline" default={0.72, 0.78, 0.94, 1.0}
--[[ @description
A speech or thought balloon pops in behind the text and auto-fits its width.
The tail travels anywhere around the outline. 2D only: 3D projection is forced off.
]]

local kStyleSpeech = 1
local kStyleThought = 2

-- Tail Side leans the tip along the outline. Position alone cannot say which way
-- the speaker stands from that point, so the two controls are independent.
local kSideLeft = 1
local kSideRight = 2

-- Tail Position walks the outline as a 0..1 loop, so the tail can point at a
-- speaker anywhere around the balloon. Path Y is down, so advancing the loop
-- travels clockwise on screen from the middle of the right edge: 0 is right,
-- 0.25 bottom, 0.5 left, 0.75 top.
local kTailPositionBottom = 0.25

-- Path coordinates are part-local, Y-down, with 1000 units per em.
local kUnitsPerEm = 1000.0

local kPaddingXEm = 0.55
local kPaddingYEm = 0.45
local kMinimumHalfWidthEm = 0.6
local kMinimumHalfHeightEm = 0.45
-- Roundness drives the corner radius here and the thought outline's squareness
-- and waviness on the other design, so one control reads the same either way:
-- low is boxy, high is soft. The ceiling reaches past what most balloons can
-- use; appendRoundedBody clamps the radius to half the shorter side, so a high
-- setting simply rounds the ends off completely instead of breaking the shape.
-- Three stops rather than two: the ceilings reach far enough that a plain
-- min-to-max ramp would leave the default nowhere near the shape this balloon
-- is tuned around. Roundness 0.5 lands on the middle stop, so the default look
-- is unchanged and the extra range is spent above it.
local kMinimumCornerRadiusEm = 0.0
local kDefaultCornerRadiusEm = 0.28
local kMaximumCornerRadiusEm = 2.0
-- Outline Width in em. Zero leaves the balloon unstroked; the ceiling keeps a
-- heavy outline from swallowing the corner radius.
local kMinimumOutlineWidthEm = 0.0
local kMaximumOutlineWidthEm = 0.4

-- How far the tail's base sits inside the body, in em. Fixed rather than exposed:
-- a straight edge needs almost none, but the outline curves away from the base
-- near a corner, and this is deep enough to bury that gap anywhere on the
-- outline. Any deeper only wastes tail length inside the balloon.
local kTailSinkEm = 0.3
-- Tail Width is the half-width of the base, in em, which is what sets how sharp
-- the tail looks: narrow gives a spike, wide gives a blunt wedge.
local kMinimumTailWidthEm = 0.03
local kMaximumTailWidthEm = 0.9
-- Tail Length is how far the tip reaches past the outline, in em.
local kMinimumTailLengthEm = 0.05
-- Below this animated length the tail is inside the body and not worth drawing.
local kMinimumVisibleTailEm = 0.001
local kMaximumTailLengthEm = 4.0
-- How far the tip leans along the outline, as a fraction of the tail length.
local kTailLeanRatio = 0.55
-- Line segments used to trace the thought body, whose wobble has no closed form.
local kOutlineSegmentCount = 96

-- Superellipse exponent for the thought body. 2 is a plain ellipse; higher
-- values square it up, filling the corners the text reaches into. Kept well
-- below the point where the outline reads as a rectangle.
-- Exponent range for the thought body, ordered so Roundness reads the same as
-- it does for corners: a low setting gives the high exponent that squares the
-- outline up, a high setting relaxes it toward an ellipse.
local kThoughtSquareExponent = 12.0
local kThoughtDefaultExponent = 2.8
local kThoughtRoundExponent = 1.6
-- Padding factor still needed on top of the superellipse to clear its corners.
local kEllipseInscribeRatio = 1.08
-- Bulge depth as a fraction of the balloon's smaller half-axis.
-- Wobble depth at the extremes of Roundness. A squared-up outline with deep
-- waves reads as damage rather than as a drawn line, so the ripple grows with
-- the roundness that gives it room.
local kThoughtMinimumWobbleRatio = 0.0
local kThoughtDefaultWobbleRatio = 0.075
local kThoughtMaximumWobbleRatio = 0.22
local kThoughtDotRadiiEm = { 0.13, 0.09, 0.055 }
local kThoughtDotDropEm = 0.16
-- Divisors that map the tail controls onto the dot trail. Both are the tail's
-- own default over the dot value it should reproduce, so the default Length and
-- Width give the trail the spacing and size it had as fixed constants.
local kTailLengthToDotGap = 3.82
local kTailWidthAtDotUnitScale = 0.18

-- Point in the pop where the text starts appearing, as a fraction of it. The
-- balloon is near full size well before the pop settles, so the text can begin
-- while it is still growing; waiting for the end leaves a beat of empty
-- balloon, and starting much earlier lets the text outrun the shape and spill.
local kTextRevealStart = 0.05
-- The balloon must reach this scale before the text begins to show. Below it the
-- glyphs would be too small to read as text even though they still fit.
local kTextRevealMinimumScale = 0.55
-- How much faster the fade runs than the rise. Both are driven by the same
-- reveal progress, so this closes the gap after the balloon without moving the
-- glyphs any earlier.
local kTextFadeLead = 2.5
local kTextRevealStagger = 0.05
-- Reveal span as a fraction of the pop, floored so a near-instant pop still
-- fades rather than snapping.
local kTextRevealSpan = 0.66
local kMinimumRevealDuration = 0.12
local kTextRiseEm = 0.12
-- Fraction of the outro spent clearing the text before the balloon starts to
-- shrink. Collapsing both at once would leave the text hanging outside the
-- balloon as it closes, so the outro plays the intro's order in reverse. The
-- balloon's own span starts slightly inside this one so the two cross-fade
-- instead of leaving an empty balloon on screen between them.
local kOutroTextFraction = 0.55
local kOutroOverlap = 0.35
local kFallbackClipLength = 5.0
local kMinimumPopDuration = 0.05
local kCircleControlRatio = 0.5523
-- A pivot field of 0.5 means no displacement from the global position.
local kPivotNeutral = 0.5
-- Roundness value that reproduces the balloon's tuned defaults.
local kRoundnessMidpoint = 0.5

-- The balloon reaches full opacity a third of the way through the pop (see the
-- opacity ramp in OnLayout), so the tail waits until then to start growing.
local kTailGrowthDelay = 1.0 / 3.0
-- Share of the text's outro span the tail takes to retract, so it is gone well
-- before the balloon's own span opens and the body starts to fade.
local kTailRetreatFraction = 0.5

-- The balloon glyphs are prepended, so their indices are fixed: body, tail,
-- then the user's text.
local kBalloonCharacterIndex = 1
local kTailCharacterIndex = 2
local kFirstTextIndex = 3

local balloonMarker = ""
local tailMarker = ""
local balloonTailWidthEm = 0.18
local balloonTailLengthEm = 0.42
local balloonOutlineWidthEm = 0.075
-- Derived from Roundness in OnLayout and read while building the outline.
local balloonRoundness = 0.5
local balloonThoughtExponent = 2.8
local balloonThoughtWobble = 0.075
-- Global transform captured in OnPreLayout, where it is readable.
local globalScale = 1.0
local globalStretchX = 1.0
local globalStretchY = 1.0
local globalRotation = 0.0
local globalPivotX = 0.5
local globalPivotY = 0.5

-- Recomputed every frame in OnLayout and consumed by OnPath.
local balloonHalfWidthUnits = kMinimumHalfWidthEm * kUnitsPerEm
local balloonHalfHeightUnits = kMinimumHalfHeightEm * kUnitsPerEm
local balloonCornerRadiusUnits = kDefaultCornerRadiusEm * kUnitsPerEm
local balloonStyle = kStyleSpeech
local balloonTailSide = kSideRight
local balloonTailPosition = kTailPositionBottom

--- Maps a 0..1 control onto three stops, with 0.5 landing exactly on `middle`.
--- Lets a control keep its tuned default while reaching much further at one end.
local function lerpThroughMiddle(low, middle, high, amount)
    local result
    if amount <= kRoundnessMidpoint then
        result = mt.lerp(low, middle, amount / kRoundnessMidpoint)
    else
        result = mt.lerp(middle, high, (amount - kRoundnessMidpoint) / (1.0 - kRoundnessMidpoint))
    end
    return result
end

--- Samples the rounded-rectangle outline at a 0..1 loop position.
--- Returns the point on the outline and the outward unit normal there.
local function roundedRectanglePoint(position, halfWidth, halfHeight, radius)
    local cornerRadius = math.min(radius, math.min(halfWidth, halfHeight))
    local straightWidth = math.max(halfWidth * 2.0 - cornerRadius * 2.0, 0.0)
    local straightHeight = math.max(halfHeight * 2.0 - cornerRadius * 2.0, 0.0)
    local quarterArc = math.pi * 0.5 * cornerRadius
    local perimeter = straightWidth * 2.0 + straightHeight * 2.0 + quarterArc * 4.0

    -- Walk the outline clockwise from the middle of the right edge. Each segment
    -- consumes its own arc length so the position stays proportional all the way
    -- around instead of bunching up at the corners.
    local travelled = (position - math.floor(position)) * perimeter
    local x = halfWidth
    local y = 0.0
    local normalX = 1.0
    local normalY = 0.0

    local lowerRightEdge = straightHeight * 0.5
    local bottomRightCorner = lowerRightEdge + quarterArc
    local bottomEdge = bottomRightCorner + straightWidth
    local bottomLeftCorner = bottomEdge + quarterArc
    local leftEdge = bottomLeftCorner + straightHeight
    local topLeftCorner = leftEdge + quarterArc
    local topEdge = topLeftCorner + straightWidth
    local topRightCorner = topEdge + quarterArc

    if travelled < lowerRightEdge then
        y = travelled
    elseif travelled < bottomRightCorner then
        local angle = (travelled - lowerRightEdge) / math.max(quarterArc, 1e-9) * math.pi * 0.5
        x = halfWidth - cornerRadius + math.cos(angle) * cornerRadius
        y = halfHeight - cornerRadius + math.sin(angle) * cornerRadius
        normalX = math.cos(angle)
        normalY = math.sin(angle)
    elseif travelled < bottomEdge then
        x = halfWidth - cornerRadius - (travelled - bottomRightCorner)
        y = halfHeight
        normalX = 0.0
        normalY = 1.0
    elseif travelled < bottomLeftCorner then
        local angle = (travelled - bottomEdge) / math.max(quarterArc, 1e-9) * math.pi * 0.5
        x = -halfWidth + cornerRadius - math.sin(angle) * cornerRadius
        y = halfHeight - cornerRadius + math.cos(angle) * cornerRadius
        normalX = -math.sin(angle)
        normalY = math.cos(angle)
    elseif travelled < leftEdge then
        x = -halfWidth
        y = halfHeight - cornerRadius - (travelled - bottomLeftCorner)
        normalX = -1.0
        normalY = 0.0
    elseif travelled < topLeftCorner then
        local angle = (travelled - leftEdge) / math.max(quarterArc, 1e-9) * math.pi * 0.5
        x = -halfWidth + cornerRadius - math.cos(angle) * cornerRadius
        y = -halfHeight + cornerRadius - math.sin(angle) * cornerRadius
        normalX = -math.cos(angle)
        normalY = -math.sin(angle)
    elseif travelled < topEdge then
        x = -halfWidth + cornerRadius + (travelled - topLeftCorner)
        y = -halfHeight
        normalX = 0.0
        normalY = -1.0
    elseif travelled < topRightCorner then
        local angle = (travelled - topEdge) / math.max(quarterArc, 1e-9) * math.pi * 0.5
        x = halfWidth - cornerRadius + math.sin(angle) * cornerRadius
        y = -halfHeight + cornerRadius - math.cos(angle) * cornerRadius
        normalX = math.sin(angle)
        normalY = -math.cos(angle)
    else
        y = -(perimeter - travelled)
    end

    return x, y, normalX, normalY
end

--- Radial bulge of the thought outline at an angle. Two out-of-phase harmonics
--- keep the outline from looking mechanical.
local function thoughtBulge(angle, radius)
    -- Proportional to the balloon, not a fixed em: a multi-line balloon is far
    -- taller than a single line, and a constant bulge disappears into it,
    -- leaving what should be a hand-drawn cloud looking like a plain ellipse.
    local wobble = radius * balloonThoughtWobble
    return math.sin(angle * 5.0) * wobble + math.sin(angle * 3.0 + 1.1) * wobble * 0.6
end

--- Samples the thought outline at a 0..1 loop position, mirroring
--- roundedRectanglePoint's contract so both styles share the tail placement.
local function thoughtOutlinePoint(position, halfWidth, halfHeight)
    local angle = (position - math.floor(position)) * math.pi * 2.0
    -- Gauge the bulge on the smaller axis so a wide balloon does not get a
    -- wobble too coarse for its height.
    local bulge = thoughtBulge(angle, math.min(halfWidth, halfHeight))

    -- A superellipse rather than a plain ellipse: raising the exponent pushes
    -- the sides out toward the bounding box, so the corners clear the text
    -- without having to inflate the whole balloon to reach them.
    local cosine = math.cos(angle)
    local sine = math.sin(angle)
    local shapedX = (math.abs(cosine) ^ balloonThoughtExponent)
    local shapedY = (math.abs(sine) ^ balloonThoughtExponent)
    local radius = (shapedX + shapedY) ^ (-1.0 / balloonThoughtExponent)
    local x = cosine * radius * (halfWidth + bulge)
    local y = sine * radius * (halfHeight + bulge)

    -- Outward normal of the superellipse: the gradient of |x/a|^n + |y/b|^n,
    -- which flattens along the straightened sides just as the outline does.
    local exponent = balloonThoughtExponent
    local normalX = (math.abs(cosine * radius) ^ (exponent - 1.0)) / halfWidth
    local normalY = (math.abs(sine * radius) ^ (exponent - 1.0)) / halfHeight
    normalX = cosine >= 0.0 and normalX or -normalX
    normalY = sine >= 0.0 and normalY or -normalY
    local length = math.sqrt(normalX * normalX + normalY * normalY)
    if length > 1e-9 then
        normalX = normalX / length
        normalY = normalY / length
    else
        normalX = 1.0
        normalY = 0.0
    end

    return x, y, normalX, normalY
end

--- Samples whichever outline the current style draws.
local function balloonOutlinePoint(position, halfWidth, halfHeight, radius, style)
    if style == kStyleThought then
        return thoughtOutlinePoint(position, halfWidth, halfHeight)
    end
    return roundedRectanglePoint(position, halfWidth, halfHeight, radius)
end

--- Draws the thought body as a plain closed loop, sampled from the same outline
--- the dots are placed against.
local function appendThoughtOutline(path, halfWidth, halfHeight)
    for step = 0, kOutlineSegmentCount - 1 do
        local x, y = thoughtOutlinePoint(step / kOutlineSegmentCount, halfWidth, halfHeight)
        if step == 0 then
            path:move_to(x, y)
        else
            path:line_to(x, y)
        end
    end
    path:close()
end


--- Draws the rounded-rectangle body as its own closed outline.
local function appendRoundedBody(path, halfWidth, halfHeight, radius)
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

--- Draws the tail as a triangle straddling the outline at `position`, rising
--- along the outward normal and leaning toward `side`.
---
--- The tail lives in its own glyph, overlapping the body rather than being
--- stitched into it. Their shared mouth is stroked, but the body's fill is
--- painted afterwards (see ctx.global.stroke.order) and covers it, so only the
--- outer silhouette shows. The base is sunk into the body by a fixed amount,
--- which also pulls the join clear of the anti-aliased edge where a sliver of
--- that stroke can otherwise peek through.
local function appendSpeechTail(path, halfWidth, halfHeight, radius, position, side, style, widthEm, lengthEm)
    local baseHalf = widthEm * kUnitsPerEm
    local drop = lengthEm * kUnitsPerEm
    local sink = kTailSinkEm * kUnitsPerEm

    local anchorX, anchorY, normalX, normalY =
        balloonOutlinePoint(position, halfWidth, halfHeight, radius, style)
    local tangentX = -normalY
    local tangentY = normalX

    -- Lean along screen X, not along the tangent: the tangent turns with the
    -- outline, so on the top edge it points the opposite way and "Left" would
    -- send the tip right. Flipping the tangent to face the requested side keeps
    -- the control meaning the same thing wherever the tail sits.
    -- +1 walks the tangent toward screen right, -1 toward screen left.
    local wantsRight = side == kSideRight
    local tangentFacesRight = tangentX >= 0.0
    local towardSide = (tangentFacesRight == wantsRight) and 1.0 or -1.0

    -- The tip is measured from the outline itself, so pushing the base inward
    -- does not drag the tail's reach along with it.
    local tipX = anchorX + normalX * drop + tangentX * towardSide * drop * kTailLeanRatio
    local tipY = anchorY + normalY * drop + tangentY * towardSide * drop * kTailLeanRatio

    -- Sink the base along the inward normal. On a straight edge the base already
    -- lies flush, but around a corner the outline curves away from it and the
    -- two shapes read as separate; pushing the base inside buries that gap.
    local baseX = anchorX - normalX * sink
    local baseY = anchorY - normalY * sink

    path:move_to(baseX - tangentX * baseHalf, baseY - tangentY * baseHalf)
    path:line_to(baseX + tangentX * baseHalf, baseY + tangentY * baseHalf)
    path:line_to(tipX, tipY)
    path:close()
end

local function appendCircle(path, centerX, centerY, radius)
    local control = radius * kCircleControlRatio
    path:move_to(centerX, centerY - radius)
    path:cubic_to(
        centerX + control, centerY - radius,
        centerX + radius, centerY - control,
        centerX + radius, centerY)
    path:cubic_to(
        centerX + radius, centerY + control,
        centerX + control, centerY + radius,
        centerX, centerY + radius)
    path:cubic_to(
        centerX - control, centerY + radius,
        centerX - radius, centerY + control,
        centerX - radius, centerY)
    path:cubic_to(
        centerX - radius, centerY - control,
        centerX - control, centerY - radius,
        centerX, centerY - radius)
    path:close()
end

--- Trails the thought dots away from `position` on the outline, following the
--- same outward-and-leaning direction the speech tail uses.
local function appendThoughtDots(path, halfWidth, halfHeight, position, side, widthEm, lengthEm)
    local lean = side == kSideLeft and 1.0 or -1.0
    -- The two tail controls carry over to this style: Length spaces the dots and
    -- Width scales them. Both are divided by the defaults that produced the
    -- original trail, so the two designs start at the same visual weight and a
    -- given setting reads the same after switching between them.
    local gap = lengthEm / kTailLengthToDotGap * kUnitsPerEm
    local dotScale = widthEm / kTailWidthAtDotUnitScale

    local anchorX, anchorY, normalX, normalY = thoughtOutlinePoint(position, halfWidth, halfHeight)
    local tangentX = -normalY
    local tangentY = normalX

    -- Blend the outward normal with the lean into one travel direction, so the
    -- dots march away from the balloon toward the speaker.
    local travelX = normalX + tangentX * lean * kTailLeanRatio
    local travelY = normalY + tangentY * lean * kTailLeanRatio
    local travelLength = math.sqrt(travelX * travelX + travelY * travelY)
    if travelLength > 1e-9 then
        travelX = travelX / travelLength
        travelY = travelY / travelLength
    end

    local distance = kThoughtDotDropEm * kUnitsPerEm
    for _, radiusEm in ipairs(kThoughtDotRadiiEm) do
        local radius = radiusEm * dotScale * kUnitsPerEm
        distance = distance + radius + gap * 0.5
        appendCircle(path, anchorX + travelX * distance, anchorY + travelY * distance, radius)
        distance = distance + radius + gap * 0.5
    end
end

function OnPreLayout(ctx)
    -- Paint every fill after every stroke. The tail is its own glyph laid over
    -- the body, so their shared mouth would otherwise be stroked across the
    -- balloon; drawing fills last lets the body cover that seam. The setting is
    -- global, so the text cannot carry an outline of its own.
    ctx.global.stroke.order = "fill_over_stroke"

    -- Round joins throughout: the balloon is the only stroked shape here, and its
    -- corners and the tail's tip read better rounded than mitred, where a sharp
    -- join would throw a spike well past the outline at a thick width.
    ctx.global.stroke.join = "round"

    -- Zero bounds keep the balloon out of the box that h_align / v_align measure,
    -- and zero advance keeps it from occupying space on the line it leads. Any
    -- advance here would indent the first line only, which reads as the text
    -- losing its alignment on every setting except right.
    balloonMarker = ctx.glyphs:declare({
        path = mt.drawing_path(),
        advance_x = 0,
        advance_y = 0,
        bounds = { 0, 0, 0, 0 },
    })
    -- A second glyph makes the tail a separate part, which is what lets the
    -- body's fill paint over the tail's stroke. Two sub-paths inside one part
    -- would be stroked and filled together, leaving the seam visible.
    tailMarker = ctx.glyphs:declare({
        path = mt.drawing_path(),
        advance_x = 0,
        advance_y = 0,
        bounds = { 0, 0, 0, 0 },
    })
    -- Prepended, not appended: paint order follows layout order, so putting the
    -- balloon glyphs first puts them behind the text without relying on a manual
    -- order that behaves differently under 2D and 3D.
    ctx.global.text = balloonMarker .. tailMarker .. ctx.global.text

    -- Tracking is added after every character, including the two balloon glyphs,
    -- so the line they lead would start indented by that much however zero their
    -- advances are. Cancel it with a negative margin on each of them, leaving the
    -- first line aligned with the rest.
    local margins = {}
    margins[kBalloonCharacterIndex] = -ctx.global.tracking
    margins[kTailCharacterIndex] = -ctx.global.tracking
    ctx.global.margins = margins

    -- font.em_size is an untransformed metric while measure_bounds_2d reports
    -- canvas bounds with the Global transform applied, so record that transform
    -- here to bring the two onto equal terms. These are overwritten every frame
    -- rather than accumulated.
    globalScale = ctx.global.scale
    globalStretchX = ctx.global.stretch_x
    globalStretchY = ctx.global.stretch_y

    -- measure_bounds_2d returns canvas-axis-aligned bounds, so under rotation it
    -- reports the box the text sweeps out instead of the text's own extent, and
    -- the balloon would be sized to that swept box. The swept box cannot be
    -- solved back into the real extent either, because it encloses many
    -- separately rotated characters rather than one rotated rectangle. Measure
    -- with rotation removed instead, and hand it to the character transform in
    -- OnLayout so the balloon and the text still turn together.
    globalRotation = ctx.global.rotation
    ctx.global.rotation = 0.0

    -- Global rotation turns about the global position offset by the pivot, where
    -- a pivot of 0.5 means no displacement. Reproducing the rotation by hand
    -- means orbiting that same point, not the canvas center.
    globalPivotX = ctx.global.position_x + (ctx.global.pivot_x - kPivotNeutral)
    globalPivotY = ctx.global.position_y + (ctx.global.pivot_y - kPivotNeutral)
end

function OnLayout(ctx)
    balloonStyle = math.floor(mt.clamp(ctx.inputs.numbers[1], kStyleSpeech, kStyleThought) + 0.5)
    balloonTailSide = math.floor(mt.clamp(ctx.inputs.numbers[2], kSideLeft, kSideRight) + 0.5)
    -- Wraps rather than clamps, so a keyframe can sweep the tail past an edge and
    -- keep going around the balloon.
    balloonTailPosition = ctx.inputs.numbers[3] % 1.0

    local paddingScaleX = math.max(ctx.inputs.numbers[4], 0.0)
    local paddingScaleY = math.max(ctx.inputs.numbers[5], 0.0)
    balloonTailWidthEm =
        mt.clamp(ctx.inputs.numbers[6], kMinimumTailWidthEm, kMaximumTailWidthEm)
    -- The configured length; the animated portion is applied once the pop
    -- progress is known.
    local tailLengthEm =
        mt.clamp(ctx.inputs.numbers[7], kMinimumTailLengthEm, kMaximumTailLengthEm)
    balloonOutlineWidthEm =
        mt.clamp(ctx.inputs.numbers[8], kMinimumOutlineWidthEm, kMaximumOutlineWidthEm)
    balloonRoundness = mt.saturate(ctx.inputs.numbers[9])
    balloonThoughtExponent = lerpThroughMiddle(
        kThoughtSquareExponent, kThoughtDefaultExponent, kThoughtRoundExponent, balloonRoundness)
    balloonThoughtWobble = lerpThroughMiddle(
        kThoughtMinimumWobbleRatio, kThoughtDefaultWobbleRatio, kThoughtMaximumWobbleRatio,
        balloonRoundness)
    local popDuration = math.max(ctx.inputs.numbers[10], kMinimumPopDuration)

    -- The balloon only animates over the tail end of the outro (everything past
    -- balloonOutroStart), so a fixed outro span would run it faster than the pop
    -- that opened it. Stretch the span until the balloon's share matches the pop
    -- and the exit takes as long as the entrance.
    -- Reveal timing, shared by the intro and its mirrored outro.
    local revealStartSeconds = popDuration * kTextRevealStart
    local revealDurationSeconds =
        math.max(popDuration * kTextRevealSpan, kMinimumRevealDuration)

    local balloonOutroStart = kOutroTextFraction - kOutroOverlap
    local outroDuration = popDuration / (1.0 - balloonOutroStart)
    local _, outroAmount =
        mt.timeline.intro_outro_seconds(ctx, popDuration, outroDuration, kFallbackClipLength)

    -- Mirror the intro's reveal rather than splitting the outro by a fixed
    -- fraction: the text takes the same share of the span it took on the way in,
    -- measured from the end, so the two ends read as reverses of each other. A
    -- fixed fraction pulled the text off screen well before its entrance timing
    -- would suggest.
    local outroSeconds = outroAmount * outroDuration
    local textOutroStartSeconds =
        math.max(outroDuration - revealStartSeconds - revealDurationSeconds, 0.0)
    local textOutroAmount =
        mt.saturate((outroSeconds - textOutroStartSeconds) / revealDurationSeconds)
    local balloonOutroAmount =
        mt.saturate((outroAmount - balloonOutroStart) / (1.0 - balloonOutroStart))

    local balloonCharacter = ctx.chars[kBalloonCharacterIndex]
    local tailCharacter = ctx.chars[kTailCharacterIndex]
    local textCharacterCount = math.max(ctx.char_count - kFirstTextIndex + 1, 0)

    -- One em expressed in normalized canvas units on each axis. Canvas X and Y
    -- are normalized by different physical lengths, so the aspect ratio converts
    -- between them and keeps the balloon from stretching on a wide project.
    -- font.em_size is an untransformed em normalized by canvas height, so fold
    -- the Global transform back in to get the canvas length one em actually
    -- covers. Without this the balloon keeps its unscaled size while the text
    -- grows, and the two drift apart.
    local baseEmToCanvasY = ctx.font.em_size
    local emToCanvasY = baseEmToCanvasY * globalScale * globalStretchY
    local emToCanvasX = baseEmToCanvasY / ctx.canvas.aspect_ratio * globalScale * globalStretchX

    local popProgress = mt.saturate(ctx.time / popDuration)
    local popScale = mt.ease.out_back(popProgress)
    -- in_back mirrors the pop: the balloon gathers itself slightly larger before
    -- collapsing, so the exit answers the entrance instead of just deflating.
    local outroScale = 1.0 - mt.ease.in_back(balloonOutroAmount)
    local balloonScale = math.max(popScale * outroScale, 0.0)

    for index = kFirstTextIndex, ctx.char_count do
        local character = ctx.chars[index]
        local position = index - kFirstTextIndex
        local order = textCharacterCount > 1 and position / (textCharacterCount - 1) or 0.0
        local revealDelay = revealStartSeconds + order * kTextRevealStagger
        local reveal = mt.saturate((ctx.time - revealDelay) / revealDurationSeconds)
        local eased = mt.ease.out_cubic(reveal)

        -- Opacity leads the movement so the text registers as soon as the balloon
        -- has something to hold, closing the beat of empty balloon without
        -- starting the glyphs any earlier than the shape can contain them.
        -- Gated on the balloon having grown past a readable size: riding its
        -- scale keeps the text contained, but below this the glyphs are specks
        -- and reveal as visual noise rather than as text.
        local sizeGate = mt.saturate(
            (balloonScale - kTextRevealMinimumScale) / (1.0 - kTextRevealMinimumScale))
        local fadeIn = mt.saturate(reveal * kTextFadeLead) * sizeGate

        character.offset_x = 0.5
        character.offset_y = 0.5 + (1.0 - eased) * kTextRiseEm * emToCanvasY
        -- The fade out mirrors the fade in. The lead that makes the intro rush
        -- to full opacity is deliberately not repeated here: the outro window is
        -- already positioned to match, and leading it again would pull the text
        -- off early -- the very thing this timing exists to avoid.
        character.opacity = fadeIn * (1.0 - textOutroAmount)
    end

    -- Measure the text alone; including the balloon would feed its own size back
    -- into the fit and make it grow every frame.
    local textIndices = {}
    for index = kFirstTextIndex, ctx.char_count do
        textIndices[#textIndices + 1] = index
    end
    local textBounds = mt.layout.measure_bounds_2d(ctx, textIndices)

    -- Only now scale the text down with the balloon. Doing it before the measure
    -- would feed the shrunken text back into the fit, so the balloon would be
    -- built small and then scaled small again -- shrinking twice while the pop
    -- ran. The balloon is sized to the settled text and both reach it together.
    --
    -- Follows the overshoot rather than clamping at 1: the pop swells past full
    -- size and eases back, and text held at 1 through that would sit still while
    -- the balloon around it moved. Both carry the same factor, so the text stays
    -- inside the balloon at every point of the curve.
    local textScale = balloonScale
    for index = kFirstTextIndex, ctx.char_count do
        local character = ctx.chars[index]
        character.scale = character.scale * textScale
    end

    -- Scale alone leaves the advances at their full-size widths, so the line
    -- would keep its settled length while the glyphs shrank and would still
    -- overhang the small balloon. Re-typeset so the spacing follows the scale.
    --
    -- Anchor each line on its middle character: reflow otherwise pins the first
    -- one, and the line would collapse toward its left edge instead of toward
    -- its center, carrying the text off the balloon it is centred in. The anchor
    -- applies to one line, so every line is reflowed on its own.
    -- Reflow only closes up a line's own advances; the gap between lines keeps
    -- its full-size height, so a shrinking block would stay as tall as ever and
    -- overflow the balloon vertically. Pull each line toward the block's centre
    -- by the same factor the glyphs shrank.
    local blockBefore = mt.layout.measure_bounds_2d(ctx, textIndices)

    -- Which edge the host holds fixed, so the drift correction below can hold the
    -- same one instead of always recentring.
    local horizontalAlignment = ctx.global.h_align

    -- targets restricts each call to one line. Passing only an anchor would
    -- still reflow every line, pinning the others to their first character, and
    -- each call would undo the previous one's centering.
    for _, line in ipairs(mt.layout.group_by_line(ctx)) do
        local targets = {}
        for _, character in ipairs(line.items) do
            if character.index >= kFirstTextIndex then
                targets[#targets + 1] = character.index
            end
        end
        if #targets > 0 then
            -- Anchor the line on the character sitting at the edge the alignment
            -- holds fixed. Reflow keeps that character's origin exactly where it
            -- is and rebuilds the rest around it, so every line pivots about the
            -- same margin the host aligned it to and none of them drift apart as
            -- the text scales. A mid-line anchor would instead leave each line
            -- pinned at its own middle, which differs per line once the lines
            -- have different lengths.
            local anchorIndex
            if horizontalAlignment == "left" then
                anchorIndex = targets[1]
            elseif horizontalAlignment == "right" then
                anchorIndex = targets[#targets]
            else
                anchorIndex = targets[math.ceil(#targets / 2)]
            end

            local before = mt.layout.measure_bounds_2d(ctx, targets)
            mt.layout.reflow(ctx, 0.0, { targets = targets, anchor = anchorIndex })

            -- Centre alignment still needs the nudge: its anchor can only be a
            -- whole character, so on an odd count it sits half a glyph off the
            -- true centre and the line creeps as it scales.
            if horizontalAlignment ~= "left" and horizontalAlignment ~= "right" then
                local after = mt.layout.measure_bounds_2d(ctx, targets)
                if before ~= nil and after ~= nil then
                    local drift = after.center_x - before.center_x
                    for _, index in ipairs(targets) do
                        local character = ctx.chars[index]
                        character.offset_x = character.offset_x - drift
                    end
                end
            end
        end
    end

    -- Now scale the leading: each line moves toward or away from the block centre
    -- by the same factor the glyphs took, so the block scales as a whole instead
    -- of only tightening within each line. This runs above 1 as well -- the pop
    -- overshoots past full size, and skipping it there would hold the lines at
    -- their settled spacing while the balloon around them kept swelling.
    if blockBefore ~= nil then
        for _, line in ipairs(mt.layout.group_by_line(ctx)) do
            local targets = {}
            for _, character in ipairs(line.items) do
                if character.index >= kFirstTextIndex then
                    targets[#targets + 1] = character.index
                end
            end
            local lineBounds = #targets > 0 and mt.layout.measure_bounds_2d(ctx, targets) or nil
            if lineBounds ~= nil then
                local shift = (lineBounds.center_y - blockBefore.center_y) * (textScale - 1.0)
                for _, index in ipairs(targets) do
                    local character = ctx.chars[index]
                    character.offset_y = character.offset_y + shift
                end
            end
        end
    end

    local halfWidthEm = kMinimumHalfWidthEm
    local halfHeightEm = kMinimumHalfHeightEm
    local centerX = 0.5
    local centerY = 0.5

    if textBounds ~= nil and emToCanvasX > 0.0 then
        -- Rotation was zeroed in OnPreLayout, so these bounds are the text's own
        -- extent and need no correction.
        -- A rounded rectangle holds a text box out to its edges, but the thought
        -- outline is an ellipse and its corners cut inward, so the same padding
        -- lets the text escape at the diagonals -- worse the taller the block
        -- gets. Grow the half-axes so the text box inscribes the ellipse.
        local cornerFit = balloonStyle == kStyleThought and kEllipseInscribeRatio or 1.0

        halfWidthEm = math.max(
            textBounds.width / emToCanvasX * 0.5 * cornerFit + kPaddingXEm * paddingScaleX,
            kMinimumHalfWidthEm)
        halfHeightEm = math.max(
            textBounds.height / emToCanvasY * 0.5 * cornerFit + kPaddingYEm * paddingScaleY,
            kMinimumHalfHeightEm)
        centerX = textBounds.center_x
        centerY = textBounds.center_y
    end

    -- The tail is a separate part overlapping the body, so while either is
    -- translucent their overlap darkens and the two read as separate shapes.
    -- Grow the tail out of the body only once the body is fully opaque, and
    -- retract it before the balloon starts fading again, so the seam is never
    -- visible through them.
    local tailGrowth = mt.saturate((popProgress - kTailGrowthDelay) / (1.0 - kTailGrowthDelay))
    -- Measured against the whole outro, not the balloon's share of it: the
    -- balloon starts fading the moment its share opens, so a tail keyed to that
    -- same span would still be retracting once the body turns translucent.
    local tailRetreat = mt.saturate(outroAmount / (kOutroTextFraction * kTailRetreatFraction))
    balloonTailLengthEm = tailLengthEm * mt.ease.out_cubic(tailGrowth) * (1.0 - tailRetreat)

    -- Path units are em units: the Global scale matrix that maps them to the
    -- canvas is the same one that scales the text, so an em stays an em on both
    -- sides and no compensation belongs here. The path is always built at the
    -- fitted size and the character scale below carries the pop, so the balloon
    -- grows into place and settles flush against the text.
    balloonHalfWidthUnits = halfWidthEm * kUnitsPerEm
    balloonHalfHeightUnits = halfHeightEm * kUnitsPerEm
    balloonCornerRadiusUnits = lerpThroughMiddle(
        kMinimumCornerRadiusEm, kDefaultCornerRadiusEm, kMaximumCornerRadiusEm,
        balloonRoundness) * kUnitsPerEm

    -- Scale the balloon about the same edge the text holds. Both shrink during
    -- the pop, but the text pivots on its alignment margin while the balloon
    -- pivots on its own centre, so under left or right alignment the two move
    -- opposite ways and the text escapes the shape while it is still small.
    -- Offsetting the placement by the width the scale removes keeps that edge
    -- fixed for the balloon too.
    -- Hold the same edge the text holds. The balloon otherwise scales about its
    -- own centre while the text pivots on its alignment margin, so under left or
    -- right alignment the two move opposite ways and the text escapes the shape
    -- while it is still small.
    local halfWidthCanvas = balloonHalfWidthUnits / kUnitsPerEm * emToCanvasX
    local edgeShift = halfWidthCanvas * (1.0 - balloonScale)
    local placeX = centerX
    if horizontalAlignment == "left" then
        placeX = centerX - edgeShift
    elseif horizontalAlignment == "right" then
        placeX = centerX + edgeShift
    end

    -- Body and tail are drawn in the same part-local space, so they share one
    -- placement, scale and palette to stay attached. place_2d anchors a
    -- character by its ink-bounds center, which is where the path origin sits,
    -- so no extra centering offset is needed.
    local balloonOpacity = mt.saturate(popProgress * 3.0) * outroScale
    for _, character in ipairs({ balloonCharacter, tailCharacter }) do
        mt.layout.place_2d(ctx, character, placeX, centerY)
        character.scale = balloonScale
        character.opacity = balloonOpacity
        character.fill.use = true
        character.fill.color = ctx.inputs.colors[1]
        character.stroke.use = true
        character.stroke.color = ctx.inputs.colors[2]
        character.stroke.width = balloonOutlineWidthEm
    end

    -- Global rotation was zeroed so the text could be measured unrotated, so put
    -- it back per character here. Turning each character in place would spin the
    -- glyphs without moving the line, so their positions orbit the pivot as well,
    -- which is what the Global transform does.
    if globalRotation ~= 0.0 then
        local radians = math.rad(globalRotation)
        -- Canvas rotation is clockwise-positive while canvas Y grows upward, so
        -- the sine terms below carry the sign that pairing implies.
        local cosine = math.cos(radians)
        local sine = math.sin(radians)
        local aspectRatio = ctx.canvas.aspect_ratio

        for index = 1, ctx.char_count do
            local character = ctx.chars[index]
            local canvasX, canvasY = mt.layout.get_canvas_position_2d(ctx, character)
            -- Work in a square space so the orbit stays circular on a wide canvas.
            local offsetX = (canvasX - globalPivotX) * aspectRatio
            local offsetY = canvasY - globalPivotY
            local rotatedX = offsetX * cosine + offsetY * sine
            local rotatedY = -offsetX * sine + offsetY * cosine

            mt.layout.place_2d(
                ctx,
                character,
                globalPivotX + rotatedX / aspectRatio,
                globalPivotY + rotatedY)
            character.rotation = character.rotation + globalRotation
        end
    end

    -- This effect is 2D-only by contract. Under 3D the paint order follows view
    -- depth, and characters the rotation swings forward would push through the
    -- balloon; giving the balloon depth of its own is no fix, because the same
    -- perspective that separates it also shifts and shrinks it off the text it
    -- wraps. Disabling projection keeps the balloon and its text on one plane.
    ctx.output.force_disable_3d_projection = true
end

function OnPath(ctx)
    -- ctx.paths is rebuilt every frame, so both glyphs must be redrawn each time
    -- or the parts fall back to their empty declared outlines.
    for _, part in ipairs(ctx.paths:character(kBalloonCharacterIndex)) do
        part.path:clear()
        if balloonStyle == kStyleThought then
            appendThoughtOutline(part.path, balloonHalfWidthUnits, balloonHalfHeightUnits)
        else
            appendRoundedBody(
                part.path,
                balloonHalfWidthUnits,
                balloonHalfHeightUnits,
                balloonCornerRadiusUnits)
        end
    end

    for _, part in ipairs(ctx.paths:character(kTailCharacterIndex)) do
        part.path:clear()
        if balloonStyle == kStyleThought then
            -- A thought balloon trails detached dots toward the speaker instead
            -- of a tail, so the body stays a plain closed loop.
            appendThoughtDots(
                part.path,
                balloonHalfWidthUnits,
                balloonHalfHeightUnits,
                balloonTailPosition,
                balloonTailSide,
                balloonTailWidthEm,
                balloonTailLengthEm)
        elseif balloonTailLengthEm > kMinimumVisibleTailEm then
            -- A retracted tail is buried inside the body, so skip it entirely
            -- rather than emit a degenerate sliver.
            appendSpeechTail(
                part.path,
                balloonHalfWidthUnits,
                balloonHalfHeightUnits,
                balloonCornerRadiusUnits,
                balloonTailPosition,
                balloonTailSide,
                balloonStyle,
                balloonTailWidthEm,
                balloonTailLengthEm)
        end
    end
end
