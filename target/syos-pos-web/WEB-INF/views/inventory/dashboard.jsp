<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="com.syos.domain.entities.User" %>
<%@ page import="com.syos.domain.valueobjects.UserRole" %>
<%
    User currentUser = (User) session.getAttribute("user");
    if (currentUser == null) {
        response.sendRedirect(request.getContextPath() + "/views/auth/login.jsp");
        return;
    }
    String username = currentUser.getUsername();
    UserRole role = currentUser.getRole();

    // Only managers and admins can access inventory
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
    <title>SYOS POS - Inventory Dashboard</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/styles.css">
</head>
<body>
<div class="dashboard-container">
    <!-- Sidebar Navigation -->
    <aside class="sidebar">
        <div class="sidebar-header">
            <h2>🏪 SYOS POS</h2>
            <div class="user-info">
                <p class="user-name"><%= username %></p>
                <p class="user-role"><%= role %></p>
            </div>
        </div>

        <nav class="sidebar-nav">
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="nav-link">
                <span class="nav-icon">💰</span>
                <span>Sales</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link active">
                <span class="nav-icon">📦</span>
                <span>Inventory Dashboard</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="nav-link">
                <span class="nav-icon">📋</span>
                <span>All Items</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/add-stock.jsp" class="nav-link">
                <span class="nav-icon">➕</span>
                <span>Add Stock</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/move-to-shelf.jsp" class="nav-link">
                <span class="nav-icon">🔄</span>
                <span>Move to Shelf</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📈</span>
                <span>Reports</span>
            </a>

            <% if (role == UserRole.ADMIN) { %>
            <a href="${pageContext.request.contextPath}/views/user/management.jsp" class="nav-link">
                <span class="nav-icon">👥</span>
                <span>User Management</span>
            </a>
            <% } %>
        </nav>

        <div class="sidebar-footer">
            <a href="${pageContext.request.contextPath}/views/user/profile.jsp" class="btn btn-secondary btn-block">
                <span>👤 Profile</span>
            </a>
            <button id="logout-btn" class="btn btn-danger btn-block">
                <span>🚪 Logout</span>
            </button>
        </div>
    </aside>

    <!-- Main Content Area -->
    <main class="main-content">
        <header class="content-header">
            <h1>Inventory Dashboard</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Inventory Stats -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Total Items</h3>
                    <p class="stat-value" id="total-items">0</p>
                    <p class="stat-label">In Inventory</p>
                </div>
                <div class="stat-card">
                    <h3>Low Stock</h3>
                    <p class="stat-value" id="low-stock">0</p>
                    <p class="stat-label">Need Reorder</p>
                </div>
                <div class="stat-card">
                    <h3>Expiring Soon</h3>
                    <p class="stat-value" id="expiring-soon">0</p>
                    <p class="stat-label">Within 7 Days</p>
                </div>
                <div class="stat-card">
                    <h3>On Shelf</h3>
                    <p class="stat-value" id="on-shelf">0</p>
                    <p class="stat-label">Available for Sale</p>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <h2>Quick Actions</h2>
                <div class="action-grid">
                    <a href="${pageContext.request.contextPath}/views/inventory/add-stock.jsp" class="action-card">
                        <span class="action-icon">➕</span>
                        <h3>Add Stock</h3>
                        <p>Add new items to inventory</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/inventory/move-to-shelf.jsp" class="action-card">
                        <span class="action-icon">🔄</span>
                        <h3>Move to Shelf</h3>
                        <p>Make items available for sale</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="action-card">
                        <span class="action-icon">📋</span>
                        <h3>View All Items</h3>
                        <p>Browse complete inventory</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/reports/stock-report.jsp" class="action-card">
                        <span class="action-icon">📈</span>
                        <h3>Stock Report</h3>
                        <p>Generate inventory reports</p>
                    </a>
                </div>
            </div>

            <!-- Low Stock Alert -->
            <div class="table-container">
                <h3>⚠️ Low Stock Items (Need Reorder)</h3>
                <table class="data-table" id="low-stock-table">
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Current Stock</th>
                        <th>Min Level</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                    </thead>
                    <tbody id="low-stock-body">
                    <tr><td colspan="6">Loading...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- Expiring Soon -->
            <div class="table-container">
                <h3>📅 Items Expiring Soon</h3>
                <table class="data-table" id="expiring-table">
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Quantity</th>
                        <th>Action</th>
                    </tr>
                    </thead>
                    <tbody id="expiring-body">
                    <tr><td colspan="6">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadInventoryDashboardData();
    });

    async function loadInventoryDashboardData() {
        try {
            // Load inventory statistics
            const stats = await apiRequest('/inventory/statistics');
            if (stats.success && stats.data) {
                document.getElementById('total-items').textContent = stats.data.totalItems;
                document.getElementById('low-stock').textContent = stats.data.lowStockCount;
                document.getElementById('expiring-soon').textContent = stats.data.expiringCount;
                document.getElementById('on-shelf').textContent = stats.data.onShelfCount;
            }

            // Load low stock items
            await loadLowStockItems();

            // Load expiring items
            await loadExpiringItems();
        } catch (error) {
            console.error('Failed to load inventory dashboard data:', error);
        }
    }

    async function loadLowStockItems() {
        const tbody = document.getElementById('low-stock-body');

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                const lowStockItems = response.data.filter(item =>
                    item.quantity <= item.reorderLevel && item.state !== 'SOLD_OUT'
                ).slice(0, 10); // Show top 10

                if (lowStockItems.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center">No low stock items</td></tr>';
                    return;
                }

                tbody.innerHTML = lowStockItems.map(item => `
                        <tr>
                            <td>${item.code}</td>
                            <td>${item.name}</td>
                            <td>${item.quantity}</td>
                            <td>${item.reorderLevel}</td>
                            <td><span class="badge badge-warning">Low Stock</span></td>
                            <td>
                                <button class="btn btn-primary" onclick="addStockForItem('${item.code}')">
                                    Add Stock
                                </button>
                            </td>
                        </tr>
                    `).join('');
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="6" class="text-center">Error loading low stock items: ${error.message}</td></tr>`;
        }
    }

    async function loadExpiringItems() {
        const tbody = document.getElementById('expiring-body');

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                const expiringItems = response.data.filter(item =>
                    item.expiryDate && item.daysUntilExpiry <= 7 && item.daysUntilExpiry > 0
                ).slice(0, 10); // Show top 10

                if (expiringItems.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="text-center">No items expiring soon</td></tr>';
                    return;
                }

                tbody.innerHTML = expiringItems.map(item => {
                    const daysLeft = item.daysUntilExpiry;
                    const badgeClass = daysLeft <= 3 ? 'badge-danger' : 'badge-warning';

                    return `
                            <tr>
                                <td>${item.code}</td>
                                <td>${item.name}</td>
                                <td>${item.expiryDate}</td>
                                <td><span class="badge ${badgeClass}">${daysLeft} days</span></td>
                                <td>${item.quantity}</td>
                                <td>
                                    <button class="btn btn-warning" onclick="moveToShelfItem('${item.code}')">
                                        Move to Shelf
                                    </button>
                                </td>
                            </tr>
                        `;
                }).join('');
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="6" class="text-center">Error loading expiring items: ${error.message}</td></tr>`;
        }
    }

    function addStockForItem(itemCode) {
        window.location.href = `${pageContext.request.contextPath}/views/inventory/add-stock.jsp?itemCode=${itemCode}`;
    }

    function moveToShelfItem(itemCode) {
        window.location.href = `${pageContext.request.contextPath}/views/inventory/move-to-shelf.jsp?itemCode=${itemCode}`;
    }
</script>
</body>
</html>