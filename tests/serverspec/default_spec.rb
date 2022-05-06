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
# rubocop:disable Style/GlobalVars
puts $TLS
ports = $TLS ? [443, 8404] : [80, 8404]
# rubocop:enable Style/GlobalVars
cert_dir = case os[:family]
           when "freebsd"
             "/usr/local/etc/haproxy"
           else
             "/etc/haproxy"
           end
ca_pem_file = "#{cert_dir}/ca.pem"

config = "#{config_dir}/haproxy.cfg"
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
when "redhat", "fedora"
  describe file("/etc/sysconfig/haproxy") do
    it { should exist }
    it { should be_file }
    it { should be_mode 644 }
    it { should be_owned_by default_user }
    it { should be_grouped_into default_group }
    its(:content) { should match Regexp.escape("Managed by ansible") }
  end

  describe command "semanage port -l | grep -E '^http_port_t\s+' | sed -Ee 's/^http_port_t.*tcp\s+//'  -e 's/,\s+/ /g' -e 's/\\s+/\\n/g'" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    ports.each do |p|
      its(:stdout) { should match(/^#{p}$/) }
    end
  end

  describe command "semanage boolean --list" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should eq "" }
    its(:stdout) { should match(/^httpd_can_network_connect\s+\(on\s*,\s*on\)/) }
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

# rubocop:disable Style/GlobalVars
if $TLS
  describe file "#{cert_dir}/ca.pem" do
    it { should exist }
    it { should be_file }
    it { should be_mode 444 }
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end

  describe file "#{cert_dir}/pub.pem" do
    it { should exist }
    it { should be_file }
    it { should be_mode 444 }
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end

  describe file "#{cert_dir}/pub.pem" do
    it { should exist }
    it { should be_file }
    it { should be_mode 444 }
    its(:content) { should match(/BEGIN CERTIFICATE/) }
  end

  describe file "#{cert_dir}/pub.pem.key" do
    it { should exist }
    it { should be_owned_by user }
    it { should be_grouped_into group }
    it { should be_mode 400 }
    its(:content) { should match(/BEGIN (?:RSA )?PRIVATE KEY/) }
  end

  describe command "curl --cacert #{ca_pem_file.shellescape} -o /dev/null -s -v https://localhost" do
    its(:exit_status) { should eq 0 }
    its(:stderr) { should match(/SSL certificate verify ok/) }
  end
end
# rubocop:enable Style/GlobalVars
