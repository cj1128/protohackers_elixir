defmodule Protohackers.MITM.Boguscoin do
  @tonys_addr "7YWHMfk9JZe0LM0g1ZauHuiSxhI"

  def rewrite(data) do
    regex = ~r/(?<=^| )(7[[:alnum:]]{25,34})(?=$| )/
    Regex.replace(regex, data, @tonys_addr)
  end
end
