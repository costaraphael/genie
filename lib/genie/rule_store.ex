defprotocol Genie.RuleStore do
  @moduledoc false

  def insert(store, rule)

  def lookup(store, type, fact)

  def list_rules(store)

  def list_facts(store, type)
end
