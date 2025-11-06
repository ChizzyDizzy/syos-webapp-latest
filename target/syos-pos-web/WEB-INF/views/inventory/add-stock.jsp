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

    String itemCode = request.getParameter("itemCode");
    String viewMode = request.getParameter("view");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - <%= itemCode != null ? "Update Stock" : "Add Stock" %></title>
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
            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Inventory Dashboard</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="nav-link">
                <span class="nav-icon">📋</span>
                <span>All Items</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/add-stock.jsp" class="nav-link active">
                <span class="nav-icon">➕</span>
                <span><%= itemCode != null ? "Update Stock" : "Add Stock" %></span>
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
            <h1><%= itemCode != null ? "Update Stock Item" : "Add New Stock" %></h1>
            <div class="header-actions">
                <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="btn btn-secondary">
                    Back to Inventory
                </a>
            </div>
        </header>

        <div class="content-body">
            <div class="table-container">
                <form id="stock-form">
                    <div class="form-group">
                        <label for="item-code">Item Code *</label>
                        <input type="text" id="item-code" name="code" class="form-control"
                               value="<%= itemCode != null ? itemCode : "" %>"
                            <%= itemCode != null || "true".equals(viewMode) ? "readonly" : "" %> required>
                        <small class="text-muted">Unique identifier for the item</small>
                    </div>

                    <div class="form-group">
                        <label for="item-name">Item Name *</label>
                        <input type="text" id="item-name" name="name" class="form-control" required>
                    </div>

                    <div class="form-group">
                        <label for="item-price">Price ($) *</label>
                        <input type="number" id="item-price" name="price" class="form-control"
                               step="0.01" min="0" required>
                    </div>

                    <div class="form-group">
                        <label for="item-quantity">Quantity *</label>
                        <input type="number" id="item-quantity" name="quantity" class="form-control"
                               min="1" required>
                    </div>

                    <div class="form-group">
                        <label for="item-reorder-level">Reorder Level</label>
                        <input type="number" id="item-reorder-level" name="reorderLevel" class="form-control"
                               min="0" value="5">
                        <small class="text-muted">Minimum quantity before reorder alert</small>
                    </div>

                    <div class="form-group">
                        <label for="item-expiry">Expiry Date</label>
                        <input type="date" id="item-expiry" name="expiryDate" class="form-control">
                        <small class="text-muted">Leave empty for non-perishable items</small>
                    </div>

                    <div class="form-group">
                        <label for="item-description">Description</label>
                        <textarea id="item-description" name="description" class="form-control"
                                  rows="3" placeholder="Optional item description"></textarea>
                    </div>

                    <div class="form-group">
                        <% if ("true".equals(viewMode)) { %>
                        <button type="button" class="btn btn-primary" onclick="enableEditing()">
                            Enable Editing
                        </button>
                        <a href="${pageContext.request.contextPath}/views/inventory/add-stock.jsp?itemCode=<%= itemCode %>"
                           class="btn btn-warning">
                            Edit This Item
                        </a>
                        <% } else { %>
                        <button type="submit" class="btn btn-primary btn-block">
                            <%= itemCode != null ? "Update Stock" : "Add Stock" %>
                        </button>
                        <% } %>
                    </div>
                </form>
            </div>

            <!-- Current Stock Information -->
            <% if (itemCode != null) { %>
            <div class="table-container" id="current-stock-info" style="display: none;">
                <h3>Current Stock Information</h3>
                <table class="data-table">
                    <tbody id="stock-info-body">
                    <tr><td colspan="2">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
            <% } %>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    const itemCode = '<%= itemCode %>';
    const viewMode = '<%= viewMode %>' === 'true';

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();

        if (itemCode) {
            loadItemDetails();
            document.getElementById('current-stock-info').style.display = 'block';
        }

        if (!viewMode) {
            setupFormSubmission();
        }
    });

    async function loadItemDetails() {
        try {
            const response = await apiRequest(`/inventory/items/${itemCode}`);

            if (response.success && response.data) {
                const item = response.data;

                // Fill form with existing data
                document.getElementById('item-name').value = item.name || '';
                document.getElementById('item-price').value = item.price || '';
                document.getElementById('item-quantity').value = item.quantity || '';
                document.getElementById('item-reorder-level').value = item.reorderLevel || 5;
                document.getElementById('item-expiry').value = item.expiryDate || '';
                document.getElementById('item-description').value = item.description || '';

                // Display current stock info
                displayStockInfo(item);
            }
        } catch (error) {
            console.error('Failed to load item details:', error);
        }
    }

    function displayStockInfo(item) {
        const tbody = document.getElementById('stock-info-body');
        const stateBadge = getStateBadge(item.state);
        const expiryInfo = item.expiryDate ?
            `${item.expiryDate} (${item.daysUntilExpiry} days left)` : 'Non-perishable';

        tbody.innerHTML = `
                <tr>
                    <td><strong>Current Quantity:</strong></td>
                    <td>${item.quantity} units</td>
                </tr>
                <tr>
                    <td><strong>Current State:</strong></td>
                    <td>${stateBadge}</td>
                </tr>
                <tr>
                    <td><strong>Expiry Information:</strong></td>
                    <td>${expiryInfo}</td>
                </tr>
                <tr>
                    <td><strong>Last Updated:</strong></td>
                    <td>${new Date().toLocaleString()}</td>
                </tr>
            `;
    }

    function getStateBadge(state) {
        const badges = {
            'IN_STORE': '<span class="badge badge-info">In Store</span>',
            'ON_SHELF': '<span class="badge badge-success">On Shelf</span>',
            'EXPIRED': '<span class="badge badge-danger">Expired</span>',
            'SOLD_OUT': '<span class="badge badge-warning">Sold Out</span>'
        };
        return badges[state] || state;
    }

    function setupFormSubmission() {
        document.getElementById('stock-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const formData = {
                code: document.getElementById('item-code').value.toUpperCase(),
                name: document.getElementById('item-name').value,
                price: parseFloat(document.getElementById('item-price').value),
                quantity: parseInt(document.getElementById('item-quantity').value),
                reorderLevel: parseInt(document.getElementById('item-reorder-level').value),
                expiryDate: document.getElementById('item-expiry').value || null,
                description: document.getElementById('item-description').value
            };

            try {
                const endpoint = itemCode ? '/inventory/add-stock' : '/inventory/add-stock';
                const response = await apiRequest(endpoint, {
                    method: 'POST',
                    body: JSON.stringify(formData)
                });

                if (response.success) {
                    showAlert('success', itemCode ? 'Stock updated successfully!' : 'Stock added successfully!');

                    // Redirect back to inventory list after 2 seconds
                    setTimeout(() => {
                        window.location.href = '${pageContext.request.contextPath}/views/inventory/items.jsp';
                    }, 2000);
                }
            } catch (error) {
                showAlert('error', `Failed to ${itemCode ? 'update' : 'add'} stock: ${error.message}`);
            }
        });
    }

    function enableEditing() {
        // Remove readonly attributes and change button
        const form = document.getElementById('stock-form');
        const inputs = form.querySelectorAll('input, textarea, select');
        inputs.forEach(input => input.removeAttribute('readonly'));

        // Change the button to submit
        const buttonGroup = form.querySelector('.form-group:last-child');
        buttonGroup.innerHTML = `
                <button type="submit" class="btn btn-primary btn-block">
                    Update Stock
                </button>
            `;

        // Setup form submission
        setupFormSubmission();

        showAlert('info', 'Editing enabled. You can now update the item details.');
    }

    // Auto-generate item code if not provided
    document.getElementById('item-name').addEventListener('blur', function() {
        if (!itemCode && !document.getElementById('item-code').value) {
            const name = this.value;
            if (name.length >= 3) {
                const code = name.substring(0, 3).toUpperCase() +
                    Math.floor(Math.random() * 1000).toString().padStart(3, '0');
                document.getElementById('item-code').value = code;
            }
        }
    });
</script>
</body>
</html>