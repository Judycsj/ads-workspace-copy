// Extract query results from DataSuite result table.
// Run via browser_evaluate after query completes.
// Returns JSON string with headers and values arrays.
// Strips trailing "View Row" cell from each row.

() => {
  const tables = document.querySelectorAll('table');
  let targetTable = null;
  let maxCols = 0;

  // Find the result table (widest table = most columns)
  tables.forEach(t => {
    const ths = t.querySelectorAll('thead th');
    if (ths.length > maxCols) {
      maxCols = ths.length;
      targetTable = t;
    }
  });

  if (!targetTable) {
    return JSON.stringify({ error: 'No result table found' });
  }

  // Extract headers (skip last "View Row" column)
  const thEls = targetTable.querySelectorAll('thead th');
  const headers = [];
  for (let i = 0; i < thEls.length - 1; i++) {
    headers.push(thEls[i].textContent.trim());
  }

  // Extract first row values (skip last cell)
  const firstRow = targetTable.querySelector('tbody tr');
  const values = [];
  if (firstRow) {
    const cells = firstRow.querySelectorAll('td');
    for (let i = 0; i < cells.length - 1; i++) {
      values.push(cells[i].textContent.trim());
    }
  }

  return JSON.stringify({ headers, values });
}
