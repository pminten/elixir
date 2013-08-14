defmodule Xml do
  @moduledoc """
  Utilities for creating XML documents.

  This isn't very sophisticated, but for simple XML documents it will do fine.
  """

  # An XML name is either unqualified or qualified.
  # It's not possible to manually specify a full namespace URI,
  # use a namespace introduction (xmlns:...=...) for that.
  #
  # Most XML names can be specified as atoms, strings are best saved for weird
  # names with hyphens and such.
  #
  # Raw content can be passed by putting the content in a tuple with the second
  # argument being :raw (having that as a second argument distinguishes the
  # tuple from an element).
  @type namepart :: atom | String.t
  @type name :: namepart | { namepart, namepart }
  @type content :: element | String.t | { String.t, :raw }
  @type element :: { name, [ { name, String.t } ], [ content ] }
                 | { name, [ { name, String.t } ] }
                 | { name }

  # An option for serialization.
  @type serialize_option :: :iolist

  @xmlheader("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")

  @doc """
  Serialize an element tree to XML.

  To return an IO list pass the :iolist option.
  To skip the standard <?xml... header pass the :skipheader option.
  """
  @spec serialize(element) :: String.t
  @spec serialize(element, [serialize_option]) :: String.t | iolist
  def serialize(element, opts // []) do
    sl = do_serialize(element)
    sl = if Enum.member?(opts, :skipheader), do: sl, else: [@xmlheader|sl]
    if Enum.member?(opts, :iolist) do
      sl
    else
      iolist_to_binary(sl)
    end
  end

  @spec do_serialize(element) :: iolist
  defp do_serialize({ name }) do
    ["<", serialize_name(name), "/>"]
  end
  defp do_serialize({ name, [] }) do
    do_serialize({ name })
  end
  defp do_serialize({ name, attrs }) do
    ["<", serialize_name(name), " ", serialize_attrs(attrs), "/>"]
  end
  defp do_serialize({ name, attrs, [] }) do
    do_serialize({ name, attrs })
  end
  defp do_serialize({ name, attrs, "" }) do
    do_serialize({ name, attrs })
  end
  defp do_serialize({ name, attrs, content }) do
    if content != [] and content != "" do
      n = serialize_name({ name })
      ["<", n, serialize_attrs(attrs), ">",
        serialize_content(content),
       "</", n, ">"]
    else
      do_serialize({ name, attrs })
    end
  end

  @spec serialize_name(name) :: iolist
  defp serialize_name(a) when is_atom(a) do
    atom_to_binary(a)
  end
  defp serialize_name(s) when is_binary(s) do
    iolist_to_binary(s)
  end
  defp serialize_name({a, b}) do
    [serialize_name(a), ":", serialize_name(b)]
  end

  @spec serialize_attrs([ { name, String.t } ]) :: iolist
  defp serialize_attrs([]) do
    ""
  end
  defp serialize_attrs(attrs) do
    " " <> Enum.map_join(attrs, " ", &serialize_attr/1)
  end

  @spec serialize_attr({ name, String.t }) :: iolist
  defp serialize_attr({name, val}) do
    serialize_name(name) <> "=\"" <> escape(val) <> "\""
  end

  @spec serialize_content(content | [ content ]) :: iolist
  defp serialize_content(l) when is_list(l) do
    Enum.map(&serialize_content/1)
  end

  defp serialize_content({s, :raw}) do
    s
  end

  defp serialize_content({_, _, _} = t) do
    serialize(t)
  end
  defp serialize_content(b) when is_binary(b) do
    escape(b)
  end

  @doc """
  Escape a string for use in XML.
  """
  @spec escape(String.t) :: String.t
  def escape(s) do
    iolist_to_binary(escape_to_iolist(s))
  end
  
  @doc """
  Escape a string for use in XML to an iolist.
  """
  @spec escape_to_iolist(String.t) :: iolist
  def escape_to_iolist(str) do
    # An attempt to be efficient by munching as much non-escaped chars as
    # possible instead of adding them one by one to a binary.
    lc [s] inlist Regex.scan(%r{['"&<>]|[^'"&<>]+}, str) do
      case s do
        <<?',_::binary>> -> "&apos;"
        <<?",_::binary>> -> "&quot;"
        <<?&,_::binary>> -> "&amp;"
        <<?<,_::binary>> -> "&lt;"
        <<?>,_::binary>> -> "&gt;"
        _                -> s
      end
    end
  end
end
