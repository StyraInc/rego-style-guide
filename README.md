# Rego Style Guide

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

1. Use `allow` for boolean rules generating the decision
1. Use `deny` or `violation` for partial rules generating the decision

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

## Data types

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

## Best Practices

### Use `opa fmt`

The `opa fmt` tool ensures consistent formatting across teams and projects. While certainly not
[perfect](https://github.com/open-policy-agent/opa/issues/4508) (yet!), unified formatting is a big win, and saves a
lot of time in code reviews arguing over style.

A good idea could be to run `opa fmt --write` on save, which can be configured in most editors. If you want to enforce
`opa fmt` formatting as part of your build pipeline, use `opa fmt --fail`.

### Use strict mode

Strict mode provides extra checks for common mistakes like redundant imports, or unused variables. Include
an `opa check --strict path/to/polices` step as part of your build pipeline.