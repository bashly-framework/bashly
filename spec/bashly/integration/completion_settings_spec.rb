describe 'Completion settings', :slow do
  def generate_with_completions(value)
    Settings.completions = value
    reset_tmp_dir
    FileUtils.cp_r Dir['spec/fixtures/completions/core/*'], 'spec/tmp'
    Commands::Generate.new.execute %w[generate --quiet]
    File.read 'spec/tmp/cli'
  end

  after do
    Settings.completions = nil
  end

  it 'omits the runtime engine and adapters by default' do
    script = generate_with_completions nil

    expect(script).not_to include 'completion_run() {'
    expect(script).not_to include 'send_completions() {'
  end

  it 'generates only the runtime engine for minimal' do
    script = generate_with_completions 'minimal'

    expect(script).to include 'completion_run() {'
    expect(script).not_to include 'send_completions() {'
  end

  it 'generates only the Bash adapter when Bash is selected' do
    script = generate_with_completions 'bash'

    expect(script).to include 'send_completions_bash() {'
    expect(script).not_to include 'send_completions_fish() {'
    expect(script).not_to include 'send_completions_zsh() {'
    expect(script).to include 'local completion_shell="${1:-bash}"'
  end

  it 'generates only the Fish adapter when Fish is selected' do
    script = generate_with_completions 'fish'

    expect(script).not_to include 'send_completions_bash() {'
    expect(script).to include 'send_completions_fish() {'
    expect(script).not_to include 'send_completions_zsh() {'
    expect(script).to include 'local completion_shell="${1:-fish}"'
  end

  it 'generates only the Zsh adapter when Zsh is selected' do
    script = generate_with_completions 'zsh'

    expect(script).not_to include 'send_completions_bash() {'
    expect(script).not_to include 'send_completions_fish() {'
    expect(script).to include 'send_completions_zsh() {'
    expect(script).to include 'local completion_shell="${1:-zsh}"'
  end

  it 'generates every adapter for full' do
    script = generate_with_completions 'full'

    expect(script).to include 'send_completions_bash() {'
    expect(script).to include 'send_completions_fish() {'
    expect(script).to include 'send_completions_zsh() {'
  end
end
