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

## Regex

### Use raw strings for regex patterns

[Raw strings](https://www.openpolicyagent.org/docs/edge/policy-language/#strings) are interpreted literally, allowing
you to avoid having to escape special characters like `\` in your regex patterns.

**Avoid**
```rego
allow {
	regex.match(`[\d]+`, "12345")
}
```

**Prefer**
```rego
allow {
	regex.match("[\\d]+", "12345")
}
```

## Best Practices

### Use strict mode

Strict mode provides extra checks for common mistakes like redundant imports, or unused variables. Include
an `opa check --strict path/to/polices` step as part of your build pipeline.