# Rego Style Guide

Given the general purpose nature of Open Policy Agent (OPA) — and the versatility of the Rego language — there is
often more than one way to express what one wants to accomplish. Additionally, the Rego language has seen countless
improvements over the years, whether in the form of new features, built-in functions, or language constructs. While
it's "easy" to add things, great care needs to be taken with how to deal with _existing_ features and constructs.
With a strong commitment to backwards compatibility, new features in OPA tend to live in parallel with older ones
rather than replacing them entirely. Other times, patterns emerge out of experience, and some constructs prove to
simply work really well over time.

The purpose of this style guide is to provide a collection of recommendations and best practices for authoring modern
policy as code. Based on years of experience working with OPA and Rego, we hope to share some of our findings with you
in a format that should be easy for anyone to consume.

As with any style guide - much of the advice provided here is subjective. When deciding on style within a larger group
of developers, finding acceptance (if not consensus) on a set of principles is often more important than the principles
themselves. Use the rules provided here as you wish: adopt the guide in its entirety, pick what you like, or go your
own way.

Since best practices change over time, make sure to check back every now and then. We intend to keep this project
versioned, with any changes published included in the `CHANGELOG.md` file. This should allow you to quickly scan for
updates in recommendations since you last checked in.

## Contributing

This document is meant to reflect the style preferences and best practices as compiled by the OPA community. As such,
we welcome contributions from any of its members. Since most of the topics in a guide like this are likely subject to
discussion, please open an issue, and allow some time for people to comment, before opening a PR.

If you'd like to add or remove items for your own company, team or project, forking this repo is highly encouraged!

## Contents

- [General Advice](#general-advice)
  - [Optimize for readability, not performance](#optimize-for-readability-not-performance)
  - [Use `opa fmt`](#use-opa-fmt)
  - [Use strict mode](#use-strict-mode)
  - [Use metadata annotations](#use-metadata-annotations)
  - [Get to know the built-in functions](#get-to-know-the-built-in-functions)
  - [Consider using JSON schemas for type checking](#consider-using-json-schemas-for-type-checking)
- [Style](#style)
  - [Prefer snake_case for rule names and variables](#prefer-snakecase-for-rule-names-and-variables)
  - [Keep line length <= 120 characters](#keep-line-length--120-characters)
- [Rules](#rules)
  - [Use helper rules and functions](#use-helper-rules-and-functions)
  - [Use negation to handle undefined](#use-negation-to-handle-undefined)
  - [Consider partial helper rules over comprehensions in rule bodies](#consider-partial-helper-rules-over-comprehensions-in-rule-bodies)
  - [Avoid prefixing rules and functions with `get_` or `list_`](#avoid-prefixing-rules-and-functions-with-get_-or-list_)
- [Variables and Data Types](#variables-and-data-types)
  - [Use `in` to check for membership](#use-in-to-check-for-membership)
  - [Prefer `some .. in` for iteration](#prefer-some--in-for-iteration)
  - [Use `every` to express FOR ALL](#use-every-to-express-for-all)
  - [Don't use unification operator for assignment or comparison](#dont-use-unification-operator-for-assignment-or-comparison)
  - [Don't use undeclared variables](#dont-use-undeclared-variables)
  - [Prefer sets over arrays (where applicable)](#prefer-sets-over-arrays-where-applicable)
- [Regex](#regex)
  - [Use raw strings for regex patterns](#use-raw-strings-for-regex-patterns)
- [Imports](#imports)
  - [Prefer importing modules over rules and functions](#prefer-importing-modules-over-rules-and-functions)
  - [Avoid importing `input`](#avoid-importing-input)

## General Advice

### Optimize for readability, not performance

Rego is a declarative language, which in the best case means you express **what** you want rather than **how** it
should be retrieved. When authoring policy, do not try to be "smart" about assumed performance characteristics or
optimizations. That's what OPA should worry about!

Optimize for **readbility** and **obviousness**. Optimize for performance *only* if you've identified performance
issues in your policy, and even if you do — making your policy more compact or "clever" almost never helps at addressing
the problem at hand.

#### Related Resources
- [Policy Performance](https://www.openpolicyagent.org/docs/latest/policy-performance/)

### Use `opa fmt`

The `opa fmt` tool ensures consistent formatting across teams and projects. While certainly not
[perfect](https://github.com/open-policy-agent/opa/issues/4508) (yet!), unified formatting is a big win, and saves a
lot of time in code reviews arguing over details around style.

A good idea could be to run `opa fmt --write` on save, which can be configured in most editors. If you want to enforce
`opa fmt` formatting as part of your build pipeline, use `opa fmt --fail`.

In order to not flood this guide with data, formatting conventions covered by `opa fmt` will not be included here.

### Use strict mode

[Strict mode](https://www.openpolicyagent.org/docs/latest/strict/) provides extra checks for common mistakes like
redundant imports, or unused variables. Include an `opa check --strict path/to/polices` step as part of your build
pipeline.

### Use metadata annotations

Favor [metadata annotations](https://www.openpolicyagent.org/docs/latest/annotations/) over regular comments.
Metadata annotations allow external tools and editors to parse their contents, potentially leveraging them for
something useful, like in-line explanations, generated docs, etc.

**Avoid**
```rego
# Base package composing the decision from deny rules in sub-packages
package main

# Aggregate deny rules from package(s) under `authorization` based
# on first path component in input
router[msg] {
    data["authorization"][input.path[0]].deny[msg]
}
```

**Prefer**
```rego
# METADATA
# description: Base package composing the decision from deny rules in sub-packages
package main

# METADATA
# description: |
#  Aggregate deny rules from package(s) under `authorization` based
#  on first path component in input
router[msg] {
    data["authorization"][input.path[0]].deny[msg]
}
```

**Notes / Exceptions**

Use regular comments inside of rule bodies, or for packages and rules you consider "internal".

#### Related Resources
- [Annotations](https://www.openpolicyagent.org/docs/latest/annotations/)

### Get to know the built-in functions

With more than 150 [built-in functions](https://www.openpolicyagent.org/docs/latest/policy-reference/#built-in-functions)
tailor-made for policy evaluation, there's a good chance that some of them can help you accomplish your goal.

### Consider using JSON schemas for type checking

As you author Rego policy, providing JSON schemas for your `input` (and possibly `data`) enables strict
[type checking](https://www.openpolicyagent.org/docs/latest/schemas/), letting you avoid simple — but common — mistakes,
like typos, or referencing nested attributes in the wrong location. This extra level of verification improves both the
developer experience as well as the quality of your policies.

## Style

### Prefer snake_case for rule names and variables

The built-in functions use `snake_case` for naming — follow that convention for your own rules, functions, and variables.

**Avoid**
```rego
userIsAdmin {
    "admin" in input.user.roles
}
```

**Prefer**
```rego
user_is_admin {
    "admin" in input.user.roles
}
```

**Notes / Exceptions**

For many policy types, you might not control the format of the `input` data — if the domain of a policy (e.g. Envoy)
mandates a different style, making an exception might seem reasonable. Adapting policy format after `input` is however
prone to inconsistencies, as you'll likely end up mixing different styles in the same policy (due to imports of common
code, etc).

### Keep line length <= 120 characters

Long lines are tedious to read. Keep line length at 120 characters or below.

**Avoid**
```rego
frontend_admin_users := [username | some user in input.users; "frontend" in user.domains; "admin" in user.roles; username := user.username]
```

**Prefer**
```rego
frontend_admin_users := [username |
    some user in input.users
    "frontend" in user.domains
    "admin" in user.roles
    username := user.username]
```

## Rules

### Use helper rules and functions

Helper rules makes policies more readable, and for repeated conditions more performant as well. If your rule contains
more than a few simple expressions, consider splitting it into multiple rules with good names.

**Avoid**
```rego
allow {
    "developer" in input.user.roles
    input.request.method in {"GET", "HEAD"}
    startswith(input.request.path, "/docs")
}

allow {
    "developer" in input.user.roles
    input.request.method in {"GET", "HEAD"}
    startswith(input.request.path, "/api")
}
```

**Prefer**

```rego
allow {
    is_developer
    read_request
    startswith(input.request.path, "/docs")
}

allow {
    is_developer
    read_request
    startswith(input.request.path, "/api")
}

read_request {
    input.request.method in {"GET", "HEAD"}
}

is_developer {
    "developer" in input.user.roles
}
```

Additionally, helper rules and functions may be kept in (and imported from) separate modules, allowing you to build a
logical — and reusable! — structure for your policy files.

### Use negation to handle undefined

When encountering undefined references inside of rules, evaluation of the rule halts and the rule _itself_ evaluates to
undefined, unless of course, a `default` value has been provided. While saying `allow is undefined` or `allow is false`
if encountering undefined in a rule is likely desirable, this doesn't hold true when working with "inverted" rules -
i.e. rules like `deny` (as opposed to `allow`). Saying `deny is undefined` or `deny is false` if undefined is
encountered, essentially means that any occurence of undefined (such as when attributes are missing in the input
document) would lead to the `deny` rule not getting enforced. This is particularly common writing partial rules (i.e.
rules that build [sets](https://www.openpolicyagent.org/docs/latest/policy-language/#generating-sets) or
[objects](https://www.openpolicyagent.org/docs/latest/policy-language/#generating-objects)).

Consider for example this simple rule:

**Avoid**
```rego
authorized := count(deny) == 0

deny["User is anonymous"] {
    input.user_id == "anonymous"
}
```

At first glance, it might seem obvious that evaluating the rule should add a violation to the set of messages if the
`user_id` provided in `input` is equal to "anonymous". But what happens if there is no `user_id` provided _at all_?
Evaluation will stop when encountering undefined, and the comparison will never be invoked, leading to **nothing**
being added to the `deny` set — the rule allows someone without a `user_id`. We could of course add another
rule, checking only for its presence:

```rego
deny["User ID missing from input"] {
    not input.user_id
}
```

This is nice in that we'll get an even more granual message returned to the caller, but quickly becomes tedious when
working with a large set of input data. To deal with this, a helper rule using _negation_ may be used.

**Prefer**
```rego
authorized := count(deny) == 0

deny["User is anonymous"] {
    not authenticated_user
}

authenticated_user {
    input.user_id != "anonymous"
}
```

In the above case, the `authenticated_user` rule will fail **both** in the the undefined case, and if defined
but equal to "anonymous". Since we negate the result of the helper rule in the `deny` rule, we'll have both
cases covered.

#### Related Resources
- [OPA AWS CloudFormation Hook Tutorial](https://www.openpolicyagent.org/docs/latest/aws-cloudformation-hooks/)

### Consider partial helper rules over comprehensions in rule bodies

While comprehensions inside of rule bodies allows for compact rules, these are often harder to debug, and can't easily
be reused by other rules. Partial rules may be referenced by any other rule, and more importantly, by you!
Having many smaller, composable rules, is often key to quickly identifying where things fail, as each rule may be
queried individually.

**Avoid**
```rego
import future.keywords

allow {
    input.request.method in {"GET", "HEAD"}
    input.request.path[0] == "credit_reports"
    input.user.name in {username |
        # These should not count as MFA
        insecure_methods := {"email"}

        some user in data.users
        mfa_methods := {method | some method in user.authentication.methods} - insecure_methods

        count(mfa_methods) > 1
        username := user.name
    }
}
```

**Prefer**
```rego
import future.keywords

allow {
    input.request.method in {"GET", "HEAD"}
    input.request.path[0] == "credit_reports"
    input.user.name in mfa_authenticated_users
}

mfa_authenticated_users[username] {
    # These should not count as MFA
    insecure_methods := {"email"}

    some user in data.users
    mfa_methods := {method | some method in user.authentication.methods} - insecure_methods

    count(mfa_methods) > 1
    username := user.name
}
```

**Notes / Exceptions**

Does not apply if ordering is of importance, or duplicate values should be allowed. For those cases, use array
comprehensions.

### Avoid prefixing rules and functions with `get_` or `list_`

Since Rego evaluation is generally free of side effects, any rule or function is essentially a "getter". Adding a
`get_` prefix to a rule or function (like `get_resources`) thus adds little of value compared to just naming it
`resources`. Additionally, the type and return value of the rule should serve to tell whether a rule might return a
single value (i.e. a complete rule) or a collection (a partial rule).

**Avoid**
```rego
get_first_name(user) := split(user.name, " ")[0]

# Partial rule, so a set of users is to be expected
list_developers[developer] {
    some user in data.application.users
    user.type == "developer"
}
```

**Prefer**
```rego
# "get" is implied
first_name(user) := split(user.name, " ")[0]

# Partial rule, so a set of users is to be expected
developers[developer] {
    some user in data.application.users
    user.type == "developer"
}
```

**Notes / Exceptions**

Using `is_`, or `has_` for boolean helper functions, like `is_admin(user)` may be easier to comprehend than
`admin(user)`.

## Variables and Data Types

### Use `in` to check for membership

Using `in` for membership checks clearly communicates intent, and is less prone to errors. This is especially true when
checking if something is _not_ part of a collection.

**Avoid**
```rego
# "Old" way of checking for membership - iteration + comparison
allow {
    "admin" == input.user.roles[_]
}
```

**Prefer**
```rego
import future.keywords

allow {
    "admin" in input.user.roles
}
```

**Avoid**
```rego
deny["Only admin allowed"] {
    not user_is_admin
}

user_is_admin {
    "admin" == input.user.roles[_]
}
```

**Prefer**
```rego
import future.keywords

deny["Only admin allowed"] {
    not "admin" in input.user.roles
}
```

### Prefer `some .. in` for iteration

Using the `some` .. `in` construct for iteration removes ambiguity around iteration vs. membership checks, and is
generally more pleasant to read.

```rego
my_rule {
    # Are we iterating users over a partial "other_rule" here,
    # or checking if the set contains a user defined elsewhere?
    other_rule[user]
}
```

While this could be alleviated by declaring `some user` before the iteration, we can't take that consideration for
granted when reading code from someone else.

**Avoid**
```rego
# Iterating over array
internal_hosts[hostname] {
    host := data.network.hosts[_]
    host.internal == true
    hostname := host.name
}

# Iterating over object
public_endpoints[endpoint] {
    some endpoint
    attributes := endpoints[endpoint]
    attributes.public
}
```

**Prefer**
```rego
import future.keywords

internal_hosts[hostname] {
    some host in data.network.hosts
    host.internal == true
    hostname := host.name
}

# Iterating over object
public_endpoints[endpoint] {
    some endpoint, attributes in endpoints
    attributes.public
}
```

**Notes / Exceptions**

Using the "old" style of iteration may still be preferable when iterating over deeply nested structures.

```rego
# Building a list of all hostnames from a deeply nested structure

all_hostnames := [hostname | hostname := data.regions[_].networks[_].servers[_].hostname]

# ⬆️ is likely preferable over ⬇️

all_hostnames := [hostname |
    some region in data.regions
    some network in region
    some server in network
    hostname := server.hostname
]
```

### Use `every` to express FOR ALL

The `every` keyword makes it trivial to describe "for all" type expressions, which previously required the use of
helper rules, or comparing counts of items in the original collection against a filtered one produced by a
comprehension.

**Avoid**
```rego
import future.keywords

allow {
    # Negate result of _any_ match
    not any_old_registry
}

any_old_registry {
    some container in input.request.object.spec.containers
    startswith(container.image, "old.docker.registry/")
}
```

**Prefer**
```rego
import future.keywords

allow {
    every container in input.request.object.spec.containers {
        not startswith(container.image, "old.docker.registry/")
    }
}
```

**Avoid**
```rego
words := ["always", "arbitrary", "air", "brand", "asphalt"]

all_starts_with_a {
    starts_with_a := [word |
        some word in words
        startswith(word, "a")
    ]
    count(starts_with_a) == count(words)
}
```

**Prefer**
```rego
import future.keywords

words := ["always", "arbitrary", "air", "brand", "asphalt"]

all_starts_with_a {
    every word in words {
        startswith(word, "a")
    }
}
```

**Notes / Exceptions**

Older versions of OPA used the `all` built-in function to check that all elements of an array had the value `true`.
This function has been deprecated for a long time, and will eventually be removed.

### Don't use unification operator for assignment or comparison

The [unification](https://www.openpolicyagent.org/docs/latest/policy-language/#unification-) operator (`=`) allows you
to combine assignment and comparison. While this is useful in a few specific cases (see "Notes / Exceptions" below),
using the assignment operator (`:=`) for assignment, and the comparison operator (`==`) for comparison, is almost always
preferable. Separating assignment from comparison clearly demonstrates intent, and removes the ambiguity around scope
associated with unification.

**Avoid**
```rego
# Top level assignment using unification operator
roles = input.user.roles

allow {
    # Unification operator - used for assignment to `username` variable or for
    # comparing to a `username` variable or rule defined elsewhere? Who knows.
    username = input.user.name

    # ...
}

allow {
    # Unification operator used for comparison
    input.request.method = "GET"
}

allow {
    some user
    input.request.path = ["users", user]
    input.request.user == user
}
```

**Prefer**
```rego
# Top level assignment using assignment operator
roles := input.user.roles

allow {
    # Assignment operator used for assignment - no ambiguity around
    # intent, or variable scope
    username := input.user.name

    # ... do something with username
}

allow {
    # Comparison operator used for comparison
    input.request.method == "GET"
}

allow {
    input.request.path == ["users", input.request.user]
}
```

**Notes / Exceptions**

Unification was used extensively in older versions of OPA, and following that, in the policy examples provided in
the OPA documentation, blogs, and elsewhere. With the assignment and comparison operators now available for use in
any context, there are generally few reasons to use the unification operator in modern Rego.

One notable exception is when matching for example, the path of a request (as presented in array form),
where you'll want to do both comparison and assignment to variables from the path components:

```rego
# Using unification - compact but clear
router {
	some user_id, podcast_id
    ["users", user_id, "podcasts", podcast_id] = input.request.path

    # .. do something with user_id, podcast_id
}

# Using comparison + assignment - arguably messier
router {
	input.request_path[0] == "users"
    input.request_path[2] == "podcasts"

    user_id := input.request_path[1]
    podcast_id := input.request_path[3]

    # .. do something with user_id, podcast_id
}
```

#### Related Resources
- [Strict-mode to phase-out the "single =" operator](https://github.com/open-policy-agent/opa/issues/4688)
- [OPA fmt 2.0](https://github.com/open-policy-agent/opa/issues/4508)

### Don't use undeclared variables

Using undeclared variables (i.e. not declared using `some` or `:=`) makes it harder to understand what's going on
in a rule, and introduces ambiguities around scope.

**Avoid**
```rego
messages[message] {
    message := input.topics[topic].body
}
```

**Prefer**
```rego
messages[message] {
    some topic
    message := input.topics[topic].body
}

# Alternatively
import future.keywords

messages[message] {
    some topic in input.topics
    message := topic.body
}

# or

messages[message] {
    message := input.topics[_].body
}
```

### Prefer sets over arrays (where applicable)

For any *unordered* sequence of *unique* values, prefer to use
[sets](https://www.openpolicyagent.org/docs/latest/policy-reference/#sets) over
[arrays](https://www.openpolicyagent.org/docs/latest/policy-reference/#arrays).

This is almost always the case for common policy data like **roles** and **permissions**.
For any applicable sequence of values, sets have the following benefits over arrays:

* Clearly communicate uniqueness and non-ordered characteristics
* Performance: set lookups are O(1) while array lookups are O(n)
* Powerful [set operations](https://www.openpolicyagent.org/docs/latest/policy-reference/#sets-2) available

**Avoid**
```rego
import future.keywords

required_roles := ["accountant", "reports-writer"]
provided_roles := [role | some role in input.user.roles]

allow {
    every required_role in required_roles {
        required_role in provided_roles
    }
}
```

**Prefer**
```rego
import future.keywords

required_roles := {"accountant", "reports-writer"}
provided_roles := {role | some role in input.user.roles}

allow {
    every required_role in required_roles {
        required_role in provided_roles
    }
}
```

**Prefer**
```rego
# Alternatively, use set intersection
allow {
    required_roles & provided_roles == required_roles
}
```

#### Related Resources
- [Five things you didn't know about OPA](https://blog.styra.com/blog/five-things-you-didnt-know-about-opa).

## Regex

### Use raw strings for regex patterns

[Raw strings](https://www.openpolicyagent.org/docs/edge/policy-language/#strings) are interpreted literally, allowing
you to avoid having to escape special characters like `\` in your regex patterns.

**Avoid**
```rego
all_digits {
    regex.match("[\\d]+", "12345")
}
```

**Prefer**
```rego
all_digits {
    regex.match(`[\d]+`, "12345")
}
```

## Imports

### Prefer importing modules over rules and functions

Importing modules rather than specific rules and functions allows you to reference them by the module name, making it
obvious where the rule or function was declared. Additionally, well-named packages help provide context to assertions.

**Avoid**
```rego
import data.user.is_admin

allow {
    is_admin
}
```

**Prefer**
```rego
import data.user

allow {
    user.is_admin
}
```

### Avoid importing `input`

While importing attributes from the global `input` variable might eliminate some levels of nesting, it makes the origin
of the attribute(s) less apparent. Clearly differentiating `input` and `data` from values, functions, and rules
defined inside of the same module helps in making things _obvious_, and few things beat obviousness!

**Avoid**
```rego
import input.request.context.user

# ... many lines of code later

fin_dept {
    # where does "user" come from?
    contains(user.department, "finance")
}
```

**Prefer**
```rego
fin_dept {
    contains(input.request.context.user.department, "finance")
}
```

**Prefer**
```rego
fin_dept {
    # Alternatively, assign an intermediate variable close to where it's referenced
    user := input.request.context.user
    contains(user.department, "finance")
}
```

**Notes / Exceptions**

In some contexts, the source of data is obvious even when imported and/or renamed. A common practice is
to rename `input` in Terraform policies for example, either via `import` or a new top-level variable.

```rego
import input as tfplan

violations[message] {
    # still obvious where "tfplan" comes from, perhaps even more so — this is generally acceptable
    some change in tfplan.resource_changes
    # ...
}
```
