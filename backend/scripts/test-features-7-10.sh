#!/bin/bash

# Test script for Features 7-10 API endpoints
# This script tests the basic connectivity of all new endpoints

BASE_URL="http://localhost:6000"

echo "=========================================="
echo "Testing GreenBasket Features 7-10 APIs"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test counter
TOTAL=0
PASSED=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    
    TOTAL=$((TOTAL + 1))
    echo -n "Testing: $description... "
    
    response=$(curl -s -o /dev/null -w "%{http_code}" -X $method "$BASE_URL$endpoint")
    
    # Accept 200, 401 (auth required), 400 (bad request) as valid responses
    # We're just checking if the route exists
    if [[ $response == "200" || $response == "401" || $response == "400" || $response == "404" ]]; then
        if [[ $response == "404" ]]; then
            echo -e "${RED}FAIL${NC} (Route not found)"
        else
            echo -e "${GREEN}PASS${NC} (Status: $response)"
            PASSED=$((PASSED + 1))
        fi
    else
        echo -e "${RED}FAIL${NC} (Status: $response)"
    fi
}

echo "=== FEATURE 7: REFERRAL SYSTEM ==="
test_endpoint "GET" "/api/referral/validate/TEST123" "Validate Referral Code (Public)"
test_endpoint "POST" "/api/referral/generate" "Generate Referral Code (Auth Required)"
test_endpoint "GET" "/api/referral/stats" "Get Referral Stats (Auth Required)"
test_endpoint "POST" "/api/referral/apply" "Apply Referral Code (Auth Required)"
test_endpoint "POST" "/api/referral/process-reward" "Process Reward (Admin)"
echo ""

echo "=== FEATURE 8: OFFERS & PROMOTIONS ==="
test_endpoint "GET" "/api/offers/flash-sales" "Get Flash Sales (Public)"
test_endpoint "GET" "/api/offers/available" "Get Available Offers (Auth Required)"
test_endpoint "POST" "/api/offers" "Create Offer (Merchant/Admin)"
test_endpoint "GET" "/api/offers/merchant" "Get Merchant Offers (Merchant)"
test_endpoint "POST" "/api/offers/cart/apply-coupon" "Apply Coupon (User)"
test_endpoint "DELETE" "/api/offers/cart/remove-coupon" "Remove Coupon (User)"
test_endpoint "GET" "/api/offers/admin/all" "Get All Offers (Admin)"
echo ""

echo "=== FEATURE 9: MERCHANT ANALYTICS ==="
test_endpoint "GET" "/api/merchants/analytics/sales" "Sales Analytics (Merchant)"
test_endpoint "GET" "/api/merchants/analytics/products" "Product Analytics (Merchant)"
test_endpoint "GET" "/api/merchants/analytics/customers" "Customer Analytics (Merchant)"
test_endpoint "GET" "/api/merchants/analytics/inventory" "Inventory Analytics (Merchant)"
test_endpoint "GET" "/api/merchants/analytics/forecast" "Revenue Forecast (Merchant)"
test_endpoint "GET" "/api/merchants/analytics/reviews" "Review Analytics (Merchant)"
echo ""

echo "=== FEATURE 10: DELIVERY ZONES ==="
test_endpoint "POST" "/api/merchants/zones/check-delivery" "Check Delivery (Public)"
test_endpoint "POST" "/api/merchants/zones/nearby" "Get Nearby Merchants (Public)"
test_endpoint "PUT" "/api/merchants/zones/location" "Set Location (Merchant)"
test_endpoint "GET" "/api/merchants/zones/delivery-zones" "Get Zones (Merchant)"
test_endpoint "POST" "/api/merchants/zones/delivery-zones" "Add Zone (Merchant)"
echo ""

echo "=========================================="
echo "Test Results: $PASSED/$TOTAL endpoints responding"
echo "=========================================="

if [ $PASSED -eq $TOTAL ]; then
    echo -e "${GREEN}✓ All routes are properly registered!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some routes may not be registered correctly${NC}"
    echo "Note: 401/400 responses are expected for protected routes without auth"
    exit 1
fi
