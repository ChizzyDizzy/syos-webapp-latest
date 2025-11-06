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
    <title>SYOS POS - Daily Sales Report</title>
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

            <a href="${pageContext.request.contextPath}/views/reports/daily-sales.jsp" class="nav-link active">
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
            <h1>Daily Sales Report</h1>
            <div class="header-actions">
                <span class="current-time" id="current-time"></span>
            </div>
        </header>

        <div class="content-body">
            <!-- Report Controls -->
            <div class="table-container">
                <h2>Generate Daily Sales Report</h2>

                <div class="form-group">
                    <label for="report-date">Select Date</label>
                    <input type="date" id="report-date" class="form-control"
                           value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>">
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
                    <button class="btn btn-primary" onclick="generateDailySalesReport()">
                        Generate Report
                    </button>
                    <button class="btn btn-secondary" onclick="generateTodayReport()">
                        Today's Report
                    </button>
                    <button class="btn btn-secondary" onclick="generateYesterdayReport()">
                        Yesterday's Report
                    </button>
                </div>
            </div>

            <!-- Report Statistics -->
            <div class="stats-grid" id="sales-stats" style="display: none;">
                <div class="stat-card">
                    <h3>Total Sales</h3>
                    <p class="stat-value" id="total-sales">$0.00</p>
                    <p class="stat-label">Revenue</p>
                </div>
                <div class="stat-card">
                    <h3>Transactions</h3>
                    <p class="stat-value" id="total-transactions">0</p>
                    <p class="stat-label">Bills</p>
                </div>
                <div class="stat-card">
                    <h3>Average Bill</h3>
                    <p class="stat-value" id="average-bill">$0.00</p>
                    <p class="stat-label">Per Transaction</p>
                </div>
                <div class="stat-card">
                    <h3>Items Sold</h3>
                    <p class="stat-value" id="total-items">0</p>
                    <p class="stat-label">Units</p>
                </div>
            </div>

            <!-- Report Output -->
            <div id="report-output" class="report-output" style="display: none;">
                <div class="section-header">
                    <h3>Daily Sales Report</h3>
                    <div>
                        <button class="btn btn-secondary" onclick="copyReport()">Copy</button>
                        <button class="btn btn-secondary" onclick="printReport()">Print</button>
                        <button class="btn btn-secondary" onclick="downloadReport()">Download</button>
                        <button class="btn btn-secondary" onclick="hideReport()">Close</button>
                    </div>
                </div>
                <div id="report-content"></div>
            </div>

            <!-- Recent Sales Data (if available) -->
            <div class="table-container" id="sales-data-container" style="display: none;">
                <h3>Sales Details</h3>
                <table class="data-table" id="sales-details-table">
                    <thead>
                    <tr>
                        <th>Bill #</th>
                        <th>Time</th>
                        <th>Items</th>
                        <th>Total</th>
                        <th>Payment</th>
                        <th>Change</th>
                        <th>Type</th>
                    </tr>
                    </thead>
                    <tbody id="sales-details-body">
                    <tr><td colspan="7">No sales data available</td></tr>
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
        // Generate today's report by default
        generateTodayReport();
    });

    async function generateDailySalesReport() {
        const date = document.getElementById('report-date').value;
        const format = document.getElementById('report-format').value;

        if (!date) {
            showAlert('error', 'Please select a date');
            return;
        }

        showLoading('report-content', 'Generating daily sales report...');
        showReportOutput();

        try {
            const response = await apiRequest(`/reports/daily-sales?date=${date}&format=${format}`);

            if (response) {
                displayReport(response, format);
                await loadSalesStatistics(date);
                await loadSalesDetails(date);
            }
        } catch (error) {
            document.getElementById('report-content').innerHTML =
                `<div class="alert alert-error">Error generating report: ${error.message}</div>`;
        }
    }

    function generateTodayReport() {
        const today = new Date().toISOString().split('T')[0];
        document.getElementById('report-date').value = today;
        generateDailySalesReport();
    }

    function generateYesterdayReport() {
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        document.getElementById('report-date').value = yesterday.toISOString().split('T')[0];
        generateDailySalesReport();
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

    async function loadSalesStatistics(date) {
        try {
            // For now, we'll use the today's bills endpoint and filter by date
            const response = await apiRequest('/sales/today');

            if (response.success && response.data) {
                const selectedDate = new Date(date + 'T00:00:00');
                const daysBills = response.data.filter(bill => {
                    const billDate = new Date(bill.billDate);
                    return billDate.toDateString() === selectedDate.toDateString();
                });

                const totalSales = daysBills.reduce((sum, bill) => sum + bill.totalAmount, 0);
                const totalItems = daysBills.reduce((sum, bill) =>
                    sum + bill.items.reduce((itemSum, item) => itemSum + item.quantity, 0), 0);
                const averageBill = daysBills.length > 0 ? totalSales / daysBills.length : 0;

                document.getElementById('total-sales').textContent = `$${totalSales.toFixed(2)}`;
                document.getElementById('total-transactions').textContent = daysBills.length;
                document.getElementById('average-bill').textContent = `$${averageBill.toFixed(2)}`;
                document.getElementById('total-items').textContent = totalItems;

                document.getElementById('sales-stats').style.display = 'grid';
            }
        } catch (error) {
            console.error('Failed to load sales statistics:', error);
        }
    }

    async function loadSalesDetails(date) {
        const tbody = document.getElementById('sales-details-body');

        try {
            const response = await apiRequest('/sales/today');

            if (response.success && response.data) {
                const selectedDate = new Date(date + 'T00:00:00');
                const daysBills = response.data.filter(bill => {
                    const billDate = new Date(bill.billDate);
                    return billDate.toDateString() === selectedDate.toDateString();
                });

                if (daysBills.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="7" class="text-center">No sales data for selected date</td></tr>';
                    return;
                }

                tbody.innerHTML = daysBills.map(bill => `
                        <tr>
                            <td><strong>${bill.billNumber}</strong></td>
                            <td>${new Date(bill.billDate).toLocaleTimeString()}</td>
                            <td>${bill.items.length} items</td>
                            <td>$${bill.totalAmount.toFixed(2)}</td>
                            <td>$${bill.cashTendered.toFixed(2)}</td>
                            <td>$${bill.change.toFixed(2)}</td>
                            <td><span class="badge badge-${bill.transactionType === 'ONLINE' ? 'info' : 'success'}">${bill.transactionType}</span></td>
                        </tr>
                    `).join('');

                document.getElementById('sales-data-container').style.display = 'block';
            }
        } catch (error) {
            tbody.innerHTML = `<tr><td colspan="7" class="text-center">Error loading sales details: ${error.message}</td></tr>`;
        }
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
        const reportContent = document.getElementById('report-content').innerHTML;
        const printWindow = window.open('', '_blank');
        printWindow.document.write(`
                <html>
                    <head>
                        <title>Daily Sales Report - SYOS POS</title>
                        <style>
                            body { font-family: Arial, sans-serif; margin: 20px; }
                            .header { text-align: center; margin-bottom: 20px; border-bottom: 2px solid #333; padding-bottom: 10px; }
                            table { width: 100%; border-collapse: collapse; margin: 20px 0; }
                            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                            th { background-color: #f5f5f5; }
                        </style>
                    </head>
                    <body>
                        <div class="header">
                            <h1>SYOS POS - Daily Sales Report</h1>
                            <p>Date: ${document.getElementById('report-date').value}</p>
                            <p>Generated on: ${new Date().toLocaleString()}</p>
                        </div>
                        ${reportContent}
                    </body>
                </html>
            `);
        printWindow.document.close();
        printWindow.print();
    }

    function downloadReport() {
        const reportContent = document.getElementById('report-content').textContent;
        const date = document.getElementById('report-date').value;
        const blob = new Blob([reportContent], { type: 'text/plain' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `daily-sales-report-${date}.txt`;
        a.click();
        window.URL.revokeObjectURL(url);
        showAlert('success', 'Report downloaded successfully');
    }

    // Auto-generate report when date changes
    document.getElementById('report-date').addEventListener('change', function() {
        if (this.value) {
            generateDailySalesReport();
        }
    });
</script>
</body>
</html>