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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - Move Items to Shelf</title>
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

            <a href="${pageContext.request.contextPath}/views/inventory/add-stock.jsp" class="nav-link">
                <span class="nav-icon">➕</span>
                <span>Add Stock</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/inventory/move-to-shelf.jsp" class="nav-link active">
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
            <h1>Move Items to Shelf</h1>
            <div class="header-actions">
                <a href="${pageContext.request.contextPath}/views/inventory/items.jsp" class="btn btn-secondary">
                    Back to Inventory
                </a>
            </div>
        </header>

        <div class="content-body">
            <!-- Move to Shelf Form -->
            <div class="table-container">
                <h2>Move Items from Store to Shelf</h2>
                <p class="text-muted">Move items from storage to make them available for sale.</p>

                <form id="move-to-shelf-form">
                    <div class="form-group">
                        <label for="move-item-code">Item Code *</label>
                        <input type="text" id="move-item-code" name="itemCode" class="form-control"
                               value="<%= itemCode != null ? itemCode : "" %>" required
                               placeholder="Enter item code or search below">
                        <small class="text-muted">Enter the item code to move to shelf</small>
                    </div>

                    <div class="form-group">
                        <label for="move-quantity">Quantity to Move *</label>
                        <input type="number" id="move-quantity" name="quantity" class="form-control"
                               min="1" required placeholder="Enter quantity">
                    </div>

                    <div class="form-group">
                        <button type="submit" class="btn btn-primary btn-block">
                            Move to Shelf
                        </button>
                    </div>
                </form>
            </div>

            <!-- Available Items in Store -->
            <div class="table-container">
                <h3>Items Available in Store (Not on Shelf)</h3>
                <table class="data-table" id="store-items-table">
                    <thead>
                    <tr>
                        <th>Code</th>
                        <th>Name</th>
                        <th>Price</th>
                        <th>In Store</th>
                        <th>On Shelf</th>
                        <th>Expiry Date</th>
                        <th>Action</th>
                    </tr>
                    </thead>
                    <tbody id="store-items-body">
                    <tr><td colspan="7">Loading items in store...</td></tr>
                    </tbody>
                </table>
            </div>

            <!-- Recently Moved Items -->
            <div class="table-container">
                <h3>Recently Moved to Shelf</h3>
                <table class="data-table" id="recent-moves-table">
                    <thead>
                    <tr>
                        <th>Item Code</th>
                        <th>Item Name</th>
                        <th>Quantity</th>
                        <th>Moved On</th>
                        <th>Status</th>
                    </tr>
                    </thead>
                    <tbody id="recent-moves-body">
                    <tr><td colspan="5">No recent moves</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    const predefinedItemCode = '<%= itemCode %>';

    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadStoreItems();
        setupFormSubmission();

        if (predefinedItemCode) {
            document.getElementById('move-item-code').value = predefinedItemCode;
            focusOnQuantity();
        }
    });

    async function loadStoreItems() {
        const tbody = document.getElementById('store-items-body');

        try {
            const response = await apiRequest('/inventory/items');

            if (response.success && response.data) {
                const storeItems = response.data.filter(item =>
                    item.state === 'IN_STORE' && item.quantity > 0
                );

                if (storeItems.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" class="text-center">No items available in store</td></tr>';
                    return;
                }

                tbody.innerHTML = storeItems.map(item => {
                    const expiryInfo = item.expiryDate ?
                        `${item.expiryDate} (${item.daysUntilExpiry} days)` : 'Non-perishable';

                    return `
                            <tr>
                                <td><strong>${item.code}</strong></td>
                                <td>${item.name}</td>
                                <td>$${item.price.toFixed(2)}</td>
                                <td><span class="badge badge-info">${item.quantity} units</span></td>
                                <td><span class="badge badge-secondary">0 units</span></td>
                                <td>${expiryInfo}</td>
                                <td>
                                    <button class="btn btn-primary" onclick="selectItem('${item.code}', ${item.quantity})">
                                        Select
                                    </button>
                                </td>
                            </tr>
                        `;
                }).join('');
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center">Error loading store items: ${error.message}</td></tr>`;
        }
    }

    function setupFormSubmission() {
        document.getElementById('move-to-shelf-form').addEventListener('submit', async function(e) {
            e.preventDefault();

            const itemCode = document.getElementById('move-item-code').value.toUpperCase();
            const quantity = parseInt(document.getElementById('move-quantity').value);

            if (!itemCode || isNaN(quantity) || quantity <= 0) {
                showAlert('error', 'Please enter valid item code and quantity');
                return;
            }

            try {
                const response = await apiRequest('/inventory/move-to-shelf', {
                    method: 'POST',
                    body: JSON.stringify({ itemCode, quantity })
                });

                if (response.success) {
                    showAlert('success', `Successfully moved ${quantity} units of ${itemCode} to shelf`);

                    // Reset form
                    document.getElementById('move-to-shelf-form').reset();
                    if (predefinedItemCode) {
                        document.getElementById('move-item-code').value = predefinedItemCode;
                    }

                    // Reload data
                    loadStoreItems();
                    addToRecentMoves(itemCode, quantity);
                }
            } catch (error) {
                showAlert('error', `Failed to move items: ${error.message}`);
            }
        });
    }

    function selectItem(itemCode, maxQuantity) {
        document.getElementById('move-item-code').value = itemCode;
        document.getElementById('move-quantity').value = '';
        document.getElementById('move-quantity').max = maxQuantity;
        document.getElementById('move-quantity').placeholder = `Max: ${maxQuantity} units`;

        focusOnQuantity();
        showAlert('info', `Selected ${itemCode}. You can move up to ${maxQuantity} units.`);
    }

    function focusOnQuantity() {
        document.getElementById('move-quantity').focus();
    }

    function addToRecentMoves(itemCode, quantity) {
        const tbody = document.getElementById('recent-moves-body');
        const now = new Date().toLocaleString();

        // Get current rows
        let currentRows = [];
        const rows = tbody.querySelectorAll('tr');
        rows.forEach(row => {
            const cells = row.querySelectorAll('td');
            if (cells.length === 5) {
                currentRows.push({
                    code: cells[0].textContent,
                    name: cells[1].textContent,
                    quantity: cells[2].textContent,
                    date: cells[3].textContent,
                    status: cells[4].innerHTML
                });
            }
        });

        // Add new move (limit to 10 recent moves)
        const newMove = {
            code: itemCode,
            name: 'Loading...', // We'd need to fetch the name
            quantity: `${quantity} units`,
            date: now,
            status: '<span class="badge badge-success">Completed</span>'
        };

        currentRows.unshift(newMove);
        if (currentRows.length > 10) {
            currentRows = currentRows.slice(0, 10);
        }

        // Update table
        tbody.innerHTML = currentRows.map(move => `
                <tr>
                    <td><strong>${move.code}</strong></td>
                    <td>${move.name}</td>
                    <td>${move.quantity}</td>
                    <td>${move.date}</td>
                    <td>${move.status}</td>
                </tr>
            `).join('');

        // Fetch item names for recent moves
        fetchItemNames();
    }

    async function fetchItemNames() {
        try {
            const response = await apiRequest('/inventory/items');
            if (response.success && response.data) {
                const items = response.data;
                const tbody = document.getElementById('recent-moves-body');
                const rows = tbody.querySelectorAll('tr');

                rows.forEach(row => {
                    const cells = row.querySelectorAll('td');
                    const itemCode = cells[0].textContent.trim();
                    const item = items.find(i => i.code === itemCode);
                    if (item && cells[1].textContent === 'Loading...') {
                        cells[1].textContent = item.name;
                    }
                });
            }
        } catch (error) {
            console.error('Failed to fetch item names:', error);
        }
    }

    // Auto-focus on quantity when item code is entered
    document.getElementById('move-item-code').addEventListener('change', function() {
        if (this.value.trim()) {
            focusOnQuantity();
        }
    });
</script>
</body>
</html>