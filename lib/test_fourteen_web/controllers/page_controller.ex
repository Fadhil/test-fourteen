defmodule TestFourteenWeb.PageController do
  use TestFourteenWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
