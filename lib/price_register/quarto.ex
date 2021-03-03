defimpl Quarto.Cursor.Encode, for: DateTime do
  def convert(term), do: {"dt", DateTime.to_unix(term, :microsecond)}
end

defimpl Quarto.Cursor.Decode, for: Tuple do
  def convert({"dt", unix_timestamp}), do: DateTime.from_unix!(unix_timestamp, :microsecond)
end
