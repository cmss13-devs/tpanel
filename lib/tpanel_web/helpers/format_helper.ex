defmodule TpanelWeb.FormatHelper do
  use TpanelWeb, :view 
  @doc """
    Gets the first 12 characters of a string if any,
    intended for use with a commit/image hash
  """
  def shorthand_revision(rev) do
    if not is_nil rev do
      String.slice(rev, 0..11)
    end
  end
  
  @doc """
    Colours text green if it matches another value,
    or red if it doesnt.
  """
  def colorize_match(input, other) do
    if not is_nil input do
      ~E"""
        <span class=<%= if input == other do "text-green-400" else "text-red-600" end %>><%= input %></span>
      """
    end
  end

end
