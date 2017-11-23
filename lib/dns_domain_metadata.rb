# Metadata provides a key->value store for a DNS domain.
class DnsDomainMetadata
  attr_reader :kind
  attr_reader :content

  def initialize(kind:, content:)
    @kind = kind
    @content = content
  end

  def toHash()
    return {
      kind: @kind,
      content: @content,
    }
  end
end
