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
#

alias Glossary.Repo
alias Glossary.Entries
alias Glossary.Entries.Entry

# Entry body is stored as HTML (from Tiptap editor) with a plain text copy in body_text
entries = [
  %{
    title: "Lorem Ipsum One",
    subtitle: "Single paragraph",
    body: """
    <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
    """,
    body_text:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
  },
  %{
    title: "Lorem Ipsum Two",
    subtitle: "Two paragraphs with formatting",
    body: """
    <p>Lorem ipsum dolor sit amet, <strong>consectetur adipiscing elit</strong>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>
    <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. <em>Excepteur sint occaecat cupidatat non proident</em>, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>
    <h2>Second Section</h2>
    <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>
    <ul>
      <li>Nemo enim ipsam voluptatem quia voluptas sit aspernatur</li>
      <li>Aut odit aut fugit, sed quia consequuntur magni dolores</li>
      <li>Neque porro quisquam est, qui dolorem ipsum</li>
    </ul>
    """,
    body_text:
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Second Section Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur Aut odit aut fugit, sed quia consequuntur magni dolores Neque porro quisquam est, qui dolorem ipsum"
  }
]

{inserted, skipped} =
  Enum.reduce(entries, {0, 0}, fn attrs, {inserted_count, skipped_count} ->
    case Repo.get_by(Entry, title: attrs.title) do
      nil ->
        {:ok, _entry} = Entries.create_entry(attrs)
        {inserted_count + 1, skipped_count}

      %Entry{} ->
        {inserted_count, skipped_count + 1}
    end
  end)

IO.puts("Seeded entries: inserted=#{inserted} skipped=#{skipped}")
