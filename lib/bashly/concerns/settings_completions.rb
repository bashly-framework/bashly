module Bashly
  module SettingsCompletions
    COMPLETION_SHELLS = %w[bash fish zsh].freeze

    def completions
      @completions ||= get :completions
    end

    def completions?
      completions == 'minimal' || completion_shells.any?
    end

    def completion_shells
      case completions
      when nil, false, 'minimal' then []
      when 'full' then COMPLETION_SHELLS
      when String then validate_completion_shells completions
      else invalid_completions
      end
    end

  private

    def validate_completion_shells(value)
      shells = value.split(',', -1).map(&:strip)
      valid = shells.any? && (shells - COMPLETION_SHELLS).empty?
      return shells if valid && shells.uniq == shells

      invalid_completions
    end

    def invalid_completions
      raise ConfigurationError,
        "completions must be false, minimal, full, or a comma-separated list of: #{COMPLETION_SHELLS.join ', '}"
    end
  end
end
