--[[
	The easing curves of `tweenDefault`. They are the standard easing equations (Robert Penner), in the form that
	easings.net lists them, written the way the Ripple library writes them so that the values stay the same.

	Ripple, MIT License, Copyright (c) 2025 littensy. Permission is hereby granted, free of charge, to any person
	obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software
	without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute,
	sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so,
	subject to the following conditions: The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
	PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- Each function takes the progress from 0 to 1 and returns the eased progress. `back` and `elastic` overshoot, so
-- their result can leave 0 to 1 in between.

const PI = math.pi
const C1 = 1.70158
const C2 = C1 * 1.525
const C3 = C1 + 1
const C4 = (2 * PI) / 3
const C5 = (2 * PI) / 4.5

const function linear(x: number): number
    return x
end

const function quadIn(x: number): number
    return x * x
end

const function quadOut(x: number): number
    return 1 - (1 - x) * (1 - x)
end

const function quadInOut(x: number): number
    return if x < 0.5 then 2 * x * x else 1 - ((-2 * x + 2) ^ 2) / 2
end

const function cubicIn(x: number): number
    return x * x * x
end

const function cubicOut(x: number): number
    return 1 - (1 - x) ^ 3
end

const function cubicInOut(x: number): number
    return if x < 0.5 then 4 * x * x * x else 1 - ((-2 * x + 2) ^ 3) / 2
end

const function sineIn(x: number): number
    return 1 - math.cos((x * PI) / 2)
end

const function sineOut(x: number): number
    return math.sin((x * PI) / 2)
end

const function sineInOut(x: number): number
    return -(math.cos(PI * x) - 1) / 2
end

const function expoIn(x: number): number
    return if x == 0 then 0 else 2 ^ (10 * x - 10)
end

const function expoOut(x: number): number
    return if x == 1 then 1 else 1 - 2 ^ (-10 * x)
end

const function expoInOut(x: number): number
    if x == 0 then
        return 0
    end

    if x == 1 then
        return 1
    end

    return if x < 0.5 then (2 ^ (20 * x - 10)) / 2 else (2 - (2 ^ (-20 * x + 10))) / 2
end

const function backIn(x: number): number
    return C3 * x * x * x - C1 * x * x
end

const function backOut(x: number): number
    return 1 + C3 * ((x - 1) ^ 3) + C1 * ((x - 1) ^ 2)
end

const function backInOut(x: number): number
    if x < 0.5 then
        return (((2 * x) ^ 2) * ((C2 + 1) * 2 * x - C2)) / 2
    end

    return (((2 * x - 2) ^ 2) * ((C2 + 1) * (x * 2 - 2) + C2) + 2) / 2
end

const function elasticIn(x: number): number
    if x == 0 then
        return 0
    end

    if x == 1 then
        return 1
    end

    return -(2 ^ (10 * x - 10)) * math.sin((x * 10 - 10.75) * C4)
end

const function elasticOut(x: number): number
    if x == 0 then
        return 0
    end

    if x == 1 then
        return 1
    end

    return (2 ^ (-10 * x)) * math.sin((x * 10 - 0.75) * C4) + 1
end

const function elasticInOut(x: number): number
    if x == 0 then
        return 0
    end

    if x == 1 then
        return 1
    end

    if x < 0.5 then
        return -((2 ^ (20 * x - 10)) * math.sin((20 * x - 11.125) * C5)) / 2
    end

    return ((2 ^ (-20 * x + 10)) * math.sin((20 * x - 11.125) * C5)) / 2 + 1
end

return table.freeze({
    linear = linear,
    quadIn = quadIn,
    quadOut = quadOut,
    quadInOut = quadInOut,
    cubicIn = cubicIn,
    cubicOut = cubicOut,
    cubicInOut = cubicInOut,
    sineIn = sineIn,
    sineOut = sineOut,
    sineInOut = sineInOut,
    expoIn = expoIn,
    expoOut = expoOut,
    expoInOut = expoInOut,
    backIn = backIn,
    backOut = backOut,
    backInOut = backInOut,
    elasticIn = elasticIn,
    elasticOut = elasticOut,
    elasticInOut = elasticInOut,
}) :: { [string]: (number) -> number }
