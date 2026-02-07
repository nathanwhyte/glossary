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
    title: "<p>What Are Corvids?</p>",
    title_text: "What Are Corvids?",
    subtitle: "<p>The smartest birds in the family</p>",
    subtitle_text: "The smartest birds in the family",
    body: """
    <p>Corvids are a family of birds that includes crows, ravens, jays, magpies, and rooks. They are found on every continent except Antarctica and South America. Scientists consider corvids among the most intelligent of all birds. They can use tools, solve puzzles, and remember human faces for years. Ravens are the largest of the passerine birds, while some jays are small and brightly coloured. Many corvids live in social groups and communicate with a wide range of calls.</p>
    """,
    body_text:
      "Corvids are a family of birds that includes crows, ravens, jays, magpies, and rooks. They are found on every continent except Antarctica and South America. Scientists consider corvids among the most intelligent of all birds. They can use tools, solve puzzles, and remember human faces for years. Ravens are the largest of the passerine birds, while some jays are small and brightly coloured. Many corvids live in social groups and communicate with a wide range of calls."
  },
  %{
    title: "<p>Corvid Intelligence</p>",
    title_text: "Corvid Intelligence",
    subtitle: "<p>Tool use, memory, and social learning</p>",
    subtitle_text: "Tool use, memory, and social learning",
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
  },
  %{
    title: "<p>Sourdough Fermentation</p>",
    title_text: "Sourdough Fermentation",
    subtitle: "<p>Wild yeast and lactobacilli in bread</p>",
    subtitle_text: "Wild yeast and lactobacilli in bread",
    body: """
    <p>Sourdough bread relies on a symbiotic culture of wild yeast and lactic acid bacteria rather than commercial yeast. The starter is a mixture of flour and water that captures microorganisms from the environment over several days of regular feeding. Lactobacilli produce lactic and acetic acids, which give sourdough its characteristic tang and also help preserve the loaf.</p>
    <p>Fermentation times are much longer than with commercial yeast, often twelve to twenty-four hours. This slow process breaks down phytic acid in the flour, making minerals like iron and zinc more bioavailable. Many bakers maintain starters for years, and some bakeries work with cultures that are decades old.</p>
    """,
    body_text:
      "Sourdough bread relies on a symbiotic culture of wild yeast and lactic acid bacteria rather than commercial yeast. The starter is a mixture of flour and water that captures microorganisms from the environment over several days of regular feeding. Lactobacilli produce lactic and acetic acids, which give sourdough its characteristic tang and also help preserve the loaf. Fermentation times are much longer than with commercial yeast, often twelve to twenty-four hours. This slow process breaks down phytic acid in the flour, making minerals like iron and zinc more bioavailable. Many bakers maintain starters for years, and some bakeries work with cultures that are decades old."
  },
  %{
    title: "<p>Tidal Locking</p>",
    title_text: "Tidal Locking",
    subtitle: "<p>Why the Moon always shows one face</p>",
    subtitle_text: "Why the Moon always shows one face",
    body: """
    <p>Tidal locking occurs when an orbiting body always shows the same face to the object it orbits. The Moon is tidally locked to Earth, so we only ever see one hemisphere from the ground. This happens because gravitational forces create tidal bulges that gradually slow the rotation of the smaller body until its rotational period matches its orbital period.</p>
    <p>Most large moons in the solar system are tidally locked to their planets. Pluto and its moon Charon are mutually locked, each always showing the same face to the other. The process takes millions to billions of years depending on the masses involved and the distance between the bodies.</p>
    """,
    body_text:
      "Tidal locking occurs when an orbiting body always shows the same face to the object it orbits. The Moon is tidally locked to Earth, so we only ever see one hemisphere from the ground. This happens because gravitational forces create tidal bulges that gradually slow the rotation of the smaller body until its rotational period matches its orbital period. Most large moons in the solar system are tidally locked to their planets. Pluto and its moon Charon are mutually locked, each always showing the same face to the other. The process takes millions to billions of years depending on the masses involved and the distance between the bodies."
  },
  %{
    title: "<p>Mycelial Networks</p>",
    title_text: "Mycelial Networks",
    subtitle: "<p>How fungi connect forest trees underground</p>",
    subtitle_text: "How fungi connect forest trees underground",
    body: """
    <p>Beneath the forest floor, fungi form vast networks of thread-like hyphae called mycelium. These networks connect the roots of different trees through mycorrhizal associations, allowing them to share nutrients and chemical signals. Ecologists sometimes call this the wood wide web.</p>
    <p>A single fungal network can span hundreds of metres and link dozens of trees across species. Older trees, called hub trees or mother trees, are often the most connected nodes. Through the network, a shaded seedling can receive carbon from a sunlit neighbour, and trees under attack by insects can send chemical warnings to others. When a tree is dying, it sometimes dumps its remaining resources into the network for its neighbours to use.</p>
    """,
    body_text:
      "Beneath the forest floor, fungi form vast networks of thread-like hyphae called mycelium. These networks connect the roots of different trees through mycorrhizal associations, allowing them to share nutrients and chemical signals. Ecologists sometimes call this the wood wide web. A single fungal network can span hundreds of metres and link dozens of trees across species. Older trees, called hub trees or mother trees, are often the most connected nodes. Through the network, a shaded seedling can receive carbon from a sunlit neighbour, and trees under attack by insects can send chemical warnings to others. When a tree is dying, it sometimes dumps its remaining resources into the network for its neighbours to use."
  },
  %{
    title: "<p>History of Map Projections</p>",
    title_text: "History of Map Projections",
    subtitle: "<p>Flattening a sphere onto paper</p>",
    subtitle_text: "Flattening a sphere onto paper",
    body: """
    <p>Every flat map distorts the globe in some way. The Mercator projection, created in 1569, preserves angles and straight-line compass bearings, which made it essential for sea navigation. However, it greatly exaggerates the size of landmasses near the poles, making Greenland appear as large as Africa when it is actually fourteen times smaller.</p>
    <p>The Peters projection, introduced in 1973, preserves relative area at the cost of distorting shapes. The Robinson projection, adopted by National Geographic in 1988, compromises on all distortion types to produce a visually balanced world map. Modern tools like the Winkel tripel and Dymaxion projections continue to seek better trade-offs. No projection can preserve area, shape, distance, and direction all at once.</p>
    """,
    body_text:
      "Every flat map distorts the globe in some way. The Mercator projection, created in 1569, preserves angles and straight-line compass bearings, which made it essential for sea navigation. However, it greatly exaggerates the size of landmasses near the poles, making Greenland appear as large as Africa when it is actually fourteen times smaller. The Peters projection, introduced in 1973, preserves relative area at the cost of distorting shapes. The Robinson projection, adopted by National Geographic in 1988, compromises on all distortion types to produce a visually balanced world map. Modern tools like the Winkel tripel and Dymaxion projections continue to seek better trade-offs. No projection can preserve area, shape, distance, and direction all at once."
  },
  %{
    title: "<p>Circadian Rhythms</p>",
    title_text: "Circadian Rhythms",
    subtitle: "<p>The body's internal clock</p>",
    subtitle_text: "The body's internal clock",
    body: """
    <p>Circadian rhythms are roughly twenty-four-hour cycles that regulate sleep, hormone release, body temperature, and other physiological processes. In mammals, the master clock sits in the suprachiasmatic nucleus of the hypothalamus and synchronises to light signals received through the eyes.</p>
    <p>Disruption of circadian rhythms through shift work, jet lag, or chronic light exposure at night has been linked to metabolic disorders, cardiovascular disease, and mood disturbances. Blue light from screens is especially effective at suppressing melatonin production, which is why sleep researchers recommend dimming devices in the evening. Some organisms, like cyanobacteria, have circadian clocks built from just three proteins that cycle through phosphorylation states without any transcription.</p>
    """,
    body_text:
      "Circadian rhythms are roughly twenty-four-hour cycles that regulate sleep, hormone release, body temperature, and other physiological processes. In mammals, the master clock sits in the suprachiasmatic nucleus of the hypothalamus and synchronises to light signals received through the eyes. Disruption of circadian rhythms through shift work, jet lag, or chronic light exposure at night has been linked to metabolic disorders, cardiovascular disease, and mood disturbances. Blue light from screens is especially effective at suppressing melatonin production, which is why sleep researchers recommend dimming devices in the evening. Some organisms, like cyanobacteria, have circadian clocks built from just three proteins that cycle through phosphorylation states without any transcription."
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

# Seed projects and associate entries
alias Glossary.Projects
alias Glossary.Projects.Project

projects = [
  %{
    # Intentionally overlaps existing entry title/body text for cross-type search checks
    name: "Corvid Intelligence",
    entry_titles: ["Corvid Intelligence", "What Are Corvids?"]
  },
  %{
    name: "Ornithology",
    entry_titles: ["What Are Corvids?", "Corvid Intelligence"]
  },
  %{
    name: "Natural Sciences",
    entry_titles: [
      "Mycelial Networks",
      "Tidal Locking",
      "Circadian Rhythms"
    ]
  }
]

for project_attrs <- projects do
  project =
    case Repo.get_by(Project, name: project_attrs.name) do
      nil ->
        {:ok, p} = Projects.create_project(%{name: project_attrs.name})
        p

      %Project{} = p ->
        p
    end

  for title <- project_attrs.entry_titles do
    case Repo.get_by(Entry, title_text: title) do
      nil ->
        :skip

      %Entry{} = entry ->
        Projects.add_entry(project, entry)
    end
  end
end
