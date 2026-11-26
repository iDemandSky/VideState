const Types = require("./Types")
const Validation = require("./Validation")
const Handler = require("./Handler")
const Info = require("./Info")
const Table = require("./Schemas/Primitives/Table")

type Infer<S> = Types.Infer<S>
type States<S> = { [string]: Types.Sources<Infer<S>> }

export type RuleMetadata = Types.RuleMetadata<string>

const function readTags(label: string, ...: string): { string }
    const given = { ... }

    if #given == 0 then
        error(`{label} requires at least one tag`, 3)
    end

    for index, tag in given do
        if type(tag) ~= "string" then
            error(`Tag {index} must be a string, got {typeof(tag)}`, 3)
        end
    end

    return given
end

-- Rules read their tags from the registry, so a change here reaches Info and every filter at once.
const function currentTags(name: string): { string }
    const registered = Info.get(name)
    const tags = if registered == nil then nil else registered.tags

    return if tags == nil then {} else table.clone(tags)
end

return function <Fields>(fields: Fields, metadata: RuleMetadata)
    local schema = Table(fields)
    Validation.schema(schema)
    Info.register(metadata)

    const ruleName = metadata.name

    return table.freeze({
        _schema = schema,

        -- Adds tags to the rule. Returns true when at least one tag was new.
        addTags = function(...: string): boolean
            const given = readTags("addTags", ...)
            const tags = currentTags(ruleName)
            local changed = false

            for _, tag in given do
                if table.find(tags, tag) == nil then
                    table.insert(tags, tag)

                    changed = true
                end
            end

            if changed then
                Info.setTags(ruleName, tags)
            end

            return changed
        end,

        -- Removes tags from the rule. Returns true when at least one tag was present.
        removeTags = function(...: string): boolean
            const given = readTags("removeTags", ...)
            const tags = currentTags(ruleName)
            local changed = false

            for _, tag in given do
                local index = table.find(tags, tag)

                if index ~= nil then
                    table.remove(tags, index)

                    changed = true
                end
            end

            if changed then
                Info.setTags(ruleName, tags)
            end

            return changed
        end,

        new = function(
            states: States<typeof(schema)>,
            initialState: string,
            options: Types.HandlerOptions?
        )
            return Handler(schema, states, initialState, options, metadata.allowedStateNames, metadata.name)
        end,
    })
end
