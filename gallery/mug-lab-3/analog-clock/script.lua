-- @MugTypography
-- @duration 6
-- @recommend text "11:35"
-- @title Analog Clock
-- @author Mug
-- @version 1.0
-- @api_level 9
-- Numbers 1-3 are the timing, listed in the order the phases play.
-- @input number 1 "Build In Duration" default=0.8
-- @input number 2 "Wait After Build In" default=0.2
-- @input number 3 "Run Duration" default=1.6
-- @input number 4 "Dial Radius (em)" default=1.9
-- @input number 5 "Text Scale" default=0.6
-- @input number 6 "Text Offset X (em)" default=0.0
-- @input number 7 "Text Offset Y (em)" default=0.0
-- @input number 8 "Text Timing (1=On Arrival 2=From Start)" default=1
-- The face is dark and the markings light, so the default global fill -- white
-- text -- stays readable sitting on the dial.
-- @input color 1 "Dial Face" default={0.13, 0.15, 0.20, 1.0}
-- @input color 2 "Rim And Ticks" default={0.72, 0.76, 0.85, 1.0}
-- @input color 3 "Hands" default={0.95, 0.96, 1.0, 1.0}
-- @input text 1 "Start Time (h:mm)" default="10:09"
-- @input text 2 "End Time (h:mm)" default="11:35"
--[[ @description
An analog clock face with an hour and a minute hand, drawn behind the text.
The dial builds itself, holds the start time, then runs to the end time.
2D only: 3D projection is forced off.

The clip plays in four phases, in this order:
    1. Build In     the face swells in and the hour ticks drop into place,
                    one after another clockwise from twelve
    2. Wait         the clock holds still, reading the start time
    3. Run          the hands travel to the end time over Run Duration, and
                    the text fades in to land with them
    4. Hold         the clock rests on the end time for the rest of the clip

The hands read the start time from the clip head, so the only rotation in the
whole clip belongs to phase 3.

Start Time / End Time:
    Written as h:mm, so 10:09 is nine past ten. A bare number is read as an
    hour, and h:mm:ss is accepted too. The dial has no am/pm, so 21:30 and
    9:30 point the same way. Anything unparseable falls back to twelve.

    End Time earlier than Start Time runs the hands forward through twelve,
    the way a real clock reaches it. To go the other way round, give Run
    Duration a negative value.

Build In Duration:
    Seconds the dial takes to assemble itself. Zero starts the clip with the
    clock already whole.

Wait After Build In:
    Seconds the clock holds the start time before it begins to run. This is
    the beat that separates the entrance from the run; at zero the two play
    as one continuous move.

Run Duration:
    Seconds phase 3 takes, from leaving the start time to settling on the
    end time. This sets the duration rather than the speed: the hands always
    take exactly this long, so a wider gap between the two readings makes
    them sweep faster. A negative value runs them anticlockwise over the
    same number of seconds, arriving at the end time from the other side.

Dial Radius:
    The face size in em, so it follows Global Scale and the font size. The
    text is scaled to sit inside it, and the rim, ticks and hands all take
    their proportions from this one measurement.

Text Offset X / Y:
    Moves the text alone, leaving the clock where it is. Both are in em, so
    the offset keeps its proportion to the glyphs at any font size, and Y is
    positive upward. At 0 the text sits in the middle of the face.

    The dial is anchored on where the text would have been, so Global
    Position and the inspector's alignment still move the two together and
    this opens a gap between them. Around -1.4 em on Y clears a
    default-sized face and reads as a caption under the clock.

    The face is dark by default so the usual white fill reads against it.
    Give the face a light colour and the text wants a dark fill to match, or
    an offset that moves it clear. The face colour's own alpha fades the dial
    behind the text where the two overlap.

Text Timing:
    1 (On Arrival) holds the text back until the hands are nearly at the end
    time, so it reads as the payoff the run arrives at. This is the default.

    2 (From Start) reveals it alongside the dial, which suits a caption
    naming the clock rather than the time it settles on -- a label, a date,
    a place.

Build In, Wait and Run are all measured in real seconds from the clip head, so
together they should fit inside the clip. Past its end the run is cut off
wherever the clip stops.

------------------------------------------------------------

長針と短針を持つアナログ時計の文字盤を、テキストの背面に描きます。
文字盤が組み上がり、開始時刻を示して静止したあと、終了時刻まで針が進みます。
2D専用で、3D投影は強制的に無効化されます。

クリップは次の4段階の順に再生されます:
    1. Build In  文字盤が現れ、12時から時計回りに目盛りが順次ポップインする
    2. Wait      開始時刻を示したまま静止する
    3. Run       Run Durationの秒数をかけて終了時刻まで進み、
                 到達に合わせてテキストがフェードインする
    4. Hold      終了時刻を示したままクリップ終端まで静止する

針はクリップ先頭から開始時刻を指しているので、クリップ中で回転するのは
段階3の針だけです。

Start Time / End Time:
    h:mm 形式で書きます。10:09 なら10時9分です。数字だけなら「時」として
    読み、h:mm:ss も受け付けます。文字盤に午前・午後の区別は無いので、
    21:30 と 9:30 は同じ位置を指します。解釈できない文字列は12時扱いです。

    終了時刻が開始時刻より前の場合、針は12時を回り込んで前進します。実際の
    時計がその時刻に到達するのと同じ動きです。逆回りさせたいときは
    Run Duration に負の値を指定してください。

Build In Duration:
    文字盤が組み上がるのにかける秒数です。
    0にすると最初から完成した状態で始まります。

Wait After Build In:
    針が進み始めるまで、開始時刻を示したまま静止する秒数です。登場と本編を
    区切る「間」にあたります。0にすると両者がひと続きの動きになります。

Run Duration:
    段階3にかける秒数です。開始時刻を離れてから終了時刻に落ち着くまでの
    長さを指定します。速さではなく長さの指定なので、針は必ずこの秒数で
    渡り切り、時刻の差が大きいほど速く動きます。負の値にすると、同じ秒数で
    反時計回りに進み、終了時刻に反対側から到達します。

Dial Radius:
    文字盤の大きさをem単位で指定します。フォントサイズと Global Scale に
    追従します。テキストは文字盤に収まるよう縮小され、リム・目盛り・針の
    太さや長さもすべてこの値から比率で決まります。

Text Offset X / Y:
    時計はそのままに、テキストだけを動かします。単位はemなので、フォント
    サイズを変えてもズラし量の比率は保たれます。Yは上方向が正です。
    0のときテキストは文字盤の中央に位置します。

    文字盤は「テキストが本来あった位置」を基準に置かれます。Global Position
    やインスペクタの整列では両者が一緒に動き、この値が両者の間に間隔を
    空けます。Yを-1.4em程度にすると既定サイズの文字盤の外に出て、時計の下の
    キャプションとして読めます。

    文字盤は既定で暗色なので、通常の白い塗りのテキストがそのまま読めます。
    文字盤を明るい色にする場合は、テキスト側を暗い色にするか、オフセットで
    文字盤の外に出してください。重なったまま使いたいときは、Dial Faceの色の
    アルファで文字盤側を透かせます。

Text Timing:
    1 (On Arrival) は針が終了時刻に着く直前にテキストを出します。針の動きが
    行き着く先として読ませる設定で、これが既定値です。

    2 (From Start) は文字盤と一緒にテキストを出します。針が示す時刻ではなく
    時計そのものに添える見出し — ラベル・日付・場所など — に向いた設定です。

Build In・Wait・Run はいずれもクリップ先頭からの実秒数なので、合計が
クリップ長に収まるように指定してください。超えた分は、クリップの終端で
打ち切られます。
]]

-- Path coordinates are part-local, Y-down, with 1000 units per em.
local kUnitsPerEm = 1000.0

-- The declared glyphs are prepended, so their indices are fixed: face, then
-- rim and ticks, then the two hands, then the user's text. The face and the
-- markings are separate glyphs: the ring is an outer circle with a reversed
-- inner one, an annulus whose hole would cancel a face disc sharing the part.
local kFaceCharacterIndex = 1
local kMarkingsCharacterIndex = 2
local kHourHandCharacterIndex = 3
local kMinuteHandCharacterIndex = 4
local kFirstTextIndex = 5

local kMinutesPerHour = 60.0
local kSecondsPerMinute = 60.0
local kHoursPerRevolution = 12.0
local kDegreesPerRevolution = 360.0
-- One full trip around the dial, in clock minutes. The run below wraps its
-- distance into this, so an end time earlier than the start is reached by going
-- forward through twelve.
local kMinutesPerRevolution = kMinutesPerHour * kHoursPerRevolution

-- Twelve o'clock is straight up, and rotation is clockwise-positive, so a hand
-- at revolution fraction 0 needs no rotation at all and the fraction maps
-- directly onto degrees.
local kTwelveOClockRotation = 0.0

local kMinimumDialRadiusEm = 0.4
local kMaximumDialRadiusEm = 12.0
local kMinimumTextScale = 0.05
-- Rim and hand weight are proportions of the dial. Each has one value that looks
-- right for a given face size, so Dial Radius stays the single size control and
-- everything scales with it.
local kRimWidthRatio = 0.047
-- Set against the tick width: at roughly three times a tick the hands outweigh
-- the marks they point at while staying slim.
local kHandWidthRatio = 0.078
local kMinimumBuildInDuration = 0.0
local kMinimumWaitDuration = 0.0
-- Reading used when a time field cannot be parsed at all. Twelve is the one
-- position on the dial that looks deliberate.
local kFallbackMinutesOfDay = 0.0
-- Floor on the run duration, keeping the progress division defined. Short
-- enough to read as an instant jump from the start time to the end time.
local kMinimumRunDuration = 1e-3

-- Tick geometry as fractions of the dial radius. The hour ticks are the only
-- markings: minute ticks at this size read as a grey band rather than as
-- separate marks, and the dial is meant to sit behind text.
-- All twelve marks are kept: fewer reads as a cleaner face but leaves the hands
-- pointing at nothing for two thirds of the dial, and the time stops being
-- readable at a glance.
--
-- Every tick measurement below is a fraction of the dial radius rather than an
-- exposed control, so the proportions hold at any face size and there is nothing
-- to tune into looking wrong.
--
-- The gap keeps the marks clear of the rim, so they read as marks sitting on
-- the face.
local kTickGapRatio = 0.055
local kTickWidthRatio = 0.026
local kHourTickLengthRatio = 0.1
-- Quarters are emphasised by length alone, with the width held constant across
-- all twelve, so they read as the same mark drawn longer.
local kQuarterTickLengthRatio = 0.185

-- Hand lengths as fractions of the dial radius. The minute hand stops just
-- inside the quarter ticks' inner ends, leaving a gap that lets its tip register
-- against the mark it points at.
--
-- Derived from the tick geometry so the two stay clear of each other however the
-- ratios above are retuned. The hour hand is set as a share of the minute hand,
-- keeping the pair legible as two distinct hands.
local kQuarterTickInnerRatio =
    1.0 - kRimWidthRatio - kTickGapRatio - kQuarterTickLengthRatio
local kMinuteHandTipClearance = 0.05
local kMinuteHandLengthRatio = kQuarterTickInnerRatio - kMinuteHandTipClearance
local kHourHandToMinuteHandRatio = 0.72
local kHourHandLengthRatio = kMinuteHandLengthRatio * kHourHandToMinuteHandRatio
-- How far each hand's tail extends past the center, as a fraction of its own
-- length. A short counterweight keeps the pivot from looking like the end of
-- the hand.
local kHandTailRatio = 0.14
-- Width of the blunt tip as a fraction of the hand's own width. A short taper
-- keeps the hand reading as a solid bar that happens to be pointed.
local kHandTipWidthRatio = 0.45
-- Length of the taper as a multiple of the hand's half-width, so the shoulder
-- angle is the same on both hands whatever their weights.
local kHandTipTaperRatio = 2.2
-- The hour hand carries a little more weight than the minute hand, enough to
-- read as deliberate while length does the work of telling them apart.
local kHourHandWidthScale = 1.2
-- Radius of the cap covering the two hands' shared pivot, relative to the hour
-- hand's half-width. Gauged on the wider of the two so it covers both tails.
local kPivotCapWidthScale = 1.15

local kCircleControlRatio = 0.5523

-- Fraction of the build-in the face itself takes to swell into place. The ticks
-- start dropping in while the disc is still arriving, so the two overlap into
-- one entrance.
local kDialArrivalFraction = 0.45
-- The dial swells slightly before settling, so the arrival has some weight.
local kDialArrivalOvershoot = 0.06

-- The hour ticks pop in one after another, clockwise from twelve, over this
-- share of the build-in. This cascade carries the entrance while the hands hold
-- the start time, keeping all rotation in the clip to the run itself.
local kTickCascadeStart = 0.25
local kTickCascadeSpan = 0.7
-- How long one tick takes to grow, as a share of the whole cascade. Well under
-- the gap between neighbours, so the marks land one at a time rather than
-- swelling as a single ring.
local kTickPopFraction = 0.35
-- Below this the tick is a sliver too short to read, so it is left out.
local kMinimumVisibleTickReveal = 0.02
-- The text is the payoff the run arrives at, so it lands with the end time. The
-- fade leads the arrival by this share of its own span, letting the text settle
-- as the hands land.
local kTextRevealLead = 0.75
local kTextRevealDuration = 0.45

-- Text Timing choices. On Arrival is the default; From Start reveals the text
-- alongside the dial, for a caption that names the clock itself.
local kTextTimingOnArrival = 1
local kTextTimingFromStart = 2
-- Share of the build-in the From Start reveal waits out before opening, so the
-- text follows the face in.
local kTextFromStartDelay = 0.35
local kFallbackClipLength = 6.0

-- A pivot field of 0.5 means no displacement from the natural position.
local kPivotNeutral = 0.5

local faceMarker = ""
local markingsMarker = ""
local hourHandMarker = ""
local minuteHandMarker = ""

-- Recomputed every frame in OnLayout and consumed by OnPath.
local dialRadiusUnits = 1.9 * kUnitsPerEm
local dialRimWidthUnits = 0.09 * kUnitsPerEm
local handWidthUnits = 0.1 * kUnitsPerEm
-- How far the cascade has run this frame, 0 to 1. OnPath turns it into each
-- tick's own reveal; kept as one number rather than a per-tick table so there
-- is nothing to keep in step across the two callbacks.
local tickCascadeProgress = 1.0

-- Global transform captured in OnPreLayout, where it is readable.
local globalScale = 1.0
local globalStretchX = 1.0
local globalStretchY = 1.0
local globalRotation = 0.0
local globalPivotX = 0.5
local globalPivotY = 0.5

--- Reads a "h:mm", "h:mm:ss" or bare-hour time field into minutes past twelve.
--- The dial has no am/pm, so the result is wrapped into one revolution and
--- 21:30 lands where 9:30 does. Unparseable input falls back to twelve rather
--- than raising, so a half-typed field leaves the clock readable instead of
--- blanking the whole effect.
local function parseClockMinutes(text)
    local minutesOfDay = kFallbackMinutesOfDay

    -- Matched longest form first: an "h:mm" pattern also matches the leading
    -- part of "h:mm:ss", so the seconds have to be claimed before it runs.
    local hourText, minuteText, secondText = string.match(text, "^%s*(%d+):(%d+):(%d+%.?%d*)%s*$")
    if hourText == nil then
        hourText, minuteText = string.match(text, "^%s*(%d+):(%d+%.?%d*)%s*$")
    end
    if hourText == nil then
        hourText = string.match(text, "^%s*(%d+%.?%d*)%s*$")
    end

    local hours = tonumber(hourText)
    if hours ~= nil then
        local minutes = tonumber(minuteText) or 0.0
        local seconds = tonumber(secondText) or 0.0
        minutesOfDay = hours * kMinutesPerHour + minutes + seconds / kSecondsPerMinute
    end

    return minutesOfDay % kMinutesPerRevolution
end

--- Appends a circle centred on the origin as a closed subpath.
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

--- Appends a circle wound the opposite way, so it cuts a hole in the shape it
--- sits inside rather than filling over it.
local function appendReversedCircle(path, centerX, centerY, radius)
    local control = radius * kCircleControlRatio
    path:move_to(centerX, centerY - radius)
    path:cubic_to(
        centerX - control, centerY - radius,
        centerX - radius, centerY - control,
        centerX - radius, centerY)
    path:cubic_to(
        centerX - radius, centerY + control,
        centerX - control, centerY + radius,
        centerX, centerY + radius)
    path:cubic_to(
        centerX + control, centerY + radius,
        centerX + radius, centerY + control,
        centerX + radius, centerY)
    path:cubic_to(
        centerX + radius, centerY - control,
        centerX + control, centerY - radius,
        centerX, centerY - radius)
    path:close()
end

--- Appends one tick as a rectangle lying along the radius at `angleDegrees`,
--- reaching inward from the rim.
local function appendTick(path, angleDegrees, outerRadius, length, halfWidth)
    -- Path space is Y-down and the ticks are placed clockwise from straight up,
    -- which is the same handedness, so the angle needs no sign correction here.
    local radians = math.rad(angleDegrees)
    local towardRimX = math.sin(radians)
    local towardRimY = -math.cos(radians)
    local acrossX = -towardRimY
    local acrossY = towardRimX

    local innerRadius = math.max(outerRadius - length, 0.0)
    local outerX = towardRimX * outerRadius
    local outerY = towardRimY * outerRadius
    local innerX = towardRimX * innerRadius
    local innerY = towardRimY * innerRadius

    path:move_to(outerX - acrossX * halfWidth, outerY - acrossY * halfWidth)
    path:line_to(outerX + acrossX * halfWidth, outerY + acrossY * halfWidth)
    path:line_to(innerX + acrossX * halfWidth, innerY + acrossY * halfWidth)
    path:line_to(innerX - acrossX * halfWidth, innerY - acrossY * halfWidth)
    path:close()
end

--- Draws the face as a plain filled disc.
local function appendFace(path, radius)
    appendCircle(path, 0.0, 0.0, radius)
end

--- Draws the rim ring and the twelve hour ticks, in their own glyph so the
--- ring's hole leaves the face disc intact under the nonzero fill rule.
---
--- `tickReveal` is a function of the hour, returning how far that tick has
--- popped in from 0 to 1. Each tick grows from its own inner end, so the marks
--- drop into place against the rim; a tick still at 0 is skipped, keeping
--- degenerate slivers out of the path.
local function appendMarkings(path, radius, rimWidth, tickReveal)
    if rimWidth > 0.0 then
        appendCircle(path, 0.0, 0.0, radius)
        -- Wound backwards, so the middle stays open and the ring reads as a rim.
        appendReversedCircle(path, 0.0, 0.0, math.max(radius - rimWidth, 0.0))
    end

    -- Held clear of the rim, so the marks sit on the face as their own objects.
    local tickOuterRadius = math.max(radius - rimWidth - radius * kTickGapRatio, 0.0)
    local halfWidth = radius * kTickWidthRatio
    for hour = 0, kHoursPerRevolution - 1 do
        local angle = hour / kHoursPerRevolution * kDegreesPerRevolution
        local isQuarter = hour % 3 == 0
        local tickHalfWidth = halfWidth
        local scaledLength =
            radius * (isQuarter and kQuarterTickLengthRatio or kHourTickLengthRatio)
        local reveal = tickReveal(hour)
        if reveal > kMinimumVisibleTickReveal then
            -- Only the length is scaled, not the width: a tick that narrows as
            -- it grows reads as a shard flying in, while one that keeps its
            -- width reads as the mark itself sliding out of the rim.
            appendTick(path, angle, tickOuterRadius, scaledLength * reveal, tickHalfWidth)
        end
    end
end

--- Draws one hand pointing straight up from the origin, with a short tail past
--- it. The hand is rotated into place by the character transform rather than
--- being redrawn at an angle, so the path stays the same every frame.
---
--- The hand tapers over its last stretch to a blunt tip, which gives it a
--- direction of its own while staying wide enough to survive anti-aliasing.
local function appendHand(path, length, halfWidth)
    local tail = length * kHandTailRatio
    -- Path space is Y-down, so the tip is at negative Y.
    local tipY = -length
    -- The taper runs over a stretch proportional to the hand's own width, so
    -- both hands narrow at the same angle whatever their weights.
    local shoulderY = tipY + halfWidth * kHandTipTaperRatio

    path:move_to(-halfWidth, tail)
    path:line_to(-halfWidth, shoulderY)
    path:line_to(-halfWidth * kHandTipWidthRatio, tipY)
    path:line_to(halfWidth * kHandTipWidthRatio, tipY)
    path:line_to(halfWidth, shoulderY)
    path:line_to(halfWidth, tail)
    path:close()
end

function OnPreLayout(ctx)
    -- Round joins throughout: the hands and ticks are the only shapes here, and
    -- a mitred join on the hand's taper would throw a spike past the tip when
    -- the inspector's stroke is on.
    ctx.global.stroke.join = "round"

    -- Zero bounds keep the clock out of the box h_align / v_align measure, and
    -- zero advance keeps the glyphs from occupying space on the line they lead.
    local emptyGlyph = {
        path = mt.drawing_path(),
        advance_x = 0,
        advance_y = 0,
        bounds = { 0, 0, 0, 0 },
    }
    -- Four separate glyphs, not one: each hand needs its own rotation, and the
    -- face, the markings and the hands each need to fill without cancelling one
    -- another. Parts within one character could not be rotated independently
    -- about the clock's centre.
    faceMarker = ctx.glyphs:declare(emptyGlyph)
    markingsMarker = ctx.glyphs:declare(emptyGlyph)
    hourHandMarker = ctx.glyphs:declare(emptyGlyph)
    minuteHandMarker = ctx.glyphs:declare(emptyGlyph)

    -- Prepended, not appended: paint order follows layout order, so putting the
    -- clock glyphs first stacks the face, its markings and the hands in that
    -- order, and all of them behind the text.
    ctx.global.text = faceMarker
        .. markingsMarker
        .. hourHandMarker
        .. minuteHandMarker
        .. ctx.global.text

    -- Tracking is added after every character, including the four clock glyphs,
    -- so the line they lead would start indented by that much however zero
    -- their advances are. Cancel it with a negative margin on each.
    local margins = {}
    margins[kFaceCharacterIndex] = -ctx.global.tracking
    margins[kMarkingsCharacterIndex] = -ctx.global.tracking
    margins[kHourHandCharacterIndex] = -ctx.global.tracking
    margins[kMinuteHandCharacterIndex] = -ctx.global.tracking
    ctx.global.margins = margins

    -- font.em_size is an untransformed metric while the text offset is applied in
    -- canvas terms, so record the Global transform here to bring the two onto
    -- equal terms. Overwritten every frame rather than accumulated.
    globalScale = ctx.global.scale
    globalStretchX = ctx.global.stretch_x
    globalStretchY = ctx.global.stretch_y

    -- measure_bounds_2d returns canvas-axis-aligned bounds, so under rotation it
    -- reports the box the text sweeps out instead of the text's own extent, and
    -- the dial would be centred on that swept box. Measure with rotation
    -- removed, and reapply it per character in OnLayout so the clock and the
    -- text still turn together.
    globalRotation = ctx.global.rotation
    ctx.global.rotation = 0.0

    -- Global rotation turns about the global position offset by the pivot, where
    -- a pivot of 0.5 means no displacement. Reproducing the rotation by hand
    -- means orbiting that same point, not the canvas centre.
    globalPivotX = ctx.global.position_x + (ctx.global.pivot_x - kPivotNeutral)
    globalPivotY = ctx.global.position_y + (ctx.global.pivot_y - kPivotNeutral)
end

function OnLayout(ctx)
    local buildInDuration = math.max(ctx.inputs.numbers[1], kMinimumBuildInDuration)
    local waitDuration = math.max(ctx.inputs.numbers[2], kMinimumWaitDuration)
    -- Negative means run anticlockwise; the magnitude is how long the trip
    -- takes, so the sign is split off before the duration is clamped.
    local runInput = ctx.inputs.numbers[3]
    local runDuration = math.max(math.abs(runInput), kMinimumRunDuration)
    local travelDirection = runInput < 0.0 and -1.0 or 1.0
    local dialRadiusEm =
        mt.clamp(ctx.inputs.numbers[4], kMinimumDialRadiusEm, kMaximumDialRadiusEm)
    -- Rim, ticks and hand weight all follow the radius, so the face keeps its
    -- proportions at any size and there is nothing to balance by hand.
    local rimWidthEm = dialRadiusEm * kRimWidthRatio
    local handWidthEm = dialRadiusEm * kHandWidthRatio
    local textScale = math.max(ctx.inputs.numbers[5], kMinimumTextScale)
    local textOffsetXEm = ctx.inputs.numbers[6]
    local textOffsetYEm = ctx.inputs.numbers[7]
    local textTiming = math.floor(
        mt.clamp(ctx.inputs.numbers[8], kTextTimingOnArrival, kTextTimingFromStart) + 0.5)

    local startMinutes = parseClockMinutes(ctx.inputs.texts[1])
    local endMinutes = parseClockMinutes(ctx.inputs.texts[2])

    -- Distance the run covers. Both readings are already wrapped into one
    -- revolution, so the forward difference is what a real clock travels: an
    -- end time that comes out negative sits on the far side of twelve, and
    -- wrapping it back into a positive distance sends the hands on through
    -- twelve to reach it.
    --
    -- Going anticlockwise covers the complement of that distance, which lands on
    -- the same end time from the other side of the dial.
    local forwardMinutes = (endMinutes - startMinutes) % kMinutesPerRevolution
    local runMinutes = forwardMinutes
    -- Equal readings stay put in either direction; their complement is a whole
    -- revolution, so they are held out of the flip.
    if travelDirection < 0.0 and forwardMinutes > 0.0 then
        runMinutes = kMinutesPerRevolution - forwardMinutes
    end

    -- The run starts once the build-in has finished and the wait has elapsed, and
    -- the reading holds at each end of it: the start time through the wait, and
    -- the end time from arrival to the end of the clip. The duration is given
    -- rather than derived, so the hands always take exactly this long whatever
    -- distance they have to cover -- a wider gap simply moves them faster.
    local runStartSeconds = buildInDuration + waitDuration
    local runProgress = mt.saturate((ctx.time - runStartSeconds) / runDuration)
    -- Eased rather than linear: the run is a transition between two readings
    -- the clock rests on, so it settles into the end time instead of stopping
    -- dead at full speed.
    local easedProgress = mt.ease.in_out_cubic(runProgress)
    local totalMinutes = startMinutes + runMinutes * easedProgress * travelDirection

    -- Revolution fractions rather than degrees, so each maps straight onto the
    -- clockwise-positive rotation the hands are given.
    local minuteRevolutions = totalMinutes / kMinutesPerHour
    -- The hour hand is driven by the same running total, not by the whole hour,
    -- so it creeps between the numerals as a real movement does.
    local hourRevolutions = totalMinutes / kMinutesPerRevolution

    -- Driven straight from the reading, so the hands show the start time from
    -- the clip head and hold it through the entrance. All rotation in the clip
    -- belongs to the run.
    local minuteRotation = kTwelveOClockRotation + minuteRevolutions * kDegreesPerRevolution
    local hourRotation = kTwelveOClockRotation + hourRevolutions * kDegreesPerRevolution

    -- The ticks drop in clockwise from twelve while the disc is still swelling.
    -- Consumed by OnPath, which turns this into each tick's own reveal.
    local cascadeStartSeconds = buildInDuration * kTickCascadeStart
    local cascadeDuration = buildInDuration * kTickCascadeSpan
    if cascadeDuration > 0.0 then
        tickCascadeProgress =
            mt.saturate((ctx.time - cascadeStartSeconds) / cascadeDuration)
    else
        -- A zero build-in means the clock is fully built at the clip head.
        tickCascadeProgress = 1.0
    end

    -- Path units are em units: the Global scale matrix that maps them to the
    -- canvas is the same one that scales the text, so an em stays an em on both
    -- sides and no compensation belongs here.
    dialRadiusUnits = dialRadiusEm * kUnitsPerEm
    dialRimWidthUnits = rimWidthEm * kUnitsPerEm
    handWidthUnits = handWidthEm * kUnitsPerEm

    -- Scale the text down to sit inside the face. Applied before the measure
    -- below so the dial is centred on the text at the size it will actually be
    -- drawn at.
    for index = kFirstTextIndex, ctx.char_count do
        ctx.chars[index].scale = ctx.chars[index].scale * textScale
    end

    -- Scale alone leaves the advances at their full-size widths, so the line
    -- would keep its settled length while the glyphs shrank and would still
    -- overhang the face. Re-typeset so the spacing follows the scale.
    --
    -- Anchor each line on the character sitting at the edge the alignment holds
    -- fixed, so every line pivots about the same margin the host aligned it to.
    local horizontalAlignment = ctx.global.h_align
    local blockBefore = mt.layout.measure_bounds_2d(ctx, nil)
    for _, line in ipairs(mt.layout.group_by_line(ctx)) do
        local targets = {}
        for _, character in ipairs(line.items) do
            if character.index >= kFirstTextIndex then
                targets[#targets + 1] = character.index
            end
        end
        if #targets > 0 then
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

    -- Reflow only closes up a line's own advances; the gap between lines keeps
    -- its full-size height, so a shrunken block would stay as tall as ever and
    -- overflow the face vertically. Pull each line toward the block's centre by
    -- the same factor the glyphs shrank.
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

    -- Centre the clock on the text, so the face follows the inspector's
    -- alignment and position rather than pinning itself to the canvas centre.
    -- Measuring the text alone matters: the clock glyphs draw far outside their
    -- declared zero bounds, and including them would feed the dial's own size
    -- back into the centre it is placed at.
    local textIndices = {}
    for index = kFirstTextIndex, ctx.char_count do
        textIndices[#textIndices + 1] = index
    end
    local textBounds = #textIndices > 0 and mt.layout.measure_bounds_2d(ctx, textIndices) or nil

    -- The clock is anchored on where the text would have been, before the offset
    -- below moves it. Reading the centre first is what makes the offset separate
    -- the two: measuring afterwards would drag the dial along and the gap would
    -- never open.
    local centerX = ctx.global.position_x
    local centerY = ctx.global.position_y
    if textBounds ~= nil then
        centerX = textBounds.center_x
        centerY = textBounds.center_y
    end

    -- One em in normalized canvas units on each axis. Canvas X and Y are
    -- normalized by different physical lengths, so the aspect ratio converts
    -- between them and an equal offset on both axes travels the same distance on
    -- screen. font.em_size is untransformed, so the Global transform is folded
    -- back in to get the canvas length one em actually covers.
    local emToCanvasY = ctx.font.em_size * globalScale * globalStretchY
    local emToCanvasX =
        ctx.font.em_size / ctx.canvas.aspect_ratio * globalScale * globalStretchX

    -- Move the text alone. offset_* is pre-global while the em lengths above are
    -- canvas measures, so they are divided back out of the Global scale the
    -- offset is about to be multiplied by. Accumulated onto whatever the reflow
    -- above left, so the per-line centering survives.
    local textShiftX = textOffsetXEm * emToCanvasX / globalScale
    local textShiftY = textOffsetYEm * emToCanvasY / globalScale
    if textShiftX ~= 0.0 or textShiftY ~= 0.0 then
        for _, index in ipairs(textIndices) do
            local character = ctx.chars[index]
            character.offset_x = character.offset_x + textShiftX
            character.offset_y = character.offset_y + textShiftY
        end
    end

    -- The dial arrives ahead of the hands so the two overlap into one entrance.
    local arrivalSpan = math.max(buildInDuration * kDialArrivalFraction, 0.0)
    local arrival = 1.0
    if arrivalSpan > 0.0 then
        arrival = mt.saturate(ctx.time / arrivalSpan)
    end
    local eased = mt.ease.out_cubic(arrival)
    -- A slight swell before settling, so the face lands with some weight.
    local dialScale = eased + math.sin(eased * math.pi) * kDialArrivalOvershoot

    -- On Arrival anchors the fade on the moment the hands land, opening a lead
    -- ahead of it so the text is settling as they arrive. The clamp holds the
    -- reveal inside the run when a short run is briefer than that lead.
    local textRevealStartSeconds = math.max(
        runStartSeconds + runDuration - kTextRevealDuration * kTextRevealLead,
        runStartSeconds)
    if textTiming == kTextTimingFromStart then
        textRevealStartSeconds = buildInDuration * kTextFromStartDelay
    end
    local textReveal = mt.saturate(
        (ctx.time - textRevealStartSeconds) / kTextRevealDuration)

    local _, outroAmount = mt.timeline.intro_outro_seconds(
        ctx, math.max(buildInDuration, kTextRevealDuration), buildInDuration,
        kFallbackClipLength)
    local outroFade = 1.0 - mt.ease.in_cubic(outroAmount)

    for index = kFirstTextIndex, ctx.char_count do
        local character = ctx.chars[index]
        character.opacity = character.opacity * mt.ease.out_cubic(textReveal) * outroFade
    end

    -- Every clock glyph shares one centre, one scale and one entrance; only the
    -- rotation, the colour and the face's own alpha differ. The face is listed
    -- first so it paints behind the rest.
    local clockGlyphs = {
        {
            index = kFaceCharacterIndex,
            color = ctx.inputs.colors[1],
            rotation = kTwelveOClockRotation,
            alpha = 1.0,
        },
        {
            index = kMarkingsCharacterIndex,
            color = ctx.inputs.colors[2],
            rotation = kTwelveOClockRotation,
            alpha = 1.0,
        },
        {
            index = kHourHandCharacterIndex,
            color = ctx.inputs.colors[3],
            rotation = hourRotation,
            alpha = 1.0,
        },
        {
            index = kMinuteHandCharacterIndex,
            color = ctx.inputs.colors[3],
            rotation = minuteRotation,
            alpha = 1.0,
        },
    }
    for _, glyph in ipairs(clockGlyphs) do
        local character = ctx.chars[glyph.index]
        mt.layout.place_2d(ctx, character, centerX, centerY)
        character.scale = character.scale * dialScale
        character.opacity = character.opacity * eased * outroFade * glyph.alpha
        -- Assigned, not accumulated: a hand's angle is the clock reading, and an
        -- inspector rotation added on top would make the clock show a different
        -- time than the one it was configured for. The face and the markings are
        -- radially symmetric, so pinning them to zero costs nothing.
        character.rotation = glyph.rotation
        character.fill.use = true
        character.fill.color = glyph.color
        -- Every clock shape is drawn as a filled outline, so the inspector's
        -- stroke would only thicken them unevenly. Match it to the fill and zero
        -- its width to keep the silhouettes exact.
        character.stroke.use = true
        character.stroke.color = glyph.color
        character.stroke.width = 0.0
    end

    -- Global rotation was zeroed so the text could be measured unrotated, so put
    -- it back per character here. Turning each character in place would spin the
    -- glyphs without moving the line, so their positions orbit the pivot as
    -- well, which is what the Global transform does.
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
    -- depth, so a hand swung forward by the projection would cut through the
    -- face it turns on, and the same perspective that separates them also shifts
    -- and shrinks the dial off the text it wraps.
    ctx.output.force_disable_3d_projection = true
end

function OnPath(ctx)
    -- ctx.paths is rebuilt every frame, so all four glyphs must be redrawn each
    -- time or the parts fall back to their empty declared outlines.
    for _, part in ipairs(ctx.paths:character(kFaceCharacterIndex)) do
        part.path:clear()
        appendFace(part.path, dialRadiusUnits)
    end

    -- Each tick opens a pop of its own, staggered clockwise from twelve so the
    -- marks arrive in reading order. The stagger spends only the share of the
    -- cascade the pops do not need, which keeps the last tick landing exactly as
    -- the cascade completes however long the pop itself is.
    local stagger = (1.0 - kTickPopFraction) / kHoursPerRevolution
    local tickReveal = function(hour)
        local delay = hour * stagger
        local pop = mt.saturate((tickCascadeProgress - delay) / kTickPopFraction)
        -- out_back overshoots slightly, so each mark springs past its length and
        -- settles rather than easing to a stop.
        return mt.ease.out_back(pop)
    end

    for _, part in ipairs(ctx.paths:character(kMarkingsCharacterIndex)) do
        part.path:clear()
        appendMarkings(
            part.path, dialRadiusUnits, dialRimWidthUnits, tickReveal)
    end

    local minuteHalfWidth = handWidthUnits * 0.5
    local hourHalfWidth = minuteHalfWidth * kHourHandWidthScale

    for _, part in ipairs(ctx.paths:character(kHourHandCharacterIndex)) do
        part.path:clear()
        appendHand(part.path, dialRadiusUnits * kHourHandLengthRatio, hourHalfWidth)
    end

    for _, part in ipairs(ctx.paths:character(kMinuteHandCharacterIndex)) do
        part.path:clear()
        appendHand(part.path, dialRadiusUnits * kMinuteHandLengthRatio, minuteHalfWidth)
        -- The cap belongs to the minute hand because that glyph paints last, so
        -- it covers the point where both hands meet. On the hour hand it would
        -- be painted over.
        appendCircle(part.path, 0.0, 0.0, hourHalfWidth * kPivotCapWidthScale)
    end
end
