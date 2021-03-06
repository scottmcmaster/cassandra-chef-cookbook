require 'spec_helper'

describe 'cassandra-dse' do
  context 'all config options enalbed on rhel platform_family' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        # turn on all only_if attributes
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['metrics_reporter']['enabled'] = true
        node.set['cassandra']['rackdc'] = { 'dc' => 'testdc', 'rack' => 'testrack' }
        node.set['cassandra']['snitch_conf'] = { 'dc' => 'testdc', 'rac' => 'testrack' }
        node.set['cassandra']['setup_jamm'] = true
        node.set['cassandra']['setup_priam'] = true
        node.set['cassandra']['setup_jna'] = true
        node.set['cassandra']['notify_restart'] = true

        # provide a testable hash to verify template generation
        node.set['cassandra']['metrics_reporter']['config'] = {'test1' => 'value1', 'test2' => ['value2', 'value3']}
      end.converge(described_recipe)
    end

    it 'installs the jna.jar file' do
      expect(chef_run).to create_remote_file('/usr/share/java/jna.jar').with(
        source: 'https://github.com/twall/jna/raw/4.0/dist/jna.jar',
        checksum: 'dac270b6441ce24d93a96ddb6e8f93d8df099192738799a6f6fcfc2b2416ca19'
      )
    end

    it 'downloads the /usr/share/java/jamm-0.3.1.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/jamm-0.3.1.jar').with(
        source: 'http://repo1.maven.org/maven2/com/github/jbellis/jamm/0.3.1/jamm-0.3.1.jar',
        checksum: 'b599dc7a58b305d697bbb3d897c91f342bbddefeaaf10a3fa156c93efca397ef'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/jamm-0.3.1.jar').with(
        to: '/usr/share/java/jamm-0.3.1.jar'
      )
    end

    it 'downloads the priam-cass-extensions-2.2.0.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/priam-cass-extensions-2.2.0.jar').with(
        source: 'http://search.maven.org/remotecontent?filepath=com/netflix/priam/priam-cass-extensions/2.2.0/priam-cass-extensions-2.2.0.jar',
        checksum: '9fde9a40dc5c538adee54f40fa9027cf3ebb7fd42e3592b3e6fdfe3f7aff81e1'
      )
    end

    it 'sets up a link for the priam-cass extensions jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/priam-cass-extensions-2.2.0.jar').with(
        to: '/usr/share/java/priam-cass-extensions-2.2.0.jar'
      )
    end

    it 'creates the metrics reporter jar file' do
      expect(chef_run).to create_remote_file('/usr/share/java/metrics-graphite-2.2.0.jar').with(
        source: 'http://search.maven.org/remotecontent?filepath=com/yammer/metrics/metrics-graphite/2.2.0/metrics-graphite-2.2.0.jar',
        checksum: '6b4042aabf532229f8678b8dcd34e2215d94a683270898c162175b1b13d87de4'
      )
    end

    it 'links /usr/share/cassandra/lib/metrics-graphite.jar to /usr/share/java/metrics-graphite-2.2.0.jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/metrics-graphite.jar').with(
        to: '/usr/share/java/metrics-graphite-2.2.0.jar'
      )
    end

    
    %w(cassandra.yaml cassandra-env.sh cassandra-topology.properties 
       cassandra-metrics.yaml cassandra-rackdc.properties logback.xml logback-tools.xml).each do |conffile|
      let(:template) { chef_run.template("/etc/cassandra/conf/#{conffile}") }
      it "creates the /etc/cassandra/conf/#{conffile} configuration file" do
        expect(chef_run).to create_template("/etc/cassandra/conf/#{conffile}").with(
          source: "#{conffile}.erb",
          owner: 'cassandra',
          group: 'cassandra',
          mode: '0644'
        )
      end

      it "renders the /etc/cassandra/conf/#{conffile} with content from ./spec/rendered_templates/#{conffile}" do
        content = File.read("./spec/rendered_templates/#{conffile}")
        expect(chef_run).to render_file("/etc/cassandra/conf/#{conffile}")
          .with_content(content)
      end

      it "restarts the cassandra service if there is a chage to #{conffile}" do
        expect(template).to notify('service[cassandra]').to(:restart)
      end
    end
  end

  context 'all config options enalbed on debian platform_family' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04') do |node|
        # turn on all only_if attributes
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['metrics_reporter']['enabled'] = true
        node.set['cassandra']['rackdc'] = { 'dc' => 'testdc', 'rack' => 'testrack' }
        node.set['cassandra']['snitch_conf'] = { 'dc' => 'testdc', 'rac' => 'testrack' }
        node.set['cassandra']['setup_priam'] = true
        node.set['cassandra']['setup_jna'] = true
        node.set['cassandra']['notify_restart'] = true

        # provide a testable hash to verify template generation
        node.set['cassandra']['metrics_reporter']['config'] = {'test1' => 'value1', 'test2' => ['value2', 'value3']}
      end.converge(described_recipe)
    end

    %w(cassandra.yaml cassandra-env.sh cassandra-topology.properties 
       cassandra-metrics.yaml cassandra-rackdc.properties logback.xml logback-tools.xml).each do |conffile|
      let(:template) { chef_run.template("/etc/cassandra/#{conffile}") }
      it "creates the /etc/cassandra/#{conffile} configuration file" do
        expect(chef_run).to create_template("/etc/cassandra/#{conffile}").with(
          source: "#{conffile}.erb",
          owner: 'cassandra',
          group: 'cassandra',
          mode: '0644'
        )
      end

      it "renders the /etc/cassandra/#{conffile} with content from ./spec/rendered_templates/#{conffile}" do
        content = File.read("./spec/rendered_templates/#{conffile}")
        expect(chef_run).to render_file("/etc/cassandra/#{conffile}")
          .with_content(content)
      end

      it "restarts the cassandra service if there is a chage to #{conffile}" do
        expect(template).to notify('service[cassandra]').to(:restart)
      end
    end
  end

  context 'default' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['metrics_reporter']['enabled'] = false
      end.converge(described_recipe)
    end

    it 'does not create the cassandra-metrics.yaml file in /etc/cassandra/' do
      expect(chef_run).to_not create_template('/etc/cassandra/conf/cassandra-metrics.yaml')
    end

    it 'does not create the cassandra-rackdc.properties file in /etc/cassandra/conf' do
      expect(chef_run).to_not create_template('/etc/cassandra/conf/cassandra-rackdc.properties')
    end

    it 'creates the log file /var/log/cassandra/system.log and sets the permissions' do
      expect(chef_run).to create_file('/var/log/cassandra/system.log').with(
        owner: 'cassandra',
        group: 'cassandra',
        mode: '0644'
      )
    end

    it 'creates the log file /var/log/cassandra/boot.log and sets the permissions' do
      expect(chef_run).to create_file('/var/log/cassandra/boot.log').with(
        owner: 'cassandra',
        group: 'cassandra',
        mode: '0644'
      )
    end
  end

  context 'skip jna' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['metrics_reporter']['enabled'] = false
        node.set['cassandra']['skip_jna'] = true
      end.converge(described_recipe)
    end

    it 'deletes the jna.jar file' do
      expect(chef_run).to delete_file('/usr/share/cassandra/lib/jna.jar')
    end
  end

  context 'jamm and priam with cassandra version 1 or 2.0' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['version'] = '2.0.11'
        node.set['cassandra']['package_name'] = 'dsc20'
        node.set['cassandra']['setup_jamm'] = true
        node.set['cassandra']['setup_priam'] = true
      end.converge(described_recipe)
    end

    it 'downloads the /usr/share/java/jamm-0.2.5.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/jamm-0.2.5.jar').with(
        source: 'http://repo1.maven.org/maven2/com/github/jbellis/jamm/0.2.5/jamm-0.2.5.jar',
        checksum: 'b599dc7a58b305d697bbb3d897c91f342bbddefeaaf10a3fa156c93efca397ef'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/jamm-0.2.5.jar').with(
        to: '/usr/share/java/jamm-0.2.5.jar'
      )
    end

    it 'downloads the /usr/share/java/priam-cass-extensions-2.0.11.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/priam-cass-extensions-2.0.11.jar').with(
        source: 'http://search.maven.org/remotecontent?filepath=com/netflix/priam/priam-cass-extensions/2.0.11/priam-cass-extensions-2.0.11.jar',
        checksum: '9fde9a40dc5c538adee54f40fa9027cf3ebb7fd42e3592b3e6fdfe3f7aff81e1'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/priam-cass-extensions-2.0.11.jar').with(
        to: '/usr/share/java/priam-cass-extensions-2.0.11.jar'
      )
    end
  end

  context 'jamm and priam with cassandra version 2.1' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['version'] = '2.1.7'
        node.set['cassandra']['package_name'] = 'dsc21'
        node.set['cassandra']['setup_jamm'] = true
        node.set['cassandra']['setup_priam'] = true
      end.converge(described_recipe)
    end

    it 'downloads the /usr/share/java/jamm-0.3.0.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/jamm-0.3.0.jar').with(
        source: 'http://repo1.maven.org/maven2/com/github/jbellis/jamm/0.3.0/jamm-0.3.0.jar',
        checksum: 'b599dc7a58b305d697bbb3d897c91f342bbddefeaaf10a3fa156c93efca397ef'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/jamm-0.3.0.jar').with(
        to: '/usr/share/java/jamm-0.3.0.jar'
      )
    end

    it 'downloads the /usr/share/java/priam-cass-extensions-2.1.7.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/priam-cass-extensions-2.1.7.jar').with(
        source: 'http://search.maven.org/remotecontent?filepath=com/netflix/priam/priam-cass-extensions/2.1.7/priam-cass-extensions-2.1.7.jar',
        checksum: '9fde9a40dc5c538adee54f40fa9027cf3ebb7fd42e3592b3e6fdfe3f7aff81e1'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/priam-cass-extensions-2.1.7.jar').with(
        to: '/usr/share/java/priam-cass-extensions-2.1.7.jar'
      )
    end
  end

  context 'priam with cassandra version 2.2.1' do
    cached(:chef_run) do
      ChefSpec::SoloRunner.new(platform: 'centos', version: '6.4') do |node|
        node.set['cassandra']['config']['cluster_name'] = 'chefspec'
        node.set['cassandra']['version'] = '2.2.1'
        node.set['cassandra']['package_name'] = 'dsc21'
        node.set['cassandra']['setup_priam'] = true
      end.converge(described_recipe)
    end

    it 'downloads the /usr/share/java/priam-cass-extensions-2.2.1.jar jar' do
      expect(chef_run).to create_remote_file('/usr/share/java/priam-cass-extensions-2.2.1.jar').with(
        source: 'http://search.maven.org/remotecontent?filepath=com/netflix/priam/priam-cass-extensions/2.2.1/priam-cass-extensions-2.2.1.jar',
        checksum: '9fde9a40dc5c538adee54f40fa9027cf3ebb7fd42e3592b3e6fdfe3f7aff81e1'
      )
    end

    it 'sets up a link for the jamm jar' do
      expect(chef_run).to create_link('/usr/share/cassandra/lib/priam-cass-extensions-2.2.1.jar').with(
        to: '/usr/share/java/priam-cass-extensions-2.2.1.jar'
      )
    end
  end
end
