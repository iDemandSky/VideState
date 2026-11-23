# VideState

VideState is a UI state handler specifically for Vide. This is meant to allow developers to seamlessly transition the states per change. Nothing more, nothing less.

Vide creates the UI Instances. VideState handles state changes of source values,
not the creation or management of Instances.

## Usage

When using VideState, the developer must create a rule first before creating an individual handler for each UI component. This way we can validate the parameters given from the UI components who inherit the base components.

After creating the rule, developers can create an independent handler for each UI component's sources. They must choose the initial state before declaring the UI through Vide.

Once the developers have created a new handler, developers can use this to create instructions on modifying the values whenever the state gets changed.

## Usage Steps

Create rule -> New handler, along with provided arguments -> Validate, error if not valid -> Use new handler's methods

## Schemas for Rule

Creating a new rule require the developers to use VideState's data type schema. Here are the data types that should be turned into a method that can be translated by the rule.

1. Integer
2. Float
3. String
4. Iterable (The key must always be a string)
5. All UI properties such as Color3, ColorSequence, etc.

Do note that these methods should return a mapped table, so we will need to have a schema builder like in Typed. Arrays should never be accepted as the purpose of this is to allow seamless property change.

The schema builders are now exposed as `VideState.schema`. `iterable` is an alias
of `record`: fixed string field names, each with its own schema, with no arrays or
extra fields. Integer requires whole numbers; Float accepts all finite numbers.
Boolean, enum membership, and Roblox datatype builders are also available.
Instance schemas are excluded. AdReward and Collection are deferred pending concrete Luau types.
See the [schema API](../README.md#schemas) for usage and datatype names. Rules and
handlers remain proposals, not implemented APIs.

The internal source helper can wrap a value schema to require a Vide-compatible
source function, validate its current contents, and return the same source.
Checking a getter does not prove setter behavior or enforce future writes.

## Handlers

This is a table of methods that can be found when creating a new one from the initialised rule. Here are the methods that the handlers should have:

TBC
