#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# order-ci.sh — Order a Catalog Item from the Red Hat demo catalog
#
# Usage: order-ci.sh <ci-name> [env] [domain] [activity] [purpose]
#
#   ci-name   Catalog item name to search for (required)
#   env       Environment: prod, dev, test, event (default: prod)
#   domain    "integration" for integration.demo.redhat.com, otherwise
#             catalog.demo.redhat.com (default: empty)
#   activity  Activity radio button selection (default: Admin)
#   purpose   Purpose dropdown selection (default: Asset Development)
#
# Requirements: playwright-cli (npm install -g @playwright/cli@latest)
#
# The browser opens in headed + persistent mode so login state is reused
# across sessions. If a login page is detected, the script pauses for you
# to authenticate manually.
###############################################################################

# --- Arguments ---------------------------------------------------------------

CI_NAME="${1:-}"
ENV="${2:-prod}"
DOMAIN="${3:-}"
ACTIVITY="${4:-Admin}"
PURPOSE="${5:-Asset Development}"

if [[ -z "$CI_NAME" ]]; then
  echo "Usage: $0 <ci-name> [env] [domain] [activity] [purpose]"
  echo "  env:      prod | dev | test | event  (default: prod)"
  echo "  domain:   integration | (empty)      (default: catalog.demo.redhat.com)"
  echo "  activity: e.g. Admin                 (default: Admin)"
  echo "  purpose:  e.g. Asset Development     (default: Asset Development)"
  exit 1
fi

# --- Resolve base URL --------------------------------------------------------

if [[ "$DOMAIN" == "integration" ]]; then
  BASE_URL="https://integration.demo.redhat.com/catalog"
else
  BASE_URL="https://catalog.demo.redhat.com/catalog"
fi

# --- Helpers -----------------------------------------------------------------

CLI="playwright-cli"
CLI_OPTS="--headed --browser=chrome --persistent"
SNAPSHOT_FILE=""

snapshot() {
  SNAPSHOT_FILE=$($CLI snapshot $CLI_OPTS 2>/dev/null | grep -oE '/[^ ]+\.md' | head -1)
  if [[ -z "$SNAPSHOT_FILE" ]]; then
    # Fallback: capture output directly
    $CLI snapshot $CLI_OPTS
    return 1
  fi
  echo "Snapshot saved to: $SNAPSHOT_FILE"
}

run_code() {
  $CLI run-code "$1" $CLI_OPTS
}

wait_for_user() {
  echo ""
  echo ">>> $1"
  echo "Press ENTER to continue..."
  read -r
}

# --- Step 1: Open browser and navigate --------------------------------------

echo "==> Opening browser at $BASE_URL ..."
OPEN_OUTPUT=$($CLI open "$BASE_URL" $CLI_OPTS 2>&1) || true
echo "$OPEN_OUTPUT"

# --- Step 2: Handle login if needed ------------------------------------------

if echo "$OPEN_OUTPUT" | grep -qiE 'log.in|sign.in|username|password|sso'; then
  wait_for_user "Login page detected. Please log in manually in the browser window."
  echo "==> Verifying catalog page loaded..."
  snapshot || true
fi

# --- Step 3: Search for the CI -----------------------------------------------

echo "==> Searching for '$CI_NAME' ..."
run_code "async (page) => {
  await page.getByRole('textbox', { name: 'Search' }).fill('$CI_NAME');
  await page.keyboard.press('Enter');
  await page.waitForTimeout(2000);
}"

# --- Step 4: Select the correct environment result ---------------------------

echo "==> Clicking first search result matching env '$ENV' ..."
run_code "async (page) => {
  const link = page.locator('a[href*=\"babylon-catalog-${ENV}\"]').first();
  await link.waitFor({ timeout: 5000 });
  await link.click();
  await page.waitForTimeout(2000);
}"

# --- Step 5: Click Order button ----------------------------------------------

echo "==> Clicking Order button ..."
run_code "async (page) => {
  const orderBtn = page.getByRole('button', { name: 'Order' });
  await orderBtn.waitFor({ timeout: 5000 });
  await orderBtn.click();
  await page.waitForTimeout(2000);
}"

# --- Step 6: Fill the order form ---------------------------------------------

echo "==> Filling order form (activity=$ACTIVITY, purpose=$PURPOSE) ..."
run_code "async (page) => {
  await page.getByRole('radio', { name: '$ACTIVITY' }).click();
  await page.getByRole('button', { name: '- Select purpose -' }).click();
  await page.getByRole('option', { name: '$PURPOSE' }).click();
  await page.getByText('Keep instance if provision').click();
  await page.getByRole('checkbox', { name: 'I confirm that I understand' }).click();
}"

# --- Step 7: Submit the order ------------------------------------------------

echo "==> Submitting order..."
run_code "async (page) => {
  await page.getByRole('button', { name: 'Order' }).click();
  await page.waitForTimeout(3000);
}"

# --- Step 9: Report result ---------------------------------------------------

RESULT_URL=$($CLI eval "window.location.href" $CLI_OPTS 2>&1) || true
echo ""
echo "============================================"
echo "  Order submitted!"
echo "  URL: $RESULT_URL"
echo "============================================"
echo ""
echo "Browser left open for review. Close it manually when done."
