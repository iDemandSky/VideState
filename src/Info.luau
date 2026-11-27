const Types = require("./Types")

type RuleMetadata = Types.RuleMetadata<string>

-- Rule metadata keyed by name; a name can only be registered once
local rules = {} :: { [string]: RuleMetadata }

const function checkDuplicatedName(name: string)
    if rules[name] then
        error(("Duplicate rule name: %s"):format(name))
    end
end

const function checkString(value: unknown, label: string)
    if type(value) ~= "string" then
        error(`{label} must be a string, got {typeof(value)}`, 3)
    end
end

-- Tags are compared exactly as written. They are never trimmed, lowercased, or otherwise formatted.
const function hasTag(metadata: RuleMetadata, tag: string): boolean
    local tags = metadata.tags

    if tags == nil then
        return false
    end

    return table.find(tags, tag) ~= nil
end

-- Rules are sorted by name so that results do not depend on registration order.
const function sortedRuleNames(): { string }
    local names = {}

    for name in rules do
        table.insert(names, name)
    end

    table.sort(names)

    return names
end

local api = {}

function api.register(metadata: RuleMetadata)
    checkDuplicatedName(metadata.name)

    local tags = metadata.tags

    rules[metadata.name] = table.freeze({
        name = metadata.name,
        description = metadata.description,
        tags = if tags == nil then nil else table.freeze(table.clone(tags)),
        allowedStateNames = metadata.allowedStateNames,
    }) :: RuleMetadata
end

-- Replaces the tags of a registered rule. The rule's addTags and removeTags call this.
function api.setTags(name: string, tags: { string })
    const metadata = rules[name]

    if metadata == nil then
        error(`No rule is registered under {name}`, 2)
    end

    rules[name] = table.freeze({
        name = metadata.name,
        description = metadata.description,
        tags = table.freeze(table.clone(tags)),
        allowedStateNames = metadata.allowedStateNames,
    }) :: RuleMetadata
end

function api.get(name: string): RuleMetadata?
    return rules[name]
end

-- Returns every rule that has all of the given tags, sorted by rule name.
function api.getAllRulesWithTags(...: string): { RuleMetadata }
    const wantedTags = { ... }

    if #wantedTags == 0 then
        error("getAllRulesWithTags requires at least one tag", 2)
    end

    for index, tag in wantedTags do
        checkString(tag, `Tag {index}`)
    end

    local matches: { RuleMetadata } = {}

    for _, name in sortedRuleNames() do
        const metadata = rules[name]
        local hasAllTags = true

        for _, tag in wantedTags do
            if not hasTag(metadata, tag) then
                hasAllTags = false

                break
            end
        end

        if hasAllTags then
            table.insert(matches, metadata)
        end
    end

    return table.freeze(matches)
end

-- Returns every distinct tag used by a registered rule, sorted alphabetically.
function api.getAllTags(): { string }
    local seen: { [string]: boolean } = {}
    local tags: { string } = {}

    for _, metadata in rules do
        for _, tag in metadata.tags or {} do
            if not seen[tag] then
                seen[tag] = true
                table.insert(tags, tag)
            end
        end
    end

    table.sort(tags)

    return table.freeze(tags)
end

-- Returns whether the rule has the exact tag. A rule that is not registered has no tags.
function api.ruleHasTag(ruleName: string, tag: string): boolean
    checkString(ruleName, "Rule name")
    checkString(tag, "Tag")

    const metadata = rules[ruleName]

    if metadata == nil then
        return false
    end

    return hasTag(metadata, tag)
end

return table.freeze(api)
