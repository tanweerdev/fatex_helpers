defmodule Fatex.FatHospital do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "fat_hospitals" do
    field(:name, :string)
    field(:location, :string)
    field(:phone, :string)
    field(:address, :string)
    field(:total_staff, :integer)
    field(:rating, :integer)

    has_many(:fat_rooms, Fatex.FatRoom)

    many_to_many(:fat_doctors, Fatex.FatDoctor, join_through: Fatex.FatHospitalDoctor)
  end

  def changeset(struct, params \\ %{}) do
    cast(struct, params, [
      :name,
      :location,
      :phone,
      :address,
      :total_staff,
      :rating
    ])
    |> validate_required([:name])
  end
end
