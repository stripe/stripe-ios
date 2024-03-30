#!/usr/bin/env ruby

require_relative 'vm_tools'

if need_to_build_vm?
  build_vm
else
  print "VM already built! If you want to rebuild it, run `tart delete #{VM_NAME}` (and sonoma-base and sonoma-vanilla if you'd like) and try again."
end
