import pytest

@pytest.fixture
def enclave_name():
    return "beagclave-test"

@pytest.fixture
def subscription_id():
    import os
    return os.environ.get("ARM_SUBSCRIPTION_ID", "")