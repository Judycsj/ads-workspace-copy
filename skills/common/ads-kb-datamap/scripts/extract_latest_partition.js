// Extract the latest grass_date partition from DataMap Partition tab.
// Run via browser_evaluate on a DataMap Partition tab.
// Returns JSON string with latest_grass_date.
//
// DOM structure (Partition tab):
//   - Table 1: "Partition Column" (column definitions)
//   - Table 2: "Partition Detail" (actual partition values, newest first)
//     - Row format: "grass_date=YYYY-MM-DD/grass_region=XX" or "grass_date=YYYY-MM-DD"

() => {
  // Find the Partition Detail table (2nd table on the page)
  const tables = document.querySelectorAll('table');
  const detailTable = tables[1];
  if (!detailTable) {
    return JSON.stringify({ error: 'Partition Detail table not found' });
  }

  // Get the first row's Partition Name (newest partition, sorted desc by default)
  const firstRow = detailTable.querySelector('tbody tr');
  if (!firstRow) {
    return JSON.stringify({ error: 'No partition rows found' });
  }

  const partitionName = firstRow.querySelector('td')?.textContent?.trim() || '';

  // Parse grass_date=YYYY-MM-DD from the partition name
  const match = partitionName.match(/grass_date=(\d{4}-\d{2}-\d{2})/);
  if (!match) {
    return JSON.stringify({ error: 'Cannot parse grass_date', partitionName });
  }

  return JSON.stringify({ latest_grass_date: match[1] });
}
