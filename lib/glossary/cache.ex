defmodule Glossary.Cache do
  @moduledoc """
  Application-level cache backed by Cachex.

  Caches per-user list queries for projects, topics, tags, and recent entries.
  Caching is disabled in test environment to prevent cross-test state leakage.

  Uses the "Cache-Aside" pattern.
  """

  @cache :glossary_cache
  @ttl :timer.minutes(5)

  @doc """
  Fetches a value from the cache, computing and storing it on a miss.

  The fallback function is only called when the key is not in the cache.
  Returns the cached or freshly computed value.
  """
  def fetch(key, fun) do
    if enabled?() do
      case Cachex.get(@cache, key) do
        {:ok, nil} ->
          value = fun.()
          Cachex.put(@cache, key, value, ttl: @ttl)
          value

        {:ok, cached} ->
          cached
      end
    else
      fun.()
    end
  end

  @doc """
  Removes a key from the cache. Safe to call even if the key is absent.
  """
  def invalidate(key) do
    if enabled?() do
      Cachex.del(@cache, key)
    end

    :ok
  end

  defp enabled? do
    Application.get_env(:glossary, :cache_enabled, true)
  end
end
