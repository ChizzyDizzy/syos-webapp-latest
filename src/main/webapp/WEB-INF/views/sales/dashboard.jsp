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
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SYOS POS - Sales Dashboard</title>
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
            <a href="${pageContext.request.contextPath}/views/sales/dashboard.jsp" class="nav-link active">
                <span class="nav-icon">💰</span>
                <span>Sales Dashboard</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/sales/create-sale.jsp" class="nav-link">
                <span class="nav-icon">🛒</span>
                <span>Create Sale</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/sales/view-bills.jsp" class="nav-link">
                <span class="nav-icon">📋</span>
                <span>View Bills</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/sales/today-sales.jsp" class="nav-link">
                <span class="nav-icon">📊</span>
                <span>Today's Sales</span>
            </a>

            <% if (role == UserRole.MANAGER || role == UserRole.ADMIN) { %>
            <a href="${pageContext.request.contextPath}/views/inventory/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📦</span>
                <span>Inventory</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link">
                <span class="nav-icon">📈</span>
                <span>Reports</span>
            </a>
            <% } %>

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
            <h1>Sales Dashboard</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Quick Stats -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Today's Revenue</h3>
                    <p class="stat-value" id="today-revenue">$0.00</p>
                    <p class="stat-label">Total Sales</p>
                </div>
                <div class="stat-card">
                    <h3>Bills Today</h3>
                    <p class="stat-value" id="today-bills">0</p>
                    <p class="stat-label">Transactions</p>
                </div>
                <div class="stat-card">
                    <h3>Average Bill</h3>
                    <p class="stat-value" id="average-bill">$0.00</p>
                    <p class="stat-label">Per Transaction</p>
                </div>
                <div class="stat-card">
                    <h3>Items Sold</h3>
                    <p class="stat-value" id="items-sold">0</p>
                    <p class="stat-label">Today</p>
                </div>
            </div>

            <!-- Quick Actions -->
            <div class="quick-actions">
                <h2>Quick Actions</h2>
                <div class="action-grid">
                    <a href="${pageContext.request.contextPath}/views/sales/create-sale.jsp" class="action-card">
                        <span class="action-icon">🛒</span>
                        <h3>New Sale</h3>
                        <p>Process a transaction</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/sales/today-sales.jsp" class="action-card">
                        <span class="action-icon">📊</span>
                        <h3>Today's Sales</h3>
                        <p>View today's transactions</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/sales/view-bills.jsp" class="action-card">
                        <span class="action-icon">📋</span>
                        <h3>All Bills</h3>
                        <p>View all transactions</p>
                    </a>

                    <% if (role == UserRole.MANAGER || role == UserRole.ADMIN) { %>
                    <a href="${pageContext.request.contextPath}/views/reports/daily-sales.jsp" class="action-card">
                        <span class="action-icon">📈</span>
                        <h3>Sales Report</h3>
                        <p>Generate reports</p>
                    </a>
                    <% } %>
                </div>
            </div>

            <!-- Recent Transactions -->
            <div class="table-container">
                <h3>Recent Transactions</h3>
                <table class="data-table" id="recent-transactions-table">
                    <thead>
                    <tr>
                        <th>Bill #</th>
                        <th>Time</th>
                        <th>Total</th>
                        <th>Payment</th>
                        <th>Change</th>
                        <th>Type</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="recent-transactions-body">
                    <tr><td colspan="7">Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    // Initialize dashboard
    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadSalesDashboardData();
    });

    async function loadSalesDashboardData() {
        try {
            // Load today's sales summary
            const todayBills = await apiRequest('/sales/today');
            if (todayBills.success && todayBills.data) {
                const totalSales = todayBills.data.reduce((sum, bill) => sum + bill.totalAmount, 0);
                const totalItems = todayBills.data.reduce((sum, bill) =>
                    sum + bill.items.reduce((itemSum, item) => itemSum + item.quantity, 0), 0);
                const averageBill = todayBills.data.length > 0 ? totalSales / todayBills.data.length : 0;

                document.getElementById('today-revenue').textContent = `$${totalSales.toFixed(2)}`;
                document.getElementById('today-bills').textContent = todayBills.data.length;
                document.getElementById('average-bill').textContent = `$${averageBill.toFixed(2)}`;
                document.getElementById('items-sold').textContent = totalItems;
            }

            // Load recent transactions
            await loadRecentTransactions();
        } catch (error) {
            console.error('Failed to load sales dashboard data:', error);
        }
    }

    async function loadRecentTransactions() {
        const tbody = document.getElementById('recent-transactions-body');

        try {
            const response = await apiRequest('/sales/today');

            if (response.success && response.data) {
                const recentBills = response.data.slice(0, 10); // Show last 10 transactions

                if (recentBills.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" class="text-center">No transactions today</td></tr>';
                    return;
                }

                tbody.innerHTML = recentBills.map(bill => `
                        <tr>
                            <td>${bill.billNumber}</td>
                            <td>${new Date(bill.billDate).toLocaleTimeString()}</td>
                            <td>$${bill.totalAmount.toFixed(2)}</td>
                            <td>$${bill.cashTendered.toFixed(2)}</td>
                            <td>$${bill.change.toFixed(2)}</td>
                            <td><span class="badge badge-${bill.transactionType === 'ONLINE' ? 'info' : 'success'}">${bill.transactionType}</span></td>
                            <td>
                                <button class="btn btn-secondary" onclick="viewBillDetails(${bill.billNumber})">
                                    View
                                </button>
                            </td>
                        </tr>
                    `).join('');
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center">Error loading transactions: ${error.message}</td></tr>`;
        }
    }

    async function viewBillDetails(billNumber) {
        try {
            const response = await apiRequest(`/sales/${billNumber}`);

            if (response.success && response.data) {
                const bill = response.data;

                const modalHTML = `
                        <div class="modal active" id="bill-details-modal">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h2>Bill #${bill.billNumber}</h2>
                                    <button class="modal-close" onclick="closeModal('bill-details-modal')">&times;</button>
                                </div>
                                <div class="modal-body">
                                    <p><strong>Date:</strong> ${new Date(bill.billDate).toLocaleString()}</p>
                                    <p><strong>Type:</strong> ${bill.transactionType}</p>

                                    <h3>Items:</h3>
                                    <table class="data-table">
                                        <thead>
                                            <tr>
                                                <th>Item</th>
                                                <th>Qty</th>
                                                <th>Price</th>
                                                <th>Total</th>
                                            </tr>
                                        </thead>
                                        <tbody>
                                            ${bill.items.map(item => `
                                                <tr>
                                                    <td>${item.itemName}</td>
                                                    <td>${item.quantity}</td>
                                                    <td>$${item.unitPrice.toFixed(2)}</td>
                                                    <td>$${item.subtotal.toFixed(2)}</td>
                                                </tr>
                                            `).join('')}
                                        </tbody>
                                    </table>

                                    <div style="margin-top: 20px;">
                                        <p><strong>Total:</strong> $${bill.totalAmount.toFixed(2)}</p>
                                        <p><strong>Discount:</strong> $${bill.discount.toFixed(2)}</p>
                                        <p><strong>Cash:</strong> $${bill.cashTendered.toFixed(2)}</p>
                                        <p><strong>Change:</strong> $${bill.change.toFixed(2)}</p>
                                    </div>
                                </div>
                                <div class="modal-footer">
                                    <button class="btn btn-secondary" onclick="closeModal('bill-details-modal')">Close</button>
                                </div>
                            </div>
                        </div>
                    `;

                document.getElementById('modal-container').innerHTML = modalHTML;
            }
        } catch (error) {
            showAlert('error', `Failed to load bill details: ${error.message}`);
        }
    }
</script>
</body>
</html>