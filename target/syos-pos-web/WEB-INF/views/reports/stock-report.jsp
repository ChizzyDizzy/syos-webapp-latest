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
    <title>SYOS POS - Stock Report</title>
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

            <a href="${pageContext.request.contextPath}/views/reports/stock-report.jsp" class="nav-link active">
                <span class="nav-icon">📦</span>
                <span>Stock Report</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/reorder-report.jsp" class="nav-link">
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
            <h1>Stock Report</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Report Controls -->
            <div class="table-container">
                <h2>Generate Stock Report</h2>

                <div class="form-group">
                    <label for="report-type">Report Type</label>
                    <select id="report-type" class="form-control">
                        <option value="full">Full Inventory Report</option>
                        <option value="low-stock">Low Stock Only</option>
                        <option value="expiring">Expiring Soon</option>
                        <option value="on-shelf">On Shelf Items</option>
                        <option value="in-store">In Store Items</option>
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
                    <button class="btn btn-primary" onclick="generateStockReport()">
                        Generate Report
                    </button>
                    <button class="btn btn-secondary" onclick="exportToExcel()">
                        Export to Excel
                    </button>
                    <button class="btn btn-secondary" onclick="refreshStockData()">
                        Refresh Data
                    </button>
                </div>
            </div>

            <!-- Stock Summary -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Items</h3>
                    <p class="stat-value" id="total-items">0</p>
                    <p class="stat-label">In Inventory</p>
                </div>
                <div class="stat-card">
                    <h3>Total Value</h3>
                    <p class="stat-value" id="total-value">$0.00</p>
                    <p class="stat-label">Stock Value</p>
                </div>
                <div class="stat-card">
                    <h3>Low Stock</h3>
                    <p class="stat-value" id="low-stock-count">0</p>
                    <p class="stat-label">Need Reorder</p>
                </div>
                <div class="stat-card">
                    <h3>Expiring Soon</h3>
                    <p class="stat-value" id="expiring-count">0</p>
                    <p class="stat-label">Within 7 Days</p>
                </div>
            </div>

            <!-- Quick Stock Overview -->
            <div class="table-container">
                <h3>Quick Stock Overview</h3>
                <table class="data-table" id="quick-stock-table">
                    <thead>
                    <tr>
                        <th>Category</th>
                        <th>Count</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                    </thead>
                    <tbody id="quick-stock-body">
                    <tr><td colspan="4">Loading stock data...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- Report Output -->
            <div id="report-output" class="report-output" style="display: none;">
                <div class="section-header">
                    <h3>Stock Report</h3>
                    <div>
                        <button class="btn btn-secondary" onclick="copyReport()">Copy</button>
                        <button class="btn btn-secondary" onclick="printReport()">Print</button>
                        <button class="btn btn-secondary" onclick="downloadReport()">Download</button>
                        <button class="btn btn-secondary" onclick="hideReport()">Close</button>
                    </div>
                </div>
                <div id="report-content"></div>
            </div>

            <!-- Detailed Stock Table -->
            <div class="table-container">
                <h3>Detailed Inventory</h3>
                <div class="section-header">
                    <div></div>
                    <div>
                        <input type="text" id="search-stock" class="form-control" placeholder="Search items..." style="width: 300px;">
                    </div>
                </div>
                <table class="data-table" id="detailed-stock-table">
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Price</th>
                        <th>Quantity</th>
                        <th>State</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Value</th>
                        <th>Status</th>
                    </tr>
                    </thead>
                    <tbody id="detailed-stock-body">
                    <tr><td colspan="9">Loading detailed inventory...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let allStockItems = [];

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadStockData();

        // Setup search
        document.getElementById('search-stock').addEventListener('input', function(e) {
            filterStockItems(e.target.value);
        });
    });

    async function loadStockData() {
        await loadStockSummary();
        await loadQuickStockOverview();
        await loadDetailedStock();
    }

    async function loadStockSummary() {
        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                allStockItems = response.data;

                const totalItems = allStockItems.length;
                const totalValue = allStockItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
                const lowStockCount = allStockItems.filter(item =>
                    item.quantity <= item.reorderLevel && item.state !== 'SOLD_OUT'
                ).length;
                const expiringCount = allStockItems.filter(item =>
                    item.expiryDate && item.daysUntilExpiry <= 7 && item.daysUntilExpiry > 0
                ).length;

                document.getElementById('total-items').textContent = totalItems;
                document.getElementById('total-value').textContent = `$${totalValue.toFixed(2)}`;
                document.getElementById('low-stock-count').textContent = lowStockCount;
                document.getElementById('expiring-count').textContent = expiringCount;
            }
        } catch (error) {
            console.error('Failed to load stock summary:', error);
        }
    }

    async function loadQuickStockOverview() {
        const tbody = document.getElementById('quick-stock-body');

        try {
            const categories = [
                { name: 'On Shelf Items', filter: item => item.state === 'ON_SHELF', class: 'success' },
                { name: 'In Store Items', filter: item => item.state === 'IN_STORE', class: 'info' },
                { name: 'Low Stock Items', filter: item => item.quantity <= item.reorderLevel && item.state !== 'SOLD_OUT', class: 'warning' },
                { name: 'Expired Items', filter: item => item.state === 'EXPIRED', class: 'danger' },
                { name: 'Sold Out Items', filter: item => item.state === 'SOLD_OUT', class: 'secondary' }
            ];

            tbody.innerHTML = categories.map(category => {
                const count = allStockItems.filter(category.filter).length;
                const status = count > 0 ?
                    `<span class="badge badge-${category.class}">${count} items</span>` :
                    `<span class="badge badge-success">No items</span>`;

                return `
                        <tr>
                            <td><strong>${category.name}</strong></td>
                            <td>${count}</td>
                            <td>${status}</td>
                            <td>
                                <button class="btn btn-secondary" onclick="filterByCategory('${category.name}')">
                                    View
                                </button>
                            </td>
                        </tr>
                    `;
            }).join('');
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="4" class="text-center">Error loading stock overview: ${error.message}</td></tr>`;
        }
    }

    async function loadDetailedStock() {
        const tbody = document.getElementById('detailed-stock-body');

        try {
            if (allStockItems.length === 0) {
                tbody.innerHTML = '<tr><td colspan="9" class="text-center">No inventory items found</td></tr>';
                return;
            }

            displayStockItems(allStockItems);
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="9" class="text-center">Error loading detailed stock: ${error.message}</td></tr>`;
        }
    }

    function displayStockItems(items) {
        const tbody = document.getElementById('detailed-stock-body');

        tbody.innerHTML = items.map(item => {
            const stateBadge = getStateBadge(item.state);
            const expiryInfo = item.expiryDate ?
                `<td>${item.expiryDate}</td><td>${item.daysUntilExpiry || 'N/A'}</td>` :
                '<td>N/A</td><td>N/A</td>';

            const stockValue = (item.price * item.quantity).toFixed(2);
            const stockStatus = getStockStatus(item.quantity, item.reorderLevel, item.state);

            return `
                    <tr>
                        <td><strong>${item.code}</strong></td>
                        <td>${item.name}</td>
                        <td>$${item.price.toFixed(2)}</td>
                        <td><span class="${stockStatus.class}">${item.quantity}</span></td>
                        <td>${stateBadge}</td>
                        ${expiryInfo}
                        <td>$${stockValue}</td>
                        <td>${stockStatus.badge}</td>
                    </tr>
                `;
        }).join('');
    }

    function getStateBadge(state) {
        const badges = {
            'IN_STORE': '<span class="badge badge-info">In Store</span>',
            'ON_SHELF': '<span class="badge badge-success">On Shelf</span>',
            'EXPIRED': '<span class="badge badge-danger">Expired</span>',
            'SOLD_OUT': '<span class="badge badge-warning">Sold Out</span>'
        };
        return badges[state] || '<span class="badge badge-secondary">' + state + '</span>';
    }

    function getStockStatus(quantity, reorderLevel, state) {
        if (state === 'EXPIRED') {
            return { class: 'text-danger', badge: '<span class="badge badge-danger">Expired</span>' };
        } else if (state === 'SOLD_OUT') {
            return { class: 'text-warning', badge: '<span class="badge badge-warning">Sold Out</span>' };
        } else if (quantity === 0) {
            return { class: 'text-danger', badge: '<span class="badge badge-danger">Out of Stock</span>' };
        } else if (quantity <= reorderLevel) {
            return { class: 'text-warning', badge: '<span class="badge badge-warning">Low Stock</span>' };
        } else {
            return { class: 'text-success', badge: '<span class="badge badge-success">In Stock</span>' };
        }
    }

    async function generateStockReport() {
        const reportType = document.getElementById('report-type').value;
        const format = document.getElementById('report-format').value;

        showLoading('report-content', `Generating ${reportType} stock report...`);
        showReportOutput();

        try {
            const response = await apiRequest(`/reports/stock?type=${reportType}&format=${format}`);

            if (response) {
                displayReport(response, format);
            }
        } catch (error) {
            document.getElementById('report-content').innerHTML =
                `<div class="alert alert-error">Error generating report: ${error.message}</div>`;
        }
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

    function filterByCategory(categoryName) {
        let filteredItems = [];

        switch(categoryName) {
            case 'On Shelf Items':
                filteredItems = allStockItems.filter(item => item.state === 'ON_SHELF');
                break;
            case 'In Store Items':
                filteredItems = allStockItems.filter(item => item.state === 'IN_STORE');
                break;
            case 'Low Stock Items':
                filteredItems = allStockItems.filter(item =>
                    item.quantity <= item.reorderLevel && item.state !== 'SOLD_OUT');
                break;
            case 'Expired Items':
                filteredItems = allStockItems.filter(item => item.state === 'EXPIRED');
                break;
            case 'Sold Out Items':
                filteredItems = allStockItems.filter(item => item.state === 'SOLD_OUT');
                break;
            default:
                filteredItems = allStockItems;
        }

        displayStockItems(filteredItems);
        showAlert('info', `Showing ${filteredItems.length} ${categoryName.toLowerCase()}`);
    }

    function filterStockItems(searchTerm) {
        if (!searchTerm) {
            displayStockItems(allStockItems);
            return;
        }

        const filtered = allStockItems.filter(item =>
            item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.name.toLowerCase().includes(searchTerm.toLowerCase())
        );

        displayStockItems(filtered);
    }

    function refreshStockData() {
        loadStockData();
        showAlert('success', 'Stock data refreshed');
    }

    function exportToExcel() {
        // Simple CSV export
        const headers = ['Code', 'Name', 'Price', 'Quantity', 'State', 'Expiry Date', 'Days Left', 'Stock Value'];
        const csvContent = [
            headers.join(','),
            ...allStockItems.map(item => [
                item.code,
                `"${item.name}"`,
                item.price,
                item.quantity,
                item.state,
                item.expiryDate || 'N/A',
                item.daysUntilExpiry || 'N/A',
                (item.price * item.quantity).toFixed(2)
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `stock-report-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);

        showAlert('success', 'Stock report exported to CSV');
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
        const reportType = document.getElementById('report-type').value;
        const blob = new Blob([reportContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${reportType}-stock-report-${new Date().toISOString().split('T')[0]}.txt`;
        a.click();
        window.URL.revokeObjectURL(url);
        showAlert('success', 'Report downloaded successfully');
    }
</script>
</body>
</html>