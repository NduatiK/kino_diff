defmodule KinoDiff do
  @moduledoc ~S'''
  A kino for rendering the diff between two strings.

  ## Options

    * `:layout` - whether to show the diffs `:inline` or `:split`

  ## Examples

      KinoDiff.new(
        """
        a
        b
        c
        """,
        """
        a

        c
        """,
        layout: :inline
      )


      KinoDiff.new(
        """
        a
        b
        c
        """,
        """
        a

        c
        """,
        layout: :split
      )
  '''

  @doc """
  Creates a new kino displaying the diff of the two strings.
  """
  def new(string1, string2, opts \\ [layout: :inline])

  def new(string1, string2, layout: :inline) do
    diffs =
      :diffy.diff(string1, string2)
      |> Enum.map(&to_html(&1, :inline))

    [
      ~s|<div style='
              line-height: 1.5;
              width: 100%;
              font-size: 14px;
              font-family: "JetBrains Mono", "Droid Sans Mono", monospace, Consolas, "Courier New", monospace;
              white-space: pre;
              overflow-x: auto;
          '>|,
      diffs,
      "</div>"
    ]
    |> IO.iodata_to_binary()
    |> Kino.HTML.new()
    |> then(fn frame ->
      Kino.Layout.grid(
        [
          frame
        ],
        boxed: true
      )
    end)
  end

  def new(string1, string2, layout: :split) do
    diffs =
      :diffy.diff_linemode(string1, string2)
      |> Enum.flat_map(&split_lines/1)
      |> Enum.reduce(
        [
          {:equal, "",
           %{
             ends_with_new_line: true,
             is_line: true
           }}
        ],
        fn {type, text}, [{_, _, prev} | _] = list ->
          ends_with_new_line = String.ends_with?(text, "\n")

          [
            {
              type,
              text,
              %{
                is_line: ends_with_new_line and prev.ends_with_new_line,
                ends_with_new_line: ends_with_new_line
              }
            }
            | list
          ]
        end
      )
      |> Enum.reverse()
      |> Enum.drop(1)

    [
      ~s|<div style='
              line-height: 1.5;
              width: 100%;
              display: grid;
              grid-auto-flow: column;
              grid-auto-columns: 1ch 1fr 1ch 1fr;
              grid-gap: 1ch;
              font-size: 14px;
              font-family: "JetBrains Mono", "Droid Sans Mono", monospace, Consolas, "Courier New", monospace;
              white-space: pre;
              overflow-x: auto;
          '>|,
      "<div style='width:1ch;'>",
      get_html(diffs, :old_marker),
      "</div>",
      "<div style='white-space: pre;overflow-x: auto;'>",
      get_html(diffs, :old),
      "</div>",
      "<div>",
      get_html(diffs, :new_marker),
      "</div style='width:1ch;'>",
      "<div style='white-space: pre;overflow-x: auto;'>",
      get_html(diffs, :new),
      "</div>",
      "</div>"
    ]
    |> IO.iodata_to_binary()
    |> Kino.HTML.new()
    |> then(fn frame ->
      Kino.Layout.grid(
        [
          frame
        ],
        boxed: true
      )
    end)
  end

  defp get_html(diffs, display) do
    Enum.map(diffs, fn change -> to_html(change, display) end)
  end

  defp split_lines({type, text}) do
    chunk_fun = fn element, acc ->
      if element == "\n" do
        {:cont, {type, Enum.join(Enum.reverse([element | acc]))}, []}
      else
        {:cont, [element | acc]}
      end
    end

    after_fun = fn
      [] -> {:cont, []}
      acc -> {:cont, {type, Enum.join(Enum.reverse(acc))}, []}
    end

    text
    |> String.codepoints()
    |> Enum.chunk_while([], chunk_fun, after_fun)
  end

  @green "#4ADE8080"
  @red "#E975794f"
  #
  defp to_html({:equal, text}, :inline) do
    text
  end

  defp to_html({:delete, text}, :inline) do
    ["<del style='background:#{@red};'>", text, "</del>"]
  end

  defp to_html({:insert, text}, :inline) do
    ["<ins style='background:#{@green};'>", text, "</ins>"]
  end

  defp to_html({:delete, text, _}, :old) do
    ["<span style='background-color: #{@red};'>", text, "</span>"]
  end

  defp to_html({:delete, "\n", _}, :new) do
    ["<div style='background-color: #eaeef280; width:100%;'>", "&nbsp;", "</div>"]
  end

  defp to_html({:delete, _, %{ends_with_new_line: true}}, :new) do
    ["<div style='background-color: #eaeef280; width:100%;'>", "&nbsp;", "</div>"]
  end

  defp to_html({:insert, "\n", _}, :old) do
    ["<div style='background-color: #eaeef280; width:100%;'>", "&nbsp;", "</div>"]
  end

  defp to_html({:insert, _, %{ends_with_new_line: true}}, :old) do
    ["<div style='background-color: #eaeef280; width:100%;'>", "&nbsp;", "</div>"]
  end

  defp to_html({:insert, "\n", _}, :new) do
    ["<span style='background-color: #{@green};'>", "&nbsp;\n", "</span>"]
  end

  defp to_html({:insert, text, _}, :new) do
    ["<span style='background-color: #{@green};'>", text, "</span>"]
  end

  defp to_html({:delete, _, %{ends_with_new_line: true}}, :old_marker) do
    ["-\n"]
  end

  defp to_html({:delete, _, _}, :old_marker) do
    ["-"]
  end

  defp to_html({:insert, _, %{ends_with_new_line: true}}, :new_marker) do
    ["+\n"]
  end

  defp to_html({:insert, _, _}, :new_marker) do
    ["+"]
  end

  defp to_html({_, _, %{ends_with_new_line: true}}, marker)
       when marker in [:old_marker, :new_marker] do
    ["\n"]
  end

  defp to_html({_, _, _}, marker) when marker in [:old_marker, :new_marker] do
    [""]
  end

  defp to_html({:equal, "\n", _}, :old) do
    []
  end

  defp to_html({:equal, "\n", _}, _) do
    ["\n"]
  end

  defp to_html({:equal, text, _}, _) do
    [text]
  end

  defp to_html(_, _) do
    []
  end
end
