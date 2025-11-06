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
    <title>SYOS POS - Reshelve Report</title>
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

            <a href="${pageContext.request.contextPath}/views/reports/reorder-report.jsp" class="nav-link">
                <span class="nav-icon">🔄</span>
                <span>Reorder Report</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/reshelve-report.jsp" class="nav-link active">
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
            <h1>Reshelve Report</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Report Controls -->
            <div class="table-container">
                <h2>Generate Reshelve Report</h2>
                <p class="text-muted">Items that are expiring soon and need to be moved to shelf or discounted.</p>

                <div class="form-group">
                    <label for="days-threshold">Days Until Expiry</label>
                    <select id="days-threshold" class="form-control">
                        <option value="3">Critical (≤ 3 days)</option>
                        <option value="7" selected>Urgent (≤ 7 days)</option>
                        <option value="14">Warning (≤ 14 days)</option>
                        <option value="30">All Expiring (≤ 30 days)</option>
                    </select>
                </div>

                <div class="form-group">
                    <label for="item-status">Item Status</label>
                    <select id="item-status" class="form-control">
                        <option value="all">All Items</option>
                        <option value="in_store">In Store Only</option>
                        <option value="on_shelf">On Shelf Only</option>
                        <option value="both">Both Store & Shelf</option>
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
                    <button class="btn btn-primary" onclick="generateReshelveReport()">
                        Generate Report
                    </button>
                    <button class="btn btn-danger" onclick="generateCriticalReport()">
                        Critical Items Only
                    </button>
                    <button class="btn btn-secondary" onclick="exportReshelvePlan()">
                        Export Action Plan
                    </button>
                </div>
            </div>

            <!-- Expiry Statistics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Critical Items</h3>
                    <p class="stat-value" id="critical-count">0</p>
                    <p class="stat-label">≤ 3 days</p>
                </div>
                <div class="stat-card">
                    <h3>Urgent Items</h3>
                    <p class="stat-value" id="urgent-count">0</p>
                    <p class="stat-label">4-7 days</p>
                </div>
                <div class="stat-card">
                    <h3>Warning Items</h3>
                    <p class="stat-value" id="warning-count">0</p>
                    <p class="stat-label">8-14 days</p>
                </div>
                <div class="stat-card">
                    <h3>Total Value</h3>
                    <p class="stat-value" id="expiry-value">$0.00</p>
                    <p class="stat-label">At Risk</p>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="table-container">
                <h3>🚨 Immediate Actions Required</h3>
                <div class="action-grid">
                    <div class="action-card critical" onclick="showCriticalItems()">
                        <span class="action-icon">🔴</span>
                        <h3>Critical Priority</h3>
                        <p>Items expiring in 3 days or less</p>
                        <div class="action-stats">
                            <span class="stat" id="critical-action-count">0 items</span>
                            <span class="value" id="critical-action-value">$0.00</span>
                        </div>
                        <button class="btn btn-danger">View Critical</button>
                    </div>

                    <div class="action-card urgent" onclick="showUrgentItems()">
                        <span class="action-icon">🟠</span>
                        <h3>Urgent Priority</h3>
                        <p>Items expiring in 4-7 days</p>
                        <div class="action-stats">
                            <span class="stat" id="urgent-action-count">0 items</span>
                            <span class="value" id="urgent-action-value">$0.00</span>
                        </div>
                        <button class="btn btn-warning">View Urgent</button>
                    </div>

                    <div class="action-card warning" onclick="showWarningItems()">
                        <span class="action-icon">🟡</span>
                        <h3>Warning Priority</h3>
                        <p>Items expiring in 8-14 days</p>
                        <div class="action-stats">
                            <span class="stat" id="warning-action-count">0 items</span>
                            <span class="value" id="warning-action-value">$0.00</span>
                        </div>
                        <button class="btn btn-info">View Warning</button>
                    </div>

                    <div class="action-card normal" onclick="generateFullReport()">
                        <span class="action-icon">📊</span>
                        <h3>Complete Report</h3>
                        <p>All expiring items analysis</p>
                        <div class="action-stats">
                            <span class="stat" id="total-action-count">0 items</span>
                            <span class="value" id="total-action-value">$0.00</span>
                        </div>
                        <button class="btn btn-secondary">Full Report</button>
                    </div>
                </div>
            </div>

            <!-- Report Output -->
            <div id="report-output" class="report-output" style="display: none;">
                <div class="section-header">
                    <h3>Reshelve Report</h3>
                    <div>
                        <button class="btn btn-secondary" onclick="copyReport()">Copy</button>
                        <button class="btn btn-secondary" onclick="printReport()">Print</button>
                        <button class="btn btn-secondary" onclick="downloadReport()">Download</button>
                        <button class="btn btn-secondary" onclick="hideReport()">Close</button>
                    </div>
                </div>
                <div id="report-content"></div>
            </div>

            <!-- Expiring Items Table -->
            <div class="table-container">
                <h3>Expiring Items Requiring Action</h3>
                <div class="section-header">
                    <div>
                        <button class="btn btn-primary" onclick="moveSelectedToShelf()">
                            Move Selected to Shelf
                        </button>
                        <button class="btn btn-warning" onclick="applyDiscountToSelected()">
                            Apply Discount to Selected
                        </button>
                    </div>
                    <div>
                        <input type="text" id="search-expiring" class="form-control" placeholder="Search items..." style="width: 300px;">
                    </div>
                </div>
                <table class="data-table" id="expiring-table">
                    <thead>
                    <tr>
                        <th><input type="checkbox" id="select-all-expiring" onchange="toggleSelectAllExpiring()"></th>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Quantity</th>
                        <th>Location</th>
                        <th>Stock Value</th>
                        <th>Priority</th>
                        <th>Recommended Action</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="expiring-body">
                    <tr><td colspan="11">Loading expiring items...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- Bulk Actions Panel -->
            <div class="table-container" id="bulk-actions-panel" style="display: none;">
                <h3>Bulk Actions for Selected Items</h3>
                <div class="form-group">
                    <label for="bulk-action">Select Action</label>
                    <select id="bulk-action" class="form-control">
                        <option value="move_to_shelf">Move to Shelf</option>
                        <option value="apply_discount">Apply Discount</option>
                        <option value="mark_discounted">Mark as Discounted</option>
                    </select>
                </div>

                <div id="discount-options" style="display: none;">
                    <div class="form-group">
                        <label for="discount-percentage">Discount Percentage</label>
                        <input type="number" id="discount-percentage" class="form-control" min="1" max="100" value="20" placeholder="Enter discount %">
                    </div>
                </div>

                <div class="form-group">
                    <button class="btn btn-primary" onclick="executeBulkAction()">
                        Execute Bulk Action
                    </button>
                    <button class="btn btn-secondary" onclick="clearExpiringSelection()">
                        Clear Selection
                    </button>
                </div>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let expiringItems = [];
    let selectedExpiringItems = new Set();

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadReshelveReportData();

        // Setup search
        document.getElementById('search-expiring').addEventListener('input', function(e) {
            filterExpiringItems(e.target.value);
        });

        // Show/hide discount options
        document.getElementById('bulk-action').addEventListener('change', function() {
            const discountOptions = document.getElementById('discount-options');
            discountOptions.style.display = this.value === 'apply_discount' ? 'block' : 'none';
        });
    });

    async function loadReshelveReportData() {
        await loadExpiryStatistics();
        await loadExpiringItems();
    }

    async function loadExpiryStatistics() {
        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                const items = response.data.filter(item => item.expiryDate);

                const criticalItems = items.filter(item =>
                    item.daysUntilExpiry <= 3 && item.daysUntilExpiry > 0
                );
                const urgentItems = items.filter(item =>
                    item.daysUntilExpiry > 3 && item.daysUntilExpiry <= 7
                );
                const warningItems = items.filter(item =>
                    item.daysUntilExpiry > 7 && item.daysUntilExpiry <= 14
                );
                const allExpiring = items.filter(item => item.daysUntilExpiry > 0);

                const criticalValue = criticalItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
                const urgentValue = urgentItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
                const warningValue = warningItems.reduce((sum, item) => sum + (item.price * item.quantity), 0);
                const totalValue = allExpiring.reduce((sum, item) => sum + (item.price * item.quantity), 0);

                // Update statistics
                document.getElementById('critical-count').textContent = criticalItems.length;
                document.getElementById('urgent-count').textContent = urgentItems.length;
                document.getElementById('warning-count').textContent = warningItems.length;
                document.getElementById('expiry-value').textContent = `$${totalValue.toFixed(2)}`;

                // Update action cards
                document.getElementById('critical-action-count').textContent = `${criticalItems.length} items`;
                document.getElementById('critical-action-value').textContent = `$${criticalValue.toFixed(2)}`;

                document.getElementById('urgent-action-count').textContent = `${urgentItems.length} items`;
                document.getElementById('urgent-action-value').textContent = `$${urgentValue.toFixed(2)}`;

                document.getElementById('warning-action-count').textContent = `${warningItems.length} items`;
                document.getElementById('warning-action-value').textContent = `$${warningValue.toFixed(2)}`;

                document.getElementById('total-action-count').textContent = `${allExpiring.length} items`;
                document.getElementById('total-action-value').textContent = `$${totalValue.toFixed(2)}`;
            }
        } catch (error) {
            console.error('Failed to load expiry statistics:', error);
        }
    }

    async function loadExpiringItems() {
        const tbody = document.getElementById('expiring-body');

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                expiringItems = response.data.filter(item =>
                    item.expiryDate && item.daysUntilExpiry > 0 && item.daysUntilExpiry <= 30
                ).sort((a, b) => a.daysUntilExpiry - b.daysUntilExpiry);

                displayExpiringItems(expiringItems);
            } else {
                tbody.innerHTML = '<tr><td colspan="11" class="text-center">🎉 No items expiring soon!</td></tr>';
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="11" class="text-center">Error loading expiring items: ${error.message}</td></tr>`;
        }
    }

    function displayExpiringItems(items) {
        const tbody = document.getElementById('expiring-body');

        if (items.length === 0) {
            tbody.innerHTML = '<tr><td colspan="11" class="text-center">🎉 No items expiring in the next 30 days!</td></tr>';
            document.getElementById('bulk-actions-panel').style.display = 'none';
            return;
        }

        tbody.innerHTML = items.map(item => {
            const priority = getExpiryPriority(item.daysUntilExpiry);
            const recommendedAction = getRecommendedAction(item, priority);
            const stockValue = (item.price * item.quantity).toFixed(2);
            const location = item.state === 'ON_SHELF' ?
                '<span class="badge badge-success">On Shelf</span>' :
                '<span class="badge badge-info">In Store</span>';

            return `
                    <tr>
                        <td>
                            <input type="checkbox" class="expiring-checkbox" value="${item.code}"
                                   onchange="toggleExpiringSelection('${item.code}')">
                        </td>
                        <td><strong>${item.code}</strong></td>
                        <td>${item.name}</td>
                        <td>${item.expiryDate}</td>
                        <td>${priority.badge}</td>
                        <td>${item.quantity}</td>
                        <td>${location}</td>
                        <td>$${stockValue}</td>
                        <td>${priority.level}</td>
                        <td>${recommendedAction}</td>
                        <td>
                            <button class="btn btn-primary" onclick="moveToShelf('${item.code}')">
                                Move to Shelf
                            </button>
                        </td>
                    </tr>
                `;
        }).join('');
    }

    function getExpiryPriority(daysUntilExpiry) {
        if (daysUntilExpiry <= 3) {
            return {
                level: 'CRITICAL',
                badge: `<span class="badge badge-danger">${daysUntilExpiry} days</span>`,
                color: 'danger'
            };
        } else if (daysUntilExpiry <= 7) {
            return {
                level: 'URGENT',
                badge: `<span class="badge badge-warning">${daysUntilExpiry} days</span>`,
                color: 'warning'
            };
        } else if (daysUntilExpiry <= 14) {
            return {
                level: 'WARNING',
                badge: `<span class="badge badge-info">${daysUntilExpiry} days</span>`,
                color: 'info'
            };
        } else {
            return {
                level: 'NORMAL',
                badge: `<span class="badge badge-success">${daysUntilExpiry} days</span>`,
                color: 'success'
            };
        }
    }

    function getRecommendedAction(item, priority) {
        if (priority.level === 'CRITICAL') {
            if (item.state === 'IN_STORE') {
                return '<span class="badge badge-danger">MOVE TO SHELF + DISCOUNT</span>';
            } else {
                return '<span class="badge badge-danger">APPLY DISCOUNT NOW</span>';
            }
        } else if (priority.level === 'URGENT') {
            if (item.state === 'IN_STORE') {
                return '<span class="badge badge-warning">MOVE TO SHELF</span>';
            } else {
                return '<span class="badge badge-warning">PREPARE DISCOUNT</span>';
            }
        } else {
            if (item.state === 'IN_STORE') {
                return '<span class="badge badge-info">MOVE TO SHELF SOON</span>';
            } else {
                return '<span class="badge badge-success">MONITOR</span>';
            }
        }
    }

    async function generateReshelveReport() {
        const daysThreshold = document.getElementById('days-threshold').value;
        const itemStatus = document.getElementById('item-status').value;
        const format = document.getElementById('report-format').value;

        showLoading('report-content', `Generating reshelve report...`);
        showReportOutput();

        try {
            const response = await apiRequest(`/reports/reshelve?days=${daysThreshold}&status=${itemStatus}&format=${format}`);

            if (response) {
                displayReport(response, format);
            }
        } catch (error) {
            document.getElementById('report-content').innerHTML =
                `<div class="alert alert-error">Error generating report: ${error.message}</div>`;
        }
    }

    function generateCriticalReport() {
        document.getElementById('days-threshold').value = '3';
        generateReshelveReport();
    }

    function generateFullReport() {
        document.getElementById('days-threshold').value = '30';
        generateReshelveReport();
    }

    function showCriticalItems() {
        const criticalItems = expiringItems.filter(item => item.daysUntilExpiry <= 3);
        displayExpiringItems(criticalItems);
        showAlert('error', `Showing ${criticalItems.length} critical items expiring within 3 days`);
    }

    function showUrgentItems() {
        const urgentItems = expiringItems.filter(item => item.daysUntilExpiry > 3 && item.daysUntilExpiry <= 7);
        displayExpiringItems(urgentItems);
        showAlert('warning', `Showing ${urgentItems.length} urgent items expiring in 4-7 days`);
    }

    function showWarningItems() {
        const warningItems = expiringItems.filter(item => item.daysUntilExpiry > 7 && item.daysUntilExpiry <= 14);
        displayExpiringItems(warningItems);
        showAlert('info', `Showing ${warningItems.length} warning items expiring in 8-14 days`);
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

    function filterExpiringItems(searchTerm) {
        if (!searchTerm) {
            displayExpiringItems(expiringItems);
            return;
        }

        const filtered = expiringItems.filter(item =>
            item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.name.toLowerCase().includes(searchTerm.toLowerCase())
        );

        displayExpiringItems(filtered);
    }

    function toggleSelectAllExpiring() {
        const selectAll = document.getElementById('select-all-expiring');
        const checkboxes = document.querySelectorAll('.expiring-checkbox');

        checkboxes.forEach(checkbox => {
            checkbox.checked = selectAll.checked;
            if (selectAll.checked) {
                selectedExpiringItems.add(checkbox.value);
            } else {
                selectedExpiringItems.delete(checkbox.value);
            }
        });

        updateBulkActionsPanel();
    }

    function toggleExpiringSelection(itemCode) {
        const checkbox = document.querySelector(`.expiring-checkbox[value="${itemCode}"]`);

        if (checkbox.checked) {
            selectedExpiringItems.add(itemCode);
        } else {
            selectedExpiringItems.delete(itemCode);
        }

        // Update select all checkbox
        const checkboxes = document.querySelectorAll('.expiring-checkbox');
        const allChecked = Array.from(checkboxes).every(cb => cb.checked);
        document.getElementById('select-all-expiring').checked = allChecked;

        updateBulkActionsPanel();
    }

    function updateBulkActionsPanel() {
        const bulkPanel = document.getElementById('bulk-actions-panel');

        if (selectedExpiringItems.size > 0) {
            bulkPanel.style.display = 'block';
            showAlert('info', `${selectedExpiringItems.size} expiring items selected for bulk action`);
        } else {
            bulkPanel.style.display = 'none';
        }
    }

    function clearExpiringSelection() {
        selectedExpiringItems.clear();
        const checkboxes = document.querySelectorAll('.expiring-checkbox');
        checkboxes.forEach(checkbox => checkbox.checked = false);
        document.getElementById('select-all-expiring').checked = false;
        updateBulkActionsPanel();
    }

    async function moveSelectedToShelf() {
        if (selectedExpiringItems.size === 0) {
            showAlert('error', 'Please select items first');
            return;
        }

        try {
            const promises = Array.from(selectedExpiringItems).map(itemCode => {
                const item = expiringItems.find(i => i.code === itemCode);
                return apiRequest('/inventory/move-to-shelf', {
                    method: 'POST',
                    body: JSON.stringify({
                        itemCode: itemCode,
                        quantity: item.quantity
                    })
                });
            });

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

            showAlert('success', `Successfully moved ${successCount} items to shelf`);
            if (errorCount > 0) {
                showAlert('error', `Failed to move ${errorCount} items`);
            }

            // Refresh data
            clearExpiringSelection();
            loadReshelveReportData();
        } catch (error) {
            showAlert('error', `Failed to move items: ${error.message}`);
        }
    }

    async function applyDiscountToSelected() {
        if (selectedExpiringItems.size === 0) {
            showAlert('error', 'Please select items first');
            return;
        }

        // This would typically integrate with your pricing system
        showAlert('info', 'Discount application would be implemented here. Selected items: ' + Array.from(selectedExpiringItems).join(', '));
    }

    async function executeBulkAction() {
        const action = document.getElementById('bulk-action').value;

        if (selectedExpiringItems.size === 0) {
            showAlert('error', 'Please select items first');
            return;
        }

        try {
            if (action === 'move_to_shelf') {
                await moveSelectedToShelf();
            } else if (action === 'apply_discount') {
                const discount = document.getElementById('discount-percentage').value;
                await applyDiscountToSelected();
            } else if (action === 'mark_discounted') {
                // Mark items as discounted in the system
                showAlert('info', 'Marking selected items as discounted');
            }
        } catch (error) {
            showAlert('error', `Failed to execute bulk action: ${error.message}`);
        }
    }

    async function moveToShelf(itemCode) {
        try {
            const item = expiringItems.find(i => i.code === itemCode);
            const response = await apiRequest('/inventory/move-to-shelf', {
                method: 'POST',
                body: JSON.stringify({
                    itemCode: itemCode,
                    quantity: item.quantity
                })
            });

            if (response.success) {
                showAlert('success', `Moved ${item.quantity} units of ${itemCode} to shelf`);
                loadReshelveReportData();
            }
        } catch (error) {
            showAlert('error', `Failed to move item: ${error.message}`);
        }
    }

    function exportReshelvePlan() {
        const actionPlan = expiringItems.map(item => {
            const priority = getExpiryPriority(item.daysUntilExpiry);
            const action = getRecommendedAction(item, priority);

            return {
                code: item.code,
                name: item.name,
                expiryDate: item.expiryDate,
                daysLeft: item.daysUntilExpiry,
                quantity: item.quantity,
                location: item.state,
                priority: priority.level,
                recommendedAction: action.replace(/<[^>]*>/g, ''), // Remove HTML tags
                stockValue: (item.price * item.quantity).toFixed(2)
            };
        });

        const headers = ['Item Code', 'Item Name', 'Expiry Date', 'Days Left', 'Quantity', 'Location', 'Priority', 'Recommended Action', 'Stock Value'];
        const csvContent = [
            headers.join(','),
            ...actionPlan.map(item => [
                item.code,
                `"${item.name}"`,
                item.expiryDate,
                item.daysLeft,
                item.quantity,
                item.location,
                item.priority,
                `"${item.recommendedAction}"`,
                item.stockValue
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `reshelve-action-plan-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);

        showAlert('success', 'Reshelve action plan exported successfully');
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
        const daysThreshold = document.getElementById('days-threshold').value;
        const blob = new Blob([reportContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `reshelve-report-${daysThreshold}days-${new Date().toISOString().split('T')[0]}.txt`;
        a.click();
        window.URL.revokeObjectURL(url);
        showAlert('success', 'Report downloaded successfully');
    }

    // Add custom CSS for action cards
    const style = document.createElement('style');
    style.textContent = `
            .action-stats {
                margin: 10px 0;
                display: flex;
                justify-content: space-between;
                font-size: 0.9rem;
            }
            .action-stats .stat {
                font-weight: 600;
            }
            .action-stats .value {
                color: var(--success-color);
                font-weight: 600;
            }
            .action-card.critical {
                border-left: 4px solid #ef4444;
            }
            .action-card.urgent {
                border-left: 4px solid #f59e0b;
            }
            .action-card.warning {
                border-left: 4px solid #3b82f6;
            }
            .action-card.normal {
                border-left: 4px solid #64748b;
            }
        `;
    document.head.appendChild(style);
</script>
</body>
</html>