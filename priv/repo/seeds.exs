# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Glossary.Repo.insert!(%Glossary.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Glossary.Accounts
alias Glossary.Entries.{Entry, Project, Tag, Topic}
alias Glossary.Repo

# Check if we're in dev environment (Mix is available) or production (no Mix)
is_dev = Code.ensure_loaded?(Mix) && Mix.env() == :dev

# Create admin user with UUID password
admin_password = Ecto.UUID.generate()
admin_email = "noot@nathanwhyte.dev"

case Accounts.get_user_by_email(admin_email) do
  nil ->
    {:ok, admin_user} = Accounts.register_user(%{email: admin_email})
    {:ok, _} = Accounts.update_user_password(admin_user, %{password: admin_password})

    # Confirm the user so they can log in immediately
    admin_user
    |> Accounts.User.confirm_changeset()
    |> Repo.update!()

    IO.puts("Admin user created:")
    IO.puts("  Email: #{admin_email}")
    IO.puts("  Password: #{admin_password}")

  _existing_user ->
    IO.puts("Admin user already exists: #{admin_email}")
end

# Only create test data in development
if is_dev do
  test_project =
    Repo.insert!(%Project{
      name: "Test Project w/ Entries"
    })

  test_topic =
    Repo.insert!(%Topic{
      name: "elixir",
      description: "A topic for testing purposes"
    })

  test_tag =
    Repo.insert!(%Tag{
      name: "testing"
    })

  Repo.insert!(%Project{
    name: "Test Project w/o Entries"
  })

  Repo.insert!(%Entry{
    title:
      "<p>Test Title with <code>code</code>, and it gets much, much, much longer to see if it gets properly truncated by the div</p>",
    description:
      "<p>This is a description with <code>code</code>, and it also gets much, much, much longer to see if it gets properly truncated by the div. It takes a lot more text for the description to reach the end of the div</p>",
    body:
      "<h1>This is an h1</h1><ul><li><p>level 1</p><ul><li><p>level 2</p><ul><li><p>level 3</p></li></ul></li></ul></li></ul><h2>This is an h2</h2><ol><li><p>level 1</p><ol><li><p>level 2</p><ol><li><p>level 3</p></li></ol></li></ol></li></ol><h3>This is an h3</h3><pre><code>this is a code block</code></pre><p>this is some <code>inline code</code></p>",
    status: :Published,
    project: test_project,
    topics: [test_topic, %Topic{name: "mvc"}],
    tags: [test_tag, %Tag{name: "phoenix"}]
  })

  Repo.insert!(%Entry{
    title: "<p>Meeting w/ Dad - November 1st</p>",
    description: "<p>Reviewed Equal Risk Portfolio feedback and Credit Coach plan.</p>",
    body:
      "<h1>Equal Risk Updates</h1><ul><li><p>make sure navigation buttons, and other styling, is consistent throughout the whole app</p></li><li><p>\"cap and redistribute\" options</p><ul><li><p>version history</p></li></ul></li><li><p>Dad wants us to ask Popper about starting the weights at the same value instead of with a random value</p><ul><li><p>confirm this is a valid approach and won't drastically skew outputs in certain situations</p></li></ul></li><li><p>\"Portfolio Allocation Adjustment\" section</p><ul><li><p>apply a weight reduction to each stock based on inputted percentage</p></li><li><p>per Bryan's text, useful if a portfolio has a percentage of it's total value allocated to bonds</p><ul><li><p>e.g. allocation set to 20% → multiply all equal risk portfolio weights by 0.2</p></li></ul></li></ul></li></ul><p></p>"
  })
end
