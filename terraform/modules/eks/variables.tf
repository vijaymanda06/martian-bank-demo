# EKS Module Variables
#
# Configuration variables for EKS cluster with Auto Mode
# Requirements: 5.1, 5.2, 6.1

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_id" {
  description = "ID of the VPC where the cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the cluster (should be private subnets)"
  type        = list(string)
}

# Auto Mode Configuration (Requirement 5.1, 5.2)
variable "auto_mode_node_pools" {
  description = "List of Auto Mode node pools. Options: general-purpose, system"
  type        = list(string)
  default     = ["general-purpose", "system"]
}

# Cluster Endpoint Access Configuration
variable "cluster_endpoint_public_access" {
  description = "Enable public access to cluster endpoint"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Access Entries for cluster administration
variable "access_entries" {
  description = "Map of access entries to add to the cluster"
  type        = any
  default     = {}
}

# Security Group Configuration
variable "cluster_security_group_additional_rules" {
  description = "Additional security group rules for the cluster security group"
  type        = any
  default     = {}
}

variable "node_security_group_additional_rules" {
  description = "Additional security group rules for the node security group"
  type        = any
  default     = {}
}

# Network Policy
variable "enable_network_policy" {
  description = "Enable network policy support in VPC CNI"
  type        = bool
  default     = true
}

# CloudWatch Logging
variable "cluster_enabled_log_types" {
  description = "List of control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# Common Tags
variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
