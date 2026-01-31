defmodule Glossary.Repo do
  use Ecto.Repo,
    otp_app: :glossary,
    adapter: Ecto.Adapters.Postgres
end
