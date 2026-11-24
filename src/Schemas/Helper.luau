const TypedCore = require("../../packages/luau/TypedCore")
const Vide = require("../../packages/roblox/Vide")

type Source<T> = Vide.Source<T>
type ParseResult<T> = TypedCore.ParseResult<T>
type ParseIssue = TypedCore.ParseIssue

const effect = Vide.effect

local helper = {}

const function isFunction(value: unknown): boolean
    return typeof(value) == "function"
end

function helper.formatTypeMismatch(expected: string, value: unknown): string
    return `expected {expected}, got {typeof(value)}`
end

function helper.parseType<T>(
    value: unknown,
    expectedType: string,
    expectedName: string
): ParseResult<T>
    if typeof(value) ~= expectedType then
        return TypedCore.parseResult.err({
            TypedCore.parseIssue.create(
                "invalid_type",
                helper.formatTypeMismatch(expectedName, value)
            ),
        })
    end

    return TypedCore.parseResult.ok(value :: T)
end

function helper.invalidValue(message: string): TypedCore.ParseResultErr
    return TypedCore.parseResult.err({
        TypedCore.parseIssue.create("invalid_value", message),
    })
end

function helper.isFinite(value: number): boolean
    return value == value and math.abs(value) < math.huge
end

function helper.decimalPlaces(value: number): number
    local representation = string.format("%.15g", value)
    local mantissa, exponentText = string.match(representation, "^([^eE]+)[eE]([+-]?%d+)$")
    local exponent = 0
    local fraction: string

    if mantissa then
        exponent = tonumber(exponentText) or 0
        fraction = string.match(mantissa, "%.(%d+)") or ""
    else
        fraction = string.match(representation, "%.(%d+)") or ""
    end

    return math.max(0, #fraction - exponent)
end

function helper.assertOptionsTable(options: unknown, name: string)
    assert(options == nil or type(options) == "table", `expected {name} options to be a table`)
end

function helper.assertFiniteOption(value: unknown, name: string)
    assert(
        value == nil or (type(value) == "number" and helper.isFinite(value)),
        `{name} must be finite`
    )
end

function helper.assertInteger(value: unknown, name: string, minimum: number?)
    assert(
        type(value) == "number"
            and helper.isFinite(value)
            and value % 1 == 0
            and (minimum == nil or value >= minimum),
        `{name} must be a finite integer{if minimum then ` greater than or equal to {minimum}` else ""}`
    )
end

function helper.assertOrderedBounds(min: number?, max: number?, name: string)
    assert(min == nil or max == nil or min <= max, `{name} minimum must not exceed maximum`)
end

function helper.assertMinimumCount(count: number, minimum: number, message: string)
    assert(count >= minimum, message)
end

function helper.assertType(value: unknown, expectedType: string, expectedName: string, context: string)
    if typeof(value) ~= expectedType then
        error(`expected {context} to be {expectedName}, got {typeof(value)}`, 2)
    end
end

function helper.trackAndValidateSource<T>(
    source: Source<T>,
    parser: (T) -> ParseResult<T>
): T
    if not isFunction(source) then
        error(`Expected a source function, got {typeof(source)}`, 2)
    end

    local initialValue: { value: T }? = nil

    effect(function()
        local result = parser(source())

        if not result.ok then
            local message = if #result.issues > 0
                then TypedCore.parseIssue.formatIssues(result.issues)
                else "the parser rejected the value without a parse issue"

            error(`Failed to validate the source: {message}`, 2)
        end

        initialValue = { value = result.value }
    end)

    local result = initialValue

    if not result then
        error("Vide effect did not run during source validation", 2)
    end

    return result.value
end

function helper.createSchemaWithSource<T, S, M>(
    name: string,
    parse: (value: unknown) -> ParseResult<T>,
    shape: S,
    metadata: M
): TypedCore.Schema<T, S, M>
    return TypedCore.schema.createSchema<<T, S, M>>(
        name,
        function(value: unknown): ParseResult<T>
            if isFunction(value) then
                local source = value :: Source<T>

                return TypedCore.parseResult.ok(
                    helper.trackAndValidateSource(source, parse)
                )
            end

            return parse(value)
        end,
        shape,
        metadata
    )
end

return table.freeze(helper)
