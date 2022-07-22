defmodule Anacounts.Accounts.BalanceTest do
  use Anacounts.DataCase, async: true

  import Anacounts.AccountsFixtures
  import Anacounts.Accounts.BalanceFixtures
  import Anacounts.AuthFixtures
  import Anacounts.TransfersFixtures

  alias Anacounts.Accounts.Balance
  alias Anacounts.Accounts.Balance.UserParams

  alias Anacounts.Repo

  # TODO reenable for_book/1 test

  @tag :skip
  describe "for_book/1" do
    setup :setup_user_fixture
    setup :setup_book_fixture

    test "balances transfers correctly", %{book: %{members: [member]} = book} do
      other_user = user_fixture()
      other_member = book_member_fixture(book, other_user)

      _money_transfer =
        money_transfer_fixture(
          amount: Money.new(10, :EUR),
          book_id: book.id,
          tenant_id: member.id,
          peers: [%{member_id: member.id}, %{member_id: other_member.id}]
        )

      assert Balance.for_book(book.id) == %{
               members_balance: %{
                 member.id => %Money{amount: 5, currency: :EUR},
                 other_member.id => %Money{amount: -5, currency: :EUR}
               },
               transactions: [
                 %{
                   amount: %Money{amount: 5, currency: :EUR},
                   from: other_member.id,
                   to: member.id
                 }
               ]
             }
    end
  end

  describe "find_user_params/1" do
    setup :setup_user_fixture
    setup :setup_balance_user_params_fixtures

    test "find user parameters for all codes", %{user: user} do
      user_params = Balance.find_user_params(user.id)

      assert length(user_params) == 1

      sorted_codes =
        user_params
        |> Enum.map(& &1.means_code)
        |> Enum.sort()

      assert sorted_codes == [:weight_by_income]
    end
  end

  describe "get_user_params_with_code/2" do
    setup :setup_user_fixture
    setup :setup_balance_user_params_fixtures

    test "gets the user param with specified code", %{user: user} do
      assert user_params = Balance.get_user_params_with_code(user.id, :weight_by_income)

      assert user_params.means_code == :weight_by_income
      assert user_params.params == %{"income" => 1234}
      assert user_params.user_id == user.id
    end

    test "returns `nil` if no user param exist for this code" do
      other_user = user_fixture()

      refute Balance.get_user_params_with_code(other_user.id, :weight_by_income)
    end
  end

  describe "upsert_user_params/1" do
    setup :setup_user_fixture

    test "creates a new user params", %{user: user} do
      assert {:ok, user_params} =
               Balance.upsert_user_params(valid_balance_user_params_attrs(user_id: user.id))

      assert user_params.user_id == user.id
      assert user_params.means_code == valid_balance_user_means_code()
      assert user_params.params == valid_balance_user_params()
    end

    test "updates the user params", %{user: user} do
      [user_params | _] = balance_user_params_fixtures(user)

      assert {:ok, updated} =
               Balance.upsert_user_params(%{
                 user_id: user_params.user_id,
                 #  TODO Change code and params once possible
                 means_code: valid_balance_user_means_code(),
                 params: valid_balance_user_params()
               })

      assert updated.user_id == user.id
      assert updated.means_code == valid_balance_user_means_code()
      assert updated.params == valid_balance_user_params()
    end

    test "fails if the means code does not exist", %{user: user} do
      assert {:error, changeset} =
               Balance.upsert_user_params(%{
                 user_id: user.id,
                 means_code: :unknown_means_code,
                 params: %{}
               })

      assert errors_on(changeset) == %{means_code: ["is invalid"]}
    end

    test "fails if the params do not match the code", %{user: user} do
      assert {:error, changeset} =
               Balance.upsert_user_params(%{
                 user_id: user.id,
                 means_code: :weight_by_income,
                 params: %{foo: :bar}
               })

      assert errors_on(changeset) == %{params: ["expected \"income\" key, containing an integer"]}
    end

    test "fails if the user does not exist" do
      assert {:error, changeset} =
               Balance.upsert_user_params(%{
                 user_id: 0,
                 means_code: :weight_by_income,
                 params: %{income: 1234}
               })

      assert errors_on(changeset) == %{user_id: ["does not exist"]}
    end
  end

  describe "delete_user_params/1" do
    setup :setup_user_fixture
    setup :setup_balance_user_params_fixtures

    test "deletes the user parameters", %{user: user, balance_user_params: [user_params | _]} do
      assert {:ok, deleted} = Balance.delete_user_params(user_params)

      assert deleted.id == user_params.id

      refute Balance.get_user_params_with_code(user.id, user_params.means_code)
      refute Repo.get(UserParams, user_params.id)
    end
  end
end
