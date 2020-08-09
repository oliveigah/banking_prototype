defmodule Helpers do
  def map_keys_string_to_atom(%{} = map) do
    map
    |> Map.new(fn {k, v} -> {String.to_atom(k), map_keys_string_to_atom(v)} end)
  end

  def map_keys_string_to_atom([_ | _] = list) do
    list
    |> Enum.map(&map_keys_string_to_atom/1)
  end

  def map_keys_string_to_atom(value) do
    value
  end

  def validate_body(required_fields_spec, parsed_body, key_prefix \\ "")

  def validate_body(%{} = required_fields_spec, %{} = parsed_body, key_prefix) do
    required_fields_spec
    |> Stream.map(fn {template_key, template_value} ->
      body_value = Map.get(parsed_body, template_key)

      if is_function(template_value) do
        {"#{key_prefix}.#{template_key}", template_value.(body_value)}
      else
        validate_body(template_value, body_value, template_key)
      end
    end)
    |> Enum.map(&process_validation_list/1)
    |> List.flatten()
    |> Enum.filter(&(&1 !== nil))
    |> Enum.map(&remove_initial_dot/1)
  end

  def validate_body(%{} = required_fields_spec, nil, key_prefix) do
    required_fields_spec
    |> Enum.map(fn {template_key, _} ->
      {"#{key_prefix}.#{template_key}", false}
    end)
  end

  defp remove_initial_dot(string) do
    if String.starts_with?(string, ".") do
      {_, new_string} =
        String.to_charlist(string)
        |> List.pop_at(0)

      List.to_string(new_string)
    else
      string
    end
  end

  defp process_validation_list({path, false}) do
    path
  end

  defp process_validation_list({_path, true}) do
    nil
  end

  defp process_validation_list([_ | _] = entry) do
    Enum.map(entry, &process_validation_list/1)
  end

  defp process_validation_list(path) do
    path
  end
end