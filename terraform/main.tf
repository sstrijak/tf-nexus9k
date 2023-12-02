
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    nxos = {
      source  = "CiscoDevNet/nxos"
      version = ">= 0.5.0"
    }
    utils = {
      source  = "netascode/utils"
      version = ">= 0.2.5"
    }
  }
}

data "utils_yaml_merge" "model" {
  input = [for file in fileset(path.module, "data/*.yaml") : file(file)]
}

locals {
  model = yamldecode(data.utils_yaml_merge.model.output)
  devices    = concat(lookup(local.model.fabric.inventory, "FENs", []), lookup(local.model.fabric.inventory, "FBNs", []))
  fens       = toset([for fen in lookup(local.model.fabric.inventory, "FENs", []) : fen.name])
  fbns       = toset([for fbn in lookup(local.model.fabric.inventory, "FBNs", []) : fbn.name])
  loopbacks  = tomap({for loopback in local.model.fabric.underlay.loopbacks: loopback.device => loopback.ipv4_address })
  isis_nets  = tomap({for loopback in local.model.fabric.underlay.loopbacks: loopback.device => loopback.isis_net })
  ul_ifs              = toset([for un_if in lookup(local.model.fabric.underlay, "interfaces", []) : un_if.ref ])
  underlay_ifs        = toset([for un_if in lookup(local.model.fabric.underlay, "interfaces", []) : un_if.ref ])
  underlay_if_devices = tomap({for interface in local.model.fabric.underlay.interfaces: interface.ref => interface.device })
  underlay_if_ids     = tomap({for interface in local.model.fabric.underlay.interfaces: interface.ref => interface.id })
  underlay_if_vrfs    = tomap({for interface in local.model.fabric.underlay.interfaces: interface.ref => interface.vrf })
  underlay_if_descs   = tomap({for interface in local.model.fabric.underlay.interfaces: interface.ref => interface.description })
  underlay_if_ips     = tomap({for interface in local.model.fabric.underlay.interfaces: interface.ref => interface.ipv4_address })
}

provider "nxos" {
  devices = local.devices
}

resource "nxos_vrf" "infra" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  name        = "infra"
  description = "Infrastructure"
  encap       = "vxlan-103901"
}

resource "nxos_vrf" "default" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  name        = "default"
#  description = "Default"
#  encap       = "vxlan-103901"
}

resource "nxos_ipv4_vrf" "default" {
  name = "default"
}

resource "nxos_loopback_interface" "loopback99" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  interface_id = "lo99"
  admin_state  = "up"
  description  = "Loopback for fabric operation"
}

resource "nxos_loopback_interface_vrf" "loopback99" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  interface_id = "lo99"
  vrf_dn       = "sys/inst-infra"
  depends_on = [
    nxos_vrf.infra
  ]
}

resource "nxos_ipv4_interface" "loopback99" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  vrf          = "infra"
  interface_id = "lo99"
}

resource "nxos_ipv4_interface_address" "loopback99" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  vrf          = "infra"
  interface_id = "loopback99"
  address      = lookup(local.loopbacks, each.key, "127.0.0.1/32")
  type         = "primary"
  depends_on = [
    nxos_vrf.infra,
    nxos_loopback_interface.loopback99
  ]
}




resource "nxos_loopback_interface" "loopback0" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  interface_id = "lo0"
  admin_state  = "up"
  description  = "Loopback for fabric operation"
}

resource "nxos_loopback_interface_vrf" "loopback0" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  interface_id = "lo0"
  vrf_dn       = "sys/inst-default"
  depends_on = [
    nxos_vrf.infra
  ]
}

resource "nxos_ipv4_interface" "loopback0" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  vrf          = "default"
  interface_id = "lo0"
}

resource "nxos_ipv4_interface_address" "loopback0" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  vrf          = "default"
  interface_id = "loopback0"
  address      = lookup(local.loopbacks, each.key, "127.0.0.1/32")
  type         = "primary"
  depends_on = [
    nxos_vrf.infra,
    nxos_loopback_interface.loopback0
  ]
}





resource "nxos_physical_interface" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  interface_id = lookup(local.underlay_if_ids, each.key, "")
  description  = lookup(local.underlay_if_descs, each.key, "")
  admin_state  = "up"
  layer        = "Layer3"
  mtu          = 9100
}


resource "nxos_physical_interface_vrf" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  interface_id = lookup(local.underlay_if_ids, each.key, "")
  vrf_dn       = "sys/inst-${lookup(local.underlay_if_vrfs, each.key, "")}"
  depends_on = [
    nxos_ipv4_vrf.default,
    nxos_physical_interface.underlay_if
  ]
}

resource "nxos_ipv4_interface" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  interface_id = lookup(local.underlay_if_ids, each.key, "")
  vrf          = lookup(local.underlay_if_vrfs, each.key, "")
  depends_on = [
    nxos_ipv4_vrf.default,
    nxos_physical_interface.underlay_if
  ]
}

resource "nxos_ipv4_interface_address" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  interface_id = lookup(local.underlay_if_ids, each.key, "")
  vrf          = lookup(local.underlay_if_vrfs, each.key, "")
#  vrf          = "default"
  address      = lookup(local.underlay_if_ips, each.key, "127.0.0.1/32")
  type         = "primary"
  depends_on = [
    nxos_ipv4_vrf.default,
    nxos_physical_interface.underlay_if
  ]
}

resource "nxos_feature_isis" "underlay" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  admin_state = "enabled"
}

resource "nxos_isis" "underlay" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  admin_state = "enabled"
}

resource "nxos_isis_instance" "underlay" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  name        = "underlay"
  admin_state = "enabled"
  depends_on = [
    nxos_isis.underlay
  ]
}

resource "nxos_isis_vrf" "underlay" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  instance_name= "underlay"
  name         = "default"
  metric_type  = "wide"
#  net          = "49.0001.0000.0000.3333.00"
  net          = lookup(local.isis_nets, each.key, "49.0001.0000.0000.3333.00")
  depends_on = [
    nxos_isis_instance.underlay
  ]
}


resource "nxos_isis_interface" "underlay_lo" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  interface_id = "lo0"
  vrf          = "default"
  network_type_p2p        = "on"
}

resource "nxos_isis_interface" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  interface_id = lookup(local.underlay_if_ids, each.key, "")
  vrf          = lookup(local.underlay_if_vrfs, each.key, "")
  network_type_p2p        = "on"
  depends_on = [
    nxos_isis_vrf.underlay,
    nxos_ipv4_interface_address.underlay_if
  ]
}

resource "nxos_rest" "underlay_if" {
  for_each     = toset([for interface in local.underlay_ifs : interface])
  device       = lookup(local.underlay_if_devices, each.key, "")
  dn       = "sys/isis/if-[${lookup(local.underlay_if_vrfs, each.key, "")}]"
  class_name = "isisInternalIf"
  content = {
    id   = lookup(local.underlay_if_ids, each.key, "")
    instance = "underlay"
    v4enable = "yes"
  }
}

resource "nxos_rest" "isis_af" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  dn       = "sys/isis/inst-underlay/dom-default"
  class_name = "isisDomAf"
  content = {
    type = "v4"
  }
}

resource "nxos_rest" "isis_advertise" {
  for_each     = toset([for fn in local.devices : fn.name])
  device       = each.key
  dn       = "sys/isis/inst-underlay/dom-default/af-v4"
  class_name = "isisAdvertiseInt"
  content = {
    advtIf = "lo0"
  }
}

