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
    title: "What Are Corvids?",
    subtitle: "The smartest birds in the family",
    body: """
    <p>Corvids are a family of birds that includes crows, ravens, jays, magpies, and rooks. They are found on every continent except Antarctica and South America. Scientists consider corvids among the most intelligent of all birds. They can use tools, solve puzzles, and remember human faces for years. Ravens are the largest of the passerine birds, while some jays are small and brightly coloured. Many corvids live in social groups and communicate with a wide range of calls.</p>
    """,
    body_text:
      "Corvids are a family of birds that includes crows, ravens, jays, magpies, and rooks. They are found on every continent except Antarctica and South America. Scientists consider corvids among the most intelligent of all birds. They can use tools, solve puzzles, and remember human faces for years. Ravens are the largest of the passerine birds, while some jays are small and brightly coloured. Many corvids live in social groups and communicate with a wide range of calls."
  },
  %{
    title: "Corvid Intelligence and Behaviour",
    subtitle: "Tool use, memory, and social learning",
    body: """
    <p>New Caledonian crows make and use tools in the wild, such as hooked sticks to pull insects from bark. <strong>Researchers have watched them bend wire into hooks</strong> when no ready-made tool was available. Scrub jays and other corvids cache thousands of food items and remember where they hid them months later.</p>
    <p>Magpies have been shown to pass the mirror test, meaning they can recognise themselves in a reflection. <em>American crows can recognise and remember human faces</em> that have threatened them and will scold those people years later. Corvids also learn from each other, so clever solutions spread through groups.</p>
    <h2>Why It Matters</h2>
    <p>Studying corvids helps us understand how intelligence evolves in animals that are not primates. Their ability to plan, use tools, and cooperate suggests that complex cognition can arise in very different branches of the tree of life.</p>
    <ul>
      <li>Corvids use tools in the wild and in experiments</li>
      <li>They cache food and remember thousands of locations</li>
      <li>Some species pass the mirror test for self-recognition</li>
    </ul>
    """,
    body_text:
      "New Caledonian crows make and use tools in the wild, such as hooked sticks to pull insects from bark. Researchers have watched them bend wire into hooks when no ready-made tool was available. Scrub jays and other corvids cache thousands of food items and remember where they hid them months later. Magpies have been shown to pass the mirror test, meaning they can recognise themselves in a reflection. American crows can recognise and remember human faces that have threatened them and will scold those people years later. Corvids also learn from each other, so clever solutions spread through groups. Why It Matters Studying corvids helps us understand how intelligence evolves in animals that are not primates. Their ability to plan, use tools, and cooperate suggests that complex cognition can arise in very different branches of the tree of life. Corvids use tools in the wild and in experiments They cache food and remember thousands of locations Some species pass the mirror test for self-recognition"
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
