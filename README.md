# FatExUtils

[![Build Status](https://github.com/tanweerdev/fatex_helpers/actions/workflows/fatex_helpers.yml/badge.svg)](https://github.com/tanweerdev/fatex_helpers/actions)
[![Coverage Status](https://coveralls.io/repos/github/tanweerdev/fatex_helpers/badge.svg)](https://coveralls.io/github/tanweerdev/fatex_helpers)
[![hex.pm version](https://img.shields.io/hexpm/v/fatex_helpers.svg)](https://hex.pm/packages/fatex_helpers)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/fatex_helpers.svg)](https://hex.pm/packages/fatex_helpers)
[![hex.pm license](https://img.shields.io/hexpm/l/fatex_helpers.svg)](https://github.com/tanweerdev/fatex_helpers/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/tanweerdev/fatex_helpers.svg)](https://github.com/tanweerdev/fatex_helpers/commits/master)

A comprehensive utility library for Elixir applications, providing helper functions for working with Ecto changesets, data sanitization, string manipulation, and more.

---

## Installation

Getting started is simple! Add `fatex_helpers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    # Check https://hexdocs.pm/fatex_helpers for the latest version
    {:fatex_helpers, "~> 1.0.0"}
  ]
end
```

Then, run `mix deps.get` to install the package.

---

## Features

FatExUtils provides several helper modules for common Elixir/Phoenix development tasks:

### 🔧 Changeset Validation Helpers

Advanced Ecto changeset validation functions with flexible options:

```elixir
# Validate exclusive fields (only one can be present)
changeset
|> Fatex.ChangesetHelper.validate_exclusive_fields([:email, :phone])

# Treat empty strings as absent
changeset
|> Fatex.ChangesetHelper.validate_exclusive_fields([:email, :phone],
    treat_values_absent: ["", 0])

# Validate exactly one field is present
changeset
|> Fatex.ChangesetHelper.validate_exactly_one_field([:card_number, :card_token])
```

### 🗺️ Map Utilities

Comprehensive map manipulation and validation functions:

```elixir
# Check if a map contains all required keys
Fatex.MapHelper.has_all_keys?(%{a: 1, b: 2}, [:a, :b])

# Ensure a map contains only allowed keys
Fatex.MapHelper.contain_only_allowed_keys?(%{a: 1, c: 3}, [:a, :b])

# Deep merge maps
Fatex.MapHelper.deep_merge(%{a: %{b: 1}}, %{a: %{c: 2}})
# => %{a: %{b: 1, c: 2}}
```

### 🔤 String Helpers

Generate random strings and tokens:

```elixir
# Generate random string
Fatex.StringHelper.random(12)

# Generate from custom character set
Fatex.StringHelper.random_of(8, ["a", "b", "c"])
```

### 📅 DateTime Utilities

Work with dates and times:

```elixir
# Get current timestamp
Fatex.DateTimeHelper.get_current_time()

# Parse and format dates
Fatex.DateTimeHelper.parse_date("2023-01-01")
```

### 🔢 Integer & UUID Helpers

Parse and validate integers and UUIDs:

```elixir
# Parse integer safely
Fatex.IntegerHelper.parse_integer("123")

# Generate and validate UUIDs
Fatex.UuidHelper.generate_uuid()
Fatex.UuidHelper.is_valid_uuid?(uuid)
```

### 🔍 Data Sanitization

Clean and structure your data:

```elixir
defmodule MySanitizer do
  use Fatex.FatDataSanitizer
  # Define your custom sanitization functions here
end
```

---

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`mix test`)
5. Run code quality checks (`mix credo --strict`)
6. Submit a pull request

## Testing

Run the test suite:

```bash
mix test
```

Run with coverage:

```bash
mix test --cover
```

## Documentation

Generate documentation:

```bash
mix docs
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Links

- [Documentation](https://hexdocs.pm/fatex_helpers/)
- [Hex Package](https://hex.pm/packages/fatex_helpers)
- [GitHub Repository](https://github.com/tanweerdev/fatex_helpers)
