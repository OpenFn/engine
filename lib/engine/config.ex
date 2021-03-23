defmodule Engine.Config do
  @moduledoc """
  Configuration for an Engine process, parse/1 expects either a schema-based
  path or a string.

  A config file has the following structure:

  ```yaml
  credentials:
    my-secret-credential:
      username: me
      password: shhhh
  jobs:
    job-one:
      credential: my-secret-credential
      expression: >
        alterState((state) => {
          console.log("Hi there!")
          return state;
        })
      adaptor: '@openfn/language-common'
      trigger: trigger-one

  triggers:
    trigger-one:
      criteria: '{"foo": "bar"}'
    ...
  ```

  ## Top Level Elements

  ### jobs

  A list of jobs that can be executed, key'ed by their name.

  The jobs key name must be URL safe.

  **expression**

  A string representing the JS expression that gets executed.

  **adaptor**

  The module to be used when executing the job. The module parameter is expected
  to be compatible with NodeJS' `require` schemantics.
  Assuming the modules were installed via NPM, the parameter looks like this:
  `@openfn/language-common`.

  This gets passed to the `--language` option in the core runtime.

  **trigger**

  The name of the trigger defined elsewhere in to the configuration.

  ### triggers

  The list of available triggers. Like `jobs`, they are key'ed by a URL safe name.

  **criteria**

  A JSON style matcher, which performs a 'contains' operation.

  In this example JSON message, we want to trigger when it contains a specific
  key/value pair.

  ```
  {"foo": "bar", "baz": "quux"}
  ```
  A criteria of `{"foo": "bar"}` would satisfy this test.

  ```
  {"foo": "bar", "baz": {"quux": 5}}
  ```
  A criteria of `{"baz": {"quux": 5}}` would also match this test.

  **cron**

  A cron matcher, which gets triggered at the interval specified.

  **success**

  A Flow matcher, which gets triggered on the success of the specified job.

  _Success is specified as a job exit code of `0`_

  **failure**

  A Flow matcher, which gets triggered when the specified job fails.

  _Failure is specified as **any** non-zero job exit code_
  """

  defstruct jobs: [], triggers: [], credentials: []
  @type t :: %__MODULE__{jobs: any(), triggers: any(), credentials: any()}

  alias Engine.{CriteriaTrigger, CronTrigger, FlowTrigger, Job, Credential}

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  def parse!(any) do
    case parse(any) do
      {:ok, config} ->
        config

      {:error, _} ->
        raise "Couldn't load configuration: #{inspect(any)}"
    end
  end

  @doc """
  Parse a config YAML file from the filesystem.
  """
  def parse("file://" <> path) do
    YamlElixir.read_from_file(path)
    |> case do
      {:ok, data} ->
        {:ok, __MODULE__.from_map(data)}

      any ->
        any
    end
  end

  @doc """
  Parse a config string of YAML.
  """
  def parse(str) do
    {:ok, data} = YamlElixir.read_from_string(str)

    {:ok, data |> __MODULE__.from_map()}
  end

  @doc """
  Cast a serialisable map of config into a Config struct.
  """
  @spec from_map(map) :: Engine.Config.t()
  def from_map(data) do
    trigger_data = data["triggers"]
    job_data = data["jobs"]
    credential_data = data["credentials"]

    triggers =
      for {name, trigger_opts} <- trigger_data, into: [] do
        case Map.keys(trigger_opts) do
          ["criteria"] ->
            {:ok, criteria} = Jason.decode(Map.get(trigger_opts, "criteria"))
            %CriteriaTrigger{name: name, criteria: criteria}

          ["cron"] ->
            %CronTrigger{name: name, cron: Map.get(trigger_opts, "cron")}

          ["success"] ->
            %FlowTrigger{name: name, success: Map.get(trigger_opts, "success")}

          ["failure"] ->
            %FlowTrigger{name: name, failure: Map.get(trigger_opts, "failure")}
        end
      end

    jobs =
      for {name, job_opts} <- job_data, into: [] do
        %Job{
          name: name,
          credential: Map.get(job_opts, "credential"),
          trigger: Map.get(job_opts, "trigger"),
          adaptor: Map.get(job_opts, "adaptor"),
          expression: Map.get(job_opts, "expression")
        }
      end

    credentials =
      for {name, credential_body} <- credential_data, into: [] do
        %Credential{
          name: name,
          body: credential_body
        }
      end

    %__MODULE__{
      jobs: jobs,
      triggers: triggers,
      credentials: credentials
    }
  end

  def jobs_for(%__MODULE__{} = config, triggers) do
    Enum.filter(config.jobs, fn j ->
      Enum.any?(triggers, fn t ->
        t.name == j.trigger
      end)
    end)
  end

  def triggers(%__MODULE__{} = config, type) do
    Enum.filter(
      config.triggers,
      case type do
        :flow -> fn t -> t.__struct__ == FlowTrigger end
        :cron -> fn t -> t.__struct__ == CronTrigger end
        :criteria -> fn t -> t.__struct__ == CriteriaTrigger end
      end
    )
  end

  @doc """
  Returns a list of tuples containing a tuples with the job & trigger combination
  for all triggers the provided job with subsequently trigger.
  """
  def job_triggers_for(%__MODULE__{} = config, job) do
    triggers(config, :flow)
    |> Enum.filter(fn trigger -> (trigger.success || trigger.failure) == job.name end)
    |> Enum.map(fn trigger -> {jobs_for(config, [trigger]), trigger} end)
    |> Enum.flat_map(fn {jobs, trigger} -> Enum.map(jobs, fn j -> {j, trigger} end) end)
  end

  @doc """
  Returns the :body of a credential for a job using that credential.
  """
  def credential_body_for(%__MODULE__{} = config, job) do
    case job.credential do
      nil ->
        nil

      credential_name ->
        config.credentials
        |> Enum.find(fn x -> x.name == credential_name end)
        |> Map.get(:body)
    end
  end
end
