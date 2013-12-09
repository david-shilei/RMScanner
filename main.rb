load 'rbvmomi_scanner.rb'

pod={:name=>"rdinfra3-vc4-1", 
     :host=>"rdinfra3-compute-vc4.eng.vmware.com", 
     :user=>"clouduser", 
     :password=>"SvL9n9123!", 
     :insecure=>1, 
     :datacenter=>"RDinfra3 VC4"}

conn_opts = {
      :host     => pod[:host],
      :user     => pod[:user],
      :password => pod[:password],
      :insecure => pod[:insecure],
    }

CLASSES_AND_MODUELS = [RbVmomi, RbVmomi::BasicTypes, RbVmomi::VIM::ComputeResource, RbVmomi::VIM::Datacenter, RbVmomi::VIM::Datastore, RbVmomi::VIM::DynamicTypeMgrAllTypeInfo, RbVmomi::VIM::DynamicTypeMgrDataTypeInfo, \
RbVmomi::VIM::DynamicTypeMgrManagedTypeInfo, RbVmomi::VIM::DynamicTypeMgrManagedTypeInfo, RbVmomi::VIM::Folder, RbVmomi::VIM::HostSystem, RbVmomi::VIM::ManagedEntity, RbVmomi::VIM::ManagedObject, RbVmomi::VIM::ObjectContent, \
RbVmomi::VIM::ObjectUpdate, RbVmomi::VIM::OvfManager, RbVmomi::VIM::PropertyCollector, RbVmomi::VIM::ReflectManagedMethodExecuter, RbVmomi::VIM::ResourcePool, RbVmomi::VIM::ServiceInstance, RbVmomi::VIM::Task, RbVmomi::VIM::VirtualMachine, \
RbVmomi::VIM::VirtualMachineConfigInfo]

scanner = RbVmomiScanner.new
CLASSES_AND_MODUELS.each do |class_or_module|
  scanner.scan class_or_module
end
scanner.scan_module(RbVmomi::VIM) # another Class also called this name
# scanner.scan RbVmomi::VIM::VirtualMachine

# vim = RbVmomi::VIM.connect(conn_opts)
# dc = vim.serviceInstance.find_datacenter(pod[:datacenter])
# nf = dc.vmFolder.traverse('nimbus', RbVmomi::VIM::Folder)
# #v = nf.traverse('*', RbVmomi::VIM::VirtualMachine)
# vm = dc.find_vm("users/dshi/dshi-david")
# vim.close