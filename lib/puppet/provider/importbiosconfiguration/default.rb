provider_path = Pathname.new(__FILE__).parent.parent
require 'rexml/document'
include REXML
require File.join(provider_path, 'idrac')
require File.join(provider_path, 'checklcstatus')
require File.join(provider_path, 'checkjdstatus')
require File.join(provider_path, 'importtemplatexml')

Puppet::Type.type(:importbiosconfiguration).provide(:importbiosconfiguration, :parent => Puppet::Provider::Idrac) do
  desc "Dell idrac provider for import system configuration."
  $count = 0
  $maxcount = 30

  def create
    memtest = resource[:memtest]
    procvirtualization = resource[:procvirtualization]
    proccores = resource[:proccores]
    bootmode = resource[:bootmode]
    bootseqretry = resource[:bootseqretry]
    integratedraid = resource[:integratedraid]
    usbports = resource[:usbports]
    internalusb = resource[:internalusb]
    internalsdcard = resource[:internalsdcard]
    internalsdcardredundancy = resource[:internalsdcardredundancy]
    integratednetwork1 = resource[:integratednetwork1]
    puts internalsdcard
    file = File.new('/etc/puppet/modules/idrac/lib/puppet/provider/defaultxmls/biosconfiguration.xml')
    xmldoc = Document.new(file)
    
    xmldoc.elements.each("SystemConfiguration/Component/Attribute") { 
      |e|  if e.attributes["Name"] == "MemTest"
             e.text = memtest
           end 
           if e.attributes["Name"] == "ProcVirtualization"
             e.text = procvirtualization
           end
           if e.attributes["Name"] == "ProcCores"
             e.text = proccores
           end
           if e.attributes["Name"] == "BootMode"
             e.text = bootmode
           end
           if e.attributes["Name"] == "BootSeqRetry"
             e.text = bootseqretry
           end
           if e.attributes["Name"] == "IntegratedRaid"
             e.text = integratedraid
           end
           if e.attributes["Name"] == "UsbPorts"
             e.text = usbports
           end
           if e.attributes["Name"] == "InternalUsb"
             e.text = internalusb
           end
           if e.attributes["Name"] == "InternalSdCard"
             e.text = internalsdcard
           end
           if e.attributes["Name"] == "InternalSdCardRedundancy"
             e.text = internalsdcardredundancy
           end
           if e.attributes["Name"] == "IntegratedNetwork1"
             e.text = integratednetwork1
           end
    }
    biosconfigurationfile = "#{resource[:nfssharepath]}/biosconfiguration.xml"
    file = File.open("#{biosconfigurationfile}", "w")
    xmldoc.write(file)
    #Need to close the file
    file.close
    biosconfiguration = "biosconfiguration.xml"
    #Import System Configuration
    obj = Puppet::Provider::Importtemplatexml.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword],biosconfiguration,resource[:nfsipaddress],resource[:nfssharepath])
    instanceid = obj.importtemplatexml
    puts "Instance id #{instanceid}"
    for i in 0..30
        obj = Puppet::Provider::Checkjdstatus.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword],instanceid)
        response = obj.checkjdstatus
        puts "JD status : #{response}"
        if response  == "Completed"
            Puppet.info "Import System Configuration is completed."
            break
        else
            Puppet.info "Job is running, wait for 1 minute"
            sleep 60
        end
    end
    if response != "Completed"
      raise "Import System Configuration is still running."
    end
    

  end
  
  def exists?
    puts "Inside exist"
    obj = Puppet::Provider::Checklcstatus.new(resource[:dracipaddress],resource[:dracusername],resource[:dracpassword])
    response = obj.checklcstatus
    response = response.to_i
    if response == 0
        return false
    else
        #recursive call  method exists till lcstatus =0
        while $count < $maxcount  do
            Puppet.info "LC status busy, wait for 1 minute"
            sleep 60
            $count +=1
            exists?
        end
        raise Puppet::Error, "Life cycle controller is busy"
        return true
    end
  end

end
