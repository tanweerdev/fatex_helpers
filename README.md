# FatExUtils: Supercharge Your Ecto Queries with Ease! 🚀

[![Build Status](https://github.com/tanweerdev/fatex_helpers/actions/workflows/fatex_helpers.yml/badge.svg)](https://github.com/tanweerdev/fatex_helpers/actions)
[![Coverage Status](https://coveralls.io/repos/github/tanweerdev/fatex_helpers/badge.svg)](https://coveralls.io/github/tanweerdev/fatex_helpers)
[![hex.pm version](https://img.shields.io/hexpm/v/fatex_helpers.svg)](https://hex.pm/packages/fatex_helpers)
[![hex.pm downloads](https://img.shields.io/hexpm/dt/fatex_helpers.svg)](https://hex.pm/packages/fatex_helpers)
[![hex.pm license](https://img.shields.io/hexpm/l/fatex_helpers.svg)](https://github.com/tanweerdev/fatex_helpers/blob/master/LICENSE)
[![Last Updated](https://img.shields.io/github/last-commit/tanweerdev/fatex_helpers.svg)](https://github.com/tanweerdev/fatex_helpers/commits/master)

---

## Description

FatExUtils is an Elixir package designed to make your life easier when working with Ecto. It simplifies query building, filtering, sorting, pagination, and data sanitization—so you can focus on what truly matters: building amazing applications. With FatExUtils, writing complex queries becomes effortless, flexible, and powerful! 💪

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

## Features & Modules

### 🔍 Fatex.FatDataSanitizer – Clean & Structured Data

Messy data? Not anymore! `DataSanitizer` helps you sanitize records and transform them into structured, clean views effortlessly. Keep your data tidy and consistent. 🎯

#### Usage of FatDataSanitizer

```elixir
defmodule Fat.MySanitizer do
  use Fatex.FatDataSanitizer
  # Define your custom sanitization functions here
end
```

---

### ⚡ FatExUtils Utilities – Small Helpers, Big Impact

FatExUtils also comes with a set of handy utility functions to streamline your workflow:

```elixir
# Check if a map contains all required keys
Fatex.MapHelper.has_all_keys?(%{a: 1, b: 2}, [:a, :b])

# Ensure a map contains only allowed keys
Fatex.MapHelper.contain_only_allowed_keys?(%{a: 1, c: 3}, [:a, :b])
```

---

## 🚀 Contributing

We love contributions! If you’d like to improve FatExUtils, submit an issue or pull request. Let’s build something amazing together! 🔥

---

## 📜 License

FatExUtils is released under the MIT License.

📖 See the full documentation at [HexDocs](https://hexdocs.pm/fatex_helpers/) for more details.
