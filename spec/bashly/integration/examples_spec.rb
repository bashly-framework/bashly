# This spec tests that the generated bash scripts are actually doing
# what they are supposed to do, and running without errors.
# It will run several tests on all the configuration files in the examples
# folder
#
# To only test examples containing a certain string in their path, run:
# EXAMPLE=yaml bundle exec run spec examples
describe 'generated bash scripts', :slow do
  # Make sure all examples are generated with strict mode
  before { ENV['BASHLY_STRICT'] = 'yes' }
  after { ENV['BASHLY_STRICT'] = nil }

  # Test public examples from the examples folder...
  examples = Dir['examples/*'].select { |f| File.directory?(f) }

  # ...as well as internal examples, not suitable for public view
  fixtures = Dir['spec/fixtures/workspaces/*'].select do |f|
    File.directory?(f) && File.exist?("#{f}/test.sh")
  end

  test_cases = fixtures + examples

  # Allow up to a certain string distance from the approval text in CI
  let(:leeway) { ENV['CI'] ? 40 : 0 }

  # For certain examples, allow some exceptions (replacements) since they
  # are too volatile (e.g. line number changes)
  let(:exceptions) do
    {
      'examples/stacktrace'       => [/download:\d+/, 'download:<line>'],
      'examples/render-mandoc'    => [/Version 0.1.0.*download\(1\)/, '<footer>'],
      'examples/dependencies-alt' => [%r[/home/(.+)/ruby], '/home/.../ruby']
    }
  end

  test_cases.each do |example|
    next if ENV['EXAMPLE'] && !example.include?(ENV['EXAMPLE'])

    describe example do
      let(:approval_name) do
        example.gsub('spec/fixtures/workspaces', 'fixtures')
      end

      it 'is executed properly' do
        output = 'not executed'
        Dir.chdir(example) do
          output = `bash test.sh 2>&1`
        end

        # Use .diff to give CI some leeway, since its shell differs sometimes
        # This was observed in at least these two cases:
        # - The "+ ..." shell messages driven by `set -x` have no space
        # - The order of our `inspect_args` sometimes differs
        # - The result of the `deps` array sometimes differs
        # In addition, for some examples we allow exceptions, so the below is
        # just a more granular version of:
        # expect(output).to match_approval(approval_name).diff(leeway).except(*except)
        match_output = match_approval(approval_name).diff(leeway)
        except = exceptions[example]
        match_output = match_output.except(*except) if except
        expect(output).to match_output
      end
    end
  end
end
