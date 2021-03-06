require 'spec_helper'
require 'puppet/provider/importtemplatexml'
require 'puppet/provider/exporttemplatexml'
require 'yaml'
require 'rspec/expectations'
describe Puppet::Provider::Importtemplatexml do
	
	before(:each) do
        @test_config_dir = URI(File.join(Dir.pwd, "spec", "fixtures"))
		@idrac_attrib = {
          :ip => '172.17.10.106',
          :username => 'root',
          :password => 'calvin',
          :configxmlfilename => 'FOOTAG.xml',
          :nfsipaddress => '172.28.10.191',
          :enable_npar => 'true',
          :target_boot_device => 'HD',
          :servicetag => 'FOOTAG',
          :nfssharepath => @test_config_dir
        }
		@fixture=Puppet::Provider::Importtemplatexml.new(@idrac_attrib['ip'],@idrac_attrib['username'],@idrac_attrib['password'],@idrac_attrib)
		@fixture.stub(:initialize).and_return("")
		@commandoutput= <<END
		<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:n1="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LCService" xmlns:wsman="http://schemas.dmtf.org/wbem/wsman/1/wsman.xsd">
  <s:Header>
    <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
    <wsa:Action>http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LCService/ImportSystemConfigurationResponse</wsa:Action>
    <wsa:RelatesTo>uuid:c8687f4e-efcf-1fcf-8002-9f3392565000</wsa:RelatesTo>
    <wsa:MessageID>uuid:51b947e2-efe0-1fe0-81e0-502ed9ddf95c</wsa:MessageID>
  </s:Header>
  <s:Body>
    <n1:ImportSystemConfiguration_OUTPUT>
      <n1:Job>
        <wsa:EndpointReference>
          <wsa:Address>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:Address>
          <wsa:ReferenceParameters>
            <wsman:ResourceURI>http://schemas.dell.com/wbem/wscim/1/cim-schema/2/DCIM_LifecycleJob</wsman:ResourceURI>
            <wsman:SelectorSet>
              <wsman:Selector Name="InstanceID">JID_896466295795</wsman:Selector>
              <wsman:Selector Name="__cimnamespace">root/dcim</wsman:Selector>
            </wsman:SelectorSet>
          </wsa:ReferenceParameters>
        </wsa:EndpointReference>
      </n1:Job>
      <n1:ReturnValue>4096</n1:ReturnValue>
    </n1:ImportSystemConfiguration_OUTPUT>
  </s:Body>
</s:Envelope>
END
	@failedoutput= <<END
	<?xml version="1.0" encoding="UTF-8"?>
<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope" xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" xmlns:n1="http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LCService">
  <s:Header>
    <wsa:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</wsa:To>
    <wsa:Action>http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/root/dcim/DCIM_LCService/ImportSystemConfigurationResponse</wsa:Action>
    <wsa:RelatesTo>uuid:c3acfb57-efcf-1fcf-8002-9f3392565000</wsa:RelatesTo>
    <wsa:MessageID>uuid:4d0d8270-efe0-1fe0-81df-502ed9ddf95c</wsa:MessageID>
  </s:Header>
  <s:Body>
    <n1:ImportSystemConfiguration_OUTPUT>
      <n1:Message>Import file not found.</n1:Message>
      <n1:MessageID>LC070</n1:MessageID>
      <n1:ReturnValue>2</n1:ReturnValue>
    </n1:ImportSystemConfiguration_OUTPUT>
  </s:Body>
</s:Envelope>
END
end
	context " instance validation " do
		it "should have instance object" do
			@fixture.should be_kind_of(Puppet::Provider::Importtemplatexml)
			
		end
		it "should get the instance variable value"  do
			@fixture.instance_variable_get(:@ip).should eql(@idrac_attrib['ip'])
			@fixture.instance_variable_get(:@username).should eql(@idrac_attrib['username'])
			@fixture.instance_variable_get(:@password).should eql(@idrac_attrib['password'])
			@fixture.instance_variable_get(:@resource)['configxmlfilename'].should eql(@idrac_attrib['configxmlfilename'])
			@fixture.instance_variable_get(:@resource)['nfsipaddress'].should eql(@idrac_attrib['nfsipaddress'])
			@fixture.instance_variable_get(:@resource)['nfssharepath'].should eql(@idrac_attrib['nfssharepath'])
			@fixture.instance_variable_get(:@resource)['enable_npar'].should eql(@idrac_attrib['enable_npar'])
			@fixture.instance_variable_get(:@resource)['servicetag'].should eql(@idrac_attrib['servicetag'])
			@fixture.instance_variable_get(:@resource)['target_boot_device'].should eql(@idrac_attrib['target_boot_device'])
		end
		it "should have method " do
			@fixture.class.instance_method(:importtemplatexml).should_not == nil
		end
	end
	context "when exporting template" do
		it "should get Job id for Export template xml"  do
			@fixture.should_receive(:executeimportcmd).once.and_return(@commandoutput)
			@fixture.stub(:munge_config_xml)
			jobid = @fixture.importtemplatexml
			jobid.should == "JID_896466295795"
		end
		it "should not get Job id if import template fail" do
			@fixture.should_receive(:executeimportcmd).once.and_return(@failedoutput)
			@fixture.stub(:munge_config_xml)
			expect{ @fixture.importtemplatexml}.to raise_error("Job ID not created")
		end
	end
	context "when importing template" do 
		it "should munge the config xml data" do
			Puppet::Module.stub(:find).with("idrac").and_return(@test_config_dir)
            Puppet::Provider::Exporttemplatexml.any_instance.stub(:exporttemplatexml).and_return("12341234")
            #Needed to call original open method by default
            original_method = File.method(:open)
            File.stub(:open).with(anything()) { |*args| original_method.call(*args) }
            File.stub(:open).with(File.join(@test_config_dir.path, @idrac_attrib[:configxmlfilename]), "w+").and_return('')
            xml = @fixture.munge_config_xml
            xml.xpath("//Attribute[@Name='Remove']").size.should == 0
            xml.xpath("//Component[@FQDD='RemoveMe']").size.should == 0
            xml.xpath("//Component[@FQDD='BIOS.Setup.1-1']/Attribute").first.content.should == "Disabled"
            xml.xpath("//Component[@FQDD='LifecycleController.Embedded.1']/Attribute").size.should_not == 0
		end
	end
end
