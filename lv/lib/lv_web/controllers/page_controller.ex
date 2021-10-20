defmodule LvWeb.PageController do
  use LvWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def download(conn, _params) do
   content = Lv.Data.get_data()
   ret = Jason.encode!(content)

   flst  = ["Player","Team","Pos","Att","Att/G","Yds","Avg","Yds/G","TD","Lng","1st","1st%","20+","40+","FUM"]
   fname = UUID.uuid4()
   file  = File.open!("/tmp/#{fname}.csv", [:write, :utf8])
   content
        |> Enum.map(fn(e) -> for n <- flst, do: Map.get(e, n, " ")  end)
        |> CSV.encode 
        |> Enum.each(&IO.write(file, &1))

   conn
    |> put_resp_content_type("application/csv")
    |> put_resp_header("content-disposition", "attachment; filename=#{fname}.csv")
    |> send_file(200, "/tmp/#{fname}.csv") 
  end

end
