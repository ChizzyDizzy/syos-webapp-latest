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
    <title>SYOS POS - Reports Dashboard</title>
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
                <span>Inventory</span>
            </a>

            <a href="${pageContext.request.contextPath}/views/reports/dashboard.jsp" class="nav-link active">
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
            <h1>Reports Dashboard</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Report Statistics -->
            <div class="stats-grid">
                <div class="stat-card">
                    <h3>Today's Revenue</h3>
                    <p class="stat-value" id="today-revenue">$0.00</p>
                    <p class="stat-label">Sales Today</p>
                </div>
                <div class="stat-card">
                    <h3>Monthly Revenue</h3>
                    <p class="stat-value" id="monthly-revenue">$0.00</p>
                    <p class="stat-label">This Month</p>
                </div>
                <div class="stat-card">
                    <h3>Low Stock Items</h3>
                    <p class="stat-value" id="low-stock-count">0</p>
                    <p class="stat-label">Need Attention</p>
                </div>
                <div class="stat-card">
                    <h3>Expiring Soon</h3>
                    <p class="stat-value" id="expiring-count">0</p>
                    <p class="stat-label">Within 7 Days</p>
                </div>
            </div>

            <!-- Quick Reports -->
            <div class="quick-actions">
                <h2>Quick Reports</h2>
                <div class="action-grid">
                    <a href="${pageContext.request.contextPath}/views/reports/daily-sales.jsp" class="action-card">
                        <span class="action-icon">💰</span>
                        <h3>Daily Sales</h3>
                        <p>Sales summary by date</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/reports/stock-report.jsp" class="action-card">
                        <span class="action-icon">📦</span>
                        <h3>Stock Report</h3>
                        <p>Complete inventory status</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/reports/reorder-report.jsp" class="action-card">
                        <span class="action-icon">🔄</span>
                        <h3>Reorder Report</h3>
                        <p>Items below reorder level</p>
                    </a>

                    <a href="${pageContext.request.contextPath}/views/reports/reshelve-report.jsp" class="action-card">
                        <span class="action-icon">⚠️</span>
                        <h3>Reshelve Report</h3>
                        <p>Items expiring soon</p>
                    </a>
                </div>
            </div>

            <!-- Recent Report Activity -->
            <div class="table-container">
                <h3>Recent Report Activity</h3>
                <table class="data-table" id="recent-reports-table">
                    <thead>
                    <tr>
                        <th>Report Type</th>
                        <th>Generated On</th>
                        <th>Generated By</th>
                        <th>Time Period</th>
                        <th>Actions</th>
                    </tr>
                    </thead>
                    <tbody id="recent-reports-body">
                    <tr>
                        <td colspan="5" class="text-center">No recent reports generated</td>
                    </tr>
                    </tbody>
                </table>
            </div>

            <!-- Quick Generate Section -->
            <div class="table-container">
                <h3>Quick Generate Reports</h3>
                <div class="reports-grid">
                    <div class="report-card">
                        <h4>📊 Today's Sales Report</h4>
                        <p>Generate sales report for today</p>
                        <button class="btn btn-primary" onclick="generateTodaysSalesReport()">
                            Generate Now
                        </button>
                    </div>

                    <div class="report-card">
                        <h4>📦 Current Stock Status</h4>
                        <p>Snapshot of current inventory</p>
                        <button class="btn btn-primary" onclick="generateCurrentStockReport()">
                            Generate Now
                        </button>
                    </div>

                    <div class="report-card">
                        <h4>🔄 Urgent Reorders</h4>
                        <p>Items that need immediate attention</p>
                        <button class="btn btn-warning" onclick="generateUrgentReorderReport()">
                            Generate Now
                        </button>
                    </div>

                    <div class="report-card">
                        <h4>⚠️ Critical Expiry</h4>
                        <p>Items expiring within 3 days</p>
                        <button class="btn btn-danger" onclick="generateCriticalExpiryReport()">
                            Generate Now
                        </button>
                    </div>
                </div>
            </div>

            <!-- Report Output Area -->
            <div id="quick-report-output" class="report-output" style="display: none;">
                <div class="section-header">
                    <h3>Report Output</h3>
                    <div>
                        <button class="btn btn-secondary" onclick="copyReportOutput()">Copy</button>
                        <button class="btn btn-secondary" onclick="printReportOutput()">Print</button>
                        <button class="btn btn-secondary" onclick="hideReportOutput()">Close</button>
                    </div>
                </div>
                <pre id="quick-report-content"></pre>
            </div>
        </div>
    </main>
</div>

<script src="${pageContext.request.contextPath}/js/main.js"></script>
<script>
    document.addEventListener('DOMContentLoaded', function() {
        initializeDashboard();
        loadReportsDashboardData();
    });

    async function loadReportsDashboardData() {
        try {
            // Load today's sales
            const todayBills = await apiRequest('/sales/today');
            if (todayBills.success && todayBills.data) {
                const totalSales = todayBills.data.reduce((sum, bill) => sum + bill.totalAmount, 0);
                document.getElementById('today-revenue').textContent = `$${totalSales.toFixed(2)}`;
            }

            // Load inventory statistics
            const stats = await apiRequest('/inventory/statistics');
            if (stats.success && stats.data) {
                document.getElementById('low-stock-count').textContent = stats.data.lowStockCount;
                document.getElementById('expiring-count').textContent = stats.data.expiringCount;

                // Estimate monthly revenue (this would normally come from an API)
                const today = new Date();
                const daysInMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0).getDate();
                const dailyAverage = parseFloat(document.getElementById('today-revenue').textContent.replace('$', ''));
                const monthlyEstimate = dailyAverage * daysInMonth;
                document.getElementById('monthly-revenue').textContent = `$${monthlyEstimate.toFixed(2)}`;
            }
        } catch (error) {
            console.error('Failed to load reports dashboard data:', error);
        }
    }

    async function generateTodaysSalesReport() {
        showLoading('quick-report-content', 'Generating today\'s sales report...');
        showReportOutput();

        try {
            const today = new Date().toISOString().split('T')[0];
            const response = await apiRequest(`/reports/daily-sales?date=${today}&format=text`);

            if (response) {
                document.getElementById('quick-report-content').textContent = response;
                addToRecentReports('Daily Sales Report', 'Today');
            }
        } catch (error) {
            document.getElementById('quick-report-content').textContent = `Error generating report: ${error.message}`;
        }
    }

    async function generateCurrentStockReport() {
        showLoading('quick-report-content', 'Generating current stock report...');
        showReportOutput();

        try {
            const response = await apiRequest('/reports/stock?format=text');

            if (response) {
                document.getElementById('quick-report-content').textContent = response;
                addToRecentReports('Stock Report', 'Current');
            }
        } catch (error) {
            document.getElementById('quick-report-content').textContent = `Error generating report: ${error.message}`;
        }
    }

    async function generateUrgentReorderReport() {
        showLoading('quick-report-content', 'Generating urgent reorder report...');
        showReportOutput();

        try {
            const response = await apiRequest('/reports/reorder?format=text');

            if (response) {
                document.getElementById('quick-report-content').textContent = response;
                addToRecentReports('Reorder Report', 'Urgent');
            }
        } catch (error) {
            document.getElementById('quick-report-content').textContent = `Error generating report: ${error.message}`;
        }
    }

    async function generateCriticalExpiryReport() {
        showLoading('quick-report-content', 'Generating critical expiry report...');
        showReportOutput();

        try {
            const response = await apiRequest('/reports/reshelve?format=text');

            if (response) {
                document.getElementById('quick-report-content').textContent = response;
                addToRecentReports('Reshelve Report', 'Critical');
            }
        } catch (error) {
            document.getElementById('quick-report-content').textContent = `Error generating report: ${error.message}`;
        }
    }

    function showLoading(elementId, message) {
        document.getElementById(elementId).textContent = message + '\n\nPlease wait...';
    }

    function showReportOutput() {
        document.getElementById('quick-report-output').style.display = 'block';
        // Scroll to report output
        document.getElementById('quick-report-output').scrollIntoView({ behavior: 'smooth' });
    }

    function hideReportOutput() {
        document.getElementById('quick-report-output').style.display = 'none';
    }

    function copyReportOutput() {
        const reportContent = document.getElementById('quick-report-content').textContent;
        navigator.clipboard.writeText(reportContent).then(() => {
            showAlert('success', 'Report copied to clipboard');
        }).catch(err => {
            showAlert('error', 'Failed to copy report: ' + err);
        });
    }

    function printReportOutput() {
        const reportContent = document.getElementById('quick-report-content').textContent;
        const printWindow = window.open('', '_blank');
        printWindow.document.write(`
                <html>
                    <head>
                        <title>SYOS POS Report</title>
                        <style>
                            body { font-family: Arial, sans-serif; margin: 20px; }
                            pre { white-space: pre-wrap; font-size: 12px; }
                            .header { text-align: center; margin-bottom: 20px; }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>SYOS POS Report</h1>
                            <p>Generated on: ${new Date().toLocaleString()}</p>
                        </div>
                        <pre>${reportContent}</pre>
                    </body>
                </html>
            `);
        printWindow.document.close();
        printWindow.print();
    }

    function addToRecentReports(reportType, timePeriod) {
        const tbody = document.getElementById('recent-reports-body');
        const now = new Date().toLocaleString();
        const username = sessionStorage.getItem('username') || 'Current User';

        // Check if it's the placeholder row
        if (tbody.querySelector('tr td[colspan="5"]')) {
            tbody.innerHTML = '';
        }

        // Add new report to the top
        const newRow = `
                <tr>
                    <td><strong>${reportType}</strong></td>
                    <td>${now}</td>
                    <td>${username}</td>
                    <td>${timePeriod}</td>
                    <td>
                        <button class="btn btn-secondary" onclick="regenerateReport('${reportType}', '${timePeriod}')">
                            Regenerate
                        </button>
                    </td>
                </tr>
            `;

        tbody.innerHTML = newRow + tbody.innerHTML;

        // Limit to 10 recent reports
        const rows = tbody.querySelectorAll('tr');
        if (rows.length > 10) {
            rows[rows.length - 1].remove();
        }
    }

    function regenerateReport(reportType, timePeriod) {
        switch(reportType) {
            case 'Daily Sales Report':
                generateTodaysSalesReport();
                break;
            case 'Stock Report':
                generateCurrentStockReport();
                break;
            case 'Reorder Report':
                generateUrgentReorderReport();
                break;
            case 'Reshelve Report':
                generateCriticalExpiryReport();
                break;
        }
    }
</script>
</body>
</html>