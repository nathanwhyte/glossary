defmodule GlossaryWeb.Mappings do
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
