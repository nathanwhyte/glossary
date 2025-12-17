defmodule Mix.Tasks.CreateUser do
  @moduledoc """
  Creates a new user in the database.

  This task can be used in any environment (dev, test, prod) to create users.

  ## Examples

      # Create a user with email and password
      mix create_user user@example.com "secure_password_123"

      # Create and confirm a user (so they can log in immediately)
      mix create_user user@example.com "secure_password_123" --confirm

      # Create a user with a generated password
      mix create_user user@example.com --generate-password

  ## Options

    * `--confirm` - Confirms the user's email so they can log in immediately
    * `--generate-password` - Generates a random password instead of requiring one
  """
  use Mix.Task

  alias Glossary.Accounts
  alias Glossary.Repo

  @shortdoc "Creates a new user in the database"

  @switches [
    confirm: :boolean,
    generate_password: :boolean
  ]

  @aliases [
    c: :confirm,
    g: :generate_password
  ]

  def run(args) do
    # Start the application to ensure Repo is available
    Mix.Task.run("app.start")

    {opts, args, _} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    case {args, Keyword.get(opts, :generate_password, false)} do
      {[email], true} ->
        password = generate_password()
        create_user(email, password, opts)

      {[email, password], false} ->
        create_user(email, password, opts)

      _ ->
        Mix.shell().error("""
        Invalid arguments.

        Usage:
          mix create_user EMAIL PASSWORD [--confirm]
          mix create_user EMAIL --generate-password [--confirm]

        Examples:
          mix create_user user@example.com "secure_password_123"
          mix create_user user@example.com "secure_password_123" --confirm
          mix create_user user@example.com --generate-password --confirm
        """)

        System.halt(1)
    end
  end

  defp create_user(email, password, opts) do
    case Accounts.get_user_by_email(email) do
      nil ->
        case Accounts.register_user(%{email: email}) do
          {:ok, user} ->
            case Accounts.update_user_password(user, %{password: password}) do
              {:ok, {user, _tokens}} ->
                if opts[:confirm] do
                  user
                  |> Accounts.User.confirm_changeset()
                  |> Repo.update!()
                end

                Mix.shell().info("""
                ✓ User created successfully!

                Email: #{email}
                Password: #{password}
                Confirmed: #{if opts[:confirm], do: "Yes", else: "No"}
                """)

              {:error, changeset} ->
                Mix.shell().error("Failed to set password:")
                print_errors(changeset)
                System.halt(1)
            end

          {:error, changeset} ->
            Mix.shell().error("Failed to create user:")
            print_errors(changeset)
            System.halt(1)
        end

      _existing_user ->
        Mix.shell().error("User with email #{email} already exists.")
        System.halt(1)
    end
  end

  defp generate_password do
    # Generate a secure random password
    :crypto.strong_rand_bytes(24)
    |> Base.encode64()
    |> String.slice(0..31)
  end

  defp print_errors(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.each(fn {field, errors} ->
      Enum.each(errors, fn error ->
        Mix.shell().error("  #{field}: #{error}")
      end)
    end)
  end
end
