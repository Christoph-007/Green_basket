#!/bin/bash

# Green Basket API Testing Script
# This script tests all major API endpoints

BASE_URL="http://localhost:5001/api"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Testing Green Basket APIs..."
echo "================================"
echo ""

# Test counter
TOTAL=0
PASSED=0
FAILED=0

# Function to test endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local token=$5
    
    TOTAL=$((TOTAL + 1))
    echo -n "Testing: $description... "
    
    if [ -z "$token" ]; then
        if [ "$method" == "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" "$BASE_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" -H "Content-Type: application/json" -d "$data" "$BASE_URL$endpoint")
        fi
    else
        if [ "$method" == "GET" ]; then
            response=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $token" "$BASE_URL$endpoint")
        else
            response=$(curl -s -w "\n%{http_code}" -X "$method" -H "Content-Type: application/json" -H "Authorization: Bearer $token" -d "$data" "$BASE_URL$endpoint")
        fi
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ PASS${NC} (HTTP $http_code)"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}✗ FAIL${NC} (HTTP $http_code)"
        FAILED=$((FAILED + 1))
        echo "  Response: $body"
    fi
}

echo "📋 1. HEALTH CHECK APIS"
echo "------------------------"
test_endpoint "GET" "/" "Root health check"
test_endpoint "GET" "/health" "API health check"
test_endpoint "GET" "" "API documentation"
echo ""

echo "📂 2. CATEGORY APIS"
echo "-------------------"
test_endpoint "GET" "/categories" "Get all categories"
echo ""

echo "🛍️  3. PRODUCT APIS"
echo "-------------------"
test_endpoint "GET" "/products" "Get all products"
test_endpoint "GET" "/products?limit=5" "Get products with limit"
test_endpoint "GET" "/products?category=vegetables" "Filter by category"
test_endpoint "GET" "/products?search=tomato" "Search products"
echo ""

echo "🍳 4. RECIPE APIS"
echo "-----------------"
test_endpoint "GET" "/recipes" "Get all recipes"
echo ""

echo "🔐 5. AUTHENTICATION APIS"
echo "-------------------------"

# Test User Login
echo -n "Testing: User login... "
login_response=$(curl -s -X POST "$BASE_URL/auth/user/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}')

if echo "$login_response" | grep -q "accessToken"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
    USER_TOKEN=$(echo "$login_response" | jq -r '.data.accessToken')
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
    echo "  Response: $login_response"
fi
TOTAL=$((TOTAL + 1))

# Test Merchant Login
echo -n "Testing: Merchant login... "
merchant_login=$(curl -s -X POST "$BASE_URL/auth/merchant/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"merchant@example.com","password":"password123"}')

if echo "$merchant_login" | grep -q "accessToken"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
    MERCHANT_TOKEN=$(echo "$merchant_login" | jq -r '.data.accessToken')
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi
TOTAL=$((TOTAL + 1))

# Test Admin Login
echo -n "Testing: Admin login... "
admin_login=$(curl -s -X POST "$BASE_URL/auth/admin/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@greenbasket.com","password":"admin123"}')

if echo "$admin_login" | grep -q "accessToken"; then
    echo -e "${GREEN}✓ PASS${NC}"
    PASSED=$((PASSED + 1))
    ADMIN_TOKEN=$(echo "$admin_login" | jq -r '.data.accessToken')
else
    echo -e "${RED}✗ FAIL${NC}"
    FAILED=$((FAILED + 1))
fi
TOTAL=$((TOTAL + 1))
echo ""

echo "👤 6. USER APIS (Protected)"
echo "---------------------------"
if [ ! -z "$USER_TOKEN" ]; then
    test_endpoint "GET" "/users/profile" "Get user profile" "" "$USER_TOKEN"
    test_endpoint "GET" "/users/addresses" "Get user addresses" "" "$USER_TOKEN"
else
    echo -e "${YELLOW}⚠ Skipped (no user token)${NC}"
fi
echo ""

echo "🛒 7. CART APIS (Protected)"
echo "---------------------------"
if [ ! -z "$USER_TOKEN" ]; then
    test_endpoint "GET" "/cart" "Get cart" "" "$USER_TOKEN"
else
    echo -e "${YELLOW}⚠ Skipped (no user token)${NC}"
fi
echo ""

echo "🏪 8. MERCHANT APIS (Protected)"
echo "-------------------------------"
if [ ! -z "$MERCHANT_TOKEN" ]; then
    test_endpoint "GET" "/merchants/profile" "Get merchant profile" "" "$MERCHANT_TOKEN"
    test_endpoint "GET" "/merchants/dashboard-stats" "Get dashboard stats" "" "$MERCHANT_TOKEN"
else
    echo -e "${YELLOW}⚠ Skipped (no merchant token)${NC}"
fi
echo ""

echo "👨‍💼 9. ADMIN APIS (Protected)"
echo "-----------------------------"
if [ ! -z "$ADMIN_TOKEN" ]; then
    test_endpoint "GET" "/admin/merchants/pending" "Get pending merchants" "" "$ADMIN_TOKEN"
    test_endpoint "GET" "/admin/stats" "Get platform stats" "" "$ADMIN_TOKEN"
else
    echo -e "${YELLOW}⚠ Skipped (no admin token)${NC}"
fi
echo ""

echo "================================"
echo "📊 TEST SUMMARY"
echo "================================"
echo "Total Tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $FAILED${NC}"
else
    echo -e "${GREEN}Failed: $FAILED${NC}"
fi

SUCCESS_RATE=$((PASSED * 100 / TOTAL))
echo "Success Rate: $SUCCESS_RATE%"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
