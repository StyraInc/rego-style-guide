# Rego Style Guide

Given the general purpose nature of Open Policy Agent (OPA) — and the versatility of the Rego language — there is
often more ways than one to express what one wants to accomplish. Additionally, the Rego language has seen countless
of improvements over the years, whether in the form of new features, built-in functions or language constructs. While
it's "easy" to add things, great care needs to be taken about how to deal with _existing_ features and constructs, and
with a strong commitment to not break backwards compatibility, sometimes the best way forward is simply to provide
recommendations rather than deprecations or even having things removed.

The purpose of this style guide is to provide a collection of recommendations and best practices for authoring modern
Rego. As with any style guide - the advice provided here is subjective. Although based on years of experience working
with OPA and Rego, the final decision on style yours to make.

When deciding on style within a larger group of developers, finding acceptance (if not consensus) on a set of principles
is often more important than the principles themselves. Use the rules provided here as you wish: adopt the guide in its
entirety, pick what you like, or go your own way.

## Contents

- [General Advice](#general-advice)
  - [Optimize for readability, not performance](#optimize-for-readability-not-performance)
  - [Use metadata annotations](#use-metadata-annotations)
- [Style](#style)
  - [Prefer snake_case for rule names and variables](#prefer-snakecase-for-rule-names-and-variables)
  - [Keep line length <= 120 characters](#keep-line-length--120-characters)
- [Rules](#rules)
  - [Use established naming conventions](#use-established-naming-conventions)
  - [Use helper rules](#use-helper-rules)
  - [Prefer repeated named rules over repeating rule bodies](#prefer-repeated-named-rules-over-repeating-rule-bodies)
- [Variables and Data Types](#variables-and-data-types)
  - [Don't use unification operator for assignment or comparison](#dont-use-unification-operator-for-assignment-or-comparison)
  - [Don't use undeclared variables](#dont-use-undeclared-variables)
  - [Prefer sets over arrays (where applicable)](#prefer-sets-over-arrays-where-applicable)
- [Regex](#regex)
  - [Use raw strings for regex patterns](#use-raw-strings-for-regex-patterns)
- [Imports](#imports)
  - [Prefer importing modules over rules and functions](#prefer-importing-modules-over-rules-and-functions)
  - [Avoid importing `input`](#avoid-importing-input)
- [Best Practices](#best-practices)
  - [Use `opa fmt`](#use-opa-fmt)
  - [Use strict mode](#use-strict-mode)

## General Advice

### Optimize for readability, not performance

Rego is a declarative language, which in the best of worlds means you express **what** you want rather than **how** it
should be retrieved. When authoring policy, do not try to be "smart" about assumed performance characteristics or
optimizations. That's what OPA should worry about!

Optimize for **readbility** and **obviousness**. Optimize for performance *only* if you've identified performance
issues in your policy, and even if you do — making your policy more compact or "clever" almost never helps addressing
the problem at hand.

#### Related Resources
- [Policy Performance](https://www.openpolicyagent.org/docs/latest/policy-performance/)

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

With more than 150 built-in functions tailor-made for policy evaluation, there's a good chance that some of them can
help you accomplish your goal.

## Style

### Prefer snake_case for rule names and variables

The built-in functions use `snake_case` for naming — follow that convention for your own rules, functions and variables.

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

### Use established naming conventions

Policy that sticks to established naming conventions is easier to understand.

1. Use `allow` for boolean rules generating a decision
1. Use `deny`, `enforce`, or `violation` for partial rules generating a decision

### Use helper rules

Helper rules makes policies more readable, and for repeated conditions more performant as well.

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

### Prefer repeated named rules over repeating rule bodies

While (purposely!) not well-documented, a rule may have its **body** repeated to describe OR conditions, identical
to what you'd normally see repeated in another rule declaration with the same name. While this tends to make things
more compact, it results in policy which could be difficult to understand, even for someone carefully reading the
documentation.

**Avoid**
```rego
allow {
    startswith(input.request.path, "/public")
} {
    startswith(input.request.path, "/static")
}
```

**Prefer**
```rego
allow {
    startswith(input.request.path, "/public")
}

allow {
    startswith(input.request.path, "/static")
}
```

**Prefer**
```rego
allow {
    # Alternatively, delegate OR condition to helper rule
    startswith_any(input.request.path, {"/public", "/static"})
}

startswith_any(str, prefixes) {
    some prefix in prefixes
    startswith(str, prefix)
}
```

## Variables and Data Types

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
any context, there is generally few reasons to use the unification operator in modern Rego.

#### Related Resources
- [Strict-mode to phase-out the "single =" operator](https://github.com/open-policy-agent/opa/issues/4688)
- [OPA fmt 2.0](https://github.com/open-policy-agent/opa/issues/4508)

### Don't use undeclared variables

Using undeclared variables (i.e. not declred using `some` or `:=`) makes it harder to understand what's going on
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

Related reading: [Five things you didn't know about OPA](https://blog.styra.com/blog/five-things-you-didnt-know-about-opa).

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
obvious where the rule or function was declared. Additionally, well named packages help provide context to assertions.

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
of the attribute(s) less apparent. Clearly differentiating `input` and `data` from and values, functions and rules
defined inside of the same module helps making things _obvious_, and few things beat obviousness!

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

In some contexts, the source of data is obvious even when imported and/or renamed. A common practice is for example
to rename `input` in Terraform policies, either via `import` or a new top level variable.

```rego
import input as tfplan

violations[message] {
    # still obvious where "tfplan" comes from, perhaps even more so — this is generally acceptable
    some change in tfplan.resource_changes
    # ...
}
```

## Best Practices

Some practices commonly considered best for Rego development.

### Use `opa fmt`

The `opa fmt` tool ensures consistent formatting across teams and projects. While certainly not
[perfect](https://github.com/open-policy-agent/opa/issues/4508) (yet!), unified formatting is a big win, and saves a
lot of time in code reviews arguing over style.

A good idea could be to run `opa fmt --write` on save, which can be configured in most editors. If you want to enforce
`opa fmt` formatting as part of your build pipeline, use `opa fmt --fail`.

### Use strict mode

Strict mode provides extra checks for common mistakes like redundant imports, or unused variables. Include
an `opa check --strict path/to/polices` step as part of your build pipeline.
