defmodule Elics.Window do
  @moduledoc """
  A GenServer that sets up the main window for the Emacs clone using wxWidgets.
  """
  use GenServer

  @title "Emacs Clone in Elixir"
  @default_size {800, 600}
  @default_position {100, 100}

  ## Public API

  def start_link(_args \\ []) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  ## GenServer callbacks

  @impl true
  def init(state) do
    # Start the wxWidgets application.
    wx = :wx.new()

    # Create the main frame. We pass :wx.null() as the parent.
    frame =
      :wxFrame.new(
        :wx.null(),
        -1,
        @title,
        pos: @default_position,
        size: @default_size
      )

    # Create a panel to help with layout.
    panel = :wxPanel.new(frame, [{:winid, -1}])

    # Create a multiline text control to serve as our editing area.
    text_ctrl =
      :wxTextCtrl.new(panel, -1, [{:style, 3}]
      )

    # Connect the frame’s close event so we can clean up gracefully.
    :wxFrame.connect(frame, :close_window)

    # Show the window.
    :wxFrame.show(frame)

    new_state = Map.merge(state, %{wx: wx, frame: frame, panel: panel, text_ctrl: text_ctrl})
    {:ok, new_state}
  end

  @impl true
  def handle_info({:wx, _wxRef, _id, _obj, :close_window}, state) do
    # When the window is closed, destroy it and stop the GenServer.
    :wxFrame.destroy(state.frame)

    {:stop, :normal, state}
  end

  # Handle other wx events here. For instance, you might add key event handling,
  # menu commands, and custom emulation commands similar to Emacs.
  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
