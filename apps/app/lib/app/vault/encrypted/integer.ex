defmodule App.Encrypted.Integer do
  use Cloak.Ecto.Integer, vault: App.Vault
end
