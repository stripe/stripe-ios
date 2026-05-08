#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'json'
require 'net/http'
require 'optparse'
require 'pathname'
require 'tempfile'
require 'uri'

REPO_ROOT = `git rev-parse --show-toplevel`.strip
SCRIPT_DIR = File.dirname(__FILE__)

module SnapshotTool
  module_function

  # --- generate_diff_report ---

  def generate_diff_report(recorded_dir:, baseline_dir:, output_dir:, manifest_path: nil, diff_threshold: 0.1)
    require_imagemagick!

    FileUtils.mkdir_p([
      "#{output_dir}/images/baseline",
      "#{output_dir}/images/new",
      "#{output_dir}/images/diff",
    ])

    manifest_path ||= Dir::Tmpname.create('snapshot-manifest') {}
    manifest_entries = []

    recorded_images = Dir.glob("#{recorded_dir}/**/*.png")
    baseline_images = Dir.glob("#{baseline_dir}/**/*.png")

    recorded_rel_paths = recorded_images.map { |f| relative_path(f, recorded_dir) }
    baseline_rel_paths = baseline_images.map { |f| relative_path(f, baseline_dir) }

    recorded_rel_paths.each do |rel_path|
      baseline_file = File.join(baseline_dir, rel_path)
      recorded_file = File.join(recorded_dir, rel_path)

      if !File.exist?(baseline_file)
        manifest_entries << "added|#{rel_path}"
      elsif !FileUtils.compare_file(baseline_file, recorded_file)
        if significant_difference?(baseline_file, recorded_file, diff_threshold)
          manifest_entries << "modified|#{rel_path}"
        end
      end
    end

    (baseline_rel_paths - recorded_rel_paths).each do |rel_path|
      manifest_entries << "removed|#{rel_path}"
    end

    if manifest_entries.empty?
      puts 'No snapshot differences found.'
      return 0
    end

    File.write(manifest_path, manifest_entries.join("\n") + "\n")

    changed = manifest_entries.count { |e| e.start_with?('modified|') }
    added = manifest_entries.count { |e| e.start_with?('added|') }
    removed = manifest_entries.count { |e| e.start_with?('removed|') }
    total = changed + added + removed

    puts "Found #{total} changes: #{changed} modified, #{added} added, #{removed} removed"

    manifest_entries.each do |entry|
      type, rel_path = entry.split('|', 2)
      case type
      when 'modified'
        copy_image(File.join(baseline_dir, rel_path), File.join(output_dir, 'images/baseline', rel_path))
        copy_image(File.join(recorded_dir, rel_path), File.join(output_dir, 'images/new', rel_path))
        generate_diff_image(
          File.join(baseline_dir, rel_path),
          File.join(recorded_dir, rel_path),
          File.join(output_dir, 'images/diff', rel_path)
        )
      when 'added'
        copy_image(File.join(recorded_dir, rel_path), File.join(output_dir, 'images/new', rel_path))
      when 'removed'
        copy_image(File.join(baseline_dir, rel_path), File.join(output_dir, 'images/baseline', rel_path))
      end
    end

    generate_html_report(output_dir, manifest_entries)
    puts "Report generated: #{output_dir}/index.html"
    1
  end

  def significant_difference?(baseline, recorded, threshold)
    num_diff = `compare -metric AE -fuzz 5% #{shell_escape(baseline)} #{shell_escape(recorded)} /dev/null 2>&1`.strip.to_i
    total_pixels = `identify -format '%[fx:w*h]' #{shell_escape(baseline)} 2>/dev/null`.strip.to_i
    return true if total_pixels == 0

    (num_diff.to_f / total_pixels * 100) > threshold
  end

  def generate_diff_image(baseline, recorded, output)
    FileUtils.mkdir_p(File.dirname(output))
    system('compare', baseline, recorded, '-compose', 'src', '-highlight-color', '#FF000080', output,
           [:out, :err] => '/dev/null')
  end

  def require_imagemagick!
    unless system('command', '-v', 'compare', [:out, :err] => '/dev/null')
      abort 'Error: ImageMagick is required but not installed. Run: brew install imagemagick'
    end
  end

  def copy_image(src, dst)
    FileUtils.mkdir_p(File.dirname(dst))
    FileUtils.cp(src, dst)
  end

  def relative_path(file, base)
    Pathname.new(file).relative_path_from(Pathname.new(base)).to_s
  end

  def shell_escape(str)
    "'#{str.gsub("'", "'\\\\''")}'"
  end

  def generate_html_report(output_dir, manifest_entries)
    html_template = File.read(File.join(SCRIPT_DIR, '..', 'html-template', 'report.html'))
    manifest_json = manifest_entries.map do |entry|
      type, path = entry.split('|', 2)
      { type: type, path: path }
    end.to_json

    html = html_template.gsub('/* MANIFEST_DATA */', "const MANIFEST = #{manifest_json};")
    File.write("#{output_dir}/index.html", html)
  rescue Errno::ENOENT
    generate_html_report_inline(output_dir, manifest_entries)
  end

  def generate_html_report_inline(output_dir, manifest_entries)
    manifest_json = manifest_entries.map do |entry|
      type, path = entry.split('|', 2)
      { type: type, path: path }
    end

    manifest_js = "const MANIFEST = #{manifest_json.to_json};"
    html = HTML_TEMPLATE.sub('/* MANIFEST_DATA */', manifest_js)
    File.write("#{output_dir}/index.html", html)
  end

  # --- init_baselines ---

  def init_baselines
    reference_dir = File.join(REPO_ROOT, 'Tests/ReferenceImages_64')
    unless Dir.exist?(reference_dir)
      abort "Error: #{reference_dir} does not exist"
    end

    image_count = Dir.glob("#{reference_dir}/**/*.png").size
    puts "Creating orphan branch 'snapshot-baselines' from existing reference images..."
    puts "Source: #{reference_dir} (#{image_count} images)"

    temp_dir = Dir.mktmpdir
    begin
      system('git', 'worktree', 'add', '--detach', temp_dir, exception: true)
      Dir.chdir(temp_dir) do
        system('git', 'checkout', '--orphan', 'snapshot-baselines', exception: true)
        system('git', 'rm', '-rf', '.', [:out, :err] => '/dev/null')
        FileUtils.cp_r(Dir.glob("#{reference_dir}/*"), '.')
        system('git', 'add', '-A', exception: true)
        system('git', 'commit', '-m', 'Initial snapshot baselines from Tests/ReferenceImages_64', exception: true)
      end
    ensure
      Dir.chdir(REPO_ROOT)
      system('git', 'worktree', 'remove', temp_dir, [:err] => '/dev/null')
      FileUtils.rm_rf(temp_dir)
    end

    puts
    puts "Orphan branch 'snapshot-baselines' created locally."
    puts 'To push: git push origin snapshot-baselines'
    puts
    puts 'After pushing, you can remove the reference images from the main branch'
    puts "since they'll be managed by CI going forward."
  end

  # --- local_diff ---

  def local_diff(test_target: nil)
    puts '==> Fetching current baselines...'
    unless system('git', 'fetch', 'origin', 'snapshot-baselines', '--depth=1', [:out, :err] => '/dev/null')
      abort "Error: 'snapshot-baselines' branch not found. Run `snapshot_tool.rb init_baselines` first."
    end

    baseline_dir = Dir.mktmpdir
    begin
      system('git', 'worktree', 'add', baseline_dir, 'origin/snapshot-baselines', '--detach',
             [:out, :err] => '/dev/null', exception: true)

      puts '==> Running snapshot tests in record mode...'
      recorded_dir = File.join(REPO_ROOT, 'Tests/ReferenceImages_64')

      build_cmd = [
        'xcodebuild', 'test',
        '-workspace', 'Stripe.xcworkspace',
        '-scheme', 'StripeiOS',
        "-destination", "platform=iOS Simulator,name=iPhone 12 mini",
      ]
      build_cmd += ['-only-testing', test_target] if test_target

      env = { 'STP_RECORD_SNAPSHOTS' => '1' }
      system(env, *build_cmd, [:out, :err] => '/dev/null')

      puts '==> Generating diff report...'
      report_dir = File.join(REPO_ROOT, 'snapshot-report')
      FileUtils.rm_rf(report_dir)

      generate_diff_report(recorded_dir: recorded_dir, baseline_dir: baseline_dir, output_dir: report_dir)

      if File.exist?("#{report_dir}/index.html")
        puts '==> Opening report...'
        system('open', "#{report_dir}/index.html")
      else
        puts '==> No changes detected.'
      end
    ensure
      system('git', 'worktree', 'remove', baseline_dir, [:err] => '/dev/null')
      FileUtils.rm_rf(baseline_dir)
    end
  end

  # --- post_pr_comment ---

  def post_pr_comment(manifest_path:, recorded_dir:, report_url:, pr_number:)
    github_repo = ENV.fetch('GITHUB_REPOSITORY') { abort 'GITHUB_REPOSITORY not set' }
    github_token = ENV.fetch('GITHUB_TOKEN') { abort 'GITHUB_TOKEN not set' }
    report_html_url = ENV.fetch('SNAPSHOT_REPORT_URL', report_url)

    unless File.exist?(manifest_path)
      abort "Manifest file not found: #{manifest_path}"
    end

    entries = File.readlines(manifest_path, chomp: true)
    changed = entries.count { |e| e.start_with?('modified|') }
    added = entries.count { |e| e.start_with?('added|') }
    removed = entries.count { |e| e.start_with?('removed|') }
    total = changed + added + removed
    max_inline = 8

    body = build_pr_comment_body(
      entries: entries, changed: changed, added: added, removed: removed,
      total: total, max_inline: max_inline, report_url: report_url, report_html_url: report_html_url
    )

    delete_previous_snapshot_comments(github_repo, github_token, pr_number)
    post_github_comment(github_repo, github_token, pr_number, body)
    puts "PR comment posted"
  end

  def build_pr_comment_body(entries:, changed:, added:, removed:, total:, max_inline:, report_url:, report_html_url:)
    lines = []
    lines << '## 📸 Snapshot Changes Detected'
    lines << ''
    lines << '| Modified | Added | Removed | Total |'
    lines << '|:--------:|:-----:|:-------:|:-----:|'
    lines << "| #{changed} | #{added} | #{removed} | #{total} |"
    lines << ''

    shown = 0
    if changed > 0
      lines << '### Modified'
      lines << ''
      entries.select { |e| e.start_with?('modified|') }.first(max_inline).each do |entry|
        rel_path = entry.split('|', 2).last
        filename = File.basename(rel_path)
        lines << "#### `#{filename}`"
        lines << '| Baseline | New | Diff |'
        lines << '|:---:|:---:|:---:|'
        lines << "| ![baseline](#{report_url}/images/baseline/#{rel_path}) | ![new](#{report_url}/images/new/#{rel_path}) | ![diff](#{report_url}/images/diff/#{rel_path}) |"
        lines << ''
        shown += 1
      end
    end

    if added > 0
      lines << '### Added'
      lines << ''
      entries.select { |e| e.start_with?('added|') }.first(max_inline - shown).each do |entry|
        rel_path = entry.split('|', 2).last
        filename = File.basename(rel_path)
        lines << "#### `#{filename}`"
        lines << "![new](#{report_url}/images/new/#{rel_path})"
        lines << ''
        shown += 1
      end
    end

    if removed > 0
      lines << '### Removed'
      lines << ''
      entries.select { |e| e.start_with?('removed|') }.first(max_inline - shown).each do |entry|
        rel_path = entry.split('|', 2).last
        filename = File.basename(rel_path)
        lines << "- `#{filename}`"
        shown += 1
      end
      lines << ''
    end

    if total > max_inline
      remaining = total - max_inline
      lines << "_...and #{remaining} more_"
      lines << ''
    end

    lines << '---'
    lines << ''
    lines << "**[👀 View Full Diff Report](#{report_html_url})**"
    lines << ''
    lines << 'To approve, add the `snapshot changes approved` label to this PR.'

    lines.join("\n")
  end

  def delete_previous_snapshot_comments(repo, token, pr_number)
    uri = URI("https://api.github.com/repos/#{repo}/issues/#{pr_number}/comments?per_page=100")
    response = github_request(uri, token)
    return unless response.is_a?(Net::HTTPSuccess)

    comments = JSON.parse(response.body)
    comments.each do |comment|
      next unless comment['body']&.include?('Snapshot Changes Detected')

      delete_uri = URI("https://api.github.com/repos/#{repo}/issues/comments/#{comment['id']}")
      req = Net::HTTP::Delete.new(delete_uri)
      req['Authorization'] = "token #{token}"
      req['Accept'] = 'application/vnd.github.v3+json'
      Net::HTTP.start(delete_uri.host, delete_uri.port, use_ssl: true) { |http| http.request(req) }
    end
  end

  def post_github_comment(repo, token, pr_number, body)
    uri = URI("https://api.github.com/repos/#{repo}/issues/#{pr_number}/comments")
    req = Net::HTTP::Post.new(uri)
    req['Authorization'] = "token #{token}"
    req['Accept'] = 'application/vnd.github.v3+json'
    req['Content-Type'] = 'application/json'
    req.body = JSON.generate({ body: body })

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    abort "Failed to post comment: #{response.code} #{response.body}" unless response.is_a?(Net::HTTPSuccess)
  end

  def github_request(uri, token)
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "token #{token}"
    req['Accept'] = 'application/vnd.github.v3+json'
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
  end

  # --- HTML template (fallback if file not found) ---

  HTML_TEMPLATE = <<~'HTML'
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Snapshot Diff Report</title>
    <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; background: #0d1117; color: #c9d1d9; padding: 24px; }
    h1 { font-size: 24px; margin-bottom: 16px; }
    .summary { display: flex; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }
    .stat { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 10px 16px; }
    .stat .n { font-size: 24px; font-weight: bold; }
    .stat .l { font-size: 11px; color: #8b949e; text-transform: uppercase; }
    .stat.m .n { color: #f0883e; }
    .stat.a .n { color: #3fb950; }
    .stat.r .n { color: #f85149; }
    .filters { display: flex; gap: 8px; margin-bottom: 20px; flex-wrap: wrap; }
    .filters button { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; padding: 5px 14px; border-radius: 16px; cursor: pointer; font-size: 13px; }
    .filters button.on { background: #388bfd; border-color: #388bfd; color: #fff; }
    .item { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 16px; margin-bottom: 12px; }
    .item .name { font-size: 13px; font-weight: 600; margin-bottom: 10px; word-break: break-all; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; margin-right: 6px; }
    .badge.modified { background: #f0883e20; color: #f0883e; }
    .badge.added { background: #3fb95020; color: #3fb950; }
    .badge.removed { background: #f8514920; color: #f85149; }
    .modes { display: flex; gap: 6px; margin-bottom: 10px; }
    .modes button { background: #21262d; border: 1px solid #30363d; color: #c9d1d9; padding: 3px 10px; border-radius: 4px; cursor: pointer; font-size: 12px; }
    .modes button.on { background: #388bfd; border-color: #388bfd; color: #fff; }
    .view { display: flex; gap: 8px; align-items: flex-start; flex-wrap: wrap; }
    .view .col { text-align: center; }
    .view .col img { max-width: 300px; height: auto; border: 1px solid #30363d; border-radius: 4px; background: repeating-conic-gradient(#1c1c1c 0% 25%, #2a2a2a 0% 50%) 50% / 16px 16px; }
    .view .col .lbl { font-size: 10px; color: #8b949e; text-transform: uppercase; margin-bottom: 4px; }
    .overlay-wrap { position: relative; display: inline-block; }
    .overlay-wrap img { max-width: 300px; }
    .overlay-wrap img.ov { position: absolute; top: 0; left: 0; }
    .slider { margin-top: 6px; width: 300px; }
    .hidden { display: none; }
    </style>
    </head>
    <body>
    <h1>Snapshot Diff Report</h1>
    <div id="app"></div>
    <script>
    /* MANIFEST_DATA */
    const changed = MANIFEST.filter(m => m.type === 'modified').length;
    const added = MANIFEST.filter(m => m.type === 'added').length;
    const removed = MANIFEST.filter(m => m.type === 'removed').length;
    const total = MANIFEST.length;

    function basename(p) { return p.split('/').pop(); }

    function renderItem(m) {
      const name = basename(m.path);
      if (m.type === 'modified') {
        return `<div class="item" data-t="modified">
          <div class="name"><span class="badge modified">Modified</span>${name}</div>
          <div class="modes">
            <button class="on" onclick="mode(this,'sbs')">Side by Side</button>
            <button onclick="mode(this,'overlay')">Overlay</button>
            <button onclick="mode(this,'diff')">Diff Only</button>
          </div>
          <div class="view">
            <div class="col sbs-v"><div class="lbl">Baseline</div><img src="images/baseline/${m.path}" /></div>
            <div class="col sbs-v"><div class="lbl">New</div><img src="images/new/${m.path}" /></div>
            <div class="col sbs-v diff-v"><div class="lbl">Diff</div><img src="images/diff/${m.path}" /></div>
            <div class="col overlay-v hidden">
              <div class="overlay-wrap">
                <img src="images/baseline/${m.path}" />
                <img class="ov" src="images/new/${m.path}" style="opacity:0.5" />
              </div>
              <input type="range" class="slider" min="0" max="100" value="50"
                oninput="this.parentElement.querySelector('.ov').style.opacity=this.value/100" />
            </div>
          </div>
        </div>`;
      } else if (m.type === 'added') {
        return `<div class="item" data-t="added">
          <div class="name"><span class="badge added">Added</span>${name}</div>
          <div class="view"><div class="col"><img src="images/new/${m.path}" /></div></div>
        </div>`;
      } else {
        return `<div class="item" data-t="removed">
          <div class="name"><span class="badge removed">Removed</span>${name}</div>
          <div class="view"><div class="col"><img src="images/baseline/${m.path}" style="opacity:0.5" /></div></div>
        </div>`;
      }
    }

    document.getElementById('app').innerHTML = `
      <div class="summary">
        <div class="stat m"><div class="n">${changed}</div><div class="l">Modified</div></div>
        <div class="stat a"><div class="n">${added}</div><div class="l">Added</div></div>
        <div class="stat r"><div class="n">${removed}</div><div class="l">Removed</div></div>
      </div>
      <div class="filters">
        <button class="on" onclick="filt(this,'all')">All (${total})</button>
        <button onclick="filt(this,'modified')">Modified (${changed})</button>
        <button onclick="filt(this,'added')">Added (${added})</button>
        <button onclick="filt(this,'removed')">Removed (${removed})</button>
      </div>
      ${MANIFEST.map(renderItem).join('\n')}
    `;

    function filt(btn, type) {
      btn.parentElement.querySelectorAll('button').forEach(b => b.classList.remove('on'));
      btn.classList.add('on');
      document.querySelectorAll('.item').forEach(el => {
        el.style.display = (type === 'all' || el.dataset.t === type) ? '' : 'none';
      });
    }

    function mode(btn, m) {
      btn.parentElement.querySelectorAll('button').forEach(b => b.classList.remove('on'));
      btn.classList.add('on');
      var view = btn.closest('.item').querySelector('.view');
      view.querySelectorAll('.sbs-v').forEach(el => el.classList.toggle('hidden', m !== 'sbs'));
      view.querySelectorAll('.diff-v').forEach(el => el.classList.toggle('hidden', m === 'overlay'));
      view.querySelectorAll('.overlay-v').forEach(el => el.classList.toggle('hidden', m !== 'overlay'));
      if (m === 'diff') {
        view.querySelectorAll('.sbs-v').forEach(el => el.classList.add('hidden'));
        view.querySelectorAll('.diff-v').forEach(el => el.classList.remove('hidden'));
      }
    }
    </script>
    </body>
    </html>
  HTML
end

# --- CLI ---

def usage
  puts <<~USAGE
    Usage: snapshot_tool.rb <command> [options]

    Commands:
      generate_diff    Compare recorded snapshots against baselines and generate an HTML report
      init_baselines   Create the snapshot-baselines orphan branch from existing reference images
      local_diff       Run snapshot tests locally and open a diff report
      post_pr_comment  Post a snapshot diff summary as a PR comment

    Run `snapshot_tool.rb <command> --help` for command-specific options.
  USAGE
end

command = ARGV.shift

case command
when 'generate_diff'
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: snapshot_tool.rb generate_diff <recorded_dir> <baseline_dir> <output_dir> [options]'
    opts.on('--manifest PATH', 'Path to write the manifest file') { |v| options[:manifest_path] = v }
    opts.on('--threshold N', Float, 'Diff threshold percentage (default: 0.1)') { |v| options[:diff_threshold] = v }
  end.parse!

  if ARGV.size < 3
    abort 'Usage: snapshot_tool.rb generate_diff <recorded_dir> <baseline_dir> <output_dir>'
  end

  options[:manifest_path] ||= ENV['SNAPSHOT_MANIFEST']
  options[:diff_threshold] ||= ENV.fetch('SNAPSHOT_DIFF_THRESHOLD', 0.1).to_f

  exit_code = SnapshotTool.generate_diff_report(
    recorded_dir: ARGV[0],
    baseline_dir: ARGV[1],
    output_dir: ARGV[2],
    manifest_path: options[:manifest_path],
    diff_threshold: options[:diff_threshold]
  )
  exit(exit_code)

when 'init_baselines'
  SnapshotTool.init_baselines

when 'local_diff'
  options = {}
  OptionParser.new do |opts|
    opts.banner = 'Usage: snapshot_tool.rb local_diff [test_target]'
  end.parse!

  SnapshotTool.local_diff(test_target: ARGV[0])

when 'post_pr_comment'
  if ARGV.size < 4
    abort 'Usage: snapshot_tool.rb post_pr_comment <manifest_file> <recorded_dir> <report_url> <pr_number>'
  end

  SnapshotTool.post_pr_comment(
    manifest_path: ARGV[0],
    recorded_dir: ARGV[1],
    report_url: ARGV[2],
    pr_number: ARGV[3]
  )

when '--help', '-h', nil
  usage

else
  abort "Unknown command: #{command}\nRun `snapshot_tool.rb --help` for usage."
end
