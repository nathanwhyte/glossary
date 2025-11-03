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

alias Glossary.Entries.{Entry, EntryTag, Project, Tag}
alias Glossary.Repo

if Mix.env() != :dev do
  IO.puts("Don't seed non-dev environments")
  System.halt(0)
end

Repo.insert!(%Project{
  id: "10000000-0000-0000-0000-000000000000",
  name: "Test Project w/ Entries"
})

Repo.insert!(%Project{
  id: "20000000-0000-0000-0000-000000000000",
  name: "Test Project w/o Entries"
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000001",
  title: "<p>Test Title with <code>code</code></p>",
  description: "<p>This is a description with <code>code</code></p>",
  body:
    "<h1>This is an h1</h1><ul><li><p>level 1</p><ul><li><p>level 2</p><ul><li><p>level 3</p></li></ul></li></ul></li></ul><h2>This is an h2</h2><ol><li><p>level 1</p><ol><li><p>level 2</p><ol><li><p>level 3</p></li></ol></li></ol></li></ol><h3>This is an h3</h3><pre><code>this is a code block</code></pre><p>this is some <code>inline code</code></p>",
  status: :Draft,
  project_id: "10000000-0000-0000-0000-000000000000"
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000002",
  title: "<p>Test empty Description</p>",
  status: :Draft,
  project_id: "10000000-0000-0000-0000-000000000000"
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000003",
  description: "<p>Test empty title.</p>",
  status: :Draft,
  project_id: "10000000-0000-0000-0000-000000000000"
})

Repo.insert!(%Tag{
  id: "00000000-1000-0000-0000-000000000000",
  name: "testing"
})

Repo.insert!(%EntryTag{
  entry_id: "00000000-0000-0000-0000-000000000001",
  tag_id: "00000000-1000-0000-0000-000000000000"
})

Repo.insert!(%EntryTag{
  entry_id: "00000000-0000-0000-0000-000000000002",
  tag_id: "00000000-1000-0000-0000-000000000000"
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000004",
  title: "<p>Meeting w/ Dad - November 1st</p>",
  description: "<p>Reviewed Equal Risk Portfolio feedback and Credit Coach plan.</p>",
  body:
    "<h1>Equal Risk Updates</h1><ul><li><p>make sure navigation buttons, and other styling, is consistent throughout the whole app</p></li><li><p>\"cap and redistribute\" options</p><ul><li><p>version history</p></li></ul></li><li><p>Dad wants us to ask Popper about starting the weights at the same value instead of with a random value</p><ul><li><p>confirm this is a valid approach and won't drastically skew outputs in certain situations</p></li></ul></li><li><p>\"Portfolio Allocation Adjustment\" section</p><ul><li><p>apply a weight reduction to each stock based on inputted percentage</p></li><li><p>per Bryan's text, useful if a portfolio has a percentage of it's total value allocated to bonds</p><ul><li><p>e.g. allocation set to 20% → multiply all equal risk portfolio weights by 0.2</p></li></ul></li></ul></li></ul><p></p>",
  status: :Draft
})
