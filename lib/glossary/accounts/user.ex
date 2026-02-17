defmodule Glossary.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc "User schema and changesets for account registration and credentials."

  schema "users" do
    field :username, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :authenticated_at, :utc_datetime, virtual: true

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for registration.

  Validates username and password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database. Defaults to `true`.
    * `:validate_unique` - Validates the uniqueness of the username.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> username_changeset(attrs, opts)
    |> password_changeset(attrs, opts)
  end

  @doc """
  A user changeset for changing the username.

  ## Options

    * `:validate_unique` - Validates the uniqueness of the username.
      Defaults to `true`.
  """
  def username_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username])
    |> validate_username(opts)
  end

  defp validate_username(changeset, opts) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^[a-zA-Z0-9_]+$/,
      message: "can only contain letters, numbers, and underscores"
    )
    |> validate_length(:username, min: 3, max: 30)
    |> then(fn cs ->
      if Keyword.get(opts, :validate_unique, true) do
        cs
        |> unsafe_validate_unique(:username, Glossary.Repo)
        |> unique_constraint(:username)
      else
        cs
      end
    end)
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database. Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Glossary.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end
end
