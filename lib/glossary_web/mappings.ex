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

  def map_entry_status_to_badge_color(status) do
    case status do
      :draft -> "badge-warning"
      :published -> "badge-success"
      :hidden -> "badge-neutral"
      :pinned -> "badge-primary"
      _ -> ""
    end
  end
end
