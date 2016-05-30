defmodule Display do
  @doc """
  Starts a new display process
  """
  def start_link do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Puts a value to the display into various fields
  (currently only :number), state is retained
  """
  def put(display, field, value) do
    Agent.update(display, &Map.put(&1, field, value))
  end

  @doc """
  Gets the retained value of the specified display field
  (currently only :number)
  """
  def get(display, field) do
    Agent.get(display, &Map.get(&1, field))
  end
end
