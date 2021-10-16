require "spec_helper"
require "serverspec"

package = "haproxy"
service = "haproxy"
config_dir = case os[:family]
             when "freebsd"
               "/usr/local/etc"
             else
               "/etc/haproxy"
             end
user    = case os[:family]
          when "freebsd"
            "www"
          when "openbsd"
            "_haproxy"
          else
            "haproxy"
          end
group   = case os[:family]
          when "freebsd"
            "www"
          when "openbsd"
            "_haproxy"
          else
            "haproxy"
          end
ports   = [80, 8404]
config  = "#{config_dir}/haproxy.cfg"
default_user = "root"
default_group = case os[:family]
                when /bsd/
                  "wheel"
                else
                  "root"
                end
extra_packages = %w[zsh]

describe package(package) do
  it { should be_installed }
end

extra_packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

describe user(user) do
  it { should exist }
end

describe group(group) do
  it { should exist }
end

describe file(config) do
  it { should exist }
  it { should be_file }
  it { should be_mode 644 }
  its(:content) { should match Regexp.escape("Managed by ansible") }
end

case os[:family]
when "ubuntu"
  describe file("/etc/default/haproxy") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match Regexp.escape("Managed by ansible") }
  end
when "freebsd"
  describe file("/etc/rc.conf.d/haproxy") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match Regexp.escape("Managed by ansible") }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command "curl -s http://localhost:8404" do
  its(:exit_status) { should eq 0 }
  its(:stderr) { should eq "" }
  its(:stdout) { should match(/Statistics Report/) }
end
