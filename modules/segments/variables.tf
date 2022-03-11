# NSX-T Segment Module - variables

variable "segment_tenant" {
    type    = string
    default = "Unlisted"
}

variable "segment_names" {
    description = "Segment Names for main.tf"
    type        = list(string) 
} 

variable "segment_IPs" {
    description = "CIDR Blocks example: 10.180.160.1/24"
    type        = list(string)
}