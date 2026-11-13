const TypedCore = require("@luau-packages/TypedCore")
const Vide = require("@packages/Vide")
const Constants = require("./Constants")

local validation = {}

type Source<T> = Vide.Source<T>

type function sourceRecord(value_type: type)
    assert(value_type:is("table"), "rule schemas must infer a table of named values")

    local source_type = types.newtable()

    for key, property in value_type:properties() do
        if property.read then
            source_type:setproperty(key, Source(property.read))
        end
    end

    return source_type
end

export type Sources<T> = sourceRecord<T>

function validation.schema<S>(schema: S): TypedCore.SchemaFromGeneric<S>
    local validator: TypedCore.SchemaFromGeneric<S> = schema

    if type(validator) ~= "table" or type(validator.parse) ~= "function" then
        error("rule expects a schema", 2)
    end

    return validator
end

function validation.stateName(stateName: unknown, context: string): string
    if type(stateName) ~= "string" then
        error(`{context} must be a string, got {typeof(stateName)}`, 2)
    end

    return stateName
end

function validation.parseState<S>(
    schema: S,
    stateName: string,
    values: TypedCore.infer<S>
): TypedCore.infer<S>
    local validator = validation.schema(schema)
    local destroy, result = Vide.root(function()
        return validator.parse(values)
    end)

    destroy()

    if not result.ok then
        local issues = if #result.issues > 0
            then TypedCore.parseIssue.formatIssues(result.issues)
            else "the schema rejected the state without a parse issue"

        error(`Invalid state "{stateName}":\n{issues}`, 3)
    end

    if type(result.value) ~= "table" then
        error(`Invalid state "{stateName}": schema must produce a table of named values`, 3)
    end

    return result.value
end

function validation.states<S>(
    schema: S,
    states: { [string]: TypedCore.infer<S> },
    initialState: string
): { [string]: TypedCore.infer<S> }
    if type(states) ~= "table" then
        error("rule states must be a table", 2)
    end

    validation.stateName(initialState, "initial state name")

    local validatedStates: { [string]: TypedCore.infer<S> } = {}
    local stateCount = 0

    for stateName, values in states do
        validation.stateName(stateName, "state name")
        validatedStates[stateName] = validation.parseState(schema, stateName, values)
        stateCount += 1
    end

    if stateCount < Constants.MIN_STATES then
        error(`rule requires at least {Constants.MIN_STATES} states`, 2)
    end

    validation.state(validatedStates, initialState, "initial")

    return validatedStates
end

function validation.state(
    statesValue: unknown,
    stateName: string,
    context: string
): unknown
    if type(statesValue) ~= "table" then
        error("validated states must be a table", 2)
    end

    local states = statesValue :: { [string]: unknown }
    local values = states[stateName]
    if values == nil then
        if context == "initial" then
            error(`unknown initial state "{stateName}"`, 2)
        end

        error(`unknown state "{stateName}"`, 2)
    end

    return values
end

function validation.source(
    sources: { [string]: unknown },
    fieldName: string
): Vide.Source<unknown>
    local source = sources[fieldName]
    if type(source) ~= "function" then
        error(`missing source for field "{fieldName}"`, 2)
    end

    return source :: Vide.Source<unknown>
end

return table.freeze(validation)
