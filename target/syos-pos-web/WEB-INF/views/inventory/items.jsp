#%%
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
    <title>SYOS POS - All Inventory Items</title>
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
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="nav-link">
                <span class="nav-icon">💰</span>
                <span>Sales</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Inventory Dashboard</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="nav-link active">
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
        </nav>

        <div class="sidebar-footer">
            <button id="logout-btn" class="btn btn-danger btn-block">🚪 Logout</button>
        </div>
    </aside>

    <main class="main-content">
        <header class="content-header">
            <h1>All Inventory Items</h1>
            <div class="header-actions">
                <input type="text" id="search-items" class="form-control" placeholder="Search items..." style="width: 300px;">
            </div>
        </header>

        <div class="content-body">
            <div class="table-container">
                <div class="section-header">
                    <h2>Complete Inventory List</h2>
                    <div>
                        <button class="btn btn-secondary" onclick="exportInventory()">Export CSV</button>
                        <button class="btn btn-primary" onclick="refreshInventory()">Refresh</button>
                    </div>
                </div>

                <table class="data-table" id="inventory-table">
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Price</th>
                        <th>Quantity</th>
                        <th>State</th>
                        <th>Expiry Date</th>
                        <th>Days Left</th>
                        <th>Reorder Level</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="inventory-body">
                    <tr><td colspan="9">Loading inventory...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    let allInventoryItems = [];

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadAllInventoryItems();

        // Setup search functionality
        document.getElementById('search-items').addEventListener('input', function(e) {
            filterInventoryItems(e.target.value);
        });
    });

    async function loadAllInventoryItems() {
        const tbody = document.getElementById('inventory-body');
        tbody.innerHTML = '<tr><td colspan="9">Loading...</td></tr>';

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                allInventoryItems = response.data;
                displayInventoryItems(allInventoryItems);
            } else {
                tbody.innerHTML = '<tr><td colspan="9" class="text-center">No items found</td></tr>';
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="9" class="text-center">Error loading inventory: ${error.message}</td></tr>`;
        }
    }

    function displayInventoryItems(items) {
        const tbody = document.getElementById('inventory-body');

        if (items.length === 0) {
            tbody.innerHTML = '<tr><td colspan="9" class="text-center">No items found</td></tr>';
            return;
        }

        tbody.innerHTML = items.map(item => {
            const stateBadge = getStateBadge(item.state);
            const expiryInfo = item.expiryDate ?
                `<td>${item.expiryDate}</td><td>${item.daysUntilExpiry || 'N/A'}</td>` :
                '<td>N/A</td><td>N/A</td>';

            const stockStatus = getStockStatus(item.quantity, item.reorderLevel);

            return `
                    <tr>
                        <td><strong>${item.code}</strong></td>
                        <td>${item.name}</td>
                        <td>$${item.price.toFixed(2)}</td>
                        <td><span class="${stockStatus.class}">${item.quantity}</span></td>
                        <td>${stateBadge}</td>
                        ${expiryInfo}
                        <td>${item.reorderLevel}</td>
                        <td>
                            <button class="btn btn-secondary" onclick="viewItemDetails('${item.code}')">View</button>
                            <button class="btn btn-primary" onclick="addStockForItem('${item.code}')">Add Stock</button>
                        </td>
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

    function getStockStatus(quantity, reorderLevel) {
        if (quantity === 0) {
            return { class: 'badge badge-danger', text: 'Out of Stock' };
        } else if (quantity <= reorderLevel) {
            return { class: 'badge badge-warning', text: 'Low Stock' };
        } else {
            return { class: '', text: 'In Stock' };
        }
    }

    function filterInventoryItems(searchTerm) {
        if (!searchTerm) {
            displayInventoryItems(allInventoryItems);
            return;
        }

        const filtered = allInventoryItems.filter(item =>
            item.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
            item.name.toLowerCase().includes(searchTerm.toLowerCase())
        );

        displayInventoryItems(filtered);
    }

    function refreshInventory() {
        loadAllInventoryItems();
        showAlert('success', 'Inventory refreshed');
    }

    function exportInventory() {
        // Simple CSV export
        const headers = ['Code', 'Name', 'Price', 'Quantity', 'State', 'Expiry Date', 'Days Left', 'Reorder Level'];
        const csvContent = [
            headers.join(','),
            ...allInventoryItems.map(item => [
                item.code,
                `"${item.name}"`,
                item.price,
                item.quantity,
                item.state,
                item.expiryDate || 'N/A',
                item.daysUntilExpiry || 'N/A',
                item.reorderLevel
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `inventory-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);

        showAlert('success', 'Inventory exported successfully');
    }

    function viewItemDetails(itemCode) {
        window.location.href = `${pageContext.request.contextPath}/views/inventory/add-stock.jsp?itemCode=${itemCode}&view=true`;
    }

    function addStockForItem(itemCode) {
        window.location.href = `${pageContext.request.contextPath}/views/inventory/add-stock.jsp?itemCode=${itemCode}`;
    }
</script>
</body>
</html>