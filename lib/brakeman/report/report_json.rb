class Brakeman::Report::JSON < Brakeman::Report::Base
  def generate_report
    errors = tracker.errors.map{|e| { :error => e[:error], :location => e[:backtrace][0] }}

    obsolete = tracker.unused_fingerprints

    warnings = convert_to_hashes all_warnings

    ignored = convert_to_hashes ignored_warnings

    scan_info = {
      :app_path => tracker.app_path,
      :rails_version => rails_version,
      :security_warnings => all_warnings.length,
      :start_time => tracker.start_time.to_s,
      :end_time => tracker.end_time.to_s,
      :duration => tracker.duration,
      :checks_performed => checks.checks_run.sort,
      :number_of_controllers => tracker.controllers.length,
      # ignore the "fake" model
      :number_of_models => tracker.models.length - 1,
      :number_of_templates => number_of_templates(@tracker),
      :ruby_version => RUBY_VERSION,
      :brakeman_version => Brakeman::Version
    }

    report_info = {
      :scan_info => scan_info,
      :warnings => warnings,
      :ignored_warnings => ignored,
      :errors => errors,
      :obsolete => obsolete
    }

    JSON.pretty_generate report_info
  end

  def convert_to_hashes warnings
    warnings.map do |w|
      hash = w.to_hash(absolute_paths: absolute_paths?)
      hash[:render_path] = convert_render_path hash[:render_path]

      hash
    end.sort_by { |w| "#{w[:fingerprint]}#{w[:line]}" }
  end

  def convert_render_path render_path
    return unless render_path and not @tracker.options[:absolute_paths]

    render_path.map do |r|
      r = r.dup

      if r[:file]
        r[:file] = relative_path(r[:file])
      end

      if r[:rendered] and r[:rendered][:file]
        r[:rendered] = r[:rendered].dup
        r[:rendered][:file] = relative_path(r[:rendered][:file])
      end

      r
    end
  end
end
