defmodule OpenFn.CriteriaTrigger do
  defstruct name: nil, criteria: ""

  # TODO: convert our criteria style triggers into list of expectations that
  #       work with is_match?/2
  # {
  #   "Envelope": {
  #     "Body": {
  #       "notifications": {
  #         "Notification": [],   <=== Must match that is a list, not an empty list
  #         "OrganizationId": "00DA0000000CmO4MAK"
  #       }
  #     }
  #   }
  # }
  def to_expectations(%{criteria: criteria}) do
    criteria |> Enum.map(&to_expectation(&1, "$"))
  end

  defp to_expectation({key, value}, path) do
    {path <> ".#{key}", value}
  end
end
