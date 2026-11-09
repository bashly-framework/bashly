describe Settings do
  subject { BaselineSettings.clone }

  describe 'standard value' do
    it 'returns a predefined default value' do
      expect(subject.tab_indent).to be false
    end

    context 'when settings.yml exists' do
      before do
        reset_tmp_dir
        File.write 'spec/tmp/settings.yml', 'source_dir: somedir'
        subject.source_dir = nil
      end

      it 'returns the value from the settings file' do
        Dir.chdir 'spec/tmp' do
          expect(subject.source_dir).to eq 'somedir'
        end
      end
    end

    context 'when bashly-settings.yml exists' do
      before do
        reset_tmp_dir
        File.write 'spec/tmp/bashly-settings.yml', 'source_dir: somedir'
        subject.source_dir = nil
      end

      it 'returns the value from the settings file' do
        Dir.chdir 'spec/tmp' do
          expect(subject.source_dir).to eq 'somedir'
        end
      end
    end

    context 'when BASHLY_SETTINGS_PATH is set' do
      before do
        reset_tmp_dir
        File.write 'spec/tmp/my-settings.yml', 'source_dir: from-var'
        ENV['BASHLY_SETTINGS_PATH'] = 'spec/tmp/my-settings.yml'
        subject.source_dir = nil
      end

      after { ENV['BASHLY_SETTINGS_PATH'] = nil }

      it 'returns the value from the settings file' do
        expect(subject.source_dir).to eq 'from-var'
      end
    end

    context 'when its corresponding env var is set' do
      let(:original_value) { ENV['BASHLY_TAB_INDENT'] }

      before { described_class.tab_indent = nil }
      after { ENV['BASHLY_TAB_INDENT'] = original_value }

      it 'returns true when the env var is truthy' do
        %w[1 true yes].each do |value|
          ENV['BASHLY_TAB_INDENT'] = value
          expect(subject.tab_indent).to be true
        end
      end

      it 'returns false when the env var is falsy' do
        %w[0 false no].each do |value|
          ENV['BASHLY_TAB_INDENT'] = value
          expect(subject.tab_indent).to be false
        end
      end

      it 'returns the env var value itself otherwise' do
        ENV['BASHLY_TAB_INDENT'] = 'anything at all'
        expect(subject.tab_indent).to eq ENV['BASHLY_TAB_INDENT']
      end
    end

    context 'when using env suffix overrides' do
      before do
        reset_tmp_dir
        File.write 'spec/tmp/settings.yml', 'formatter_production: shfmt --minify'
        subject.formatter = nil
      end

      it 'returns the default value when it is not the specified environment' do
        Dir.chdir 'spec/tmp' do
          expect(subject.formatter).to eq 'internal'
        end
      end

      it 'returns the config value when it is the specified environment' do
        Dir.chdir 'spec/tmp' do
          subject.env = :production
          expect(subject.formatter).to eq 'shfmt --minify'
        end
      end
    end
  end

  describe '::env' do
    it 'returns :development by default' do
      expect(subject.env).to eq :development
    end
  end

  describe '::argfile_var' do
    it 'returns its default value' do
      expect(subject.argfile_var).to eq 'ARGFILE'
    end
  end

  describe '::extra_lib_dirs' do
    context 'when set using env var as a comma delimited string' do
      before { ENV['BASHLY_EXTRA_LIB_DIRS'] = 'one,two' }
      after { ENV['BASHLY_EXTRA_LIB_DIRS'] = nil }

      it 'converts comma delimited string to an array' do
        expect(subject.extra_lib_dirs).to match_array %w[one two]
      end
    end

    context 'when provided as an array' do
      let(:config) { Config.new({ 'extra_lib_dirs' => %w[item1 item2] }) }

      it 'returns the array as is' do
        allow(subject).to receive(:user_settings).and_return(config)
        expect(subject.extra_lib_dirs).to match_array %w[item1 item2]
      end
    end
  end

  describe '::completion_shells' do
    it 'disables completions by default' do
      expect(subject.completions?).to be false
      expect(subject.completion_shells).to be_empty
    end

    it 'disables completions when set to false' do
      subject.completions = false

      expect(subject.completions?).to be false
      expect(subject.completion_shells).to be_empty
    end

    it 'enables only the runtime engine when set to minimal' do
      subject.completions = 'minimal'

      expect(subject.completions?).to be true
      expect(subject.completion_shells).to be_empty
    end

    it 'enables every supported shell when set to full' do
      subject.completions = 'full'

      expect(subject.completion_shells).to eq %w[bash fish zsh]
    end

    it 'accepts one shell' do
      subject.completions = 'zsh'

      expect(subject.completion_shells).to eq %w[zsh]
    end

    it 'accepts comma-separated shells with optional whitespace' do
      subject.completions = 'bash, fish, zsh'

      expect(subject.completion_shells).to eq %w[bash fish zsh]
    end

    it 'accepts the setting from the environment' do
      original_value = ENV['BASHLY_COMPLETIONS']
      ENV['BASHLY_COMPLETIONS'] = 'zsh,bash'
      subject.completions = nil

      expect(subject.completion_shells).to eq %w[zsh bash]
    ensure
      ENV['BASHLY_COMPLETIONS'] = original_value
    end

    it 'rejects invalid values' do
      invalid_values = [true, '', 'all', 'bash+zsh', 'ksh', 'bash,', 'bash,,zsh', 'bash,bash']

      invalid_values.each do |value|
        subject.completions = value
        expect { subject.completion_shells }.to raise_error ConfigurationError
      end
    end
  end

  describe '::production?' do
    it 'returns false by default' do
      expect(subject.production?).to be false
    end

    context 'when env == :production' do
      before { subject.env = :production }
      after { subject.env = nil }

      it 'returns true' do
        expect(subject.production?).to be true
      end
    end
  end

  describe '::enabled?' do
    context 'when the value is always' do
      before { subject.enable_header_comment = 'always' }

      it 'returns true' do
        expect(subject.enabled? :header_comment).to be true
      end
    end

    context 'when the value is never' do
      before { subject.enable_header_comment = 'never' }

      it 'returns false' do
        expect(subject.enabled? :header_comment).to be false
      end
    end

    context 'when the value is production in a production env' do
      before do
        subject.enable_header_comment = 'production'
        subject.env = :production
      end

      after { subject.env = nil }

      it 'returns true' do
        expect(subject.enabled? :header_comment).to be true
      end
    end

    context 'when the value is production in a development env' do
      before do
        subject.enable_header_comment = 'production'
        subject.env = :development
      end

      after { subject.env = nil }

      it 'returns false' do
        expect(subject.enabled? :header_comment).to be false
      end
    end

    context 'when the value is development in a production env' do
      before do
        subject.enable_header_comment = 'development'
        subject.env = :production
      end

      after { subject.env = nil }

      it 'returns false' do
        expect(subject.enabled? :header_comment).to be false
      end
    end

    context 'when the value is development in a development env' do
      before do
        subject.enable_header_comment = 'development'
        subject.env = :development
      end

      after { subject.env = nil }

      it 'returns true' do
        expect(subject.enabled? :header_comment).to be true
      end
    end
  end

  describe '::strict_string' do
    context 'when strict is true' do
      before { subject.strict = true }

      it 'returns "set -euo pipefail"' do
        expect(subject.strict_string).to eq 'set -euo pipefail'
      end
    end

    context 'when strict is false' do
      before { subject.strict = false }

      it 'returns "set -e"' do
        expect(subject.strict_string).to eq 'set -e'
      end
    end

    context 'when strict is string' do
      before { subject.strict = 'set -o pipefail' }

      it 'returns the string as is' do
        expect(subject.strict_string).to eq 'set -o pipefail'
      end
    end
  end
end
