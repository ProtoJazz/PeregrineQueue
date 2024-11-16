defmodule PeregrineQueueWeb.DashboardLiveTest do
  use PeregrineQueueWeb.ConnCase

  import Phoenix.LiveViewTest
  import PeregrineQueue.AdminFixtures

  @create_attrs %{}
  @update_attrs %{}
  @invalid_attrs %{}

  defp create_dashboard(_) do
    dashboard = dashboard_fixture()
    %{dashboard: dashboard}
  end

  describe "Index" do
    setup [:create_dashboard]

    test "lists all dashboard", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/dashboard")

      assert html =~ "Listing Dashboard"
    end

    test "saves new dashboard", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/dashboard")

      assert index_live |> element("a", "New Dashboard") |> render_click() =~
               "New Dashboard"

      assert_patch(index_live, ~p"/dashboard/new")

      assert index_live
             |> form("#dashboard-form", dashboard: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#dashboard-form", dashboard: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/dashboard")

      html = render(index_live)
      assert html =~ "Dashboard created successfully"
    end

    test "updates dashboard in listing", %{conn: conn, dashboard: dashboard} do
      {:ok, index_live, _html} = live(conn, ~p"/dashboard")

      assert index_live |> element("#dashboard-#{dashboard.id} a", "Edit") |> render_click() =~
               "Edit Dashboard"

      assert_patch(index_live, ~p"/dashboard/#{dashboard}/edit")

      assert index_live
             |> form("#dashboard-form", dashboard: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#dashboard-form", dashboard: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/dashboard")

      html = render(index_live)
      assert html =~ "Dashboard updated successfully"
    end

    test "deletes dashboard in listing", %{conn: conn, dashboard: dashboard} do
      {:ok, index_live, _html} = live(conn, ~p"/dashboard")

      assert index_live |> element("#dashboard-#{dashboard.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#dashboard-#{dashboard.id}")
    end
  end

  describe "Show" do
    setup [:create_dashboard]

    test "displays dashboard", %{conn: conn, dashboard: dashboard} do
      {:ok, _show_live, html} = live(conn, ~p"/dashboard/#{dashboard}")

      assert html =~ "Show Dashboard"
    end

    test "updates dashboard within modal", %{conn: conn, dashboard: dashboard} do
      {:ok, show_live, _html} = live(conn, ~p"/dashboard/#{dashboard}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Dashboard"

      assert_patch(show_live, ~p"/dashboard/#{dashboard}/show/edit")

      assert show_live
             |> form("#dashboard-form", dashboard: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#dashboard-form", dashboard: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/dashboard/#{dashboard}")

      html = render(show_live)
      assert html =~ "Dashboard updated successfully"
    end
  end
end
