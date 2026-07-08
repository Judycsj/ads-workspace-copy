// Extract column metadata from one page of DataMap Column Info tab.
// Run via browser_evaluate on the Column Info tab.
// Returns JSON string — array of column objects for the current page.
// PARTITION suffix is preserved (Python script handles stripping).

() => {
  const data = [];
  const rows = document.querySelectorAll('.ant-table-body table .ant-table-row');

  rows.forEach(row => {
    const cells = row.querySelectorAll('td');
    if (cells.length < 7) return;

    const name = cells[1]?.textContent?.trim();
    if (!name) return;

    data.push({
      name: name,
      type: cells[2]?.textContent?.trim() || '',
      desc: cells[3]?.textContent?.trim() || '',
      query: cells[7]?.textContent?.trim() || cells[6]?.textContent?.trim() || ''
    });
  });

  return JSON.stringify(data);
}
