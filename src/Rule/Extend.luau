const Types = require("../Types")
const Info = require("../Info")
const Rule = require("../Rule")

type RuleMetadata = Types.RuleMetadata<string>

-- One table type with the fields of both, so the schema of the new rule is inferred like any other rule's.
type function mergedFields(base: type, extra: type)
    assert(base:is("table"), "extend expects the base rule's fields to be a table")
    assert(extra:is("table"), "extend expects a table of named field schemas")

    local result = types.newtable()

    for key, property in base:properties() do
        if property.read then
            result:setproperty(key, property.read)
        end
    end

    for key, property in extra:properties() do
        if property.read then
            result:setproperty(key, property.read)
        end
    end

    return result
end

-- The names in either list, in order, without repeats. `nil` when neither has a list.
const function mergeNames(base: { string }?, extra: { string }?): { string }?
    if base == nil then
        return extra
    end

    if extra == nil then
        return base
    end

    local merged = table.clone(base)

    for _, name in extra do
        if table.find(merged, name) == nil then
            table.insert(merged, name)
        end
    end

    return merged
end

-- The transitions of both rules. A state the extension lists replaces the base rule's list for that state.
const function mergeTransitions(
    base: { [string]: { string } }?,
    extra: { [string]: { string } }?
): { [string]: { string } }?
    if base == nil then
        return extra
    end

    if extra == nil then
        return base
    end

    local merged = table.clone(base)

    for from, targets in extra do
        merged[from] = targets
    end

    return merged
end

-- The fields of the base rule with the new ones. A field may not be defined twice, because a schema that changes
-- under the same name would break the states written for the base rule.
const function mergeFields(base: { [string]: unknown }, extra: unknown, baseName: string): { [string]: unknown }
    if type(extra) ~= "table" then
        error(`extend expects a table of named field schemas, got {typeof(extra)}`, 3)
    end

    local merged = table.clone(base)

    for fieldName, fieldSchema in extra :: { [string]: unknown } do
        if merged[fieldName] ~= nil then
            error(`extend cannot redefine field "{fieldName}" of rule {baseName}`, 3)
        end

        merged[fieldName] = fieldSchema
    end

    return merged
end

-- Makes a new rule with every field, state name, transition, and tag of `base`, and the ones given here. The base
-- rule does not change, and its handlers are not affected.
return function <Fields, Extra>(
    base: { read _fields: Fields, read _metadata: RuleMetadata },
    extraFields: Extra,
    metadata: RuleMetadata
)
    local isRule = type(base) == "table" and type((base :: any)._metadata) == "table"

    if not isRule then
        error("extend expects a rule made with VideState.rule as its first argument", 2)
    end

    if type(metadata) ~= "table" then
        error("extend expects metadata with a name", 2)
    end

    const baseMetadata = base._metadata
    const registered = Info.get(baseMetadata.name)
    -- The tags are read from the registry, because addTags and removeTags change them after the rule is made.
    const baseTags = if registered == nil then baseMetadata.tags else registered.tags
    const mergedFields = mergeFields(base._fields :: any, extraFields, baseMetadata.name)
    const tags = mergeNames(baseTags, metadata.tags)
    const hasTags = tags ~= nil and #tags > 0

    const mergedMetadata: RuleMetadata = {
        name = metadata.name,
        description = metadata.description,
        tags = if hasTags then table.clone(tags :: { string }) else nil,
        allowedStateNames = mergeNames(baseMetadata.allowedStateNames, metadata.allowedStateNames),
        allowedTransitions = mergeTransitions(baseMetadata.allowedTransitions, metadata.allowedTransitions),
    }

    return Rule((mergedFields :: any) :: mergedFields<Fields, Extra>, mergedMetadata)
end
