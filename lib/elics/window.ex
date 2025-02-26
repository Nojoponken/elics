defmodule Elics.Window do
  @moduledoc """
  A GenServer that sets up the main window for the Emacs clone using wxWidgets.
  """
  use GenServer

  # Import wx constants
  alias Elics.{WX}
  # to allow ORing of flags with |||
  import Bitwise

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
    panel = :wxPanel.new(frame, [])

    # Setup sizers
    main_sizer = :wxBoxSizer.new(WX.wxVERTICAL())
    sizer_buffer = :wxStaticBoxSizer.new(WX.wxVERTICAL(), panel)
    sizer_minibuffer = :wxStaticBoxSizer.new(WX.wxVERTICAL(), panel)

    # Setup text controls
    text_buffer =
      :wxTextCtrl.new(panel, -1, [{:style, WX.wxDEFAULT() ||| WX.wxTE_MULTILINE()}])

    text_minibuffer =
      :wxTextCtrl.new(panel, -1, [{:style, WX.wxDEFAULT()}])

    # Add controls to sizers
    :wxSizer.add(sizer_buffer, text_buffer, [{:flag, WX.wxEXPAND()}, {:proportion, 1}])
    :wxSizer.add(sizer_minibuffer, text_minibuffer, [{:flag, WX.wxEXPAND()}])

    # Add sizers to main
    :wxSizer.add(main_sizer, sizer_buffer, [{:flag, WX.wxEXPAND()}, {:proportion, 1}])
    :wxSizer.add(main_sizer, sizer_minibuffer, [{:flag, WX.wxEXPAND()}])

    # Set panel sizer to main
    :wxPanel.setSizer(panel, main_sizer)

    # Connect the frame’s close event so we can clean up gracefully.
    :wxFrame.connect(frame, :close_window)

    # Show the window.
    :wxFrame.show(frame)

    new_state = Map.merge(state, %{wx: wx, frame: frame, panel: panel})
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
