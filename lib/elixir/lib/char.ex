defmodule Char do
  @moduledoc """
  Character property tests.

  These functions accept a character. The character may be an integer
  representing a codepoint ordinal, or a binary representing an UTF-8 encoded
  string. For binaries the first codepoint is tested. For graphemes consisting
  of a base character and a combining mark that tests the base character (which
  is usually what you want).
  """

  @typedoc """
  A Unicode general category, encoded as `{ major, minor }`.

  For example `{ :letter, :lowercase }`.
  """
  @type category :: { atom, atom }

  @doc """
  Is the character a letter (Unicode categories starting with

  @doc """
  Get the Unicode general category of the character.

  If an integer that doesn't represent a codepoint or an empty string is passed
  `nil` is returned.

  The category is a major/minor tuple like `{ :letter, :lowercase }`. For a
  complete list of categories see the Unicode standard.
  [Wikipedia](https://en.wikipedia.org/wiki/Unicode_character_property#General_Category)
  also has a list.

  ## Examples

      iex> Char.category(?A)
      { :letter, :uppercase }
      iex> Char.category(?é)
      { :letter, :lowercase }
      iex> Char.category("é")
      { :letter, :lowercase }
      iex> Char.category("ab")
      { :letter, :lowercase }
      iex> Char.category(" ")
      { :separator, :space }
      iex> Char.category("")
      nil
  """
  @spec category(integer | String.t) :: category | nil
  def category(char)
  def category(cp) when is_integer(cp), do: String.Unicode.category_from_ordinal(cp)
  def category(<< cp :: utf8, _ :: binary>>), do: String.Unicode.category_from_ordinal(cp)
  def category(<<>>), do: nil

  @doc """
  Get the category abbreviation from a tuple `{ major, minor }`.

  ## Examples

      iex> Char.category_abbreviation({ :letter, :lowercase })
      :Ll
      iex> Char.category_abbreviation({ :punctuation, :initial_quote })
      :Pi

  """
  @spec category_abbreviation(category) :: atom
  def category_abbreviation(cat), do: String.Unicode.category_abbreviation(cat)

  ### Predicates

  @compile { :inline, letter?: 1, upper?: 1, lower?: 1, number?: 1, digit?: 1,
                      punctuation?: 1, symbol?: 1, separator?: 1, other?: 1 }

  @doc %S"""
  Is the character a letter?
  
  A letter has Unicode general category major identifier `:letter`.

  ## Examples

      iex> Char.letter?("A")
      true
      iex> Char.letter?("3")
      false
      iex> Char.letter?("\n")
      false
      iex> Char.letter?("")
      false

  """
  def letter?(char), do: match?({ :letter, _ }, category(char))

  @doc %S"""
  Is the character an uppercase letter?

  ## Examples

      iex> Char.upper?("A")
      true
      iex> Char.upper?("a")
      false
      iex> Char.upper?("\n")
      false
      iex> Char.upper?("3")
      false

  """
  def upper?(char), do: match?({ :letter, :uppercase }, category(char))

  @doc %S"""
  Is the character a lowercase letter?

  ## Examples

      iex> Char.lower?("a")
      true
      iex> Char.lower?("A")
      false
      iex> Char.lower?("3")
      false
      iex> Char.lower?("\n")
      false
      iex> Char.lower?("")
      false

  """
  def lower?(char), do: match?({ :letter, :lowercase }, category(char))

  @doc %S"""
  Is the character a number?
  
  A number has Unicode general category major identifier `:number`.

  ## Examples

      iex> Char.number?("3")
      true
      iex> Char.number?("Ⅳ") # U+2163	ROMAN NUMERAL FOUR
      true
      iex> Char.number?("A")
      false
      iex> Char.number?("\n")
      false
      iex> Char.number?("")
      false

  """
  def number?(char), do: match?({ :number, _ }, category(char))

  @doc %S"""
  Is the character a decimal digit?
  
  ## Examples

      iex> Char.digit?("3")
      true
      iex> Char.digit?("Ⅳ") # U+2163	ROMAN NUMERAL FOUR
      false
      iex> Char.digit?("A")
      false
      iex> Char.digit?("\n")
      false
      iex> Char.digit?("")
      false

  """
  def digit?(char), do: match?({ :number, :decimal_digit }, category(char))

  @doc %S"""
  Is the character punctuation?

  ## Examples

      iex> Char.punctuation?("-")
      true
      iex> Char.punctuation?("(")
      true
      iex> Char.punctuation?("A")
      false
      iex> Char.punctuation?("3")
      false
      iex> Char.punctuation?("\n")
      false
      iex> Char.punctuation?("")
      false

  """
  def punctuation?(char), do: match?({ :punctuation, _ }, category(char))

  @doc %S"""
  Is the character a symbol?

  ## Examples

      iex> Char.symbol?("+")
      true
      iex> Char.symbol?("€")
      true
      iex> Char.symbol?("A")
      false
      iex> Char.symbol?("3")
      false
      iex> Char.symbol?("-")
      false
      iex> Char.symbol?("\n")
      false
      iex> Char.symbol?("")
      false

  """
  def symbol?(char), do: match?({ :symbol, _ }, category(char))

  @doc %S"""
  Is the character a separator?

  ## Examples

      iex> Char.separator?(" ")
      true
      iex> Char.separator?(" ") # U+1680	OGHAM SPACE MARK
      true
      iex> Char.separator?("\n")
      false
      iex> Char.separator?("A")
      false
      iex> Char.separator?("3")
      false
      iex> Char.separator?("-")
      false
      iex> Char.separator?("")
      false

  """
  def separator?(char), do: match?({ :separator, _ }, category(char))

  @doc %S"""
  Is the character in Unicode major category `:other`?

  Despite what you might think there are some pretty common codepoints under
  `:other`, such as the newline (in category `{ :other, :control }`).
  
      iex> Char.other?(0)
      true
      iex> Char.other?("\n")
      true
      iex> Char.other?(" ")
      false
      iex> Char.other?("A")
      false
      iex> Char.other?("3")
      false
      iex> Char.other?("-")
      false
      iex> Char.other?("")
      false

  """
  def other?(char), do: match?({ :other, _ }, category(char))

  @doc %S"""
  Is the character whitespace?

  The common definition of whitespace considers both a space and a newline
  character to be whitespace. In Unicode however these are in different
  categories (`{ :separator, :space }` and `{ :other, :control }` to be exact).

  Whitespace characters are identified by a different property.

  Technically OGHAM SPACE MARK (" ") is considered whitespace as well. Luckily
  ancient Irish isn't terribly popular.

  ## Examples

      iex> Char.white?(?\t)
      true
      iex> Char.white?(" ")
      true
      iex> Char.white?(" ") # U+1680	OGHAM SPACE MARK
      true
      iex> Char.white?("\n")
      true
      iex> Char.white?("A")
      false
      iex> Char.white?("3")
      false
      iex> Char.white?("-")
      false
      iex> Char.white?("")
      false

  """
  # Easiest approach is to manually test for the non-separator whitespace
  # characters.
  def white?(char)
  def white?(<<cp :: utf8, _ :: binary>>), do: white?(cp)
  def white?(<<>>), do: false 
  def white?(0x9), do: true # horizontal tab (\t)
  def white?(0xA), do: true # newline (\n)
  def white?(0xB), do: true # vertical tab (\v)
  def white?(0xC), do: true # form feed (\f)
  def white?(0xD), do: true # carriage return (\r)
  def white?(0x20), do: true # space, special cased here for speed
  def white?(0x85), do: true # next line
  def white?(c), do: separator?(c)
end
