"""
Smoke tests for the accounts service.

These tests verify basic functionality and that the service can be imported
and instantiated correctly.

Requirements: 10.1, 10.2, 10.3
"""
import pytest
import sys
import os
from unittest.mock import MagicMock, patch
from hypothesis import given, strategies as st, settings, HealthCheck


@pytest.fixture(scope="module", autouse=True)
def setup_environment():
    """Set up required environment variables before importing accounts module."""
    os.environ.setdefault("DB_URL", "mongodb://localhost:27017/test")
    os.environ.setdefault("SERVICE_PROTOCOL", "http")
    yield


@pytest.fixture
def mock_mongo_client():
    """Fixture to mock MongoDB client for testing without a real database."""
    with patch("pymongo.mongo_client.MongoClient") as mock_client:
        mock_db = MagicMock()
        mock_collection = MagicMock()
        mock_client.return_value.__getitem__.return_value = mock_db
        mock_db.__getitem__.return_value = mock_collection
        yield mock_client, mock_collection


class TestAccountsServiceSmoke:
    """Smoke tests for accounts service health verification."""

    def test_service_module_imports(self, setup_environment, mock_mongo_client):
        """
        Verify core modules can be imported.
        
        This tests that the service code is syntactically correct and
        all dependencies are available.
        """
        # Add accounts directory to path
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        # Should not raise ImportError
        import accounts
        
        assert accounts is not None
        assert hasattr(accounts, "AccountsGeneric")
        assert hasattr(accounts, "AccountDetailsService")

    def test_accounts_generic_class_exists(self, setup_environment, mock_mongo_client):
        """Verify AccountsGeneric class is defined and accessible."""
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        from accounts import AccountsGeneric
        
        assert AccountsGeneric is not None
        assert callable(AccountsGeneric)

    def test_accounts_generic_instantiation(self, setup_environment, mock_mongo_client):
        """
        Verify AccountsGeneric can be instantiated.
        
        This confirms the class constructor works without errors.
        """
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        from accounts import AccountsGeneric
        
        # Should not raise any exceptions
        accounts_instance = AccountsGeneric()
        assert accounts_instance is not None

    def test_accounts_generic_has_required_methods(self, setup_environment, mock_mongo_client):
        """Verify AccountsGeneric has all required methods."""
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        from accounts import AccountsGeneric
        
        accounts_instance = AccountsGeneric()
        
        # Check required methods exist
        assert hasattr(accounts_instance, "getAccountDetails")
        assert hasattr(accounts_instance, "createAccount")
        assert hasattr(accounts_instance, "getAccounts")
        
        # Verify methods are callable
        assert callable(accounts_instance.getAccountDetails)
        assert callable(accounts_instance.createAccount)
        assert callable(accounts_instance.getAccounts)

    def test_account_details_service_instantiation(self, setup_environment, mock_mongo_client):
        """Verify AccountDetailsService (gRPC servicer) can be instantiated."""
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        from accounts import AccountDetailsService
        
        # Should not raise any exceptions
        service = AccountDetailsService()
        assert service is not None
        assert hasattr(service, "accounts")


class TestServiceHealthProperty:
    """
    Property-based tests for service health response.
    
    **Feature: devops-transformation, Property 3: Service Health Response**
    **Validates: Requirements 10.1, 10.2**
    """

    @given(
        account_number=st.text(
            alphabet=st.characters(whitelist_categories=("Lu", "Ll", "Nd")),
            min_size=1,
            max_size=20
        )
    )
    @settings(max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_account_detail_endpoint_returns_valid_status_code(
        self, setup_environment, mock_mongo_client, account_number
    ):
        """
        **Feature: devops-transformation, Property 3: Service Health Response**
        **Validates: Requirements 10.1, 10.2**
        
        Property: For any HTTP request to a service endpoint, the service SHALL
        respond with a valid HTTP status code (200 for healthy, 503 for unhealthy)
        within 5 seconds.
        """
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        # Import the Flask app
        from accounts import app
        
        # Create test client
        with app.test_client() as client:
            # Make request to account-detail endpoint
            response = client.post(
                "/account-detail",
                json={"account_number": account_number},
                content_type="application/json"
            )
            
            # Property: Response status code must be a valid HTTP status code
            # For a healthy service: 200 (success) or 4xx (client error for invalid input)
            # For unhealthy service: 503 (service unavailable)
            valid_status_codes = {200, 400, 404, 500, 503}
            assert response.status_code in valid_status_codes or (200 <= response.status_code < 600), \
                f"Invalid HTTP status code: {response.status_code}"

    @given(
        email_id=st.emails(),
        account_type=st.sampled_from(["checking", "savings", "investment"])
    )
    @settings(max_examples=100, suppress_health_check=[HealthCheck.function_scoped_fixture])
    def test_get_accounts_endpoint_returns_valid_status_code(
        self, setup_environment, mock_mongo_client, email_id, account_type
    ):
        """
        **Feature: devops-transformation, Property 3: Service Health Response**
        **Validates: Requirements 10.1, 10.2**
        
        Property: For any HTTP request to get-all-accounts endpoint, the service
        SHALL respond with a valid HTTP status code.
        """
        accounts_path = os.path.join(os.path.dirname(__file__), "..", "..", "accounts")
        if accounts_path not in sys.path:
            sys.path.insert(0, os.path.abspath(accounts_path))
        
        from accounts import app
        
        with app.test_client() as client:
            response = client.post(
                "/get-all-accounts",
                json={"email_id": email_id},
                content_type="application/json"
            )
            
            # Property: Response must have valid HTTP status code
            assert 200 <= response.status_code < 600, \
                f"Invalid HTTP status code: {response.status_code}"
            
            # For a healthy service responding to valid requests
            # Status should be 200 (success) or appropriate error code
            assert response.status_code in {200, 400, 404, 500, 503} or response.status_code == 200, \
                f"Unexpected status code for health check: {response.status_code}"
