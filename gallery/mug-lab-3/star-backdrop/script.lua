-- @MugTypography
-- @duration 6.0
-- @title Star Backdrop
-- @author Mug
-- @version 1.0
-- @api_level 6
-- @recommend text "STARLIGHT"
-- @recommend bg #10152b
--[[ @description
Softly pulsing gold stars sit behind individual characters with automatic
spacing and full Inspector alignment, margin, and transform support.
]]

local kStarScale = 1.6
local kStarPhaseOffset = 0.13
-- Gap left between neighbouring stars, as a fraction of a star's own width.
-- The tracking that realises it is derived below, so resizing the star widens
-- the spacing to match instead of letting the stars collide.
local kStarGapRatio = 0.3825

local kIntroSeconds = 1.1
local kOutroSeconds = 0.5
-- Fraction of the intro spent distributing the per-star start times.
local kIntroStaggerSpan = 0.55
-- How far out the stars begin, as a fraction of the canvas.
local kIntroFlyDistance = 0.85
local kIntroSpinTurns = 540.0
-- Portion of each star's arrival spent growing to full size.
local kIntroGrowFraction = 0.35

-- A glint that sweeps across the row while the text is still hidden, filling
-- the gap between the last star landing and the text appearing.
local kGlintSeconds = 0.5
-- Fraction of the sweep each star spends lit; the rest is its wait to be lit.
local kGlintWidth = 0.45
local kGlintScale = 0.22
local kGlintSpin = 26.0
local kGlintStrokeGrowth = 1.4
local kGlintColor = { r = 1.0, g = 1.0, b = 0.95, a = 1.0 }
-- Pause after the text is fully visible before the drift creeps in.
local kIdleStartDelaySeconds = 0.3
local kIdleFadeInSeconds = 0.8

-- The idle phase is a slow drift rather than a pulse, so the stars stay legible
-- behind the text.
local kIdleSwayAmount = 0.004
local kIdleSwayFrequency = 0.19
local kIdleTiltAmount = 3.5
local kIdleTiltFrequency = 0.13
local kIdleScaleAmount = 0.02
local kIdleScaleFrequency = 0.22

local kOutroBurstScale = 1.9
local kOutroSpinTurns = 180.0
-- Fraction of the outro spent dipping inward before the pop.
local kOutroAnticipation = 0.45
local kOutroSquashAmount = 0.12
-- Point in the outro where the pop has fully finished.
local kOutroBurstEnd = 0.9
-- Stars scatter outward from the text centre as they burst.
local kOutroFlyDistance = 0.35
-- Per-star direction mixed into the burst so the centre star also travels.
local kOutroScatter = 0.35
local kStarOuterRadius = 500.0
local kStarInnerRadius = 220.0
local kStarPointCount = 5
local kHalfTurn = math.pi
local kPathUnitsPerEm = 1000.0

-- Widest span of the star outline, in path units: the two points either side of
-- the bottom reach furthest out, at sin(72 degrees) of the outer radius.
local kStarWidthInPathUnits = 2.0
    * math.sin(kHalfTurn * 2.0 / kStarPointCount)
    * kStarOuterRadius
-- Zero point for the Inspector Tracking knob, derived from the star's own width
-- so neighbours keep the same relative gap at any star size.
local kNeutralStarTracking = (kStarWidthInPathUnits / kPathUnitsPerEm)
    * kStarScale * (1.0 + kStarGapRatio)
    - 1.0
local kStarStrokeWidth = 0.006
local kStarColor = { r = 1.0, g = 0.67, b = 0.12, a = 1.0 }
local kStarStrokeColor = { r = 1.0, g = 0.88, b = 0.38, a = 1.0 }
local kTransparentColor = { r = 0.0, g = 0.0, b = 0.0, a = 0.0 }

local activeMarkerCount = 0
local duplicateEnabled = false

local function copyColor(color)
    return { r = color.r, g = color.g, b = color.b, a = color.a }
end

local function snapshotCharacter(character)
    return {
        offsetX = character.offset_x,
        offsetY = character.offset_y,
        pivotX = character.pivot_x,
        pivotY = character.pivot_y,
        scale = character.scale,
        stretchX = character.stretch_x,
        stretchY = character.stretch_y,
        rotation = character.rotation,
        z = character.z,
        yaw = character.yaw,
        pitch = character.pitch,
        opacity = character.opacity,
        fill = {
            use = character.fill.use,
            color = copyColor(character.fill.color),
        },
        stroke = {
            use = character.stroke.use,
            width = character.stroke.width,
            gap = character.stroke.gap,
            color = copyColor(character.stroke.color),
        },
        shadow = {
            use = character.shadow.use,
            color = copyColor(character.shadow.color),
        },
    }
end

local function applyCharacterSnapshot(character, snapshot)
    character.offset_x = snapshot.offsetX
    character.offset_y = snapshot.offsetY
    character.pivot_x = snapshot.pivotX
    character.pivot_y = snapshot.pivotY
    character.scale = snapshot.scale
    character.stretch_x = snapshot.stretchX
    character.stretch_y = snapshot.stretchY
    character.rotation = snapshot.rotation
    character.z = snapshot.z
    character.yaw = snapshot.yaw
    character.pitch = snapshot.pitch
    character.opacity = snapshot.opacity
    character.fill = snapshot.fill
    character.stroke = snapshot.stroke
    character.shadow = snapshot.shadow
end

local function snapshotPart(part)
    return {
        offsetX = part.offset_x,
        offsetY = part.offset_y,
        pivotX = part.pivot_x,
        pivotY = part.pivot_y,
        scale = part.scale,
        stretchX = part.stretch_x,
        stretchY = part.stretch_y,
        rotation = part.rotation,
        z = part.z,
        yaw = part.yaw,
        pitch = part.pitch,
        opacity = part.opacity,
        fill = {
            use = part.fill.use,
            color = copyColor(part.fill.color),
        },
        stroke = {
            use = part.stroke.use,
            width = part.stroke.width,
            gap = part.stroke.gap,
            color = copyColor(part.stroke.color),
        },
        shadow = {
            use = part.shadow.use,
            color = copyColor(part.shadow.color),
        },
    }
end

local function applyPartSnapshot(part, snapshot)
    part.offset_x = snapshot.offsetX
    part.offset_y = snapshot.offsetY
    part.pivot_x = snapshot.pivotX
    part.pivot_y = snapshot.pivotY
    part.scale = snapshot.scale
    part.stretch_x = snapshot.stretchX
    part.stretch_y = snapshot.stretchY
    part.rotation = snapshot.rotation
    part.z = snapshot.z
    part.yaw = snapshot.yaw
    part.pitch = snapshot.pitch
    part.opacity = snapshot.opacity
    part.fill = snapshot.fill
    part.stroke = snapshot.stroke
    part.shadow = snapshot.shadow
end

local function neutralizeMarkerParts(ctx, markerEndIndex)
    for markerIndex = 1, markerEndIndex do
        local markerCharacter = ctx.chars[markerIndex]
        for localPartIndex = 0, markerCharacter.part_count - 1 do
            local part = ctx.parts[markerCharacter.part_start + localPartIndex]
            -- The star is drawn around the part origin, so centre the part that
            -- carries it on the glyph as a whole.
            if localPartIndex == 0 then
                part.offset_x = 0.5
                    + markerCharacter.geometry.bounds_center_x
                    - part.geometry.canvas_center_x
                part.offset_y = 0.5
                    + markerCharacter.geometry.bounds_center_y
                    - part.geometry.canvas_center_y
            else
                part.offset_x = 0.5
                part.offset_y = 0.5
            end
            part.pivot_x = 0.5
            part.pivot_y = 0.5
            part.scale = 1.0
            part.stretch_x = 1.0
            part.stretch_y = 1.0
            part.rotation = 0.0
            part.z = 0.0
            part.yaw = 0.0
            part.pitch = 0.0
            part.opacity = localPartIndex == 0 and 1.0 or 0.0
            part.fill.use = false
            part.stroke.use = false
            part.shadow.use = false
        end
    end
end

local function collectNaturalBounds(ctx, firstOriginalIndex, lastOriginalIndex)
    local bounds = {
        left = math.huge,
        right = -math.huge,
        bottom = math.huge,
        top = -math.huge,
    }

    for index = firstOriginalIndex, lastOriginalIndex do
        local geometry = ctx.chars[index].geometry
        local halfWidth = geometry.bounds_width * 0.5
        local halfHeight = geometry.bounds_height * 0.5
        bounds.left = math.min(bounds.left, geometry.bounds_center_x - halfWidth)
        bounds.right = math.max(bounds.right, geometry.bounds_center_x + halfWidth)
        bounds.bottom = math.min(bounds.bottom, geometry.bounds_center_y - halfHeight)
        bounds.top = math.max(bounds.top, geometry.bounds_center_y + halfHeight)
    end

    return bounds
end

local function alignmentCorrection(ctx, bounds, firstOriginalIndex)
    local horizontalAnchor = (bounds.left + bounds.right) * 0.5
    if ctx.global.h_align == "left" then
        horizontalAnchor = bounds.left
    elseif ctx.global.h_align == "right" then
        horizontalAnchor = bounds.right
    end

    local verticalAnchor = (bounds.bottom + bounds.top) * 0.5
    if ctx.global.v_align == "top" then
        verticalAnchor = bounds.top
    elseif ctx.global.v_align == "bottom" then
        verticalAnchor = bounds.bottom
    elseif ctx.global.v_align == "baseline" and not ctx.global.vertical then
        verticalAnchor = ctx.chars[firstOriginalIndex].geometry.canvas_origin_y
    end

    return 0.5 - horizontalAnchor, 0.5 - verticalAnchor
end

local function transformedCharacterBounds(ctx, character)
    local geometry = character.geometry
    local canvasWidth = ctx.canvas.width
    local canvasHeight = ctx.canvas.height
    local centerX = (geometry.bounds_center_x - 0.5) * canvasWidth
    local centerY = -(geometry.bounds_center_y - 0.5) * canvasHeight
    local halfWidth = geometry.bounds_width * canvasWidth * 0.5
    local halfHeight = geometry.bounds_height * canvasHeight * 0.5
    local pivotX = (character.pivot_x - 0.5) * canvasWidth
    local pivotY = -(character.pivot_y - 0.5) * canvasHeight
    local offsetX = (character.offset_x - 0.5) * canvasWidth
    local offsetY = -(character.offset_y - 0.5) * canvasHeight
    local scaleX = character.scale * character.stretch_x
    local scaleY = character.scale * character.stretch_y
    local rotationRadians = character.rotation * math.pi / 180.0
    local cosine = math.cos(rotationRadians)
    local sine = math.sin(rotationRadians)
    local corners = {
        { x = centerX - halfWidth, y = centerY - halfHeight },
        { x = centerX + halfWidth, y = centerY - halfHeight },
        { x = centerX + halfWidth, y = centerY + halfHeight },
        { x = centerX - halfWidth, y = centerY + halfHeight },
    }
    local bounds = {
        left = math.huge,
        right = -math.huge,
        top = math.huge,
        bottom = -math.huge,
    }

    for _, corner in ipairs(corners) do
        local relativeX = (corner.x - centerX - pivotX) * scaleX
        local relativeY = (corner.y - centerY - pivotY) * scaleY
        local transformedX = centerX + pivotX + offsetX
            + relativeX * cosine - relativeY * sine
        local transformedY = centerY + pivotY + offsetY
            + relativeX * sine + relativeY * cosine
        bounds.left = math.min(bounds.left, transformedX)
        bounds.right = math.max(bounds.right, transformedX)
        bounds.top = math.min(bounds.top, transformedY)
        bounds.bottom = math.max(bounds.bottom, transformedY)
    end

    return {
        centerX = 0.5 + ((bounds.left + bounds.right) * 0.5) / canvasWidth,
        centerY = 0.5 - ((bounds.top + bounds.bottom) * 0.5) / canvasHeight,
        widthPixels = bounds.right - bounds.left,
        heightPixels = bounds.bottom - bounds.top,
    }
end

-- Spread the incoming directions around the circle without ever repeating one
-- for adjacent stars. The golden angle keeps successive indices far apart, so
-- the arrival reads as scattered while staying identical on every frame.
local kGoldenAngleDegrees = 137.507764
local kIntroDirectionSeed = 47.0

local function introDirection(pairIndex)
    local angle = math.rad(kIntroDirectionSeed + (pairIndex - 1) * kGoldenAngleDegrees)
    return math.cos(angle), math.sin(angle)
end

-- 0 to 1 to 0 over the unit interval, peaking in the middle.
local function flash(t)
    return math.sin(mt.saturate(t) * kHalfTurn)
end

-- How far a given star is through the highlight that runs along the row: below 0
-- the light has not reached it, above 1 the light has passed. Both the glint and
-- the text reveal ride this, so each character lights up as the glint hits it.
local function glintSweep(ctx, pairIndex, starCount)
    local sweep = mt.timeline.window_progress(
        ctx,
        kIntroSeconds,
        kGlintSeconds
    )
    local position = starCount > 1 and (pairIndex - 1) / (starCount - 1) or 0.0
    -- Stars later in the row start lighting later, all finishing by the end.
    local start = position * (1.0 - kGlintWidth)
    return (sweep - start) / kGlintWidth
end

-- The slow drift a landed star and its character share, so the pair never comes
-- apart. Held back until the text has settled, so both start from their plain
-- resting position and rotation before drifting.
local function idleSway(ctx, pairIndex)
    local phase = (pairIndex - 1) * kStarPhaseOffset
    local amount = mt.ease.in_out_sine(mt.timeline.window_progress(
        ctx,
        kIntroSeconds + kGlintSeconds + kIdleStartDelaySeconds,
        kIdleFadeInSeconds
    ))
    return {
        offsetX = mt.wave(ctx.time, kIdleSwayFrequency, phase)
            * kIdleSwayAmount * amount,
        offsetY = mt.wave(ctx.time, kIdleSwayFrequency, phase + 0.25)
            * kIdleSwayAmount * amount,
        rotation = mt.wave(ctx.time, kIdleTiltFrequency, phase)
            * kIdleTiltAmount * amount,
        scale = mt.wave(ctx.time, kIdleScaleFrequency, phase)
            * kIdleScaleAmount * amount,
    }
end

-- Returns the star's offset from its resting place, plus its scale and spin, by
-- blending the intro fly-in, the idle sway, and the outro burst.
local function starMotion(ctx, pairIndex, starCount, restingBounds, sway)
    local intro, outro = mt.timeline.intro_outro_seconds(
        ctx,
        kIntroSeconds,
        kOutroSeconds
    )
    local position = starCount > 1 and (pairIndex - 1) / (starCount - 1) or 0.0
    local arrival = mt.stagger_progress(intro, position, kIntroStaggerSpan)
    local settle = mt.ease.out_back(arrival)

    -- Intro: fly in from off-centre, spinning down to rest.
    local directionX, directionY = introDirection(pairIndex)
    local travel = (1.0 - settle) * kIntroFlyDistance
    local offsetX = directionX * travel + sway.offsetX
    local offsetY = directionY * travel + sway.offsetY
    local rotation = (1.0 - mt.ease.out_cubic(arrival)) * kIntroSpinTurns
        + sway.rotation
    -- Grow only over the first part of the arrival so the star reads as flying
    -- in at size rather than swelling into place.
    local scale = mt.ease.out_quad(mt.saturate(arrival / kIntroGrowFraction))
        + sway.scale

    -- Outro: dip inward, then snap outward and vanish on the same beat as the
    -- text. The burst only starts once the anticipation is done, so the pop is
    -- concentrated into the tail rather than spread across the whole outro.
    local opacity = arrival
    local outroSquash = 1.0
    local outroVisibility = 1.0
    if outro > 0.0 then
        local anticipation = mt.saturate(outro / kOutroAnticipation)
        -- Finish slightly before the clip ends so the pop completes on screen
        -- instead of being cut off mid-flight by the last frame.
        local burst = mt.ease.in_quad(mt.saturate(
            (outro - kOutroAnticipation)
                / (kOutroBurstEnd - kOutroAnticipation)
        ))
        outroSquash = 1.0 - mt.ease.out_quad(anticipation) * kOutroSquashAmount
        outroVisibility = 1.0 - burst
        -- Push away from the text centre, plus a per-star direction so the star
        -- sitting on the centre still has somewhere to go.
        local scatterX, scatterY = introDirection(pairIndex)
        local awayX = (restingBounds.centerX - 0.5) + scatterX * kOutroScatter
        local awayY = (restingBounds.centerY - 0.5) + scatterY * kOutroScatter
        offsetX = offsetX + awayX * burst * kOutroFlyDistance
        offsetY = offsetY + awayY * burst * kOutroFlyDistance
        rotation = rotation + burst * kOutroSpinTurns
        scale = scale * outroSquash * (1.0 + burst * (kOutroBurstScale - 1.0))
        opacity = opacity * outroVisibility
    end

    return {
        offsetX = offsetX,
        offsetY = offsetY,
        rotation = rotation,
        scale = scale,
        opacity = opacity,
        arrival = arrival,
        outroSquash = outroSquash,
        outroVisibility = outroVisibility,
    }
end

function OnPreLayout(ctx)
    local originalText = ctx.global.text
    local originalCodepointCount = 0
    for _, codepoint in utf8.codes(originalText) do
        if codepoint ~= 10 and codepoint ~= 13 then
            originalCodepointCount = originalCodepointCount + 1
        end
    end
    local availableCharacterSlots = math.max(
        ctx.meta.limits.max_characters - originalCodepointCount,
        0
    )
    duplicateEnabled = originalCodepointCount > 0
        and availableCharacterSlots >= originalCodepointCount
    activeMarkerCount = duplicateEnabled and originalCodepointCount or 0
    if not duplicateEnabled then
        return
    end

    local originalMargins = ctx.global.margins
    local shiftedMargins = {}
    for index = 1, ctx.meta.limits.max_characters do
        if index <= activeMarkerCount then
            shiftedMargins[index] = originalMargins[index] or 0.0
        else
            shiftedMargins[index] = originalMargins[index - activeMarkerCount] or 0.0
        end
    end

    ctx.global.margins = shiftedMargins
    ctx.global.tracking = ctx.global.tracking + kNeutralStarTracking
    ctx.global.text = originalText .. "\n" .. originalText
end

function OnLayout(ctx)
    if not duplicateEnabled or ctx.char_count <= 1 or ctx.char_count % 2 ~= 0 then
        activeMarkerCount = 0
        return
    end

    -- Inspector per-character values land on the marker slots, so move them onto
    -- the real text. Both ranges share one array: read every source first.
    local markerEndIndex = ctx.char_count / 2
    activeMarkerCount = markerEndIndex
    local firstOriginalIndex = markerEndIndex + 1

    local characterSnapshots = {}
    for index = 1, markerEndIndex do
        characterSnapshots[index] = snapshotCharacter(ctx.chars[index])
    end
    for index = 1, markerEndIndex do
        applyCharacterSnapshot(
            ctx.chars[firstOriginalIndex + index - 1],
            characterSnapshots[index]
        )
    end

    local markerPartCount = 0
    for markerIndex = 1, markerEndIndex do
        markerPartCount = markerPartCount + ctx.chars[markerIndex].part_count
    end
    local partSnapshots = {}
    for partIndex = 1, ctx.part_count - markerPartCount do
        partSnapshots[partIndex] = snapshotPart(ctx.parts[partIndex])
    end
    for partIndex = 1, #partSnapshots do
        applyPartSnapshot(
            ctx.parts[markerPartCount + partIndex],
            partSnapshots[partIndex]
        )
    end
    neutralizeMarkerParts(ctx, markerEndIndex)

    local lastOriginalIndex = ctx.char_count
    local naturalBounds = collectNaturalBounds(
        ctx,
        firstOriginalIndex,
        lastOriginalIndex
    )
    local correctionX, correctionY = alignmentCorrection(
        ctx,
        naturalBounds,
        firstOriginalIndex
    )
    for index = firstOriginalIndex, lastOriginalIndex do
        local character = ctx.chars[index]
        character.offset_x = character.offset_x + correctionX
        character.offset_y = character.offset_y + correctionY
    end

    for pairIndex = 1, markerEndIndex do
        local markerCharacter = ctx.chars[pairIndex]
        local originalCharacter = ctx.chars[firstOriginalIndex + pairIndex - 1]

        if originalCharacter.part_count > 0 then
            local originalBounds = transformedCharacterBounds(ctx, originalCharacter)
            local sway = idleSway(ctx, pairIndex)
            local motion = starMotion(
                ctx,
                pairIndex,
                markerEndIndex,
                originalBounds,
                sway
            )

            -- Read before the reveal fade below, so the star keeps the opacity
            -- the Inspector asked for instead of inheriting the text's fade-in.
            local inspectorOpacity = originalCharacter.opacity

            -- The glint travelling along the row drives both the star's
            -- highlight and its character's fade-in, so each letter arrives on
            -- the light rather than the whole line appearing at once.
            local sweep = glintSweep(ctx, pairIndex, markerEndIndex)
            local glint = flash(sweep)
            local textReveal = mt.ease.out_cubic(mt.saturate(sweep))

            -- The character rides the same sway as its star so the pair moves
            -- as one.
            originalCharacter.offset_x = originalCharacter.offset_x + sway.offsetX
            originalCharacter.offset_y = originalCharacter.offset_y + sway.offsetY
            originalCharacter.rotation = originalCharacter.rotation + sway.rotation
            -- The text shares the star's anticipation dip and disappears on the
            -- same frame, but stays put instead of scattering with it.
            originalCharacter.scale = originalCharacter.scale * motion.outroSquash
            originalCharacter.opacity = inspectorOpacity * textReveal
                * motion.outroVisibility

            local markerGeometry = markerCharacter.geometry
            markerCharacter.offset_x = 0.5 + motion.offsetX
                + originalBounds.centerX - markerGeometry.bounds_center_x
            markerCharacter.offset_y = 0.5 + motion.offsetY
                + originalBounds.centerY - markerGeometry.bounds_center_y
            markerCharacter.pivot_x = 0.5
            markerCharacter.pivot_y = 0.5
            markerCharacter.scale = originalCharacter.scale * kStarScale
                * motion.scale * (1.0 + glint * kGlintScale)
            markerCharacter.stretch_x = 1.0
            markerCharacter.stretch_y = 1.0
            markerCharacter.rotation = originalCharacter.rotation
                + motion.rotation + glint * kGlintSpin
            -- Markers already draw behind the text by virtue of coming first, so
            -- these only mirror the character. Offsetting z would shift the star
            -- sideways once perspective divides it.
            markerCharacter.z = originalCharacter.z
            markerCharacter.yaw = originalCharacter.yaw
            markerCharacter.pitch = originalCharacter.pitch
            markerCharacter.opacity = inspectorOpacity * motion.opacity
            markerCharacter.fill = {
                use = true,
                color = mt.color.lerp(kStarColor, kGlintColor, glint),
            }
            markerCharacter.stroke = {
                use = true,
                width = kStarStrokeWidth * (1.0 + glint * kGlintStrokeGrowth),
                gap = 0.0,
                color = mt.color.lerp(kStarStrokeColor, kGlintColor, glint),
            }
            markerCharacter.shadow = {
                use = true,
                color = kTransparentColor,
            }
        else
            markerCharacter.opacity = 0.0
        end
    end
end

local function replaceWithStar(path)
    path:clear()
    for pointIndex = 0, kStarPointCount * 2 - 1 do
        local radius = pointIndex % 2 == 0
            and kStarOuterRadius
            or kStarInnerRadius
        local angle = -kHalfTurn * 0.5
            + pointIndex * kHalfTurn / kStarPointCount
        local pointX = math.cos(angle) * radius
        local pointY = math.sin(angle) * radius
        if pointIndex == 0 then
            path:move_to(pointX, pointY)
        else
            path:line_to(pointX, pointY)
        end
    end
    path:close()
end

function OnPath(ctx)
    if activeMarkerCount <= 0 then
        return
    end

    for markerIndex = 1, activeMarkerCount do
        local markerParts = ctx.paths:character(markerIndex)
        for partIndex, markerPart in ipairs(markerParts) do
            if partIndex == 1 then
                replaceWithStar(markerPart.path)
            else
                markerPart.path:clear()
            end
        end
    end
end
