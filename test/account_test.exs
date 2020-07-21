defmodule AccountTest do
  use ExUnit.Case
  doctest Account

  test "account deposit" do
    {:ok, bob_account} =
      Account.new()
      |> Account.deposit(%{amount: 5000})

    assert Account.balance(bob_account) == 5000

    operations_list = Account.operations(bob_account, Date.utc_today())

    assert {%Operation{
              type: :deposit,
              status: :done,
              data: %{amount: 5000}
            }, _} = List.pop_at(operations_list, 0)
  end

  test "account transfer in" do
    {:ok, bob_account} =
      Account.new()
      |> Account.transfer_in(%{amount: 5000, sender_account_id: 1})

    assert Account.balance(bob_account) == 5000

    assert [
             %Operation{data: %{amount: 5000}, type: :transfer_in, status: :done}
           ] = Account.operations(bob_account, Date.utc_today())
  end

  test "account withdraw success" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 5000}),
         {:ok, bob_account} <- Account.withdraw(bob_account, %{amount: 3000}) do
      assert Account.balance(bob_account) == 2000

      assert [
               %Operation{data: %{amount: 5000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 3000}, type: :withdraw, status: :done}
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account withdraw failure" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 3000}),
         {:denied, _reason, bob_account} <- Account.withdraw(bob_account, %{amount: 5000}) do
      assert Account.balance(bob_account) == 3000

      assert [
               %Operation{data: %{amount: 3000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 5000, message: _m}, type: :withdraw, status: :denied}
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account transfer_out success" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 5000}),
         {:ok, bob_account} <-
           Account.transfer_out(bob_account, %{amount: 3000, recipient_account_id: 1}) do
      assert Account.balance(bob_account) == 2000

      assert [
               %Operation{data: %{amount: 5000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 3000}, type: :transfer_out, status: :done}
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account transfer_out failure" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 3000}),
         {:denied, _reason, bob_account} <-
           Account.transfer_out(bob_account, %{amount: 5000, recipient_account_id: 1}) do
      assert Account.balance(bob_account) == 3000

      assert [
               %Operation{data: %{amount: 3000}, type: :deposit, status: :done},
               %Operation{
                 data: %{amount: 5000, message: _m},
                 type: :transfer_out,
                 status: :denied
               }
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account card_transaction success" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 5000}),
         {:ok, bob_account} <- Account.card_transaction(bob_account, %{amount: 3000, card_id: 1}) do
      assert Account.balance(bob_account) == 2000

      assert [
               %Operation{data: %{amount: 5000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 3000}, type: :card_transaction, status: :done}
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account card_transaction failure" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 3000}),
         {:denied, _reason, bob_account} <-
           Account.card_transaction(bob_account, %{amount: 5000, card_id: 1}) do
      assert Account.balance(bob_account) == 3000

      assert [
               %Operation{data: %{amount: 3000}, type: :deposit, status: :done},
               %Operation{
                 data: %{amount: 5000, message: _m},
                 type: :card_transaction,
                 status: :denied
               }
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account refund success" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 5000}),
         {:ok, bob_account} <-
           Account.card_transaction(bob_account, %{amount: 3000, card_id: 1}),
         {:ok, bob_account} <-
           Account.refund(bob_account, %{operation_to_refund_id: 2}) do
      assert Account.balance(bob_account) == 5000

      assert [
               %Operation{data: %{amount: 5000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 3000}, type: :card_transaction, status: :done},
               %Operation{
                 data: %{amount: 3000, operation_to_refund_id: 2},
                 type: :refund,
                 status: :done
               }
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end

  test "account refund failure" do
    bob_account = Account.new()

    with {:ok, bob_account} <- Account.deposit(bob_account, %{amount: 5000}),
         {:ok, bob_account} <-
           Account.withdraw(bob_account, %{amount: 3000, card_id: 1}),
         {:error, _message, bob_account} <-
           Account.refund(bob_account, %{operation_to_refund_id: 2}) do
      assert Account.balance(bob_account) == 2000

      assert [
               %Operation{data: %{amount: 5000}, type: :deposit, status: :done},
               %Operation{data: %{amount: 3000}, type: :withdraw, status: :done}
             ] = Account.operations(bob_account, Date.utc_today())
    end
  end
end
