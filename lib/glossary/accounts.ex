defmodule Glossary.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Glossary.Accounts.Scope
  alias Glossary.Accounts.{User, UserToken}
  alias Glossary.Entries
  alias Glossary.Repo

  ## Database getters

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_user_by_username("alice")
      %User{}

      iex> get_user_by_username("unknown")
      nil

  """
  def get_user_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username)
  end

  @doc """
  Gets a user by username and password.

  ## Examples

      iex> get_user_by_username_and_password("alice", "correct_password")
      %User{}

      iex> get_user_by_username_and_password("alice", "invalid_password")
      nil

  """
  def get_user_by_username_and_password(username, password)
      when is_binary(username) and is_binary(password) do
    user = Repo.get_by(User, username: username)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user with username and password.

  ## Examples

      iex> register_user(%{username: "alice", password: "valid_password"})
      {:ok, %User{}}

      iex> register_user(%{username: "bad!"})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, opts \\ []) do
    create_welcome? = Keyword.get(opts, :create_welcome, true)

    transact_user_registration(attrs, create_welcome?)
  end

  defp transact_user_registration(attrs, create_welcome?) do
    case Repo.transact(fn -> do_register_user(attrs, create_welcome?) end) do
      {:ok, user} -> {:ok, user}
      {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
    end
  end

  defp do_register_user(attrs, create_welcome?) do
    with {:ok, user} <-
           %User{}
           |> User.registration_changeset(attrs)
           |> Repo.insert(),
         {:ok, _entry} <- maybe_create_welcome_entry(user, create_welcome?) do
      {:ok, user}
    else
      {:error, %Ecto.Changeset{} = changeset} -> Repo.rollback(changeset)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user registration changes.
  """
  def change_user_registration(user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_unique: false)
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 20 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Glossary.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  defp maybe_create_welcome_entry(_user, false), do: {:ok, nil}

  defp maybe_create_welcome_entry(user, true) do
    user
    |> Scope.for_user()
    |> Entries.create_entry(welcome_entry_attrs())
  end

  defp welcome_entry_attrs do
    %{
      title: "<h1>Welcome to Glossary</h1>",
      title_text: "Welcome to Glossary",
      subtitle:
        "<p>Start organizing notes with entries, projects, topics, and powerful search.</p>",
      subtitle_text:
        "Start organizing notes with entries, projects, topics, and powerful search.",
      body: """
      <h2>How your glossary is organized</h2>
      <p><strong>Entries</strong> are your core notes. Keep ideas, definitions, snippets, and references here.</p>
      <p><strong>Projects</strong> group entries by initiative, deliverable, or workflow.</p>
      <p><strong>Topics</strong> group entries by subject area so you can connect related concepts across projects.</p>
      <p><strong>Tags</strong> are planned next, and will add lightweight labels for cross-cutting filters.</p>

      <h2>Search and commands</h2>
      <p>Open search with <code>Cmd+K</code> (or the search button).</p>
      <ul>
        <li><code>@</code> projects</li>
        <li><code>%</code> entries</li>
        <li><code>#</code> topics</li>
        <li><code>!</code> commands</li>
      </ul>
      <p>You can also type naturally without a prefix to see mixed results and suggested commands.</p>

      <h2>Editor built-ins to try</h2>
      <ul>
        <li>Headings for structure</li>
        <li><strong>Bold</strong> and <em>italic</em> for emphasis</li>
        <li>Bullet lists and checklists for task-oriented notes</li>
        <li>Code blocks for snippets and terminal commands</li>
        <li>Blockquotes for key takeaways</li>
        <li>Links to references and docs</li>
      </ul>
      """,
      body_text: """
      How your glossary is organized

      Entries are your core notes. Keep ideas, definitions, snippets, and references here.
      Projects group entries by initiative, deliverable, or workflow.
      Topics group entries by subject area so you can connect related concepts across projects.
      Tags are planned next, and will add lightweight labels for cross-cutting filters.

      Search and commands

      Open search with Cmd+K (or the search button).
      @ projects
      % entries
      # topics
      ! commands

      You can also type naturally without a prefix to see mixed results and suggested commands.

      Editor built-ins to try

      Headings for structure
      Bold and italic for emphasis
      Bullet lists and checklists for task-oriented notes
      Code blocks for snippets and terminal commands
      Blockquotes for key takeaways
      Links to references and docs
      """
    }
  end
end
