describe 'Bash completion script', :slow do
  def complete_with_bash(*words, trace_options: false)
    completion_words = words.map { |word| Shellwords.shellescape word }.join ' '
    option_trace = if trace_options
      "compopt() { printf 'option %s\\n' \"$*\"; }"
    end

    Open3.capture3(
      'bash', '-c', <<~BASH
        cd ./spec/tmp
        source cli
        eval "$(send_completions)"
        #{option_trace}
        COMP_WORDS=(./cli #{completion_words})
        COMP_CWORD=#{words.length}
        _cli_completions
        printf 'candidate %s\n' "${COMPREPLY[@]}"
      BASH
    )
  end

  context 'when generating the script' do
    let(:cli) { File.expand_path 'spec/tmp/cli' }

    before(:context) do
      Settings.completions = 'full'
      reset_tmp_dir
      FileUtils.cp_r Dir['spec/fixtures/completions/core/*'], 'spec/tmp'
      Commands::Generate.new.execute %w[generate --quiet]
    end

    after(:context) do
      Settings.completions = nil
    end

    it 'prints Bash completions by default' do
      stdout, stderr, status = Open3.capture3(
        'bash', '-c', "source #{cli}; send_completions"
      )

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout).to include '_cli_completions() {'
      expect(stdout).to end_with "complete -F _cli_completions cli\n"
    end

    it 'accepts Bash explicitly' do
      default_output, = Open3.capture3('bash', '-c', "source #{cli}; send_completions")
      bash_output, stderr, status = Open3.capture3(
        'bash', '-c', "source #{cli}; send_completions bash"
      )

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(bash_output).to eq default_output
    end

    it 'rejects unsupported shells' do
      stdout, stderr, status = Open3.capture3(
        'bash', '-c', "source #{cli}; send_completions ksh"
      )

      expect(status).not_to be_success
      expect(stdout).to be_empty
      expect(stderr).to eq "unsupported shell: ksh\n"
    end
  end

  context 'with configured options' do
    before(:context) do
      Settings.completions = 'full'
      reset_tmp_dir
      FileUtils.cp_r Dir['spec/fixtures/completions/configured/*'], 'spec/tmp'
      Commands::Generate.new.execute %w[generate --quiet]
      FileUtils.touch 'spec/tmp/apple.txt'
      FileUtils.mkdir 'spec/tmp/apricot'
    end

    after(:context) do
      Settings.completions = nil
    end

    it 'adds files when requested' do
      stdout, stderr, status = complete_with_bash 'files', 'a'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout.lines(chomp: true)).to contain_exactly(
        'candidate apple.txt', 'candidate apricot'
      )
    end

    it 'adds only directories when requested' do
      stdout, stderr, status = complete_with_bash 'directories', 'a'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout.lines(chomp: true)).to eq ['candidate apricot']
    end

    it 'applies no-space alongside candidate-source options' do
      stdout, stderr, status = complete_with_bash 'combined', 'a', trace_options: true

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout.lines(chomp: true)).to contain_exactly(
        'option -o nospace', 'candidate apple.txt', 'candidate apricot'
      )
    end
  end
end
