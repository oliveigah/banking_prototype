defmodule Http.Account.Transfer do
  @required_body %{
    amount: &is_number/1,
    currency: &is_atom/1,
    recipient_account_id: &is_number/1
  }

  @spec execute(map(), number()) :: {number(), map()}
  def execute(%{} = entry_body, account_id) do
    parsed_body = Helpers.parse_body_request(entry_body)

    error_list = Helpers.validate_body(@required_body, parsed_body)

    case error_list do
      [] ->
        parsed_body
        |> execute_operation(account_id)
        |> generate_http_response()

      non_empty ->
        raise(Http.Account.ValidationError, non_empty)
    end
  end

  defp execute_operation(parsed_body, account_id) do
    account_id
    |> Account.Cache.server_process()
    |> Account.Server.transfer_out(parsed_body)
  end

  defp generate_http_response(operation_response) do
    case operation_response do
      {:ok, new_balance, operation_data, recipiet_operation_data} ->
        {201,
         %{
           success: true,
           response: %{
             approved: true,
             new_balance: new_balance,
             operation: operation_data,
             recipient_operation_data: recipiet_operation_data
           }
         }}

      {:denied, reason, balance, operation_data} ->
        {
          201,
          %{
            success: true,
            response: %{
              approved: false,
              reason: reason,
              new_balance: balance,
              operation: operation_data
            }
          }
        }
    end
  end
end
