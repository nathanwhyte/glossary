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

alias Glossary.Entries.Entry
alias Glossary.Repo

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000001",
  title: "<p>Test Title with <code>code</code></p>",
  description: "<p>This is a description with <code>code</code></p>",
  body:
    "<h1>This is an h1</h1><ul><li><p>level 1</p><ul><li><p>level 2</p><ul><li><p>level 3</p></li></ul></li></ul></li></ul><h2>This is an h2</h2><ol><li><p>level 1</p><ol><li><p>level 2</p><ol><li><p>level 3</p></li></ol></li></ol></li></ol><h3>This is an h3</h3><pre><code>this is a code block</code></pre><p>this is some <code>inline code</code></p>",
  status: :Draft
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000002",
  title: "<p>Test empty Description</p>",
  status: :Draft
})

Repo.insert!(%Entry{
  id: "00000000-0000-0000-0000-000000000003",
  description: "<p>Test empty title.</p>",
  status: :Draft
})
