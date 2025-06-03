defmodule Fatex.FatContextTest do
  use Fatex.ConnCase
  import Fatex.Factory
  alias Fatex.{Repo, FatRoom, FatBed}

  # Define a test context that uses our FatContext
  defmodule TestContext do
    use Fatex.FatContext, repo: Fatex.Repo
  end

  setup do
    # Explicitly start the repo for tests
    Repo.start_link()
    :ok
    # :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "first/2" do
    test "returns first record ordered by ID when no order specified" do
      room2 = insert(:room, name: "Second", inserted_at: ~N[2020-01-02 00:00:00])
      room1 = insert(:room, name: "First", inserted_at: ~N[2020-01-01 00:00:00])

      assert %{name: "First"} = TestContext.first(FatRoom)
    end

    test "returns first record with preloaded associations" do
      room = insert(:room)
      bed = insert(:bed, fat_room: room)

      result = TestContext.first(FatRoom, preload: [:fat_beds])
      assert [^bed] = result.fat_beds
    end

    test "returns nil when no records exist" do
      assert nil == TestContext.first(FatRoom)
    end
  end

  describe "last/2" do
    test "returns last record ordered by ID when no order specified" do
      room1 = insert(:room, name: "First")
      _room2 = insert(:room, name: "Second")

      assert %{name: "Second"} = TestContext.last(FatRoom)
    end

    test "respects custom order_by option" do
      room1 = insert(:room, name: "A", inserted_at: ~N[2020-01-01 00:00:00])
      room2 = insert(:room, name: "B", inserted_at: ~N[2020-01-02 00:00:00])

      assert %{name: "B"} = TestContext.last(FatRoom, order_by: :inserted_at)
    end
  end

  describe "count/2" do
    test "counts all records without conditions" do
      insert(:room)
      insert(:room)

      assert 2 == TestContext.count(FatRoom)
    end

    test "counts filtered records with conditions" do
      insert(:room, name: "A")
      insert(:room, name: "B")
      insert(:room, name: "B")

      assert 2 == TestContext.count(FatRoom, where: [name: "B"])
    end
  end

  describe "list/2" do
    test "returns all records" do
      room1 = insert(:room, name: "A")
      room2 = insert(:room, name: "B")

      results = TestContext.list(FatRoom)
      assert length(results) == 2
      assert Enum.any?(results, &(&1.name == "A"))
      assert Enum.any?(results, &(&1.name == "B"))
    end

    test "supports filtering and ordering" do
      insert(:room, name: "A", is_active: false)
      room2 = insert(:room, name: "B", is_active: true)
      room3 = insert(:room, name: "C", is_active: true)

      results = TestContext.list(FatRoom,
        where: [is_active: true],
        order_by: [desc: :name]
      )

      assert [%{name: "C"}, %{name: "B"}] = results
    end
  end

  describe "get/3" do
    test "returns {:ok, record} when found" do
      room = insert(:room)
      assert {:ok, %{id: id}} = TestContext.get(FatRoom, room.id)
      assert id == room.id
    end

    test "returns {:error, :not_found} when not found" do
      assert {:error, :not_found} = TestContext.get(FatRoom, -1)
    end

    test "preloads associations" do
      room = insert(:room)
      bed = insert(:bed, fat_room: room)

      {:ok, result} = TestContext.get(FatRoom, room.id, preload: [:fat_beds])
      assert [^bed] = result.fat_beds
    end
  end

  describe "get!/3" do
    test "returns record when found" do
      room = insert(:room)
      assert %{id: id} = TestContext.get!(FatRoom, room.id)
      assert id == room.id
    end

    test "raises when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        TestContext.get!(FatRoom, -1)
      end
    end
  end

  describe "get_by/3" do
    test "finds record by conditions" do
      room = insert(:room, name: "Special")
      assert {:ok, %{id: id}} = TestContext.get_by(FatRoom, name: "Special")
      assert id == room.id
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
    test "updates record with valid attributes" do
      room = insert(:room, name: "Old")
      assert {:ok, %{name: "New"}} = TestContext.update(room, FatRoom, %{name: "New"})
    end

    test "returns error with invalid attributes" do
      room = insert(:room)
      assert {:error, %Ecto.Changeset{}} = TestContext.update(room, FatRoom, %{name: nil})
    end
  end

  describe "delete/2" do
    test "deletes a record" do
      room = insert(:room)
      assert {:ok, _} = TestContext.delete(room)
      assert {:error, :not_found} = TestContext.get(FatRoom, room.id)
    end
  end

  describe "delete_all/2" do
    test "deletes all matching records" do
      insert(:room, name: "A")
      insert(:room, name: "B")

      assert {2, _} = TestContext.delete_all(FatRoom)
      assert [] = TestContext.list(FatRoom)
    end

    test "deletes filtered records" do
      insert(:room, name: "A")
      insert(:room, name: "B")

      assert {1, _} = TestContext.delete_all(FatRoom, where: [name: "A"])
      assert [%{name: "B"}] = TestContext.list(FatRoom)
    end
  end

  describe "upsert/5" do
    test "creates new record when not found" do
      assert {:ok, %{name: "New"}} =
               TestContext.upsert(FatRoom, [name: "Test"], %{name: "Updated"}, %{name: "New"})
    end

    test "updates existing record when found" do
      room = insert(:room, name: "Test")
      assert {:ok, %{name: "Updated"}} =
               TestContext.upsert(FatRoom, [name: "Test"], %{name: "Updated"}, %{name: "New"})
    end
  end
end
