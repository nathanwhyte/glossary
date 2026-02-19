defmodule GlossaryWeb.Mappings do
  @moduledoc """
  Centralize common mapping logic for styling and behavior.
  """
  def map_entity_to_badge_color(entity) do
    case entity do
      :projects -> "badge-accent"
      :entries -> "badge-primary"
      :topics -> "badge-info"
      :commands -> "badge-warning"
      _ -> "badge-ghost"
    end
  end
end
