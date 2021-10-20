defmodule Lv.Data do

  use GenServer
  require Logger
    
  def load_data() do
    with {:ok, body} <- File.read(:code.priv_dir(:lv) ++ '/rushing.json'),
         {:ok, json} <- Jason.decode(body), do: json
  end

  def get_page(:nil), do: get_page(1)
  def get_page(pagenum) do
    GenServer.call(__MODULE__, {:page, pagenum})
  end

  def sort(param), do: GenServer.call(__MODULE__, {:sort, param})
  def sort(param, sd), do: GenServer.call(__MODULE__, {:sort, param, sd})

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [name: __MODULE__])
  end

  def init(opts) do
    Logger.debug("Lv.Data init")
    state = load_data()
    Logger.debug("Lv.Data data loaded")
    {:ok, state}
  end


  def handle_call({:sort, param}, _, state) do
    {:reply, :ok, ssort(state, param)}
  end
  def handle_call({:sort, param, sd}, _, state) do
    {:reply, :ok, ssort(state, param, sd)}
  end

  def handle_call({:page, pagenum}, _, state) do
    ln = length(state)
    page_size = 20
    num = (pagenum - 1) * page_size
    {_, r1} = Enum.split(state, num)
    prods = Enum.take(r1, page_size)
    total_pages = round(ln / page_size) + 1

    ret = %{
      prods: prods,
      page_number: pagenum,
      page_size: page_size,
      total_entries: ln,
      total_pages: total_pages
    }

    {:reply, ret, state}
  end

  def handle_call(msg, _from, state) do
    Logger.error("Lv.Data unexpected call #{inspect(msg)}")
    {:reply, :ok, state}
  end

  def handle_cast(msg, state) do
    Logger.error("Lv.Data unexpected cast #{inspect(msg)}")
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.error("Lv.Data unexpected info #{inspect(msg)}")
    {:noreply, state}
  end

  def ssort(data, "player"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "Player") end)
  def ssort(data, "team"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "Team") end)
  def ssort(data, "pos"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "Pos") end)
  def ssort(data, "ydsg"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "Yds/G") end)
  def ssort(data, "td"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "TD") end)
  def ssort(data, "lng"), do: Enum.sort_by(data, fn(e) -> Map.get(e, "Lng") end)

  def ssort(data, param, :asc), do: ssort(data, param)
  def ssort(data, param, :desc), do: ssort(data, param) |> Enum.reverse
end
