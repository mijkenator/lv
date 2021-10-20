defmodule LvWeb.DataLive do
  use Phoenix.LiveView
  require Logger
  alias LvWeb.Router.Helpers, as: Routes
  alias LvWeb.DataLive
  
  def mount(_params, %{"_csrf_token" => csrf_token} = session, socket) do
  #def mount(_params, session, socket) do
    Logger.debug("DataLive mount!!!!!!!!!!   #{inspect(session)}")
    if connected?(socket), do: Phoenix.PubSub.subscribe(Lv.PubSub, "app:#{csrf_token}")

    assigns = [
      conn: socket,
      csrf_token: csrf_token
    ]

    {:ok, assign(socket, assigns)}
  end

  def render(assigns) do
    Logger.debug("DataLive render!!!!!!!!!!   #{inspect(assigns)}")
    if connected?(assigns.conn) do
      Logger.debug("DataLive render1")
      LvWeb.DataView.render("data.html", assigns)
    else
      Logger.debug("DataLive render2")
      LvWeb.DataView.render("data_loading.html", assigns)
    end
  end

  def handle_event("nav", %{"page" => page}, socket) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: Routes.live_path(socket, DataLive, page: page))}
  end
  def handle_event("srt", %{"srt" => value}, socket) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: Routes.live_path(socket, DataLive, srt: value))}
  end

  def handle_event("filter", %{"_target" => ["player"], "player" => player}, socket) do
    {:noreply, Phoenix.LiveView.push_patch(socket, to: Routes.live_path(socket, DataLive, filter: player))}
  end

  def handle_params(%{"page" => page}, _, socket) do
    Logger.debug("DataLive HP1")
    connected = connected?(socket)
    assigns = get_and_assign_page(page, connected)
    {:noreply, assign(socket, assigns)}
  end
  
  def handle_params(%{"filter" => player}, _, socket) do
    Logger.debug("DataLive Filter #{player}")
    connected = connected?(socket)
    Lv.Data.filter(player)
    assigns = Keyword.merge(get_and_assign_page(1, connected), [pfilter: player])
    {:noreply, assign(socket, assigns)}
  end
  
  def handle_params(%{"srt" => param} = pp, a2, socket) do
    Logger.debug("DataLive HP sort1 #{inspect{pp}}")
    Logger.debug("DataLive HP sort2 #{inspect{a2}}")
    Logger.debug("DataLive HP sort3 #{inspect{socket}}")
    connected = connected?(socket)
    a = socket.assigns
    srtdir = case {Map.get(a, :srt, :nil), Map.get(a, :srtdir, :nil)} do
        {:nil, _} -> :asc
        {param, :nil} -> :asc
        {param, :asc} -> :desc
        {param, :desc} -> :asc
        {_, _} -> :asc
    end
    Lv.Data.sort(param, srtdir)
    assigns = Keyword.merge(get_and_assign_page(1, connected), [srt: param, srtdir: srtdir])
    {:noreply, assign(socket, assigns)}
  end

  def handle_params(a1, a2, socket) do
    Logger.debug("DataLive HP2 --- #{inspect(a1)} --- #{inspect(a2)} ")
    connected = connected?(socket)
    assigns = get_and_assign_page(nil, connected)
    {:noreply, assign(socket, assigns)}
  end

  def handle_info({"paginate", %{"page" => page}}, socket) do
    Logger.debug("DataLive HI1")
    {:noreply, live_redirect(socket, to: Routes.live_path(socket, DataLive, page: page))}
  end

  def handle_info(msg, socket) do
    
    Logger.debug("DataLive HI  --> #{inspect(msg)} ")

    {:noreply, socket}
  end

  def get_and_assign_page(_page_number, false) do
#    product_count = 100
#
#    [
#      products: Enum.to_list(1..product_count)
#    ]
    Logger.debug("DataLive GAAP !!! ")
    [
       products: []   
    ]
  end

  def get_and_assign_page(page_number, arg) when is_binary(page_number), do: get_and_assign_page(String.to_integer(page_number),arg)
  def get_and_assign_page(page_number, _) do
    Logger.debug("DataLive GAAP --- #{inspect(page_number)} ")
    %{
      prods: prods,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    } = Lv.Data.get_page(page_number)

    [
      products: prods,
      page_number: page_number,
      page_size: page_size,
      total_entries: total_entries,
      total_pages: total_pages
    ]
  end

  
end
