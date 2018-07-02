defprotocol Genie.RuleStore do
  @moduledoc false

  def insert(store, rule)

  def lookup(store, type, fact)
end
