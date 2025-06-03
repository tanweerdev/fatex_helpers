defmodule Fatex.BahaviourHelper do
  @moduledoc """
  Provides utility functions for parsing integers from strings.

  This module handles parsing of integers from strings and ensures consistent return types.
  """

  @doc """
  Checks if a module implements the given behaviour by inspecting its `__info__/1` metadata.

  ## Parameters
  - `module`: The module to check.
  - `behaviour`: The behaviour to validate against.

  ## Examples
      iex> implements_behaviour?(MyApp.Repo, Ecto.Repo)
      true

      iex> implements_behaviour?(NotARepo, Ecto.Repo)
      false
  """
  @spec implements_behaviour?(module(), module()) :: boolean()
  def implements_behaviour?(module, behaviour) do
    is_atom(module) &&
      Code.ensure_compiled(module) &&
      function_exported?(module, :__info__, 1) &&
      :attributes
      |> module.__info__()
      |> Keyword.get(:behaviour, [])
      |> Enum.member?(behaviour)
  end
end
