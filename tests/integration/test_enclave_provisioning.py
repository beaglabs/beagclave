#!/usr/bin/env python3
"""
Integration test for Beagclave enclave provisioning.
Validates that all core resources are created correctly.
"""

import os
import pytest
from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.desktopvirtualizer import DesktopVirtualizationClient
from azure.mgmt.containerservice import ContainerServiceClient
from azure.mgmt.purview import PurviewClient
from azure.mgmt.operationalinsights import OperationalInsightsClient

ENCLAVE_NAME = os.environ.get("ENCLAVE_NAME", "beagclave")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "test")
RESOURCE_GROUP = f"{ENCLAVE_NAME}-{ENVIRONMENT}"
SUBSCRIPTION_ID = os.environ.get("ARM_SUBSCRIPTION_ID", "")

@pytest.fixture(scope="module")
def clients():
    credentials = DefaultAzureCredential()
    return {
        "resource": ResourceManagementClient(credentials, SUBSCRIPTION_ID),
        "avd": DesktopVirtualizationClient(credentials, SUBSCRIPTION_ID),
        "aks": ContainerServiceClient(credentials, SUBSCRIPTION_ID),
        "purview": PurviewClient(credentials, SUBSCRIPTION_ID),
        "logs": OperationalInsightsClient(credentials, SUBSCRIPTION_ID),
    }

class TestResourceExistence:
    """Test that all required resources are provisioned."""

    def test_resource_group_exists(self, clients):
        rg = clients["resource"].resource_groups.get(RESOURCE_GROUP)
        assert rg is not None
        assert "nist-800-171" in rg.tags.get("compliance", "")

    def test_avd_host_pool_exists(self, clients):
        pools = clients["avd"].host_pools.list(RESOURCE_GROUP)
        pool_names = [p.name for p in pools]
        matching = [n for n in pool_names if ENCLAVE_NAME in n]
        assert len(matching) > 0, "No AVD host pool found"

    def test_avd_workspace_exists(self, clients):
        workspaces = clients["avd"].workspaces.list_by_resource_group(RESOURCE_GROUP)
        ws_names = [w.name for w in workspaces]
        matching = [n for n in ws_names if ENCLAVE_NAME in n]
        assert len(matching) > 0, "No AVD workspace found"

    def test_aks_cluster_exists(self, clients):
        clusters = clients["aks"].managed_clusters.list(RESOURCE_GROUP)
        cluster_names = [c.name for c in clusters]
        matching = [n for n in cluster_names if ENCLAVE_NAME in n]
        assert len(matching) > 0, "No AKS cluster found"

    def test_purview_account_exists(self, clients):
        accounts = clients["purview"].accounts.list_by_resource_group(RESOURCE_GROUP)
        account_names = [a.name for a in accounts]
        matching = [n for n in account_names if ENCLAVE_NAME in n]
        assert len(matching) > 0, "No Purview account found"

    def test_log_analytics_exists(self, clients):
        workspaces = clients["logs"].workspaces.list_by_resource_group(RESOURCE_GROUP)
        ws_names = [w.name for w in workspaces]
        matching = [n for n in ws_names if ENCLAVE_NAME in n]
        assert len(matching) > 0, "No Log Analytics workspace found"

class TestAVDConfiguration:
    """Test AVD-specific security configurations."""

    def test_host_pool_is_pooled(self, clients):
        pools = clients["avd"].host_pools.list(RESOURCE_GROUP)
        for pool in pools:
            if ENCLAVE_NAME in pool.name:
                assert pool.properties.custom_rdp_property is not None
                assert "redirectclipboard:i:0" in pool.properties.custom_rdp_property
                assert "redirectprinters:i:0" in pool.properties.custom_rdp_property
                break

    def test_max_session_limit(self, clients):
        pools = clients["avd"].host_pools.list(RESOURCE_GROUP)
        for pool in pools:
            if ENCLAVE_NAME in pool.name:
                assert pool.properties.validation_environment is False
                break

class TestAKSConfiguration:
    """Test AKS security configurations."""

    def test_aks_has_network_policy(self, clients):
        clusters = clients["aks"].managed_clusters.list(RESOURCE_GROUP)
        for cluster in clusters:
            if ENCLAVE_NAME in cluster.name:
                assert cluster.properties.network_profile.network_policy == "calico"
                assert cluster.properties.api_server_profile.enable_private_cluster is True
                break

    def test_aks_has_oidc_enabled(self, clients):
        clusters = clients["aks"].managed_clusters.list(RESOURCE_GROUP)
        for cluster in clusters:
            if ENCLAVE_NAME in cluster.name:
                assert cluster.properties.oidc_issuer_profile.enabled is True
                break

class TestPurviewConfiguration:
    """Test Purview data protection configurations."""

    def test_purview_account_sku(self, clients):
        accounts = clients["purview"].accounts.list_by_resource_group(RESOURCE_GROUP)
        for account in accounts:
            if ENCLAVE_NAME in account.name:
                assert account.sku.name == "Standard"
                break

class TestPolicyCompliance:
    """Test Azure Policy compliance."""

    def test_resource_group_has_tags(self, clients):
        rg = clients["resource"].resource_groups.get(RESOURCE_GROUP)
        assert "project" in rg.tags
        assert "compliance" in rg.tags
        assert rg.tags["compliance"] == "nist-800-171"

if __name__ == "__main__":
    pytest.main([__file__, "-v"])