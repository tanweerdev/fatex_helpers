defmodule Fatex.FatContextTest do
  use Fatex.ConnCase
  import Fatex.Factory
  alias Fatex.FatRoom

  # Define a test context that uses our FatContext
  defmodule TestContext do
    use Fatex.FatContext, repo: Fatex.Repo
  end

  setup do
    :ok
  end

  def insert_rooms(_context) do
    room1 = insert(:room, name: "First")
    room2 = insert(:room, name: "Second")
    %{room1: room1, room2: room2}
  end

  def insert_rooms_with_beds(_context) do
    room = insert(:room, name: "Room with beds")
    bed1 = insert(:bed, fat_room: room, name: "Bed 1")
    bed2 = insert(:bed, fat_room: room, name: "Bed 2")
    %{room: room, bed1: bed1, bed2: bed2}
  end

  describe "first/2" do
    setup [:insert_rooms]

    test "returns first record" do
      result = TestContext.first(FatRoom)
      assert %FatRoom{} = result
    end

    test "returns first record with preload", %{room1: room1} do
      _bed = insert(:bed, fat_room: room1, name: "Test Bed")
      result = TestContext.first(FatRoom, where: [id: room1.id], preload: [:fat_beds])
      assert %FatRoom{} = result
      assert length(result.fat_beds) == 1
    end
  end

  describe "last/2" do
    setup [:insert_rooms]

    test "returns last record" do
      result = TestContext.last(FatRoom)
      assert %FatRoom{} = result
    end
  end

  describe "count/2" do
    setup [:insert_rooms]

    test "counts records" do
      count = TestContext.count(FatRoom)
      assert count >= 2
    end

    test "counts with conditions" do
      count = TestContext.count(FatRoom, where: [name: "First"])
      assert count >= 1
    end
  end

  describe "list/2" do
    setup [:insert_rooms]

    test "returns records" do
      results = TestContext.list(FatRoom)
      assert is_list(results)
      assert length(results) >= 2
    end

    test "supports filtering" do
      results = TestContext.list(FatRoom, where: [name: "First"])
      assert is_list(results)
      assert length(results) >= 1
    end
  end

  describe "get/3" do
    setup [:insert_rooms]

    test "returns {:ok, record} when found", %{room1: room1} do
      assert {:ok, %{id: id}} = TestContext.get(FatRoom, room1.id)
      assert id == room1.id
    end

    test "returns {:error, :not_found} when not found" do
      assert {:error, :not_found} = TestContext.get(FatRoom, -1)
    end
  end

  describe "get!/3" do
    setup [:insert_rooms]

    test "returns record when found", %{room1: room1} do
      assert %{id: id} = TestContext.get!(FatRoom, room1.id)
      assert id == room1.id
    end

    test "raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        TestContext.get!(FatRoom, -1)
      end
    end
  end

  describe "get_by/3" do
    setup [:insert_rooms]

    test "finds record by conditions", %{room1: room1} do
      assert {:ok, %{id: id}} = TestContext.get_by(FatRoom, id: room1.id)
      assert id == room1.id
    end

    test "returns error when not found" do
      assert {:error, :not_found} = TestContext.get_by(FatRoom, name: "Non-existent")
    end
  end

  describe "create/3" do
    test "creates a record with valid attributes" do
      assert {:ok, %{name: "Test"}} = TestContext.create(FatRoom, %{name: "Test"})
    end

    test "returns error with invalid attributes" do
      assert {:error, %Ecto.Changeset{}} = TestContext.create(FatRoom, %{name: nil})
    end
  end

  describe "update/4" do
    setup [:insert_rooms]

    test "updates record with valid attributes", %{room1: room1} do
      assert {:ok, %{name: "Updated"}} = TestContext.update(room1, FatRoom, %{name: "Updated"})
    end

    test "returns error with invalid attributes", %{room1: room1} do
      assert {:error, %Ecto.Changeset{}} = TestContext.update(room1, FatRoom, %{name: nil})
    end
  end

  describe "delete/2" do
    test "deletes a record" do
      room = insert(:room)
      assert {:ok, _} = TestContext.delete(room)
      assert {:error, :not_found} = TestContext.get(FatRoom, room.id)
    end
  end

  describe "upsert/5" do
    test "creates new record when not found" do
      assert {:ok, %{name: "New"}} =
               TestContext.upsert(FatRoom, [name: "NonExistent"], %{name: "Updated"}, %{name: "New"})
    end

    test "updates existing record when found" do
      _room = insert(:room, name: "Existing")
      assert {:ok, %{name: "Updated"}} =
               TestContext.upsert(FatRoom, [name: "Existing"], %{name: "Updated"}, %{name: "New"})
    end
  end
end
