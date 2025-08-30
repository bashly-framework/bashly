module Bashly
  class Settings
    class << self
      include AssetHelper

      attr_writer(
        :commands_dir,
        :compact_short_flags,
        :conjoined_flag_args,
        :config_path,
        :enable_bash3_bouncer,
        :enable_deps_array,
        :enable_env_var_names_array,
        :enable_header_comment,
        :enable_inspect_args,
        :enable_sourcing,
        :enable_view_markers,
        :formatter,
        :function_names,
        :lib_dir,
        :partials_extension,
        :private_reveal_key,
        :show_examples_on_error,
        :source_dir,
        :strict,
        :tab_indent,
        :target_dir,
        :usage_colors,
        :var_aliases
      )

      def commands_dir
        @commands_dir ||= get :commands_dir
      end

      def compact_short_flags
        @compact_short_flags ||= get :compact_short_flags
      end

      def conjoined_flag_args
        @conjoined_flag_args ||= get :conjoined_flag_args
      end

      def config_path
        @config_path ||= get(:config_path) % { source_dir: source_dir }
      end

      def enabled?(feature)
        send(:"enable_#{feature}") == 'always' ||
          (send(:"enable_#{feature}") == 'production' && production?) ||
          (send(:"enable_#{feature}") == 'development' && !production?)
      end

      def enable_bash3_bouncer
        @enable_bash3_bouncer ||= get :enable_bash3_bouncer
      end

      def enable_deps_array
        @enable_deps_array ||= get :enable_deps_array
      end

      def enable_env_var_names_array
        @enable_env_var_names_array ||= get :enable_env_var_names_array
      end

      def enable_header_comment
        @enable_header_comment ||= get :enable_header_comment
      end

      def enable_inspect_args
        @enable_inspect_args ||= get :enable_inspect_args
      end

      def enable_sourcing
        @enable_sourcing ||= get :enable_sourcing
      end

      def enable_view_markers
        @enable_view_markers ||= get :enable_view_markers
      end

      def env
        @env ||= get(:env)&.to_sym
      end

      def env=(value)
        @env = value&.to_sym
      end

      def formatter
        @formatter ||= get :formatter
      end

      def full_lib_dir
        "#{source_dir}/#{lib_dir}"
      end

      def function_name(key)
        function_names[key.to_s] || key.to_s
      end

      def function_names
        @function_names ||= get :function_names
      end

      def lib_dir
        @lib_dir ||= get :lib_dir
      end

      def partials_extension
        @partials_extension ||= get :partials_extension
      end

      def private_reveal_key
        @private_reveal_key ||= get :private_reveal_key
      end

      def production?
        env == :production
      end

      def show_examples_on_error
        @show_examples_on_error ||= get :show_examples_on_error
      end

      def source_dir
        @source_dir ||= get :source_dir
      end

      def strict
        @strict ||= get :strict
      end

      def strict_string
        if strict.is_a? String
          strict
        elsif strict
          'set -euo pipefail'
        else
          'set -e'
        end
      end

      def tab_indent
        @tab_indent ||= get :tab_indent
      end

      def target_dir
        @target_dir ||= get :target_dir
      end

      def usage_colors
        @usage_colors ||= get :usage_colors
      end

      def var_aliases
        @var_aliases ||= get :var_aliases
      end

    private

      def get(key)
        case env_value key
        when nil                 then config[key.to_s]
        when '0', 'false', 'no'  then false
        when '1', 'true', 'yes'  then true
        else                     env_value key
        end
      end

      def env_value(key)
        ENV["BASHLY_#{key.upcase}"]
      end

      def config
        @config ||= default_settings.merge user_settings
      end

      def user_settings
        @user_settings ||= File.exist?(user_settings_path) ? Config.new(user_settings_path) : {}
      end

      def user_settings_path
        @user_settings_path ||= ENV['BASHLY_SETTINGS_PATH'] || [
          '.bashly.yml', 'bashly.yml',
          '.bashly-settings.yml', 'bashly-settings.yml',
          '.bashlyrc.yml', 'bashlyrc.yml',
          '.settings.yml'
        ].find { |f| File.exist?(f) } || 'settings.yml'
      end

      def default_settings
        @default_settings ||= Config.new default_settings_path
      end

      def default_settings_path
        asset 'libraries/settings/settings.yml'
      end
    end
  end
end
