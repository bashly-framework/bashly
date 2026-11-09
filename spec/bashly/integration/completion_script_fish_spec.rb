describe 'Fish completion script', :slow do
  def complete_with_fish(*words)
    commandline = ['./cli', *words].map { |word| word.empty? ? '' : Shellwords.shellescape(word) }.join ' '

    stdout, stderr, status = Open3.capture3(
      'fish', '--no-config', '--private', '-c', <<~FISH
        cd ./spec/tmp
        eval (bash -c 'source ./cli; send_completions fish' | string collect)
        complete -C #{Shellwords.shellescape commandline}
      FISH
    )

    # Fish candidates may carry a tab-separated description
    candidates = stdout.lines(chomp: true).map { |line| line.split("\t").first }
    [candidates, stderr, status]
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

    it 'prints Fish completions' do
      stdout, stderr, status = Open3.capture3(
        'bash', '-c', "source #{cli}; send_completions fish"
      )

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout).to start_with "function _cli_completions\n"
      expect(stdout).to end_with %(complete --command cli --no-files --arguments "(_cli_completions)"\n)
    end

    it 'completes commands' do
      candidates, stderr, status = complete_with_fish 'd'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to eq %w[deploy]
    end

    it 'preserves an empty current word' do
      candidates, stderr, status = complete_with_fish 'server', ''

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to include 'start'
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

    it 'preserves literal candidates' do
      candidates, stderr, status = complete_with_fish 'static', ''

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to include 'two words', '$literal', ':options=files'
    end

    it 'adds files when requested' do
      candidates, stderr, status = complete_with_fish 'files', 'a'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to contain_exactly 'apple.txt', 'apricot/'
    end

    it 'adds only directories when requested' do
      candidates, stderr, status = complete_with_fish 'directories', 'a'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to eq %w[apricot/]
    end

    it 'adds a second candidate to apply no-space to a unique candidate' do
      candidates, stderr, status = complete_with_fish 'flag', '--target', 'pro'

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(candidates).to eq ['production', 'production ']
    end
  end
end
