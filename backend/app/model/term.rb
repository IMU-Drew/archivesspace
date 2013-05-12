class Term < Sequel::Model(:term)
  include ASModel
  corresponds_to JSONModel(:term)

  set_model_scope :global

  def validate
    super
    validates_unique([:vocab_id, :term, :term_type_id], :message => "Term must be unique")
    map_validation_to_json_property([:vocab_id, :term, :term_type_id], :term)
  end

  def self.set_vocabulary(json, opts)
    opts["vocab_id"] = nil

    if json["vocabulary"]
      opts["vocab_id"] = parse_reference(json["vocabulary"], opts)[:id]
    end
  end

  def self.create_from_json(json, opts = {})
    set_vocabulary(json, opts)
    obj = super

    broadcast_changes
    obj
  end

  def self.sequel_to_jsonmodel(obj, opts = {})
    json = super
    json.vocabulary = uri_for(:vocabulary, obj.vocab_id)

    json
  end


  def self.ensure_exists(json, referrer)
    begin
      self.create_from_json(json)
    rescue Sequel::ValidationFailed
      term_type_id = BackendEnumSource.id_for_value("subject_term_type", json.term_type)

      Term.find(:vocab_id => JSONModel(:vocabulary).id_for(json.vocabulary),
                :term => json.term,
                :term_type_id => term_type_id)
    end
  end

  def self.broadcast_changes
    Notifications.notify("VOCABULARY_CHANGED")
  end
end
