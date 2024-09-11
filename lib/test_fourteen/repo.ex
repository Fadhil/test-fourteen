defmodule TestFourteen.Repo do
  use Ecto.Repo,
    otp_app: :test_fourteen,
    adapter: Ecto.Adapters.Postgres
end
