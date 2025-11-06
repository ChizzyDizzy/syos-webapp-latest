<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.syos.domain.entities.User" %>
<%@ page import="com.syos.domain.valueobjects.UserRole" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/views/auth/login.jsp");
        return;
    }
    UserRole role = currentUser.getRole();

    if (role != UserRole.MANAGER && role != UserRole.ADMIN) {
        response.sendRedirect(request.getContextPath() + "/views/sales/dashboard.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - Reorder Report</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="dashboard-container">
    <aside class="sidebar">
        <div class="sidebar-header">
            <h2>🏪 SYOS POS</h2>
            <div class="user-info">
                <p class="user-name"><%= currentUser.getUsername() %></p>
                <p class="user-role"><%= role %></p>
            </div>
        </div>

        <nav class="sidebar-nav">
            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📈</span>
                <span>Reports Dashboard</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/daily-sales.jsp" class="nav-link">
                <span class="nav-icon">💰</span>
                <span>Daily Sales</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/stock-report.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Stock Report</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/reorder-report.jsp" class="nav-link active">
                <span class="nav-icon">🔄</span>
                <span>Reorder Report</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/reshelve-report.jsp" class="nav-link">
                <span class="nav-icon">⚠️</span>
                <span>Reshelve Report</span>
            </a>
        </nav>

        <div class="sidebar-footer">
            <button id="logout-btn" class="btn btn-danger btn-block">🚪 Logout</button>
        </div>
    </aside>

    <main class="main-content">
        <header class="content-header">
            <h1>Reorder Report</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Report Controls -->
            <div class="table-container">
                <h2>Generate Reorder Report</h2>
                <p class="text-muted">Items that are below or at reorder level and need restocking.</p>

                <div class="form-group">
                    <label for="urgency-level">Urgency Level</label>
                    <select id="urgency-level" class="form-control">
                        <option value="all">All Low Stock Items</option>
                        <option value="critical">Critical (Out of Stock)</option>
                        <option value="urgent">Urgent (Below Min Level)</option>
                        <option value="warning">Warning (At Min Level)</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="report-format">Report Format</label>
                    <select id="report-format" class="form-control">
                        <option value="text">Text Format</option>
                        <option value="html">HTML Format</option>
                        <option value="csv">CSV Format</option>
                    </select>
                </div>

                <div class="form-group">
                    <button class="btn btn-primary" onclick="generateReorderReport()">
                        Generate Report
                    </button>
                    <button class="btn btn-warning" onclick="generateCriticalReport()">
                        Critical Items Only
                    </button>
                    <button class="btn btn-secondary" onclick="exportReorderList()">
                        Export Order List
                    </button>
                </div>
            </div>

            <!-- Reorder Statistics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Critical Items</h3>
                    <p class="stat-value" id="critical-count">0</p>
                    <p class="stat-label">Out of Stock</p>
                </div>
                <div class="stat-card">
                    <h3>Urgent Items</h3>
                    <p class="stat-value" id="urgent-count">0</p>
                    <p class="stat-label">Below Min Level</p>
                </div>
                <div class="stat-card">
                    <h3>Warning Items</h3>
                    <p class="stat-value" id="warning-count">0</p>
                    <p class="stat-label">At Min Level</p>
                </div>
                <div class="stat-card">
                    <h3>Total Value</h3>
                    <p class="stat-value" id="reorder-value">$0.00</p>
                    <p class="stat-label">Restocking Cost</p>
                </div>
            </div>

            <!-- Priority Actions -->
            <div class="table-container">
                <h3>🔄 Priority Reorder Actions</h3>
                <div class="action-grid">
                    <div class="action-card" onclick="showCriticalItems()">
                        <span class="action-icon">🔴</span>
                        <h3>Critical Items</h3>
                        <p>Out of stock - Immediate action needed</p>
                        <div class="stat-badge" id="critical-badge">0</div>
                    </div>

                    <div class="action-card" onclick="showUrgentItems()">
                        <span class="action-icon">🟠</span>
                        <h3>Urgent Items</h3>
                        <p>Below minimum level - Order soon</p>
                        <div class="stat-badge" id="urgent-badge">0</div>
                    </div>

                    <div class="action-card" onclick="showWarningItems()">
                        <span class="action-icon">🟡</span>
                        <h3>Warning Items</h3>
                        <p>At minimum level - Monitor closely</p>
                        <div class="stat-badge" id="warning-badge">0</div>
                    </div>

                    <div class="action-card" onclick="generateAllReorderReport()">
                        <span class="action-icon">📋</span>
                        <h3>Full Report</h3>
                        <p>Complete reorder analysis</p>
                        <div class="stat-badge" id="total-badge">0</div>
                    </div>
                </div>
            </div>

            <!-- Report Output -->
            <div id="report-output" class="report-output" style="display: none;">
                <div class="section-header">
                    <h3>Reorder Report</h3>
                    <div>
                        <button class="btn btn-secondary" onclick="copyReport()">Copy</button>
                        <button class="btn btn-secondary" onclick="printReport()">Print</button>
                        <button class="btn btn-secondary" onclick="downloadReport()">Download</button>
                        <button class="btn btn-secondary" onclick="hideReport()">Close</button>
                    </div>
                </div>
                <div id="report-content"></div>
            </div>

            <!-- Reorder Items Table -->
            <div class="table-container">
                <h3>Items Needing Reorder</h3>
                <div class="section-header">
                    <div>
                        <button class="btn btn-primary" onclick="addStockForSelected()">
                            Add Stock to Selected
                        </button>
                    </div>
                    <div>
                        <input type="text" id="search-reorder" class="form-control" placeholder="Search items..." style="width: 300px;">
                    </div>
                </div>
                <table class="data-table" id="reorder-table">
                    <thead>
                    <tr>
                        <th><input type="checkbox" id="select-all" onchange="toggleSelectAll()"></th>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Current Stock</th>
                        <th>Min Level</th>
                        <th>Recommended Order</th>
                        <th>Urgency</th>
                        <th>Last Sale</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="reorder-body">
                    <tr><td colspan="9">Loading reorder items...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- Bulk Actions -->
            <div class="table-container" id="bulk-actions" style="display: none;">
                <h3>Bulk Actions</h3>
                <div class="form-group">
                    <label for="bulk-quantity">Quantity to Add (for all selected items)</label>
                    <input type="number" id="bulk-quantity" class="form-control" min="1" value="10">
                </div>
                <button class="btn btn-primary" onclick="addBulkStock()">
                    Add Stock to Selected Items
                </button>
                <button class="btn btn-secondary" onclick="clearSelection()">
                    Clear Selection
                </button>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let reorderItems = [];
    let selectedItems = new Set();

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadReorderReportData();

        // Setup search
        document.getElementById('search-reorder').addEventListener('input', function(e) {
            filterReorderItems(e.target.value);
        });
    });

    async function loadReorderReportData() {
        await loadReorderStatistics();
        await loadReorderItems();
    }

    async function loadReorderStatistics() {
        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                const items = response.data;

                const criticalItems = items.filter(item =>
                    item.quantity === 0 && item.state !== 'DISCONTINUED'
                );
                const urgentItems = items.filter(item =>
                    item.quantity > 0 && item.quantity < item.reorderLevel
                );
                const warningItems = items.filter(item =>
                    item.quantity === item.reorderLevel
                );

                const totalReorderValue = [...criticalItems, ...urgentItems, ...warningItems]
                    .reduce((sum, item) => sum + (item.price * (item.reorderLevel * 2)), 0);

                document.getElementById('critical-count').textContent = criticalItems.length;
                document.getElementById('urgent-count').textContent = urgentItems.length;
                document.getElementById('warning-count').textContent = warningItems.length;
                document.getElementById('reorder-value').textContent = `$${totalReorderValue.toFixed(2)}`;

                // Update badges
                document.getElementById('critical-badge').textContent = criticalItems.length;
                document.getElementById('urgent-badge').textContent = urgentItems.length;
                document.getElementById('warning-badge').textContent = warningItems.length;
                document.getElementById('total-badge').textContent = criticalItems.length + urgentItems.length + warningItems.length;
            }
        } catch (error) {
            console.error('Failed to load reorder statistics:', error);
        }
    }

    async function loadReorderItems() {
        const tbody = document.getElementById('reorder-body');

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                reorderItems = response.data.filter(item =>
                    item.quantity <= item.reorderLevel && item.state !== 'DISCONTINUED'
                );

                displayReorderItems(reorderItems);
            } else {
                tbody.innerHTML = '<tr><td colspan="9" class="text-center">No items need reordering</td></tr>';
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="9" class="text-center">Error loading reorder items: ${error.message}</td></tr>`;
        }
    }

    function displayReorderItems(items) {
        const tbody = document.getElementById('reorder-body');

        if (items.length === 0) {
            tbody.innerHTML = '<tr><td colspan="9" class="text-center">🎉 All items are sufficiently stocked!</td></tr>';
            document.getElementById('bulk-actions').style.display = 'none';
            return;
        }

        tbody.innerHTML = items.map(item => {
            const urgency = getUrgencyLevel(item.quantity, item.reorderLevel);
            const recommendedOrder = Math.max(item.reorderLevel * 2 - item.quantity, 10);
            const lastSale = item.lastSaleDate ? new Date(item.lastSaleDate).toLocaleDateString() : 'No sales';

            return `
                    <tr>
                        <td>
                            <input type="checkbox" class="item-checkbox" value="${item.code}"
                                   onchange="toggleItemSelection('${item.code}')">
                        </td>
                        <td><strong>${item.code}</strong></td>
                        <td>${item.name}</td>
                        <td>${item.quantity}</td>
                        <td>${item.reorderLevel}</td>
                        <td>${recommendedOrder} units</td>
                        <td>${urgency.badge}</td>
                        <td>${lastSale}</td>
                        <td>
                            <button class="btn btn-primary" onclick="addStockForItem('${item.code}')">
                                Add Stock
                            </button>
                        </td>
                    </tr>
                `;
        }).join('');
    }

    function getUrgencyLevel(quantity, reorderLevel) {
        if (quantity === 0) {
            return {
                level: 'critical',
                badge: '<span class="badge badge-danger">Critical</span>',
                description: 'Out of stock'
            };
        } else if (quantity < reorderLevel) {
            return {
                level: 'urgent',
                badge: '<span class="badge badge-warning">Urgent</span>',
                description: 'Below minimum'
            };
        } else if (quantity === reorderLevel) {
            return {
                level: 'warning',
                badge: '<span class="badge badge-info">Warning</span>',
                description: 'At minimum level'
            };
        } else {
            return {
                level: 'normal',
                badge: '<span class="badge badge-success">Normal</span>',
                description: 'Adequate stock'
            };
        }
    }

    async function generateReorderReport() {
        const urgencyLevel = document.getElementById('urgency-level').value;
        const format = document.getElementById('report-format').value;

        showLoading('report-content', `Generating ${urgencyLevel} reorder report...`);
        showReportOutput();

        try {
            const response = await apiRequest(`/reports/reorder?urgency=${urgencyLevel}&format=${format}`);

            if (response) {
                displayReport(response, format);
            }
        } catch (error) {
            document.getElementById('report-content').innerHTML =
                `<div class="alert alert-error">Error generating report: ${error.message}</div>`;
        }
    }

    function generateCriticalReport() {
        document.getElementById('urgency-level').value = 'critical';
        generateReorderReport();
    }

    function generateAllReorderReport() {
        document.getElementById('urgency-level').value = 'all';
        generateReorderReport();
    }

    function showCriticalItems() {
        const criticalItems = reorderItems.filter(item => item.quantity === 0);
        displayReorderItems(criticalItems);
        showAlert('info', `Showing ${criticalItems.length} critical items`);
    }

    function showUrgentItems() {
        const urgentItems = reorderItems.filter(item => item.quantity > 0 && item.quantity < item.reorderLevel);
        displayReorderItems(urgentItems);
        showAlert('info', `Showing ${urgentItems.length} urgent items`);
    }

    function showWarningItems() {
        const warningItems = reorderItems.filter(item => item.quantity === item.reorderLevel);
        displayReorderItems(warningItems);
        showAlert('info', `Showing ${warningItems.length} warning items`);
    }

    function displayReport(content, format) {
        const reportContent = document.getElementById('report-content');

        if (format === 'html') {
            reportContent.innerHTML = content;
        } else if (format === 'csv') {
            reportContent.innerHTML = `<pre>${content}</pre>`;
        } else {
            reportContent.innerHTML = `<pre>${content}</pre>`;
        }
    }

    function filterReorderItems(searchTerm) {
        if (!searchTerm) {
            displayReorderItems(reorderItems);
            return;
        }

        const filtered = reorderItems.filter(item =>
            item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.name.toLowerCase().includes(searchTerm.toLowerCase())
        );

        displayReorderItems(filtered);
    }

    function toggleSelectAll() {
        const selectAll = document.getElementById('select-all');
        const checkboxes = document.querySelectorAll('.item-checkbox');

        checkboxes.forEach(checkbox => {
            checkbox.checked = selectAll.checked;
            if (selectAll.checked) {
                selectedItems.add(checkbox.value);
            } else {
                selectedItems.delete(checkbox.value);
            }
        });

        updateBulkActions();
    }

    function toggleItemSelection(itemCode) {
        const checkbox = document.querySelector(`.item-checkbox[value="${itemCode}"]`);

        if (checkbox.checked) {
            selectedItems.add(itemCode);
        } else {
            selectedItems.delete(itemCode);
        }

        // Update select all checkbox
        const checkboxes = document.querySelectorAll('.item-checkbox');
        const allChecked = Array.from(checkboxes).every(cb => cb.checked);
        document.getElementById('select-all').checked = allChecked;

        updateBulkActions();
    }

    function updateBulkActions() {
        const bulkActions = document.getElementById('bulk-actions');

        if (selectedItems.size > 0) {
            bulkActions.style.display = 'block';
            showAlert('info', `${selectedItems.size} items selected for bulk action`);
        } else {
            bulkActions.style.display = 'none';
        }
    }

    function clearSelection() {
        selectedItems.clear();
        const checkboxes = document.querySelectorAll('.item-checkbox');
        checkboxes.forEach(checkbox => checkbox.checked = false);
        document.getElementById('select-all').checked = false;
        updateBulkActions();
    }

    async function addBulkStock() {
        const quantity = parseInt(document.getElementById('bulk-quantity').value);

        if (isNaN(quantity) || quantity <= 0) {
            showAlert('error', 'Please enter a valid quantity');
            return;
        }

        if (selectedItems.size === 0) {
            showAlert('error', 'No items selected');
            return;
        }

        try {
            const promises = Array.from(selectedItems).map(itemCode =>
                apiRequest('/inventory/add-stock', {
                    method: 'POST',
                    body: JSON.stringify({
                        code: itemCode,
                        quantity: quantity,
                        // We'll use the existing item details
                        name: 'Bulk Restock',
                        price: 0 // This would need to be handled differently in a real scenario
                    })
                })
            );

            const results = await Promise.allSettled(promises);

            let successCount = 0;
            let errorCount = 0;

            results.forEach((result, index) => {
                if (result.status === 'fulfilled' && result.value.success) {
                    successCount++;
                } else {
                    errorCount++;
                }
            });

            showAlert('success', `Successfully added stock to ${successCount} items`);
            if (errorCount > 0) {
                showAlert('error', `Failed to add stock to ${errorCount} items`);
            }

            // Refresh data
            clearSelection();
            loadReorderReportData();
        } catch (error) {
            showAlert('error', `Failed to add bulk stock: ${error.message}`);
        }
    }

    function addStockForSelected() {
        if (selectedItems.size === 0) {
            showAlert('error', 'Please select items first');
            return;
        }

        // Show the bulk actions section if not visible
        document.getElementById('bulk-actions').style.display = 'block';
        document.getElementById('bulk-actions').scrollIntoView({ behavior: 'smooth' });
    }

    function addStockForItem(itemCode) {
        window.location.href = `${pageContext.request.contextPath}/views/inventory/add-stock.jsp?itemCode=${itemCode}`;
    }

    function exportReorderList() {
        const itemsToExport = reorderItems.map(item => {
            const urgency = getUrgencyLevel(item.quantity, item.reorderLevel);
            const recommendedOrder = Math.max(item.reorderLevel * 2 - item.quantity, 10);

            return {
                code: item.code,
                name: item.name,
                currentStock: item.quantity,
                minLevel: item.reorderLevel,
                recommendedOrder: recommendedOrder,
                urgency: urgency.level,
                unitPrice: item.price,
                totalCost: (item.price * recommendedOrder).toFixed(2)
            };
        });

        const headers = ['Item Code', 'Item Name', 'Current Stock', 'Min Level', 'Recommended Order', 'Urgency', 'Unit Price', 'Total Cost'];
        const csvContent = [
            headers.join(','),
            ...itemsToExport.map(item => [
                item.code,
                `"${item.name}"`,
                item.currentStock,
                item.minLevel,
                item.recommendedOrder,
                item.urgency,
                item.unitPrice,
                item.totalCost
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `reorder-list-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);

        showAlert('success', 'Reorder list exported successfully');
    }

    function showLoading(elementId, message) {
        document.getElementById(elementId).innerHTML = `
                <div class="text-center">
                    <p>${message}</p>
                    <div class="spinner" style="margin: 20px auto;"></div>
                </div>
            `;
    }

    function showReportOutput() {
        document.getElementById('report-output').style.display = 'block';
        document.getElementById('report-output').scrollIntoView({ behavior: 'smooth' });
    }

    function hideReport() {
        document.getElementById('report-output').style.display = 'none';
    }

    function copyReport() {
        const reportContent = document.getElementById('report-content').textContent;
        navigator.clipboard.writeText(reportContent).then(() => {
            showAlert('success', 'Report copied to clipboard');
        });
    }

    function printReport() {
        window.print();
    }

    function downloadReport() {
        const reportContent = document.getElementById('report-content').textContent;
        const urgencyLevel = document.getElementById('urgency-level').value;
        const blob = new Blob([reportContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${urgencyLevel}-reorder-report-${new Date().toISOString().split('T')[0]}.txt`;
        a.click();
        window.URL.revokeObjectURL(url);
        showAlert('success', 'Report downloaded successfully');
    }

    // Add some CSS for the stat badges in action cards
    const style = document.createElement('style');
    style.textContent = `
            .stat-badge {
                position: absolute;
                top: 10px;
                right: 10px;
                background: #ef4444;
                color: white;
                border-radius: 50%;
                width: 24px;
                height: 24px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 12px;
                font-weight: bold;
            }
            .action-card {
                position: relative;
            }
        `;
    document.head.appendChild(style);
</script>
</body>
</html>